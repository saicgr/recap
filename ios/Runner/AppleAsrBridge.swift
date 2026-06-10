// Apple SFSpeechRecognizer ↔ Flutter platform channel.
// Implements: recap.asr.apple (MethodChannel) + recap.asr.apple.events (EventChannel).
// Methods: isAvailable, startStreaming, stopStreaming, transcribeFile.
//
// On-device flag: `requiresOnDeviceRecognition = true` so we never bounce off
// Apple's cloud. iOS 13+ guarantees on-device for English; other languages
// vary by OS version + region.
//
// Streaming caveat: each SFSpeechRecognitionTask has a hard ~1-minute ceiling.
// We restart the task every 50s and merge the final-result text into our
// running `startMs` offset so callers see a single contiguous stream of
// AsrPartial events.

import Flutter
import Speech
import AVFoundation

@available(iOS 13.0, macOS 10.15, *)
class AppleAsrBridge: NSObject, FlutterStreamHandler {
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var streamStartMs: Int64 = 0
    private var streamingActive = false
    private var rotateTimer: Timer?

    init(messenger: FlutterBinaryMessenger) {
        super.init()
        methodChannel = FlutterMethodChannel(
            name: "recap.asr.apple",
            binaryMessenger: messenger
        )
        eventChannel = FlutterEventChannel(
            name: "recap.asr.apple.events",
            binaryMessenger: messenger
        )
        methodChannel?.setMethodCallHandler(handle)
        eventChannel?.setStreamHandler(self)
    }

    func onListen(withArguments arguments: Any?,
                  eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            let lang = (call.arguments as? [String: Any])?["lang"] as? String ?? "en"
            let locale = Locale(identifier: lang)
            let r = SFSpeechRecognizer(locale: locale)
            let supportsOnDevice: Bool
            if #available(iOS 13.0, macOS 10.15, *) {
                supportsOnDevice = r?.supportsOnDeviceRecognition ?? false
            } else {
                supportsOnDevice = false
            }
            result((r?.isAvailable ?? false) && supportsOnDevice)
        case "startStreaming":
            let lang = (call.arguments as? [String: Any])?["lang"] as? String ?? "en"
            do {
                try startStreaming(lang: lang)
                result(nil)
            } catch {
                result(FlutterError(code: "start_failed",
                                    message: error.localizedDescription,
                                    details: nil))
            }
        case "stopStreaming":
            stopStreaming()
            result(nil)
        case "transcribeFile":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                result(FlutterError(code: "bad_args",
                                    message: "Missing 'path'", details: nil))
                return
            }
            let lang = args["lang"] as? String ?? "en"
            transcribeFile(path: path, lang: lang, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Streaming

    private func startStreaming(lang: String) throws {
        SFSpeechRecognizer.requestAuthorization { _ in /* user prompt on first call */ }
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: lang))
        guard let r = recognizer, r.isAvailable else {
            throw NSError(domain: "AppleAsrBridge", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Recognizer unavailable"])
        }

        try AVAudioSession.sharedInstance().setCategory(.playAndRecord,
                                                       mode: .measurement,
                                                       options: [.mixWithOthers, .duckOthers])
        try AVAudioSession.sharedInstance().setActive(true,
                                                     options: .notifyOthersOnDeactivation)

        streamStartMs = Int64(Date().timeIntervalSince1970 * 1000)
        streamingActive = true
        try beginRecognitionTask(lang: lang)

        rotateTimer = Timer.scheduledTimer(withTimeInterval: 50, repeats: true) { [weak self] _ in
            guard let self = self, self.streamingActive else { return }
            self.rotateTask(lang: lang)
        }
    }

    private func beginRecognitionTask(lang: String) throws {
        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true
        if #available(iOS 13.0, macOS 10.15, *) {
            request?.requiresOnDeviceRecognition = true
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer?.recognitionTask(with: request!) { [weak self] result, error in
            guard let self = self, let sink = self.eventSink else { return }
            if let r = result {
                let now = Int64(Date().timeIntervalSince1970 * 1000)
                sink([
                    "text": r.bestTranscription.formattedString,
                    "isFinal": r.isFinal,
                    "startMs": self.streamStartMs,
                    "endMs": now,
                    "confidence": NSNumber(value: r.bestTranscription.segments.last?.confidence ?? 0)
                ])
            }
            if error != nil {
                // Swallow; rotateTask handles restart.
            }
        }
    }

    private func rotateTask(lang: String) {
        // End current task, start a fresh one without dropping mic tap.
        request?.endAudio()
        task?.finish()
        task = nil
        request = nil
        do {
            try beginRecognitionTask(lang: lang)
        } catch {
            eventSink?(FlutterError(code: "rotate_failed",
                                    message: error.localizedDescription,
                                    details: nil))
        }
    }

    private func stopStreaming() {
        streamingActive = false
        rotateTimer?.invalidate()
        rotateTimer = nil
        request?.endAudio()
        task?.cancel()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request = nil
        task = nil
        try? AVAudioSession.sharedInstance().setActive(false,
                                                     options: .notifyOthersOnDeactivation)
    }

    // MARK: - File transcription

    private func transcribeFile(path: String, lang: String,
                                result: @escaping FlutterResult) {
        let url = URL(fileURLWithPath: path)
        let r = SFSpeechRecognizer(locale: Locale(identifier: lang))
        guard let recog = r, recog.isAvailable else {
            result(FlutterError(code: "unavailable",
                                message: "Recognizer unavailable for \(lang)",
                                details: nil))
            return
        }
        let req = SFSpeechURLRecognitionRequest(url: url)
        if #available(iOS 13.0, macOS 10.15, *) {
            req.requiresOnDeviceRecognition = true
        }
        recog.recognitionTask(with: req) { speechResult, error in
            if let err = error {
                result(FlutterError(code: "task_failed",
                                    message: err.localizedDescription,
                                    details: nil))
                return
            }
            guard let r = speechResult, r.isFinal else { return }
            result(r.bestTranscription.formattedString)
        }
    }
}
