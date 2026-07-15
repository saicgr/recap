import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../cloud/cloud_proxy.dart';
import '../cloud/install_identity.dart';
import 'summary_backend.dart';
import 'summary_types.dart';

/// Cloud summaries via the Render proxy -> Gemini 3.1 Flash Lite.
///
/// The app holds no Gemini key: it POSTs the prompt to the proxy, which
/// attaches the key server-side. Authentication is an install token issued by
/// the proxy (see [InstallIdentity]) — the app cannot mint one itself, which is
/// what closed the open-proxy hole in the retired Cloudflare Worker.
///
/// The network is touched ONLY from [generate], and only when the user has
/// explicitly asked for a cloud summary. No pings, no warm-ups, no health
/// checks — those would violate the Karpathy invariants.
///
/// Gemini's window (1M) dwarfs any meeting, so the pipeline always takes the
/// SINGLE-PASS branch here: one composed prompt, one metered call, self-check
/// embedded in the prompt rather than spent as a second request.
class CloudBackend implements SummaryBackend {
  CloudBackend({
    required this.proxyUrlProvider,
    required this.identity,
    required this.cloudEnabled,
    http.Client? client,
    Duration? timeout,
  }) : _client = client ?? http.Client(),
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

  static const _fallbackModelId = 'gemini-3.1-flash-lite';

  /// The proxy reports which model actually answered (`model_id`). We persist
  /// that, not a guess, so a server-side model swap is visible in the meeting's
  /// history. Before the first call there is nothing to report, so we fall back
  /// to the model the proxy is pinned to today.
  String? _lastServerModelId;

  @override
  String get modelId => _lastServerModelId ?? _fallbackModelId;

  @override
  BackendCapabilities get capabilities =>
      const BackendCapabilities(contextTokens: 1000000, maxOutputTokens: 8192);

  @override
  Future<bool> isAvailable() async {
    if (!cloudEnabled()) return false;
    // Deliberately does not ping the proxy: a reachability check would be a
    // background network call. We trust the URL and let generate() report.
    return isConfiguredProxyUrl(proxyUrlProvider());
  }

  /// [temperature] is fixed at 0.4 server-side (`generationConfig` in
  /// `render-proxy/src/gemini.ts`) and is accepted here only for interface
  /// conformance. That is harmless in practice: the cloud path is always
  /// single-pass, and 0.4 is exactly the temperature the reduce stage wants. If
  /// the pipeline ever runs a low-temperature critic through the cloud, the
  /// proxy must learn a `temperature` field first.
  @override
  Future<String> generate({
    required String prompt,
    String? system,
    double temperature = 0.4,
    int? maxOutputTokens,
    CancelToken? cancel,
  }) async {
    // The Privacy tier's promise is enforced HERE, at the socket, not in the
    // widget that draws the button. Do not weaken this to a UI check.
    if (!cloudEnabled()) {
      throw CloudError(
        CloudFailureKind.disabled,
        'Cloud summaries are disabled on this tier.',
      );
    }
    cancel?.throwIfCancelled();

    final base = requireConfiguredProxyUrl(proxyUrlProvider());

    // The rebuilt client composes the ENTIRE prompt (instructions + transcript)
    // and sends no `transcript` field. The proxy appends its own "Transcript:"
    // block only when that field is present, so sending the transcript again
    // here would duplicate it and double the metered input.
    // See render-proxy/src/gemini.ts.
    final body = jsonEncode({
      'prompt': prompt,
      if (system != null && system.trim().isNotEmpty)
        'system_instruction': system,
      'max_output_tokens': maxOutputTokens ?? capabilities.maxOutputTokens,
    });

    var resp = await _post(base, body, forceRefresh: false);

    // 401 means our cached token is not one this server would issue — the
    // pepper rotated, or the token predates the Render backend. Re-register
    // ONCE and retry. If it 401s again the credential is not the problem, so we
    // surface it instead of looping and re-uploading the transcript forever.
    if (resp.statusCode == 401) {
      resp = await _post(base, body, forceRefresh: true);
    }

    switch (resp.statusCode) {
      case 401:
        throw CloudError(
          CloudFailureKind.unauthorized,
          'The cloud proxy rejected this install. Try again later.',
        );
      case 429:
        throw CloudError(
          CloudFailureKind.rateLimited,
          'Cloud rate limit reached. Wait a moment, or summarize on-device.',
        );
      case 402:
        throw CloudError(
          CloudFailureKind.quotaExhausted,
          'Your cloud allowance is used up for this month.',
        );
      case 503:
        throw CloudError(
          CloudFailureKind.budgetExhausted,
          'The cloud service is at its daily limit. Try tomorrow, or '
          'summarize on-device.',
        );
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
      throw CloudError(
        CloudFailureKind.emptyResponse,
        'Cloud summary returned an unreadable response.',
      );
    }
    final text = (json['text'] as String?)?.trim();
    if (text == null || text.isEmpty) {
      throw CloudError(
        CloudFailureKind.emptyResponse,
        'Cloud summary returned empty text.',
      );
    }

    final serverModelId = (json['model_id'] as String?)?.trim();
    if (serverModelId != null && serverModelId.isNotEmpty) {
      _lastServerModelId = serverModelId;
    }

    cancel?.throwIfCancelled();

    // Gemini stopped at maxOutputTokens rather than finishing. The notes are
    // still worth showing, but we must not present a cut-off summary as a whole
    // one (CLAUDE.md: never silently degrade), so we say so IN the output where
    // the user will actually read it.
    if (json['truncated'] == true) {
      return '$text\n\n> ⚠️ This summary hit the cloud output limit and may be '
          'cut off before the last sections.';
    }
    return text;
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
      throw CloudError(
        CloudFailureKind.timeout,
        'The cloud summary timed out. Try again, or summarize on-device.',
      );
    } on IOException catch (e) {
      // SocketException, HandshakeException, TlsException, ... A captive portal
      // throws HandshakeException, not SocketException, so catching only the
      // latter would miss the most common real-world failure.
      throw CloudError(
        CloudFailureKind.offline,
        'Could not reach the cloud proxy: ${truncateForError('$e')}',
      );
    }
  }
}
