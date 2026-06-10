import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../billing/persona.dart';
import 'summary_backend.dart';

/// Cloud summaries via the Render proxy → Gemini 3.1 Flash Lite.
///
/// (Originally planned on Cloudflare Workers; switched to Render per
/// Decision 11.3 in the plan — Express/Hono on Render's hobby tier with
/// per-IP rate limiting + daily budget cap. The directory name
/// `cloudflare-worker/` is legacy — rename to `render-proxy/` when the
/// proxy code is moved.)
///
/// The proxy is in `render-proxy/` (or legacy `cloudflare-worker/`).
/// Deploy it, then put the URL + per-install token here. App never sees
/// the Gemini API key.
class CloudBackend implements SummaryBackend {
  CloudBackend({
    required this.workerUrl,
    required this.installTokenFuture,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Set this to your deployed proxy URL (Render). Leaving the placeholder
  /// makes the backend report unavailable so we don't accidentally call a
  /// dead URL.
  static const placeholderUrl = 'https://recap-proxy.example.onrender.com';

  final String workerUrl;
  /// The install token is generated asynchronously after first launch (the
  /// secure-storage RSA key gen takes ~130ms). We await this future on the
  /// first actual cloud call so it never blocks app startup.
  final Future<String> installTokenFuture;
  final http.Client _client;

  @override
  Future<bool> isAvailable() async {
    if (workerUrl.isEmpty || workerUrl == placeholderUrl) return false;
    // We don't ping on availability check — that would be a background ping,
    // which violates Karpathy invariants. We trust the URL.
    return true;
  }

  @override
  Future<SummaryResult> summarize({
    required String transcript,
    required Persona persona,
    void Function(double progress)? onProgress,
  }) async {
    if (!await isAvailable()) {
      throw StateError(
        'CloudBackend: workerUrl is not configured. '
        'Deploy cloudflare-worker/ and set the URL.',
      );
    }

    final stopwatch = Stopwatch()..start();
    final body = jsonEncode({
      'persona_key': persona.key,
      'prompt': persona.prompt.trim(),
      'transcript': transcript,
    });

    final token = await installTokenFuture;
    final response = await _client.post(
      Uri.parse('$workerUrl/v1/summarize'),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $token',
      },
      body: body,
    );
    stopwatch.stop();

    if (response.statusCode == 429) {
      throw StateError(
        'Cloud rate-limited (429). Wait a moment and try again, or '
        'fall back to on-device summary.',
      );
    }
    if (response.statusCode >= 400) {
      throw StateError(
        'Cloud summary failed: HTTP ${response.statusCode} ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (json['text'] as String?)?.trim();
    if (text == null || text.isEmpty) {
      throw StateError('Cloud summary returned empty text');
    }
    return SummaryResult(
      text: text,
      modelId: json['model_id'] as String? ?? 'gemini-3.1-flash-lite',
      processingTime: stopwatch.elapsed,
    );
  }
}
