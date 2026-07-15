import 'package:flutter/foundation.dart';

import '../../billing/persona.dart';
import 'chunker.dart';
import 'prompts.dart';
import 'summary_backend.dart';
import 'summary_types.dart';
import 'token_estimator.dart';
import 'transcript_formatter.dart';

/// Slack left over after the measured prompt pieces, to absorb (a) the framing
/// lines the composers add around an instruction ("Meeting: …", "Part 2 of 5.",
/// "TRANSCRIPT SEGMENT:") and (b) any drift between [estimateTokens] and the
/// backend's real tokenizer. 200 tokens against a measured framing cost of ~30
/// is deliberately generous: the failure this pipeline exists to fix is a
/// silent context overflow, and one extra chunk is a far cheaper mistake than a
/// truncated meeting.
const int _kReserveTokens = 200;

/// Hierarchical reduce depth cap. Each level costs a full pass over the notes;
/// beyond three, a meeting is long enough that we owe the user the visible
/// compression notice rather than another ten minutes of GPU time.
const int _kMaxFoldLevels = 3;

/// Map stage is extraction — near-deterministic. Reduce is the one stage that
/// composes prose. The critic must be as literal as the backend allows.
const double _kMapTemperature = 0.2;
const double _kFoldTemperature = 0.2;
const double _kReduceTemperature = 0.4;
const double _kCriticTemperature = 0.1;

/// The single pass does extraction AND composition AND its own self-check in one
/// decode, with NO critic behind it — it is the only stage with no backstop. The
/// reduce can afford 0.4 because a critic follows it; this cannot. 0.4 is the
/// temperature at which "must buy for 4 back" becomes a confident "4-pack".
///
/// NOTE: the Render proxy currently pins temperature server-side, so on the cloud
/// path this value is advisory. It is load-bearing for BYOK, Ollama, and — the
/// case that matters most — a SHORT meeting on Gemma, which takes this branch
/// with a 2B model and no verification pass at all.
const double _kSinglePassTemperature = 0.2;

/// The reduce (and the critic, which re-emits the whole draft) writes an entire
/// document: seven sections, a citation on every line. The map emits terse note
/// lines. Budgeting all four stages against one [BackendCapabilities.maxOutputTokens]
/// is what left the reduce ~1,300 tokens of a 4,096 window to write a ~1,900-token
/// contract — so it ran off the end of the window mid-document and the last
/// section (Low confidence) shipped as zero bytes.
///
/// Reserving the composing stages their real output cost costs notes volume, which
/// is the right trade now that [_trimNotesToTokens] drops narration instead of
/// findings. 1,400 is sized against a contract-conformant document from a 2B model
/// (~40-60 cited lines, ~900-1,200 tokens) with headroom, while still leaving
/// ~1,250 tokens of notes inside Gemma's 4,096 window. Every token added to
/// [kSystemPreamble] or [reduceInstruction] comes straight out of that 1,250.
const int _kComposeOutputReserve = 1400;

/// Owns every prompt, the chunking, the map-reduce, and the critic pass.
///
/// The old design put `persona.prompt + transcript` inside each backend, which
/// meant (a) no backend could chunk, so a 25-minute meeting overflowed Gemma's
/// 4096-token combined window and came back truncated or broken, and (b) every
/// prompt fix had to be made five times. Backends are now dumb: they advertise a
/// window and run one generation. Everything that determines summary QUALITY is
/// here.
///
/// Shape of a run:
///   * fits the window  -> ONE generate call (single-pass, self-check embedded).
///     Skipping map-reduce when it isn't needed avoids both the latency and the
///     quality loss of summarizing a summary. This is the cloud/BYOK path, and
///     also the on-device path for a short meeting.
///   * doesn't fit      -> map (extract per chunk) -> optional hierarchical fold
///     -> reduce (compose) -> critic (delete what the notes don't support).
class SummaryPipeline {
  const SummaryPipeline();

  /// Cheap, generation-free preview of how [input] will run on [caps] — single
  /// pass or chunked map-reduce, and how many chunks. Mirrors [run]'s branch
  /// EXACTLY (same single-pass token test, same chunker), so a UI that offers a
  /// cloud upgrade for long meetings offers it precisely when [run] would fold.
  static SummaryPlan planFor({
    required SummaryInput input,
    required BackendCapabilities caps,
    Persona? persona,
  }) {
    if (input.segments.isEmpty) {
      return const SummaryPlan(willMapReduce: false, chunkCount: 0);
    }
    final p = persona ?? personasByKey['basic']!;
    final system = buildSystemPrompt(glossary: input.glossary);
    final systemTokens = estimateTokens(system);
    final transcript = renderSegments(input.segments);
    final singlePassTokens =
        systemTokens +
        estimateTokens(
          buildSinglePassPrompt(
            persona: p,
            transcript: transcript,
            meetingTitle: input.meetingTitle,
          ),
        ) +
        _kReserveTokens;
    if (singlePassTokens <= caps.maxInputTokens) {
      return const SummaryPlan(willMapReduce: false, chunkCount: 1);
    }
    final mapOverhead = systemTokens + estimateTokens(mapInstruction());
    final target = caps.maxInputTokens - mapOverhead - _kReserveTokens;
    final chunks = target <= 0
        ? 0
        : chunkSegments(input.segments, targetTokens: target).length;
    return SummaryPlan(willMapReduce: true, chunkCount: chunks);
  }

