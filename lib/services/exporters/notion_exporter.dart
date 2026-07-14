import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/database.dart';
import 'workflow_exporter.dart';

/// Notion export (D8.1). Power tier. Uses Notion OAuth public-integration
/// flow; token stored via flutter_secure_storage. Creates a page in the
/// user's selected workspace, renders transcript as toggle-blocks per
/// speaker and summary as a callout at top.
///
/// **OAuth scopes:** `read_user`, `read_content`, `update_content`,
/// `insert_content` (Notion's public OAuth model — workspace-scoped tokens).
class NotionExporter implements WorkflowExporter {
  @override
  String get targetId => 'notion';
  @override
  String get displayName => 'Notion';
  @override
  bool get requiresOAuth => true;
  @override
  bool get isCloudDestination => true;

  String? _accessToken;
  String? _databaseId; // user-selected destination

  @override
  Future<bool> isAvailable() async => _accessToken != null;

  @override
  Future<void> authorize() async {
    // TODO: full OAuth flow via flutter_appauth. Notion's flow:
    //   1. Redirect to https://api.notion.com/v1/oauth/authorize?...
    //   2. Receive code on app-scheme redirect (recap://notion/callback)
    //   3. Exchange for access_token (POST /v1/oauth/token, basic auth
    //      with client_id:client_secret)
    //   4. Store token via flutter_secure_storage
    //   5. Prompt user to pick a destination database (POST /v1/search)
    throw UnimplementedError(
        'Notion OAuth pending: client ID + flutter_appauth integration.');
  }

  @override
  Future<void> deauthorize() async {
    _accessToken = null;
    _databaseId = null;
  }

  @override
  Future<ExportResult> push({
    required Meeting meeting,
    required Transcript? transcript,
    required List<Summary> summaries,
  }) async {
    final token = _accessToken;
    final dbId = _databaseId;
    if (token == null || dbId == null) {
      return ExportResult.err('Connect to Notion first (Settings → Exports).');
    }

    final summaryText =
        summaries.isEmpty ? '(no summary yet)' : summaries.first.body;
    final body = {
      'parent': {'database_id': dbId},
      'properties': {
        'Name': {
          'title': [
            {
              'text': {'content': meeting.title}
            }
          ]
        },
      },
      'children': [
        {
          'object': 'block',
          'type': 'callout',
          'callout': {
            'rich_text': [
              {
                'type': 'text',
                'text': {'content': summaryText}
              }
            ],
            'icon': {'emoji': '📝'},
          }
        },
        {
          'object': 'block',
          'type': 'heading_2',
          'heading_2': {
            'rich_text': [
              {
                'type': 'text',
                'text': {'content': 'Transcript'}
              }
            ],
          }
        },
        {
          'object': 'block',
          'type': 'paragraph',
          'paragraph': {
            'rich_text': [
              {
                'type': 'text',
                'text': {'content': transcript?.body ?? '(empty)'}
              }
            ],
          }
        },
      ],
    };

    final res = await http.post(
      Uri.parse('https://api.notion.com/v1/pages'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Notion-Version': '2022-06-28',
      },
      body: jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return ExportResult.ok(url: data['url'] as String?);
    }
    return ExportResult.err('Notion HTTP ${res.statusCode}: ${res.body}');
  }
}
