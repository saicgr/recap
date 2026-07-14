import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:recap/services/audio/mic_policy.dart';

/// The Bluetooth hijack: with AirPods connected, opening a record-capable audio
/// session flips the route to the Hands-Free Profile — 8-16 kHz narrowband —
/// and the transcript quality collapses while the user is told nothing.
///
/// It is the `record` package's DEFAULT behaviour (iOS categoryOptions include
/// allowBluetooth; Android manageBluetooth defaults true), so every recording
/// made with AirPods connected has been narrowband.
///
/// MicPolicy is the pure-Dart half of the defence and is fully testable here.
/// The other half — that the session config actually holds — needs a device.
void main() {
  const builtIn = InputDevice(id: 'builtin', label: 'iPhone Microphone');
  const airpods = InputDevice(id: 'bt-1', label: 'AirPods Pro');
  const btHeadset =
      InputDevice(id: 'bt-2', label: 'Jabra Evolve Bluetooth Headset');
  const usb = InputDevice(id: 'usb-1', label: 'USB Audio Device');
  const wired = InputDevice(id: 'w-1', label: 'Wired Headphones');

  group('classification', () {
    test('recognises Bluetooth inputs by label', () {
      expect(MicPolicy.isBluetooth(airpods), isTrue);
      expect(MicPolicy.isBluetooth(btHeadset), isTrue);
      expect(MicPolicy.isBluetooth(builtIn), isFalse);
      expect(MicPolicy.isBluetooth(usb), isFalse);
    });

    test('recognises built-in and wired inputs', () {
      expect(MicPolicy.isBuiltIn(builtIn), isTrue);
      expect(MicPolicy.isWired(usb), isTrue);
      expect(MicPolicy.isWired(wired), isTrue);
    });
  });

  group('choose', () {
    test('THE BUG: prefers the built-in mic over AirPods', () {
      // This single assertion is the entire feature. AirPods keep playing audio
      // over A2DP; we simply refuse to record through their narrowband mic.
      final c = MicPolicy.choose([airpods, builtIn]);
      expect(c.device, builtIn);
      expect(c.reason, MicChoiceReason.preferredBuiltIn);
      expect(MicPolicy.shouldWarn(c), isFalse);
    });

    test('prefers wired/USB over built-in — those are genuinely better', () {
      final c = MicPolicy.choose([builtIn, usb, airpods]);
      expect(c.device, usb);
      expect(c.reason, MicChoiceReason.wiredPreferred);
    });

    test('an explicit user pin wins, even a Bluetooth one — but warns', () {
      // We respect the choice; we do not override it. But the user is told what
      // it costs, rather than silently getting a worse transcript.
      final c = MicPolicy.choose([builtIn, airpods], pinnedId: 'bt-1');
      expect(c.device, airpods);
      expect(c.reason, MicChoiceReason.pinned);
      expect(MicPolicy.shouldWarn(c), isTrue);
    });

    test('a pin for a device that has been unplugged falls back safely', () {
      final c = MicPolicy.choose([builtIn, airpods], pinnedId: 'gone');
      expect(c.device, builtIn, reason: 'must not fail, must not pick the BT mic');
    });

    test('Bluetooth is used only when it is genuinely the ONLY input', () {
      // Recording through HFP is bad. Recording nothing is worse.
      final c = MicPolicy.choose([airpods]);
      expect(c.device, airpods);
      expect(c.reason, MicChoiceReason.onlyOption);
      expect(MicPolicy.shouldWarn(c), isTrue,
          reason: 'the user must still be told the quality is degraded');
    });

    test('no inputs enumerated -> defer to the platform, do not crash', () {
      final c = MicPolicy.choose([]);
      expect(c.device, isNull);
    });

    test('an unrecognised label is preferred over a Bluetooth one', () {
      // Labels vary by OS and locale. When in doubt, anything is better than a
      // known-narrowband route.
      const odd = InputDevice(id: 'x', label: 'Mikrofon');
      final c = MicPolicy.choose([airpods, odd]);
      expect(c.device, odd);
    });
  });
}
