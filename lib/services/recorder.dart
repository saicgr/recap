import 'package:record/record.dart';

import 'audio/mic_policy.dart';

class RecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  /// The input actually used for the current/last recording, and why.
  MicChoice? _lastChoice;
  MicChoice? get lastChoice => _lastChoice;

  Future<bool> ensurePermission() => _recorder.hasPermission();

  /// Inputs the platform will let us record from.
  ///
  /// Returns empty on failure rather than throwing — a mic picker that cannot
  /// enumerate is a degraded picker, not a broken recording.
  Future<List<InputDevice>> listInputs() async {
    try {
      return await _recorder.listInputDevices();
    } catch (_) {
      return const [];
    }
  }

  /// Start recording to [path].
  ///
  /// [pinnedDeviceId] is the user's explicit choice from Settings, if any.
  Future<MicChoice> start(String path, {String? pinnedDeviceId}) async {
    if (!await ensurePermission()) {
      throw StateError('Microphone permission denied');
    }

    final choice = MicPolicy.choose(
      await listInputs(),
      pinnedId: pinnedDeviceId,
    );
    _lastChoice = choice;

    await _recorder.start(_config(choice.device), path: path);
    return choice;
  }

  /// The configuration that defeats the Bluetooth hijack.
  ///
  /// -- THE BUG ---------------------------------------------------------------
  /// `record`'s DEFAULTS cause it. Verified in the package source
  /// (record_platform_interface/lib/src/types/):
  ///
  ///   iOS      categoryOptions = [defaultToSpeaker, allowBluetooth,
  ///                               allowBluetoothA2DP]
  ///   Android  manageBluetooth = true
  ///
  /// `allowBluetooth` is the Hands-Free Profile switch, and `manageBluetooth`
  /// starts Bluetooth SCO. Either one drags the whole capture route down to
  /// 8-16 kHz narrowband mono the moment a headset is connected. The recording
  /// still "works" — it is just quietly, dramatically worse, and Whisper's
  /// accuracy falls off a cliff. Every recording made with AirPods connected has
  /// been narrowband.
  ///
  /// -- THE FIX ---------------------------------------------------------------
  /// iOS:     drop `allowBluetooth`, KEEP `allowBluetoothA2DP`. A2DP is the
  ///          PLAYBACK profile — the user's AirPods keep playing audio in full
  ///          quality. We simply refuse to capture through their microphone.
  /// Android: `manageBluetooth: false`, so the plugin never starts SCO, and pass
  ///          the chosen device explicitly.
  ///
  /// The two platforms need opposite-LOOKING settings for the same outcome, so
  /// this reads like an inconsistency and is not. Do not "tidy" it: putting
  /// `allowBluetooth` back, or letting `manageBluetooth` default to true,
  /// silently reintroduces narrowband capture — with no error, and no test
  /// failure.
  RecordConfig _config(InputDevice? device) => RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: 16000,
    numChannels: 1,
    device: device,
    // Let the mic be the mic. AGC/NS pump and gate quiet speakers, which is
    // exactly the audio Whisper already struggles with.
    autoGain: false,
    echoCancel: false,
    noiseSuppress: false,
    iosConfig: const IosRecordConfig(
      categoryOptions: [
        IosAudioCategoryOption.defaultToSpeaker,
        // allowBluetooth DELIBERATELY OMITTED — see above.
        IosAudioCategoryOption.allowBluetoothA2DP,
      ],
    ),
    androidConfig: const AndroidRecordConfig(
      manageBluetooth: false,
      // voiceRecognition is tuned for ASR and skips the aggressive
      // call-oriented processing that mic/voiceCommunication apply.
      audioSource: AndroidAudioSource.voiceRecognition,
    ),
  );

  Future<String?> stop() => _recorder.stop();

  Future<void> pause() => _recorder.pause();

  Future<void> resume() => _recorder.resume();

  Future<bool> isRecording() => _recorder.isRecording();

  Future<bool> isPaused() => _recorder.isPaused();

  Stream<Amplitude> onAmplitudeChanged(Duration interval) =>
      _recorder.onAmplitudeChanged(interval);

  Future<void> dispose() => _recorder.dispose();
}