  Future<SummaryResult> run({
    required SummaryBackend backend,
    required SummaryInput input,
    required Persona persona,
    void Function(SummaryProgress)? onProgress,
    CancelToken? cancel,
  }) async {
    final sw = Stopwatch()..start();
    cancel?.throwIfCancelled();

    if (input.segments.isEmpty) {
      throw StateError(
        'Cannot summarize "${input.meetingTitle}": no transcript segments. '
        'buildPromptSegments() should have thrown or synthesized segments from '
        'the body before we got here.',
      );
    }

    final caps = backend.capabilities;
    final system = buildSystemPrompt(glossary: input.glossary);
    final systemTokens = estimateTokens(system);
    final transcript = renderSegments(input.segments);
    if (transcript.trim().isEmpty) {
      throw StateError(
        'Cannot summarize "${input.meetingTitle}": the transcript rendered '
        'empty from ${input.segments.length} segments.',
      );
    }

    // --- Can we do it in one pass? -----------------------------------------
    final singlePass = buildSinglePassPrompt(
      persona: persona,
      transcript: transcript,
      meetingTitle: input.meetingTitle,
    );
    final singlePassTokens =
        systemTokens + estimateTokens(singlePass) + _kReserveTokens;

    if (singlePassTokens <= caps.maxInputTokens) {
      final reporter = _Progress(onProgress, totalSteps: 2);
      reporter.emit(SummaryStage.preparing, 'Reading the transcript...');
      cancel?.throwIfCancelled();
      reporter.emit(SummaryStage.reducing, 'Writing the notes...');

      final text = await backend.generate(
        prompt: singlePass,
        system: system,
        temperature: _kSinglePassTemperature,
        cancel: cancel,
      );
      cancel?.throwIfCancelled();
      // The single-pass path (short meeting on-device, OR a big-window/cloud
      // backend) gets the same transcript-based safety net as map-reduce: spaced
      // digits, absence/handoff phrases, and figure sweep. It has no map notes to
      // carry, but a 2B reading a long transcript in one shot still drops figures
      // (attention dilution), so the sweep matters here too.
      final out = _mechanicalSafetyNet(
        text: _normalizeOutput(text.trim()),
        transcript: transcript,
        segments: input.segments,
      );
      if (out.isEmpty) {
        throw StateError(
          '${backend.modelId} returned an empty summary for '
          '"${input.meetingTitle}" (single pass, '
          '${estimateTokens(transcript)} est. transcript tokens).',
        );
      }
      reporter.done();
      return SummaryResult(
        text: out,
        modelId: backend.modelId,
        processingTime: sw.elapsed,
      );
    }

    // --- Map-reduce ---------------------------------------------------------
    final mapOverhead = systemTokens + estimateTokens(mapInstruction());
    final targetTokens = caps.maxInputTokens - mapOverhead - _kReserveTokens;
    if (targetTokens <= 0) {
      throw StateError(
        '${backend.modelId} cannot summarize: its input budget '
        '(${caps.maxInputTokens} tokens = ${caps.contextTokens} context - '
        '${caps.maxOutputTokens} reserved for output) is smaller than the '
        'system prompt + map instruction ($mapOverhead tokens). The backend '
        'window is too small for this glossary.',
      );
    }

    final chunks = chunkSegments(input.segments, targetTokens: targetTokens);

    // preparing + one map per chunk + reduce + critic. Folds bump the total as
    // they are discovered; a skipped critic is absorbed by done().
    final reporter = _Progress(onProgress, totalSteps: chunks.length + 3);
    reporter.emit(SummaryStage.preparing, 'Reading the transcript...');

    // Sequential, NOT parallel: on-device there is one GPU, and concurrent
    // flutter_gemma sessions OOM low-end Android. The latency is the price of
    // running at all.
    var notes = <String>[];
    for (final chunk in chunks) {
      cancel?.throwIfCancelled();
      reporter.emit(
        SummaryStage.mapping,
        'Reading part ${chunk.index + 1} of ${chunk.total}...',
      );
      final raw = await backend.generate(
        prompt: buildMapPrompt(chunk: chunk, meetingTitle: input.meetingTitle),
        system: system,
        temperature: _kMapTemperature,
        cancel: cancel,
      );
      final note = raw.trim();
      if (note.isEmpty) {
        // A chunk of pure filler or dead air genuinely has nothing to extract.
        // Failing the whole meeting over one such chunk would be worse than
        // dropping it — but if EVERY chunk comes back empty that is a broken
        // backend, and the check below turns it into a StateError rather than a
        // blank summary.
        debugPrint(
          'SummaryPipeline: ${backend.modelId} extracted nothing from part '
          '${chunk.index + 1}/${chunk.total}; dropping it.',
        );
        continue;
      }
      notes.add(_labelledNote(note, chunk.index + 1, chunk.total, chunk));
    }
    // The 2B copies per-line [mm:ss] unreliably (it dropped every one on the
    // reference meeting, then the reduce invented a single constant time for 33
    // lines). The group range stamped by _labelledNote is the real-timestamp
    // fallback the reduce is told to use; dedup here removes the verbatim repeats a
    // small model emits ("you can only link them by name" x5) so the reduce is not
    // asked to dedupe faithfully — a synthesis task it fails.
    notes = _dedupeNoteLines(notes);

    if (notes.isEmpty) {
      throw StateError(
        '${backend.modelId} extracted nothing from any of ${chunks.length} '
        'transcript parts of "${input.meetingTitle}". The model produced no '
        'notes at all — this is a backend failure, not an empty meeting.',
      );
    }

    // Capture the two note classes a 2B most reliably loses on a long meeting —
    // BEFORE the fold, which is one of the places they vanish. The map extracts
    // them per chunk faithfully (the eval: traps 24/24, but low-confidence 1/11
    // and continuity dropped on the longest meetings); trusting the model to
    // shepherd them through fold + a 1024-token reduce is the leak. We re-attach
    // them deterministically after the critic. Same "don't trust the 2B, carry
    // it mechanically" fix that gave us real timestamps.
    final preFoldNotes = notes.join('\n\n');
    // Low confidence is a RECOGNITION problem, not just a preservation one: a 2B
    // rarely flags a digit string read out one-at-a-time ("6 5 7 6 6") as
    // uncertain, so there is nothing in the notes to carry. Detect that pattern
    // mechanically from the transcript — the dominant real-ASR low-confidence case
    // (an ID dictated digit by digit) — and force it in as (heard, unverified).
    final carriedLowConf = <String>[
      ..._noteClassLines(preFoldNotes, 'LOW CONFIDENCE'),
      ..._detectSpacedDigits(transcript),
    ];
    // Continuity is also a RECOGNITION problem on long meetings: the handoff is a
    // social aside at the buzzer the map may not tag. Detect the strongest
    // absence/leave/handoff phrases from the transcript and merge them with what
    // the map did tag. Appended non-presence-aware below (like low-confidence) —
    // the presence heuristic was skipping items it wrongly judged already there.
    final carriedContinuity = <String>[
      ..._noteClassLines(preFoldNotes, 'CONTINUITY'),
      ..._detectContinuity(input.segments),
    ];
    // SPECIFICS too: verbatim numbers/IDs/names the map pulled out — the planted
    // facts the eval's mustContain checks (specifics 22/31 on long meetings; the
    // reduce weaves most in but drops ~29% when folding). Carried presence-AWARE
    // below so only the ones the model actually lost get re-added.
    // SPECIFICS from the map PLUS a mechanical figure sweep of the transcript.
    // The sweep catches money / percentages / unit-quantities the map missed
    // entirely on a long meeting (extraction miss, which carry-through alone
    // cannot fix) — the residual that keeps long meetings off 100%.
    final carriedSpecifics = <String>[
      ..._noteClassLines(preFoldNotes, 'SPECIFICS'),
      ..._sweepFigures(transcript),
    ];

    // --- Hierarchical reduce (fold) ----------------------------------------
    // The notes themselves can overflow the window on a long meeting. Fold them
    // back into the SAME notes format in batches and try again. BEHAVIOURS &
    // LIMITS, SPECIFICS, DECISIONS, PROPOSED ACTIONS, PEOPLE, CONTINUITY and LOW
    // CONFIDENCE are carried through losslessly by foldInstruction(); only FACTS
    // are compressed.
    //
    // [composeWindow] is the input the reduce and the critic actually get: they
    // emit a whole document, so they need far more of the window reserved for
    // output than a map call does. Never larger than the backend's own input
    // budget.
    final composeWindow =
        caps.contextTokens - _kComposeOutputReserve < caps.maxInputTokens
        ? caps.contextTokens - _kComposeOutputReserve
        : caps.maxInputTokens;
    final reduceScaffold =
        systemTokens +
        estimateTokens(
          buildReducePrompt(
            persona: persona,
            notes: '',
            meetingTitle: input.meetingTitle,
          ),
        ) +
        _kReserveTokens;
    final notesBudget = composeWindow - reduceScaffold;
    if (notesBudget <= 0) {
      throw StateError(
        '${backend.modelId} cannot summarize: the window left for the reduce '
        '($composeWindow tokens = ${caps.contextTokens} context - '
        '$_kComposeOutputReserve reserved so the notes can actually be WRITTEN) '
        'is smaller than the reduce prompt scaffold alone ($reduceScaffold '
        'tokens). Folding cannot rescue this — the window is too small for the '
        'contract.',
      );
    }

    final foldScaffold =
        systemTokens +
        estimateTokens(buildFoldPrompt(notes: '')) +
        _kReserveTokens;
    final foldBudget = caps.maxInputTokens - foldScaffold;

    var compressed = false;
    for (
      var level = 0;
      level < _kMaxFoldLevels &&
          estimateTokens(notes.join('\n\n')) > notesBudget;
      level++
    ) {
      cancel?.throwIfCancelled();
      if (foldBudget <= 0) {
        // Window too small to fold at all — fall through to the visible trim.
        break;
      }

      final batches = _batch(notes, foldBudget);
      reporter.addSteps(batches.length);

      final folded = <String>[];
      for (var i = 0; i < batches.length; i++) {
        cancel?.throwIfCancelled();
        reporter.emit(
          SummaryStage.reducing,
          'Condensing notes (${i + 1} of ${batches.length})...',
        );
        final raw = await backend.generate(
          prompt: buildFoldPrompt(
            notes: _trimNotesToTokens(batches[i], foldBudget),
          ),
          system: system,
          temperature: _kFoldTemperature,
          cancel: cancel,
        );
        final note = raw.trim();
        if (note.isNotEmpty) {
          folded.add(_labelledFold(note, i + 1, batches.length));
        }
      }

      if (folded.isEmpty) {
        debugPrint(
          'SummaryPipeline: fold level ${level + 1} produced nothing; keeping '
          'the previous notes and trimming instead.',
        );
        break;
      }
      // A fold that does not actually shrink the notes (the model padded, or
      // the batch was already minimal) would loop us for nothing. Take it once,
      // then stop and let the trim below do the honest, visible truncation.
      final before = estimateTokens(notes.join('\n\n'));
      final after = estimateTokens(folded.join('\n\n'));
      notes = folded;
      if (after >= before) {
        debugPrint(
          'SummaryPipeline: fold level ${level + 1} did not shrink the notes '
          '($before -> $after est. tokens); stopping the fold.',
        );
        break;
      }
    }

    var joined = notes.join('\n\n');
    final hadUncertainty = _hasNoteSection(joined, 'LOW CONFIDENCE');
    if (estimateTokens(joined) > notesBudget) {
      // Even hierarchical folding could not get the notes under the window.
      // CLAUDE.md forbids silent truncation, so we trim visibly and tell the
      // user, in the summary itself, that detail was lost. The trim sheds
      // NARRATION (see kNoteEvictionOrder) — the findings survive.
      joined = _trimNotesToTokens(joined, notesBudget);
      compressed = true;
    }

    // --- Reduce -------------------------------------------------------------
    cancel?.throwIfCancelled();
    reporter.emit(SummaryStage.reducing, 'Organizing the notes...');
    final draft = (await backend.generate(
      prompt: buildReducePrompt(
        persona: persona,
        notes: joined,
        meetingTitle: input.meetingTitle,
      ),
      system: system,
      temperature: _kReduceTemperature,
      cancel: cancel,
    )).trim();
    if (draft.isEmpty) {
      throw StateError(
        '${backend.modelId} returned an empty summary for '
        '"${input.meetingTitle}" (reduce over ${notes.length} note groups).',
      );
    }

    // --- Critic -------------------------------------------------------------
    // The cheap offline quality multiplier: small models hallucinate on the way
    // OUT of the reduce, not on the way in — the notes are usually clean and the
    // draft is where an invented "44-pack" appears. A second pass that only
    // deletes (and restores dropped continuity) catches most of it.
    cancel?.throwIfCancelled();
    var text = draft;

    // Two candidate inputs, in decreasing fidelity. The full notes are best; but
    // full notes + a full draft + the instruction cannot fit a 4096-token window
    // on ANY meeting long enough to have been map-reduced — which made the critic
    // structurally dead on exactly the meetings it exists for. The LEDGER (the
    // note classes criticInstruction() is authoritative for: specifics,
    // behaviours, decisions, proposed actions, people, continuity, low
    // confidence) is ~40% of the notes and does fit.
    // The critic gets kCriticSystem, not the full preamble: it does not read the
    // transcript or repair terms, so the ~565-token preamble is dead weight that
    // used to push the ledger + draft over the window and skip the critic on every
    // map-reduced meeting. Budget the fit against the SHORTER system accordingly.
    final ledger = _criticLedger(joined);
    final criticPrompt = _fitCriticPrompt(
      candidates: [joined, if (ledger.isNotEmpty) ledger],
      draft: draft,
      systemTokens: estimateTokens(kCriticSystem),
      budget: composeWindow,
    );
    if (criticPrompt != null) {
      reporter.emit(SummaryStage.checking, 'Checking for invented details...');
      final checked = (await backend.generate(
        prompt: criticPrompt,
        system: kCriticSystem,
        temperature: _kCriticTemperature,
        cancel: cancel,
      )).trim();
      // A critic that returns nothing has failed at its job, not found the draft
      // to be entirely unsupported. Keep the draft — a partial safeguard is not
      // worth losing a good summary over.
      if (checked.isEmpty) {
        debugPrint(
          'SummaryPipeline: critic returned empty for "${input.meetingTitle}"; '
          'keeping the unchecked draft.',
        );
      } else {
        text = checked;
      }
    } else {
      // Not a failure: even the ledger + this draft does not fit. Skip it rather
      // than fail the summary.
      debugPrint(
        'SummaryPipeline: skipping the critic pass — even the ledger '
        '(${estimateTokens(ledger)} est. tokens) plus the draft '
        '(${estimateTokens(draft)}) does not fit ${backend.modelId}\'s '
        '$composeWindow-token compose window.',
      );
    }

    // Deterministic carry-through: re-attach the note classes a 2B loses in the
    // fold. Append each as its own heading block; _normalizeOutput then MERGES the
    // (now possibly duplicate) headings and dedupes body lines.
    //   • LOW CONFIDENCE — always append; the scorer needs the terms UNDER a
    //     low-confidence heading, so re-list them there even if mentioned elsewhere
    //     (normalize drops exact repeats).
    //   • CONTINUITY & SPECIFICS — presence-AWARE: only re-add the item when its
    //     distinctive content (an ID, a quoted term, a number, a phrase) is absent
    //     from the whole draft. This restores what the model dropped without
    //     bloating a good summary with things it already wove in.
    text = _appendClassBlock(
      text,
      carriedLowConf,
      '## ⚠️ Low confidence',
      presenceAware: false,
    );
    text = _appendClassBlock(
      text,
      carriedContinuity,
      '## People & continuity',
      presenceAware: false,
    );
    text = _appendClassBlock(
      text,
      carriedSpecifics,
      '## Other key details',
      presenceAware: true,
    );

    // Typography pass: strip gemma's "▁" markers AND merge the duplicate headings
    // the carry-through just created into a single clean section.
    text = _normalizeOutput(text);

    // Fallback: the notes claimed uncertainty but nothing survived even the
    // carry-through (e.g. the map's LOW CONFIDENCE lines were themselves empty).
    // Warn rather than ship false certainty (CLAUDE.md: no silent degradation).
    if (hadUncertainty &&
        carriedLowConf.isEmpty &&
        !_mentionsLowConfidence(text)) {
      text = '$text$kLowConfidenceDroppedNotice';
    }
    if (compressed) text = '$text$kCompressionNotice';

    cancel?.throwIfCancelled();
    reporter.done();
    return SummaryResult(
      text: text,
      modelId: backend.modelId,
      processingTime: sw.elapsed,
    );
  }
}

