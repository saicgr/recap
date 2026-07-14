import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../billing/persona.dart';
import '../cloud/cloud_proxy.dart';
import '../cloud/install_identity.dart';
import 'summary_backend.dart';

/// Cloud summaries via the Render proxy -> Gemini 3.1 Flash Lite.
///
/// The app holds no Gemini key: it POSTs the transcript to the proxy, which
/// attaches the key server-side. Authentication is an install token issued by
/// the proxy (see [InstallIdentity]) — the app cannot mint one itself, which is
/// what closed the open-proxy hole in the retired Cloudflare Worker.
///
/// The network is touched ONLY from [summarize], and only when the user has
/// explicitly asked for a cloud summary. No pings, no warm-ups, no health
/// checks — those would violate the Karpathy invariants.
class CloudBackend implements SummaryBackend {
  CloudBackend({
    required this.proxyUrlProvider,
    required this.identity,
    required this.cloudEnabled,
    http.Client? client,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 90);

  /// Read on every call so a Settings change takes effect without a restart.
  final String Function() proxyUrlProvider;

  final InstallIdentity identity;

  /// Whether the current tier may reach the cloud at all. False on Privacy —
  /// and this is checked at the call site, not just in the UI, so the Privacy
  /// tier's "cannot reach the network" promise holds even if a button leaks in.
  final bool Function() cloudEnabled;

  final http.Client _client;
  final Duration _timeout;

  @override
  Future<bool> isAvailable() async {
    if (!cloudEnabled()) return false;
    // Deliberately does not ping the proxy: a reachability check would be a
    // background network call. We trust the URL and let summarize() report.
    return isConfiguredProxyUrl(proxyUrlProvider());
  }

  @override
  Future<SummaryResult> summarize({
    required String transcript,
    required Persona persona,
    void Function(double progress)? onProgress,
  }) async {
    if (!cloudEnabled()) {
      throw CloudError(
        CloudFailureKind.disabled,
        'Cloud summaries are disabled on this tier.',
      );
    }
    final base = requireConfiguredProxyUrl(proxyUrlProvider());

    final stopwatch = Stopwatch()..start();
    final body = jsonEncode({
      'persona_key': persona.key,
      'prompt': persona.prompt.trim(),
      'transcript': transcript,
    });

    var resp = await _post(base, body, forceRefresh: false);

    // 401 means our cached token is not one this server would issue — the
    // pepper rotated, or the token predates the Render backend. Re-register
    // ONCE and retry. If it 401s again the credential is not the problem, so we
    // surface it instead of looping and re-uploading the transcript forever.
    if (resp.statusCode == 401) {
      resp = await _post(base, body, forceRefresh: true);
    }

    stopwatch.stop();

    switch (resp.statusCode) {
      case 401:
        throw CloudError(CloudFailureKind.unauthorized,
            'The cloud proxy rejected this install. Try again later.');
      case 429:
        throw CloudError(CloudFailureKind.rateLimited,
            'Cloud rate limit reached. Wait a moment, or summarize on-device.');
      case 402:
        throw CloudError(CloudFailureKind.quotaExhausted,
            'Your cloud allowance is used up for this month.');
      case 503:
        throw CloudError(
            CloudFailureKind.budgetExhausted,
            'The cloud service is at its daily limit. Try tomorrow, or '
            'summarize on-device.');
    }
    if (resp.statusCode >= 400) {
      throw CloudError(
        CloudFailureKind.server,
        'Cloud summary failed (HTTP ${resp.statusCode}): '
        '${truncateForError(resp.body)}',
      );
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      throw CloudError(CloudFailureKind.emptyResponse,
          'Cloud summary returned an unreadable response.');
    }
    final text = (json['text'] as String?)?.trim();
    if (text == null || text.isEmpty) {
      throw CloudError(
          CloudFailureKind.emptyResponse, 'Cloud summary returned empty text.');
    }

    return SummaryResult(
      text: text,
      modelId: json['model_id'] as String? ?? 'gemini-3.1-flash-lite',
      processingTime: stopwatch.elapsed,
    );
  }

  Future<http.Response> _post(
    String base,
    String body, {
    required bool forceRefresh,
  }) async {
    final headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      ...await identity.authHeaders(forceRefresh: forceRefresh),
    };
    try {
      return await _client
          .post(Uri.parse('$base/v1/summarize'), headers: headers, body: body)
          .timeout(_timeout);
    } on TimeoutException {
      throw CloudError(CloudFailureKind.timeout,
          'The cloud summary timed out. Try again, or summarize on-device.');
    } on IOException catch (e) {
      // SocketException, HandshakeException, TlsException, ... A captive portal
      // throws HandshakeException, not SocketException, so catching only the
      // latter would miss the most common real-world failure.
      throw CloudError(CloudFailureKind.offline,
          'Could not reach the cloud proxy: ${truncateForError('$e')}');
    }
  }
}
