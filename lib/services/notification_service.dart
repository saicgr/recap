import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notifications (D14.17). **Local only** — per Karpathy invariants,
/// no push servers. The categories we surface:
///   - Meeting starting soon (calendar-driven)
///   - Transcription complete (long Whisper run finished while user was elsewhere)
///   - Summary ready
///   - Action item due
///   - Backup reminder
///
/// All notifications fire from the device, not a server. The
/// `flutter_local_notifications` package handles scheduling against the OS
/// notification system; we never call out.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const init = InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(init);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showTranscriptionReady({
    required String meetingId,
    required String title,
  }) async {
    await init();
    await _plugin.show(
      _hash(meetingId),
      'Transcript ready',
      title,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'transcription_ready',
          'Transcription complete',
          channelDescription: 'Fires when Whisper finishes a long recording.',
          importance: Importance.defaultImportance,
        ),
      ),
      payload: 'meeting:$meetingId',
    );
  }

  Future<void> scheduleMeetingReminder({
    required String eventId,
    required String eventTitle,
    required DateTime fireAt,
  }) async {
    // TODO: implement with timezone-aware zonedSchedule. flutter_local_
    // notifications requires `tz` package import. Skeleton committed for the
    // call site to land cleanly.
  }

  int _hash(String s) =>
      s.codeUnits.fold(0, (h, c) => (h * 31 + c) & 0x7fffffff);
}
