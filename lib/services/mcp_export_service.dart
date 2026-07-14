import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../main.dart';

/// MCP (Model Context Protocol) companion sync — Power tier feature (D9).
///
/// **Architecture:** running an MCP server on a phone is awkward (NAT,
/// always-on, battery). Instead we export meetings as JSON to a user-chosen
/// sync folder (iCloud Drive / Google Drive / local), and ship a separate
/// `recap-mcp` companion binary the user runs on their Mac / Linux box.
/// That binary exposes MCP over stdio to Claude Desktop and other MCP
/// clients, reading from the sync folder.
///
/// This service is the *exporter* — incremental, append-only, conflict-
/// free JSON sync. The companion binary lives in a sibling `recap-mcp/`
/// folder once the v2 product PR lands.
class McpExportService {
  /// User-configured sync folder. Empty = MCP export disabled.
  String syncFolder = '';

  /// Sync all meetings + transcripts + summaries to [syncFolder]. Skips
  /// already-synced rows by comparing last-modified timestamps in a small
  /// `sync_state.json` index file kept alongside the data.
  Future<void> sync() async {
    if (syncFolder.isEmpty) return;
    final dir = Directory(syncFolder);
    if (!await dir.exists()) await dir.create(recursive: true);

    final statePath = p.join(syncFolder, 'sync_state.json');
    final stateFile = File(statePath);
    Map<String, dynamic> state = {};
    if (await stateFile.exists()) {
      try {
        state =
            jsonDecode(await stateFile.readAsString()) as Map<String, dynamic>;
      } catch (_) {/* corrupt; reset */}
    }
    final synced =
        (state['synced'] as Map<String, dynamic>? ?? {}).cast<String, String>();

    final meetings = await db.select(db.meetings).get();
    for (final m in meetings) {
      final updatedAt = m.updatedAt.toIso8601String();
      if (synced[m.id] == updatedAt) continue;

      final tr = await db.transcriptFor(m.id);
      final segs = await db.segmentsFor(m.id);
      final summaries = await db.summariesFor(m.id);
      final blob = {
        'mcp_version': 1,
        'meeting': {
          'id': m.id,
          'title': m.title,
          'createdAt': m.createdAt.toIso8601String(),
          'updatedAt': updatedAt,
          'durationMs': m.durationMs,
          'status': m.status.name,
          'language': m.language,
        },
        'transcript': tr?.body,
        'segments': segs
            .map((s) => {
                  'startMs': s.startMs,
                  'endMs': s.endMs,
                  'body': s.body,
                  'speaker': s.speakerLabel,
                })
            .toList(),
        'summaries': summaries
            .map((s) => {
                  'personaKey': s.personaKey,
                  'body': s.body,
                  'modelId': s.modelId,
                  'createdAt': s.createdAt.toIso8601String(),
                })
            .toList(),
      };
      final outFile = File(p.join(syncFolder, '${m.id}.json'));
      await outFile
          .writeAsString(const JsonEncoder.withIndent('  ').convert(blob));
      synced[m.id] = updatedAt;
    }

    state['synced'] = synced;
    state['lastSync'] = DateTime.now().toIso8601String();
    await stateFile
        .writeAsString(const JsonEncoder.withIndent('  ').convert(state));
  }
}
