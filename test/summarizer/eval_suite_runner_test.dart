// Batch eval runner — NOT a CI test. Runs the REAL SummaryPipeline over the
// generated 100-case suite (planted facts + hallucination traps + continuity)
// against a real model via Ollama, and scores each case's rubric.
//
// This is the harness the prompt-optimization loop uses: change prompts.dart,
// re-run, watch the pass rate move.
//
// Run (all cases — SLOW, hours on a 2B):
//   RECAP_OLLAMA_MODEL=gemma4:e2b RECAP_EVAL_CASES=/path/cases.json \
//     flutter test test/summarizer/eval_suite_runner_test.dart --plain-name suite
// Run a subset (fast signal): RECAP_EVAL_FILTER=long  or  RECAP_EVAL_LIMIT=12
// Skipped automatically when RECAP_OLLAMA_MODEL is unset.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recap/billing/persona.dart';
import 'package:recap/services/summarizer/summary_backend.dart';
import 'package:recap/services/summarizer/summary_pipeline.dart';
import 'package:recap/services/summarizer/summary_types.dart';

final _model = Platform.environment['RECAP_OLLAMA_MODEL'] ?? '';
final _casesPath =
    Platform.environment['RECAP_EVAL_CASES'] ??
    'test/summarizer/eval_cases/cases.json';
final _filter = Platform.environment['RECAP_EVAL_FILTER'] ?? ''; // lengthClass
final _limit =
    int.tryParse(Platform.environment['RECAP_EVAL_LIMIT'] ?? '') ?? 0;

