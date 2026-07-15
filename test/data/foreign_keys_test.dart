import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recap/data/database.dart';

/// SQLite turns foreign keys OFF by default, per connection, every time. The
/// schema declared `onDelete: cascade` in ten places and none of them did
/// anything: deleting a meeting silently orphaned its transcripts, segments,
/// summaries and bookmarks, and they accumulated forever.
void main() {
  late AppDb db;

  setUp(() => db = AppDb.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> seedMeeting(String id) async {
    await db
        .into(db.meetings)
        .insert(
          MeetingsCompanion.insert(
            id: id,
            title: 'Meeting $id',
            durationMs: const Value(1000),
            audioPath: '/tmp/$id.wav',
            createdAt: DateTime(2026, 7, 1),
            updatedAt: DateTime(2026, 7, 1),
            status: MeetingStatus.ready,
          ),
        );
    await db
        .into(db.transcripts)
        .insert(
          TranscriptsCompanion.insert(
            meetingId: id,
            body: 'hello',
            modelId: 'whisper',
            processingMs: const Value(10),
            createdAt: DateTime(2026, 7, 1),
          ),
        );
    await db
        .into(db.bookmarks)
        .insert(
          BookmarksCompanion.insert(
            id: 'bm-$id',
            meetingId: id,
            atMs: 500,
            createdAt: DateTime(2026, 7, 1),
          ),
        );
  }

  test('foreign_keys pragma is actually ON', () async {
    final rows = await db.customSelect('PRAGMA foreign_keys').get();
    expect(
      rows.first.data.values.first,
      1,
      reason: 'without this every onDelete: cascade is inert decoration',
    );
  });

  test('deleting a meeting cascades to its children', () async {
    await seedMeeting('m1');
    expect((await db.select(db.transcripts).get()).length, 1);
    expect((await db.select(db.bookmarks).get()).length, 1);

    await (db.delete(db.meetings)..where((t) => t.id.equals('m1'))).go();

    // Before the pragma, both of these were still sitting there.
    expect(await db.select(db.transcripts).get(), isEmpty);
    expect(await db.select(db.bookmarks).get(), isEmpty);
  });

  test('a child row referencing a missing parent is rejected', () async {
    await expectLater(
      db
          .into(db.transcripts)
          .insert(
            TranscriptsCompanion.insert(
              meetingId: 'does-not-exist',
              body: 'orphan',
              modelId: 'whisper',
              processingMs: const Value(1),
              createdAt: DateTime(2026, 7, 1),
            ),
          ),
      throwsA(anything),
      reason: 'FK enforcement should refuse an orphan at write time',
    );
  });

  test('deleting one meeting leaves another meeting intact', () async {
    // Guard against a cascade that is too enthusiastic — a "fix" that wiped
    // every child row would pass the test above.
    await seedMeeting('keep');
    await seedMeeting('drop');

    await (db.delete(db.meetings)..where((t) => t.id.equals('drop'))).go();

    final transcripts = await db.select(db.transcripts).get();
    expect(transcripts.length, 1);
    expect(transcripts.single.meetingId, 'keep');
  });
}
