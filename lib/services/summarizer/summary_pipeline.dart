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
      final out = text.trim();
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
      notes.add(_labelledNote(note, chunk.index + 1, chunk.total));
    }

    if (notes.isEmpty) {
      throw StateError(
        '${backend.modelId} extracted nothing from any of ${chunks.length} '
        'transcript parts of "${input.meetingTitle}". The model produced no '
        'notes at all — this is a backend failure, not an empty meeting.',
      );
    }

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
    final reduceScaffold = systemTokens +
        estimateTokens(buildReducePrompt(
          persona: persona,
          notes: '',
          meetingTitle: input.meetingTitle,
        )) +
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

    final foldScaffold = systemTokens +
        estimateTokens(buildFoldPrompt(notes: '')) +
        _kReserveTokens;
    final foldBudget = caps.maxInputTokens - foldScaffold;

    var compressed = false;
    for (var level = 0;
        level < _kMaxFoldLevels &&
            estimateTokens(notes.join('\n\n')) > notesBudget;
        level++) {
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
    ))
        .trim();
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
    final ledger = _criticLedger(joined);
    final criticPrompt = _fitCriticPrompt(
      candidates: [joined, if (ledger.isNotEmpty) ledger],
      draft: draft,
      systemTokens: systemTokens,
      budget: composeWindow,
    );
    if (criticPrompt != null) {
      reporter.emit(SummaryStage.checking, 'Checking for invented details...');
      final checked = (await backend.generate(
        prompt: criticPrompt,
        system: system,
        temperature: _kCriticTemperature,
        cancel: cancel,
      ))
          .trim();
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

    // The section this whole design exists to guarantee. If the notes recorded
    // uncertain terms and the finished document has no Low-confidence section,
    // the model dropped it — and its silence does not read as "detail was lost",
    // it reads as "nothing was uncertain". That is Granola's failure mode wearing
    // a different coat, and CLAUDE.md forbids the silent degradation that
    // produces it.
    if (hadUncertainty && !_mentionsLowConfidence(text)) {
      debugPrint(
        'SummaryPipeline: the notes carried LOW CONFIDENCE terms but '
        '${backend.modelId} emitted no Low-confidence section for '
        '"${input.meetingTitle}"; warning the user rather than shipping false '
        'certainty.',
      );
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

/// Part headers keep the reduce stage able to honour "consecutive segments
/// overlap, so some notes are duplicates" — without them the model cannot tell
/// which notes are adjacent.
String _labelledNote(String note, int part, int total) =>
    '### Notes — part $part of $total\n$note';

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
    sink(SummaryProgress(
      stage: stage,
      step: _step,
      totalSteps: _total,
      label: label,
    ));
  }

  void done() {
    final sink = _sink;
    if (sink == null) return;
    _step = _total;
    sink(SummaryProgress(
      stage: SummaryStage.done,
      step: _total,
      totalSteps: _total,
      label: 'Done',
    ));
  }
}