void main() {
  HttpOverrides.global = null;

  test(
    'suite: run the eval cases through the real model and score rubrics',
    () async {
      if (_model.isEmpty) {
        markTestSkipped('set RECAP_OLLAMA_MODEL to run the eval suite');
        return;
      }
      final file = File(_casesPath);
      if (!file.existsSync()) {
        markTestSkipped('cases.json not found at $_casesPath');
        return;
      }

      var cases = (jsonDecode(file.readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();
      if (_filter.isNotEmpty) {
        cases = cases.where((c) => c['lengthClass'] == _filter).toList();
      }
      if (_limit > 0 && cases.length > _limit) cases = cases.sublist(0, _limit);

      final backend = _OllamaBackend(model: _model);
      final results = <Map<String, dynamic>>[];

      for (var i = 0; i < cases.length; i++) {
        final c = cases[i];
        final id = c['id'] as String? ?? 'case-$i';
        stderr.writeln(
          '[${i + 1}/${cases.length}] $id '
          '(${c['lengthClass']}, ${c['durationMin']}min)',
        );
        try {
          final segments = _parse(c['transcript'] as String? ?? '');
          if (segments.isEmpty) {
            results.add({'id': id, 'error': 'transcript did not parse'});
            continue;
          }
          final res = await const SummaryPipeline().run(
            backend: backend,
            input: SummaryInput(
              segments: segments,
              meetingTitle: c['title'] as String? ?? id,
              glossary: const [],
            ),
            persona: resolvePersona('basic', const []),
          );
          results.add(_score(id, c, res.text));
        } catch (e) {
          results.add({'id': id, 'error': e.toString()});
        }
      }

      // Aggregate.
      var casesPass = 0;
      final dim = <String, List<int>>{
        'mustContain': [0, 0],
        'mustNotContain': [0, 0],
        'continuity': [0, 0],
        'requiredSections': [0, 0],
        'lowConfidence': [0, 0],
      };
      for (final r in results) {
        if (r['error'] != null) continue;
        if (r['pass'] == true) casesPass++;
        for (final k in dim.keys) {
          final s = (r[k] as List?)?.cast<int>();
          if (s != null) {
            dim[k]![0] += s[0];
            dim[k]![1] += s[1];
          }
        }
      }

      final report = {
        'model': _model,
        'total': results.length,
        'errored': results.where((r) => r['error'] != null).length,
        'casesPassed': casesPass,
        'casesPassRate': results.isEmpty ? 0 : casesPass / results.length,
        'dimensions': {
          for (final e in dim.entries)
            e.key: {'pass': e.value[0], 'of': e.value[1]},
        },
        'results': results,
      };
      final outPath = '${Directory.systemTemp.path}/eval_report_$_model'
          .replaceAll(RegExp(r'[^A-Za-z0-9._/-]'), '_');
      File(
        outPath,
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));

      stderr.writeln('\n==== EVAL SUMMARY ($_model) ====');
      stderr.writeln(
        'cases: $casesPass/${results.length} fully passed '
        '(${results.where((r) => r['error'] != null).length} errored)',
      );
      for (final e in dim.entries) {
        stderr.writeln('  ${e.key}: ${e.value[0]}/${e.value[1]}');
      }
      stderr.writeln('report: $outPath');

      expect(results, isNotEmpty);
    },
    timeout: const Timeout(Duration(hours: 6)),
  );
}

/// Score a summary against a case rubric. Critical dims (mustContain,
/// mustNotContain, continuity) decide pass/fail; sections + lowConfidence are
/// tracked but not gating.
Map<String, dynamic> _score(String id, Map<String, dynamic> c, String summary) {
  final s = summary.toLowerCase();
  final rubric = (c['rubric'] as Map?)?.cast<String, dynamic>() ?? {};

  final failed =
      <String>[]; // "dim:needle" for every miss — the loop reads this

  List<int> checkNeedles(String key, String field, bool wantPresent) {
    final items = (rubric[key] as List?)?.cast<Map<String, dynamic>>() ?? [];
    var pass = 0;
    var fails = 0;
    for (final it in items) {
      final needle = (it[field] as String? ?? '').toLowerCase().trim();
      if (needle.isEmpty) continue;
      final present = _matches(s, needle);
      if (present == wantPresent) {
        pass++;
      } else {
        fails++;
        failed.add('$key:$needle');
      }
    }
    return [pass, items.length, fails];
  }

  final mc = checkNeedles('mustContain', 'needle', true);
  final mnc = checkNeedles('mustNotContain', 'needle', false);
  final cont = checkNeedles('continuity', 'needle', true);

  // required sections
  final secs = (rubric['requiredSections'] as List?)?.cast<String>() ?? [];
  var secPass = 0;
  for (final sec in secs) {
    if (s.contains(sec.toLowerCase().replaceAll('#', '').trim())) secPass++;
  }

  // low confidence: the garbled term should appear AND the doc has a
  // low-confidence section (lenient — we reward flagging, not exact placement).
  final lc =
      (rubric['lowConfidence'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  final hasLcSection = s.contains('low confidence');
  var lcPass = 0;
  for (final it in lc) {
    final term = (it['term'] as String? ?? '').toLowerCase().trim();
    if (term.isEmpty) continue;
    if (hasLcSection && _matches(s, term)) lcPass++;
  }

  final critical = mc[2] == 0 && mnc[2] == 0 && cont[2] == 0;
  return {
    'id': id,
    'lengthClass': c['lengthClass'],
    'pass': critical,
    'mustContain': [mc[0], mc[1]],
    'mustNotContain': [mnc[0], mnc[1]],
    'continuity': [cont[0], cont[1]],
    'requiredSections': [secPass, secs.length],
    'lowConfidence': [lcPass, lc.length],
    // Everything the prompt-optimization loop needs to see WHY a case failed:
    // which planted needle was missed (or which trap was tripped), and the
    // model's actual output.
    'failed': failed,
    'summary': summary,
  };
}

/// A needle matches if it appears as a (case-insensitive) substring, OR as a
/// loose regex when it contains regex metacharacters like alternation.
bool _matches(String haystack, String needle) {
  if (haystack.contains(needle)) return true;
  try {
    return RegExp(needle, caseSensitive: false).hasMatch(haystack);
  } catch (_) {
    return false;
  }
}

List<PromptSegment> _parse(String raw) {
  // A speaker header is a WHOLE line of "<label> (t)" where <label> is a short
  // name (real names like "Nadia"/"Professor", or "Speaker 1") and t is mm:ss,
  // m:ss or h:mm:ss. Anchored end-to-end so a prose line that merely ends in a
  // parenthetical time is not mistaken for a header.
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
      final c = m.group(4); // present => h:mm:ss
      startMs =
          (c != null ? (a * 3600 + b * 60 + int.parse(c)) : (a * 60 + b)) *
          1000;
    } else {
      buf.write(' $line');
    }
  }
  flush();
  return segs;
}

class _OllamaBackend implements SummaryBackend {
  _OllamaBackend({required this.model});
  final String model;

  @override
  String get modelId => 'ollama:$model';

  @override
  BackendCapabilities get capabilities =>
      const BackendCapabilities(contextTokens: 4096, maxOutputTokens: 1024);

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
    final client = HttpClient();
    try {
      final req = await client.postUrl(
        Uri.parse('http://localhost:11434/api/generate'),
      );
      req.headers.contentType = ContentType.json;
      req.add(
        utf8.encode(
          jsonEncode({
            'model': model,
            'prompt': prompt,
            if (system != null && system.trim().isNotEmpty)
              'system': system.trim(),
            'stream': false,
            'think':
                false, // Gemma 4 thinking mode empties the on-device budget.
            'options': {
              'temperature': temperature,
              'num_ctx': 4096,
              'num_predict': maxOutputTokens ?? 1024,
            },
          }),
        ),
      );
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      if (resp.statusCode != 200) {
        throw StateError('Ollama HTTP ${resp.statusCode}: $body');
      }
      return ((jsonDecode(body) as Map<String, dynamic>)['response']
                  as String? ??
              '')
          .trim();
    } finally {
      client.close();
    }
  }
}
