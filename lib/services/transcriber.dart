import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

/// Wraps whisper_ggml. Manages model lifecycle: knows whether the GGML model
/// file is on disk, can trigger a streaming background download (with
/// progress in bytes), and reports status changes to the UI.
///
/// Default model is `tiny.en` (~75 MB). Settings → Transcription lets the
/// user upgrade to `base.en` (~140 MB) or `small.en` (~466 MB).
enum TranscriberStatus { uninitialized, downloading, ready, failed }

class TranscriberService extends ChangeNotifier {
  final WhisperController _whisper = WhisperController();
  // Default model — Free tier ceiling. Resolved per-tier at boot in main.dart
  // by calling [setModel] with the right `WhisperModel` for the current tier
  // (base.en for Free, small.en for Pro+). Live captions use a separate tiny
  // model via [LiveCaptionsService] for the every-5s streaming chunks.
  WhisperModel _model = WhisperModel.baseEn;

  TranscriberStatus _status = TranscriberStatus.uninitialized;
  String? _failureReason;
  int _bytesReceived = 0;
  int _bytesTotal = 0;

  TranscriberStatus get status => _status;
  String? get failureReason => _failureReason;
  int get bytesReceived => _bytesReceived;
  int get bytesTotal => _bytesTotal;

  /// 0..1 if total is known; null if total is unknown (rare).
  double? get downloadProgress {
    if (_bytesTotal <= 0) return null;
    return _bytesReceived / _bytesTotal;
  }

  WhisperModel get model => _model;

  /// Does the model file exist on disk?
  Future<bool> get isModelInstalled async {
    try {
      final path = await _whisper.getPath(_model);
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Kick off the model download in the background. Re-entrant; no-op if
  /// already downloading or ready.
  void warmUp() {
    if (_status == TranscriberStatus.downloading ||
        _status == TranscriberStatus.ready) {
      return;
    }
    unawaited(_warmUpAsync());
  }

  Future<void> _warmUpAsync() async {
    try {
      if (await isModelInstalled) {
        _setStatus(TranscriberStatus.ready);
        return;
      }
      _bytesReceived = 0;
      _bytesTotal = 0;
      _setStatus(TranscriberStatus.downloading);
      await _streamDownload(_model);
      _setStatus(TranscriberStatus.ready);
    } catch (e) {
      _failureReason = e.toString();
      _setStatus(TranscriberStatus.failed);
    }
  }

  /// Stream the GGML model from HuggingFace, writing bytes to disk as they
  /// arrive. Updates [_bytesReceived] / [_bytesTotal] continuously so the
  /// UI can render a real progress bar instead of a spinner.
  Future<void> _streamDownload(WhisperModel m) async {
    final destPath = await _whisper.getPath(m);
    final dest = File(destPath);
    // Make sure the parent dir exists (whisper_ggml usually handles this, but
    // be defensive — first-launch on a fresh install can hit a missing dir).
    if (!await dest.parent.exists()) {
      await dest.parent.create(recursive: true);
    }
    // Tmp file → rename at end. Avoids leaving a half-downloaded model that
    // looks installed but is actually truncated.
    final tmp = File('$destPath.part');
    if (await tmp.exists()) await tmp.delete();

    final client = HttpClient();
    try {
      final request = await client.getUrl(m.modelUri);
      final response = await request.close();
      if (response.statusCode != 200) {
        throw StateError(
          'Model download HTTP ${response.statusCode} for ${m.modelUri}',
        );
      }
      _bytesTotal = response.contentLength;
      notifyListeners();

      final sink = tmp.openWrite();
      var lastEmitted = 0;
      await for (final chunk in response) {
        sink.add(chunk);
        _bytesReceived += chunk.length;
        // Throttle UI updates to ~10/sec (every ~50 KB) so we don't melt
        // the render thread on a fast connection.
        if (_bytesReceived - lastEmitted > 50 * 1024) {
          lastEmitted = _bytesReceived;
          notifyListeners();
        }
      }
      await sink.close();
      await tmp.rename(destPath);
      notifyListeners();
    } finally {
      client.close();
    }
  }

  /// Switch model and re-download if needed. Used by Settings → Model picker.
  Future<void> setModel(WhisperModel m) async {
    if (_model == m) return;
    _model = m;
    _status = TranscriberStatus.uninitialized;
    _bytesReceived = 0;
    _bytesTotal = 0;
    notifyListeners();
    await _warmUpAsync();
  }

  /// Transcribe a WAV file. Throws if model isn't installed yet.
  Future<String> transcribe(String wavPath, {String lang = 'en'}) async {
    if (!await isModelInstalled) {
      throw StateError(
        'Whisper model not installed. Wait for status == ready (or call warmUp() first).',
      );
    }
    final result = await _whisper.transcribe(
      model: _model,
      audioPath: wavPath,
      lang: lang,
    );
    final text = result?.transcription.text.trim();
    if (text == null || text.isEmpty) {
      throw StateError('Whisper produced empty transcript for $wavPath');
    }
    return text;
  }

  void _setStatus(TranscriberStatus s) {
    _status = s;
    notifyListeners();
  }
}
