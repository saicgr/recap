# Audio capture — the Bluetooth hijack, and how we defeat it

## The bug

When AirPods (or any Bluetooth headset) are connected and an app opens a
record-capable audio session, the route flips to the **Hands-Free Profile (HFP)**:
8–16 kHz, narrowband, heavily compressed mono. The recording still "works" — it
is just quietly, dramatically worse, and Whisper's accuracy falls off a cliff.
The user is told nothing and has no way to find out.

**This is not hypothetical. It is the `record` package's default configuration**,
verified in `record_platform_interface/lib/src/types/`:

```dart
// iOS default
categoryOptions = [defaultToSpeaker, allowBluetooth, allowBluetoothA2DP]
//                                   ^^^^^^^^^^^^^^ the HFP switch

// Android default
manageBluetooth = true   // starts Bluetooth SCO
```

So **every Recap recording made with AirPods connected has been narrowband.**

## The fix

`lib/services/recorder.dart` — `_config()`:

| Platform | Setting | Why |
|---|---|---|
| iOS | drop `allowBluetooth`, **keep** `allowBluetoothA2DP` | A2DP is the *playback* profile. The user's AirPods keep playing audio in full quality; we simply refuse to capture through their microphone. |
| Android | `manageBluetooth: false` | Never start SCO. Pass the chosen `device` explicitly instead. |
| Android | `audioSource: voiceRecognition` | Tuned for ASR; skips the aggressive call-oriented processing `mic`/`voiceCommunication` apply. |
| both | `autoGain/echoCancel/noiseSuppress: false` | AGC/NS pump and gate quiet speakers — exactly the audio Whisper already struggles with. |

`lib/services/audio/mic_policy.dart` picks the input: **wired/USB > built-in >
anything > Bluetooth**. A user can still pin a Bluetooth mic explicitly — we
respect the choice and *warn*, rather than override it. The warning is shown on
the recording screen. A silent quality loss is the bug; telling the user is the
feature.

> **The two platforms need opposite-LOOKING settings for the same outcome.** This
> reads like an inconsistency and is not. Do **not** "tidy" it. Putting
> `allowBluetooth` back, or letting `manageBluetooth` default to `true`, silently
> reintroduces narrowband capture — with no error, and no failing test.

`record` is **pinned exactly** (`record: 6.1.1`, not `^6.1.1`) because a minor
bump could change these defaults back underneath us.

## ⚠️ Device verification — NOT YET DONE

`MicPolicy` is pure Dart and fully unit-tested (`test/audio/mic_policy_test.dart`).
**The half that matters — that the audio session config actually holds on a real
device — cannot be simulated and has not been verified.** A simulator does not
have Bluetooth audio routing.

Run this on a **physical iPhone with AirPods** before trusting the feature:

1. **Connect AirPods.** Play music to confirm A2DP is active.
2. **Start a recording in Recap.** Speak for ~20 seconds.
3. **Check the music kept playing in full quality.** If it dropped to tinny
   mono, the session still took HFP and the fix did not hold.
4. **Export the WAV and inspect its spectrogram** (Audacity, `sox -n spectrogram`).
   - ✅ **PASS:** energy present up to ~8 kHz (the ceiling of a 16 kHz capture from
     the built-in mic).
   - ❌ **FAIL:** a hard cliff at ~3.4–4 kHz → the route is still narrowband HFP.
5. **Confirm no warning banner appeared** — the built-in mic should have been
   chosen automatically, so `MicPolicy.shouldWarn` is false.
6. **Now pin the AirPods** in Settings and record again. The warning banner MUST
   appear, and the spectrogram SHOULD show the narrowband cliff. That proves the
   warning fires when it should.

Android equivalent: same steps with any BT headset; also confirm the notification
"ding" during recording does not stop capture.

Until step 4 passes on hardware, treat this feature as **implemented but
unverified**.

## What we deliberately do NOT build

**Capturing audio from another app (Zoom/Teams/WhatsApp) on the same device is
impossible on both platforms**, for everyone — not just us:

- **iOS:** CallKit claims the audio session. Winning it would mute the user's
  actual call.
- **Android:** `VOICE_COMMUNICATION` is `privacySensitive`, so every other
  capturer receives zeros. `AudioPlaybackCapture` cannot capture
  `USAGE_VOICE_COMMUNICATION`.

Granola concedes the same thing publicly ("phones don't let apps capture audio
from other apps"), so this is **not** a competitive gap and there is no roadmap
item that closes it. What works is **room audio**: an in-person meeting, or a call
on speakerphone from a *second* device. Ship that truth in the UI — a zero-input
watchdog with a visible banner — rather than a silent WAV of nothing.
