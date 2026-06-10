import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../billing/persona.dart';
import 'summary_backend.dart';

/// Routes cloud summaries through the user's own provider key. No Worker
/// proxy involved — the key + the transcript text go directly to the chosen
/// provider's API. Their key, their bill, their privacy boundary.
///
/// Supported providers (set during onboarding via ByokScreen):
///   - `gemini`    → Google Generative Language API
///   - `openai`    → OpenAI Chat Completions
///   - `anthropic` → Anthropic Messages API
class ByokBackend implements SummaryBackend {
  static const _storage = FlutterSecureStorage();
  static const _kProvider = 'byok_provider';
  static const _kKey = 'byok_api_key';

  final http.Client _client;

  ByokBackend({http.Client? client}) : _client = client ?? http.Client();

  Future<({String provider, String key})?> _credentials() async {
    final provider = await _storage.read(key: _kProvider);
    final key = await _storage.read(key: _kKey);
    if (provider == null || key == null || key.isEmpty) return null;
    return (provider: provider, key: key);
  }

  @override
  Future<bool> isAvailable() async => (await _credentials()) != null;

  @override
  Future<SummaryResult> summarize({
    required String transcript,
    required Persona persona,
    void Function(double progress)? onProgress,
  }) async {
    final creds = await _credentials();
    if (creds == null) {
      throw StateError('ByokBackend: no key configured.');
    }
    final prompt = '${persona.prompt.trim()}\n\nTranscript:\n$transcript';
    final stopwatch = Stopwatch()..start();
    final (text, modelId) = await switch (creds.provider) {
      'gemini' => _gemini(creds.key, prompt),
      'openai' => _openai(creds.key, prompt),
      'anthropic' => _anthropic(creds.key, prompt),
      _ => throw StateError('Unknown BYOK provider: ${creds.provider}'),
    };
    stopwatch.stop();
    if (text.trim().isEmpty) {
      throw StateError('BYOK provider returned empty summary');
    }
    return SummaryResult(
      text: text.trim(),
      modelId: 'byok:$modelId',
      processingTime: stopwatch.elapsed,
    );
  }

  Future<(String text, String modelId)> _gemini(
      String key, String prompt) async {
    const model = 'gemini-2.0-flash';
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key');
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
        'generationConfig': {
          'temperature': 0.4,
          'topK': 40,
          'maxOutputTokens': 2048,
        },
      }),
    );
    if (resp.statusCode >= 400) {
      throw StateError(
          'Gemini ${resp.statusCode}: ${_truncate(resp.body)}');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final text = (json['candidates'] as List?)
        ?.firstOrNull?['content']?['parts']?[0]?['text'] as String?;
    return (text ?? '', model);
  }

  Future<(String text, String modelId)> _openai(
      String key, String prompt) async {
    const model = 'gpt-4o-mini';
    final resp = await _client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $key',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.4,
      }),
    );
    if (resp.statusCode >= 400) {
      throw StateError(
          'OpenAI ${resp.statusCode}: ${_truncate(resp.body)}');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final text = (json['choices'] as List?)
        ?.firstOrNull?['message']?['content'] as String?;
    return (text ?? '', model);
  }

  Future<(String text, String modelId)> _anthropic(
      String key, String prompt) async {
    const model = 'claude-3-5-haiku-latest';
    final resp = await _client.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        'x-api-key': key,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': 2048,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );
    if (resp.statusCode >= 400) {
      throw StateError(
          'Anthropic ${resp.statusCode}: ${_truncate(resp.body)}');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final blocks = json['content'] as List?;
    final text = blocks?.firstOrNull?['text'] as String?;
    return (text ?? '', model);
  }

  String _truncate(String s) =>
      s.length > 400 ? '${s.substring(0, 400)}…' : s;
}
