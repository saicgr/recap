import 'dart:typed_data';

import 'embedding_service.dart';

/// One chapter: a contiguous run of segments labeled with a heading.
class Chapter {
  final String title;
  final int startMs;
  final int endMs;
  final List<String> segmentIds;
  const Chapter({
    required this.title,
    required this.startMs,
    required this.endMs,
    required this.segmentIds,
  });
}

/// Heuristic auto-chapter detection (D14.7 / C4 in the plan). Combines three
/// signals from data we already have:
///   1. Speaker change (from Pyannote diarization output)
///   2. Silence gap > 3s (from VAD or segment timestamps)
///   3. Embedding-distance shift between adjacent segments (MiniLM cosine)
///
/// Scores each segment boundary, picks the top-k as chapter breaks (cap at
/// one chapter per ~5 min so we don't fragment short meetings). Title is
/// the first 4-6 salient words of the chapter's first segment — production
/// could route through Gemma for a real generated title.
class ChapterDetector {
  final EmbeddingService embeddings;
  final double embeddingShiftWeight;
  final double speakerChangeWeight;
  final double silenceGapWeight;
  final int minSilenceMsForBreak;
  final int minChapterDurationMs;

  ChapterDetector({
    required this.embeddings,
    this.embeddingShiftWeight = 1.0,
    this.speakerChangeWeight = 0.7,
    this.silenceGapWeight = 0.5,
    this.minSilenceMsForBreak = 3000,
    this.minChapterDurationMs = 90 * 1000, // 90s minimum chapter
  });

  Future<List<Chapter>> detect(
    List<({String id, int startMs, int endMs, String body, String? speaker})> segments,
  ) async {
    if (segments.length <= 1) {
      return [
        Chapter(
          title: _titleFrom(segments.isEmpty ? '' : segments.first.body),
          startMs: segments.isEmpty ? 0 : segments.first.startMs,
          endMs: segments.isEmpty ? 0 : segments.last.endMs,
          segmentIds: segments.map((s) => s.id).toList(),
        ),
      ];
    }

    // Pre-compute embeddings for all segments (parallelism not strictly
    // needed — MiniLM 384d is fast).
    //
    // embed() now THROWS when the MiniLM model is not installed, rather than
    // handing back a hash-of-the-text vector that looks like an embedding and
    // is not. So check first, and if it is unavailable, drop the embedding term
    // and score boundaries on speaker change + silence gap alone — a genuinely
    // weaker signal, rather than a confidently wrong one.
    final useEmbeddings = await embeddings.isReady();
    final vecs = <Float32List>[];
    if (useEmbeddings) {
      for (final s in segments) {
        vecs.add(await embeddings.embed(s.body));
      }
    }

    // Score each boundary i (between segment i-1 and i).
    final scores = <double>[];
    for (var i = 1; i < segments.length; i++) {
      final prev = segments[i - 1];
      final curr = segments[i];
      var s = 0.0;
      if (useEmbeddings) {
        final embDist = 1.0 - EmbeddingService.cosineSim(vecs[i - 1], vecs[i]);
        s += embeddingShiftWeight * embDist;
      }
      if (prev.speaker != null &&
          curr.speaker != null &&
          prev.speaker != curr.speaker) {
        s += speakerChangeWeight;
      }
      final gap = curr.startMs - prev.endMs;
      if (gap >= minSilenceMsForBreak) {
        s += silenceGapWeight * (gap / minSilenceMsForBreak).clamp(1.0, 3.0);
      }
      scores.add(s);
    }

    // Greedy pick: highest score wins, then enforce min-duration spacing.
    final indexed = List<({int i, double score})>.generate(
        scores.length, (idx) => (i: idx + 1, score: scores[idx]));
    indexed.sort((a, b) => b.score.compareTo(a.score));

    final breakPoints = <int>{0};
    for (final entry in indexed) {
      if (entry.score < 0.6) break; // threshold for "real" break
      final startMs = segments[entry.i].startMs;
      final tooClose = breakPoints.any((p) =>
          (segments[p].startMs - startMs).abs() < minChapterDurationMs);
      if (tooClose) continue;
      breakPoints.add(entry.i);
      // Cap chapter count at ~6 for usability.
      if (breakPoints.length >= 6) break;
    }

    final sortedBreaks = breakPoints.toList()..sort();
    final chapters = <Chapter>[];
    for (var b = 0; b < sortedBreaks.length; b++) {
      final start = sortedBreaks[b];
      final end =
          b + 1 < sortedBreaks.length ? sortedBreaks[b + 1] : segments.length;
      final slice = segments.sublist(start, end);
      chapters.add(Chapter(
        title: _titleFrom(slice.first.body),
        startMs: slice.first.startMs,
        endMs: slice.last.endMs,
        segmentIds: slice.map((s) => s.id).toList(),
      ));
    }
    return chapters;
  }

  String _titleFrom(String body) {
    final words = body.trim().split(RegExp(r'\s+'));
    final pick = words.take(6).join(' ');
    return pick.length > 60 ? '${pick.substring(0, 57)}…' : pick;
  }
}
