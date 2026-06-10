// WASAPI loopback capture implementation. Captures the default render
// endpoint (whatever's playing through the speakers/headphones), resamples
// to 16 kHz mono 16-bit PCM, writes to a WAV file. RMS-per-buffer emitted
// to Flutter for UI meter.
//
// This is a scaffold — the WASAPI loop is implemented at a high level; full
// production-ready error handling (device-change notifications, format-
// negotiation fallback, glitch detection) gets added when we wire this into
// the desktop recording flow in PR 41.

#include "system_audio_capture.h"

#include <flutter/encodable_value.h>
#include <flutter/method_call.h>

#include <windows.h>
#include <mmdeviceapi.h>
#include <audioclient.h>
#include <combaseapi.h>
#include <functiondiscoverykeys_devpkey.h>

#include <fstream>
#include <vector>
#include <cmath>

namespace {

void WriteWavHeader(std::ofstream& out, uint32_t pcm_bytes) {
    // Minimal RIFF/WAVE header for 16 kHz mono 16-bit PCM.
    const uint32_t sample_rate = 16000;
    const uint16_t channels = 1;
    const uint16_t bits_per_sample = 16;
    const uint32_t byte_rate = sample_rate * channels * bits_per_sample / 8;
    const uint16_t block_align = channels * bits_per_sample / 8;
    const uint32_t chunk_size = pcm_bytes + 36;

    out.write("RIFF", 4);
    out.write(reinterpret_cast<const char*>(&chunk_size), 4);
    out.write("WAVE", 4);
    out.write("fmt ", 4);
    const uint32_t fmt_size = 16;
    out.write(reinterpret_cast<const char*>(&fmt_size), 4);
    const uint16_t pcm_format = 1; // PCM
    out.write(reinterpret_cast<const char*>(&pcm_format), 2);
    out.write(reinterpret_cast<const char*>(&channels), 2);
    out.write(reinterpret_cast<const char*>(&sample_rate), 4);
    out.write(reinterpret_cast<const char*>(&byte_rate), 4);
    out.write(reinterpret_cast<const char*>(&block_align), 2);
    out.write(reinterpret_cast<const char*>(&bits_per_sample), 2);
    out.write("data", 4);
    out.write(reinterpret_cast<const char*>(&pcm_bytes), 4);
}

} // namespace

SystemAudioCapture::SystemAudioCapture(flutter::BinaryMessenger* messenger) {
    method_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        messenger, "recap.system_audio",
        &flutter::StandardMethodCodec::GetInstance()
    );
    event_channel_ = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
        messenger, "recap.system_audio.events",
        &flutter::StandardMethodCodec::GetInstance()
    );
    method_channel_->SetMethodCallHandler(
        [this](const auto& call, auto result) {
            HandleMethodCall(call, std::move(result));
        }
    );
    auto handler = std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
        [this](const auto*, auto&& events)
            -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            event_sink_ = std::move(events);
            return nullptr;
        },
        [this](const auto*) -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            event_sink_.reset();
            return nullptr;
        }
    );
    event_channel_->SetStreamHandler(std::move(handler));
}

SystemAudioCapture::~SystemAudioCapture() {
    StopCapture();
}

void SystemAudioCapture::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const auto& method = call.method_name();
    if (method == "isAvailable") {
        result->Success(flutter::EncodableValue(CheckAvailable()));
    } else if (method == "startCapture") {
        const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
        if (!args) { result->Error("bad_args", "Missing arguments"); return; }
        auto it = args->find(flutter::EncodableValue("wavPath"));
        if (it == args->end()) { result->Error("bad_args", "Missing wavPath"); return; }
        const auto* path = std::get_if<std::string>(&it->second);
        if (!path) { result->Error("bad_args", "wavPath not a string"); return; }
        if (StartCapture(*path)) {
            result->Success();
        } else {
            result->Error("start_failed", "Failed to start WASAPI loopback capture");
        }
    } else if (method == "stopCapture") {
        StopCapture();
        result->Success();
    } else {
        result->NotImplemented();
    }
}

bool SystemAudioCapture::CheckAvailable() {
    // WASAPI is available on every Windows ≥ Vista, which is below our
    // supported floor. We could test by enumerating endpoints; for now,
    // optimistically return true.
    return true;
}

bool SystemAudioCapture::StartCapture(const std::string& wav_path) {
    if (running_.load()) return false;
    output_wav_path_ = wav_path;
    running_ = true;
    capture_thread_ = std::thread([this] { CaptureLoop(); });
    return true;
}

