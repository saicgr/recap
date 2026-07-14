import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'summary_backend.dart';
import 'summary_types.dart';

/// Routes cloud summaries through the user's own provider key. No proxy
/// involved — the key + the prompt go directly to the chosen provider's API.
/// Their key, their bill, their privacy boundary.
///
/// Supported providers (set during onboarding via ByokScreen):
///   - `gemini`    → Google Generative Language API
///   - `openai`    → OpenAI Chat Completions
///   - `anthropic` → Anthropic Messages API
///
/// Every supported provider has a long window, so the pipeline takes the
/// single-pass branch: one call, one bill, self-check embedded in the prompt.
class ByokBackend implements SummaryBackend {
  static const _storage = FlutterSecureStorage();
  static const _kProvider = 'byok_provider';
  static const _kKey = 'byok_api_key';

  static const _geminiModel = 'gemini-2.0-flash';
  static const _openaiModel = 'gpt-4o-mini';
  static const _anthropicModel = 'claude-3-5-haiku-latest';

  final http.Client _client;

  ByokBackend({http.Client? client}) : _client = client ?? http.Client();

  /// Set as soon as we know which provider is configured, so the pipeline can
  /// stamp the right id on the summary. Defaults to a generic id before the
  /// keychain has been read.
  String _resolvedModelId = 'byok';

  @override
  String get modelId => _resolvedModelId;

  /// The floor across the three supported providers — the smallest window any
  /// of them offers is far larger than this, so it is safe for all three, and
  /// generous enough that a meeting never needs chunking on the BYOK path.
  @override
  BackendCapabilities get capabilities => const BackendCapabilities(
        contextTokens: 128000,
        maxOutputTokens: 4096,
      );

  Future<({String provider, String key})?> _credentials() async {
    final provider = await _storage.read(key: _kProvider);
    final key = await _storage.read(key: _kKey);
    if (provider == null || key == null || key.isEmpty) return null;
    _resolvedModelId = 'byok:${_modelFor(provider) ?? provider}';
    return (provider: provider, key: key);
  }

  String? _modelFor(String provider) => switch (provider) {
        'gemini' => _geminiModel,
        'openai' => _openaiModel,
        'anthropic' => _anthropicModel,
        _ => null,
      };

  @override
  Future<bool> isAvailable() async => (await _credentials()) != null;

  @override
  Future<String> generate({
    required String prompt,
    String? system,
    double temperature = 0.4,
    int? maxOutputTokens,
    CancelToken? cancel,
  }) async {
    cancel?.throwIfCancelled();

    final creds = await _credentials();
    if (creds == null) {
      throw StateError('ByokBackend: no key configured.');
    }
    final sys =
        (system == null || system.trim().isEmpty) ? null : system.trim();
    final maxOut = maxOutputTokens ?? capabilities.maxOutputTokens;

    cancel?.throwIfCancelled();

    final text = await switch (creds.provider) {
      'gemini' => _gemini(creds.key, prompt, sys, temperature, maxOut),
      'openai' => _openai(creds.key, prompt, sys, temperature, maxOut),
      'anthropic' => _anthropic(creds.key, prompt, sys, temperature, maxOut),
      _ => throw StateError('Unknown BYOK provider: ${creds.provider}'),
    };

    cancel?.throwIfCancelled();

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw StateError(
          'BYOK provider "${creds.provider}" returned an empty summary');
    }
    return trimmed;
  }

  Future<String> _gemini(
    String key,
    String prompt,
    String? system,
    double temperature,
    int maxOutputTokens,
  ) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$key');
    final resp = await _client.post(
      url,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        // The preamble carries every anti-hallucination rule, so it goes in the
        // dedicated system slot where the model weights it hardest.
        if (system != null)
          'systemInstruction': {
            'parts': [
              {'text': system}
            ]
          },
        'generationConfig': {
          'temperature': temperature,
          'topK': 40,
          'maxOutputTokens': maxOutputTokens,
        },
      }),
    );
    if (resp.statusCode >= 400) {
      throw StateError('Gemini ${resp.statusCode}: ${_truncate(resp.body)}');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return '';
    final content = (candidates.first as Map)['content'] as Map?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) return '';
    // A long answer can arrive as several parts. Joining them is a no-op for
    // the single-part case and stops us silently dropping the tail otherwise.
    return parts.map((p) => (p as Map)['text'] as String? ?? '').join();
  }

  Future<String> _openai(
    String key,
    String prompt,
    String? system,
    double temperature,
    int maxOutputTokens,
  ) async {
    final resp = await _client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $key',
      },
      body: jsonEncode({
        'model': _openaiModel,
        'messages': [
          if (system != null) {'role': 'system', 'content': system},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': temperature,
        'max_tokens': maxOutputTokens,
      }),
    );
    if (resp.statusCode >= 400) {
      throw StateError('OpenAI ${resp.statusCode}: ${_truncate(resp.body)}');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) return '';
    final message = (choices.first as Map)['message'] as Map?;
    return message?['content'] as String? ?? '';
  }

  Future<String> _anthropic(
    String key,
    String prompt,
    String? system,
    double temperature,
    int maxOutputTokens,
  ) async {
    final resp = await _client.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        'x-api-key': key,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _anthropicModel,
        'max_tokens': maxOutputTokens,
        'temperature': temperature,
        if (system != null) 'system': system,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );
    if (resp.statusCode >= 400) {
      throw StateError('Anthropic ${resp.statusCode}: ${_truncate(resp.body)}');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final blocks = json['content'] as List?;
    if (blocks == null || blocks.isEmpty) return '';
    // The Messages API returns a list of content blocks. Concatenate the text
    // ones rather than taking only the first — a long answer is split.
    return blocks
        .whereType<Map>()
        .map((b) => b['text'] as String? ?? '')
        .join();
  }

  String _truncate(String s) => s.length > 400 ? '${s.substring(0, 400)}…' : s;
}
