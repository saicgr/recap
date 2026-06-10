import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-level biometric lock (D14.12). Face ID / Touch ID / device passcode
/// gate before opening the app. Per-launch or after N minutes of inactivity.
///
/// **Privacy invariant:** biometric authentication uses the platform
/// keystore (iOS Keychain, Android Keystore) — same surface used by
/// `flutter_secure_storage` for BYOK keys. No network involvement.
///
/// Wraps `local_auth` package (TODO add to pubspec). For now this file is
/// the state-management layer; the actual biometric prompt is invoked via
/// the platform channels at the screen guard layer.
class AppLockService extends ChangeNotifier {
  static const _enabledKey = 'app_lock_enabled';
  static const _timeoutKey = 'app_lock_timeout_minutes';

  bool _enabled = false;
  int _timeoutMinutes = 5;
  DateTime? _lastUnlockAt;
  bool _isUnlocked = false;

  bool get enabled => _enabled;
  int get timeoutMinutes => _timeoutMinutes;
  bool get isUnlocked => _isUnlocked;

  /// Whether the app should currently be locked (= biometric prompt due).
  bool get shouldLock {
    if (!_enabled) return false;
    if (!_isUnlocked) return true;
    final last = _lastUnlockAt;
    if (last == null) return true;
    final elapsed = DateTime.now().difference(last);
    return elapsed > Duration(minutes: _timeoutMinutes);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    _timeoutMinutes = prefs.getInt(_timeoutKey) ?? 5;
    notifyListeners();
  }

  Future<void> setEnabled(bool v) async {
    _enabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, v);
    notifyListeners();
  }

  Future<void> setTimeoutMinutes(int m) async {
    _timeoutMinutes = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timeoutKey, m);
    notifyListeners();
  }

  /// Called by the screen guard after a successful biometric prompt.
  void markUnlocked() {
    _isUnlocked = true;
    _lastUnlockAt = DateTime.now();
    notifyListeners();
  }

  void markLocked() {
    _isUnlocked = false;
    notifyListeners();
  }

  // Confidential meetings (D14.12) — meetings tagged confidential are
  // hidden from list previews + excluded from cross-meeting search results
  // unless the user explicitly searches confidentials after a biometric
  // prompt.
  Set<String> _confidentialMeetingIds = {};

  Set<String> get confidentialMeetingIds => Set.unmodifiable(_confidentialMeetingIds);

  Future<void> loadConfidentials() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('confidential_meetings') ?? const [];
    _confidentialMeetingIds = list.toSet();
    notifyListeners();
  }

  Future<void> markConfidential(String meetingId, bool confidential) async {
    if (confidential) {
      _confidentialMeetingIds.add(meetingId);
    } else {
      _confidentialMeetingIds.remove(meetingId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'confidential_meetings', _confidentialMeetingIds.toList());
    notifyListeners();
  }
}
