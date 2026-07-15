/// Shared value types for the summarizer pipeline.
///
/// The pipeline — not the backends — owns every prompt. Backends are dumb
/// generation engines that advertise their window via [BackendCapabilities];
/// everything else here is what flows between the pipeline stages.
library;

/// What a backend can physically accept and emit in one call.
///
/// [contextTokens] is the COMBINED input+output budget (that is how
/// flutter_gemma's `maxTokens` behaves — the 4096 there is not 4096 of input),
/// so the pipeline must reserve [maxOutputTokens] before it packs any prompt.
/// Getting this wrong is the exact P0 we are fixing: a 25-min meeting is ~3.8k
/// tokens and silently overflowed a 4096 combined window.
class BackendCapabilities {
  final int contextTokens;
  final int maxOutputTokens;
  final bool supportsSystemPrompt;

  const BackendCapabilities({
    required this.contextTokens,
    required this.maxOutputTokens,
    this.supportsSystemPrompt = true,
  });

  /// The budget actually available for system + instruction + transcript.
  int get maxInputTokens => contextTokens - maxOutputTokens;
}

/// One attributable, citable unit of transcript.
///
/// [speaker] is null when diarization never ran; [startMs]/[endMs] are null when
/// the transcript has no timing at all (imported YouTube captions, pasted text).
/// Both cases are normal — the prompts render without the missing piece rather
/// than inventing one.
class PromptSegment {
  final String? speaker;
  final int? startMs;
  final int? endMs;
  final String text;

  const PromptSegment({
    required this.text,
    this.speaker,
    this.startMs,
    this.endMs,
  });
}

/// Everything the pipeline needs about the meeting. Note this is segments, not
/// a flat body: the old code fed `transcripts.body` and speaker labels never
/// reached the model.
class SummaryInput {
  final List<PromptSegment> segments;
  final String meetingTitle;

  /// Preferred spellings for domain terms the ASR mangles ("skin apps" ->
  /// "Scan Apps"). May be empty. Built by `summary_glossary.dart`.
  final List<String> glossary;

  const SummaryInput({
    required this.segments,
    required this.meetingTitle,
    this.glossary = const [],
  });
}

/// Cheap preview (no generation) of how a summary will run on a given backend.
/// The UI uses [willMapReduce] to decide whether to OFFER a cloud summary for a
/// long meeting on a non-Privacy tier — the meetings where a 2B loses the most
/// and where cloud is worth a credit. Computed the same way the pipeline decides,
/// so the offer matches what would actually happen.
class SummaryPlan {
  /// True when the transcript does not fit the backend's single-pass window and
  /// will be chunked + folded — i.e. a long meeting.
  final bool willMapReduce;

  /// Number of map chunks (1 for the single-pass path).
  final int chunkCount;

  const SummaryPlan({required this.willMapReduce, required this.chunkCount});

  /// A meeting worth offering a cloud upgrade for.
  bool get isLong => willMapReduce;

  /// A meeting so long (>=12 chunks — roughly 3 hours and up: a prod war room, a
  /// legal deposition) that on-device is genuinely impractical: 30-60+ minutes of
  /// sustained, hot, sequential compute, with heavy fold compression. Here cloud
  /// should be STRONGLY recommended, not merely offered — the on-device path
  /// stays available for privileged/Privacy-tier work but with an honest warning
  /// about time and compression.
  bool get isExtreme => chunkCount >= 12;
}

enum SummaryStage { preparing, mapping, reducing, checking, done }

class SummaryProgress {
  final SummaryStage stage;

  /// 1-based.
  final int step;
  final int totalSteps;

  /// Human string for the UI ("Reading part 3 of 7...").
  final String label;

  const SummaryProgress({
    required this.stage,
    required this.step,
    required this.totalSteps,
    required this.label,
  });

  double get fraction => totalSteps == 0 ? 0 : step / totalSteps;
}

/// Cooperative cancellation. On-device map-reduce over a 1hr meeting is minutes
/// of GPU work; the user must be able to walk away from it (CLAUDE.md:
/// "transcription is async + cancellable" — summaries inherit the same rule).
class CancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;

  void throwIfCancelled() {
    if (_cancelled) throw const SummaryCancelled();
  }
}

/// Thrown through the pipeline when the user cancels. The UI must swallow this
/// silently — it is not an error state.
class SummaryCancelled implements Exception {
  const SummaryCancelled();

  @override
  String toString() => 'SummaryCancelled';
}
