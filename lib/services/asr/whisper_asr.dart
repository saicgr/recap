import 'dart:async';

import '../transcriber.dart';
import 'asr_engine.dart';

/// Wraps the existing TranscriberService (whisper_ggml) as an [AsrEngine] so
/// it slots into the same router as the native engines. Whisper is the
/// universal fallback — runs on every platform where flutter_ggml does, and
/// can use any of the tiny/base/small models (tier-controlled by the user's
/// `Tier.whisperCeiling`).
///
/// Streaming via Whisper isn't truly real-time — it batches in 5s chunks via
/// the existing LiveCaptionsService pattern. For now, [transcribeStreaming]
/// returns an empty stream and emits a single AsrUnavailable signal;
/// AsrRouter should prefer native engines for streaming and only call this
/// for file-mode transcribeFile.
class WhisperAsrEngine implements AsrEngine {
  WhisperAsrEngine({required this.transcriber});
  final TranscriberService transcriber;

  @override
  String get id => 'whisper';

  @override
  String get displayName => 'Whisper (Recap-bundled)';

  @override
  Future<bool> isAvailable({String lang = 'en'}) async {
    return transcriber.isModelInstalled;
  }

  @override
  Stream<AsrPartial> transcribeStreaming({String lang = 'en'}) async* {
    // Whisper-streaming is provided by LiveCaptionsService, which already
    // chunks the in-progress WAV every 5s. The AsrRouter routes live
    // captions through that existing pipeline rather than through this
    // method. Surface a clear error if someone calls this directly.
    throw const AsrUnavailableException(
        AsrUnavailableReason.unsupportedPlatform,
        'Whisper streaming is provided by LiveCaptionsService — use that '
        'service for streaming captions, not AsrEngine.transcribeStreaming.');
  }

  @override
  Future<String> transcribeFile(String wavPath, {String lang = 'en'}) async {
    if (!await transcriber.isModelInstalled) {
      throw const AsrUnavailableException(AsrUnavailableReason.notInstalled,
          'Whisper model not downloaded yet.');
    }
    return transcriber.transcribe(wavPath, lang: lang);
  }
}
