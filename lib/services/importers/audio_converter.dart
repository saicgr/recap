import 'dart:io';

// `ffmpeg_kit_flutter_new_min` is a transitive dep via whisper_ggml — see
// pubspec.yaml for the explanation of why we don't redeclare it directly.
// ignore_for_file: depend_on_referenced_packages
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Convert any audio / video file to 16 kHz mono 16-bit PCM WAV — the format
/// Whisper expects internally. Audio track is stripped from video sources;
/// stereo is downmixed; any sample rate / codec is resampled.
class AudioConverter {
  /// Returns the output WAV path on success; throws [StateError] on failure.
  static Future<String> convertToWhisperWav(String inputPath) async {
    final docs = await getApplicationSupportDirectory();
    final dir = Directory(p.join(docs.path, 'recordings'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final outPath = p.join(dir.path, '${const Uuid().v4()}.wav');

    // -y overwrite, -i input, -vn no video, -ac 1 mono, -ar 16000 sample rate,
    // -acodec pcm_s16le 16-bit PCM little-endian.
    final cmd =
        '-y -i "$inputPath" -vn -ac 1 -ar 16000 -acodec pcm_s16le "$outPath"';
    final session = await FFmpegKit.execute(cmd);
    final rc = await session.getReturnCode();
    if (!ReturnCode.isSuccess(rc)) {
      final logs = await session.getAllLogsAsString();
      throw StateError(
        'ffmpeg conversion failed (rc=$rc): ${(logs ?? '').trim()}',
      );
    }
    return outPath;
  }

  /// Returns duration in milliseconds via ffprobe, or 0 if unknown.
  static Future<int> probeDurationMs(String path) async {
    final session = await FFprobeKit.getMediaInformation(path);
    final info = session.getMediaInformation();
    if (info == null) return 0;
    final durStr = info.getDuration();
    if (durStr == null) return 0;
    final secs = double.tryParse(durStr);
    if (secs == null) return 0;
    return (secs * 1000).round();
  }
}
