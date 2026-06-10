import 'dart:async';

/// Wake word detection (D7 — "Hey Recap, bookmark this"). Pro+ feature.
///
/// **Engine choice (decision in plan):** start with Picovoice Porcupine via
/// `porcupine_flutter`. Validate Porcupine's licensing model fits Recap's
/// lifetime-no-subscription positioning before final ship; fall back to a
/// custom ONNX KWS (~20 MB trained on "Hey Recap" data) if Porcupine's
/// per-MAU costs are incompatible.
///
/// **Commands (v1):**
///   - "Hey Recap, bookmark this" → drop a timestamped bookmark
///   - "Hey Recap, new section" → insert a chapter break marker
///
/// **Privacy-tier behavior:** Porcupine binary is closed-source — fails the
/// verifiable-no-network audit. Either use the ONNX KWS path on Privacy
/// tier, or hide the wake-word feature entirely on Privacy.
enum WakeWordCommand { bookmark, newSection }

abstract class WakeWordService {
  Stream<WakeWordCommand> get detections;
  Future<bool> isAvailable();
  Future<void> start();
  Future<void> stop();
}

/// Default no-op implementation — exists so the recording flow can wire to
/// a WakeWordService without crashing on platforms where Porcupine isn't
/// installed yet or the user hasn't enabled the feature.
class NullWakeWordService implements WakeWordService {
  final _controller = StreamController<WakeWordCommand>.broadcast();
  @override
  Stream<WakeWordCommand> get detections => _controller.stream;
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
}
