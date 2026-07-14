import '../../billing/tier.dart';
import '../../data/database.dart';
import '../summarizer/summary_backend.dart';
import '../summarizer/summary_types.dart';
import 'segment_retriever.dart';

/// A citation the UI can deep-link from. `transcript_screen` already does
/// tap-to-seek (`_audio.seekMs(seg.startMs)`), so a citation only needs the
/// meeting and the offset.
class ChatCitation {
  const ChatCitation({
    required this.index,
    required this.meetingId,
    required this.meetingTitle,
    required this.startMs,
    required this.quote,
  });

  final int index; // the [1] the model wrote
  final String meetingId;
  final String meetingTitle;
  final int startMs;
  final String quote;
}

class ChatAnswer {
  const ChatAnswer({
    required this.text,
    required this.citations,
    required this.modelId,
  });

  final String text;
  final List<ChatCitation> citations;
  final String modelId;
}

/// "Ask your notes anything", over the local corpus.
///
/// Runs ON-DEVICE by default — Gemma / Apple FM / Ollama — which means it works
/// offline, costs nothing per question, and **the Privacy tier gets it**.
/// Granola's chat is cloud-only, so a Privacy-tier user simply cannot have it
/// there. Cloud chat is a later, opt-in upgrade with its own meter; it must
/// never quietly spend cloud-SUMMARY credits, or a few chat turns would silently
/// consume summaries the user paid for.
class ChatService {
  ChatService({
    required this.db,
    required this.retriever,
    required this.backends,
    required this.tierProvider,
  });

  final AppDb db;
  final SegmentRetriever retriever;

  /// On-device backends in priority order (Ollama → Apple FM → Gemma). Same
  /// objects the summarizer uses: the refactor made SummaryBackend a plain
  /// generation engine, so chat needs no parallel interface.
  final List<SummaryBackend> backends;

  final Tier Function() tierProvider;

  static const _system =
      'You answer questions about the user\'s own meeting recordings.\n'
      'Rules:\n'
      '- Use ONLY the numbered excerpts provided. They are the only source.\n'
      '- Cite every claim with its excerpt number in square brackets, like [2].\n'
      '- If the excerpts do not contain the answer, say so plainly. Do not '
      'guess, and do not use outside knowledge.\n'
      '- Be brief and concrete. Quote the speaker when it matters.';

  Future<SummaryBackend?> _pickBackend() async {
    for (final b in backends) {
      if (await b.isAvailable()) return b;
    }
    return null;
  }

  /// Answer [question] from the corpus (or one meeting).
  ///
  /// Throws [StateError] when no on-device model is installed — it does not
  /// invent an answer or silently return an empty one.
  Future<ChatAnswer> ask(
    String question, {
    String? meetingId,
    CancelToken? cancel,
  }) async {
    final q = question.trim();
    if (q.isEmpty) throw ArgumentError('Question cannot be empty');

    // Confidential meetings are excluded from retrieval unconditionally. Doing
    // this at the RETRIEVER, not at the prompt, means a confidential transcript
    // cannot reach a backend at all — including a cloud one, later.
    final confidential = await _confidentialMeetingIds();

    final hits = await retriever.retrieve(
      q,
      meetingId: meetingId,
      limit: 8,
      excludeMeetingIds: confidential,
    );
    cancel?.throwIfCancelled();

    if (hits.isEmpty) {
      return const ChatAnswer(
        text: "I couldn't find anything about that in your recordings.",
        citations: [],
        modelId: 'none',
      );
    }

    final backend = await _pickBackend();
    if (backend == null) {
      throw StateError(
        'No on-device model is available for chat. Download the on-device '
        'summary model in Settings, then try again.',
      );
    }

    final buf = StringBuffer()
      ..writeln('Excerpts from the user\'s recordings:')
      ..writeln();
    for (var i = 0; i < hits.length; i++) {
      final h = hits[i];
      final who = h.speakerLabel != null ? '${h.speakerLabel}: ' : '';
      buf
        ..writeln('[${i + 1}] (${h.meetingTitle}, ${_ts(h.startMs)})')
        ..writeln('$who${h.body.trim()}')
        ..writeln();
    }
    buf
      ..writeln('Question: $q')
      ..writeln()
      ..writeln('Answer, citing excerpt numbers:');

    final text = await backend.generate(
      prompt: buf.toString(),
      system: _system,
      temperature: 0.2, // factual recall, not creative writing
      cancel: cancel,
    );

    return ChatAnswer(
      text: text.trim(),
      citations: _extractCitations(text, hits),
      modelId: backend.modelId,
    );
  }

  /// Map the `[n]` markers the model actually used back to their segments.
  /// Only cite what it referenced — listing all 8 excerpts as "citations" when
  /// it leaned on two is noise dressed up as rigour.
  List<ChatCitation> _extractCitations(
    String answer,
    List<RetrievedSegment> hits,
  ) {
    final used = <int>{};
    for (final m in RegExp(r'\[(\d{1,2})\]').allMatches(answer)) {
      final n = int.tryParse(m.group(1)!);
      if (n != null && n >= 1 && n <= hits.length) used.add(n);
    }
    final out = <ChatCitation>[];
    for (final n in used.toList()..sort()) {
      final h = hits[n - 1];
      out.add(ChatCitation(
        index: n,
        meetingId: h.meetingId,
        meetingTitle: h.meetingTitle,
        startMs: h.startMs,
        quote: h.body.trim(),
      ));
    }
    return out;
  }

  /// Meetings the user flagged confidential.
  ///
  /// The schema has no `confidential` column yet (it arrives with the per-meeting
  /// flag), so this is empty today. It exists now so the exclusion is wired
  /// through the retriever from day one rather than bolted on after a leak.
  Future<Set<String>> _confidentialMeetingIds() async => const {};

  static String _ts(int ms) {
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }
}
