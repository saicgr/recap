import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'asr_engine.dart';

/// Android on-device SpeechRecognizer (API 33+ for guaranteed on-device with
/// `RECOGNIZER_EXTRA_LANGUAGE_PREFERENCE_LOCAL`). Native bridge in
/// `android/app/src/main/kotlin/.../AndroidAsrBridge.kt` (D15.2).
///
/// On older Android versions or where on-device support isn't bundled with
/// Play Services, `isAvailable()` returns false and the AsrRouter falls back
/// to Whisper tiny.en.
class AndroidAsrEngine implements AsrEngine {
  static const _method = MethodChannel('recap.asr.android');
  static const _events = EventChannel('recap.asr.android.events');

  @override
  String get id => 'android';

  @override
  String get displayName => 'Google Speech (on-device)';

  @override
  Future<bool> isAvailable({String lang = 'en'}) async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _method.invokeMethod<bool>('isAvailable', {
        'lang': lang,
      });
      return res ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Stream<AsrPartial> transcribeStreaming({String lang = 'en'}) async* {
    if (!Platform.isAndroid) {
      throw const AsrUnavailableException(
          AsrUnavailableReason.unsupportedPlatform);
    }
    try {
      await _method.invokeMethod<void>('startStreaming', {'lang': lang});
    } on MissingPluginException {
      throw const AsrUnavailableException(
          AsrUnavailableReason.unsupportedPlatform,
          'Android ASR native bridge not installed');
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
      } catch (_) {/* best effort */}
    }
  }

  @override
  Future<String> transcribeFile(String wavPath, {String lang = 'en'}) async {
    // Android's SpeechRecognizer is mic-only — there's no file-input API.
    // For the final-quality file pass we always route to Whisper on Android.
    throw const AsrUnavailableException(
        AsrUnavailableReason.unsupportedPlatform,
        'Android on-device SpeechRecognizer does not support file input — '
        'use WhisperAsrEngine for transcribeFile on Android.');
  }
}
