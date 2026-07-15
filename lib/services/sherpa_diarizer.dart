import 'dart:async';
import 'dart:ffi' show nullptr;
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as so;

import 'diarizer.dart';

enum SherpaDiarizerStatus { uninitialized, downloading, ready, failed }

/// Pyannote segmentation-3.0 + WeSpeaker embedding diarizer via sherpa-onnx.
/// Implements the same [Diarizer] interface as [HeuristicDiarizer] so it
/// drops into the existing call site; the recording flow doesn't need to
/// know which backend is running.
///
/// Sherpa's diarization produces its own (start, end, speakerId) tuples for
/// the whole audio. We then map each *transcript* segment (from Whisper) to
/// whichever sherpa speaker segment overlaps it most, so the existing per-
/// transcript-segment Speaker N label shape is preserved.
class SherpaDiarizer extends ChangeNotifier implements Diarizer {
  static const _segmentationArchive =
      'sherpa-onnx-pyannote-segmentation-3-0.tar.bz2';
  static const _segmentationFolder = 'sherpa-onnx-pyannote-segmentation-3-0';
  static const _segmentationFile = 'model.onnx';
  static const _segmentationUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/speaker-segmentation-models/$_segmentationArchive';

  static const _embeddingFile = 'wespeaker_en_voxceleb_resnet34_LM.onnx';
  static const _embeddingUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/speaker-recongition-models/$_embeddingFile';

  /// Below 0.5 → too many speakers, above 0.7 → too few. 0.5 matches the
  /// upstream Dart example default.
  final double clusteringThreshold;
  final Diarizer fallback;

  SherpaDiarizer({this.clusteringThreshold = 0.5, Diarizer? fallback})
    : fallback = fallback ?? HeuristicDiarizer();

  SherpaDiarizerStatus _status = SherpaDiarizerStatus.uninitialized;
  String? _failureReason;
  int _bytesReceived = 0;
  int _bytesTotal = 0;

  SherpaDiarizerStatus get status => _status;
  String? get failureReason => _failureReason;
  int get bytesReceived => _bytesReceived;
  int get bytesTotal => _bytesTotal;
  double? get downloadProgress =>
      _bytesTotal <= 0 ? null : _bytesReceived / _bytesTotal;

  so.OfflineSpeakerDiarization? _sd;

