// Live on-device fidelity harness — NOT a CI test.
//
// Runs the REAL SummaryPipeline (real prompts, real chunker, real map-reduce +
// critic) with a backend whose window is pinned to Gemma 4 E2B's exact budget
// (4096 context / 1024 output), driven by a genuine ~2B model via a local
// Ollama daemon. This replaces the frontier-model SIMULATION the July 2026
// eval used with an actual small model, which is the one thing that simulation
// could not tell us: whether a 2B can follow the 9-heading map contract and
// stay faithful.
//
// Fidelity caveats (this is a mild UPPER bound on true on-device quality):
//   * Ollama quantization (Q4_K) differs from flutter_gemma's LiteRT int4/int8.
//   * Desktop M-series GPU is stronger than a phone NPU, but quality (not speed)
//     is what we measure, and num_ctx is pinned to 4096 to match the phone's
//     real combined window — the model gets NO more context than the handset.
//   * gemma3n:e2b is the direct predecessor of gemma-4-e2b-it (same effective-2B
//     on-device class); Gemma 4 should be equal or better.
//
// Run:
//   RECAP_OLLAMA_MODEL=gemma3n:e2b flutter test test/summarizer/gemma_live_eval_test.dart --plain-name live
// Skipped automatically when RECAP_OLLAMA_MODEL is unset (so CI never hits it).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recap/billing/persona.dart';
import 'package:recap/services/summarizer/summary_backend.dart';
import 'package:recap/services/summarizer/summary_pipeline.dart';
import 'package:recap/services/summarizer/summary_types.dart';

final _model = Platform.environment['RECAP_OLLAMA_MODEL'] ?? '';

void main() {
  // Allow real localhost sockets — flutter_test stubs HttpClient by default.
  HttpOverrides.global = null;

  test(
      'live: Gemma-E2B-class model runs the real pipeline on the ASR transcript',
      () async {
    if (_model.isEmpty) {
      markTestSkipped(
          'set RECAP_OLLAMA_MODEL=gemma3n:e2b to run the live eval');
      return;
    }

    final transcriptPath = Platform.environment['RECAP_TRANSCRIPT'] ??
        '/private/tmp/claude-501/-Users-saichetangrandhe-recap/'
            '3dfee06c-6205-4ccb-a4bc-1eddaa11a041/scratchpad/transcript.txt';
    final segments = _parseTranscript(File(transcriptPath).readAsStringSync());
    expect(segments, isNotEmpty, reason: 'transcript did not parse');

    // The honest glossary for THIS meeting: only the acronyms the shipped
    // case-sensitive HeuristicEntityExtractor would actually catch. "skin apps"
    // -> Scan Apps is deliberately NOT here — the polish agent flagged it as
    // unreachable, so rule-1 repair must work from context alone. Testing with a
    // fat hand-authored glossary would flatter the result.
    final input = SummaryInput(
      segments: segments,
      meetingTitle: 'Scan Apps promo-ID tracking',
      glossary: const ['APT', 'JBP', 'RGM'],
    );

    final backend = _OllamaGemmaBackend(model: _model);
    final result = await const SummaryPipeline().run(
      backend: backend,
      input: input,
      persona: resolvePersona('basic', const []),
      onProgress: (p) => stderr.writeln(
          '  [${p.stage.name}] ${p.step}/${p.totalSteps} — ${p.label}'),
    );

    // Dump everything for inspection.
    final out = StringBuffer()
      ..writeln('\n${'=' * 78}')
      ..writeln(
          'MODEL: ${result.modelId}   (${backend.calls.length} generate calls, '
          '${result.processingTime.inSeconds}s total)')
      ..writeln(
          'CHUNKS: ${backend.calls.where((c) => c.tag == 'map').length} map / '
          '${backend.calls.where((c) => c.tag == 'reduce').length} reduce / '
          '${backend.calls.where((c) => c.tag == 'critic').length} critic')
      ..writeln('=' * 78);

    for (var i = 0; i < backend.calls.length; i++) {
      final c = backend.calls[i];
      out
        ..writeln('\n----- CALL ${i + 1}: ${c.tag.toUpperCase()} '
            '(temp ${c.temperature}, ~${c.promptTokens} prompt tok) -----')
        ..writeln('>>> RESPONSE:\n${c.response}');
    }
    out
      ..writeln('\n${'#' * 78}')
      ..writeln('# FINAL SUMMARY (what the user sees)')
      ..writeln('#' * 78)
      ..writeln(result.text);

    // Write to a file too — test stdout gets truncated.
    File('${Directory.systemTemp.path}/gemma_eval_output.md')
        .writeAsStringSync(out.toString());
    // ignore: avoid_print
    print(out.toString());

    expect(result.text.trim(), isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 30)));
}

/// Parses "Speaker N (mm:ss)\n text" blocks into PromptSegments. Mirrors what
/// buildPromptSegments would yield after diarization — one turn per block.
List<PromptSegment> _parseTranscript(String raw) {
  final re = RegExp(r'^(Speaker \d+)\s*\((\d+):(\d+)\)\s*$');
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
      speaker = m.group(1);
      startMs = (int.parse(m.group(2)!) * 60 + int.parse(m.group(3)!)) * 1000;
    } else {
      buf.write(' $line');
    }
  }
  flush();
  return segs;
}

