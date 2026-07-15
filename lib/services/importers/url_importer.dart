import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'audio_converter.dart';
import 'import_pipeline.dart';

/// Direct URL → temp file → ffmpeg → 16 kHz mono WAV. Refuses HTML
/// (paywalled / login redirects) so users get a clear "this isn't a media
/// URL" error instead of a corrupted file.
class UrlImporter {
  /// [url] should point at a publicly-fetchable audio/video file (no auth).
  /// Returns null on user-visible content-type rejection so the UI can show
  /// a clear error; throws on network / conversion failures.
  static Future<ImportedAudio?> importFromUrl(
    String url, {
    void Function(double)? onProgress,
  }) async {
    final uri = Uri.parse(url);
    final req = http.Request('GET', uri);
    final res = await http.Client().send(req);
    if (res.statusCode != 200) {
      throw StateError('HTTP ${res.statusCode} fetching $url');
    }
    final type = res.headers['content-type'] ?? '';
    if (type.startsWith('text/html')) {
      // Avoid downloading a login page or paywall HTML.
      return null;
    }

    final docs = await getApplicationSupportDirectory();
    final dir = Directory(p.join(docs.path, 'imports'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final ext = _guessExtension(uri.path, type);
    final tmp = File(p.join(dir.path, '${const Uuid().v4()}$ext'));
    final sink = tmp.openWrite();
    final total = res.contentLength ?? 0;
    var got = 0;
    try {
      await for (final chunk in res.stream) {
        sink.add(chunk);
        got += chunk.length;
        if (total > 0 && onProgress != null) {
          onProgress(got / total);
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    final wavPath = await AudioConverter.convertToWhisperWav(tmp.path);
    final durMs = await AudioConverter.probeDurationMs(wavPath);
    try {
      await tmp.delete();
    } catch (_) {
      /* best effort */
    }

    final title = p.basenameWithoutExtension(uri.path).replaceAll('_', ' ');
    return ImportedAudio(
      wavPath: wavPath,
      duration: Duration(milliseconds: durMs),
      title: title.isEmpty ? 'Imported from URL' : title,
      sourceDate: DateTime.now(),
    );
  }

  static String _guessExtension(String path, String contentType) {
    final lower = path.toLowerCase();
    const exts = [
      '.mp3',
      '.m4a',
      '.aac',
      '.wav',
      '.opus',
      '.ogg',
      '.flac',
      '.mp4',
      '.mov',
      '.mkv',
      '.webm',
      '.aiff',
      '.amr',
    ];
    for (final e in exts) {
      if (lower.endsWith(e)) return e;
    }
    if (contentType.contains('mpeg')) return '.mp3';
    if (contentType.contains('mp4')) return '.mp4';
    if (contentType.contains('webm')) return '.webm';
    if (contentType.contains('ogg')) return '.ogg';
    return '.bin';
  }
}
