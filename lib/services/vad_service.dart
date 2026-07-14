import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Silero VAD via flutter_onnxruntime (D15.2 / PR 4).
///
/// Model: `silero_vad.onnx` (~1.6 MB), 16 kHz mono, 512-sample frames (32 ms).
/// The model is stateful — it carries hidden state across calls within one
/// utterance — but in v1 we run it as a one-shot scan and reset between
/// files. Streaming usage shares the same OrtSession but resets the hidden
/// tensors between segments.
///
/// **Why this exists:**
///   1. Pre-trim silence before Whisper — faster transcription, fewer
///      hallucinated tokens on empty audio (the "Whisper says random words
///      during silence" failure mode).
///   2. Gate the live-caption chunker — Whisper only fires when speech is
///      actually present in the last 5s window. Significant battery + perceived
///      latency win, especially on Free tier where the model is heavier.
class VadService {
  static const _modelUrl =
      'https://huggingface.co/onnx-community/silero-vad/resolve/main/onnx/model.onnx';
  static const _modelFilename = 'silero_vad.onnx';

  /// Model expects 16 kHz audio in 512-sample (32 ms) chunks.
  static const int sampleRate = 16000;
  static const int windowSize = 512;

  OrtSession? _session;

  Future<String> _modelPath() async {
    final docs = await getApplicationSupportDirectory();
    final dir = Directory(p.join(docs.path, 'onnx_models'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return p.join(dir.path, _modelFilename);
  }

  Future<bool> isModelInstalled() async {
    final f = File(await _modelPath());
    return await f.exists() && (await f.length()) > 1024;
  }

  /// Trigger one-time model download. ~1.6 MB so we can do it without
  /// pre-download disclosure dialogs. Mirror of TranscriberService /
  /// SherpaDiarizer / GemmaDownloader patterns — see those for parallelism.
  Future<void> ensureModelInstalled({
    void Function(double)? onProgress,
  }) async {
    if (await isModelInstalled()) return;
    final dest = File(await _modelPath());
    final tmp = File('${dest.path}.part');
    final req = http.Request('GET', Uri.parse(_modelUrl));
    final res = await http.Client().send(req);
    if (res.statusCode != 200) {
      throw StateError('VAD model download failed: HTTP ${res.statusCode}');
    }
    final total = res.contentLength ?? 0;
    var got = 0;
    final sink = tmp.openWrite();
    try {
      await for (final chunk in res.stream) {
        sink.add(chunk);
        got += chunk.length;
        if (total > 0 && onProgress != null) onProgress(got / total);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    await tmp.rename(dest.path);
  }

  Future<OrtSession> _ensureSession() async {
    if (_session != null) return _session!;
    if (!await isModelInstalled()) {
      await ensureModelInstalled();
    }
    final ort = OnnxRuntime();
    _session = await ort.createSession(await _modelPath());
    return _session!;
  }

  /// Run VAD over a 16 kHz mono PCM16 WAV file. Returns continuous segments
  /// where the model emitted a probability above [threshold]. Empty list if
  /// the file is pure silence.
  Future<List<({int startMs, int endMs})>> detectSpeechSegments(
    String wavPath, {
    double threshold = 0.5,
    int minSilenceMs = 300,
    int minSpeechMs = 250,
  }) async {
    final samples = await _readWavMono16(wavPath);
    if (samples.isEmpty) return const [];
    return _detectInFrames(samples,
        threshold: threshold,
        minSilenceMs: minSilenceMs,
        minSpeechMs: minSpeechMs);
  }

  Future<List<({int startMs, int endMs})>> _detectInFrames(
    Int16List samples, {
    required double threshold,
    required int minSilenceMs,
    required int minSpeechMs,
  }) async {
    final session = await _ensureSession();
    // Silero VAD inputs:
    //   input  — [1, windowSize] float32 PCM (-1..1)
    //   sr     — [1] int64 sample rate (16000)
    //   state  — [2, 1, 128] float32 hidden state (zero-init per utterance)
    var state = Float32List(2 * 1 * 128);

    final probs = <double>[];
    final frameBuf = Float32List(windowSize);
    for (var i = 0; i + windowSize <= samples.length; i += windowSize) {
      for (var k = 0; k < windowSize; k++) {
        frameBuf[k] = samples[i + k] / 32768.0;
      }
      final inputs = {
        'input': await OrtValue.fromList(frameBuf, [1, windowSize]),
        'sr': await OrtValue.fromList(Int64List.fromList([sampleRate]), [1]),
        'state': await OrtValue.fromList(state, [2, 1, 128]),
      };
      try {
        final outputs = await session.run(inputs);
        final probList = await outputs['output']!.asList();
        probs.add((probList.first as num).toDouble());
        final newState = await outputs['stateN']!.asList();
        // Re-pack flattened state into a fresh Float32List for the next call.
        state = Float32List.fromList(
            newState.cast<num>().map((n) => n.toDouble()).toList());
      } catch (e) {
        // Per-frame failure — model schema mismatch with this Silero ONNX
        // variant (output names differ between v4 / v5 dumps). Fall back to
        // "speech everywhere" so downstream Whisper still runs.
        debugPrint('VAD frame inference failed: $e');
        final start = (i * 1000 / sampleRate).round();
        final end = (samples.length * 1000 / sampleRate).round();
        return [(startMs: start, endMs: end)];
      }
    }
    return _probsToSegments(probs,
        threshold: threshold,
        minSilenceMs: minSilenceMs,
        minSpeechMs: minSpeechMs);
  }

  /// Convert per-frame probabilities into [(startMs, endMs)] segments.
  /// State machine: in_silence / in_speech, with hysteresis sized by
  /// [minSilenceMs] + [minSpeechMs] to avoid clipping word boundaries.
  List<({int startMs, int endMs})> _probsToSegments(
    List<double> probs, {
    required double threshold,
    required int minSilenceMs,
    required int minSpeechMs,
  }) {
    const frameMs = 1000 * windowSize / sampleRate;
    final minSilenceFrames = (minSilenceMs / frameMs).ceil();
    final minSpeechFrames = (minSpeechMs / frameMs).ceil();

    final segments = <({int startMs, int endMs})>[];
    int? speechStart;
    int silenceRun = 0;
    int speechRun = 0;

    for (var i = 0; i < probs.length; i++) {
      final isSpeech = probs[i] >= threshold;
      if (isSpeech) {
        speechStart ??= i;
        speechRun++;
        silenceRun = 0;
      } else {
        if (speechStart != null) {
          silenceRun++;
          if (silenceRun >= minSilenceFrames) {
            if (speechRun >= minSpeechFrames) {
              segments.add((
                startMs: (speechStart * frameMs).round(),
                endMs: ((i - silenceRun) * frameMs).round(),
              ));
            }
            speechStart = null;
            speechRun = 0;
            silenceRun = 0;
          }
        }
      }
    }
    // Close out a final speech run that runs to the end of the file.
    if (speechStart != null && speechRun >= minSpeechFrames) {
      segments.add((
        startMs: (speechStart * frameMs).round(),
        endMs: (probs.length * frameMs).round(),
      ));
    }
    return segments;
  }

  /// Streaming variant for live captions. Caller feeds 32 ms PCM frames
  /// (512 samples at 16 kHz mono); emits true while speech is present.
  /// LiveCaptionsService gates Whisper inference on this output.
  Stream<bool> isSpeechStream(Stream<Int16List> pcm16,
      {double threshold = 0.5}) async* {
    final session = await _ensureSession();
    var state = Float32List(2 * 1 * 128);
    final frameBuf = Float32List(windowSize);
    await for (final frame in pcm16) {
      if (frame.length < windowSize) {
        yield false;
        continue;
      }
      for (var k = 0; k < windowSize; k++) {
        frameBuf[k] = frame[k] / 32768.0;
      }
      try {
        final outputs = await session.run({
          'input': await OrtValue.fromList(frameBuf, [1, windowSize]),
          'sr': await OrtValue.fromList(Int64List.fromList([sampleRate]), [1]),
          'state': await OrtValue.fromList(state, [2, 1, 128]),
        });
        final probList = await outputs['output']!.asList();
        final newState = await outputs['stateN']!.asList();
        state = Float32List.fromList(
            newState.cast<num>().map((n) => n.toDouble()).toList());
        yield (probList.first as num).toDouble() >= threshold;
      } catch (_) {
        yield true; // graceful: assume speech when VAD fails
      }
    }
  }

  /// Parse a 16 kHz mono 16-bit PCM WAV file into an Int16List. Skips the
  /// 44-byte canonical RIFF/WAVE header (matches WavUtils elsewhere in the
  /// codebase + the format produced by AudioConverter.convertToWhisperWav).
  Future<Int16List> _readWavMono16(String wavPath) async {
    final file = File(wavPath);
    if (!await file.exists()) return Int16List(0);
    final bytes = await file.readAsBytes();
    if (bytes.length <= 44) return Int16List(0);
    final pcm = bytes.sublist(44);
    return Int16List.view(
      pcm.buffer,
      pcm.offsetInBytes,
      pcm.length ~/ 2,
    );
  }
}
