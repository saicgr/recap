import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart' hide CancelToken;
import 'package:flutter_gemma_builtin_ai/flutter_gemma_builtin_ai.dart';

import 'summary_backend.dart';
import 'summary_types.dart';

/// The OS-provided on-device model, wired exactly like [GemmaBackend] but with
/// zero download — the operating system owns the weights:
///   * Android  -> Gemini Nano (ML Kit GenAI / AICore), Pixel 9+ / Galaxy S25+.
///   * iOS/macOS -> Apple Foundation Models, iPhone 15 Pro+ / Apple-Silicon Macs
///     with Apple Intelligence enabled.
///
/// Both are reached through the SAME flutter_gemma surface (an
/// `InferenceModelSpec` with `ModelFileType.builtIn`), so this one backend serves
/// both platforms. It replaces the old hand-written Apple method-channel stub,
/// which `flutter_gemma_builtin_ai` makes unnecessary.
///
/// Availability is a RUNTIME property of the device/OS — most phones do NOT have
/// it — so [isAvailable] probes [BuiltInAi.availability] and the router falls
/// through to the downloaded Gemma model when it is absent.
class BuiltinAiBackend implements SummaryBackend {
  BuiltinAiBackend();

  /// Same window class as Gemma E2B (Nano and Apple FM are ~2-3B with small
  /// context), so a long meeting takes the identical chunked / chaptered path.
  static const _contextTokens = 4096;
  static const _maxOutputTokens = 1024;

  InferenceModel? _model;
  bool? _availableCache;

  InferenceModelSpec get _spec =>
      defaultTargetPlatform == TargetPlatform.android
      ? BuiltInAiModels.geminiNano
      : BuiltInAiModels.appleFoundationModels;

  @override
  String get modelId => _spec.name; // 'gemini-nano' | 'apple-foundation-models'

  @override
  BackendCapabilities get capabilities => const BackendCapabilities(
    contextTokens: _contextTokens,
    maxOutputTokens: _maxOutputTokens,
    // The built-in session takes user messages only — no separate system
    // role — so the pipeline's system preamble is prepended to the prompt in
    // [generate], never dropped (it carries the anti-hallucination rules).
    supportsSystemPrompt: false,
  );

  @override
  Future<bool> isAvailable() async {
    if (_availableCache != null) return _availableCache!;
    try {
      _availableCache =
          (await BuiltInAi.availability()) == BuiltInAiAvailability.available;
    } catch (_) {
      _availableCache = false;
    }
    return _availableCache!;
  }

  Future<void> _ensureLoaded(void Function(double)? onProgress) async {
    if (_model != null) return;
    // Make the OS model the active one (idempotent) and, on Android, trigger the
    // first-use AICore download. Then load it. This activates the built-in spec
    // so getActiveModel returns Nano/Apple FM rather than a leftover Gemma.
    await BuiltInAi.ensureReady(
      onProgress: (percent) => onProgress?.call(percent / 100.0),
    );
    await FlutterGemma.installModel(
      modelType: ModelType.general,
      fileType: ModelFileType.builtIn,
    ).fromBundled(_spec.name).install();
    _model = await FlutterGemma.getActiveModel(maxTokens: _contextTokens);
  }

  @override
  Future<String> generate({
    required String prompt,
    String? system,
    double temperature = 0.4,
    int? maxOutputTokens,
    CancelToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    await _ensureLoaded(null);
    cancel?.throwIfCancelled();

    final preamble = system?.trim() ?? '';
    final full = preamble.isEmpty ? prompt : '$preamble\n\n$prompt';

    final session = await _model!.createSession(temperature: temperature);
    try {
      await session.addQueryChunk(Message.text(text: full, isUser: true));
      cancel?.throwIfCancelled();
      final response = (await session.getResponse()).trim();
      cancel?.throwIfCancelled();
      if (response.isEmpty) {
        throw StateError(
          '$modelId returned an empty response ($full.length chars against a '
          '$_contextTokens-token window).',
        );
      }
      return response;
    } on SummaryCancelled {
      try {
        await session.stopGeneration();
      } catch (_) {}
      rethrow;
    } finally {
      await session.close();
    }
  }
}
