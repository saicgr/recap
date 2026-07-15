import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../billing/entitlement_service.dart';
import '../billing/tier.dart';
import 'cloud/cloud_proxy.dart';

class SettingsService extends ChangeNotifier {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---- Audio / transcription ----
  String get audioLanguage => _prefs.getString('audioLanguage') ?? 'auto';
  bool get showTimestamps => _prefs.getBool('showTimestamps') ?? false;
  bool get restoreLastTranscription => _prefs.getBool('restoreLast') ?? true;
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
  /// Whether to route ASR through the platform-native engines (Apple / Android
  /// SpeechRecognizer). DEFAULT FALSE: those bridges have never been executed on
  /// a device, so until they are tested, every meeting transcribes through
  /// Whisper. Flipping this on is what lets the AsrRouter actually use native.
  bool get nativeAsrEnabled => _prefs.getBool('nativeAsrEnabled') ?? false;

  Future<void> setNativeAsrEnabled(bool v) async {
    await _prefs.setBool('nativeAsrEnabled', v);
    notifyListeners();
  }

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

  /// The Gemma variant the user explicitly picked in the model picker, or null
  /// to follow the tier default ([Tier.gemmaVariant]). Lets a user opt UP to E4B
  /// for sharper long-meeting summaries even on a tier that defaults to E2B, or
  /// stay on E2B to save space/RAM.
  String? get gemmaVariantChoice => _prefs.getString('gemmaVariantChoice');

  /// Persist a variant choice: records the id AND points the download URL at it
  /// (unless the user has a manual custom URL override, which still wins).
  Future<void> setGemmaVariant(GemmaVariant variant) async {
    await _prefs.setString('gemmaVariantChoice', variant.modelId);
    // Only set the URL when there is no manual override, so we don't clobber a
    // power user's self-hosted CDN.
    final manual = _prefs.getString('gemmaModelUrl');
    if (manual == null || manual.isEmpty) {
      await _prefs.setString('gemmaModelUrl', variant.defaultUrl);
    }
    notifyListeners();
  }

  /// Resolve the effective variant: explicit picker choice, else the tier
  /// default. Callers pass the tier default so this stays UI-agnostic.
  GemmaVariant effectiveGemmaVariant(GemmaVariant tierDefault) {
    final id = gemmaVariantChoice;
    if (id == null) return tierDefault;
    for (final v in GemmaVariant.values) {
      if (v.modelId == id) return v;
    }
    return tierDefault;
  }

  // ---- Microphone ----

  /// The input the user explicitly pinned, if any. null = let MicPolicy choose
  /// (which prefers the built-in mic over a Bluetooth headset).
  String? get pinnedMicId => _prefs.getString('pinnedMicId');

  Future<void> setPinnedMicId(String? id) async {
    if (id == null) {
      await _prefs.remove('pinnedMicId');
    } else {
      await _prefs.setString('pinnedMicId', id);
    }
    notifyListeners();
  }

  // ---- Home: upcoming events ----

  /// How far ahead the home-screen "coming up" strip looks. Granola's mobile
  /// list is short and fixed; ours is configurable.
  int get upcomingWindowHours => _prefs.getInt('upcomingWindowHours') ?? 24;

  Future<void> setUpcomingWindowHours(int hours) async {
    await _prefs.setInt('upcomingWindowHours', hours);
    notifyListeners();
  }

  // ---- Cloud proxy config ----

  /// URL of the Render proxy (the app's only backend; it holds the API keys).
  ///
  /// Precedence: user override -> --dart-define -> the shipped default.
  ///
  /// IMPORTANT: a stored URL pointing at the retired Cloudflare Worker is
  /// IGNORED. Early installs may have persisted a `*.workers.dev` URL, and that
  /// service is being un-deployed — honouring it would permanently pin those
  /// users to a dead host and silently break cloud summaries for exactly the
  /// people who used the feature first.
  String get proxyUrl {
    final stored =
        _prefs.getString('proxyUrl') ?? _prefs.getString('workerUrl');
    if (stored != null &&
        stored.isNotEmpty &&
        !stored.contains(kRetiredWorkerHostFragment)) {
      return stored;
    }
    const fromProxyEnv = String.fromEnvironment('RECAP_PROXY_URL');
    if (fromProxyEnv.isNotEmpty) return fromProxyEnv;
    const fromEnv = String.fromEnvironment('RECAP_WORKER_URL');
    if (fromEnv.isNotEmpty && !fromEnv.contains(kRetiredWorkerHostFragment)) {
      return fromEnv;
    }
    return kDefaultProxyUrl;
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

  Future<void> setProxyUrl(String url) async {
    await _prefs.setString('proxyUrl', url);
    // Drop the pre-Render key so it can never win the precedence check again.
    await _prefs.remove('workerUrl');
    notifyListeners();
  }

  Future<void> setWhisperModel(String m) async {
    await _prefs.setString('whisperModel', m);
    notifyListeners();
  }
}
