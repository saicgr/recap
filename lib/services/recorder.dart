import 'package:record/record.dart';

class RecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> ensurePermission() => _recorder.hasPermission();

  Future<void> start(String path) async {
    if (!await ensurePermission()) {
      throw StateError('Microphone permission denied');
    }
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
  }

  Future<String?> stop() => _recorder.stop();

  Future<void> pause() => _recorder.pause();

  Future<void> resume() => _recorder.resume();

  Future<bool> isRecording() => _recorder.isRecording();

  Future<bool> isPaused() => _recorder.isPaused();

  Stream<Amplitude> onAmplitudeChanged(Duration interval) =>
      _recorder.onAmplitudeChanged(interval);

  Future<void> dispose() => _recorder.dispose();
}
