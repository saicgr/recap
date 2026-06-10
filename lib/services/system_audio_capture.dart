import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Cross-platform interface for system-audio loopback capture on desktop.
/// Implementations:
///   - macOS: `macos/Runner/SystemAudioCapture.swift` using ScreenCaptureKit
///     (no virtual audio driver needed since macOS 13 Sonoma).
///   - Windows: `windows/runner/system_audio_capture.{h,cpp}` using WASAPI
///     loopback (IMMDevice.GetEndpoint(eRender) + loopback capture).
///
/// On mobile / web / Linux this returns the appropriate "unsupported" status
/// without crashing — UI surface guards via [isSupportedPlatform].
///
/// **Why this exists:** removes the "no meeting bot" weakness vs Otter/
/// Fathom. The user is already in the Zoom/Meet/Teams call; we capture the
/// audio their speakers are already playing. No bot in the participant list.
class SystemAudioCapture {
  static const _method = MethodChannel('recap.system_audio');
  static const _events = EventChannel('recap.system_audio.events');

  static bool get isSupportedPlatform =>
      Platform.isMacOS || Platform.isWindows;

  /// Are we allowed to capture system audio right now? macOS requires Screen
  /// Recording permission; first call prompts.
  Future<bool> isAvailable() async {
    if (!isSupportedPlatform) return false;
    try {
      final res = await _method.invokeMethod<bool>('isAvailable');
      return res ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Begin loopback capture, writing 16 kHz mono PCM to [wavPath]. The
  /// native side handles resampling. Optional [appBundleId] filters macOS
  /// ScreenCaptureKit to just one app (e.g. `us.zoom.xos`) — Windows ignores.
  Future<void> startCapture({
    required String wavPath,
    String? appBundleId,
  }) async {
    if (!isSupportedPlatform) {
      throw const SystemAudioCaptureUnsupportedException();
    }
    try {
      await _method.invokeMethod<void>('startCapture', {
        'wavPath': wavPath,
        'appBundleId': appBundleId,
      });
    } on MissingPluginException {
      throw const SystemAudioCaptureUnsupportedException(
          'Native system-audio bridge not installed in this build.');
    }
  }

  Future<void> stopCapture() async {
    if (!isSupportedPlatform) return;
    try {
      await _method.invokeMethod<void>('stopCapture');
    } catch (_) {/* best effort */}
  }

  /// Stream of RMS levels (0..1) emitted by the native side for the UI
  /// meter. Empty on unsupported platforms.
  Stream<double> levels() {
    if (!isSupportedPlatform) return const Stream.empty();
    return _events
        .receiveBroadcastStream()
        .where((e) => e is num)
        .map((e) => (e as num).toDouble().clamp(0.0, 1.0));
  }
}

class SystemAudioCaptureUnsupportedException implements Exception {
  final String message;
  const SystemAudioCaptureUnsupportedException(
      [this.message = 'System audio capture is desktop-only.']);
  @override
  String toString() => 'SystemAudioCaptureUnsupportedException: $message';
}
