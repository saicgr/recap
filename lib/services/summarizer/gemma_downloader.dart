import 'dart:async';

import 'package:flutter/foundation.dart';

import 'gemma_backend.dart';

enum GemmaDownloadStatus {
  unknown,
  notInstalled,
  downloading,
  installed,
  failed,
}

/// ChangeNotifier wrapper around [GemmaBackend] for the UI. Tracks install
/// state + download progress so a Settings tile / transcript empty-state card
/// can show "Downloading 42%" without each caller threading state by hand.
///
/// The model URL is configurable so users with their own self-hosted Gemma
/// LiteRT `.task` file can point Recap at it; default URL points to the
/// official Hugging Face Gemma 4 E2B-IT LiteRT release (HF license + token
/// may be required — the [failureReason] surfaces that).
class GemmaDownloader extends ChangeNotifier {
  GemmaDownloader({required this.backend, required this.modelUrl});

  final GemmaBackend backend;
  String modelUrl;

  GemmaDownloadStatus _status = GemmaDownloadStatus.unknown;
  String? _failureReason;
  double _progress = 0;

  GemmaDownloadStatus get status => _status;
  String? get failureReason => _failureReason;
  double get progress => _progress;

  /// Probe install state. Idempotent; safe to call from initState. Delegates to
  /// the backend so there is one source of truth for "is a model active".
  Future<void> refreshStatus() async {
    try {
      final installed = await backend.isAvailable();
      _setStatus(
        installed
            ? GemmaDownloadStatus.installed
            : GemmaDownloadStatus.notInstalled,
      );
    } catch (e) {
      _failureReason = e.toString();
      _setStatus(GemmaDownloadStatus.failed);
    }
  }

  void updateUrl(String url) {
    modelUrl = url;
    notifyListeners();
  }

  /// Trigger the download. Re-entrant; no-op if already downloading or
  /// already installed.
  void warmUp() {
    if (_status == GemmaDownloadStatus.downloading ||
        _status == GemmaDownloadStatus.installed) {
      return;
    }
    unawaited(_downloadAsync());
  }

  Future<void> _downloadAsync() async {
    if (modelUrl.isEmpty) {
      _failureReason =
          'Set a model URL first (Settings → Summaries → Model URL).';
      _setStatus(GemmaDownloadStatus.failed);
      return;
    }
    try {
      _progress = 0;
      _failureReason = null;
      _setStatus(GemmaDownloadStatus.downloading);
      await backend.download(
        modelUrl: modelUrl,
        onProgress: (p) {
          _progress = p;
          notifyListeners();
        },
      );
      _setStatus(GemmaDownloadStatus.installed);
    } catch (e) {
      _failureReason = e.toString();
      _setStatus(GemmaDownloadStatus.failed);
    }
  }

  Future<void> delete() async {
    try {
      await backend.delete();
      _progress = 0;
      _setStatus(GemmaDownloadStatus.notInstalled);
    } catch (e) {
      _failureReason = e.toString();
      _setStatus(GemmaDownloadStatus.failed);
    }
  }

  void _setStatus(GemmaDownloadStatus s) {
    _status = s;
    notifyListeners();
  }
}
