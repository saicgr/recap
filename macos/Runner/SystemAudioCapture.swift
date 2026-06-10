// System audio capture for macOS via ScreenCaptureKit.
//
// Implements the `recap.system_audio` MethodChannel + `recap.system_audio.events`
// EventChannel from lib/services/system_audio_capture.dart.
//
// ScreenCaptureKit (macOS 13 Sonoma+) gives us system-audio loopback WITHOUT
// requiring a virtual audio driver. Prior to Sonoma you'd need BlackHole or
// similar; we just refuse-with-message on older macOS versions.
//
// Output: 16 kHz mono 16-bit PCM WAV file at the path passed in by Dart.
// Resampling + downmix happens here in Swift via AVAudioConverter.

import Cocoa
import FlutterMacOS
import ScreenCaptureKit
import AVFoundation

@available(macOS 13.0, *)
class SystemAudioCapture: NSObject, FlutterStreamHandler, SCStreamDelegate, SCStreamOutput {
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    private var stream: SCStream?
    private var converter: AVAudioConverter?
    private var wavFile: AVAudioFile?
    private var targetFormat: AVAudioFormat?

    init(messenger: FlutterBinaryMessenger) {
        super.init()
        methodChannel = FlutterMethodChannel(
            name: "recap.system_audio",
            binaryMessenger: messenger
        )
        eventChannel = FlutterEventChannel(
            name: "recap.system_audio.events",
            binaryMessenger: messenger
        )
        methodChannel?.setMethodCallHandler { [weak self] call, result in
            self?.handle(call: call, result: result)
        }
        eventChannel?.setStreamHandler(self)
    }

    func onListen(withArguments arguments: Any?,
                  eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            Task {
                let ok = await checkAvailability()
                result(ok)
            }
        case "startCapture":
            guard let args = call.arguments as? [String: Any?],
                  let wavPath = args["wavPath"] as? String else {
                result(FlutterError(code: "bad_args",
                                    message: "Missing wavPath", details: nil))
                return
            }
            let bundleId = args["appBundleId"] as? String
            Task {
                do {
                    try await startCapture(wavPath: wavPath, bundleId: bundleId)
                    result(nil)
                } catch {
                    result(FlutterError(code: "start_failed",
                                        message: error.localizedDescription,
                                        details: nil))
                }
            }
        case "stopCapture":
            Task {
                await stopCapture()
                result(nil)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func checkAvailability() async -> Bool {
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false,
                                                                    onScreenWindowsOnly: true)
            return true
        } catch {
            return false
        }
    }

    private func startCapture(wavPath: String, bundleId: String?) async throws {
        // Get shareable content; filter by bundleId if provided.
        let content = try await SCShareableContent.excludingDesktopWindows(false,
                                                                            onScreenWindowsOnly: true)
        let filter: SCContentFilter
        if let bundleId = bundleId,
           let app = content.applications.first(where: { $0.bundleIdentifier == bundleId }) {
            filter = SCContentFilter(display: content.displays.first!,
                                     including: [app],
                                     exceptingWindows: [])
        } else {
            // Default: capture entire system audio. We still need a display in
            // the filter; pick the main one. Audio-only stream doesn't render
            // video.
            filter = SCContentFilter(display: content.displays.first!,
                                     excludingApplications: [],
                                     exceptingWindows: [])
        }

        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.sampleRate = 16000
        config.channelCount = 1
        config.excludesCurrentProcessAudio = true
        // Minimal video frame settings — we don't use video but the API
        // requires they be set.
        config.width = 2
        config.height = 2
        config.minimumFrameInterval = CMTime(value: 1, timescale: 1)

        // Prepare WAV writer.
        let outURL = URL(fileURLWithPath: wavPath)
        let outFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                      sampleRate: 16000,
                                      channels: 1,
                                      interleaved: true)!
        wavFile = try AVAudioFile(forWriting: outURL,
                                  settings: outFormat.settings,
                                  commonFormat: .pcmFormatInt16,
                                  interleaved: true)
        targetFormat = outFormat

        let s = SCStream(filter: filter, configuration: config, delegate: self)
        try s.addStreamOutput(self, type: .audio, sampleHandlerQueue: .global(qos: .userInitiated))
        try await s.startCapture()
        stream = s
    }

    private func stopCapture() async {
        if let s = stream {
            try? await s.stopCapture()
        }
        stream = nil
        wavFile = nil
        converter = nil
        targetFormat = nil
    }

    // MARK: - SCStreamOutput

    func stream(_ stream: SCStream,
                didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
                of type: SCStreamOutputType) {
        guard type == .audio,
              let target = targetFormat,
              let wav = wavFile else { return }

        // Convert CMSampleBuffer → AVAudioPCMBuffer (incoming) → resampled
        // AVAudioPCMBuffer (16 kHz mono int16) → file.
        guard let pcm = sampleBuffer.asPcmBuffer() else { return }

        if converter == nil {
            converter = AVAudioConverter(from: pcm.format, to: target)
        }
        guard let conv = converter else { return }

        let ratio = target.sampleRate / pcm.format.sampleRate
        let outFrames = AVAudioFrameCount(Double(pcm.frameLength) * ratio + 256)
        guard let outBuf = AVAudioPCMBuffer(pcmFormat: target,
                                            frameCapacity: outFrames) else { return }

        var error: NSError?
        var supplied = false
        conv.convert(to: outBuf, error: &error) { _, status in
            if supplied {
                status.pointee = .noDataNow
                return nil
            }
            supplied = true
            status.pointee = .haveData
            return pcm
        }
        if error == nil {
            do {
                try wav.write(from: outBuf)
            } catch { /* swallow per-frame errors */ }
            emitLevel(outBuf)
        }
    }

    private func emitLevel(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.int16ChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        var sumSquares: Double = 0
        for i in 0..<frameCount {
            let s = Double(channelData[i]) / 32768.0
            sumSquares += s * s
        }
        let rms = sqrt(sumSquares / Double(max(1, frameCount)))
        DispatchQueue.main.async { self.eventSink?(rms) }
    }
}

@available(macOS 13.0, *)
private extension CMSampleBuffer {
    func asPcmBuffer() -> AVAudioPCMBuffer? {
        guard let formatDesc = CMSampleBufferGetFormatDescription(self),
              let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc)?.pointee
        else { return nil }
        let format = AVAudioFormat(streamDescription: withUnsafePointer(to: asbd) { $0 })
        guard let fmt = format else { return nil }
        let frameCount = AVAudioFrameCount(CMSampleBufferGetNumSamples(self))
        guard let pcm = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: frameCount) else {
            return nil
        }
        pcm.frameLength = frameCount
        do {
            try CMSampleBufferCopyPCMDataIntoAudioBufferList(
                self, at: 0, frameCount: Int32(frameCount),
                into: pcm.mutableAudioBufferList
            )
        } catch {
            return nil
        }
        return pcm
    }
}
