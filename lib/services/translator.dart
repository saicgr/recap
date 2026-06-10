import '../billing/tier.dart';

/// One translated chunk. For segmented transcripts we translate per-segment
/// and preserve timing.
class TranslationResult {
  final String translated;
  final String sourceLang;
  final String targetLang;
  final String engineId;
  const TranslationResult({
    required this.translated,
    required this.sourceLang,
    required this.targetLang,
    required this.engineId,
  });
}

/// Per the v1 plan (Decision 13), translation has five backends with tiered
/// availability:
///   1. Apple Translation framework (iOS 18+ / macOS 15+) — fully offline,
///      ~20 languages
///   2. ML Kit Translation — 58 languages, on-device after per-pair download
///   3. ONNX MarianMT / NLLB — Privacy Android fallback
///   4. Gemma 4 on-device — uses existing model with translate prompt
///   5. Gemini 3.1 Flash Lite via Render proxy — opt-in cloud upgrade
///
/// AbstractTranslator + factory pattern matches the LanguageDetector layout.
abstract class Translator {
  String get engineId;
  bool get isOnlineRequired;
  Future<bool> isAvailable({required String from, required String to});
  Future<TranslationResult> translate(
    String text, {
    required String from,
    required String to,
  });
}

class StubTranslator implements Translator {
  @override
  String get engineId => 'stub';

  @override
  bool get isOnlineRequired => false;

  @override
  Future<bool> isAvailable({required String from, required String to}) async {
    return from == to; // identity-only until real engines ship
  }

  @override
  Future<TranslationResult> translate(
    String text, {
    required String from,
    required String to,
  }) async {
    return TranslationResult(
      translated: text, // identity until real engines land
      sourceLang: from,
      targetLang: to,
      engineId: engineId,
    );
  }
}

/// Factory — composes the routing chain per tier per D13.1.
List<Translator> buildTranslatorChain(Tier tier) {
  // TODO: Apple / ML Kit / ONNX / Gemma / Gemini wiring.
  return [StubTranslator()];
}