  Future<Directory> get _modelsDir async {
    final docs = await getApplicationSupportDirectory();
    final d = Directory(p.join(docs.path, 'sherpa_diarizer'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<String> get _segmentationPath async =>
      p.join((await _modelsDir).path, _segmentationFolder, _segmentationFile);

  Future<String> get _embeddingPath async =>
      p.join((await _modelsDir).path, _embeddingFile);

  /// True iff both ONNX files are on disk and non-empty.
  Future<bool> get isModelInstalled async {
    final seg = File(await _segmentationPath);
    final emb = File(await _embeddingPath);
    if (!await seg.exists() || !await emb.exists()) return false;
    return (await seg.length()) > 1024 && (await emb.length()) > 1024;
  }

  /// Trigger model download (idempotent). UI calls this from a Settings tile
  /// or auto-triggers after first record. Re-entrant.
  void warmUp() {
    if (_status == SherpaDiarizerStatus.downloading ||
        _status == SherpaDiarizerStatus.ready) {
      return;
    }
    unawaited(_warmUpAsync());
  }

  Future<void> _warmUpAsync() async {
    try {
      if (await isModelInstalled) {
        _setStatus(SherpaDiarizerStatus.ready);
        return;
      }
      _setStatus(SherpaDiarizerStatus.downloading);
      await _ensureSegmentation();
      await _ensureEmbedding();
      _setStatus(SherpaDiarizerStatus.ready);
    } catch (e) {
      _failureReason = e.toString();
      _setStatus(SherpaDiarizerStatus.failed);
    }
  }

  Future<void> _ensureSegmentation() async {
    final destOnnx = File(await _segmentationPath);
    if (await destOnnx.exists() && (await destOnnx.length()) > 1024) return;

    final dir = await _modelsDir;
    final archivePath = p.join(dir.path, _segmentationArchive);
    await _streamDownload(_segmentationUrl, archivePath);

    // Untar .tar.bz2 to the models dir. Sherpa's archive lays out as
    //   sherpa-onnx-pyannote-segmentation-3-0/model.onnx
    final input = InputFileStream(archivePath);
    try {
      final tarBytes = BZip2Decoder().decodeBuffer(input);
      final tar = TarDecoder().decodeBytes(tarBytes);
      for (final entry in tar) {
        if (!entry.isFile) continue;
        final outPath = p.join(dir.path, entry.name);
        await Directory(p.dirname(outPath)).create(recursive: true);
        await File(outPath).writeAsBytes(entry.content as List<int>);
      }
    } finally {
      await input.close();
    }
    try {
      await File(archivePath).delete();
    } catch (_) {
      /* best effort */
    }
  }

  Future<void> _ensureEmbedding() async {
    final dest = File(await _embeddingPath);
    if (await dest.exists() && (await dest.length()) > 1024) return;
    await _streamDownload(_embeddingUrl, dest.path);
  }

  Future<void> _streamDownload(String url, String destPath) async {
    final req = http.Request('GET', Uri.parse(url));
    final res = await http.Client().send(req);
    if (res.statusCode != 200) {
      throw StateError('Download failed: HTTP ${res.statusCode} for $url');
    }
    _bytesReceived = 0;
    _bytesTotal = res.contentLength ?? 0;
    notifyListeners();

    final tmp = File('$destPath.part');
    final sink = tmp.openWrite();
    try {
      await for (final chunk in res.stream) {
        sink.add(chunk);
        _bytesReceived += chunk.length;
        notifyListeners();
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    await tmp.rename(destPath);
  }

  Future<void> _ensureInitialized() async {
    if (_sd != null) return;
    if (!await isModelInstalled) {
      throw StateError(
        'Sherpa diarizer models not installed. Call warmUp() first.',
      );
    }
    final segPath = await _segmentationPath;
    final embPath = await _embeddingPath;
    final config = so.OfflineSpeakerDiarizationConfig(
      segmentation: so.OfflineSpeakerSegmentationModelConfig(
        pyannote: so.OfflineSpeakerSegmentationPyannoteModelConfig(
          model: segPath,
        ),
      ),
      embedding: so.SpeakerEmbeddingExtractorConfig(model: embPath),
      // numClusters = -1 → auto-detect using threshold.
      clustering: so.FastClusteringConfig(
        numClusters: -1,
        threshold: clusteringThreshold,
      ),
      minDurationOn: 0.2,
      minDurationOff: 0.5,
    );
    final sd = so.OfflineSpeakerDiarization(config);
    if (sd.ptr == nullptr) {
      throw StateError('Failed to initialize OfflineSpeakerDiarization.');
    }
    _sd = sd;
  }

  @override
  Future<List<String?>> diarize({
    required String wavPath,
    required List<({int startMs, int endMs})> segments,
  }) async {
    if (segments.isEmpty) return const [];
    try {
      if (!await isModelInstalled) {
        return fallback.diarize(wavPath: wavPath, segments: segments);
      }
      await _ensureInitialized();
      final wave = so.readWave(wavPath);
      if (wave.sampleRate != _sd!.sampleRate) {
        // Whisper output is 16 kHz; this should always match. If not, fall
        // back rather than crash.
        return fallback.diarize(wavPath: wavPath, segments: segments);
      }
      final speakerSegments = _sd!.process(samples: wave.samples);
      return _mapSegmentsToSpeakers(segments, speakerSegments);
    } catch (e) {
      debugPrint('SherpaDiarizer.diarize failed: $e — falling back');
      return fallback.diarize(wavPath: wavPath, segments: segments);
    }
  }

  /// For each transcript segment, find the sherpa-onnx speaker segment(s) that
  /// overlap it; assign the speaker with the greatest overlap.
  List<String?> _mapSegmentsToSpeakers(
    List<({int startMs, int endMs})> transcriptSegments,
    List<so.OfflineSpeakerDiarizationSegment> speakerSegments,
  ) {
    if (speakerSegments.isEmpty) {
      return List<String?>.filled(transcriptSegments.length, 'Speaker 1');
    }
    // Speaker IDs from sherpa are 0-based ints; remap to 1-based stable labels
    // in the order they first appear, so "Speaker 1" is whoever spoke first.
    final firstSeenOrder = <int, int>{};
    for (final s in speakerSegments) {
      firstSeenOrder.putIfAbsent(s.speaker, () => firstSeenOrder.length + 1);
    }

    final out = <String?>[];
    for (final t in transcriptSegments) {
      final overlap = <int, int>{}; // speakerId → total overlap ms
      for (final s in speakerSegments) {
        final sStartMs = (s.start * 1000).round();
        final sEndMs = (s.end * 1000).round();
        final lo = t.startMs > sStartMs ? t.startMs : sStartMs;
        final hi = t.endMs < sEndMs ? t.endMs : sEndMs;
        final ov = hi - lo;
        if (ov > 0) {
          overlap[s.speaker] = (overlap[s.speaker] ?? 0) + ov;
        }
      }
      if (overlap.isEmpty) {
        out.add(null);
        continue;
      }
      final best = overlap.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      out.add('Speaker ${firstSeenOrder[best]}');
    }
    return out;
  }

  void _setStatus(SherpaDiarizerStatus s) {
    _status = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _sd?.free();
    _sd = null;
    super.dispose();
  }
}
