import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ha.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_jv.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_or.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_sw.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tl.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('bn'),
    Locale('cs'),
    Locale('de'),
    Locale('es'),
    Locale('fi'),
    Locale('fr'),
    Locale('ha'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('jv'),
    Locale('kn'),
    Locale('ko'),
    Locale('ml'),
    Locale('mr'),
    Locale('ms'),
    Locale('ne'),
    Locale('nl'),
    Locale('or'),
    Locale('pa'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('sv'),
    Locale('sw'),
    Locale('ta'),
    Locale('te'),
    Locale('th'),
    Locale('tl'),
    Locale('tr'),
    Locale('ur'),
    Locale('vi'),
    Locale('zh')
  ];

  /// Product name (does not translate).
  ///
  /// In en, this message translates to:
  /// **'Recap'**
  String get appName;

  /// Primary CTA on home screen.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get homeRecord;

  /// Toolbar action to open the universal import screen.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get homeImport;

  /// No description provided for @homeSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get homeSearch;

  /// No description provided for @homeSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettings;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to record your first meeting. Audio stays on your device.'**
  String get homeEmptySubtitle;

  /// No description provided for @transcribing.
  ///
  /// In en, this message translates to:
  /// **'Transcribing on-device…'**
  String get transcribing;

  /// No description provided for @transcriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Transcription failed'**
  String get transcriptionFailed;

  /// No description provided for @tabTranscript.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get tabTranscript;

  /// No description provided for @tabSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get tabSummary;

  /// No description provided for @tabBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get tabBookmarks;

  /// No description provided for @summaryPickStyle.
  ///
  /// In en, this message translates to:
  /// **'Pick a style above and tap Generate.'**
  String get summaryPickStyle;

  /// No description provided for @summaryNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No summary yet'**
  String get summaryNoneYet;

  /// No description provided for @summaryGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get summaryGenerate;

  /// No description provided for @onDeviceAiNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'On-device AI not installed'**
  String get onDeviceAiNotInstalled;

  /// No description provided for @settingsTier.
  ///
  /// In en, this message translates to:
  /// **'Tier'**
  String get settingsTier;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsSummaries.
  ///
  /// In en, this message translates to:
  /// **'Summaries'**
  String get settingsSummaries;

  /// No description provided for @settingsTranscription.
  ///
  /// In en, this message translates to:
  /// **'Transcription'**
  String get settingsTranscription;

  /// No description provided for @settingsOrganization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get settingsOrganization;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & security'**
  String get settingsPrivacy;

  /// No description provided for @settingsBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get settingsBackup;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAppLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get settingsAppLock;

  /// No description provided for @settingsBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get settingsBackupTitle;

  /// No description provided for @settingsPrivacyDashboard.
  ///
  /// In en, this message translates to:
  /// **'Privacy dashboard'**
  String get settingsPrivacyDashboard;

  /// No description provided for @settingsInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get settingsInsights;

  /// No description provided for @settingsActionItems.
  ///
  /// In en, this message translates to:
  /// **'Action items'**
  String get settingsActionItems;

  /// No description provided for @settingsVoiceEnrollment.
  ///
  /// In en, this message translates to:
  /// **'Voice enrollment'**
  String get settingsVoiceEnrollment;

  /// No description provided for @actionItemsEmpty.
  ///
  /// In en, this message translates to:
  /// **'All clear — nothing pending'**
  String get actionItemsEmpty;

  /// No description provided for @importFile.
  ///
  /// In en, this message translates to:
  /// **'From file or gallery'**
  String get importFile;

  /// No description provided for @importUrl.
  ///
  /// In en, this message translates to:
  /// **'From URL'**
  String get importUrl;

  /// No description provided for @importYoutube.
  ///
  /// In en, this message translates to:
  /// **'From YouTube'**
  String get importYoutube;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Recap'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Memos, with on-device AI.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing leaves your phone'**
  String get onboardingPrivacyTitle;

  /// No description provided for @onboardingPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get onboardingPermissionsTitle;

  /// No description provided for @onboardingDownloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Better AI in the background'**
  String get onboardingDownloadsTitle;

  /// No description provided for @onboardingReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re set'**
  String get onboardingReadyTitle;

  /// No description provided for @onboardingReadyCta.
  ///
  /// In en, this message translates to:
  /// **'Start using Recap'**
  String get onboardingReadyCta;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @permMicLabel.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get permMicLabel;

  /// No description provided for @permMicDesc.
  ///
  /// In en, this message translates to:
  /// **'Required for recording. Recap never shares mic audio.'**
  String get permMicDesc;

  /// No description provided for @permCalLabel.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get permCalLabel;

  /// No description provided for @permCalDesc.
  ///
  /// In en, this message translates to:
  /// **'Optional. Auto-titles meetings from calendar events.'**
  String get permCalDesc;

  /// No description provided for @permNotifLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permNotifLabel;

  /// No description provided for @permNotifDesc.
  ///
  /// In en, this message translates to:
  /// **'Optional. Local-only — \"transcript ready\", \"action item due\".'**
  String get permNotifDesc;

  /// No description provided for @wifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi only'**
  String get wifiOnly;

  /// No description provided for @wifiOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended — large models stay off your cellular data plan.'**
  String get wifiOnlySubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'bn',
        'cs',
        'de',
        'en',
        'es',
        'fi',
        'fr',
        'ha',
        'hi',
        'id',
        'it',
        'ja',
        'jv',
        'kn',
        'ko',
        'ml',
        'mr',
        'ms',
        'ne',
        'nl',
        'or',
        'pa',
        'pl',
        'pt',
        'ru',
        'sv',
        'sw',
        'ta',
        'te',
        'th',
        'tl',
        'tr',
        'ur',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'cs':
      return AppLocalizationsCs();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'ha':
      return AppLocalizationsHa();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'jv':
      return AppLocalizationsJv();
    case 'kn':
      return AppLocalizationsKn();
    case 'ko':
      return AppLocalizationsKo();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'ms':
      return AppLocalizationsMs();
    case 'ne':
      return AppLocalizationsNe();
    case 'nl':
      return AppLocalizationsNl();
    case 'or':
      return AppLocalizationsOr();
    case 'pa':
      return AppLocalizationsPa();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
    case 'sw':
      return AppLocalizationsSw();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'th':
      return AppLocalizationsTh();
    case 'tl':
      return AppLocalizationsTl();
    case 'tr':
      return AppLocalizationsTr();
    case 'ur':
      return AppLocalizationsUr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
