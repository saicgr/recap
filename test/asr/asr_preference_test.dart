import 'package:flutter_test/flutter_test.dart';
import 'package:recap/services/asr/asr_router.dart';

/// The AsrRouter is now wired into the recording flow. The one thing that must
/// NOT happen as a side effect: real meetings silently switching from Whisper to
/// the Apple/Android native bridges, which have never been executed on a device.
///
/// resolveAsrPreference is the guard. These tests pin it.
void main() {
  group('native ASR is off by default -> Whisper for capture', () {
    test('with native disabled, EVERY raw preference resolves to Whisper', () {
      // This is the safety property. Wiring the router in must be a pure
      // refactor: no meeting changes which engine transcribes it.
      for (final raw in ['auto', 'native', 'whisper', 'garbage', '']) {
        expect(
          resolveAsrPreference(raw, nativeEnabled: false),
          AsrEnginePreference.whisperOnly,
          reason: 'raw="$raw" must still be Whisper while native is off',
        );
      }
    });
  });

  group('once native is enabled, the raw preference takes effect', () {
    // Positive control: if resolve() returned whisperOnly for everyone always,
    // the test above would pass vacuously. It must actually honour the setting
    // once native is switched on.
    test('auto -> auto', () {
      expect(
        resolveAsrPreference('auto', nativeEnabled: true),
        AsrEnginePreference.auto,
      );
    });
    test('native -> nativeOnly', () {
      expect(
        resolveAsrPreference('native', nativeEnabled: true),
        AsrEnginePreference.nativeOnly,
      );
    });
    test('whisper -> whisperOnly (user can still force Whisper)', () {
      expect(
        resolveAsrPreference('whisper', nativeEnabled: true),
        AsrEnginePreference.whisperOnly,
      );
    });
    test('an unknown value falls back to auto', () {
      expect(
        resolveAsrPreference('???', nativeEnabled: true),
        AsrEnginePreference.auto,
      );
    });
  });
}
