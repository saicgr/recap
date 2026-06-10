import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whisper_ggml/whisper_ggml.dart' show WhisperModel;

import 'billing/entitlement_service_impl.dart';
import 'data/database.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'billing/tier.dart';
import 'services/background_recorder.dart';
import 'services/custom_personas_service.dart';
import 'services/diarizer.dart';
import 'services/sherpa_diarizer.dart';
import 'services/exporter.dart';
import 'services/iap_service.dart';
import 'services/live_captions.dart';
import 'services/recorder.dart';
import 'services/settings.dart';
import 'services/summarizer/apple_foundation_models_backend.dart';
import 'services/summarizer/byok_backend.dart';
import 'services/summarizer/cloud_backend.dart';
import 'services/summarizer/gemma_backend.dart';
import 'services/summarizer/gemma_downloader.dart';
import 'services/summarizer/ollama_backend.dart';
import 'services/summarizer/summary_router.dart';
import 'services/asr/android_asr.dart';
import 'services/asr/apple_asr.dart';
import 'services/asr/asr_router.dart';
import 'services/asr/whisper_asr.dart';
import 'services/action_item_service.dart';
import 'services/app_lock_service.dart';
import 'services/backup_service.dart';
import 'services/bundled_models.dart';
import 'services/calendar_matcher.dart';
import 'services/clip_studio_service.dart';
import 'services/folder_service.dart';
import 'services/embedding_service.dart';
import 'services/insights_service.dart';
import 'services/mcp_export_service.dart';
import 'services/notification_service.dart';
import 'services/pdf_exporter.dart';
import 'services/recall_buffer.dart';
import 'services/system_audio_capture.dart';
import 'services/transcriber.dart';
import 'services/translator.dart';
import 'services/vad_service.dart';
import 'services/voiceprint_service.dart';
import 'services/wake_word_service.dart';
import 'ui/theme.dart';

