import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../ui/components.dart';
import '../ui/theme.dart';
import '../ui/type.dart';

/// Storage management (D14.15). Breakdown of meeting audio + transcripts +
/// summaries + models on disk, with delete-all options scoped to each.
/// Loads sizes by walking the app support dir.
class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  Map<String, int>? _sizes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docs = await getApplicationSupportDirectory();
    final categories = {
      'Recordings': p.join(docs.path, 'recordings'),
      'Imports': p.join(docs.path, 'imports'),
      'Exports': p.join(docs.path, 'exports'),
      'Whisper models': p.join(docs.path, 'bundled_models'),
      'Speaker models': p.join(docs.path, 'sherpa_diarizer'),
      'Gemma models': p.join(docs.path, 'gemma'),
      'Backups': p.join(docs.path, 'backups'),
    };
    final sizes = <String, int>{};
    for (final entry in categories.entries) {
      sizes[entry.key] = await _dirSize(entry.value);
    }
    if (!mounted) return;
    setState(() => _sizes = sizes);
  }

  Future<int> _dirSize(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return 0;
    var total = 0;
    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          try {
            total += await entity.length();
          } catch (_) {
            /* per-file races on iOS */
          }
        }
      }
    } catch (_) {
      /* dir missing */
    }
    return total;
  }

  String _fmtBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final t = RecapThemeScope.of(context);
    final sizes = _sizes;
    final total = sizes?.values.fold<int>(0, (a, b) => a + b) ?? 0;
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
                'Storage',
                style: RT.subtitle.copyWith(color: t.textPrimary),
              ),
            ),
            Expanded(
              child: sizes == null
                  ? Center(child: CircularProgressIndicator(color: t.accent))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: t.surface,
                            border: Border.all(color: t.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Total on this device',
                                  style: RT.subtitle.copyWith(
                                    color: t.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                _fmtBytes(total),
                                style: RT.titleLg.copyWith(
                                  color: t.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final entry in sizes.entries) _row(t, entry),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(RecapTheme t, MapEntry<String, int> entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.key,
              style: RT.body.copyWith(color: t.textPrimary),
            ),
          ),
          Text(
            _fmtBytes(entry.value),
            style: RT.bodySm.copyWith(color: t.textSecondary).merge(RT.num),
          ),
        ],
      ),
    );
  }
}
