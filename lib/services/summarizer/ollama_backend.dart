import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../billing/persona.dart';
import 'summary_backend.dart';

/// Desktop-only summarizer that talks to a locally-running Ollama daemon at
/// `http://localhost:11434`. Same on-device semantics as Gemma — runs on the
/// user's CPU/GPU, costs us $0, fully compatible with the Privacy tier.
///
/// Why this exists: desktop users have 16-128 GB of RAM vs 6-16 GB on phones.
/// That fits 27B+ parameter models (gemma3:27b, llama3.3:70b, qwen2.5:32b)
/// which deliver markedly better summary quality than Gemma 4 E4B at 4 GB.
/// If Ollama is installed + a model is pulled, we use it; otherwise we fall
/// back through the normal SummaryRouter priority.
///
/// Status is published via a [ChangeNotifier] so the Settings tile can show
/// live detection state without ad-hoc polling everywhere.
class OllamaBackend extends ChangeNotifier implements SummaryBackend {
  OllamaBackend({String? baseUrl})
      : baseUrl = baseUrl ?? _defaultUrl();

  static String _defaultUrl() {
    const fromEnv = String.fromEnvironment('RECAP_OLLAMA_URL');
    return fromEnv.isNotEmpty ? fromEnv : 'http://localhost:11434';
  }

  /// Where the daemon listens. Defaults to `http://localhost:11434`. Power
  /// tier users can point at a LAN IP via [updateBaseUrl]. Privacy tier
  /// hardcodes this to localhost (custom-URL field hidden on Privacy).
  String baseUrl;

  /// Last-detected list of installed models, populated by [refreshStatus].
  /// Empty list = daemon reachable but no models pulled yet.
  List<OllamaModel> availableModels = const [];

  /// User-selected model name. If null, we auto-pick the best by parameter
  /// count + instruction-tuned heuristics.
  String? preferredModel;

  OllamaStatus _status = OllamaStatus.unknown;
  String? _failureReason;
  DateTime? _lastPingAt;

  OllamaStatus get status => _status;
  String? get failureReason => _failureReason;
  DateTime? get lastPingAt => _lastPingAt;

  /// True only on desktop platforms — mobile never tries to detect Ollama
  /// because (a) the daemon doesn't run on iOS/Android, (b) no point loading
  /// HTTP clients pointed at localhost on a phone.
  static bool get isSupportedPlatform =>
      !kIsWeb &&
      (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  /// Probe the daemon. Idempotent; safe to call from settings screen
  /// initState + on a periodic timer.
  Future<void> refreshStatus() async {
    if (!isSupportedPlatform) {
      _setStatus(OllamaStatus.unsupportedPlatform);
      return;
    }
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/tags'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode != 200) {
        _failureReason = 'HTTP ${res.statusCode}';
        _setStatus(OllamaStatus.daemonNotReachable);
        return;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final models = (body['models'] as List<dynamic>? ?? const [])
          .map((m) {
            final map = m as Map<String, dynamic>;
            return OllamaModel(
              name: map['name'] as String? ?? '',
              sizeBytes: (map['size'] as num?)?.toInt() ?? 0,
              parameterSize: map['details']?['parameter_size'] as String?,
              family: map['details']?['family'] as String?,
              modifiedAt: map['modified_at'] as String?,
            );
          })
          .where((m) => m.name.isNotEmpty)
          .toList();
      availableModels = models;
      _lastPingAt = DateTime.now();
      if (models.isEmpty) {
        _setStatus(OllamaStatus.noModelsPulled);
      } else {
        _setStatus(OllamaStatus.ready);
      }
    } on SocketException {
      _failureReason = 'Connection refused — daemon not running?';
      _setStatus(OllamaStatus.daemonNotReachable);
    } on TimeoutException {
      _failureReason = 'Timed out after 2s';
      _setStatus(OllamaStatus.daemonNotReachable);
    } catch (e) {
      _failureReason = e.toString();
      _setStatus(OllamaStatus.daemonNotReachable);
    }
  }

  void updateBaseUrl(String url) {
    if (url == baseUrl) return;
    baseUrl = url;
    notifyListeners();
    unawaited(refreshStatus());
  }

  void selectModel(String? name) {
    preferredModel = name;
    notifyListeners();
  }

  /// Returns the model we'd use for the next summary, or null if none usable.
  /// Heuristic: user's [preferredModel] if installed → biggest instruction-
  /// tuned model installed → biggest model installed.
  OllamaModel? bestModel() {
    if (availableModels.isEmpty) return null;
    if (preferredModel != null) {
      final picked = availableModels
          .where((m) => m.name == preferredModel)
          .toList(growable: false);
      if (picked.isNotEmpty) return picked.first;
    }
    final sorted = [...availableModels];
    sorted.sort((a, b) {
      // Instruction-tuned models (':instruct', '-it', no suffix) score
      // higher than base/code models for summarization.
      final aIt = _looksInstructionTuned(a.name) ? 1 : 0;
      final bIt = _looksInstructionTuned(b.name) ? 1 : 0;
      if (aIt != bIt) return bIt - aIt;
      return b.sizeBytes - a.sizeBytes;
    });
    return sorted.first;
  }