// Global service singletons.
late final AppDb db;
late final SettingsService settings;
late final RecorderService recorder;
late final TranscriberService transcriber;
late final LiveCaptionsService liveCaptions;
late final BackgroundRecorder backgroundRecorder;
late final DriftEntitlementService entitlements;
late final IapService iap;
late final Exporter exporter;
late final SummaryRouter summaryRouter;
late final GemmaBackend gemmaBackend;
late final GemmaDownloader gemmaDownloader;
late final OllamaBackend ollamaBackend;
late final AsrRouter asrRouter;
late final SystemAudioCapture systemAudio;
late final VoiceprintService voiceprints;
late final ActionItemService actionItems;
late final AppLockService appLock;
late final BackupService backupService;
late final NotificationService notifications;
late final InsightsService insights;
late final PdfExporter pdfExporter;
late final RecallBuffer recallBuffer;
late final CalendarMatcher calendarMatcher;
late final EmbeddingService embeddings;
late final ClipStudioService clipStudio;
late final McpExportService mcpExport;
late final VadService vad;
late final WakeWordService wakeWord;
late final FolderService folderService;
late final List<Translator> translatorChain;
late final AppleFoundationModelsBackend appleFmBackend;
late final CloudBackend cloudBackend;
late final ByokBackend byokBackend;
late final ThemeController themeController;
late final CustomPersonasService customPersonas;
late final SherpaDiarizer diarizer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Critical path (blocks first frame) ──────────────────────────────────
  //
  // Only the settings load + theme reconstruction need to happen before
  // runApp. Everything else is deferred to a post-frame callback.

  db = AppDb();
  settings = SettingsService();
  await settings.init();

  themeController = ThemeController(
    mode: settings.themeMode == 'dark' ? RecapMode.dark : RecapMode.light,
    buttonStyle: settings.buttonStyleRaw == 'glass'
        ? RecapButtonStyle.glass
        : RecapButtonStyle.flat,
    accent: accentOptions[
        settings.accentIndex.clamp(0, accentOptions.length - 1)],
  );
  themeController.addListener(() async {
    await settings.setThemeMode(
        themeController.mode == RecapMode.dark ? 'dark' : 'light');
    await settings.setButtonStyle(
        themeController.buttonStyle == RecapButtonStyle.glass
            ? 'glass'
            : 'flat');
    await settings.setAccentIndex(accentOptions.indexOf(themeController.accent));
  });

  // ── Service objects (constructors only — no I/O yet) ─────────────────────

  entitlements = DriftEntitlementService(db: db);
  recorder = RecorderService();
  transcriber = TranscriberService();
  // Resolve the Whisper ceiling for the current tier — Free → base.en
  // (~140 MB, competitive with Voice Memos), Pro+ → small.en (~466 MB).
  // setModel is a no-op when the model matches the current default; on a
  // mismatch it queues the download.
  final ceilingModel = switch (entitlements.currentTier.whisperCeiling) {
    WhisperCeiling.tinyEn => WhisperModel.tinyEn,
    WhisperCeiling.baseEn => WhisperModel.baseEn,
    WhisperCeiling.smallEn => WhisperModel.smallEn,
  };
  unawaited(transcriber.setModel(ceilingModel));
  liveCaptions = LiveCaptionsService(transcriber: transcriber);
  backgroundRecorder = BackgroundRecorder();
  appleFmBackend = AppleFoundationModelsBackend();
  gemmaBackend = GemmaBackend();
  gemmaDownloader = GemmaDownloader(
    backend: gemmaBackend,
    modelUrl: settings.gemmaModelUrlFor(entitlements.currentTier.gemmaVariant),
  );
  unawaited(gemmaDownloader.refreshStatus());
  // Ollama lives on desktop; on mobile this is a cheap no-op (refreshStatus
  // short-circuits via OllamaBackend.isSupportedPlatform).
  ollamaBackend = OllamaBackend();
  unawaited(ollamaBackend.refreshStatus());
  byokBackend = ByokBackend();
  exporter = Exporter(entitlements: entitlements);
  diarizer = SherpaDiarizer(fallback: HeuristicDiarizer());
  customPersonas = CustomPersonasService();
  iap = IapService(entitlements: entitlements);

  // Install token — secure-storage RSA key gen runs in the background; the
  // CloudBackend awaits this future lazily on the first cloud-summary call,
  // so the ~130ms cost never lands on the main isolate during startup.
  final installTokenFuture = _ensureInstallToken();

  cloudBackend = CloudBackend(
    workerUrl: settings.workerUrl,
    installTokenFuture: installTokenFuture,
  );
  summaryRouter = SummaryRouter(
    entitlements: entitlements,
    appleFm: appleFmBackend,
    gemma: gemmaBackend,
    cloud: cloudBackend,
    byok: byokBackend,
    ollama: ollamaBackend,
  );
  // ASR engines + router (D15.2). Native engines no-op on unsupported
  // platforms; Whisper is the universal fallback. Router reads tier +
  // settings on every call so live tier changes are honored.
  final appleAsr = AppleAsrEngine();
  final androidAsr = AndroidAsrEngine();
  final whisperAsr = WhisperAsrEngine(transcriber: transcriber);
  systemAudio = SystemAudioCapture();
  voiceprints = VoiceprintService();
  actionItems = ActionItemService();
  appLock = AppLockService();
  backupService = BackupService();
  notifications = NotificationService();
  insights = InsightsService();
  pdfExporter = PdfExporter();
  recallBuffer = RecallBuffer();
  calendarMatcher = CalendarMatcher();
  embeddings = EmbeddingService();
  clipStudio = ClipStudioService();
  mcpExport = McpExportService();
  vad = VadService();
  wakeWord = NullWakeWordService();
  folderService = FolderService();
  translatorChain = buildTranslatorChain(entitlements.currentTier);
  unawaited(appLock.init());
  unawaited(notifications.init());
  asrRouter = AsrRouter(
    appleAsr: appleAsr,
    androidAsr: androidAsr,
    whisperAsr: whisperAsr,
    tierProvider: () => entitlements.currentTier,
    preferenceProvider: () => switch (settings.asrEnginePreferenceRaw) {
      'native' => AsrEnginePreference.nativeOnly,
      'whisper' => AsrEnginePreference.whisperOnly,
      _ => AsrEnginePreference.auto,
    },
  );

  runApp(const RecapApp());

  // ── Deferred work (runs after first frame is painted) ────────────────────
  //
  // None of these block any user-visible action. IAP product lookups, custom
  // persona load, and the Whisper model warmup all happen while the home
  // screen is already on screen.

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initDeferredServices());
  });
}

