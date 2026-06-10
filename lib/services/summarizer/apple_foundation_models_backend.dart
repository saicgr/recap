import 'dart:io';

import 'package:flutter/services.dart';

import '../../billing/persona.dart';
import 'summary_backend.dart';

/// Routes to Apple's Foundation Models framework (iOS 26+, Apple Intelligence
/// eligible devices: iPhone 15 Pro / 16+ / M-series iPad).
///
/// NATIVE TODO: implement the Swift method-channel handler in
/// `ios/Runner/FoundationModelsChannel.swift`:
///   import FoundationModels
///   let model = SystemLanguageModel.default
///   let session = LanguageModelSession(model: model, instructions: ...)
///   let response = try await session.respond(to: prompt)
///   result(["text": response.content, "modelId": "apple-fm-3b"])
///
/// Channel name: `com.recapfreenote.recap/apple_foundation_models`
/// Methods:
///   - `isAvailable` → bool
///   - `summarize` (args: {prompt: String}) → {text: String, modelId: String}
class AppleFoundationModelsBackend implements SummaryBackend {
  static const _channel =
      MethodChannel('com.recapfreenote.recap/apple_foundation_models');

  bool? _availableCache;

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isIOS) return false;
    if (_availableCache != null) return _availableCache!;
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      _availableCache = result ?? false;
    } on MissingPluginException {
      // Native handler not wired yet.
      _availableCache = false;
    } on PlatformException {
      _availableCache = false;
    }
    return _availableCache!;
  }

  @override
  Future<SummaryResult> summarize({
    required String transcript,
    required Persona persona,
    void Function(double progress)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final prompt = '${persona.prompt.trim()}\n\nTranscript:\n$transcript';

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'summarize',
        {'prompt': prompt},
      );
      stopwatch.stop();

      if (result == null) {
        throw StateError('Apple Foundation Models returned null');
      }
      final text = (result['text'] as String?)?.trim() ?? '';
      if (text.isEmpty) {
        throw StateError('Apple Foundation Models returned empty summary');
      }
      return SummaryResult(
        text: text,
        modelId: result['modelId'] as String? ?? 'apple-fm-3b',
        processingTime: stopwatch.elapsed,
      );
    } on MissingPluginException {
      throw StateError(
        'AppleFoundationModelsBackend: native handler not registered. '
        'Implement ios/Runner/FoundationModelsChannel.swift.',
      );
    }
  }
}
