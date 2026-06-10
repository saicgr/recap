import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Folder {
  final String id;
  final String name;
  final String? parentId;
  final int colorIndex;
  final DateTime createdAt;
  const Folder({
    required this.id,
    required this.name,
    this.parentId,
    this.colorIndex = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parentId': parentId,
        'colorIndex': colorIndex,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Folder.fromJson(Map<String, dynamic> m) => Folder(
        id: m['id'] as String,
        name: m['name'] as String,
        parentId: m['parentId'] as String?,
        colorIndex: (m['colorIndex'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}

/// Folders + tags organization (D14.8). Drift target once codegen is
/// unblocked; shared_preferences for v1 to keep moving.
class FolderService {
  static const _foldersKey = 'folders_v1';
  static const _meetingFoldersKey = 'meeting_folders_v1'; // {meetingId: [folderId,...]}
  static const _meetingTagsKey = 'meeting_tags_v1';      // {meetingId: [tag,...]}

  Future<List<Folder>> allFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_foldersKey);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((m) => Folder.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<Folder> createFolder({
    required String name,
    String? parentId,
    int colorIndex = 0,
  }) async {
    final folder = Folder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      parentId: parentId,
      colorIndex: colorIndex,
      createdAt: DateTime.now(),
    );
    final list = await allFolders();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_foldersKey,
        jsonEncode([...list, folder].map((f) => f.toJson()).toList()));
    return folder;
  }

  Future<void> deleteFolder(String id) async {
    final list = await allFolders();
    final updated = list.where((f) => f.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _foldersKey, jsonEncode(updated.map((f) => f.toJson()).toList()));
  }

  Future<Set<String>> foldersForMeeting(String meetingId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_meetingFoldersKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list = (map[meetingId] as List<dynamic>?) ?? const [];
    return list.cast<String>().toSet();
  }

  Future<void> setFoldersForMeeting(
      String meetingId, Set<String> folderIds) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_meetingFoldersKey);
    final map = raw == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw) as Map<String, dynamic>);
    map[meetingId] = folderIds.toList();
    await prefs.setString(_meetingFoldersKey, jsonEncode(map));
  }

  Future<Set<String>> tagsForMeeting(String meetingId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_meetingTagsKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list = (map[meetingId] as List<dynamic>?) ?? const [];
    return list.cast<String>().toSet();
  }

  Future<void> setTagsForMeeting(String meetingId, Set<String> tags) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_meetingTagsKey);
    final map = raw == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw) as Map<String, dynamic>);
    map[meetingId] = tags.toList();
    await prefs.setString(_meetingTagsKey, jsonEncode(map));
  }
}
