import 'package:flutter_test/flutter_test.dart';
import 'package:recap/billing/tier.dart';
import 'package:recap/services/settings.dart';
import 'package:recap/services/summarizer/builtin_ai_backend.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('on-device model picker — settings logic', () {
    test('follows the tier default until the user explicitly picks', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SettingsService();
      await s.init();
      expect(s.effectiveGemmaVariant(GemmaVariant.e2b), GemmaVariant.e2b);
      expect(s.effectiveGemmaVariant(GemmaVariant.e4b), GemmaVariant.e4b);
    });

    test(
      'a user can opt UP to E4B even on a tier that defaults to E2B',
      () async {
        SharedPreferences.setMockInitialValues({});
        final s = SettingsService();
        await s.init();
        await s.setGemmaVariant(GemmaVariant.e4b);
        expect(s.effectiveGemmaVariant(GemmaVariant.e2b), GemmaVariant.e4b);
        // ...and the download URL now points at E4B.
        expect(
          s.gemmaModelUrlFor(GemmaVariant.e2b),
          GemmaVariant.e4b.defaultUrl,
        );
      },
    );

    test(
      'a manual custom URL override still wins over a variant pick',
      () async {
        SharedPreferences.setMockInitialValues({});
        final s = SettingsService();
        await s.init();
        await s.setGemmaModelUrl('https://my.cdn/custom.litertlm');
        await s.setGemmaVariant(
          GemmaVariant.e4b,
        ); // records choice, keeps override
        expect(
          s.gemmaModelUrlFor(GemmaVariant.e2b),
          'https://my.cdn/custom.litertlm',
        );
      },
    );
  });

  group('BuiltinAiBackend — Gemini Nano / Apple FM', () {
    test('advertises the E2B-class window so it takes the chunked path', () {
      final b = BuiltinAiBackend();
      expect(b.capabilities.contextTokens, 4096);
      expect(
        b.capabilities.supportsSystemPrompt,
        isFalse,
        reason: 'built-in session has no system role — preamble is prepended',
      );
    });

    test('reports a platform-appropriate model id', () {
      expect(
        BuiltinAiBackend().modelId,
        anyOf('gemini-nano', 'apple-foundation-models'),
      );
    });

    test('isAvailable is false (not a crash) with no native support', () async {
      // In the test VM there is no AICore / Apple Intelligence channel, so
      // availability() throws — the backend must swallow it and fall through.
      expect(await BuiltinAiBackend().isAvailable(), isFalse);
    });
  });
}
