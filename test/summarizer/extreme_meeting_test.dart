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
