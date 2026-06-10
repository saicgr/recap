# Build & Setup

The Dart-side implementation is in place. To make it actually run, you need to do the steps below in order.

## 1. Scaffold native iOS / Android

```bash
cd /Users/saichetangrandhe/recap
flutter create . --project-name recap --org com.recapfreenote --platforms=ios,android
flutter pub get
```

## 2. Generate Drift code

The Drift schema in `lib/data/database.dart` declares `part 'database.g.dart'`. Generate it once:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Commit the resulting `database.g.dart`. Re-run only when `database.dart` changes (per `CLAUDE.md` — don't run build_runner blindly).

## 3. iOS Info.plist additions

`ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Recap records meetings on this device. Your audio never leaves it.</string>
<key>NSCalendarsUsageDescription</key>
<string>Recap reads calendar events to auto-title meetings.</string>
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

For Apple Foundation Models you must target iOS 26+ and add the framework. In `ios/Runner.xcodeproj`:
- Set deployment target to iOS 26.
- Add `FoundationModels.framework` (weak link) to Runner target.
- Create `ios/Runner/FoundationModelsChannel.swift` implementing the method channel `com.recapfreenote.recap/apple_foundation_models`. Wire it from `AppDelegate.swift`. The expected interface is documented in `lib/services/summarizer/apple_foundation_models_backend.dart`.

## 4. Android setup

`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.INTERNET"/> <!-- cloud summaries only -->
<uses-permission android:name="android.permission.READ_CALENDAR"/>

<application ...>
  ...
  <service android:name=".RecordingService"
           android:foregroundServiceType="microphone"
           android:exported="false"/>
</application>
```

`android/app/build.gradle`: `minSdkVersion 24` (or higher — `whisper_ggml` and `flutter_gemma` both require it).

Create `android/app/src/main/kotlin/com/recapfreenote/recap/RecordingService.kt` per the TODO in `lib/services/background_recorder.dart`.

## 5. Deploy the Cloudflare Worker

```bash
cd cloudflare-worker
npm install
npx wrangler login
npx wrangler kv:namespace create recap-rate-limit
# paste returned id into wrangler.toml

npx wrangler secret put GEMINI_API_KEY        # your Google AI Studio key
npx wrangler secret put INSTALL_TOKEN_PEPPER  # any 32+ random hex string

npm run deploy
```

Put the deployed URL (`https://recap-worker.<account>.workers.dev`) into the app via Settings → Cloudflare Worker URL, **or** at build time:

```bash
flutter run --dart-define=RECAP_WORKER_URL=https://recap-worker.<account>.workers.dev
```

Without this, cloud summaries are disabled (`CloudBackend.isAvailable` returns false). On-device summaries still work.

## 6. Register IAP products

In App Store Connect (iOS) and Play Console (Android), register these product IDs as **non-consumable** (lifetime tiers) or **consumable** (top-ups):

| Product ID | Type | Price |
|---|---|---|
| `recap_privacy_lifetime` | non-consumable | $25 |
| `recap_starter_lifetime` | non-consumable | $29 |
| `recap_pro_lifetime` | non-consumable | $59 |
| `recap_power_lifetime` | non-consumable | $99 |
| `recap_topup_25` | consumable | $2.99 |
| `recap_topup_100` | consumable | $9.99 |
| `recap_topup_500` | consumable | $39.99 |

Without these registered + the app signed for distribution, IAP queries return empty and the paywall shows "no products."

## 7. (Optional) Bundle Gemma 4 manually

The `flutter_gemma` plugin's `downloadModelFromNetworkWithProgress` pulls Gemma 4 E2B (~2.4 GB LiteRT) on first summary request, or Gemma 4 E4B (~4.3 GB) on Pro+ tiers. If you'd rather host it yourself (CDN cost) or bundle a smaller model, see `lib/services/summarizer/gemma_backend.dart`.

## 8. Run

```bash
./scripts/run_ios_debug.sh         # iOS — host mic works for testing
./scripts/run_android_debug.sh     # Android — has -use-host-audio flag
```

## What works end-to-end without any of the above

| Feature | Without setup |
|---|---|
| Record + on-device Whisper transcription | ✅ once `flutter pub get` runs |
| Live captions during recording | ✅ |
| Tier model, paywall UI, IAP scaffolding | ✅ UI works; purchases fail until IAP products are registered |
| Cross-meeting FTS5 search | ✅ once Drift codegen runs |
| Persona templates + summary UI | ✅ but "New summary" needs an active backend (next row) |
| On-device summary (Apple FM) | ❌ until Swift method channel implemented |
| On-device summary (Gemma) | ✅ but downloads 1.4 GB on first use |
| Cloud summary | ❌ until Worker deployed + URL set in Settings |
| Background recording (Android) | ❌ until Kotlin foreground service implemented; foreground recording still works |
| Background recording (iOS) | ✅ once `UIBackgroundModes = [audio]` set |
| Workflow integrations (Notion / Slack / GDocs / Obsidian) | ❌ until each provider's OAuth client ID is registered + flutter_appauth flow filled in. Service classes + push() bodies are written; only the authorize() call throws UnimplementedError today. |

## Native-code stubs documented in source

- `lib/services/summarizer/apple_foundation_models_backend.dart` — Swift method channel `com.recapfreenote.recap/apple_foundation_models`
- `lib/services/background_recorder.dart` — Kotlin method channel `com.recapfreenote.recap/background_recorder`

Search for `NATIVE TODO` in source for full implementation contracts.