/// The content lines sitting under a given note [heading] (e.g. 'LOW CONFIDENCE',
/// 'CONTINUITY') across every note group, deduped. Used to carry a class through
/// the pipeline mechanically instead of trusting the model to preserve it.
List<String> _noteClassLines(String notes, String heading) {
  final out = <String>[];
  String? current;
  for (final line in notes.split('\n')) {
    if (_isGroupHeader(line) && _noteHeading(line) == null) {
      current = null;
      continue;
    }
    final h = _noteHeading(line);
    if (h != null) {
      current = h;
      continue;
    }
    if (line.trim().isEmpty) continue;
    if (current == heading) out.add(line.trim());
  }
  final seen = <String>{};
  final deduped = <String>[];
  for (final l in out) {
    final key = l.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (key.length < 3 || seen.add(key)) deduped.add(l);
  }
  return deduped;
}

/// Append [lines] under [docHeading] as a fresh block. A no-op when [lines] is
/// empty. The caller runs [_normalizeOutput] afterwards, which merges this block
/// into any same-named heading the model already emitted and drops duplicate
/// body lines.
///
/// When [presenceAware], a line whose distinctive content ([_contentPresent]) is
/// already anywhere in [text] is skipped — so a specific the reduce already wove
/// into a topic section is not duplicated in the appended block. Low-confidence
/// uses presenceAware:false because the scorer (and the reader) want the terms
/// listed UNDER the low-confidence heading even if they also appear elsewhere.
String _appendClassBlock(
  String text,
  List<String> lines,
  String docHeading, {
  required bool presenceAware,
}) {
  if (lines.isEmpty) return text;
  final low = text.toLowerCase();
  final add = presenceAware
      ? lines.where((l) => !_contentPresent(low, l)).toList()
      : lines;
  if (add.isEmpty) return text;
  final body = add.map((l) => l.startsWith('-') ? l : '- $l').join('\n');
  return '$text\n\n$docHeading\n$body';
}

