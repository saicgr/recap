package com.recapfreenote.recap

// Android on-device SpeechRecognizer ↔ Flutter platform channel.
// Implements: recap.asr.android (MethodChannel) + recap.asr.android.events (EventChannel).
//
// On-device guarantee: API 33+ via SpeechRecognizer.createOnDeviceSpeechRecognizer
// (since Android 13). On older devices isAvailable() returns false and the
// AsrRouter falls back to Whisper.

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class AndroidAsrBridge(private val context: Context, flutterEngine: FlutterEngine) {
    private val methodChannel: MethodChannel =
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "recap.asr.android")
    private val eventChannel: EventChannel =
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "recap.asr.android.events")

    private var eventSink: EventChannel.EventSink? = null
    private var recognizer: SpeechRecognizer? = null
    private var streamStartMs: Long = 0

    init {
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> {
                    val lang = call.argument<String>("lang") ?: "en"
                    result.success(isAvailable(lang))
                }
                "startStreaming" -> {
                    val lang = call.argument<String>("lang") ?: "en"
                    try {
                        startStreaming(lang)
                        result.success(null)
                    } catch (e: Throwable) {
                        result.error("start_failed", e.message, null)
                    }
                }
                "stopStreaming" -> {
                    stopStreaming()
                    result.success(null)
                }
                "transcribeFile" -> {
                    // Android SpeechRecognizer doesn't accept file input — AsrRouter
                    // routes file transcription to Whisper on Android.
                    result.error(
                        "unsupported",
                        "Android on-device SpeechRecognizer doesn't support file input.",
                        null
                    )
                }
                else -> result.notImplemented()
            }
        }
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun isAvailable(@Suppress("UNUSED_PARAMETER") lang: String): Boolean {
        if (!SpeechRecognizer.isRecognitionAvailable(context)) return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return false
        return try {
            SpeechRecognizer.isOnDeviceRecognitionAvailable(context)
        } catch (_: NoSuchMethodError) {
            false
        }
    }

    private fun startStreaming(lang: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            throw IllegalStateException("On-device SpeechRecognizer requires Android 13+")
        }
        recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
        streamStartMs = System.currentTimeMillis()

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, lang)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        }

        recognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(p0: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(p0: Float) {}
            override fun onBufferReceived(p0: ByteArray?) {}
            override fun onEndOfSpeech() {}
            override fun onError(p0: Int) {
                // Most errors → silently restart the session so streaming
                // continues. ERROR_NETWORK / ERROR_AUDIO are fatal.
                if (p0 == SpeechRecognizer.ERROR_NETWORK ||
                    p0 == SpeechRecognizer.ERROR_AUDIO) {
                    eventSink?.error("recognition_error", "code=$p0", null)
                } else {
                    try { recognizer?.startListening(intent) } catch (_: Throwable) {}
                }
            }
            override fun onResults(results: Bundle?) {
                emit(results, isFinal = true)
                // Loop again — SpeechRecognizer auto-stops after each utterance.
                try { recognizer?.startListening(intent) } catch (_: Throwable) {}
            }
            override fun onPartialResults(results: Bundle?) {
                emit(results, isFinal = false)
            }
            override fun onEvent(p0: Int, p1: Bundle?) {}
        })
        recognizer?.startListening(intent)
    }

    private fun emit(results: Bundle?, isFinal: Boolean) {
        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        val text = matches?.firstOrNull() ?: return
        val now = System.currentTimeMillis()
        val map = HashMap<String, Any>()
        map["text"] = text
        map["isFinal"] = isFinal
        map["startMs"] = streamStartMs
        map["endMs"] = now
        eventSink?.success(map)
    }

    private fun stopStreaming() {
        try { recognizer?.stopListening() } catch (_: Throwable) {}
        try { recognizer?.destroy() } catch (_: Throwable) {}
        recognizer = null
    }
}
