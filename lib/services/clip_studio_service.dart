import '../billing/persona.dart' show Persona;
import '../billing/tier.dart' show SummaryStyle;
import '../data/database.dart';

/// Viral Clip Studio (C3) — the marquee moat-expanding feature. Takes a
/// long-form recording (meeting / podcast / lecture / interview) and emits
/// vertical 9:16 clips with kinetic captions for Reels / TikTok / Shorts.
///
/// **Why on-device matters competitively:** Submagic / Opus Clip both
/// upload your audio to their servers. We're the only one doing it on-device,
/// preserving the Karpathy invariants.
///
/// **Pipeline (all on-device):**
///   1. Word-level timestamps via whisper.cpp `-ml 1` tokens (or WhisperX-
///      style phoneme alignment).
///   2. Clip-worthiness scoring via Apple FM / Gemma 4 / Ollama on desktop —
///      "score this 30-60s window for viral potential, return JSON".
///   3. Vertical 9:16 render via ffmpeg_kit_flutter — crop/pad, burn-in
///      captions with kinetic word-by-word ASS templates.
///   4. Optional waveform visualization for audio-only sources.
class ClipCandidate {
  final int startMs;
  final int endMs;
  final double score; // 0..1
  final String hook;
  final String body;
  const ClipCandidate({
    required this.startMs,
    required this.endMs,
    required this.score,
    required this.hook,
    required this.body,
  });
}

class ClipStudioService {
  /// Score the meeting's segments for viral potential and return top-k
  /// candidates. Calls the appropriate summarizer (Apple FM / Gemma 4 /
  /// Ollama) with a "score this for viral worthiness" prompt.
  Future<List<ClipCandidate>> findCandidates({
    required Meeting meeting,
    required List<TranscriptSegment> segments,
    int topK = 5,
    Duration minClipLen = const Duration(seconds: 25),
    Duration maxClipLen = const Duration(seconds: 65),
  }) async {
    // TODO: full LLM scoring pass. Heuristic fallback: pick segments with
    // high word density + named entities + emphatic punctuation. For now,
    // return the longest contiguous high-density windows in [minClipLen,
    // maxClipLen] so the rest of the pipeline (preview + render) can be
    // exercised in dev.
    if (segments.isEmpty) return const [];
    final candidates = <ClipCandidate>[];
    var current = <TranscriptSegment>[];
    int currentMs = 0;
    for (final s in segments) {
      current.add(s);
      currentMs += (s.endMs - s.startMs);
      if (currentMs >= minClipLen.inMilliseconds) {
        candidates.add(
          ClipCandidate(
            startMs: current.first.startMs,
            endMs: current.last.endMs,
            score: 0.6,
            hook: current.first.body.split(' ').take(8).join(' '),
            body: current.map((s) => s.body).join(' '),
          ),
        );
        current = [];
        currentMs = 0;
      }
      if (currentMs > maxClipLen.inMilliseconds) {
        current = [];
        currentMs = 0;
      }
    }
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(topK).toList();
  }

  /// Render a single clip as a 9:16 vertical video with burned-in
  /// kinetic captions. ffmpeg_kit_flutter pipeline:
  ///   1. ffmpeg -i input.wav -i waveform.mov -filter_complex … out.mp4
  ///   2. Burn-in captions via subtitles=… filter with ASS template
  /// Returns the on-disk path.
  Future<String> renderClip({
    required ClipCandidate candidate,
    required String sourceAudioPath,
    required ClipTemplate template,
    bool watermark = true,
  }) async {
    // TODO: real ffmpeg pipeline. For v1 dev, write a stub .mp4-named text
    // file so the Clip Studio screen can be wired end-to-end.
    throw UnimplementedError(
      'Clip rendering requires ffmpeg_kit_flutter; pipeline TODO.',
    );
  }
}

enum ClipTemplate {
  /// Submagic-inspired: bold yellow highlighted keyword on white text.
  highlightedWord,

  /// Bold yellow text with black outline. Classic.
  boldYellow,

  /// Neon outline (cyan + magenta). High-contrast for dark videos.
  neonOutline,

  /// Minimal: white text, no decorations. Editor-friendly.
  minimal,
}

/// Resolve the right persona-style prompt for the LLM scoring step.
/// Power-tier users can override with a custom persona.
Persona viralScoringPersona() => const Persona(
  style: SummaryStyle.basic,
  key: 'viral_clip_scoring',
  displayName: 'Viral clip scoring',
  emoji: '✨',
  prompt: '''
You are scoring a meeting / podcast / lecture transcript for short-form
social-video potential. For each ~30-60s window, output a JSON line:
{"startMs":..., "endMs":..., "score":0..1, "hook":"first 8 words",
"reason":"why it's clip-worthy"}

Score high for: surprising claims, strong opinions, vivid stories, clear
takeaways, emotional beats, sharp one-liners. Score low for: meta talk,
filler, scheduling, "uh"s. Output top 5 only.
''',
);