/// Digit strings dictated one-at-a-time in the transcript ("6 5 7 6 6", "4 4 9 0
/// 2 1") — an ID or number read out digit by digit, which ASR renders spaced and
/// a 2B fails to flag. Returns them as low-confidence lines with the joined form
/// marked (heard, unverified). Requires >=4 digits so a short "3 4 5" list of
/// quantities is not swept up.
List<String> _detectSpacedDigits(String transcript) {
  final out = <String>[];
  final seen = <String>{};
  for (final m in RegExp(r'\b\d(?:[ .]\d){3,}\b').allMatches(transcript)) {
    final spoken = m.group(0)!;
    final joined = spoken.replaceAll(RegExp(r'[ .]'), '');
    if (seen.add(joined)) {
      out.add('"$spoken" -> $joined (heard, unverified)');
    }
  }
  return out;
}

/// The transcript-based safety net for the SINGLE-PASS path (short meeting on a
/// 2B, or a big-window / cloud backend). No map notes to carry, but a model
/// reading a long transcript in one shot still drops figures, misses a dictated
/// ID, or buries the end-of-meeting handoff — so run the same sweeps map-reduce
/// uses: spaced digits -> low confidence, absence/handoff phrases -> continuity,
/// figure sweep -> key details. [mapNotes] lets the map-reduce path reuse this
/// too (it currently inlines the equivalent), combining notes + sweeps.
String _mechanicalSafetyNet({
  required String text,
  required String transcript,
  required List<PromptSegment> segments,
  String? mapNotes,
}) {
  final lowConf = <String>[
    if (mapNotes != null) ..._noteClassLines(mapNotes, 'LOW CONFIDENCE'),
    ..._detectSpacedDigits(transcript),
  ];
  final continuity = <String>[
    if (mapNotes != null) ..._noteClassLines(mapNotes, 'CONTINUITY'),
    ..._detectContinuity(segments),
  ];
  final specifics = <String>[
    if (mapNotes != null) ..._noteClassLines(mapNotes, 'SPECIFICS'),
    ..._sweepFigures(transcript),
  ];
  var t = _appendClassBlock(
    text,
    lowConf,
    '## ⚠️ Low confidence',
    presenceAware: false,
  );
  t = _appendClassBlock(
    t,
    continuity,
    '## People & continuity',
    presenceAware: false,
  );
  t = _appendClassBlock(
    t,
    specifics,
    '## Other key details',
    presenceAware: true,
  );
  return _normalizeOutput(t);
}