void SystemAudioCapture::StopCapture() {
    if (!running_.load()) return;
    running_ = false;
    if (capture_thread_.joinable()) capture_thread_.join();
}

void SystemAudioCapture::CaptureLoop() {
    HRESULT hr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);

    IMMDeviceEnumerator* enumerator = nullptr;
    IMMDevice* device = nullptr;
    IAudioClient* client = nullptr;
    IAudioCaptureClient* capture_client = nullptr;
    WAVEFORMATEX* format = nullptr;

    std::ofstream out(output_wav_path_, std::ios::binary);
    // Reserve space for the WAV header — rewrite at the end with the
    // actual size.
    out.write(std::string(44, '\0').c_str(), 44);
    uint32_t total_pcm_bytes = 0;

    do {
        hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr,
                              CLSCTX_ALL, __uuidof(IMMDeviceEnumerator),
                              reinterpret_cast<void**>(&enumerator));
        if (FAILED(hr)) break;
        hr = enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &device);
        if (FAILED(hr)) break;
        hr = device->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr,
                              reinterpret_cast<void**>(&client));
        if (FAILED(hr)) break;
        hr = client->GetMixFormat(&format);
        if (FAILED(hr)) break;

        // 100 ms buffer.
        const REFERENCE_TIME buffer_duration = 1000000;
        hr = client->Initialize(AUDCLNT_SHAREMODE_SHARED,
                                AUDCLNT_STREAMFLAGS_LOOPBACK,
                                buffer_duration, 0, format, nullptr);
        if (FAILED(hr)) break;
        hr = client->GetService(__uuidof(IAudioCaptureClient),
                                reinterpret_cast<void**>(&capture_client));
        if (FAILED(hr)) break;
        hr = client->Start();
        if (FAILED(hr)) break;

        const float ratio = 16000.0f / static_cast<float>(format->nSamplesPerSec);
        std::vector<int16_t> resampled;

        while (running_.load()) {
            UINT32 packet_size = 0;
            capture_client->GetNextPacketSize(&packet_size);
            if (packet_size == 0) {
                Sleep(5);
                continue;
            }
            BYTE* data = nullptr;
            UINT32 frames_available = 0;
            DWORD flags = 0;
            capture_client->GetBuffer(&data, &frames_available, &flags, nullptr, nullptr);

            // Convert to 16 kHz mono int16 via naive linear interpolation +
            // channel-average downmix. Production version should use a
            // proper resampler (libsamplerate / r8brain).
            const int channels = format->nChannels;
            const int bps = format->wBitsPerSample;
            const float* float_in = reinterpret_cast<const float*>(data);
            const int16_t* int_in = reinterpret_cast<const int16_t*>(data);
            const bool is_float = bps == 32;

            const size_t out_frame_count =
                static_cast<size_t>(static_cast<float>(frames_available) * ratio);
            resampled.resize(out_frame_count);
            float sum_squares = 0.0f;
            for (size_t i = 0; i < out_frame_count; ++i) {
                size_t src_frame =
                    static_cast<size_t>(static_cast<float>(i) / ratio);
                if (src_frame >= frames_available) src_frame = frames_available - 1;
                float mixed = 0.0f;
                for (int c = 0; c < channels; ++c) {
                    float s;
                    if (is_float) {
                        s = float_in[src_frame * channels + c];
                    } else {
                        s = int_in[src_frame * channels + c] / 32768.0f;
                    }
                    mixed += s;
                }
                mixed /= channels;
                if (mixed > 1.0f) mixed = 1.0f;
                if (mixed < -1.0f) mixed = -1.0f;
                resampled[i] = static_cast<int16_t>(mixed * 32767.0f);
                sum_squares += mixed * mixed;
            }
            out.write(reinterpret_cast<const char*>(resampled.data()),
                      resampled.size() * sizeof(int16_t));
            total_pcm_bytes +=
                static_cast<uint32_t>(resampled.size() * sizeof(int16_t));

            const float rms = std::sqrt(sum_squares /
                static_cast<float>(std::max<size_t>(1, out_frame_count)));
            if (event_sink_) {
                event_sink_->Success(flutter::EncodableValue(static_cast<double>(rms)));
            }

            capture_client->ReleaseBuffer(frames_available);
        }
        client->Stop();
    } while (false);

    if (format) CoTaskMemFree(format);
    if (capture_client) capture_client->Release();
    if (client) client->Release();
    if (device) device->Release();
    if (enumerator) enumerator->Release();
    CoUninitialize();

    // Rewrite the WAV header with the final size.
    out.seekp(0);
    WriteWavHeader(out, total_pcm_bytes);
    out.close();
}
