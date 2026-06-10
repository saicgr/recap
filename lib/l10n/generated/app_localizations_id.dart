// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'Recap';

  @override
  String get homeRecord => 'Record';

  @override
  String get homeImport => 'Import';

  @override
  String get homeSearch => 'Search';

  @override
  String get homeSettings => 'Settings';

  @override
  String get homeEmptyTitle => 'No recordings yet';

  @override
  String get homeEmptySubtitle =>
      'Tap the button below to record your first meeting. Audio stays on your device.';

  @override
  String get transcribing => 'Transcribing on-device…';

  @override
  String get transcriptionFailed => 'Transcription failed';

  @override
  String get tabTranscript => 'Transcript';

  @override
  String get tabSummary => 'Summary';

  @override
  String get tabBookmarks => 'Bookmarks';

  @override
  String get summaryPickStyle => 'Pick a style above and tap Generate.';

  @override
  String get summaryNoneYet => 'No summary yet';

  @override
  String get summaryGenerate => 'Generate';

  @override
  String get onDeviceAiNotInstalled => 'On-device AI not installed';

  @override
  String get settingsTier => 'Tier';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsSummaries => 'Summaries';

  @override
  String get settingsTranscription => 'Transcription';

  @override
  String get settingsOrganization => 'Organization';

  @override
  String get settingsPrivacy => 'Privacy & security';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAppLock => 'App Lock';

  @override
  String get settingsBackupTitle => 'Backup & restore';

  @override
  String get settingsPrivacyDashboard => 'Privacy dashboard';

  @override
  String get settingsInsights => 'Insights';

  @override
  String get settingsActionItems => 'Action items';

  @override
  String get settingsVoiceEnrollment => 'Voice enrollment';

  @override
  String get actionItemsEmpty => 'All clear — nothing pending';

  @override
  String get importFile => 'From file or gallery';

  @override
  String get importUrl => 'From URL';

  @override
  String get importYoutube => 'From YouTube';

  @override
  String get onboardingWelcomeTitle => 'Recap';

  @override
  String get onboardingWelcomeSubtitle => 'Voice Memos, with on-device AI.';

  @override
  String get onboardingPrivacyTitle => 'Nothing leaves your phone';

  @override
  String get onboardingPermissionsTitle => 'Permissions';

  @override
  String get onboardingDownloadsTitle => 'Better AI in the background';

  @override
  String get onboardingReadyTitle => 'You\'re set';

  @override
  String get onboardingReadyCta => 'Start using Recap';

  @override
  String get onboardingNext => 'Next';

  @override
  String get permMicLabel => 'Microphone';

  @override
  String get permMicDesc =>
      'Required for recording. Recap never shares mic audio.';

  @override
  String get permCalLabel => 'Calendar';

  @override
  String get permCalDesc =>
      'Optional. Auto-titles meetings from calendar events.';

  @override
  String get permNotifLabel => 'Notifications';

  @override
  String get permNotifDesc =>
      'Optional. Local-only — \"transcript ready\", \"action item due\".';

  @override
  String get wifiOnly => 'Wi-Fi only';

  @override
  String get wifiOnlySubtitle =>
      'Recommended — large models stay off your cellular data plan.';
}
