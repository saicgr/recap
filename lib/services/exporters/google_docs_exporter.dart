import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/database.dart';
import 'workflow_exporter.dart';

/// Google Docs export (D8.4). Power tier (Starter+ for some configurations).
/// OAuth with `drive.file` scope only (minimum privilege — we create
/// app-owned docs, never read user's other docs).
///
/// **Verification gate:** Google requires security review for production
/// OAuth apps with sensitive scopes. `drive.file` is *not* a sensitive
/// scope so we avoid the review process entirely. Document this in CLAUDE.md.
class GoogleDocsExporter implements WorkflowExporter {
  @override
  String get targetId => 'gdocs';
  @override
  String get displayName => 'Google Docs';
  @override
  bool get requiresOAuth => true;
  @override
  bool get isCloudDestination => true;

  String? _accessToken;

  @override
  Future<bool> isAvailable() async => _accessToken != null;
  @override
  Future<void> authorize() async {
    // TODO: Google OAuth via google_sign_in (Android/iOS native).
    //   scopes: ['https://www.googleapis.com/auth/drive.file']
    //   On success: store access_token + refresh_token in secure storage.
    throw UnimplementedError('Google OAuth pending.');
  }

  @override
  Future<void> deauthorize() async {
    _accessToken = null;
  }

  @override
  Future<ExportResult> push({
    required Meeting meeting,
    required Transcript? transcript,
    required List<Summary> summaries,
  }) async {
    final token = _accessToken;
    if (token == null) {
      return ExportResult.err('Connect Google first (Settings → Exports).');
    }

    // 1. Create the doc via Docs API.
    final createRes = await http.post(
      Uri.parse('https://docs.googleapis.com/v1/documents'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'title': meeting.title}),
    );
    if (createRes.statusCode != 200) {
      return ExportResult.err(
          'Google Docs create: HTTP ${createRes.statusCode}');
    }
    final created = jsonDecode(createRes.body) as Map<String, dynamic>;
    final docId = created['documentId'] as String;

    // 2. Build batchUpdate with summary + transcript content.
    final body = StringBuffer();
    if (summaries.isNotEmpty) {
      body.writeln('Summary');
      body.writeln(summaries.first.body);
      body.writeln('');
    }
    body.writeln('Transcript');
    body.writeln(transcript?.body ?? '(empty)');

    final updateRes = await http.post(
      Uri.parse('https://docs.googleapis.com/v1/documents/$docId:batchUpdate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'requests': [
          {
            'insertText': {
              'location': {'index': 1},
              'text': body.toString(),
            },
          },
        ],
      }),
    );
    if (updateRes.statusCode != 200) {
      return ExportResult.err(
          'Google Docs update: HTTP ${updateRes.statusCode}');
    }

    return ExportResult.ok(
        url: 'https://docs.google.com/document/d/$docId/edit');
  }
}
