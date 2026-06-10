import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../billing/entitlement_service.dart';
import '../billing/tier.dart';

class SettingsService extends ChangeNotifier {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---- Audio / transcription ----
  String get audioLanguage => _prefs.getString('audioLanguage') ?? 'auto';
  bool get showTimestamps => _prefs.getBool('showTimestamps') ?? false;
  bool get restoreLastTranscription =>
      _prefs.getBool('restoreLast') ?? true;
  bool get autoDeleteOldRecordings => _prefs.getBool('autoDelete') ?? false;
  int get autoDeleteDays => _prefs.getInt('autoDeleteDays') ?? 7;
  String get whisperModel => _prefs.getString('whisperModel') ?? 'small';

  // ---- Summaries ----
  SummaryMode get summaryMode {
    final raw = _prefs.getString('summaryMode') ?? 'auto';
    return switch (raw) {
      'cloud' => SummaryMode.cloud,
      'onDevice' => SummaryMode.onDevice,
      _ => SummaryMode.onDevice, // 'auto' resolves to onDevice by default
    };
  }

  String get summaryModeRaw => _prefs.getString('summaryMode') ?? 'auto';
  String get defaultPersonaKey =>
      _prefs.getString('defaultPersonaKey') ?? 'basic';

  // ---- ASR engine preference (D15.2) ----
  /// Stored as a string so we don't depend on the enum order. Values:
  /// 'auto' (default), 'native', 'whisper'.
  String get asrEnginePreferenceRaw =>
      _prefs.getString('asrEnginePreference') ?? 'auto';

  Future<void> setAsrEnginePreference(String v) async {
    await _prefs.setString('asrEnginePreference', v);
    notifyListeners();
  }

  // ---- On-device summary model (Gemma) ----
  /// Resolve the Gemma 4 model URL for the *current tier*. Caller should
  /// pass the user's entitled [GemmaVariant] (from `Tier.gemmaVariant`).
  /// Manual override via `setGemmaModelUrl` always wins — power users can
  /// point at a self-hosted CDN, a quantized variant, or a smaller LiteRT
  /// build if they prefer faster inference.
  String gemmaModelUrlFor(GemmaVariant variant) {
    final stored = _prefs.getString('gemmaModelUrl');
    if (stored != null && stored.isNotEmpty) return stored;
    const fromEnv = String.fromEnvironment('RECAP_GEMMA_MODEL_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return variant.defaultUrl;
  }

  Future<void> setGemmaModelUrl(String v) async {
    await _prefs.setString('gemmaModelUrl', v);
    notifyListeners();
  }

  // ---- Cloud worker config ----
  /// Default placeholder. Replace via build-time --dart-define=RECAP_WORKER_URL=...
  /// or via Settings once you deploy your Worker.
  String get workerUrl {
    final stored = _prefs.getString('workerUrl');
    if (stored != null && stored.isNotEmpty) return stored;
    const fromEnv = String.fromEnvironment('RECAP_WORKER_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return '';
  }

  // ---- Theme tweaks ----
  /// Defaults: dark + glass. New installs get the futuristic look; users who
  /// have toggled keep their saved preference.
  String get themeMode => _prefs.getString('themeMode') ?? 'dark';
  String get buttonStyleRaw => _prefs.getString('buttonStyle') ?? 'glass';
  int get accentIndex => _prefs.getInt('accentIndex') ?? 0;

  Future<void> setThemeMode(String v) async {
    await _prefs.setString('themeMode', v);
    notifyListeners();
  }

  Future<void> setButtonStyle(String v) async {
    await _prefs.setString('buttonStyle', v);
    notifyListeners();
  }

  Future<void> setAccentIndex(int i) async {
    await _prefs.setInt('accentIndex', i);
    notifyListeners();
  }

  // ---- Setters ----
  Future<void> setAudioLanguage(String v) async {
    await _prefs.setString('audioLanguage', v);
    notifyListeners();
  }

  Future<void> setShowTimestamps(bool v) async {
    await _prefs.setBool('showTimestamps', v);
    notifyListeners();
  }

  Future<void> setRestoreLast(bool v) async {
    await _prefs.setBool('restoreLast', v);
    notifyListeners();
  }

  Future<void> setAutoDelete(bool v) async {
    await _prefs.setBool('autoDelete', v);
    notifyListeners();
  }

  Future<void> setSummaryMode(String mode) async {
    await _prefs.setString('summaryMode', mode);
    notifyListeners();
  }

  Future<void> setDefaultPersona(String key) async {
    await _prefs.setString('defaultPersonaKey', key);
    notifyListeners();
  }

  Future<void> setWorkerUrl(String url) async {
    await _prefs.setString('workerUrl', url);
    notifyListeners();
  }

  Future<void> setWhisperModel(String m) async {
    await _prefs.setString('whisperModel', m);
    notifyListeners();
  }
}
