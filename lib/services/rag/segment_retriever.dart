import 'dart:typed_data';

import 'package:drift/drift.dart';

import '../../data/database.dart';
import '../embedding_service.dart';
import 'embedding_indexer.dart';

/// One retrieved passage, with everything the UI needs to cite it.
class RetrievedSegment {
  const RetrievedSegment({
    required this.segmentId,
    required this.meetingId,
    required this.meetingTitle,
    required this.startMs,
    required this.endMs,
    required this.body,
    required this.score,
    this.speakerLabel,
  });

  final String segmentId;
  final String meetingId;
  final String meetingTitle;
  final int startMs;
  final int endMs;
  final String body;
  final String? speakerLabel;
  final double score;
}

/// Hybrid retrieval over the meeting corpus: keyword (FTS5/bm25) fused with
/// semantic (MiniLM cosine).
///
/// Neither alone is enough. Keyword search misses "what did we decide about
/// pricing" when the transcript says "we'll go with $49"; vector search misses
/// exact identifiers like a ticket number or a surname. Reciprocal Rank Fusion
/// combines the two rankings without needing their scores to be on the same
/// scale — which they emphatically are not (bm25 is unbounded, cosine is [-1,1]).
class SegmentRetriever {
  SegmentRetriever({required this.db, required this.embeddings});

  final AppDb db;
  final EmbeddingService embeddings;

  /// RRF constant. 60 is the value from the original paper and is not sensitive.
  static const _k = 60;

  Future<List<RetrievedSegment>> retrieve(
    String query, {
    int limit = 8,
    /// Restrict to one meeting (per-meeting chat) — null searches the corpus.
    String? meetingId,
    /// Meetings the user marked confidential. Excluded UNCONDITIONALLY when the
    /// answer may leave the device.
    Set<String> excludeMeetingIds = const {},
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final keyword = await _keywordRanking(q, meetingId: meetingId);
    final semantic = await _semanticRanking(q, meetingId: meetingId);

    // Reciprocal Rank Fusion: score = sum over rankers of 1 / (k + rank).
    final fused = <String, double>{};
    void fuse(List<String> ranking) {
      for (var i = 0; i < ranking.length; i++) {
        fused.update(ranking[i], (v) => v + 1.0 / (_k + i + 1),
            ifAbsent: () => 1.0 / (_k + i + 1));
      }
    }

    fuse(keyword);
    fuse(semantic);
    if (fused.isEmpty) return const [];

    final ordered = fused.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final out = <RetrievedSegment>[];
    for (final e in ordered) {
      if (out.length >= limit) break;
      final seg = await _hydrate(e.key, e.value);
      if (seg == null) continue;
      if (excludeMeetingIds.contains(seg.meetingId)) continue;
      out.add(seg);
    }
    return out;
  }

  /// FTS5 finds MEETINGS; we then take that meeting's best segments. The FTS
  /// index is built over whole transcripts, not per segment.
  Future<List<String>> _keywordRanking(String q, {String? meetingId}) async {
    final match = escapeFts5(q);
    if (match.isEmpty) return const [];

    final meetingIds = meetingId != null
        ? [meetingId]
        : (await db.searchRanked(q, limit: 10)).map((r) => r.meetingId).toList();
    if (meetingIds.isEmpty) return const [];

    // Within those meetings, rank segments by literal term overlap. Crude, but
    // it is the keyword half of the hybrid — the vector half handles meaning.
    final terms = q
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2)
        .toSet();
    final segs = await (db.select(db.transcriptSegments)
          ..where((s) => s.meetingId.isIn(meetingIds)))
        .get();

    final scored = <({String id, int hits})>[];
    for (final s in segs) {
      final body = s.body.toLowerCase();
      final hits = terms.where(body.contains).length;
      if (hits > 0) scored.add((id: s.id, hits: hits));
    }
    scored.sort((a, b) => b.hits.compareTo(a.hits));
    return scored.take(30).map((e) => e.id).toList();
  }

  /// Brute-force cosine over the vector index.
  ///
  /// No ANN index on purpose: a linear scan of 10k segments is a few
  /// milliseconds, and an approximate index would add a dependency, an index to
  /// maintain, and a sync complication for zero measurable gain at this corpus
  /// size.
  Future<List<String>> _semanticRanking(String q, {String? meetingId}) async {
    if (!await embeddings.isReady()) return const [];

    final Float32List qv;
    try {
      qv = await embeddings.embed(q);
    } catch (_) {
      // Semantic half unavailable — degrade to keyword-only rather than fail the
      // whole query.
      return const [];
    }

    final rows = await (db.select(db.segmentEmbeddings)
          ..where((e) => meetingId == null
              // Only OUR model's vectors. Mixing embedding spaces produces
              // confident nonsense, silently.
              ? e.model.equals(EmbeddingIndexer.modelId)
              : e.model.equals(EmbeddingIndexer.modelId) &
                  e.meetingId.equals(meetingId)))
        .get();
    if (rows.isEmpty) return const [];

    final scored = <({String id, double sim})>[];
    for (final r in rows) {
      if (r.dim != EmbeddingService.dim) continue; // width mismatch — skip
      final v = Float32List.view(
        Uint8List.fromList(r.vec).buffer,
        0,
        r.dim,
      );
      scored.add((id: r.segmentId, sim: EmbeddingService.cosineSim(qv, v)));
    }
    scored.sort((a, b) => b.sim.compareTo(a.sim));
    return scored.take(30).map((e) => e.id).toList();
  }

  Future<RetrievedSegment?> _hydrate(String segmentId, double score) async {
    final seg = await (db.select(db.transcriptSegments)
          ..where((s) => s.id.equals(segmentId)))
        .getSingleOrNull();
    if (seg == null) return null;
    final meeting = await (db.select(db.meetings)
          ..where((m) => m.id.equals(seg.meetingId)))
        .getSingleOrNull();
    if (meeting == null) return null;
    return RetrievedSegment(
      segmentId: seg.id,
      meetingId: seg.meetingId,
      meetingTitle: meeting.title,
      startMs: seg.startMs,
      endMs: seg.endMs,
      body: seg.body,
      speakerLabel: seg.speakerLabel,
      score: score,
    );
  }
}
