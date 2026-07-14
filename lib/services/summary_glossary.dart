import '../data/database.dart' show AppDb, TranscriptSegment;
import 'entity_extractor.dart';
import 'summarizer/token_estimator.dart';
import 'voiceprint_service.dart';

/// Hard caps on the glossary block. It rides in the system prompt of EVERY
/// map call, so its cost is multiplied by the chunk count: 300 tokens across
/// 7 chunks is 2,100 tokens of a 4k on-device window. Precision over recall.
const int kMaxGlossaryTerms = 40;
const int kMaxGlossaryTokens = 300;

/// What the summarizer needs to know about *this* meeting's vocabulary.
///
/// [terms] feeds `buildSystemPrompt(glossary: …)` ("prefer these exact
/// spellings"). [speakerAliases] feeds `buildPromptSegments(speakerAliases: …)`
/// so a diarization label can be rendered as the person's real name.
class GlossaryContext {
  final List<String> terms;
  final Map<String, String> speakerAliases;

  const GlossaryContext({
    required this.terms,
    required this.speakerAliases,
  });

  static const empty = GlossaryContext(terms: [], speakerAliases: {});

  bool get isEmpty => terms.isEmpty && speakerAliases.isEmpty;
}

/// Builds the glossary the summarizer uses to repair ASR damage.
///
/// **Read this before trusting it.** On a badly garbled transcript this often
/// returns NOTHING, and that is the designed behaviour, not a bug. The terms we
/// most want ("Scan Apps", "loyalty") arrive from Whisper lowercase and mangled
/// ("skin apps", "scan ups", "laurel T"), so a case-sensitive heuristic cannot see
/// them — and the alternative, a lowercase/fuzzy matcher, would flood the block
/// with junk. The glossary block instructs the model to "treat a near-miss in the
/// transcript as a mis-transcription of one of these terms", so a WRONG glossary
/// manufactures exactly the fabrications `kSystemPreamble` rule 2 forbids. Empty
/// beats wrong. What this reliably does deliver is stable spellings for acronyms
/// (RGM, APT, JBP), repeated proper-noun bigrams, and the people the user has
/// enrolled or curated. Rule 1 in `prompts.dart` is written to hold WITHOUT a
/// glossary: any repair inferred from context alone must be disclosed under Low
/// confidence.
///
/// Three sources, in trust order:
///  1. The user-curated `GlossaryTerms` Drift table — highest trust, never
///     dropped by the cap.
///  2. Enrolled voiceprint names — the people who show up across meetings, so
///     their names should be spelled the same way every time.
///  3. Entities pulled out of the transcript itself by [HeuristicEntityExtractor]
///     (no model download, always available).
///
/// **Why only PERSON/ORG entities and never MONEY or DATE.** The glossary block
/// tells the model to "treat a near-miss in the transcript as a mis-transcription
/// of one of these terms". That instruction is safe for proper nouns and actively
/// dangerous for numbers: listing "$8" would invite the model to snap a heard
/// "$18" onto it, which is precisely the fabrication `kSystemPreamble` rule 2
/// forbids ("never round a number, never complete a partial one, never 'fix' one
/// into a more plausible value"). Numbers must survive as heard; the prompt's
/// SPECIFICS/Low-confidence machinery is what handles them.
///
/// **Why extracted terms need [_minOccurrences] hits.** On a garbled ASR
/// transcript the capitalized-bigram heuristic mostly fires on sentence starts
/// ("Yeah Okay", "So So"). A single-occurrence match is noise, and a noisy
/// glossary is worse than no glossary — it manufactures the very repairs we are
/// trying to prevent. Requiring a repeat plus a stop-word filter means a bad
/// transcript yields an EMPTY extracted set rather than a wrong one. The same
/// floor is what keeps a one-off ASR acronym ("ISIS", "AUS") out of the block
/// while letting a real one through (RGM/APT/JBP recur).
class SummaryGlossary {
  SummaryGlossary({
    required this.db,
    required this.voiceprints,
    EntityExtractor? extractor,
  }) : _extractor = extractor ?? HeuristicEntityExtractor();

  final AppDb db;
  final VoiceprintService voiceprints;
  final EntityExtractor _extractor;

  /// Entity kinds worth putting in front of the model as spellings.
  static const _spellableKinds = {'PERSON', 'ORG'};

  /// An extracted term must appear at least this many times to be trusted.
  static const _minOccurrences = 2;

  /// First words that mark a capitalized bigram as a sentence-start artifact
  /// rather than a proper noun. Cheap, and it is what keeps "So Okay" out of a
  /// prompt that would otherwise be told to "prefer this exact spelling".
  static final Set<String> _leadingStopWords = _stopWordList.split(' ').toSet();

  static const _stopWordList = 'a about after all also am an and any are as at '
      'because been before but by can did do does for from good great had has '
      'have he her here his how i if in is it its just let like made make may '
      'me my no not now of off ok okay on one or our out over right she so '
      'some sorry sure thank thanks that the their them then there these they '
      'this those to up was we well were what when where which who why will '
      'with would yeah yes yet you your';