class _Call {
  final String tag;
  final double temperature;
  final int promptTokens;
  final String response;
  _Call(this.tag, this.temperature, this.promptTokens, this.response);
}

/// A SummaryBackend that advertises Gemma 4 E2B's EXACT window (so the pipeline
/// chunks identically to the phone) but generates with a real local model.
class _OllamaGemmaBackend implements SummaryBackend {
  _OllamaGemmaBackend({required this.model});
  final String model;
  final calls = <_Call>[];

  @override
  String get modelId => 'ollama:$model (pinned to gemma-4-e2b window)';

  // Default to Gemma 4 E2B's phone window (forces the chunked map-reduce path).
  // Override via RECAP_CTX_TOKENS to model a bigger backend — e.g. the desktop
  // Ollama tier, where a 27B runs single-pass with a large window (one call, not
  // ten), which is BOTH how it would really run and fast enough to not time out.
  @override
  BackendCapabilities get capabilities => BackendCapabilities(
        contextTokens:
            int.tryParse(Platform.environment['RECAP_CTX_TOKENS'] ?? '') ??
                4096,
        maxOutputTokens:
            int.tryParse(Platform.environment['RECAP_MAX_OUT'] ?? '') ?? 1024,
      );

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
    // Infer stage for the log from the real prompt text.
    final tag = prompt.contains('DRAFT')
        ? 'critic'
        : (prompt.contains('Extract structured notes') ||
                prompt.contains('SEGMENT'))
            ? 'map'
            : prompt.startsWith('Condense')
                ? 'fold'
                : 'reduce';

    final client = HttpClient();
    try {
      final req = await client
          .postUrl(Uri.parse('http://localhost:11434/api/generate'));
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(jsonEncode({
        'model': model,
        'prompt': prompt,
        if (system != null && system.trim().isNotEmpty) 'system': system.trim(),
        'stream': false,
        // Gemma 4 is a THINKING model. Left on, it spends the entire ~1024-token
        // on-device output budget reasoning and never emits a final answer — the
        // response comes back EMPTY and the pipeline sees "extracted nothing".
        // A phone cannot afford a thinking budget on top of the answer, so the
        // real on-device config disables it; this mirrors that.
        'think': false,
        'options': {
          'temperature': temperature,
          // Match the advertised window (see capabilities): 4096 pins the phone's
          // combined budget; a RECAP_CTX_TOKENS override models a bigger backend.
          'num_ctx':
              int.tryParse(Platform.environment['RECAP_CTX_TOKENS'] ?? '') ??
                  4096,
          'num_predict': maxOutputTokens ?? capabilities.maxOutputTokens,
        },
      })));
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      if (resp.statusCode != 200) {
        throw StateError('Ollama HTTP ${resp.statusCode}: $body');
      }
      final text =
          ((jsonDecode(body) as Map<String, dynamic>)['response'] as String? ??
                  '')
              .trim();
      calls.add(_Call(tag, temperature, (prompt.length / 3.6).ceil(), text));
      return text;
    } finally {
      client.close();
    }
  }
}
