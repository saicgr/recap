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
