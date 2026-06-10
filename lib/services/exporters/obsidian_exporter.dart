import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../data/database.dart';
import 'workflow_exporter.dart';

/// Obsidian export (D8.2). Power tier in feature list, but Obsidian doesn't
/// need cloud / OAuth — Markdown to a folder is enough. So no Power tier
/// gate beyond the "no-watermark" UX on Pro+ vs watermarked on Free.
///
/// Obsidian + iOS: vault syncs via iCloud Drive. We use share_plus to hand
/// the .md file off; user picks "Save to Files → Obsidian vault". The
/// `obsidian://new` URL scheme is an alternative but harder to wire.
class ObsidianExporter implements WorkflowExporter {
  @override
  String get targetId => 'obsidian';
  @override
  String get displayName => 'Obsidian';
  @override
  bool get requiresOAuth => false;
  @override
  bool get isCloudDestination => false;

  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<void> authorize() async {}
  @override
  Future<void> deauthorize() async {}

  @override
  Future<ExportResult> push({
    required Meeting meeting,
    required Transcript? transcript,
    required List<Summary> summaries,
  }) async {
    try {
      final docs = Directory.systemTemp.createTempSync('recap_obsidian_');
      final filename = '${_safeFilename(meeting.title)}.md';
      final outFile = File(p.join(docs.path, filename));
      final body = _buildMarkdown(meeting, transcript, summaries);
      await outFile.writeAsString(body);
      await Share.shareXFiles(
        [XFile(outFile.path)],
        subject: 'Recap → Obsidian: ${meeting.title}',
      );
      return ExportResult.ok();
    } catch (e) {
      return ExportResult.err(e.toString());
    }
  }

  String _buildMarkdown(
    Meeting m,
    Transcript? tr,
    List<Summary> summaries,
  ) {
    final buf = StringBuffer()
      ..writeln('---')
      ..writeln('title: ${_yamlEscape(m.title)}')
      ..writeln('date: ${m.createdAt.toIso8601String()}')
      ..writeln('duration_ms: ${m.durationMs}')
      ..writeln('source: recap')
      ..writeln('---')
      ..writeln()
      ..writeln('# ${m.title}')
      ..writeln();
    if (summaries.isNotEmpty) {
      buf
        ..writeln('## Summary')
        ..writeln(summaries.first.body)
        ..writeln();
    }
    if (tr != null) {
      buf
        ..writeln('## Transcript')
        ..writeln(tr.body)
        ..writeln();
    }
    return buf.toString();
  }

  String _safeFilename(String s) {
    final cleaned = s.replaceAll(RegExp(r'[/\\:*?"<>|]'), '-').trim();
    return cleaned.isEmpty ? 'recap-meeting' : cleaned;
  }

  String _yamlEscape(String s) => s.replaceAll('"', r'\"');
}
