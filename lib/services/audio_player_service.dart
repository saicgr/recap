import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Thin ChangeNotifier wrapper over [AudioPlayer]. The transcript screen
/// listens to this and (a) seeks on segment tap, (b) highlights the segment
/// containing the current playhead position.
///
/// One instance per [TranscriptScreen]; the screen owns + disposes.
class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  String? _loadedPath;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  double _speed = 1.0;
  String? _failureReason;

  late final StreamSubscription<Duration> _posSub;
  late final StreamSubscription<Duration?> _durSub;
  late final StreamSubscription<PlayerState> _stateSub;

  AudioPlayerService() {
    _posSub = _player.positionStream.listen((p) {
      _position = p;
      notifyListeners();
    });
    _durSub = _player.durationStream.listen((d) {
      _duration = d ?? Duration.zero;
      notifyListeners();
    });
    _stateSub = _player.playerStateStream.listen((s) {
      _isPlaying = s.playing;
      notifyListeners();
    });
  }

  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  double get speed => _speed;
  String? get failureReason => _failureReason;
  bool get hasSource => _loadedPath != null;

  Future<void> loadFile(String path) async {
    try {
      _failureReason = null;
      if (_loadedPath == path) return;
      final f = File(path);
      if (!await f.exists()) {
        throw StateError('Audio file not found: $path');
      }
      await _player.setFilePath(path);
      _loadedPath = path;
      notifyListeners();
    } catch (e) {
      _failureReason = e.toString();
      notifyListeners();
    }
  }

  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      _failureReason = e.toString();
      notifyListeners();
    }
  }

  Future<void> pause() async => _player.pause();

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration d) async {
    final clamped = d < Duration.zero
        ? Duration.zero
        : (_duration > Duration.zero && d > _duration ? _duration : d);
    await _player.seek(clamped);
  }

  Future<void> seekMs(int ms) => seek(Duration(milliseconds: ms));

  /// Cycle 1x → 1.5x → 2x → 1x. Persists across pauses but not across
  /// loadFile() calls.
  Future<void> cycleSpeed() async {
    _speed = switch (_speed) {
      1.0 => 1.5,
      1.5 => 2.0,
      _ => 1.0,
    };
    await _player.setSpeed(_speed);
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await _posSub.cancel();
    await _durSub.cancel();
    await _stateSub.cancel();
    await _player.dispose();
    super.dispose();
  }
}
