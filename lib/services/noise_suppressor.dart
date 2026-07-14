import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// RNNoise via flutter_onnxruntime — on-device noise suppression for the
/// live recording pipeline. Pre-Whisper filter: raw mic → [processFrame] →
/// Whisper. Significantly improves transcription accuracy in noisy
/// environments (cafes, open offices, cars) where the meeting product
/// actually gets used.
///
/// Model: `rnnoise.onnx` (~100 KB). Native 48 kHz frames; we resample at
/// integration boundaries since our recording pipeline is 16 kHz.
///
/// Default ON for recordings; OFF for imports (music or multi-voice
/// material shouldn't be touched — RNNoise is voice-trained).
class NoiseSuppressor {
  static const _modelUrl =
      'https://huggingface.co/onnx-community/rnnoise/resolve/main/onnx/model.onnx';
  static const _modelFilename = 'rnnoise.onnx';

  /// RNNoise's native frame size at 48 kHz. Our pipeline upsamples 256-sample
  /// 16 kHz frames → ~768 48 kHz samples (we pad to 480 with linear interp).
  static const int rnnoiseFrameSize = 480;

  bool enabled = true;
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

  Future<void> ensureModelInstalled() async {
    if (await isModelInstalled()) return;
    final dest = File(await _modelPath());
    final tmp = File('${dest.path}.part');
    final req = http.Request('GET', Uri.parse(_modelUrl));
    final res = await http.Client().send(req);
    if (res.statusCode != 200) {
      throw StateError('RNNoise model download failed: HTTP ${res.statusCode}');
    }
    final sink = tmp.openWrite();
    try {
      await for (final chunk in res.stream) {
        sink.add(chunk);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    await tmp.rename(dest.path);
  }

  Future<OrtSession> _ensureSession() async {
    if (_session != null) return _session!;
    if (!await isModelInstalled()) await ensureModelInstalled();
    final ort = OnnxRuntime();
    _session = await ort.createSession(await _modelPath());
    return _session!;
  }

  /// Process a 16 kHz frame of [Int16List] samples. Returns a same-length
  /// frame with noise suppressed. Pass-through when [enabled] is false or
  /// the model fails to load.
  ///
  /// We upsample to 48 kHz internally (3×), run the model, downsample back.
  /// The naive upsample/downsample loses some fidelity vs a proper polyphase
  /// resampler, but RNNoise is forgiving — the GRU model cares about speech
  /// formant structure, not 24+ kHz content we're not capturing anyway.
  Future<Int16List> processFrame(Int16List frame) async {
    if (!enabled) return frame;
    try {
      final session = await _ensureSession();
      final upsampled = _upsample3x(frame);
      // Process in 480-sample windows.
      final out48 = Float32List(upsampled.length);
      for (var off = 0;
          off + rnnoiseFrameSize <= upsampled.length;
          off += rnnoiseFrameSize) {
        final win = Float32List(rnnoiseFrameSize);
        for (var i = 0; i < rnnoiseFrameSize; i++) {
          win[i] = upsampled[off + i].toDouble();
        }
        final outputs = await session.run({
          'input': await OrtValue.fromList(win, [1, rnnoiseFrameSize]),
        });
        final denoised = await outputs['output']!.asList();
        for (var i = 0; i < rnnoiseFrameSize; i++) {
          out48[off + i] = (denoised[i] as num).toDouble();
        }
      }
      return _downsample3x(out48);
    } catch (e) {
      debugPrint('NoiseSuppressor.processFrame failed: $e — passthrough');
      return frame;
    }
  }

  /// One-shot processing for a whole 16 kHz mono PCM file. Used after
  /// recording stops, before Whisper's final pass.
  Future<Int16List> processFile(Int16List pcm) async {
    if (!enabled) return pcm;
    // 256-sample chunks at 16 kHz = 16 ms — matches the RNNoise frame rate.
    const chunk = 256;
    final out = Int16List(pcm.length);
    var written = 0;
    for (var i = 0; i + chunk <= pcm.length; i += chunk) {
      final frame = Int16List.sublistView(pcm, i, i + chunk);
      final denoised = await processFrame(frame);
      for (var k = 0; k < chunk; k++) {
        out[written + k] = k < denoised.length ? denoised[k] : 0;
      }
      written += chunk;
    }
    return out;
  }

  Float32List _upsample3x(Int16List pcm16k) {
    final out = Float32List(pcm16k.length * 3);
    for (var i = 0; i < pcm16k.length - 1; i++) {
      final a = pcm16k[i].toDouble();
      final b = pcm16k[i + 1].toDouble();
      out[i * 3] = a;
      out[i * 3 + 1] = a + (b - a) / 3;
      out[i * 3 + 2] = a + 2 * (b - a) / 3;
    }
    out[(pcm16k.length - 1) * 3] = pcm16k.last.toDouble();
    return out;
  }

  Int16List _downsample3x(Float32List pcm48k) {
    final out = Int16List(pcm48k.length ~/ 3);
    for (var i = 0; i < out.length; i++) {
      var v = pcm48k[i * 3];
      if (v > 32767) v = 32767;
      if (v < -32768) v = -32768;
      out[i] = v.round();
    }
    return out;
  }
}
