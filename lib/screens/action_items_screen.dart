import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/action_item_service.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';

/// Action items aggregate view (D14.9). Pulls from ActionItemService —
/// extracted from summaries on every persona-generation pass. User checks
/// off, app surfaces overdue / due-today, syncs to Apple Reminders if
/// connected.
class ActionItemsScreen extends StatefulWidget {
  const ActionItemsScreen({super.key});

  @override
  State<ActionItemsScreen> createState() => _ActionItemsScreenState();
}

class _ActionItemsScreenState extends State<ActionItemsScreen> {
  final _svc = ActionItemService();
  List<ActionItem> _items = const [];
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _svc.all();
    items.sort((a, b) {
      if (a.status == ActionItemStatus.done &&
          b.status != ActionItemStatus.done) {
        return 1;
      }
      if (b.status == ActionItemStatus.done &&
          a.status != ActionItemStatus.done) {
        return -1;
      }
      final aDue = a.dueDate?.millisecondsSinceEpoch ?? 1 << 62;
      final bDue = b.dueDate?.millisecondsSinceEpoch ?? 1 << 62;
      return aDue.compareTo(bDue);
    });
    if (!mounted) return;
    setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    final filtered = _showCompleted
        ? _items
        : _items.where((i) => i.status != ActionItemStatus.done).toList();
    return Scaffold(
      backgroundColor: t.bgSubtle,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              leading: IconBtn(
                icon: Icons.arrow_back,
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Action items',
                style: RT.subtitle.copyWith(color: t.textPrimary),
              ),
              trailing: [
                IconBtn(
                  icon: _showCompleted
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  onPressed: () =>
                      setState(() => _showCompleted = !_showCompleted),
                ),
              ],
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'All clear — nothing pending',
                        style: RT.body.copyWith(color: t.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _tile(t, filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(RecapTheme t, ActionItem item) {
    final done = item.status == ActionItemStatus.done;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      child: InkWell(
        onTap: () async {
          await _svc.markDone(item.id);
          await _load();
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done ? t.positive : t.textMuted,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.body,
                      style: RT.body.copyWith(
                        color: done ? t.textMuted : t.textPrimary,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (item.assignee != null || item.dueDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (item.assignee != null) ...[
                            Icon(
                              Icons.person_outline,
                              size: 13,
                              color: t.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              item.assignee!,
                              style: RT.caption.copyWith(color: t.textMuted),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (item.dueDate != null) ...[
                            Icon(
                              Icons.event_outlined,
                              size: 13,
                              color: t.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat.MMMd().format(item.dueDate!),
                              style: RT.caption.copyWith(color: t.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
