import 'dart:async';
import 'dart:io';

import '../../billing/tier.dart';
import 'android_asr.dart';
import 'apple_asr.dart';
import 'asr_engine.dart';
import 'whisper_asr.dart';

enum AsrEnginePreference {
  /// Pick based on platform + availability.
  auto,

  /// Always prefer the platform native engine (Apple / Google / Windows).
  nativeOnly,

  /// Always use Whisper (Recap-bundled). Required on Privacy tier.
  whisperOnly,
}

/// Picks the right [AsrEngine] for the current request, considering:
///   - User's Settings preference (auto / native-only / Whisper-only)
///   - User's tier (Privacy ⇒ force Whisper for verifiable no-network)
///   - Platform (iOS/macOS prefer Apple; Android prefers Android; desktop ≥
///     Windows Speech SDK is TODO so falls to Whisper today)
///   - Per-call mode (streaming vs file). Android native doesn't support
///     file input → always Whisper for transcribeFile on Android.
///
/// The router is stateless; engines are passed in so the same instances can
/// be shared across the app (avoiding double-initialization of audio
/// sessions etc.).
class AsrRouter {
  AsrRouter({
    required this.appleAsr,
    required this.androidAsr,
    required this.whisperAsr,
    required this.tierProvider,
    required this.preferenceProvider,
  });

  final AppleAsrEngine appleAsr;
  final AndroidAsrEngine androidAsr;
  final WhisperAsrEngine whisperAsr;

  /// Read on every call so we always honor live tier changes.
  final Tier Function() tierProvider;
  final AsrEnginePreference Function() preferenceProvider;

  /// Returns the engine for streaming use, or null if no engine is currently
  /// available (UI should surface "Live captions unavailable, retry later").
  Future<AsrEngine?> pickStreamingEngine({String lang = 'en'}) async {
    final tier = tierProvider();
    final pref = preferenceProvider();

    // Privacy tier — Whisper only, structurally.
    if (tier == Tier.privacy) {
      if (await whisperAsr.isAvailable(lang: lang)) return whisperAsr;
      return null;
    }

    if (pref == AsrEnginePreference.whisperOnly) {
      if (await whisperAsr.isAvailable(lang: lang)) return whisperAsr;
      return null;
    }

    // Auto / native-only: prefer platform native, fall through to Whisper
    // (unless native-only, in which case we surface unavailable).
    if (Platform.isIOS || Platform.isMacOS) {
      if (await appleAsr.isAvailable(lang: lang)) return appleAsr;
    } else if (Platform.isAndroid) {
      if (await androidAsr.isAvailable(lang: lang)) return androidAsr;
    }

    if (pref == AsrEnginePreference.nativeOnly) return null;
    if (await whisperAsr.isAvailable(lang: lang)) return whisperAsr;
    return null;
  }

  /// Returns the engine for one-shot file transcription. Always picks
  /// Whisper on Android (no native file API). Picks Apple on iOS/macOS for
  /// short files, Whisper for long (Apple's recognition tasks have a 1-min
  /// hard ceiling; LiveCaptionsService restarts every 50s for streaming but
  /// for a 1hr file Whisper is the right choice).
  Future<AsrEngine?> pickFileEngine({
    String lang = 'en',
    Duration? approxDuration,
  }) async {
    final tier = tierProvider();
    final pref = preferenceProvider();

    if (tier == Tier.privacy || pref == AsrEnginePreference.whisperOnly) {
      if (await whisperAsr.isAvailable(lang: lang)) return whisperAsr;
      return null;
    }

    final shortEnoughForApple =
        approxDuration == null || approxDuration < const Duration(seconds: 50);

    if ((Platform.isIOS || Platform.isMacOS) && shortEnoughForApple) {
      if (await appleAsr.isAvailable(lang: lang)) return appleAsr;
    }
    // Android: native doesn't do file. Whisper.
    // Windows: TODO (Windows Speech SDK). Whisper for now.
    if (pref == AsrEnginePreference.nativeOnly) return null;
    if (await whisperAsr.isAvailable(lang: lang)) return whisperAsr;
    return null;
  }
}
