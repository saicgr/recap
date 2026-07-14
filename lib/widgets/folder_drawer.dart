import 'package:flutter/material.dart';

import '../data/database.dart';
import '../main.dart';
import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';

/// The folder sidebar.
///
/// Granola's mobile app cannot ship this — it renders "No folders yet: folders
/// will appear here after they are synced", because its folders live on a
/// server. Ours are local-first Drift rows, so they can be created offline, with
/// no account, and appear instantly.
class FolderDrawer extends StatelessWidget {
  const FolderDrawer({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  /// null == "All recordings".
  final Folder? selected;
  final ValueChanged<Folder?> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    return Drawer(
      backgroundColor: t.surface,
      child: SafeArea(
        child: StreamBuilder<List<Folder>>(
          stream: folderService.watchFolders(),
          builder: (ctx, snap) {
            final folders = snap.data ?? const <Folder>[];
            return StreamBuilder<Map<String, int>>(
              stream: folderService.watchFolderCounts(),
              builder: (ctx2, countSnap) {
                final counts = countSnap.data ?? const <String, int>{};
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Text('Folders',
                          style: RT.titleLg.copyWith(color: t.textPrimary)),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: [
                          _row(
                            t,
                            icon: Icons.all_inbox_outlined,
                            label: 'All recordings',
                            active: selected == null,
                            onTap: () => onSelect(null),
                          ),
                          if (folders.isEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                              child: Text(
                                'No folders yet. Create one to organise your '
                                'recordings — it works offline, no account needed.',
                                style:
                                    RT.bodySm.copyWith(color: t.textMuted),
                              ),
                            ),
                          // Flat list, parents first. Nesting is supported in the
                          // data model; the drawer indents children one level,
                          // which is as deep as anyone actually navigates.
                          ..._ordered(folders).map((f) {
                            final depth = _depthOf(f, folders);
                            return _row(
                              t,
                              icon: depth > 0
                                  ? Icons.subdirectory_arrow_right
                                  : Icons.folder_outlined,
                              label: f.name,
                              count: counts[f.id] ?? 0,
                              indent: depth.clamp(0, 1),
                              active: selected?.id == f.id,
                              onTap: () => onSelect(f),
                              onLongPress: () => _folderActions(context, f),
                            );
                          }),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Btn(
                        label: 'New folder',
                        leading: Icons.create_new_folder_outlined,
                        full: true,
                        onPressed: () => _createFolder(context),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Parents before their children, so an indented child never renders above the
  /// folder it belongs to.
  List<Folder> _ordered(List<Folder> all) {
    final byParent = <String?, List<Folder>>{};
    for (final f in all) {
      byParent.putIfAbsent(f.parentId, () => []).add(f);
    }
    final out = <Folder>[];
    void walk(String? parent, int depth) {
      // Bound the recursion: the service guards against cycles, but a database
      // that predates that guard could still hold one, and hanging the drawer is
      // worse than dropping a folder from it.
      if (depth > 8) return;
      for (final f in byParent[parent] ?? const <Folder>[]) {
        out.add(f);
        walk(f.id, depth + 1);
      }
    }

    walk(null, 0);
    // Anything unreachable (orphaned parent) still gets shown.
    for (final f in all) {
      if (!out.contains(f)) out.add(f);
    }
    return out;
  }

  int _depthOf(Folder f, List<Folder> all) {
    var d = 0;
    var parent = f.parentId;
    final seen = <String>{};
    while (parent != null && d < 8 && seen.add(parent)) {
      d++;
      parent = all.where((x) => x.id == parent).firstOrNull?.parentId;
    }
    return d;
  }

  Widget _row(
    RecapTheme t, {
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    int count = 0,
    int indent = 0,
  }) {
    return Material(
      color: active ? t.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.0 + indent * 16, 12, 12, 12),
          child: Row(
            children: [
              Icon(icon,
                  size: 18, color: active ? t.accent : t.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: RT.body.copyWith(
                    color: active ? t.accent : t.textPrimary,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (count > 0)
                Text('$count',
                    style: RT.caption.copyWith(color: t.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createFolder(BuildContext context) async {
    final name = await promptForText(
      context,
      title: 'New folder',
      hint: 'e.g. Client work',
      confirmLabel: 'Create',
    );
    if (name == null || name.trim().isEmpty) return;
    await folderService.createFolder(name: name);
  }

  Future<void> _folderActions(BuildContext context, Folder f) async {
    final t = RecapThemeScope.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: t.textPrimary),
              title: Text('Rename',
                  style: RT.body.copyWith(color: t.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text('Delete folder',
                  style: RT.body.copyWith(color: Colors.redAccent)),
              subtitle: Text('Recordings stay — only the folder is removed',
                  style: RT.caption.copyWith(color: t.textMuted)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    if (action == 'rename') {
      final name = await promptForText(
        context,
        title: 'Rename folder',
        initial: f.name,
        confirmLabel: 'Save',
      );
      if (name != null && name.trim().isNotEmpty) {
        await folderService.renameFolder(f.id, name);
      }
    } else if (action == 'delete') {
      // Children are promoted to this folder's parent, and the meetings
      // themselves are untouched — deleting a folder must never destroy
      // recordings.
      await folderService.deleteFolder(f.id);
      if (selected?.id == f.id) onSelect(null);
    }
  }
}

/// Small shared text prompt. The codebase had no reusable dialog helper — every
/// sheet re-implemented the same boilerplate.
Future<String?> promptForText(
  BuildContext context, {
  required String title,
  String? initial,
  String? hint,
  String confirmLabel = 'OK',
}) {
  final t = RecapThemeScope.of(context);
  final controller = TextEditingController(text: initial ?? '');
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: t.surface,
      title: Text(title, style: RT.subtitle.copyWith(color: t.textPrimary)),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: RT.body.copyWith(color: t.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: RT.body.copyWith(color: t.textMuted),
        ),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: RT.label.copyWith(color: t.textMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: Text(confirmLabel,
              style: RT.label.copyWith(color: t.accent)),
        ),
      ],
    ),
  );
}
