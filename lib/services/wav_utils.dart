import 'dart:io';
import 'dart:typed_data';

/// Helpers for assembling WAV files. The recorder writes one WAV per
/// pause/resume segment; on Transcribe we merge them into a single WAV
/// before feeding to Whisper.
class WavUtils {
  /// Bytes 0..43 of a standard 16-bit PCM WAV file are the canonical header.
  static const int headerBytes = 44;

  /// Concatenate the PCM bodies of [inputPaths] into a single WAV at
  /// [outputPath]. **Streaming**: copies through a fixed [copyBufferBytes]
  /// buffer (default 64 KB) instead of materializing each input in memory.
  /// Keeps peak memory near constant regardless of recording length.
  ///
  /// All inputs must share the same sample format (true for everything
  /// RecorderService writes — 16 kHz mono 16-bit PCM).
  ///
  /// If [inputPaths] has only one entry, the file is copied as-is.
  /// Returns [outputPath].
  static Future<String> mergeWavs({
    required List<String> inputPaths,
    required String outputPath,
    int copyBufferBytes = 64 * 1024,
  }) async {
    if (inputPaths.isEmpty) {
      throw ArgumentError('mergeWavs called with empty inputPaths');
    }
    if (inputPaths.length == 1) {
      final src = File(inputPaths.first);
      if (!await src.exists()) {
        throw StateError('mergeWavs: source not found ${inputPaths.first}');
      }
      await src.copy(outputPath);
      return outputPath;
    }

    // Find the first existing input — we'll use its header as the template
    // for the merged file.
    Uint8List? headerTemplate;
    for (final p in inputPaths) {
      final f = File(p);
      if (!await f.exists()) continue;
      final raf = await f.open();
      try {
        if (await raf.length() >= headerBytes) {
          headerTemplate =
              Uint8List.fromList(await raf.read(headerBytes));
          break;
        }
      } finally {
        await raf.close();
      }
    }
    if (headerTemplate == null) {
      throw StateError('mergeWavs: no usable input files');
    }

    final out = File(outputPath);
    if (await out.exists()) await out.delete();
    final outRaf = await out.open(mode: FileMode.write);
    try {
      // Reserve 44 bytes — we'll come back and patch the size fields once
      // we know the total PCM length.
      await outRaf.writeFrom(headerTemplate);

      final buffer = Uint8List(copyBufferBytes);
      var totalPcmBytes = 0;
      for (final p in inputPaths) {
        final f = File(p);
        if (!await f.exists()) continue;
        final inRaf = await f.open();
        try {
          final len = await inRaf.length();
          if (len <= headerBytes) continue;
          await inRaf.setPosition(headerBytes);
          var remaining = len - headerBytes;
          while (remaining > 0) {
            final want = remaining < buffer.length ? remaining : buffer.length;
            final read = await inRaf.readInto(buffer, 0, want);
            if (read <= 0) break;
            await outRaf.writeFrom(buffer, 0, read);
            totalPcmBytes += read;
            remaining -= read;
          }
        } finally {
          await inRaf.close();
        }
      }

      // Patch RIFF size (bytes 4..7) + data chunk size (bytes 40..43).
      final patch = Uint8List(4);
      await outRaf.setPosition(4);
      _writeU32(patch, 0, 36 + totalPcmBytes);
      await outRaf.writeFrom(patch);

      await outRaf.setPosition(40);
      _writeU32(patch, 0, totalPcmBytes);
      await outRaf.writeFrom(patch);
    } finally {
      await outRaf.close();
    }
    return outputPath;
  }

  /// Total duration in milliseconds across all WAV chunks (16 kHz mono 16-bit).
  static Future<int> totalDurationMs(List<String> inputPaths) async {
    var pcmBytes = 0;
    for (final p in inputPaths) {
      final f = File(p);
      if (!await f.exists()) continue;
      final len = await f.length();
      if (len > headerBytes) pcmBytes += len - headerBytes;
    }
    return (pcmBytes * 1000) ~/ 32000;
  }

  static void _writeU32(Uint8List buf, int offset, int value) {
    buf[offset] = value & 0xff;
    buf[offset + 1] = (value >> 8) & 0xff;
    buf[offset + 2] = (value >> 16) & 0xff;
    buf[offset + 3] = (value >> 24) & 0xff;
  }
}