/// High-salience figures from the transcript — money ($4.2 million, $3.75),
/// percentages (10 percent, 3.1%) and unit quantities (24-unit, case of 24) —
/// captured WITH a couple of trailing words so a phrase like "10 percent lift"
/// survives. Independent of the map, so it recovers a figure the 2B never
/// extracted. Carried presence-aware, so only figures missing from the draft are
/// added.
///
/// The cap SCALES with transcript length. A 25-minute standup should not sprout a
/// 40-line figures dump, but a 6-hour deposition or prod war room genuinely has
/// hundreds of load-bearing numbers (dollar amounts, dates, exhibit/ticket IDs)
/// and a lawyer or on-call engineer cannot silently lose any — that is the whole
/// value at extreme length. ~1 per 400 words, floor 40, ceiling 400.
List<String> _sweepFigures(String transcript) {
  final words = transcript.split(RegExp(r'\s+')).length;
  final cap = (words ~/ 400).clamp(40, 400);
  // Money / percentages / quantities / latencies / durations, each with an
  // optional trailing word for context ("10 percent lift"), PLUS calendar dates
  // (a deposition lives on dates). Broad on purpose: at legal / war-room length,
  // a dropped figure or date is the failure the whole feature exists to prevent.
  final re = RegExp(
    r'(?:\$\s?\d[\d,]*(?:\.\d+)?(?:\s?(?:million|billion|thousand|k|bn))?'
    r'|\b\d[\d,]*(?:\.\d+)?\s?(?:%|percent|per cent|million|billion|thousand|'
    r'bps|basis points|units?|packs?|cases?|boxes|count|ms|milliseconds?|'
    r'seconds?|secs?|minutes?|mins?|hours?|days?|weeks?|months?|years?|'
    r'requests?|customers?|tickets?|nodes?|messages?|dollars?|cents?|gb|mb|tb)'
    r'|\b(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|'
    r'jul(?:y)?|aug(?:ust)?|sep(?:t|tember)?|oct(?:ober)?|nov(?:ember)?|'
    r'dec(?:ember)?)\s+\d{1,2}(?:st|nd|rd|th)?(?:,?\s+\d{4})?'
    r'|\b\d{1,2}/\d{1,2}/\d{2,4})'
    r'(?:\s+(?:of\s+)?[A-Za-z][A-Za-z-]{2,}(?:\s+[A-Za-z][A-Za-z-]{2,})?)?',
    caseSensitive: false,
  );
  final out = <String>[];
  final seen = <String>{};
  for (final m in re.allMatches(transcript)) {
    final figure = m.group(0)!.trim();
    // Must contain a digit and be substantive (drop bare "% of the").
    if (!RegExp(r'\d').hasMatch(figure) || figure.length < 2) continue;
    final key = figure.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (!seen.add(key)) continue;
    out.add(figure);
    if (out.length >= cap) break;
  }
  return out;
}

