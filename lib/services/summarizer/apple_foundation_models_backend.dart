import 'dart:io';

import 'package:flutter/services.dart';

import 'summary_backend.dart';
import 'summary_types.dart';

/// Routes to Apple's Foundation Models framework (iOS 26+, Apple Intelligence
/// eligible devices: iPhone 15 Pro / 16+ / M-series iPad).
///
/// NATIVE TODO — STILL UNIMPLEMENTED. There is no Swift handler yet, so
/// [isAvailable] returns false on every device and the router falls through to
/// Gemma. This backend is nonetheless now fully chunk-aware: the moment someone
/// writes the handler below, long meetings work, because the pipeline sizes its
/// chunks from [capabilities] and never hands us more than we can take.
///
/// Implement `ios/Runner/FoundationModelsChannel.swift`:
///   import FoundationModels
///   let model = SystemLanguageModel.default
///   // `system` carries every anti-hallucination rule — pass it as the
///   // session's instructions, do not concatenate it into the prompt.
///   let session = LanguageModelSession(model: model, instructions: system)
///   let opts = GenerationOptions(temperature: temperature,
///                                maximumResponseTokens: maxOutputTokens)
///   let response = try await session.respond(to: prompt, options: opts)
///   result(["text": response.content])
///
/// Channel name: `com.recapfreenote.recap/apple_foundation_models`
/// Methods:
///   - `isAvailable` → bool
///   - `generate` (args: {prompt: String, system: String?,
///                        temperature: double, maxOutputTokens: int})
///                → {text: String}
class AppleFoundationModelsBackend implements SummaryBackend {
  static const _channel =
      MethodChannel('com.recapfreenote.recap/apple_foundation_models');

  static const _modelId = 'apple-fm-3b';

  /// The on-device Apple model is ~3B with a small window; treat it exactly as
  /// conservatively as Gemma. Unlike Gemma it DOES have a real system-prompt
  /// slot (`LanguageModelSession(instructions:)`).
  static const _contextTokens = 4096;
  static const _maxOutputTokens = 1024;

  bool? _availableCache;

  @override
  String get modelId => _modelId;

  @override
  BackendCapabilities get capabilities => const BackendCapabilities(
        contextTokens: _contextTokens,
        maxOutputTokens: _maxOutputTokens,
      );

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isIOS) return false;
    if (_availableCache != null) return _availableCache!;
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      _availableCache = result ?? false;
    } on MissingPluginException {
      // Native handler not wired yet — this is the branch every build takes
      // today. Not an error: the router falls through to Gemma.
      _availableCache = false;
    } on PlatformException {
      _availableCache = false;
    }
    return _availableCache!;
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

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'generate',
        {
          'prompt': prompt,
          'system': system,
          'temperature': temperature,
          'maxOutputTokens': maxOutputTokens ?? _maxOutputTokens,
        },
      );
      // A cancel that lands while the native side is generating cannot preempt
      // it (the framework exposes no cancellation handle), so we honour it on
      // return instead of handing back a summary the user no longer wants.
      cancel?.throwIfCancelled();

      if (result == null) {
        throw StateError('Apple Foundation Models returned null');
      }
      final text = (result['text'] as String?)?.trim() ?? '';
      if (text.isEmpty) {
        throw StateError('Apple Foundation Models returned an empty response');
      }
      return text;
    } on MissingPluginException {
      throw StateError(
        'AppleFoundationModelsBackend: native handler not registered. '
        'Implement ios/Runner/FoundationModelsChannel.swift.',
      );
    }
  }
}
