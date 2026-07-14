import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../billing/entitlement_service.dart';
import '../billing/tier.dart';
import '../data/database.dart';

class ExportNotAvailable implements Exception {
  final ExportTarget target;
  final Tier tier;
  ExportNotAvailable(this.target, this.tier);
  @override
  String toString() =>
      'ExportNotAvailable: ${target.name} requires a tier above ${tier.name}';
}

class Exporter {
  Exporter({required this.entitlements});

  final EntitlementService entitlements;

  /// availableExports, not exports: on the Privacy tier this strips every
  /// destination that would make a network call, so the cloud targets are never
  /// rendered in the first place.
  List<ExportTarget> get availableTargets =>
      entitlements.currentTier.availableExports;

  String _format(Meeting m, String body) {
    final tier = entitlements.currentTier;
    final created = DateFormat('MMM d, y · h:mm a').format(m.createdAt);
    final header = '# ${m.title}\n\n_${created}_\n\n';
    final footer =
        tier.watermark ? '\n\n---\n_Made with Recap_' : '';
    return '$header$body$footer';
  }

  Future<void> export({
    required ExportTarget target,
    required Meeting meeting,
    required String body,
  }) async {
    if (!availableTargets.contains(target)) {
      throw ExportNotAvailable(target, entitlements.currentTier);
    }
    final text = _format(meeting, body);
    switch (target) {
      case ExportTarget.copy:
        await Clipboard.setData(ClipboardData(text: text));
        break;
      case ExportTarget.shareSheet:
        await Share.share(text, subject: meeting.title);
        break;
      case ExportTarget.appleReminders:
        await _openUrl('x-apple-reminderkit://');
        await Clipboard.setData(ClipboardData(text: text));
        break;
      case ExportTarget.appleNotes:
        await _openUrl('mobilenotes://');
        await Clipboard.setData(ClipboardData(text: text));
        break;
      case ExportTarget.markdown:
        final path = await _writeMarkdown(meeting, text);
        await Share.shareXFiles([XFile(path)], subject: meeting.title);
        break;
      case ExportTarget.googleDocs:
      case ExportTarget.notion:
      case ExportTarget.obsidian:
      case ExportTarget.slack:
        // v1.1 — workflow integrations.
        throw UnimplementedError(
            '${target.name} export ships in v1.1. Use share-sheet for now.');
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<String> _writeMarkdown(Meeting meeting, String body) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory(p.join(dir.path, 'exports'));
    if (!await exportsDir.exists()) await exportsDir.create(recursive: true);
    final safeTitle = meeting.title.replaceAll(RegExp(r'[^\w\s-]'), '_').trim();
    final filename =
        '${safeTitle}_${meeting.id.substring(0, 8)}.md';
    final file = File(p.join(exportsDir.path, filename));
    await file.writeAsString(body);
    return file.path;
  }
}
