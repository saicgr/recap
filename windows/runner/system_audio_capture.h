// Windows system-audio loopback capture via WASAPI.
//
// Implements the `recap.system_audio` MethodChannel + events channel from
// lib/services/system_audio_capture.dart. Uses IMMDevice → IAudioClient with
// AUDCLNT_STREAMFLAGS_LOOPBACK to capture whatever is currently playing on
// the default render device (Zoom, Meet, Teams audio mixed with everything
// else the user is hearing).
//
// Output: 16 kHz mono 16-bit PCM WAV written to the path provided by Dart.
// Resampling lives here (input is typically 48 kHz stereo from the render
// device).

#pragma once

#include <flutter/binary_messenger.h>
#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/event_sink.h>

#include <memory>
#include <thread>
#include <atomic>
#include <string>

class SystemAudioCapture {
public:
    explicit SystemAudioCapture(flutter::BinaryMessenger* messenger);
    ~SystemAudioCapture();

    void Register();

private:
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> method_channel_;
    std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;

    std::thread capture_thread_;
    std::atomic<bool> running_{false};
    std::string output_wav_path_;

    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue>& call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    bool CheckAvailable();
    bool StartCapture(const std::string& wav_path);
    void StopCapture();
    void CaptureLoop();
};
