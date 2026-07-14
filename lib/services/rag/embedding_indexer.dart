import 'package:drift/drift.dart';

import '../../data/database.dart';
import '../embedding_service.dart';

/// Writes segment vectors into `SegmentEmbeddings`.
///
/// **Nothing has ever written to that table.** It has been in the schema since
/// the first commit, cascades were declared on it, the orphan sweep cleans it —
/// and it has always been empty. So "cross-meeting search over embeddings" and
/// "chat over your notes" had no index to search. This is that index.
///
/// Runs on the ROOT ISOLATE, deliberately. Both flutter_onnxruntime and Drift
/// are MethodChannel-bound and cannot be used from a background isolate. Only
/// the pure-Dart cosine scan (see [SegmentRetriever]) is safe to offload.
class EmbeddingIndexer {
  EmbeddingIndexer({required this.db, required this.embeddings});

  final AppDb db;
  final EmbeddingService embeddings;

  /// The model these vectors came from. Stored per row: mixing two embedding
  /// models in one index makes cosine similarity meaningless, and it fails
  /// silently — search just returns nonsense with no error anywhere.
  static const modelId = 'all-MiniLM-L6-v2';

  /// Index every not-yet-indexed segment of [meetingId].
  ///
  /// Idempotent: re-running skips segments that already have a vector from this
  /// model. Returns how many it wrote.
  ///
  /// Returns 0 (rather than throwing) when the MiniLM model is not installed —
  /// indexing is a background nicety, and a missing optional model must not fail
  /// a recording the user just finished. `embed()` itself still throws, so
  /// nothing fabricates a vector.
  Future<int> indexMeeting(String meetingId) async {
    if (!await embeddings.isReady()) return 0;

    final segments = await (db.select(db.transcriptSegments)
          ..where((s) => s.meetingId.equals(meetingId)))
        .get();
    if (segments.isEmpty) return 0;

    final existing = await (db.select(db.segmentEmbeddings)
          ..where((e) =>
              e.meetingId.equals(meetingId) & e.model.equals(modelId)))
        .get();
    final done = existing.map((e) => e.segmentId).toSet();

    var written = 0;
    for (final seg in segments) {
      if (done.contains(seg.id)) continue;
      final text = seg.body.trim();
      if (text.isEmpty) continue;

      final vec = await embeddings.embed(text);
      await db.into(db.segmentEmbeddings).insert(
            SegmentEmbeddingsCompanion.insert(
              segmentId: seg.id,
              meetingId: meetingId,
              vec: Uint8List.view(vec.buffer, 0, vec.lengthInBytes),
              dim: const Value(EmbeddingService.dim),
              model: const Value(modelId),
              createdAt: DateTime.now(),
            ),
            // A segment re-transcribed by a cloud accuracy pass keeps its id;
            // overwrite rather than fail.
            mode: InsertMode.insertOrReplace,
          );
      written++;
    }
    return written;
  }

  /// Meetings that have segments but no vectors — the backlog for everything
  /// recorded before this indexer existed.
  Future<List<String>> pendingMeetingIds({int limit = 20}) async {
    final rows = await db.customSelect(
      '''
      SELECT DISTINCT s.meeting_id AS id
      FROM transcript_segments s
      LEFT JOIN segment_embeddings e
        ON e.segment_id = s.id AND e.model = ?
      WHERE e.segment_id IS NULL
      LIMIT ?
      ''',
      variables: [const Variable<String>(modelId), Variable<int>(limit)],
      readsFrom: {db.transcriptSegments, db.segmentEmbeddings},
    ).get();
    return rows.map((r) => r.read<String>('id')).toList();
  }

  /// Work through the backlog. Best-effort: one bad meeting must not stall the
  /// rest, and this is never on a user-visible path.
  Future<int> backfill({int maxMeetings = 5}) async {
    if (!await embeddings.isReady()) return 0;
    var total = 0;
    for (final id in await pendingMeetingIds(limit: maxMeetings)) {
      try {
        total += await indexMeeting(id);
      } catch (_) {
        // Skip and continue — a single unembeddable meeting is not a reason to
        // leave the whole corpus unsearchable.
      }
    }
    return total;
  }
}
