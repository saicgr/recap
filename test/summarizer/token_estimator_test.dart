import 'package:flutter_test/flutter_test.dart';
import 'package:recap/services/summarizer/token_estimator.dart';

/// The estimator is the pipeline's only defence against the P0 it exists to fix:
/// a 25-minute meeting silently overflowing Gemma's 4096-token COMBINED window.
/// Every budget in `summary_pipeline.dart` is computed from this number, so the
/// one property that must never regress is that it OVER-estimates. A future
/// "let's make this more accurate" tweak that drops below the chars/4 rule of
/// thumb re-opens the overflow bug, and these tests are where it should die.
void main() {
  /// The industry rule of thumb for English prose. Our estimate must never come
  /// in under it.
  int baseline(String s) => (s.length / 4).ceil();

  group('estimateTokens is conservative', () {
    const samples = <String>[
      '',
      'a',
      'Hello world.',
      'The quick brown fox jumps over the lazy dog.',
      // Real ASR shapes: garbled proper nouns, piecemeal digits, promo IDs.
      "so the promo is 6 5 7 6 6 and it's labelled five dollar off laurel T",
      'skin apps is ptc driven and the R GM team owns the musk buy list',
      '75 cents a gallon up to 15 gallons so about \$8 and they always claim the max',
      'Speaker 1: I am out for surgery next week, so reach out to Lisa instead.',
      // Digit-dense line — exactly what tokenizes worst.
      '1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 65766 40201 \$8.00 12% Q3 2026',
    ];

    for (final s in samples) {
      test('never under-estimates vs chars/4 — "${_label(s)}"', () {
        expect(
          estimateTokens(s),
          greaterThanOrEqualTo(baseline(s)),
          reason:
              'estimateTokens must over-estimate; under-estimating '
              'silently overflows the on-device context window.',
        );
      });
    }

    test('never under-estimates across a large sweep of lengths', () {
      for (var len = 0; len < 5000; len += 7) {
        final s = 'x' * len;
        expect(
          estimateTokens(s),
          greaterThanOrEqualTo(baseline(s)),
          reason: 'failed at length $len',
        );
      }
    });

    test('is strictly pessimistic (>= baseline) on realistic prose', () {
      final prose = 'The quick brown fox jumps over the lazy dog. ' * 200;
      expect(estimateTokens(prose), greaterThan(baseline(prose)));
    });
  });

  group('estimateTokens basics', () {
    test('empty string is 0 tokens', () {
      expect(estimateTokens(''), 0);
    });

    test('rounds up — a fragment is never free', () {
      // 1 char / 3.6 = 0.27 -> 1. A budget check must never see "0 tokens" for
      // real content.
      expect(estimateTokens('a'), 1);
      expect(estimateTokens('abc'), 1);
    });

    test('is monotonic in length', () {
      var prev = 0;
      for (var len = 0; len < 500; len++) {
        final t = estimateTokens('y' * len);
        expect(t, greaterThanOrEqualTo(prev));
        prev = t;
      }
    });

    test('uses the documented 3.6 chars/token ratio', () {
      expect(estimateTokens('z' * 36), 10);
      expect(estimateTokens('z' * 3600), 1000);
    });
  });
}

String _label(String s) {
  if (s.isEmpty) return '(empty)';
  return s.length <= 32 ? s : '${s.substring(0, 32)}…';
}