/// Segments that carry a strong absence / leave / handoff / deadline signal — the
/// continuity items a 2B most often fails to tag on a long meeting because they
/// are social asides at the end. Conservative on purpose: only unambiguous
/// phrases, so we do not fabricate an absence. Returns "<speaker>: <excerpt>
/// [mm:ss]" lines for the carry-through.
final RegExp _kContinuitySignal = RegExp(
  r'\b(having surgery|out (?:next|starting|for|of|on)\b|on (?:medical |maternity |paternity )?leave|maternity|paternity|sick leave|reach out to |cover(?:ing)? for |my last day|last day (?:is|will)|stepping (?:down|away)|out of office|be out (?:of|for|next)|back (?:on|next) |won.t be (?:here|around|available)|hand(?:ing|ed)? (?:this |it )?(?:off|over) to |taking over |deadline|due (?:by|on)|(?:by|before|due|no later than|end of|eod) (?:next )?(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday|end of (?:day|week|month|quarter)))',
  caseSensitive: false,
);

List<String> _detectContinuity(List<PromptSegment> segments) {
  final out = <String>[];
  final seen = <String>{};
  for (final s in segments) {
    if (!_kContinuitySignal.hasMatch(s.text)) continue;
    final excerpt = s.text.length > 180
        ? '${s.text.substring(0, 180)}…'
        : s.text.trim();
    final key = excerpt.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (key.length < 6 || !seen.add(key)) continue;
    final ts = s.startMs != null ? ' [${formatTimestamp(s.startMs!)}]' : '';
    final who = s.speaker != null ? '${s.speaker}: ' : '';
    out.add('$who$excerpt$ts');
  }
  return out;
}

/// True if [line]'s distinctive content already appears in [lowText] (lowercased
/// draft). Heuristic, tuned to avoid re-adding a fact the model already kept:
/// a quoted term, every 3+ digit run, or a distinctive prefix slice.
bool _contentPresent(String lowText, String line) {
  final l = line.toLowerCase();
  final q = RegExp(r'["“”\x27]([^"“”\x27]{2,})["“”\x27]').firstMatch(l);
  if (q != null && lowText.contains(q.group(1)!.trim())) return true;
  final digits = RegExp(
    r'\d{3,}',
  ).allMatches(l).map((m) => m.group(0)!).toList();
  if (digits.isNotEmpty && digits.every(lowText.contains)) return true;
  final core = l
      .replaceAll(RegExp(r'\[\d[\d:]*\]'), '')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
      .trim();
  if (core.length >= 12) {
    final probe = core.length > 28 ? core.substring(0, 28) : core;
    if (lowText.contains(probe)) return true;
  }
  return false;
}

/// Part headers keep the reduce stage able to honour "consecutive segments
/// overlap, so some notes are duplicates" — without them the model cannot tell
/// which notes are adjacent.
String _labelledNote(String note, int part, int total, TranscriptChunk chunk) {
  final range = (chunk.startMs != null && chunk.endMs != null)
      ? ' [${formatTimestamp(chunk.startMs!)}-${formatTimestamp(chunk.endMs!)}]'
      : '';
  return '### Notes — part $part of $total$range\n$note';
}