Future<void> _initDeferredServices() async {
  // Force the install-token Future to start resolving (we don't await its
  // result here — CloudBackend has it).
  try {
    await iap.init();
  } catch (e) {
    // No analytics SDK — log to console only.
    // ignore: avoid_print
    print('iap.init() failed: $e');
  }
  try {
    await customPersonas.init();
  } catch (e) {
    // ignore: avoid_print
    print('customPersonas.init() failed: $e');
  }
  // Extract any bundled models from the IPA/APK to app-private storage so
  // whisper.cpp can mmap them by path. Idempotent across launches. Logs
  // softly if the binary isn't present (dev builds without the CI fetch).
  try {
    await BundledModels.ensureAll();
  } catch (e) {
    // ignore: avoid_print
    print('BundledModels.ensureAll() failed: $e');
  }
  transcriber.warmUp();
}

Future<String> _ensureInstallToken() async {
  const storage = FlutterSecureStorage();
  const key = 'install_token';
  var token = await storage.read(key: key);
  if (token == null) {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    token = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await storage.write(key: key, value: token);
  }
  return token;
}

/// First-launch gate: shows onboarding once, then HomeScreen forever.
/// Bridges the persisted `onboarding_completed_v1` flag the onboarding screen
/// writes via [SharedPreferences].
class _LaunchGate extends StatefulWidget {
  const _LaunchGate();

  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_completed_v1') ?? false;
    if (!mounted) return;
    setState(() => _onboardingDone = done);
  }

  @override
  Widget build(BuildContext context) {
    final done = _onboardingDone;
    if (done == null) {
      // Loading. Render a thin splash; SharedPreferences.getInstance() is
      // <50ms in practice so this is invisible most of the time.
      return const ColoredBox(color: Color(0xFF0F0F12));
    }
    if (!done) {
      return OnboardingScreen(
        onComplete: () => setState(() => _onboardingDone = true),
      );
    }
    return const HomeScreen();
  }
}

class RecapApp extends StatelessWidget {
  const RecapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RecapThemeScope(
      controller: themeController,
      child: AnimatedBuilder(
        animation: themeController,
        builder: (ctx, _) {
          final t = themeController.theme;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: t.mode == RecapMode.dark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarColor: t.bg,
            systemNavigationBarIconBrightness: t.mode == RecapMode.dark
                ? Brightness.light
                : Brightness.dark,
          ));
          return MaterialApp(
            title: 'Recap',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: t.mode == RecapMode.dark
                  ? Brightness.dark
                  : Brightness.light,
              scaffoldBackgroundColor: t.bg,
              canvasColor: t.bg,
              colorScheme: t.mode == RecapMode.dark
                  ? ColorScheme.dark(
                      primary: t.accent,
                      surface: t.surface,
                      onSurface: t.textPrimary,
                    )
                  : ColorScheme.light(
                      primary: t.accent,
                      surface: t.surface,
                      onSurface: t.textPrimary,
                    ),
              splashFactory: InkSparkle.splashFactory,
              snackBarTheme: SnackBarThemeData(
                backgroundColor: t.surface,
                contentTextStyle: TextStyle(color: t.textPrimary),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: t.border),
                ),
              ),
            ),
            home: const _LaunchGate(),
          );
        },
      ),
    );
  }
}
