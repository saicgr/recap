import 'dart:io';

import 'package:flutter/services.dart';

/// Keeps recording alive when the app is backgrounded or screen-locked.
///
/// NATIVE TODO — Android:
///   Create `android/app/src/main/kotlin/com/recapfreenote/recap/RecordingService.kt`
///   extending `Service` with `FOREGROUND_SERVICE_TYPE_MICROPHONE`. Post a
///   persistent notification ("Recap is recording"). MethodChannel handler:
///     - `startForeground` → starts the service + notification
///     - `stopForeground` → stops the service
///   AndroidManifest.xml needs:
///     <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
///     <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE"/>
///     <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
///     <service android:name=".RecordingService"
///              android:foregroundServiceType="microphone"
///              android:exported="false"/>
///
/// NATIVE TODO — iOS:
///   Info.plist already needs UIBackgroundModes = [audio]. That alone keeps
///   AVAudioRecorder running in the background. No method-channel work
///   strictly required on iOS — this class is a no-op there.
class BackgroundRecorder {
  static const _channel =
      MethodChannel('com.recapfreenote.recap/background_recorder');

  Future<void> startForeground({required String meetingTitle}) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('startForeground', {
        'title': meetingTitle,
        'notificationText': 'Recording in progress',
      });
    } on MissingPluginException {
      // Native handler not wired yet — recording will still work foreground.
      // Background-kill behavior will not be correct until the service is wired.
    }
  }

  Future<void> stopForeground() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopForeground');
    } on MissingPluginException {
      // No-op.
    }
  }
}
