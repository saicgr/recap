import '../../data/database.dart';
import 'summary_types.dart';

/// Above this, a run of same-speaker segments stops merging and a fresh
/// `[mm:ss] Speaker:` line starts.
///
/// Merging is what kills label noise and saves tokens, but merging without a cap
/// destroys the thing the prompts depend on: an undiarized Whisper transcript is
/// one long run of null-speaker segments, and merging all of it yields a single
/// timestamp-free blob that can neither be cited nor chunked. ~600 chars keeps
/// citations at roughly paragraph granularity.
const _mergeCharLimit = 600;

/// Same-speaker segments separated by more than this are NOT merged — a
/// 30-second gap means the speaker came back to a different thought, and folding
/// them together would attach the later claim to the earlier timestamp.
const _mergeGapMs = 20 * 1000;

/// Build the citable, attributed segments the prompts consume.
///
/// [segments] is the source of truth when present (it carries `speakerLabel` and
/// timing — the thing the old summarizer threw away by feeding `transcripts.body`).
/// [speakerAliases] maps raw diarization labels to enrolled names, e.g.
/// `{'Speaker 1': 'Dana'}`.
///
/// When [segments] is empty (imported captions, pasted text) we synthesize
/// speaker-less, timing-less segments from [fallbackBody] rather than throwing:
/// the prompts render fine without either. Only a transcript that is empty BOTH
/// ways is an error — and it is a real one, not something to paper over with "".
List<PromptSegment> buildPromptSegments({
  required List<TranscriptSegment> segments,
  required String fallbackBody,
  Map<String, String> speakerAliases = const {},
}) {
  final usable = segments
      .where((s) => s.body.trim().isNotEmpty)
      .toList(growable: false)
    ..sort((a, b) => a.startMs.compareTo(b.startMs));

  if (usable.isEmpty) {
    final body = fallbackBody.trim();
    if (body.isEmpty) {
      throw StateError(
        'Cannot summarize: transcript has no segments and an empty body. '
        'The meeting was never transcribed, or transcription failed and left a '
        'blank row.',
      );
    }
    return _fromFlatBody(body);
  }

  final merged = <PromptSegment>[];
  for (final s in usable) {
    final speaker = _alias(s.speakerLabel, speakerAliases);
    final text = s.body.trim();

    final last = merged.isEmpty ? null : merged.last;
    final canMerge = last != null &&
        last.speaker == speaker &&
        last.text.length + text.length + 1 <= _mergeCharLimit &&
        (last.endMs == null || s.startMs - last.endMs! <= _mergeGapMs);

    if (canMerge) {
      merged[merged.length - 1] = PromptSegment(
        speaker: speaker,
        startMs: last.startMs, // first start
        endMs: s.endMs, // last end
        text: '${last.text} $text',
      );
    } else {
      merged.add(PromptSegment(
        speaker: speaker,
        startMs: s.startMs,
        endMs: s.endMs,
        text: text,
      ));
    }
  }
  return merged;
}

String? _alias(String? label, Map<String, String> aliases) {
  if (label == null) return null;
  final trimmed = label.trim();
  if (trimmed.isEmpty) return null;
  return aliases[trimmed] ?? trimmed;
}

/// Split a flat body into paragraph-sized segments with no speaker and no
/// timing. Paragraph breaks first; if the body is one wall of text (Whisper's
/// usual output), fall back to sentence-packed blocks so the chunker still has
/// seams to cut on.
List<PromptSegment> _fromFlatBody(String body) {
  final paras = body
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList(growable: false);

  final source = paras.length > 1 ? paras : _packSentences(body);
  return source.map((p) => PromptSegment(text: p)).toList(growable: false);
}

List<String> _packSentences(String body) {
  final sentences = splitSentences(body);
  final out = <String>[];
  final buf = StringBuffer();
  for (final s in sentences) {
    if (buf.isNotEmpty && buf.length + s.length + 1 > _mergeCharLimit) {
      out.add(buf.toString().trim());
      buf.clear();
    }
    if (buf.isNotEmpty) buf.write(' ');
    buf.write(s);
  }
  if (buf.isNotEmpty) out.add(buf.toString().trim());
  return out.isEmpty ? [body.trim()] : out;
}

/// Sentence split on terminal punctuation. Shared with the chunker, which needs
/// the same seams when it is forced to hard-split an oversized segment.
List<String> splitSentences(String text) {
  final parts = text
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList(growable: false);
  return parts.isEmpty ? [text.trim()] : parts;
}

/// `[00:21] Speaker 1: text` — the citable line format every prompt rule
/// ("every claim carries the [mm:ss]") is written against.
///
/// The `[mm:ss]` is omitted when there is no timing and the `Speaker N:` when
/// there is no diarization. The model is told to cite what exists, not to invent
/// what does not.
String renderSegment(PromptSegment s) {
  final b = StringBuffer();
  if (s.startMs != null) b.write('[${formatTimestamp(s.startMs!)}] ');
  if (s.speaker != null) b.write('${s.speaker}: ');
  b.write(s.text);
  return b.toString();
}

String renderSegments(List<PromptSegment> segments) =>
    segments.map(renderSegment).join('\n');

/// mm:ss, or h:mm:ss past the hour.
String formatTimestamp(int ms) {
  final total = ms ~/ 1000;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}
