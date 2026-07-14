import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recap/data/database.dart';
import 'package:recap/services/folder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('folders', () {
    test('create, rename, nest', () async {
      final work = await svc.createFolder(name: 'Work');
      final sub = await svc.createFolder(name: 'Standups', parentId: work.id);

      expect((await svc.allFolders()).length, 2);
      expect((await svc.childrenOf(work.id)).single.id, sub.id);
      expect((await svc.childrenOf(null)).single.id, work.id);

      await svc.renameFolder(work.id, '  Work Stuff  ');
      final renamed =
          (await svc.allFolders()).firstWhere((f) => f.id == work.id);
      expect(renamed.name, 'Work Stuff', reason: 'name should be trimmed');
    });

    test('an empty folder name is rejected', () async {
      expect(() => svc.createFolder(name: '   '), throwsArgumentError);
    });

    test('a folder cannot be moved into its own descendant', () async {
      // Without this guard the tree contains a cycle, and every recursive walk
      // of it loops forever — the UI hangs with no way back out.
      final a = await svc.createFolder(name: 'A');
      final b = await svc.createFolder(name: 'B', parentId: a.id);
      final c = await svc.createFolder(name: 'C', parentId: b.id);

      await expectLater(svc.moveFolder(a.id, c.id), throwsArgumentError);
      await expectLater(svc.moveFolder(a.id, a.id), throwsArgumentError);

      // A legitimate move still works.
      await svc.moveFolder(c.id, a.id);
      expect((await svc.childrenOf(a.id)).map((f) => f.id),
          containsAll([b.id, c.id]));
    });

    test('deleting a folder promotes its children instead of destroying them',
        () async {
      final root = await svc.createFolder(name: 'Root');
      final mid = await svc.createFolder(name: 'Mid', parentId: root.id);
      final leaf = await svc.createFolder(name: 'Leaf', parentId: mid.id);

      await svc.deleteFolder(mid.id);

      final all = await svc.allFolders();
      expect(all.map((f) => f.id), containsAll([root.id, leaf.id]));
      expect(all.any((f) => f.id == mid.id), isFalse);
      // Silently deleting the subtree because the user removed one node is not
      // a trade anyone would accept.
      expect((await svc.childrenOf(root.id)).single.id, leaf.id);
    });
  });

  group('meeting assignment', () {
    test('assign, replace, and query by folder', () async {
      await seedMeeting('m1');
      final f1 = await svc.createFolder(name: 'F1');
      final f2 = await svc.createFolder(name: 'F2');

      await svc.setFoldersForMeeting('m1', {f1.id, f2.id});
      expect(await svc.foldersForMeeting('m1'), {f1.id, f2.id});
      expect((await svc.meetingsInFolder(f1.id)).single.id, 'm1');

      await svc.setFoldersForMeeting('m1', {f2.id});
      expect(await svc.foldersForMeeting('m1'), {f2.id});
      expect(await svc.meetingsInFolder(f1.id), isEmpty);
    });

    test('deleting a meeting cascades its folder + tag rows away', () async {
      await seedMeeting('m1');
      final f = await svc.createFolder(name: 'F');
      await svc.setFoldersForMeeting('m1', {f.id});
      await svc.setTagsForMeeting('m1', {'q3'});

      await (db.delete(db.meetings)..where((t) => t.id.equals('m1'))).go();

      expect(await db.select(db.meetingFolders).get(), isEmpty);
      expect(await db.select(db.meetingTags).get(), isEmpty);
      // The folder itself survives — only the association went.
      expect((await svc.allFolders()).single.id, f.id);
    });
  });

  group('tags', () {
    test('tags are trimmed, deduped, and blanks dropped', () async {
      await seedMeeting('m1');
      await svc.setTagsForMeeting('m1', {'  q3  ', 'q3', '', '   ', 'board'});
      expect(await svc.tagsForMeeting('m1'), {'q3', 'board'});
      expect(await svc.allTags(), ['board', 'q3']);
    });
  });

  group('migration from SharedPreferences', () {
    test('moves legacy folders/tags into Drift and clears the old keys',
        () async {
      await seedMeeting('m1');
      SharedPreferences.setMockInitialValues({
        'folders_v1': jsonEncode([
          {
            'id': 'legacy-1',
            'name': 'Legacy',
            'parentId': null,
            'colorIndex': 2,
            'createdAt': DateTime(2026, 1, 1).toIso8601String(),
          }
        ]),
        'meeting_folders_v1': jsonEncode({
          'm1': ['legacy-1'],
          // A meeting that no longer exists. Foreign keys are enforced now, so
          // inserting this would throw and abort the whole migration.
          'ghost': ['legacy-1'],
        }),
        'meeting_tags_v1': jsonEncode({
          'm1': ['q3'],
          'ghost': ['orphan'],
        }),
      });

      await svc.migrateFromPrefs();

      expect((await svc.allFolders()).single.name, 'Legacy');
      expect(await svc.foldersForMeeting('m1'), {'legacy-1'});
      expect(await svc.tagsForMeeting('m1'), {'q3'});
      // The dangling rows were dropped, not fatal.
      expect((await db.select(db.meetingFolders).get()).length, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('folders_v1'), isNull);
      expect(prefs.getBool('folders_migrated_to_drift_v1'), isTrue);
    });

    test('is idempotent — a second run does not duplicate', () async {
      await seedMeeting('m1');
      SharedPreferences.setMockInitialValues({
        'folders_v1': jsonEncode([
          {
            'id': 'legacy-1',
            'name': 'Legacy',
            'parentId': null,
            'colorIndex': 0,
            'createdAt': DateTime(2026, 1, 1).toIso8601String(),
          }
        ]),
      });

      await svc.migrateFromPrefs();
      await svc.migrateFromPrefs();

      expect((await svc.allFolders()).length, 1);
    });

    test('a clean install marks itself migrated without touching the db',
        () async {
      await svc.migrateFromPrefs();
      expect(await svc.allFolders(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('folders_migrated_to_drift_v1'), isTrue);
    });
  });
}
