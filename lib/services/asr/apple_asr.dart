import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'asr_engine.dart';

/// Apple's SFSpeechRecognizer (iOS 13+ / macOS 10.15+). Fully on-device on
/// iOS 13+ when `requiresOnDeviceRecognition = true`. Free; uses the Neural
/// Engine. The platform channel lives in `ios/Runner/AppleAsrBridge.swift`
/// and `macos/Runner/AppleAsrBridge.swift` (D15.2).
///
/// **Battery win:** measured ~5-10× more efficient than Whisper-small running
/// on CPU. The reason this engine is the default for live captions on iOS.
class AppleAsrEngine implements AsrEngine {
  static const _method = MethodChannel('recap.asr.apple');
  static const _events = EventChannel('recap.asr.apple.events');

  @override
  String get id => 'apple';

  @override
  String get displayName => 'Apple Speech (on-device)';

  bool get _supportedPlatform => Platform.isIOS || Platform.isMacOS;

  @override
  Future<bool> isAvailable({String lang = 'en'}) async {
    if (!_supportedPlatform) return false;
    try {
      final res = await _method.invokeMethod<bool>('isAvailable', {
        'lang': lang,
      });
      return res ?? false;
    } on MissingPluginException {
      // Native bridge not installed in this build (e.g. dev hot-reload before
      // a clean build). Treat as unavailable; caller falls back to Whisper.
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Stream<AsrPartial> transcribeStreaming({String lang = 'en'}) async* {
    if (!_supportedPlatform) {
      throw const AsrUnavailableException(
        AsrUnavailableReason.unsupportedPlatform,
      );
    }
    // Native side configures AVAudioSession, installs an audio tap, and
    // feeds the SFSpeechRecognizer recognition request. The 1-minute
    // streaming limit is handled by the native bridge: it transparently
    // closes + reopens the request every 50s and merges results.
    try {
      await _method.invokeMethod<void>('startStreaming', {'lang': lang});
    } on MissingPluginException {
      throw const AsrUnavailableException(
        AsrUnavailableReason.unsupportedPlatform,
        'Apple ASR native bridge not installed',
      );
    }
    try {
      await for (final event in _events.receiveBroadcastStream()) {
        if (event is! Map) continue;
        final map = Map<String, dynamic>.from(event);
        yield AsrPartial(
          text: map['text'] as String? ?? '',
          isFinal: map['isFinal'] as bool? ?? false,
          startMs: (map['startMs'] as num?)?.toInt() ?? 0,
          endMs: (map['endMs'] as num?)?.toInt() ?? 0,
          confidence: (map['confidence'] as num?)?.toDouble(),
        );
      }
    } finally {
      try {
        await _method.invokeMethod<void>('stopStreaming');
      } catch (_) {
        /* best effort */
      }
    }
  }

  @override
  Future<String> transcribeFile(String wavPath, {String lang = 'en'}) async {
    if (!_supportedPlatform) {
      throw const AsrUnavailableException(
        AsrUnavailableReason.unsupportedPlatform,
      );
    }
    try {
      final res = await _method.invokeMethod<String>('transcribeFile', {
        'path': wavPath,
        'lang': lang,
      });
      return res ?? '';
    } on MissingPluginException {
      throw const AsrUnavailableException(
        AsrUnavailableReason.unsupportedPlatform,
        'Apple ASR native bridge not installed',
      );
    } on PlatformException catch (e) {
      throw StateError('Apple ASR transcribeFile failed: ${e.message}');
    }
  }
}
