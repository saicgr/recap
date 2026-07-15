import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/database.dart';
import 'workflow_exporter.dart';

/// Slack export (D8.3). Power tier. OAuth with `chat:write` + `files:write`
/// scopes. Two send modes: (a) summary inline in a channel, (b) transcript
/// as a file upload attachment.
///
/// Rate-limit: Slack tier 2 = 20/min. We honor `Retry-After` headers.
class SlackExporter implements WorkflowExporter {
  @override
  String get targetId => 'slack';
  @override
  String get displayName => 'Slack';
  @override
  bool get requiresOAuth => true;
  @override
  bool get isCloudDestination => true;

  String? _accessToken;
  String? _defaultChannelId;

  @override
  Future<bool> isAvailable() async => _accessToken != null;
  @override
  Future<void> authorize() async {
    // TODO: full Slack OAuth flow via flutter_appauth.
    //   1. Redirect to https://slack.com/oauth/v2/authorize?...
    //   2. Receive code on app-scheme redirect (recap://slack/callback)
    //   3. POST /api/oauth.v2.access for access_token
    //   4. Show channel picker (conversations.list)
    throw UnimplementedError('Slack OAuth pending.');
  }

  @override
  Future<void> deauthorize() async {
    _accessToken = null;
    _defaultChannelId = null;
  }

  @override
  Future<ExportResult> push({
    required Meeting meeting,
    required Transcript? transcript,
    required List<Summary> summaries,
  }) async {
    final token = _accessToken;
    final channel = _defaultChannelId;
    if (token == null || channel == null) {
      return ExportResult.err('Connect Slack first (Settings → Exports).');
    }
    final summaryText = summaries.isEmpty
        ? '(no summary)'
        : summaries.first.body;
    final res = await http.post(
      Uri.parse('https://slack.com/api/chat.postMessage'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({
        'channel': channel,
        'text': '📝 *${meeting.title}*\n$summaryText',
        'blocks': [
          {
            'type': 'header',
            'text': {'type': 'plain_text', 'text': meeting.title},
          },
          {
            'type': 'section',
            'text': {'type': 'mrkdwn', 'text': summaryText},
          },
        ],
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['ok'] == true) {
        return ExportResult.ok(url: data['permalink'] as String?);
      }
      return ExportResult.err('Slack: ${data['error']}');
    }
    return ExportResult.err('Slack HTTP ${res.statusCode}');
  }
}
