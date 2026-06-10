import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies models bundled as Flutter assets to app-private storage on first
/// launch so native code (whisper.cpp) can mmap them by file path. This is
/// the D15.1 instant-start primitive — `assets/models/ggml-tiny.en.bin` ships
/// inside the IPA/APK and is copied out exactly once.
///
/// Idempotent: re-running on subsequent launches is a single existsSync()
/// check + return.
class BundledModels {
  /// Asset path → on-disk filename mapping. Add more bundled models here as
  /// we expand the instant-start surface (e.g. a Pyannote-segmentation
  /// minimum model could ship for speaker labels on first launch too).
  static const _bundles = <String, String>{
    'assets/models/ggml-tiny.en.bin': 'ggml-tiny.en.bin',
  };

  /// Ensure every bundled model is present on disk under
  /// `<docs>/bundled_models/`. Returns a map of {asset_path → on-disk path}
  /// for successfully extracted models. Skips silently if the asset isn't
  /// present in this build (CI may not have run fetch_bundled_models.sh).
  static Future<Map<String, String>> ensureAll() async {
    final docs = await getApplicationSupportDirectory();
    final outDir =
        Directory(p.join(docs.path, 'bundled_models'));
    if (!await outDir.exists()) await outDir.create(recursive: true);

    final out = <String, String>{};
    for (final entry in _bundles.entries) {
      final destPath = p.join(outDir.path, entry.value);
      final destFile = File(destPath);
      if (await destFile.exists() && await destFile.length() > 1024) {
        out[entry.key] = destPath;
        continue;
      }
      try {
        final data = await rootBundle.load(entry.key);
        final bytes = data.buffer.asUint8List(
            data.offsetInBytes, data.lengthInBytes);
        await destFile.writeAsBytes(bytes, flush: true);
        out[entry.key] = destPath;
      } catch (e) {
        // Asset wasn't bundled in this build (CI didn't run the fetch
        // script, or this is a dev build). The TranscriberService falls back
        // to the download path; no fatal error.
        debugPrint(
            'BundledModels: ${entry.key} not in this build ($e). '
            'Whisper will download on first record.');
      }
    }
    return out;
  }

  /// Convenience: returns the on-disk path of the bundled tiny.en model if
  /// extracted, else null.
  static Future<String?> tinyEnPath() async {
    final map = await ensureAll();
    return map['assets/models/ggml-tiny.en.bin'];
  }
}
