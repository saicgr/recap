import '../../data/database.dart';

/// Common shape for all workflow-export targets (Notion / Slack / Obsidian /
/// Google Docs). Each implementation handles OAuth + the destination's
/// API quirks separately; the call sites stay generic.
///
/// Per the plan (D8): shared OAuth helper, token storage via
/// flutter_secure_storage, tier gating on Power for cloud destinations.
abstract class WorkflowExporter {
  String get targetId; // 'notion' | 'slack' | 'gdocs' | 'obsidian'
  String get displayName;
  bool get requiresOAuth;
  bool get isCloudDestination; // Privacy tier must reject these

  Future<bool> isAvailable();
  Future<void> authorize();
  Future<void> deauthorize();
  Future<ExportResult> push({
    required Meeting meeting,
    required Transcript? transcript,
    required List<Summary> summaries,
  });
}

class ExportResult {
  final bool success;
  final String? destinationUrl; // e.g. notion page URL, slack permalink
  final String? errorMessage;
  const ExportResult({
    required this.success,
    this.destinationUrl,
    this.errorMessage,
  });

  factory ExportResult.ok({String? url}) =>
      ExportResult(success: true, destinationUrl: url);
  factory ExportResult.err(String msg) =>
      ExportResult(success: false, errorMessage: msg);
}