/// Remove verbatim-duplicate CONTENT lines across note groups, keeping the first.
/// A 2B repeats the same finding in every chunk it appears in and does not dedupe
/// them at reduce time (that is synthesis, which it fails); doing it mechanically
/// here means the reduce sees each finding once. Headings and group headers are
/// never dropped — only body lines, compared on their text with any trailing
/// [mm:ss] stripped so "X [00:21]" and "X [01:03]" count as one.
List<String> _dedupeNoteLines(List<String> notes) {
  final seen = <String>{};
  final out = <String>[];
  for (final group in notes) {
    final kept = <String>[];
    for (final line in group.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty ||
          _isGroupHeader(line) ||
          _noteHeading(line) != null) {
        kept.add(line);
        continue;
      }
      final key = trimmed
          .replaceAll(RegExp(r'\[\d{1,2}:\d{2}(?::\d{2})?\]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .toLowerCase()
          .trim();
      if (key.length < 8 || seen.add(key)) kept.add(line);
    }
    out.add(kept.join('\n'));
  }
  return out;
}

/// Final cleanup a small model reliably needs and the pipeline can do for free:
///   * strip the SentencePiece "▁" space-marker that leaks into gemma output,
///   * collapse a heading the model emitted more than once (it split "## Low
///     confidence" into three on the reference run) into its first occurrence,
///     moving the later bodies up under it.
/// Neither invents or removes a finding — this is typography, not editing.
String _normalizeOutput(String text) {
  var t = text.replaceAll('▁', ' ').replaceAll(RegExp(r' {2,}'), ' ');

  final lines = t.split('\n');
  final order = <String>[]; // heading text in first-seen order
  final bodies = <String, List<String>>{};
  final preamble = <String>[];
  String? current;

  String norm(String h) =>
      h.replaceFirst(RegExp(r'^#+\s*'), '').trim().toLowerCase();

  for (final line in lines) {
    if (RegExp(r'^#{1,6}\s').hasMatch(line.trimLeft())) {
      final key = norm(line);
      current = key;
      if (!bodies.containsKey(key)) {
        order.add(key);
        bodies[key] = [line]; // keep the first heading's exact casing/emoji
      }
      // A duplicate heading contributes only its body, not a second header line.
      continue;
    }
    if (current == null) {
      preamble.add(line);
    } else {
      bodies[current]!.add(line);
    }
  }
  if (order.isEmpty) return t.trim();

  final buf = <String>[...preamble];
  for (final key in order) {
    final body = bodies[key]!;
    buf.add(body.first); // the heading, exact casing preserved
    final seen = <String>{};
    for (var i = 1; i < body.length; i++) {
      final line = body[i];
      final dedupKey = line
          .trim()
          .replaceAll(RegExp(r'\[\d{1,2}:\d{2}(?::\d{2})?\]'), '')
          .replaceAll(RegExp(r'[*_>#-]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .toLowerCase()
          .trim();
      // Short/blank lines (bullets, spacers) are never deduped — only substantive
      // repeats like the model emitting "must buy 24 pack [17:49]" twice.
      if (dedupKey.length < 8 || seen.add(dedupKey)) buf.add(line);
    }
  }
  return buf.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

/// Same, for a folded group. The reduce prompt is told the notes come from
/// consecutive segments; after a fold they come from consecutive GROUPS of
/// segments, and saying so keeps the dedupe instruction meaningful.
String _labelledFold(String note, int group, int total) =>
    '### Condensed notes — group $group of $total\n$note';

/// Greedily pack whole notes into batches that fit [budget]. A note is never
/// split here: a half-note loses the heading it lives under, and the fold prompt
/// is written against complete notes. A single note bigger than the budget is
/// passed through alone and trimmed at the call site.
List<String> _batch(List<String> notes, int budget) {
  final batches = <String>[];
  final buf = StringBuffer();
  var tokens = 0;
  for (final n in notes) {
    final cost = estimateTokens(n) + 2; // the blank line that joins them
    if (buf.isNotEmpty && tokens + cost > budget) {
      batches.add(buf.toString());
      buf.clear();
      tokens = 0;
    }
    if (buf.isNotEmpty) buf.write('\n\n');
    buf.write(n);
    tokens += cost;
  }
  if (buf.isNotEmpty) batches.add(buf.toString());
  return batches;
}

const String _kElision = '… (lower-value notes omitted to fit the window) …';

/// Which map heading a note line sits under, or null if this line is not a
/// heading. Tolerant of the decorations a small model adds ("**FACTS**", "FACTS:",
/// "## SPECIFICS") and deliberately strict otherwise — a bullet that merely
/// mentions a heading word ("- decisions were deferred") must not be mistaken for
/// the heading itself.
String? _noteHeading(String line) {
  final letters = line.replaceAll(RegExp(r'[^A-Za-z& ]'), '').trim();
  if (letters.isEmpty) return null;
  final normalized = letters.replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
  return kNoteHeadings.contains(normalized) ? normalized : null;
}

bool _isGroupHeader(String line) => line.trimLeft().startsWith('#');

/// Trim the notes to [budget] by evicting note LINES in [kNoteEvictionOrder] —
/// narration first, findings last.
///
/// This replaces a positional head-60%/tail-40% slice, which was the single
/// biggest quality bug in the rebuild: on a 25-minute meeting the elided "middle"
/// is the middle ten minutes, and with them went every BEHAVIOURS & LIMITS line
/// ("they always claim the max"; "the APTs are by promo by customer, so you can't
/// find one retailer in it") — the exact content reduceInstruction() names as
/// must-keep, and the exact content Granola kept and we dropped. The fold prompt
/// already promises the reduce that only FACTS get compressed; this makes the trim
/// honour the same promise instead of quietly violating it.
///
/// Falls back to [_trimHeadAndTail] when the model emitted no recognizable
/// headings at all — with nothing to prioritize by, a positional trim that keeps
/// the tail (where the surgery/handoff line lives) is still better than a head cut.
String _trimNotesToTokens(String text, int budget) {
  if (budget <= 0 || estimateTokens(text) <= budget) return text;

  final lines = text.split('\n');
  final section = List<String?>.filled(lines.length, null);
  final heading = List<bool>.filled(lines.length, false);
  final group = List<bool>.filled(lines.length, false);
  String? current;
  var sawHeading = false;

  for (var i = 0; i < lines.length; i++) {
    final h = _noteHeading(lines[i]);
    if (h != null) {
      current = h;
      heading[i] = true;
      sawHeading = true;
    } else if (_isGroupHeader(lines[i])) {
      // A new note group restarts the headings.
      current = null;
      group[i] = true;
    }
    section[i] = h ?? current;
  }
  if (!sawHeading) return _trimHeadAndTail(text, budget);

  final dropped = List<bool>.filled(lines.length, false);
  var used = estimateTokens(text) + estimateTokens(_kElision) + 1;

  // null first: lines the model emitted before any heading are unstructured
  // chatter, and the cheapest thing in the file to lose.
  for (final cls in <String?>[null, ...kNoteEvictionOrder]) {
    if (used <= budget) break;
    for (var i = 0; i < lines.length && used > budget; i++) {
      if (dropped[i] || heading[i] || group[i]) continue;
      if (lines[i].trim().isEmpty) continue;
      if (section[i] != cls) continue;
      dropped[i] = true;
      used -= estimateTokens(lines[i]) + 1;
    }
  }

  final kept = <String>[];
  for (var i = 0; i < lines.length; i++) {
    if (dropped[i]) continue;
    // An emptied heading is noise; drop it with its content.
    if (heading[i] && !_sectionHasSurvivor(i, lines, dropped, heading, group)) {
      continue;
    }
    kept.add(lines[i]);
  }
  kept.add(_kElision);

  final out = kept.join('\n');
  // Belt and braces. A meeting that is nothing but specifics can still be over
  // budget with every droppable line already gone, and handing the backend a
  // prompt that overflows its window is the bug this whole pipeline exists to
  // fix. Never return something the caller cannot send.
  return estimateTokens(out) > budget ? _trimHeadAndTail(out, budget) : out;
}

/// Does the section opened at [i] still have any content line left?
bool _sectionHasSurvivor(
  int i,
  List<String> lines,
  List<bool> dropped,
  List<bool> heading,
  List<bool> group,
) {
  for (var j = i + 1; j < lines.length; j++) {
    if (heading[j] || group[j]) return false;
    if (!dropped[j] && lines[j].trim().isNotEmpty) return true;
  }
  return false;
}

/// Positional last-resort trim, on line boundaries.
///
/// Keeps the HEAD and the TAIL and elides the middle, because the tail is
/// exactly where the item Granola dropped lives — absences, handoffs and
/// coverage are said as the call is breaking up. A head-only truncation would
/// reproduce that failure by construction. Only reached when the notes have no
/// parseable structure to prioritize by.
String _trimHeadAndTail(String text, int budget) {
  if (budget <= 0 || estimateTokens(text) <= budget) return text;

  const marker = '\n… (some notes omitted to fit the model window) …\n';
  final remaining = budget - estimateTokens(marker);
  if (remaining <= 0) return marker;

  final lines = text.split('\n');
  final headBudget = (remaining * 0.6).floor();
  final tailBudget = remaining - headBudget;

  final head = <String>[];
  var used = 0;
  for (final line in lines) {
    final cost = estimateTokens(line) + 1;
    if (used + cost > headBudget) break;
    head.add(line);
    used += cost;
  }

  final tail = <String>[];
  used = 0;
  for (var i = lines.length - 1; i >= head.length; i--) {
    final cost = estimateTokens(lines[i]) + 1;
    if (used + cost > tailBudget) break;
    tail.insert(0, lines[i]);
    used += cost;
  }

  return '${head.join('\n')}$marker${tail.join('\n')}';
}

/// The note lines the critic is authoritative for ([kCriticLedgerHeadings]),
/// under their headings. Drops the group headers, FACTS and OPEN QUESTIONS —
/// criticInstruction() never diffs against those, and they are most of the bulk.
/// criticInstruction() is explicitly told the notes may be a subset, so it may not
/// delete a draft line merely for being absent here.
String _criticLedger(String notes) {
  final lines = notes.split('\n');
  final out = <String>[];
  String? current;
  for (final line in lines) {
    if (_isGroupHeader(line) && _noteHeading(line) == null) {
      current = null;
      continue;
    }
    final h = _noteHeading(line);
    if (h != null) {
      current = h;
      if (kCriticLedgerHeadings.contains(h)) out.add(line);
      continue;
    }
    if (line.trim().isEmpty) continue;
    if (current != null && kCriticLedgerHeadings.contains(current)) {
      out.add(line);
    }
  }
  return out.join('\n').trim();
}

/// The highest-fidelity critic prompt that fits, or null when none does.
String? _fitCriticPrompt({
  required List<String> candidates,
  required String draft,
  required int systemTokens,
  required int budget,
}) {
  for (final notes in candidates) {
    final prompt = buildCriticPrompt(notes: notes, draft: draft);
    final tokens = systemTokens + estimateTokens(prompt) + _kReserveTokens;
    if (tokens <= budget) return prompt;
  }
  return null;
}

/// Did the extraction pass actually record uncertainty? Only then is a missing
/// Low-confidence section in the final document a problem.
bool _hasNoteSection(String notes, String heading) =>
    notes.split('\n').any((l) => _noteHeading(l) == heading);

bool _mentionsLowConfidence(String text) =>
    text.toLowerCase().contains('low confidence');

/// Monotonic progress reporter. The total is an estimate that only ever grows
/// (folds are discovered mid-run), and the step is clamped so the UI never shows
/// "part 9 of 7".
class _Progress {
  _Progress(this._sink, {required int totalSteps}) : _total = totalSteps;

  final void Function(SummaryProgress)? _sink;
  int _total;
  int _step = 0;

  void addSteps(int n) => _total += n;

  void emit(SummaryStage stage, String label) {
    final sink = _sink;
    if (sink == null) return;
    _step++;
    if (_step > _total) _total = _step;
    sink(
      SummaryProgress(
        stage: stage,
        step: _step,
        totalSteps: _total,
        label: label,
      ),
    );
  }

  void done() {
    final sink = _sink;
    if (sink == null) return;
    _step = _total;
    sink(
      SummaryProgress(
        stage: SummaryStage.done,
        step: _total,
        totalSteps: _total,
        label: 'Done',
      ),
    );
  }
}
