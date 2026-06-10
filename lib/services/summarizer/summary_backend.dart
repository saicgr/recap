import '../../billing/persona.dart';

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

abstract class SummaryBackend {
  /// Cheap availability check. Implementations should not throw.
  Future<bool> isAvailable();

  Future<SummaryResult> summarize({
    required String transcript,
    required Persona persona,
    void Function(double progress)? onProgress,
  });
}
