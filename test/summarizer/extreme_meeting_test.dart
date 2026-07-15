// Extreme-length meetings (3–6+ hour war rooms and legal depositions). These run
// the REAL pipeline with a FakeBackend that DROPS everything the model would say,
// so the only thing that can preserve the planted facts is the mechanical safety
// net (figure/date sweep, dictated-digit recognition, handoff detection). This
// verifies two things fast and deterministically, without an hour of real
// inference: (1) the pipeline COMPLETES at 3750+ turns / 54k words without
// choking, and (2) every load-bearing fact survives regardless of the model.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recap/billing/persona.dart';
import 'package:recap/services/summarizer/summary_backend.dart';
import 'package:recap/services/summarizer/summary_pipeline.dart';
import 'package:recap/services/summarizer/summary_types.dart';

const _gemma = BackendCapabilities(
  contextTokens: 4096,
  maxOutputTokens: 1024,
  supportsSystemPrompt: false,
);

/// A backend that always returns a USELESS summary — it keeps none of the facts.
/// If the final summary still contains them, only the mechanical net could have.
class _DroppingBackend implements SummaryBackend {
  int calls = 0;
  @override
  String get modelId => 'dropping-fake';
  @override
  BackendCapabilities get capabilities => _gemma;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<String> generate({
    required String prompt,
    String? system,
    double temperature = 0.4,
    int? maxOutputTokens,
    CancelToken? cancel,
  }) async {
    calls++;
    // Map-stage prompts get terse empty-ish notes; compose stages get a bare doc.
    return '## TL;DR\n- A long meeting took place and the team talked.';
  }
}

void main() {
  final cases =
      (jsonDecode(
                File(
                  'test/summarizer/eval_cases/extreme_cases.json',
                ).readAsStringSync(),
              )
              as List)
          .cast<Map<String, dynamic>>();

  for (final c in cases) {
    final id = c['id'] as String;
    final wordCount = (c['transcript'] as String).split(RegExp(r'\s+')).length;

    test(
      '$id ($wordCount words) completes and preserves every planted fact',
      () async {
        final segs = _parse(c['transcript'] as String);
        expect(
          segs.length,
          greaterThan(1000),
          reason: 'this must be a genuinely extreme meeting',
        );

        final backend = _DroppingBackend();
        final result = await const SummaryPipeline().run(
          backend: backend,
          input: SummaryInput(
            segments: segs,
            meetingTitle: c['title'] as String,
          ),
          persona: personasByKey['basic']!,
        );

        // (1) It completed and genuinely map-reduced across many chunks.
        expect(
          backend.calls,
          greaterThan(15),
          reason: 'a 3–6 hour meeting must fan out into many model calls',
        );

        // (1b) It used the CHAPTERED architecture — navigable, timestamped
        // sections — so narrative quality does not decay with total length.
        final chapterCount = RegExp(
          r'## Chapter \d+',
        ).allMatches(result.text).length;
        expect(
          chapterCount,
          greaterThanOrEqualTo(3),
          reason: 'a 3–6 hour meeting must be summarized in multiple chapters',
        );
        expect(
          result.text.toLowerCase(),
          contains('summarized in chapters'),
          reason: 'the chaptered navigation notice must be present',
        );

        // (2) Every mustContain + continuity needle survived — via the safety net
        // alone, since the model dropped everything.
        final summary = result.text.toLowerCase();
        final rubric = c['rubric'] as Map<String, dynamic>;
        for (final field in ['mustContain', 'continuity']) {
          for (final item
              in (rubric[field] as List).cast<Map<String, dynamic>>()) {
            final needle = (item['needle'] as String).toLowerCase();
            expect(
              _match(summary, needle),
              isTrue,
              reason:
                  '$id lost "$needle" ($field) — the mechanical net must '
                  'preserve it even when the model keeps nothing',
            );
          }
        }
        // (3) No trap was fabricated.
        for (final item
            in (rubric['mustNotContain'] as List)
                .cast<Map<String, dynamic>>()) {
          final needle = (item['needle'] as String).toLowerCase();
          expect(
            _match(summary, needle),
            isFalse,
            reason: '$id fabricated the trap "$needle"',
          );
        }
      },
    );
  }

  // Streaming + resume make a 6-hour summary EFFORTLESS: chapters appear as they
  // finish, and an interrupted / navigated-away job does not redo finished work.
  group('effortless long meetings — streaming + resume', () {
    final war = cases.firstWhere((c) => c['id'] == 'extreme-6h-warroom');
    final segs = _parse(war['transcript'] as String);
    final input = SummaryInput(
      segments: segs,
      meetingTitle: war['title'] as String,
    );

    test('streams a partial summary after each chapter', () async {
      final partials = <SummaryResult>[];
      await const SummaryPipeline().run(
        backend: _DroppingBackend(),
        input: input,
        persona: personasByKey['basic']!,
        onPartial: partials.add,
      );
      expect(
        partials.length,
        greaterThanOrEqualTo(3),
        reason: 'one partial per chapter — the user watches it build',
      );
      // Partials grow as chapters land, and each carries the running progress.
      expect(
        partials.last.text.length,
        greaterThan(partials.first.text.length),
      );
      expect(partials.first.text.toLowerCase(), contains('still summarizing'));
      // Even a mid-flight partial preserves facts (safety net runs each time).
      expect(partials.last.text, contains('880421'));
    });

    test(
      'resumes finished chapters from the store — a re-run barely re-generates',
      () async {
        final store = InMemoryChapterStore();
        final first = _DroppingBackend();
        await const SummaryPipeline().run(
          backend: first,
          input: input,
          persona: personasByKey['basic']!,
          chapterStore: store,
        );
        // Second run with the SAME store (e.g. the user came back, or the job was
        // interrupted and retried): every chapter is cached, so almost no work.
        final second = _DroppingBackend();
        final r2 = await const SummaryPipeline().run(
          backend: second,
          input: input,
          persona: personasByKey['basic']!,
          chapterStore: store,
        );
        expect(
          second.calls,
          lessThan(first.calls ~/ 2),
          reason: 'chapters resumed from the store; only the compose runs',
        );
        // ...and the resumed summary is still complete + faithful.
        expect(r2.text, contains('880421'));
        expect(r2.text.toLowerCase(), contains('surgery'));
      },
    );
  });
}

bool _match(String hay, String needle) {
  if (hay.contains(needle)) return true;
  try {
    return RegExp(needle, caseSensitive: false).hasMatch(hay);
  } catch (_) {
    return false;
  }
}

List<PromptSegment> _parse(String raw) {
  final re = RegExp(
    r"^([A-Za-z][\w .'\-]{0,39})\s*\((\d{1,3}):(\d{2})(?::(\d{2}))?\)\s*$",
  );
  final segs = <PromptSegment>[];
  String? speaker;
  int? startMs;
  final buf = StringBuffer();
  void flush() {
    final t = buf.toString().trim();
    if (speaker != null && t.isNotEmpty) {
      segs.add(PromptSegment(speaker: speaker, startMs: startMs, text: t));
    }
    buf.clear();
  }

  for (final line in const LineSplitter().convert(raw)) {
    final m = re.firstMatch(line.trim());
    if (m != null) {
      flush();
      speaker = m.group(1)!.trim();
      final a = int.parse(m.group(2)!);
      final b = int.parse(m.group(3)!);
      final cc = m.group(4);
      startMs =
          (cc != null ? (a * 3600 + b * 60 + int.parse(cc)) : (a * 60 + b)) *
          1000;
    } else {
      buf.write(' $line');
    }
  }
  flush();
  return segs;
}
