import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/database.dart';

/// Folders + tags, backed by Drift.
///
/// The Folders / MeetingFolders / MeetingTags tables have existed in the schema
/// the whole time; this service used to ignore them and keep everything as JSON
/// blobs in SharedPreferences, with no UI anywhere. That meant folders could not
/// participate in a join, could not cascade on meeting delete, and could never
/// sync.
///
/// This is also the feature Granola's mobile app cannot do at all — it shows
/// "Folders will appear here after they are synced", because its folders live on
/// a server. Ours are local-first, so they work offline and with no account.
class FolderService {
  FolderService({required this.db, Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDb db;
  final Uuid _uuid;

  // Legacy SharedPreferences keys, read once by [migrateFromPrefs] and then
  // dropped. Kept private and never written again.
  static const _legacyFoldersKey = 'folders_v1';
  static const _legacyMeetingFoldersKey = 'meeting_folders_v1';
  static const _legacyMeetingTagsKey = 'meeting_tags_v1';
  static const _migratedFlag = 'folders_migrated_to_drift_v1';

  // -- folders ----------------------------------------------------------------

  Future<List<Folder>> allFolders() =>
      (db.select(db.folders)..orderBy([(f) => OrderingTerm.asc(f.name)])).get();

  Stream<List<Folder>> watchFolders() =>
      (db.select(db.folders)..orderBy([(f) => OrderingTerm.asc(f.name)]))
          .watch();

  /// Direct children of [parentId] (top-level when null).
  Future<List<Folder>> childrenOf(String? parentId) => (db.select(db.folders)
        ..where((f) => parentId == null
            ? f.parentId.isNull()
            : f.parentId.equals(parentId))
        ..orderBy([(f) => OrderingTerm.asc(f.name)]))
      .get();

  Future<Folder> createFolder({
    required String name,
    String? parentId,
    int colorIndex = 0,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Folder name cannot be empty');
    }
    final folder = FoldersCompanion.insert(
      id: _uuid.v4(),
      name: trimmed,
      parentId: Value(parentId),
      colorIndex: Value(colorIndex),
      createdAt: DateTime.now(),
    );
    return db.into(db.folders).insertReturning(folder);
  }

  Future<void> renameFolder(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Folder name cannot be empty');
    }
    await (db.update(db.folders)..where((f) => f.id.equals(id)))
        .write(FoldersCompanion(name: Value(trimmed)));
  }

  /// Re-parent [id] under [newParentId].
  ///
  /// Refuses to create a cycle. Without this check a user can drag a folder into
  /// its own descendant, and every recursive walk of the tree then loops
  /// forever — the UI hangs and there is no way back out of it.
  Future<void> moveFolder(String id, String? newParentId) async {
    if (newParentId == id) {
      throw ArgumentError('A folder cannot be its own parent');
    }
    if (newParentId != null && await _isDescendantOf(newParentId, id)) {
      throw ArgumentError(
          'Cannot move a folder into its own descendant (that would make a cycle)');
    }
    await (db.update(db.folders)..where((f) => f.id.equals(id)))
        .write(FoldersCompanion(parentId: Value(newParentId)));
  }

  /// True if [candidate] is [ancestor], or sits somewhere beneath it.
  Future<bool> _isDescendantOf(String candidate, String ancestor) async {
    var cursor = candidate;
    // Bounded by the folder count: even a pre-existing cycle terminates.
    final seen = <String>{};
    while (true) {
      if (cursor == ancestor) return true;
      if (!seen.add(cursor)) return false; // already-cyclic data; do not hang
      final row = await (db.select(db.folders)
            ..where((f) => f.id.equals(cursor)))
          .getSingleOrNull();
      final parent = row?.parentId;
      if (parent == null) return false;
      cursor = parent;
    }
  }

  /// Delete a folder. Children are promoted to its parent rather than deleted —
  /// silently destroying a subtree because the user removed one node is not a
  /// trade anyone would accept. MeetingFolders rows cascade away on their own.
  Future<void> deleteFolder(String id) async {
    await db.transaction(() async {
      final folder = await (db.select(db.folders)
            ..where((f) => f.id.equals(id)))
          .getSingleOrNull();
      if (folder == null) return;
      await (db.update(db.folders)..where((f) => f.parentId.equals(id)))
          .write(FoldersCompanion(parentId: Value(folder.parentId)));
      await (db.delete(db.folders)..where((f) => f.id.equals(id))).go();
    });
  }

  // -- meeting <-> folder ------------------------------------------------------

  Future<Set<String>> foldersForMeeting(String meetingId) async {
    final rows = await (db.select(db.meetingFolders)
          ..where((mf) => mf.meetingId.equals(meetingId)))
        .get();
    return rows.map((r) => r.folderId).toSet();
  }

  Future<List<Meeting>> meetingsInFolder(String folderId) async {
    final q = db.select(db.meetings).join([
      innerJoin(db.meetingFolders,
          db.meetingFolders.meetingId.equalsExp(db.meetings.id)),
    ])
      ..where(db.meetingFolders.folderId.equals(folderId))
      ..orderBy([OrderingTerm.desc(db.meetings.createdAt)]);
    final rows = await q.get();
    return rows.map((r) => r.readTable(db.meetings)).toList();
  }

  Future<void> setFoldersForMeeting(
    String meetingId,
    Set<String> folderIds,
  ) async {
    await db.transaction(() async {
      await (db.delete(db.meetingFolders)
            ..where((mf) => mf.meetingId.equals(meetingId)))
          .go();
      for (final fid in folderIds) {
        await db.into(db.meetingFolders).insert(
              MeetingFoldersCompanion.insert(
                  meetingId: meetingId, folderId: fid),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  // -- tags --------------------------------------------------------------------

  Future<Set<String>> tagsForMeeting(String meetingId) async {
    final rows = await (db.select(db.meetingTags)
          ..where((t) => t.meetingId.equals(meetingId)))
        .get();
    return rows.map((r) => r.tag).toSet();
  }

  /// Every tag in use, for autocomplete.
  Future<List<String>> allTags() async {
    final rows = await db.customSelect(
      'SELECT DISTINCT tag FROM meeting_tags ORDER BY tag',
      readsFrom: {db.meetingTags},
    ).get();
    return rows.map((r) => r.read<String>('tag')).toList();
  }

  Future<void> setTagsForMeeting(String meetingId, Set<String> tags) async {
    final clean = tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toSet();
    await db.transaction(() async {
      await (db.delete(db.meetingTags)
            ..where((t) => t.meetingId.equals(meetingId)))
          .go();
      for (final tag in clean) {
        await db.into(db.meetingTags).insert(
              MeetingTagsCompanion.insert(meetingId: meetingId, tag: tag),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  // -- migration ---------------------------------------------------------------

  /// Move any folders/tags left in SharedPreferences into Drift, once.
  ///
  /// Runs before the folder UI is reachable. Idempotent, and it does NOT delete
  /// the legacy keys until the Drift writes have committed — if we are killed
  /// halfway, the next launch replays from data that is still there.
  ///
  /// A MeetingFolders row whose meeting no longer exists is dropped: foreign
  /// keys are now enforced, so inserting it would throw and abort the whole
  /// migration over a row that refers to nothing.
  Future<void> migrateFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedFlag) ?? false) return;

    final rawFolders = prefs.getString(_legacyFoldersKey);
    final rawMeetingFolders = prefs.getString(_legacyMeetingFoldersKey);
    final rawTags = prefs.getString(_legacyMeetingTagsKey);

    if (rawFolders == null && rawMeetingFolders == null && rawTags == null) {
      await prefs.setBool(_migratedFlag, true);
      return;
    }

    final liveMeetingIds =
        (await db.select(db.meetings).get()).map((m) => m.id).toSet();

    await db.transaction(() async {
      final knownFolderIds = <String>{};

      if (rawFolders != null) {
        for (final entry in jsonDecode(rawFolders) as List<dynamic>) {
          final m = entry as Map<String, dynamic>;
          final id = m['id'] as String;
          knownFolderIds.add(id);
          await db.into(db.folders).insert(
                FoldersCompanion.insert(
                  id: id,
                  name: m['name'] as String,
                  parentId: Value(m['parentId'] as String?),
                  colorIndex: Value((m['colorIndex'] as num?)?.toInt() ?? 0),
                  createdAt:
                      DateTime.tryParse(m['createdAt'] as String? ?? '') ??
                          DateTime.now(),
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
      }

      if (rawMeetingFolders != null) {
        final map = jsonDecode(rawMeetingFolders) as Map<String, dynamic>;
        for (final e in map.entries) {
          if (!liveMeetingIds.contains(e.key)) continue;
          for (final fid in (e.value as List<dynamic>).cast<String>()) {
            if (!knownFolderIds.contains(fid)) continue;
            await db.into(db.meetingFolders).insert(
                  MeetingFoldersCompanion.insert(
                      meetingId: e.key, folderId: fid),
                  mode: InsertMode.insertOrIgnore,
                );
          }
        }
      }

      if (rawTags != null) {
        final map = jsonDecode(rawTags) as Map<String, dynamic>;
        for (final e in map.entries) {
          if (!liveMeetingIds.contains(e.key)) continue;
          for (final tag in (e.value as List<dynamic>).cast<String>()) {
            if (tag.trim().isEmpty) continue;
            await db.into(db.meetingTags).insert(
                  MeetingTagsCompanion.insert(
                      meetingId: e.key, tag: tag.trim()),
                  mode: InsertMode.insertOrIgnore,
                );
          }
        }
      }
    });

    // Only now that Drift has the data.
    await prefs.setBool(_migratedFlag, true);
    await prefs.remove(_legacyFoldersKey);
    await prefs.remove(_legacyMeetingFoldersKey);
    await prefs.remove(_legacyMeetingTagsKey);
  }
}
