import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../data/database.dart';
import '../../main.dart';

/// Common result shape from any importer.
class ImportedAudio {
  final String
  wavPath; // 16 kHz mono PCM WAV path, ready for transcribe pipeline
  final Duration duration;
  final String title;
  final DateTime sourceDate;

  /// Optional pre-existing transcript (e.g. YouTube captions); when non-null
  /// the transcribe pipeline skips Whisper and persists this directly.
  final String? precomputedTranscript;

  /// Optional pre-existing segments (start/end ms + body) for precomputed
  /// transcripts that have timing.
  final List<({int startMs, int endMs, String body})>? precomputedSegments;

  const ImportedAudio({
    required this.wavPath,
    required this.duration,
    required this.title,
    required this.sourceDate,
    this.precomputedTranscript,
    this.precomputedSegments,
  });
}

/// Persist an ImportedAudio as a new Meeting row + (optionally) precomputed
/// transcript + segments. Returns the new meeting ID.
Future<String> persistImportedMeeting(ImportedAudio imported) async {
  final id = const Uuid().v4();
  final now = DateTime.now();
  final status = imported.precomputedTranscript == null
      ? MeetingStatus.processing
      : MeetingStatus.ready;

  await db
      .into(db.meetings)
      .insert(
        MeetingsCompanion.insert(
          id: id,
          title: imported.title,
          audioPath: imported.wavPath,
          createdAt: imported.sourceDate,
          updatedAt: now,
          status: status,
          durationMs: Value(imported.duration.inMilliseconds),
          language: const Value('auto'),
        ),
      );

  // Precomputed transcript (e.g. YouTube caption track) — skip Whisper.
  if (imported.precomputedTranscript != null) {
    await db
        .into(db.transcripts)
        .insertOnConflictUpdate(
          TranscriptsCompanion.insert(
            meetingId: id,
            body: imported.precomputedTranscript!,
            modelId: 'imported',
            createdAt: now,
          ),
        );
    final segs = imported.precomputedSegments;
    if (segs != null && segs.isNotEmpty) {
      await db.batch((batch) {
        for (final s in segs) {
          batch.insert(
            db.transcriptSegments,
            TranscriptSegmentsCompanion.insert(
              id: const Uuid().v4(),
              meetingId: id,
              startMs: s.startMs,
              endMs: s.endMs,
              body: s.body,
              isFinal: const Value(true),
            ),
          );
        }
      });
    }
  }

  return id;
}
