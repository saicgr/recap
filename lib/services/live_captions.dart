import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'transcriber.dart';

/// Drives chunked Whisper inference during recording. Every [chunkInterval]
/// the service reads the latest segment of the in-progress WAV, transcribes
/// it, and emits a [LiveCaption] event.
///
/// IMPORTANT: this reads the live WAV file the recorder is writing into.
/// Whisper itself runs in an isolate per call so it doesn't block the UI.
class LiveCaption {
  final int startMs;
  final int endMs;
  final String text;
  final bool isFinal;
  const LiveCaption({
    required this.startMs,
    required this.endMs,
    required this.text,
    required this.isFinal,
  });
}

class LiveCaptionsService {
  LiveCaptionsService({required this.transcriber});

  final TranscriberService transcriber;

  /// 5s chunks balance "feels live" with "doesn't melt the phone." On older
  /// Android we may need to push this to 8-10s.
  Duration chunkInterval = const Duration(seconds: 5);

  final _controller = StreamController<LiveCaption>.broadcast();
  Stream<LiveCaption> get captions => _controller.stream;

  Timer? _timer;
  String? _sourceWavPath;
  DateTime? _recordingStart;
  int _lastChunkEndMs = 0;
  bool _running = false;

  /// Start emitting captions from the WAV file being written by RecorderService.
  Future<void> start({required String sourceWavPath}) async {
    if (_running) return;
    _sourceWavPath = sourceWavPath;
    _recordingStart = DateTime.now();
    _lastChunkEndMs = 0;
    _running = true;
    _timer = Timer.periodic(chunkInterval, (_) => _emitNextChunk());
  }

  Future<void> stop() async {
    _running = false;
    _timer?.cancel();
    _timer = null;
    // Emit a final partial chunk for whatever's left.
    await _emitNextChunk(finalChunk: true);
  }

  Future<void> _emitNextChunk({bool finalChunk = false}) async {
    if (_sourceWavPath == null || _recordingStart == null) return;
    // Don't even attempt transcription if the model isn't downloaded — the
    // native whisper.cpp call segfaults instead of returning a clean error.
    if (!await transcriber.isModelInstalled) return;

    final now = DateTime.now();
    final endMs = now.difference(_recordingStart!).inMilliseconds;
    if (endMs <= _lastChunkEndMs && !finalChunk) return;

    final chunkPath = await _writeChunk(_lastChunkEndMs, endMs);
    if (chunkPath == null) return;

    try {
      final text = await transcriber.transcribe(chunkPath);
      _controller.add(
        LiveCaption(
          startMs: _lastChunkEndMs,
          endMs: endMs,
          text: text,
          isFinal: finalChunk,
        ),
      );
      _lastChunkEndMs = endMs;
    } catch (_) {
      // Don't crash live captions on a single failed chunk — the final
      // post-record transcription will produce a clean transcript anyway.
    } finally {
      await File(chunkPath).delete().catchError((_) => File(chunkPath));
    }
  }

  /// Extract bytes [startMs, endMs] from the live WAV into a temp file.
  /// Assumes 16 kHz mono 16-bit PCM (what RecorderService writes).
  Future<String?> _writeChunk(int startMs, int endMs) async {
    final src = File(_sourceWavPath!);
    if (!await src.exists()) return null;

    final bytes = await src.readAsBytes();
    if (bytes.length < 44) return null; // need WAV header

    const sampleRate = 16000;
    const bytesPerSample = 2; // 16-bit mono
    final startByte = 44 + (startMs * sampleRate * bytesPerSample) ~/ 1000;
    final endByte = 44 + (endMs * sampleRate * bytesPerSample) ~/ 1000;
    if (startByte >= bytes.length) return null;
    final clampedEnd = endByte > bytes.length ? bytes.length : endByte;

    final pcm = bytes.sublist(startByte, clampedEnd);
    final wav = _wrapWav(pcm, sampleRate);

    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'recap_chunk_${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    await File(path).writeAsBytes(wav, flush: true);
    return path;
  }

  /// Wrap raw PCM with a minimal 16 kHz mono 16-bit WAV header so
  /// whisper_ggml can consume the chunk standalone.
  Uint8List _wrapWav(Uint8List pcm, int sampleRate) {
    final byteRate = sampleRate * 2;
    final dataLen = pcm.length;
    final fileLen = 36 + dataLen;

    final header = BytesBuilder()
      ..add('RIFF'.codeUnits)
      ..add(_u32(fileLen))
      ..add('WAVE'.codeUnits)
      ..add('fmt '.codeUnits)
      ..add(_u32(16)) // PCM chunk size
      ..add(_u16(1)) // PCM format
      ..add(_u16(1)) // mono
      ..add(_u32(sampleRate))
      ..add(_u32(byteRate))
      ..add(_u16(2)) // block align (mono * 16-bit)
      ..add(_u16(16)) // bits per sample
      ..add('data'.codeUnits)
      ..add(_u32(dataLen))
      ..add(pcm);
    return header.toBytes();
  }

  Uint8List _u32(int v) => Uint8List(4)
    ..[0] = v & 0xff
    ..[1] = (v >> 8) & 0xff
    ..[2] = (v >> 16) & 0xff
    ..[3] = (v >> 24) & 0xff;

  Uint8List _u16(int v) => Uint8List(2)
    ..[0] = v & 0xff
    ..[1] = (v >> 8) & 0xff;

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
