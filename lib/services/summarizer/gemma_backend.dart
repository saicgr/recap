import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/pigeon.g.dart';

import 'summary_backend.dart';
import 'summary_types.dart';

/// On-device summary via flutter_gemma + Gemma 4 E2B (~2.4 GB LiteRT) on
/// Free, Gemma 4 E4B (~4.3 GB) on Pro+ where storage allows. Downloaded on
/// first use; cached locally forever. Gemma 4 (released 2026-03-31) supports
/// 140+ languages and 256K context — replaces Gemma 3n.
///
/// A dumb generation engine: it owns no prompt. [SummaryPipeline] does the
/// chunking, the map-reduce and the critic pass, and hands us one already-
/// composed prompt per call.
class GemmaBackend implements SummaryBackend {
  static const _modelId = 'gemma-4-e2b-it';

  /// COMBINED input+output budget. flutter_gemma's `maxTokens` is not an input
  /// allowance — the response is drawn from the same window — which is why the
  /// pre-rebuild code silently truncated any meeting over ~15 minutes.
  ///
  /// Deliberately NOT raised even though Gemma 4 claims 256K: the LiteRT
  /// runtime allocates the KV cache up front, and 4096 is what fits in RAM on
  /// the low-end Android devices this tier is meant to serve. The fix for long
  /// meetings is chunking, not a bigger window.
  static const _contextTokens = 4096;
  static const _maxOutputTokens = 1024;

  InferenceModel? _model;

  @override
  String get modelId => _modelId;

  @override
  BackendCapabilities get capabilities => const BackendCapabilities(
        contextTokens: _contextTokens,
        maxOutputTokens: _maxOutputTokens,
        // A MediaPipe `.task` session takes user messages only — there is no
        // system role to address. We therefore prepend the preamble to the
        // prompt in [generate] rather than dropping it: it carries every
        // anti-hallucination rule and losing it is how the model starts
        // inventing pack sizes.
        supportsSystemPrompt: false,
      );

  Future<void> _ensureLoaded() async {
    if (_model != null) return;
    final manager = FlutterGemmaPlugin.instance.modelManager;
    if (!await manager.isModelInstalled) {
      throw StateError(
        'Gemma model not installed. Trigger download via GemmaBackend.download() '
        'before summarizing.',
      );
    }
    _model = await FlutterGemmaPlugin.instance.createModel(
      modelType: ModelType.gemmaIt,
      preferredBackend: PreferredBackend.gpu,
      maxTokens: _contextTokens,
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

  /// Trigger the model download. UI should show progress (0..1).
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
    await _model?.close();
    _model = null;
  }

  /// [maxOutputTokens] is accepted for interface conformance but cannot be
  /// enforced: a MediaPipe session exposes no output cap, it just draws from
  /// the shared [_contextTokens] window until it emits a stop token. The
  /// pipeline already reserves [_maxOutputTokens] of that window when it packs
  /// the prompt, which is what keeps the response from being cut off.
  @override
  Future<String> generate({
    required String prompt,
    String? system,
    double temperature = 0.4,
    int? maxOutputTokens,
    CancelToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    await _ensureLoaded();
    cancel?.throwIfCancelled();

    final preamble = system?.trim() ?? '';
    final full = preamble.isEmpty ? prompt : '$preamble\n\n$prompt';

    // One session PER generate() call, closed in a finally.
    //
    // The map stage calls generate() once per chunk. A reused session keeps
    // every previous chunk in its KV cache, so chunk 2 would overflow the 4096
    // window that chunk 1 already half-filled — and the native session handle
    // would leak for the length of the chain. Creating a fresh one costs a few
    // hundred ms and is the only correct option.
    final session = await _model!.createSession(
      temperature: temperature,
      randomSeed: 1,
      topK: 40,
    );
    try {
      await session.addQueryChunk(Message.text(text: full, isUser: true));
      cancel?.throwIfCancelled();

      final response = await session.getResponse();
      cancel?.throwIfCancelled();

      final text = response.trim();
      if (text.isEmpty) {
        // Never hand back "" as if it were a summary (CLAUDE.md: no silent
        // degradation). An empty response here usually means the prompt
        // overflowed the window, so say so.
        throw StateError(
          'Gemma ($_modelId) returned an empty response. The prompt was '
          '${full.length} chars against a $_contextTokens-token combined '
          'window.',
        );
      }
      return text;
    } on SummaryCancelled {
      // The user walked away mid-generation. Ask the runtime to stop rather
      // than letting the GPU finish work nobody will read.
      try {
        await session.stopGeneration();
      } catch (_) {
        // Best-effort: the session may already have finished or be torn down.
        // The close() in the finally is what actually frees it.
      }
      rethrow;
    } finally {
      await session.close();
    }
  }
}
