import 'package:record/record.dart';

/// How a microphone got chosen, so the UI can explain itself.
enum MicChoiceReason {
  /// The user pinned this input in Settings.
  pinned,

  /// We deliberately preferred the device's own mic over a Bluetooth headset.
  preferredBuiltIn,

  /// A wired headset / USB mic — better than built-in and not lossy.
  wiredPreferred,

  /// Nothing better was available.
  onlyOption,
}

class MicChoice {
  const MicChoice({required this.device, required this.reason});

  /// null == let the platform decide (no inputs enumerated).
  final InputDevice? device;
  final MicChoiceReason reason;
}

/// Which microphone Recap records from — and, more importantly, which one it
/// refuses to record from.
///
/// **The Bluetooth hijack.** When AirPods (or any BT headset) are connected and
/// an app opens a record-capable audio session, the route flips to the Hands-Free
/// Profile: 8–16 kHz, narrowband, heavily compressed mono. The transcript quality
/// collapses and the user never learns why — the audio still "works", it is just
/// quietly much worse, and Whisper's accuracy falls off a cliff.
///
/// This is not hypothetical: it is the `record` package's default configuration.
/// On iOS its default `categoryOptions` include `allowBluetooth` (the HFP
/// switch), and on Android `manageBluetooth` defaults to `true` (starts SCO). So
/// every Recap recording made with AirPods connected has been narrowband.
///
/// Policy: **record from the built-in mic even when AirPods are connected.** They
/// keep playing audio over A2DP — playback is untouched — we simply do not
/// capture through their microphone. This is what users actually want and never
/// get. A wired or USB mic IS preferred, because those are genuinely better and
/// carry no lossy-profile penalty.
class MicPolicy {
  /// Substrings that identify a Bluetooth input across both platforms' labels.
  /// Matching on the label is crude, but `InputDevice` exposes only `id` and
  /// `label`, and the id is an opaque platform handle.
  static const _bluetoothHints = [
    'bluetooth',
    'airpod',
    'headset', // Android reports BT SCO as "... Headset"
    'sco',
    'hands-free',
    'handsfree',
    'beats',
    'buds',
  ];

  static const _wiredHints = [
    'usb',
    'wired',
    'headphone', // wired headphones with an inline mic
    'external',
    'lightning',
  ];

  static const _builtInHints = [
    'built-in',
    'builtin',
    'internal',
    'iphone',
    'ipad',
    'macbook',
    'phone microphone',
    'default',
  ];

  static bool isBluetooth(InputDevice d) => _matches(d, _bluetoothHints);
  static bool isWired(InputDevice d) => _matches(d, _wiredHints);
  static bool isBuiltIn(InputDevice d) => _matches(d, _builtInHints);

  static bool _matches(InputDevice d, List<String> hints) {
    final label = d.label.toLowerCase();
    return hints.any(label.contains);
  }

  /// Choose the input to record from.
  ///
  /// Order: an explicit user pin > wired/USB > built-in > anything left. A
  /// Bluetooth input is chosen ONLY if it is genuinely the only thing available,
  /// and never silently.
  static MicChoice choose(
    List<InputDevice> devices, {
    String? pinnedId,
  }) {
    if (devices.isEmpty) {
      return const MicChoice(device: null, reason: MicChoiceReason.onlyOption);
    }

    if (pinnedId != null) {
      for (final d in devices) {
        if (d.id == pinnedId) {
          // The user's explicit choice wins, even a Bluetooth one. We warn; we
          // do not override.
          return MicChoice(device: d, reason: MicChoiceReason.pinned);
        }
      }
      // Pinned device is gone (unplugged). Fall through rather than fail.
    }

    for (final d in devices) {
      if (isWired(d) && !isBluetooth(d)) {
        return MicChoice(device: d, reason: MicChoiceReason.wiredPreferred);
      }
    }

    for (final d in devices) {
      if (isBuiltIn(d) && !isBluetooth(d)) {
        return MicChoice(
            device: d, reason: MicChoiceReason.preferredBuiltIn);
      }
    }

    // Nothing recognised as built-in. Prefer anything that is not Bluetooth.
    for (final d in devices) {
      if (!isBluetooth(d)) {
        return MicChoice(
            device: d, reason: MicChoiceReason.preferredBuiltIn);
      }
    }

    // Only Bluetooth inputs exist. Recording through HFP is bad; recording
    // nothing is worse.
    return MicChoice(device: devices.first, reason: MicChoiceReason.onlyOption);
  }

  /// True when the chosen input will drag the session into narrowband HFP, and
  /// the user should be told.
  static bool shouldWarn(MicChoice choice) =>
      choice.device != null && isBluetooth(choice.device!);

  static const warning =
      'Recording through Bluetooth uses call-quality audio (16 kHz), which '
      'noticeably hurts transcription. Switch to the device microphone for a '
      'much better transcript — your headphones will keep playing audio.';
}
