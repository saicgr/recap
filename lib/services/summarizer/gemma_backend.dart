import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/pigeon.g.dart';

import '../../billing/persona.dart';
import 'summary_backend.dart';

/// On-device summary via flutter_gemma + Gemma 4 E2B (~2.4 GB LiteRT) on
/// Free, Gemma 4 E4B (~4.3 GB) on Pro+ where storage allows. Downloaded on
/// first use; cached locally forever. Gemma 4 (released 2026-03-31) supports
/// 140+ languages and 256K context — replaces Gemma 3n.
class GemmaBackend implements SummaryBackend {
  static const _modelId = 'gemma-4-e2b-it';

  InferenceModel? _model;
  InferenceModelSession? _session;

  Future<void> _ensureLoaded() async {
    if (_model != null) return;
    final manager = FlutterGemmaPlugin.instance.modelManager;
    if (!await manager.isModelInstalled) {
      throw StateError(
        'Gemma model not installed. Trigger download via GemmaBackend.download() '
        'before calling summarize().',
      );
    }
    _model = await FlutterGemmaPlugin.instance.createModel(
      modelType: ModelType.gemmaIt,
      preferredBackend: PreferredBackend.gpu,
      maxTokens: 4096,
    );
  }

  /// Returns true if the model file is present on disk. Does NOT trigger a
  /// download — use [download] for that.
  @override
  Future<bool> isAvailable() async {
    try {
      return await FlutterGemmaPlugin.instance.modelManager.isModelInstalled;
    } catch (_) {
      return false;
    }
  }

  /// Trigger the ~1.4 GB model download. UI should show progress (0..1).
  Future<void> download({
    required String modelUrl,
    void Function(double progress)? onProgress,
  }) async {
    final manager = FlutterGemmaPlugin.instance.modelManager;
    final stream = manager.downloadModelFromNetworkWithProgress(modelUrl);
    await for (final progress in stream) {
      onProgress?.call(progress / 100.0);
    }
  }

  Future<void> delete() async {
    await FlutterGemmaPlugin.instance.modelManager.deleteModel();
    await _session?.close();
    _session = null;
    _model = null;
  }

  @override
  Future<SummaryResult> summarize({
    required String transcript,
    required Persona persona,
    void Function(double progress)? onProgress,
  }) async {
    await _ensureLoaded();
    final stopwatch = Stopwatch()..start();
    final prompt = '${persona.prompt.trim()}\n\nTranscript:\n$transcript';

    _session = await _model!.createSession(
      temperature: 0.4,
      randomSeed: 1,
      topK: 40,
    );
    try {
      await _session!.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await _session!.getResponse();
      stopwatch.stop();

      final text = response.trim();
      if (text.isEmpty) {
        throw StateError('Gemma returned empty summary');
      }
      return SummaryResult(
        text: text,
        modelId: _modelId,
        processingTime: stopwatch.elapsed,
      );
    } finally {
      await _session?.close();
      _session = null;
    }
  }
}
