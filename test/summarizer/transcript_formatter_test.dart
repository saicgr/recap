import 'package:flutter_test/flutter_test.dart';
import 'package:recap/data/database.dart';
import 'package:recap/services/summarizer/summary_types.dart';
import 'package:recap/services/summarizer/transcript_formatter.dart';

/// The bug this file guards: the summarizer used to be fed `transcripts.body` —
/// flat Whisper text — while the speaker labels sat on
/// `transcript_segments.speakerLabel` and NEVER reached the prompt. The prompts
/// now say "ATTRIBUTE. Use speaker labels exactly as given" and "CITE. Every
/// claim carries the [mm:ss]", which is only possible if the formatter puts both
/// on the line. These tests are the contract for that.
void main() {
  group('formatTimestamp', () {
    test('mm:ss under an hour, zero-padded', () {
      expect(formatTimestamp(0), '00:00');
      expect(formatTimestamp(1000), '00:01');
      expect(formatTimestamp(21000), '00:21');
      expect(formatTimestamp(61000), '01:01');
      expect(formatTimestamp(599000), '09:59');
      expect(formatTimestamp(3599000), '59:59');
    });

    test(
      'h:mm:ss past the hour — a 90-minute meeting must not wrap to 30:00',
      () {
        expect(formatTimestamp(3600000), '1:00:00');
        expect(formatTimestamp(3661000), '1:01:01');
        expect(formatTimestamp(3723000), '1:02:03');
        expect(formatTimestamp(5400000), '1:30:00');
        expect(formatTimestamp(7325000), '2:02:05');
      },
    );

    test('truncates sub-second, never rounds up into the next second', () {
      expect(formatTimestamp(1999), '00:01');
    });
  });

  group('renderSegment', () {
    test('renders [mm:ss] Speaker: text when both are present', () {
      expect(
        renderSegment(
          const PromptSegment(
            startMs: 21000,
            speaker: 'Speaker 1',
            text: 'Hello there.',
          ),
        ),
        '[00:21] Speaker 1: Hello there.',
      );
    });

    test('omits the speaker when diarization never ran', () {
      expect(
        renderSegment(const PromptSegment(startMs: 21000, text: 'Hello.')),
        '[00:21] Hello.',
      );
    });

    test('omits the [mm:ss] when the transcript has no timing', () {
      expect(
        renderSegment(const PromptSegment(speaker: 'Dana', text: 'Hello.')),
        'Dana: Hello.',
      );
    });

    test('renders bare text when there is neither — imported captions', () {
      expect(renderSegment(const PromptSegment(text: 'Hello.')), 'Hello.');
    });

    test('renderSegments joins on newlines, one citable line each', () {
      final out = renderSegments(const [
        PromptSegment(startMs: 0, speaker: 'Speaker 1', text: 'One.'),
        PromptSegment(startMs: 65000, speaker: 'Speaker 2', text: 'Two.'),
      ]);
      expect(out, '[00:00] Speaker 1: One.\n[01:05] Speaker 2: Two.');
    });
  });

  group('buildPromptSegments — speaker merge', () {
    test('merges CONSECUTIVE same-speaker segments into one', () {
      final out = buildPromptSegments(
        segments: [
          _seg(0, 2000, 'Speaker 1', 'Okay so'),
          _seg(2000, 4000, 'Speaker 1', 'the promo is live.'),
          _seg(4000, 6000, 'Speaker 2', 'Since when?'),
        ],
        fallbackBody: 'unused',
      );

      expect(out.length, 2, reason: 'the two Speaker 1 turns must fuse');
      expect(out[0].speaker, 'Speaker 1');
      expect(out[0].text, 'Okay so the promo is live.');
      expect(out[0].startMs, 0, reason: 'keeps the FIRST start');
      expect(out[0].endMs, 4000, reason: 'keeps the LAST end');
      expect(out[1].speaker, 'Speaker 2');
      expect(out[1].text, 'Since when?');
    });

    test('does NOT merge across a speaker change', () {
      final out = buildPromptSegments(
        segments: [
          _seg(0, 1000, 'Speaker 1', 'A.'),
          _seg(1000, 2000, 'Speaker 2', 'B.'),
          _seg(2000, 3000, 'Speaker 1', 'C.'),
        ],
        fallbackBody: '',
      );
      expect(out.map((s) => s.text).toList(), ['A.', 'B.', 'C.']);
      expect(out.map((s) => s.speaker).toList(), [
        'Speaker 1',
        'Speaker 2',
        'Speaker 1',
      ]);
    });

    test('applies speakerAliases so enrolled names reach the prompt', () {
      final out = buildPromptSegments(
        segments: [
          _seg(0, 1000, 'Speaker 1', 'A.'),
          _seg(1000, 2000, 'Speaker 2', 'B.'),
        ],
        fallbackBody: '',
        speakerAliases: const {'Speaker 1': 'Dana'},
      );
      expect(out[0].speaker, 'Dana');
      expect(
        out[1].speaker,
        'Speaker 2',
        reason: 'unaliased labels pass through',
      );
    });

    test('sorts by startMs before merging — out-of-order rows must not fuse '
        'the wrong turns', () {
      final out = buildPromptSegments(
        segments: [
          _seg(4000, 6000, 'Speaker 1', 'Third.'),
          _seg(0, 2000, 'Speaker 1', 'First.'),
          _seg(2000, 4000, 'Speaker 2', 'Second.'),
        ],
        fallbackBody: '',
      );
      expect(out.map((s) => s.text).toList(), ['First.', 'Second.', 'Third.']);
    });

    test('drops blank segments rather than emitting an empty citable line', () {
      final out = buildPromptSegments(
        segments: [
          _seg(0, 1000, 'Speaker 1', 'A.'),
          _seg(1000, 2000, 'Speaker 1', '   '),
          _seg(2000, 3000, 'Speaker 2', 'B.'),
        ],
        fallbackBody: '',
      );
      expect(out.length, 2);
      expect(out[0].text, 'A.');
      expect(out[1].text, 'B.');
    });

    test('a long same-speaker run does NOT fuse into one uncitable blob', () {
      // Merging without a cap is how an undiarized Whisper transcript becomes a
      // single timestamp-free wall that can be neither cited nor chunked.
      final segs = [
        for (var i = 0; i < 40; i++)
          _seg(
            i * 1000,
            (i + 1) * 1000,
            'Speaker 1',
            'This is turn number $i of a long uninterrupted monologue.',
          ),
      ];
      final out = buildPromptSegments(segments: segs, fallbackBody: '');
      expect(
        out.length,
        greaterThan(1),
        reason: 'must keep citation granularity',
      );
      for (final s in out) {
        expect(s.startMs, isNotNull);
      }
    });

    test('does not merge same-speaker turns separated by a long gap', () {
      // A 60s gap means a different thought; folding them attaches the later
      // claim to the earlier timestamp.
      final out = buildPromptSegments(
        segments: [
          _seg(0, 2000, 'Speaker 1', 'Before the break.'),
          _seg(62000, 64000, 'Speaker 1', 'After the break.'),
        ],
        fallbackBody: '',
      );
      expect(out.length, 2);
      expect(out[1].startMs, 62000);
    });
  });

  group('buildPromptSegments — fallback to the flat body', () {
    test('segments EMPTY (imported captions) synthesizes from the body', () {
      final out = buildPromptSegments(
        segments: const [],
        fallbackBody: 'First paragraph here.\n\nSecond paragraph here.',
      );
      expect(out.length, 2);
      expect(out[0].text, 'First paragraph here.');
      expect(out[1].text, 'Second paragraph here.');
      for (final s in out) {
        expect(s.speaker, isNull, reason: 'never invent a speaker');
        expect(s.startMs, isNull, reason: 'never invent a timestamp');
      }
    });

    test('a one-wall-of-text body is still split into citable seams', () {
      final body = List.generate(
        60,
        (i) => 'Sentence number $i explains something about the promo.',
      ).join(' ');
      final out = buildPromptSegments(segments: const [], fallbackBody: body);
      expect(
        out.length,
        greaterThan(1),
        reason: 'the chunker needs seams to cut on',
      );
      expect(out.every((s) => s.text.trim().isNotEmpty), isTrue);
    });

    test(
      'renders without speakers or timestamps — no invented attribution',
      () {
        final out = buildPromptSegments(
          segments: const [],
          fallbackBody: 'Alpha.\n\nBeta.',
        );
        expect(renderSegments(out), 'Alpha.\nBeta.');
      },
    );

    test(
      'blank-bodied segments fall back to the body rather than throwing',
      () {
        final out = buildPromptSegments(
          segments: [_seg(0, 1000, 'Speaker 1', '   ')],
          fallbackBody: 'The real transcript.',
        );
        expect(out.length, 1);
        expect(out.first.text, 'The real transcript.');
      },
    );
  });

  group('buildPromptSegments — the error path', () {
    test('empty segments AND an empty body throws StateError', () {
      // CLAUDE.md: no silent degradation. A broken transcription must surface,
      // not return "" pretending success.
      expect(
        () => buildPromptSegments(segments: const [], fallbackBody: ''),
        throwsA(isA<StateError>()),
      );
    });

    test('empty segments AND a whitespace-only body throws StateError', () {
      expect(
        () =>
            buildPromptSegments(segments: const [], fallbackBody: '   \n\n  '),
        throwsA(isA<StateError>()),
      );
    });

    test('the StateError carries context, not a bare message', () {
      try {
        buildPromptSegments(segments: const [], fallbackBody: '');
        fail('expected a StateError');
      } on StateError catch (e) {
        expect(e.message, contains('Cannot summarize'));
        expect(e.message.length, greaterThan(40));
      }
    });
  });

  group('splitSentences', () {
    test('splits on terminal punctuation', () {
      expect(splitSentences('One. Two! Three? Four.'), [
        'One.',
        'Two!',
        'Three?',
        'Four.',
      ]);
    });

    test('unpunctuated ASR output stays whole rather than vanishing', () {
      expect(splitSentences('so yeah the thing about the promo is'), [
        'so yeah the thing about the promo is',
      ]);
    });
  });
}

TranscriptSegment _seg(int startMs, int endMs, String? speaker, String body) =>
    TranscriptSegment(
      id: 's$startMs',
      meetingId: 'm1',
      startMs: startMs,
      endMs: endMs,
      body: body,
      isFinal: true,
      speakerLabel: speaker,
    );
