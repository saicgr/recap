import 'dart:async';

/// Single emitted ASR partial — either a streaming chunk (isFinal=false) or
/// the closed-out final segment for that audio window.
class AsrPartial {
  final String text;
  final bool isFinal;
  final int startMs;
  final int endMs;
  final double? confidence;
  const AsrPartial({
    required this.text,
    required this.isFinal,
    required this.startMs,
    required this.endMs,
    this.confidence,
  });
}

/// Reasons a backend may refuse a request. Routers use this to pick the next
/// fallback without prompting the user.
enum AsrUnavailableReason {
  unsupportedPlatform,
  unsupportedLanguage,
  permissionDenied,
  noNetworkRequiredButOffline, // for backends that need network bootstrap
  notInstalled, // e.g. Whisper model not downloaded yet
}

class AsrUnavailableException implements Exception {
  final AsrUnavailableReason reason;
  final String? detail;
  const AsrUnavailableException(this.reason, [this.detail]);
  @override
  String toString() =>
      'AsrUnavailableException($reason${detail == null ? '' : ': $detail'})';
}

/// One ASR backend. Implementations:
///   - AppleAsrEngine (iOS + macOS, SFSpeechRecognizer)
///   - AndroidAsrEngine (Android 13+ on-device SpeechRecognizer)
///   - WhisperAsrEngine (wraps TranscriberService; fallback on every platform)
///
/// Routers compose these — see asr_router.dart.
abstract class AsrEngine {
  String get id; // 'apple' | 'android' | 'whisper' | 'windows'
  String get displayName;

  /// True if the engine can run on this device, today, for [lang].
  Future<bool> isAvailable({String lang = 'en'});

  /// Stream partials from microphone audio (real-time mode). Caller cancels
  /// the subscription to stop. The stream emits both interim partials and
  /// per-utterance finals; callers can filter via [AsrPartial.isFinal].
  Stream<AsrPartial> transcribeStreaming({String lang = 'en'});

  /// Transcribe a 16 kHz mono WAV file (one-shot, used for final-quality
  /// passes after recording ends).
  Future<String> transcribeFile(String wavPath, {String lang = 'en'});
}
