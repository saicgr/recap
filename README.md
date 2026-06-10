# Recap

Flutter meeting recorder with **on-device** transcription. Lifetime pricing, no subscriptions. Your audio never leaves the device.

## v1 flow

Tap Record → live timer → Stop → on-device Whisper transcribes → transcript saved locally → opens in viewer. That's it. No accounts, no IAP, no cloud — yet.

## First-time setup

The repo currently contains only the Dart sources and run scripts. Before the first build you need to scaffold the native iOS/Android folders:

```bash
cd /Users/saichetangrandhe/recap
flutter create . --project-name recap --org com.recapfreenote --platforms=ios,android
flutter pub get
```

`flutter create` preserves the existing `pubspec.yaml`, `lib/`, and `scripts/` — it only adds `ios/`, `android/`, and a couple of Flutter glue files.

### iOS — `ios/Runner/Info.plist`

Add these keys:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Recap records meetings on this device. Your audio stays here.</string>
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

### Android — `android/app/src/main/AndroidManifest.xml`

Add permissions inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

Set `minSdkVersion 24` (or higher) in `android/app/build.gradle` — `whisper_ggml` and `record` both require it.

## Running

All run scripts live in `scripts/`. Bundle ID is `com.recapfreenote.recap`.

```bash
./scripts/run_ios.sh              # iOS release on best available simulator
./scripts/run_ios_debug.sh        # iOS debug (hot reload), defaults to iPhone 17 Pro
./scripts/run_android.sh          # Android release on Medium_Phone_API_36.1
./scripts/run_android_debug.sh    # Android debug (hot reload)
./scripts/run_foldable.sh         # Android foldable AVD (Pixel_Fold_API_36)
```

Each script: boots the right sim/emulator, uninstalls the old build, runs `flutter pub get`, then `flutter run`.

## Directory layout

```
lib/
  main.dart                     # entry + global service singletons
  models/meeting.dart           # plain-Dart Meeting model + JSON serialization
  services/
    storage.dart                # JSON-file-backed meeting store (no Drift)
    recorder.dart               # wrapper around `record`
    transcriber.dart            # wrapper around `whisper_ggml`
    settings.dart               # SharedPreferences-backed settings
  billing/
    tier.dart                   # Tier enum (matches docs/TIERS.md)
    entitlement_service.dart    # interface + StubEntitlementService for v1
  screens/
    home_screen.dart            # shows latest transcript, + menu, bottom toolbar
    recording_screen.dart       # timer + Discard / Transcribe / Pause
    transcript_screen.dart      # read a specific meeting from the list
    meetings_list_screen.dart   # picker
    settings_screen.dart        # language, timestamps, restore last, auto-delete

scripts/                        # run_ios.sh, run_ios_debug.sh, run_android.sh,
                                # run_android_debug.sh, run_foldable.sh
docs/TIERS.md                   # tier spec — see this for pricing decisions
CLAUDE.md                       # process rules for Claude Code
.claude/                        # agents, skills, commands
```

## Storage model

We are deliberately *not* using Drift in v1. Storage is:

- `meetings.json` — list of `Meeting` records (id, title, createdAt, duration, paths, status)
- `recordings/<id>.wav` — 16 kHz mono PCM WAV (whisper-native, no resampling)
- `transcripts/<id>.txt` — plain text transcript

All under `getApplicationDocumentsDirectory()`. Uninstall the app and it's all gone. If/when we need queries beyond "list newest first," swap in Drift.

## Testing on a simulator/emulator

Recording apps are awkward to test on emulators since they don't have a real mic. The flow:

1. **Live recording test** — the iOS Simulator pipes your Mac's mic input straight through (Simulator menu → I/O → Audio Input). Android Emulator needs `-use-host-audio` or the AVD's mic setting enabled. Talk into your laptop, hit Record, verify the round-trip.
2. **Deterministic dev loop** — drop a 16 kHz mono WAV at `assets/sample_meeting.wav`, then in debug builds the `+` menu shows **Load sample meeting**, which copies the bundled file in and runs the same transcription path. Lets you iterate on UI/transcription without re-recording. `assets/README.md` has the ffmpeg one-liner.
3. **Real device for real signal** — emulators don't reproduce battery, thermal throttling, background-kill, or call-interruption behavior. Test on a phone before shipping anything.

## Known limitations

- **No live captions yet.** Whisper runs once after Stop. Streaming partial transcription is real work — we'll add it after the core loop is solid.
- **No real background recording.** Foreground-only for now. The Info.plist / AndroidManifest entries above lay the groundwork; the `record` package's foreground service still needs to be wired.
- **No import / paste.** The `+` menu shows them as "coming soon."
- **Settings toggles are persisted but not all are enforced yet** (Show timestamps, Auto-delete are wired to prefs but not consumed).
- **`whisper_ggml` API drift.** If the installed version of the package exposes different names, edit only `lib/services/transcriber.dart` — the rest of the app calls `transcribe(path)` and doesn't care.
