import 'summary_types.dart';

class SummaryResult {
  final String text;
  final String modelId;
  final Duration processingTime;

  const SummaryResult({
    required this.text,
    required this.modelId,
    required this.processingTime,
  });
}

/// A dumb generation engine. Nothing more.
///
/// Backends used to own the whole prompt (`persona.prompt + transcript`), which
/// meant every prompt fix had to be made five times and no backend could chunk.
/// Prompt composition, chunking, map-reduce and the critic pass now live in
/// `SummaryPipeline`; a backend's only jobs are to say how big its window is and
/// to run one generation.
///
/// Backends MUST NOT import `persona.dart`.
abstract class SummaryBackend {
  /// Persisted to `summaries.modelId` — keep stable.
  String get modelId;

  /// Drives chunking. See [BackendCapabilities.contextTokens]: combined
  /// input+output.
  BackendCapabilities get capabilities;

  /// Cheap availability check. Implementations should not throw.
  Future<bool> isAvailable();

  /// Single raw generation. The pipeline composes [prompt] and [system].
  ///
  /// [maxOutputTokens] defaults to [BackendCapabilities.maxOutputTokens] when
  /// null. Backends that cannot take a system prompt
  /// ([BackendCapabilities.supportsSystemPrompt] == false) must prepend it to
  /// the user prompt rather than drop it — silently dropping the preamble
  /// discards every anti-hallucination rule.
  ///
  /// Must throw on failure (never return "" to fake success) and must honour
  /// [cancel] between whatever internal steps it has.
  Future<String> generate({
    required String prompt,
    String? system,
    double temperature = 0.4,
    int? maxOutputTokens,
    CancelToken? cancel,
  });
}
