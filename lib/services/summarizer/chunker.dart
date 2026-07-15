import 'dart:math' as math;

import 'summary_types.dart';
import 'token_estimator.dart';
import 'transcript_formatter.dart';

/// Trailing context carried from one chunk into the next so a thought spanning a
/// boundary ("...it's funded as US trade" / "6 5 7 6 6") is not cut in half and
/// lost. The reduce prompt is told chunks overlap and to dedupe.
const int kDefaultOverlapTokens = 120;

/// One unit of work for the map stage.
///
/// [index] is 0-based; [total] is the chunk count. [startMs]/[endMs] span the
/// rendered content (including any carried overlap) and are null when the
/// transcript has no timing at all.
class TranscriptChunk {
  final int index;
  final int total;
  final int? startMs;
  final int? endMs;
  final String text;

  /// True when [text] opens with lines repeated from the previous chunk.
  final bool hasOverlap;

  const TranscriptChunk({
    required this.index,
    required this.total,
    required this.text,
    this.startMs,
    this.endMs,
    this.hasOverlap = false,
  });
}

const _overlapHeader =
    '(Context from the previous part — already extracted, for continuity only:)';
const _overlapDivider = '--- New material for this part starts here ---';

/// Greedily pack segments into chunks of at most [targetTokens].
///
/// Segments are never split mid-segment — a segment is one speaker's turn and
/// splitting it orphans the speaker label and the timestamp from half the words.
/// The single exception is a segment larger than [targetTokens] on its own, which
/// is hard-split on sentence boundaries (words as a last resort); the pieces keep
/// the parent's speaker and timing, so citations stay honest to within one turn.
List<TranscriptChunk> chunkSegments(
  List<PromptSegment> segs, {
  required int targetTokens,
  int overlapTokens = kDefaultOverlapTokens,
}) {
  if (targetTokens <= 0) {
    throw ArgumentError.value(
      targetTokens,
      'targetTokens',
      'must be > 0 — the caller computed a non-positive budget, which means the '
          'system prompt + instruction already exceed the backend context window',
    );
  }
  if (segs.isEmpty) {
    throw StateError('chunkSegments: nothing to chunk (no segments).');
  }

  // Overlap must never eat the whole budget, or a chunk could be all overlap and
  // the packer would never advance.
  final overlap = math.max(0, math.min(overlapTokens, targetTokens ~/ 4));

  final units = <PromptSegment>[];
  for (final s in segs) {
    units.addAll(_fitToBudget(s, targetTokens));
  }

  final packed = <List<PromptSegment>>[];
  final overlapCounts = <int>[];

  var current = <PromptSegment>[];
  var currentTokens = 0;
  var currentOverlap = 0;

  for (final u in units) {
    final cost = _cost(u);
    // `current.length > currentOverlap` == "this chunk holds at least one NEW
    // unit". Without it, a chunk seeded with overlap could be flushed empty of
    // new material and we would loop forever on the same unit.
    final wouldOverflow = currentTokens + cost > targetTokens;
    if (wouldOverflow && current.length > currentOverlap) {
      packed.add(current);
      overlapCounts.add(currentOverlap);

      final tail = _tail(current, overlap);
      final tailTokens = tail.fold<int>(0, (a, u) => a + _cost(u));
      // If the carried tail plus the next unit cannot fit, carry nothing rather
      // than emit an over-budget chunk.
      if (tailTokens + cost <= targetTokens) {
        current = [...tail];
        currentTokens = tailTokens;
        currentOverlap = tail.length;
      } else {
        current = [];
        currentTokens = 0;
        currentOverlap = 0;
      }
    }
    current.add(u);
    currentTokens += cost;
  }
  if (current.length > currentOverlap) {
    packed.add(current);
    overlapCounts.add(currentOverlap);
  }

  return [
    for (var i = 0; i < packed.length; i++)
      _render(packed[i], overlapCounts[i], i, packed.length),
  ];
}

/// Rendered cost of a unit, including the newline that joins it to its
/// neighbour.
int _cost(PromptSegment u) => estimateTokens(renderSegment(u)) + 1;

List<PromptSegment> _tail(List<PromptSegment> chunk, int overlapTokens) {
  if (overlapTokens <= 0) return const [];
  final tail = <PromptSegment>[];
  var tokens = 0;
  for (var i = chunk.length - 1; i >= 0; i--) {
    final c = _cost(chunk[i]);
    if (tokens + c > overlapTokens) break;
    tail.insert(0, chunk[i]);
    tokens += c;
  }
  return tail;
}

TranscriptChunk _render(
  List<PromptSegment> units,
  int overlapCount,
  int index,
  int total,
) {
  final text = overlapCount == 0
      ? renderSegments(units)
      : [
          _overlapHeader,
          renderSegments(units.take(overlapCount).toList(growable: false)),
          _overlapDivider,
          renderSegments(units.skip(overlapCount).toList(growable: false)),
        ].join('\n');

  int? start;
  int? end;
  for (final u in units) {
    start ??= u.startMs;
    if (u.endMs != null) end = u.endMs;
  }

  return TranscriptChunk(
    index: index,
    total: total,
    startMs: start,
    endMs: end,
    text: text,
    hasOverlap: overlapCount > 0,
  );
}

/// Split a segment that alone exceeds the budget. Sentence seams first, word
/// seams if a single "sentence" (ASR rarely punctuates) is still too big. Each
/// piece inherits the parent's speaker and timing: the citation is then accurate
/// to the turn, which is the granularity the transcript UI seeks to anyway.
List<PromptSegment> _fitToBudget(PromptSegment s, int targetTokens) {
  if (_cost(s) <= targetTokens) return [s];

  // Budget for the text alone, minus what the `[mm:ss] Speaker:` prefix costs.
  final prefixCost =
      _cost(
        PromptSegment(
          speaker: s.speaker,
          startMs: s.startMs,
          endMs: s.endMs,
          text: '',
        ),
      ) +
      1;
  final textBudget = math.max(16, targetTokens - prefixCost);

  final pieces = <String>[];
  final buf = StringBuffer();
  for (final sentence in splitSentences(s.text)) {
    for (final part in _splitToBudget(sentence, textBudget)) {
      if (buf.isNotEmpty &&
          estimateTokens('${buf.toString()} $part') > textBudget) {
        pieces.add(buf.toString());
        buf.clear();
      }
      if (buf.isNotEmpty) buf.write(' ');
      buf.write(part);
    }
  }
  if (buf.isNotEmpty) pieces.add(buf.toString());

  return [
    for (final p in pieces)
      PromptSegment(
        speaker: s.speaker,
        startMs: s.startMs,
        endMs: s.endMs,
        text: p,
      ),
  ];
}

/// Break one sentence on word boundaries when it alone busts the budget. A
/// single word wider than the budget is emitted as-is — refusing to summarize
/// over it would be worse than one slightly-over chunk.
List<String> _splitToBudget(String sentence, int budget) {
  if (estimateTokens(sentence) <= budget) return [sentence];
  final out = <String>[];
  final buf = StringBuffer();
  for (final word in sentence.split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    if (buf.isNotEmpty && estimateTokens('${buf.toString()} $word') > budget) {
      out.add(buf.toString());
      buf.clear();
    }
    if (buf.isNotEmpty) buf.write(' ');
    buf.write(word);
  }
  if (buf.isNotEmpty) out.add(buf.toString());
  return out;
}
