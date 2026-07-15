// flutter_gemma 1.x exports its OWN CancelToken; ours (summary_types.dart) is the
// pipeline's cancellation signal. Hide theirs so `CancelToken` here means ours.
import 'package:flutter_gemma/flutter_gemma.dart' hide CancelToken;

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
    if (!FlutterGemma.hasActiveModel()) {
      throw StateError(
        'No active Gemma model. Trigger download via GemmaBackend.download() '
        'before summarizing.',
      );
    }
    // getActiveModel reads the identity persisted by installModel().install()
    // (modelType + fileType), so a .litertlm Gemma 4 and a .task Gemma 3n both
    // load through the same call — the engine registered in
    // FlutterGemma.initialize() picks the right runtime.
    _model = await FlutterGemma.getActiveModel(
      maxTokens: _contextTokens,
      preferredBackend: PreferredBackend.gpu,
    );
  }

  /// True if a model is installed AND active. Does NOT trigger a download —
  /// use [download] for that. Synchronous under the hood (reads persisted
  /// identity), wrapped for interface conformance.
  @override
  Future<bool> isAvailable() async {
    try {
      return FlutterGemma.hasActiveModel();
    } catch (_) {
      return false;
    }
  }

  /// Trigger the model download + activation. UI should show progress (0..1).
  ///
  /// Gemma 4 ships as `.litertlm` (LiteRT-LM engine, NPU-capable); Gemma 3n as
  /// `.task` (MediaPipe). The extension picks the file type, and install() also
  /// sets the model active so [isAvailable] flips to true.
  Future<void> download({
    required String modelUrl,
    void Function(double progress)? onProgress,
  }) async {
    final fileType = modelUrl.toLowerCase().endsWith('.litertlm')
        ? ModelFileType.litertlm
        : ModelFileType.task;
    await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
          fileType: fileType,
        )
        .fromNetwork(modelUrl)
        .withProgress((int p) => onProgress?.call(p / 100.0))
        .install();
  }

  Future<void> delete() async {
    await _model?.close();
    _model = null;
    // Clear the persisted "active model" identity so it isn't auto-restored on
    // next launch. The file removal is handled by the model manager's cleanup;
    // clearing the identity is what makes [isAvailable] read false again.
    await FlutterGemma.clearActiveInferenceIdentity();
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
