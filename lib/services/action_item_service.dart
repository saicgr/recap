import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum ActionItemStatus { open, inProgress, done, dropped }

class ActionItem {
  final String id;
  final String meetingId;
  final String body;
  final String? assignee;
  final DateTime? dueDate;
  final ActionItemStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  const ActionItem({
    required this.id,
    required this.meetingId,
    required this.body,
    this.assignee,
    this.dueDate,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  ActionItem copyWith({
    ActionItemStatus? status,
    DateTime? completedAt,
    String? assignee,
    DateTime? dueDate,
  }) =>
      ActionItem(
        id: id,
        meetingId: meetingId,
        body: body,
        assignee: assignee ?? this.assignee,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        createdAt: createdAt,
        completedAt: completedAt ?? this.completedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'meetingId': meetingId,
        'body': body,
        'assignee': assignee,
        'dueDate': dueDate?.toIso8601String(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory ActionItem.fromJson(Map<String, dynamic> m) => ActionItem(
        id: m['id'] as String,
        meetingId: m['meetingId'] as String,
        body: m['body'] as String,
        assignee: m['assignee'] as String?,
        dueDate: m['dueDate'] == null
            ? null
            : DateTime.parse(m['dueDate'] as String),
        status: ActionItemStatus.values.firstWhere((s) => s.name == m['status'],
            orElse: () => ActionItemStatus.open),
        createdAt: DateTime.parse(m['createdAt'] as String),
        completedAt: m['completedAt'] == null
            ? null
            : DateTime.parse(m['completedAt'] as String),
      );
}

/// Action items extracted from summaries become tracked tasks. Top-level
/// "Tasks" tab pulls from here. v1 storage: shared_preferences JSON list;
/// migrate to the `ActionItems` Drift table when codegen is fixed.
class ActionItemService {
  static const _key = 'action_items_v1';

  Future<List<ActionItem>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((m) => ActionItem.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<List<ActionItem>> forMeeting(String meetingId) async {
    final list = await all();
    return list.where((a) => a.meetingId == meetingId).toList();
  }

  Future<List<ActionItem>> open() async {
    final list = await all();
    return list.where((a) => a.status == ActionItemStatus.open).toList();
  }

  Future<void> add(ActionItem item) async {
    final list = await all();
    await _save([...list, item]);
  }

  Future<void> update(ActionItem item) async {
    final list = await all();
    final idx = list.indexWhere((a) => a.id == item.id);
    if (idx < 0) return;
    final updated = [...list];
    updated[idx] = item;
    await _save(updated);
  }

  Future<void> delete(String id) async {
    final list = await all();
    await _save(list.where((a) => a.id != id).toList());
  }

  Future<void> markDone(String id) async {
    final list = await all();
    final idx = list.indexWhere((a) => a.id == id);
    if (idx < 0) return;
    final updated = [...list];
    updated[idx] = list[idx].copyWith(
      status: ActionItemStatus.done,
      completedAt: DateTime.now(),
    );
    await _save(updated);
  }

  Future<void> _save(List<ActionItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(list.map((a) => a.toJson()).toList()));
  }
}
