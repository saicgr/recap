import '../billing/tier.dart';

/// Abstract language detector — input audio path (or text), output ISO-639-1
/// code. Per the v1 plan (D11.6 + Tier A2), the routing splits:
///
///   - Non-Privacy tiers: `google_mlkit_language_id` (ML Kit, native bundled,
///     58 languages). TODO once we add the package.
///   - Privacy tier iOS: Apple `NaturalLanguage.NLLanguageRecognizer` via
///     platform channel.
///   - Privacy tier Android: tiny fastText ONNX (`lid.176.ftz` converted).
///
/// For v1, the stub returns the user's UI locale on every call. Wire the
/// real detector when the platform channels land (TODO note in plan).
abstract class LanguageDetector {
  Future<String> detectFromText(String sample);
  Future<String> detectFromAudioFile(String wavPath);
}

class StubLanguageDetector implements LanguageDetector {
  final String defaultLocale;
  StubLanguageDetector({this.defaultLocale = 'en'});

  @override
  Future<String> detectFromText(String sample) async => defaultLocale;

  @override
  Future<String> detectFromAudioFile(String wavPath) async => defaultLocale;
}

/// Factory — picks the right detector based on tier + platform. Defaults to
/// the stub on every platform until the real bindings land.
LanguageDetector buildLanguageDetector(Tier tier) {
  // TODO: tier == Tier.privacy → Apple NLLanguageRecognizer / fastText ONNX.
  // TODO: else → MlKitLanguageDetector via google_mlkit_language_id.
  return StubLanguageDetector();
}