  Future<GlossaryContext> build({
    required String transcriptBody,
    required List<TranscriptSegment> segments,
    int maxTerms = kMaxGlossaryTerms,
    int maxTokens = kMaxGlossaryTokens,
  }) async {
    final curated = await _curatedTerms();
    final enrolled = await _enrolledNames();
    final extracted = await _extractedTerms(
      _corpus(transcriptBody, segments),
      exclude: {...curated, ...enrolled},
    );

    // Priority governs who survives the cap; the user's own terms never lose to
    // a heuristic guess. Within a priority band, longest-first: a longer term is
    // more specific and therefore a safer repair target.
    final ranked = <_Candidate>[
      for (final t in curated) _Candidate(t, 0),
      for (final n in enrolled) _Candidate(n, 1),
      for (final e in extracted) _Candidate(e, 2),
    ]..sort((a, b) {
        final byPriority = a.priority.compareTo(b.priority);
        if (byPriority != 0) return byPriority;
        return b.term.length.compareTo(a.term.length);
      });

    final kept = <String>[];
    final seen = <String>{};
    var tokens = 0;
    for (final c in ranked) {
      if (kept.length >= maxTerms) break;
      final key = c.term.toLowerCase();
      if (!seen.add(key)) continue;
      // +2 for the ", " join the prompt renders between terms.
      final cost = estimateTokens(c.term) + 2;
      if (tokens + cost > maxTokens) continue;
      tokens += cost;
      kept.add(c.term);
    }
    // Longest-first in the rendered block, so the model reads the most specific
    // spellings before the generic ones.
    kept.sort((a, b) => b.length.compareTo(a.length));

    return GlossaryContext(
      terms: List.unmodifiable(kept),
      speakerAliases: _speakerAliases(segments, enrolled),
    );
  }

  Future<List<String>> _curatedTerms() async {
    final rows = await db.select(db.glossaryTerms).get();
    return rows
        .map((r) => r.term.trim())
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<String>> _enrolledNames() async {
    final all = await voiceprints.all();
    return all
        .map((v) => v.name.trim())
        .where((n) => n.isNotEmpty)
        .toList(growable: false);
  }

  /// Prefer the segment bodies (they are what the model will actually read);
  /// fall back to the flat body when segmentation was never persisted.
  String _corpus(String transcriptBody, List<TranscriptSegment> segments) {
    if (segments.isEmpty) return transcriptBody;
    final joined = segments.map((s) => s.body).join('\n').trim();
    return joined.isEmpty ? transcriptBody : joined;
  }

  Future<List<String>> _extractedTerms(
    String corpus, {
    required Set<String> exclude,
  }) async {
    if (corpus.trim().isEmpty) return const [];
    final excluded = exclude.map((e) => e.toLowerCase()).toSet();

    final entities = await _extractor.extract(corpus);
    final counts = <String, int>{};
    final display = <String, String>{};
    for (final e in entities) {
      if (!_spellableKinds.contains(e.kind)) continue;
      final term = e.text.trim();
      if (!_isPlausibleTerm(term)) continue;
      final key = term.toLowerCase();
      if (excluded.contains(key)) continue;
      counts[key] = (counts[key] ?? 0) + 1;
      display.putIfAbsent(key, () => term);
    }

    return counts.entries
        .where((e) => e.value >= _minOccurrences)
        .map((e) => display[e.key]!)
        .toList(growable: false);
  }

  bool _isPlausibleTerm(String term) {
    if (term.length < 3 || term.length > 48) return false;
    final words = term.split(RegExp(r'\s+'));
    if (words.isEmpty) return false;
    if (_leadingStopWords.contains(words.first.toLowerCase())) return false;
    // "Speaker 1" and friends are diarization labels, not vocabulary.
    if (words.first.toLowerCase() == 'speaker') return false;
    return true;
  }

  /// Map diarization labels to enrolled names.
  ///
  /// Today this only *canonicalizes* a label that already carries a person's
  /// name (case/spacing drift), because nothing persists a `Speaker 1 -> Dana`
  /// mapping: `VoiceprintService.matchCentroid` has no caller, so
  /// `transcript_segments.speakerLabel` still holds raw `Speaker N` labels.
  /// Guessing which enrolled person is "Speaker 1" from nothing would be
  /// fabricated attribution — exactly what `kSystemPreamble` rule 4 forbids.
  /// When centroid matching is wired into the diarization step, labels become
  /// names and this map keeps their spelling stable across meetings.
  Map<String, String> _speakerAliases(
    List<TranscriptSegment> segments,
    List<String> enrolled,
  ) {
    if (enrolled.isEmpty) return const {};
    final byLower = {for (final n in enrolled) n.toLowerCase(): n};
    final out = <String, String>{};
    for (final s in segments) {
      final label = s.speakerLabel?.trim();
      if (label == null || label.isEmpty) continue;
      final canonical = byLower[label.toLowerCase()];
      if (canonical != null && canonical != label) out[label] = canonical;
    }
    return out;
  }
}

class _Candidate {
  final String term;
  final int priority;
  const _Candidate(this.term, this.priority);
}