  bool _looksInstructionTuned(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('code') || lower.contains('coder')) return false;
    return lower.contains('instruct') ||
        lower.contains('-it') ||
        lower.contains(':instruct') ||
        // Most modern "default" Ollama tags ship instruction-tuned. Names
        // like `gemma3:27b`, `llama3.3`, `qwen2.5:32b` are IT by default.
        !lower.contains('base');
  }

  @override
  Future<bool> isAvailable() async {
    if (!isSupportedPlatform) return false;
    if (_status == OllamaStatus.unknown) await refreshStatus();
    return _status == OllamaStatus.ready && bestModel() != null;
  }

  @override
  Future<SummaryResult> summarize({
    required String transcript,
    required Persona persona,
    void Function(double progress)? onProgress,
  }) async {
    if (!isSupportedPlatform) {
      throw StateError('Ollama backend only runs on desktop platforms.');
    }
    final model = bestModel();
    if (model == null) {
      throw StateError(
          'No Ollama models installed. Run `ollama pull gemma3:27b` (or similar) first.');
    }
    final stopwatch = Stopwatch()..start();
    final prompt = '${persona.prompt.trim()}\n\nTranscript:\n$transcript';

    // Use the non-streaming /api/generate path for simplicity; the router
    // can switch to /api/chat streaming later if we want token-by-token UI.
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/generate'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'model': model.name,
            'prompt': prompt,
            'stream': false,
            'options': {
              'temperature': 0.4,
              'num_ctx': _contextWindowFor(model),
            },
          }),
        )
        .timeout(const Duration(minutes: 5));
    if (res.statusCode != 200) {
      throw StateError('Ollama returned HTTP ${res.statusCode}: ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final text = (body['response'] as String? ?? '').trim();
    if (text.isEmpty) {
      throw StateError('Ollama returned empty summary');
    }
    stopwatch.stop();
    return SummaryResult(
      text: text,
      modelId: 'ollama:${model.name}',
      processingTime: stopwatch.elapsed,
    );
  }

  /// Conservative per-family context windows. Anything we don't recognize
  /// gets 8K which is the universal safe minimum for modern open-weight LLMs.
  int _contextWindowFor(OllamaModel m) {
    final lower = m.name.toLowerCase();
    if (lower.startsWith('gemma3')) return 128 * 1024; // Gemma 3 = 128K
    if (lower.startsWith('llama3.3') || lower.startsWith('llama3.2')) {
      return 128 * 1024;
    }
    if (lower.startsWith('qwen2.5') || lower.startsWith('qwen3')) {
      return 32 * 1024;
    }
    if (lower.startsWith('mistral')) return 32 * 1024;
    return 8 * 1024;
  }

  /// Trigger `ollama pull` for the given model. Streams progress via
  /// [onProgress] (0..1). Throws on network / API error.
  Future<void> pullModel(
    String modelName, {
    void Function(double progress, String status)? onProgress,
  }) async {
    final req = http.Request('POST', Uri.parse('$baseUrl/api/pull'))
      ..headers['content-type'] = 'application/json'
      ..body = jsonEncode({'name': modelName, 'stream': true});
    final res = await http.Client().send(req);
    if (res.statusCode != 200) {
      throw StateError('Ollama pull failed: HTTP ${res.statusCode}');
    }
    await for (final line
        in res.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.isEmpty) continue;
      try {
        final m = jsonDecode(line) as Map<String, dynamic>;
        final completed = (m['completed'] as num?)?.toDouble() ?? 0;
        final total = (m['total'] as num?)?.toDouble() ?? 0;
        final status = m['status'] as String? ?? '';
        if (total > 0 && onProgress != null) {
          onProgress(completed / total, status);
        }
      } catch (_) {/* skip non-JSON lines */}
    }
    await refreshStatus();
  }

  void _setStatus(OllamaStatus s) {
    _status = s;
    notifyListeners();
  }
}

class OllamaModel {
  final String name;
  final int sizeBytes;
  final String? parameterSize;
  final String? family;
  final String? modifiedAt;
  const OllamaModel({
    required this.name,
    required this.sizeBytes,
    this.parameterSize,
    this.family,
    this.modifiedAt,
  });
}

enum OllamaStatus {
  unknown,
  unsupportedPlatform, // mobile — never enters daemonNotReachable
  daemonNotReachable,
  noModelsPulled,
  ready,
}
