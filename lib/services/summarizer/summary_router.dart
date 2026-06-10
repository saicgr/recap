import 'package:flutter/foundation.dart';

import '../../billing/entitlement_service.dart';
import '../../billing/persona.dart';
import '../../billing/tier.dart';
import 'apple_foundation_models_backend.dart';
import 'byok_backend.dart';
import 'cloud_backend.dart';
import 'gemma_backend.dart';
import 'ollama_backend.dart';
import 'summary_backend.dart';

enum SummaryRoute { ollama, appleFoundationModels, gemma, cloud, byok }

sealed class SummaryAttempt {
  const SummaryAttempt();
}

class SummaryReady extends SummaryAttempt {
  final SummaryResult result;
  final SummaryRoute route;
  const SummaryReady(this.result, this.route);
}

class SummaryNeedsGemmaDownload extends SummaryAttempt {
  /// User must trigger Gemma download via `GemmaBackend.download(...)`.
  /// The router will then succeed on the next call.
  const SummaryNeedsGemmaDownload();
}

class SummaryBlockedByQuota extends SummaryAttempt {
  /// Cloud was requested but the user is out of cloud quota. On-device
  /// alternatives are also unavailable (no Apple FM, no Gemma downloaded).
  const SummaryBlockedByQuota();
}

class SummaryFailed extends SummaryAttempt {
  final Object error;
  final StackTrace? stack;
  const SummaryFailed(this.error, [this.stack]);
}

/// Picks the right backend based on (1) user's settings, (2) tier
/// entitlements, (3) availability of each backend.
///
/// Rules:
///  - Privacy tier: cloud is structurally unreachable. Apple FM → Gemma → fail.
///  - Cloud requested + cloud quota OK: try cloud first, fall back on transient
///    failure to on-device if available.
///  - On-device requested OR cloud quota exhausted: Apple FM → Gemma.
///    If Gemma not downloaded, return `SummaryNeedsGemmaDownload`.
class SummaryRouter {
  SummaryRouter({
    required this.entitlements,
    required this.appleFm,
    required this.gemma,
    required this.cloud,
    required this.byok,
    required this.ollama,
  });

  final EntitlementService entitlements;
  final AppleFoundationModelsBackend appleFm;
  final GemmaBackend gemma;
  final CloudBackend cloud;
  final ByokBackend byok;
  final OllamaBackend ollama;

  Future<SummaryAttempt> summarize({
    required String transcript,
    required Persona persona,
    required SummaryMode requested,
  }) async {
    final tier = entitlements.currentTier;

    // Privacy tier: never touch cloud.
    final mode = tier == Tier.privacy ? SummaryMode.onDevice : requested;

    if (mode == SummaryMode.cloud) {
      // Power tier with a saved BYOK key bypasses the Worker proxy entirely.
      if (tier.byok && await byok.isAvailable()) {
        try {
          final r = await byok.summarize(
              transcript: transcript, persona: persona);
          return SummaryReady(r, SummaryRoute.byok);
        } catch (e, s) {
          // BYOK failed — fall through to the standard cloud-quota path.
          final onDevice = await _tryOnDevice(transcript, persona);
          return onDevice ?? SummaryFailed(e, s);
        }
      }
      final decision = await entitlements.decideSummary(SummaryMode.cloud);
      switch (decision) {
        case AllowSummary():
          try {
            final r = await cloud.summarize(
                transcript: transcript, persona: persona);
            await entitlements.recordCloudSummaryUsed();
            return SummaryReady(r, SummaryRoute.cloud);
          } catch (e, s) {
            // Transient cloud failure — try on-device fallback.
            final onDevice = await _tryOnDevice(transcript, persona);
            return onDevice ?? SummaryFailed(e, s);
          }
        case BlockedCloudQuota(:final onDeviceAvailable):
          if (!onDeviceAvailable) return const SummaryBlockedByQuota();
          final onDevice = await _tryOnDevice(transcript, persona);
          return onDevice ?? const SummaryBlockedByQuota();
        case BlockedCloudDisabled():
          // Shouldn't happen — we already coerced Privacy to onDevice above.
          return _tryOnDevice(transcript, persona)
              .then((v) => v ?? const SummaryBlockedByQuota());
      }
    }

    // On-device path.
    final r = await _tryOnDevice(transcript, persona);
    if (r != null) return r;
    return const SummaryNeedsGemmaDownload();
  }

  Future<SummaryAttempt?> _tryOnDevice(String transcript, Persona persona) async {
    // Priority order on-device:
    //   1. Ollama (desktop only) — runs 27B+ models, biggest quality jump
    //   2. Apple Foundation Models (iOS 26+ / macOS 15+ with Apple Intelligence)
    //   3. Gemma 4 E2B/E4B via flutter_gemma (everywhere)
    // Each gracefully falls through to the next if isAvailable() returns false.
    if (await ollama.isAvailable()) {
      try {
        final r =
            await ollama.summarize(transcript: transcript, persona: persona);
        return SummaryReady(r, SummaryRoute.ollama);
      } catch (e, s) {
        // Ollama hard-failed (model OOM, daemon crash, etc.) — fall through
        // rather than surfacing the error so user still gets a summary.
        // The Settings status indicator surfaces the underlying issue.
        debugPrint('Ollama summarize failed, falling through: $e');
        debugPrintStack(stackTrace: s);
      }
    }
    if (await appleFm.isAvailable()) {
      try {
        final r = await appleFm.summarize(
            transcript: transcript, persona: persona);
        return SummaryReady(r, SummaryRoute.appleFoundationModels);
      } catch (e, s) {
        return SummaryFailed(e, s);
      }
    }
    if (await gemma.isAvailable()) {
      try {
        final r =
            await gemma.summarize(transcript: transcript, persona: persona);
        return SummaryReady(r, SummaryRoute.gemma);
      } catch (e, s) {
        return SummaryFailed(e, s);
      }
    }
    return null;
  }
}
