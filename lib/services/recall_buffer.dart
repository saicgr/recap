import 'dart:typed_data';

/// Instant Recall (D14.7) — continuous 30s ring buffer of mic audio kept in
/// RAM. User taps "Save the last 30 seconds" to promote it to a real
/// meeting + continue recording live from that point.
///
/// **Privacy:** Recording without an active session needs an explicit
/// opt-in toggle + a persistent indicator (top-of-screen pill). Per
/// jurisdiction this may still be one-party consent — document clearly in
/// the toggle's disclosure.
///
/// **Tier gating:** Pro+ feature. Off by default.
class RecallBuffer {
  /// Maximum buffer duration. Configurable in Settings → Recall (15s / 30s
  /// / 60s / 2min). Default 30s.
  final int maxDurationMs;

  /// PCM sample rate the recorder feeds us. Always 16 kHz mono in Recap.
  final int sampleRate;

  /// 16 kHz mono int16 samples, oldest first.
  final List<Int16List> _frames = [];
  int _bufferedMs = 0;
  bool _enabled = false;

  RecallBuffer({this.maxDurationMs = 30000, this.sampleRate = 16000});

  bool get enabled => _enabled;
  int get bufferedMs => _bufferedMs;

  void enable() {
    _enabled = true;
  }

  void disable() {
    _enabled = false;
    _frames.clear();
    _bufferedMs = 0;
  }

  /// Push a frame from the live mic stream. Drops oldest frames when the
  /// buffer overflows so memory stays bounded.
  void pushFrame(Int16List frame) {
    if (!_enabled) return;
    _frames.add(frame);
    _bufferedMs += (frame.length * 1000 ~/ sampleRate);
    while (_bufferedMs > maxDurationMs && _frames.isNotEmpty) {
      final dropped = _frames.removeAt(0);
      _bufferedMs -= (dropped.length * 1000 ~/ sampleRate);
    }
  }

  /// Snapshot the current buffer as a contiguous PCM block. Caller writes
  /// to a WAV file and promotes to a real meeting.
  Int16List snapshot() {
    final total = _frames.fold<int>(0, (sum, f) => sum + f.length);
    final out = Int16List(total);
    var offset = 0;
    for (final f in _frames) {
      out.setRange(offset, offset + f.length, f);
      offset += f.length;
    }
    return out;
  }

  void clear() {
    _frames.clear();
    _bufferedMs = 0;
  }
}
