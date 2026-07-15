// Verifies the "creative UI" is real, not just compiling: the summary renderer
// turns markdown-ish summary text into headers, bullets, notes, bold, and —
// the delight — tappable [mm:ss] citations that seek the audio player.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recap/ui/theme.dart';
import 'package:recap/widgets/summary_markdown.dart';

RecapTheme _theme() => RecapTheme.build(
  mode: RecapMode.light,
  accentOpt: accentOptions[0],
  buttonStyle: RecapButtonStyle.flat,
);

Future<void> _pump(
  WidgetTester tester,
  String text, {
  void Function(int)? onSeekMs,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SummaryMarkdown(text, _theme(), onSeekMs: onSeekMs),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders headers, chapter sub-headers, bullets, and notes', (
    tester,
  ) async {
    await _pump(tester, '''
## TL;DR
- The team shipped the fix.
- Rollback was **avoided**.

### Chapter 1 — Incident
> Escalate to on-call if error rate exceeds 2%.
''');
    expect(find.text('TL;DR'), findsOneWidget);
    expect(find.text('Chapter 1 — Incident'), findsOneWidget);
    // Bullets render their text (SelectableText.rich -> matched via textContaining).
    expect(find.textContaining('The team shipped the fix.'), findsOneWidget);
    // Bold splits into a separate span but the plain remainder still shows.
    expect(find.textContaining('Rollback was'), findsOneWidget);
    // The note quote renders its content.
    expect(find.textContaining('Escalate to on-call'), findsOneWidget);
  });

  testWidgets('a [mm:ss] citation is tappable and seeks the right ms', (
    tester,
  ) async {
    var seeked = -1;
    await _pump(
      tester,
      '- Decision made at [12:34] to roll forward.',
      onSeekMs: (ms) => seeked = ms,
    );
    // The chip shows the timestamp label.
    expect(find.text('12:34'), findsOneWidget);
    await tester.tap(find.text('12:34'));
    await tester.pump();
    expect(seeked, (12 * 60 + 34) * 1000);
  });

  testWidgets('an [h:mm:ss] citation seeks hours correctly — 6h meetings', (
    tester,
  ) async {
    var seeked = -1;
    await _pump(
      tester,
      'War room resolved at [5:47:09].',
      onSeekMs: (ms) => seeked = ms,
    );
    expect(find.text('5:47:09'), findsOneWidget);
    await tester.tap(find.text('5:47:09'));
    await tester.pump();
    expect(seeked, (5 * 3600 + 47 * 60 + 9) * 1000);
  });

  testWidgets('renders without an onSeekMs (read-only preview) — no crash', (
    tester,
  ) async {
    await _pump(tester, '- A point at [00:05].');
    expect(find.text('00:05'), findsOneWidget);
    // Tapping with no handler is a no-op, not an exception.
    await tester.tap(find.text('00:05'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
