import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import 'audio_converter.dart';
import 'import_pipeline.dart';

/// File / gallery import via the system picker. Supports a wide format set;
/// downstream [AudioConverter] funnels everything to 16 kHz mono WAV.
class FileImporter {
  static const _allowed = [
    // Audio
    'mp3', 'm4a', 'aac', 'wav', 'opus', 'ogg', 'flac', 'wma',
    'aiff', 'aif', 'amr', 'ac3', 'eac3',
    // Video (audio track will be stripped)
    'mp4', 'mov', 'mkv', 'webm', 'avi', 'flv', '3gp', 'wmv',
  ];

  /// Returns null if user cancels; otherwise an ImportedAudio ready for
  /// [persistImportedMeeting] + the normal transcribe pipeline.
  static Future<ImportedAudio?> pickAndConvert() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowed,
      allowMultiple: false,
      withData: false,
    );
    if (res == null || res.files.isEmpty) return null;
    final picked = res.files.single;
    final path = picked.path;
    if (path == null) return null;

    final wavPath = await AudioConverter.convertToWhisperWav(path);
    final durMs = await AudioConverter.probeDurationMs(wavPath);
    final basename = p.basenameWithoutExtension(picked.name);
    return ImportedAudio(
      wavPath: wavPath,
      duration: Duration(milliseconds: durMs),
      title: basename.isEmpty ? 'Imported audio' : basename,
      sourceDate: DateTime.now(),
    );
  }
}
