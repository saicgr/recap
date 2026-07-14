import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recap/data/database.dart';
import 'package:recap/services/folder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The folder drawer is driven entirely by streams — if these are wrong, the
/// sidebar silently shows stale counts or the wrong meetings.
void main() {
  late AppDb db;
  late FolderService svc;

  setUp(() {
    db = AppDb.forTesting(NativeDatabase.memory());
    svc = FolderService(db: db);
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => db.close());

  Future<void> seedMeeting(String id) => db.into(db.meetings).insert(
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

  test('watchMeetingsInFolder emits only that folder, and updates live',
      () async {
    await seedMeeting('m1');
    await seedMeeting('m2');
    final work = await svc.createFolder(name: 'Work');
    final personal = await svc.createFolder(name: 'Personal');

    await svc.setFoldersForMeeting('m1', {work.id});
    await svc.setFoldersForMeeting('m2', {personal.id});

    expect(
      (await svc.watchMeetingsInFolder(work.id).first).map((m) => m.id),
      ['m1'],
    );

    // Filing m2 into Work must show up without a manual reload — the home list
    // subscribes to this stream.
    await svc.setFoldersForMeeting('m2', {personal.id, work.id});
    final ids = (await svc.watchMeetingsInFolder(work.id).first)
        .map((m) => m.id)
        .toSet();
    expect(ids, {'m1', 'm2'});
  });

  test('watchFolderCounts reports per-folder totals', () async {
    await seedMeeting('m1');
    await seedMeeting('m2');
    final a = await svc.createFolder(name: 'A');
    final b = await svc.createFolder(name: 'B');

    await svc.setFoldersForMeeting('m1', {a.id});
    await svc.setFoldersForMeeting('m2', {a.id});

    final counts = await svc.watchFolderCounts().first;
    expect(counts[a.id], 2);
    // An empty folder is simply absent from the map — the drawer renders it as
    // no badge rather than "0".
    expect(counts[b.id], isNull);
  });

  test('deleting a meeting drops it from the folder stream', () async {
    await seedMeeting('m1');
    final f = await svc.createFolder(name: 'F');
    await svc.setFoldersForMeeting('m1', {f.id});
    expect((await svc.watchMeetingsInFolder(f.id).first).length, 1);

    await (db.delete(db.meetings)..where((t) => t.id.equals('m1'))).go();

    // Relies on the foreign-key cascade actually being on.
    expect(await svc.watchMeetingsInFolder(f.id).first, isEmpty);
    expect(await svc.watchFolderCounts().first, isEmpty);
  });
}
