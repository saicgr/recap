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
import 'summary_pipeline.dart';
import 'summary_types.dart';

enum SummaryRoute { ollama, appleFoundationModels, gemma, cloud, byok }

/// Whether the UI should OFFER a cloud summary before running a LONG meeting
/// on-device. Pure decision — the dialog ("~N min on-device, or 1 credit in the
/// cloud for better quality?") is the thin UI layer on top of this.
///
/// The rules encode the product invariants:
///   • Privacy tier: NEVER — cloud is structurally unreachable (Karpathy).
///   • Only LONG meetings ([SummaryPlan.isLong]); short ones summarize well
///     on-device, where a 2B is reliable and it's free + private.
///   • Only when the user is defaulting to on-device — if they already chose
///     cloud, there is nothing to offer.
///   • Only when cloud is actually usable on this tier right now (quota + proxy).
/// [SummaryPlan] comes from [SummaryPipeline.planFor] with the on-device backend's
/// window, so the offer fires exactly when the on-device path would fold.
bool shouldOfferCloudUpgrade({
  required Tier tier,
  required SummaryMode mode,
  required SummaryPlan plan,
  required bool cloudUsable,
}) {
  if (tier == Tier.privacy) return false;
  if (!tier.cloudSummariesEnabled) return false;
  if (mode == SummaryMode.cloud) return false;
  if (!plan.isLong) return false;
  return cloudUsable;
}

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
/// entitlements, (3) availability of each backend — then hands it to
/// [SummaryPipeline], which owns every prompt, the chunking and the critic pass.
///
/// The router decides WHERE the summary runs. It no longer decides anything
/// about WHAT is generated: backends stopped owning `persona.prompt +
/// transcript` (that is what made a 25-minute meeting overflow Gemma's window),
/// so the router hands the pipeline a [SummaryInput] — segments with speaker
/// labels and timestamps, not a flat body.
///
/// Rules:
///  - Privacy tier: cloud is structurally unreachable. Apple FM → Gemma → fail.
///  - Cloud requested + cloud quota OK: try cloud first, fall back on transient
///    failure to on-device if available.
///  - On-device requested OR cloud quota exhausted: Apple FM → Gemma.
///    If Gemma not downloaded, return `SummaryNeedsGemmaDownload`.
///
/// [SummaryCancelled] is never wrapped in a [SummaryFailed] and never triggers a
/// fallback — a user who cancels must not silently get a second, slower attempt
/// on another backend. It propagates out of [summarize] for the UI to swallow.
class SummaryRouter {
  SummaryRouter({
    required this.entitlements,
    required this.appleFm,
    required this.gemma,
    required this.cloud,
    required this.byok,
    required this.ollama,
    SummaryPipeline pipeline = const SummaryPipeline(),
    // `pipeline` is the public injection point (tests pass pipeline:);
    // this._pipeline would rename it, so the initializing-formal lint can't apply.
    // ignore: prefer_initializing_formals
  }) : _pipeline = pipeline;

  final EntitlementService entitlements;
  final AppleFoundationModelsBackend appleFm;
  final GemmaBackend gemma;
  final CloudBackend cloud;
  final ByokBackend byok;
  final OllamaBackend ollama;
  final SummaryPipeline _pipeline;

  Future<SummaryAttempt> summarize({
    required SummaryInput input,
    required Persona persona,
    required SummaryMode requested,
    void Function(SummaryProgress)? onProgress,
    CancelToken? cancel,
  }) async {
    final tier = entitlements.currentTier;

    // Enforce the persona gate HERE, not only in the UI.
    //
    // Tier.personaTemplates was filtered exclusively in transcript_screen's
    // picker, so it was a presentation detail: any code path that handed a
    // Persona straight to the router (an export, a retry, a future automation,
    // a bug) got a paid template on a Free account for free. A gate that only
    // exists in the widget tree is not a gate.
    //
    // Custom templates (key `custom:…`) carry style basic and are governed by
    // their own tier check at creation time, so they are allowed through.
    if (!persona.key.startsWith('custom:') &&
        !tier.personaTemplates.contains(persona.style)) {
      return SummaryFailed(
        StateError(
          'The "${persona.displayName}" template is not available on the '
          '${tier.name} tier.',
        ),
        StackTrace.current,
      );
    }

    // Privacy tier: never touch cloud.
    final mode = tier == Tier.privacy ? SummaryMode.onDevice : requested;

    if (mode == SummaryMode.cloud) {
      // Power tier with a saved BYOK key bypasses the proxy entirely.
      if (tier.byok && await byok.isAvailable()) {
        try {
          final r = await _run(byok, input, persona, onProgress, cancel);
          return SummaryReady(r, SummaryRoute.byok);
        } on SummaryCancelled {
          rethrow;
        } catch (e, s) {
          // BYOK failed — fall through to the standard cloud-quota path.
          final onDevice = await _tryOnDevice(
            input,
            persona,
            onProgress,
            cancel,
          );
          return onDevice ?? SummaryFailed(e, s);
        }
      }
      final decision = await entitlements.decideSummary(SummaryMode.cloud);
      switch (decision) {
        case AllowSummary():
          try {
            // The cloud window (1M tokens) makes this exactly ONE metered
            // generate call — the pipeline takes the single-pass branch, with
            // the self-check embedded in the prompt rather than issued as a
            // second request.
            final r = await _run(cloud, input, persona, onProgress, cancel);
            await entitlements.recordCloudSummaryUsed();
            return SummaryReady(r, SummaryRoute.cloud);
          } on SummaryCancelled {
            // Cancelled before the proxy answered: do not bill the user, do not
            // start a slow on-device retry they did not ask for.
            rethrow;
          } catch (e, s) {
            // Transient cloud failure (offline, 5xx, timeout) — try on-device
            // fallback. The 401-retry lives inside CloudBackend and has already
            // been exhausted by the time we see the error.
            final onDevice = await _tryOnDevice(
              input,
              persona,
              onProgress,
              cancel,
            );
            return onDevice ?? SummaryFailed(e, s);
          }
        case BlockedCloudQuota(:final onDeviceAvailable):
          if (!onDeviceAvailable) return const SummaryBlockedByQuota();
          final onDevice = await _tryOnDevice(
            input,
            persona,
            onProgress,
            cancel,
          );
          return onDevice ?? const SummaryBlockedByQuota();
        case BlockedCloudDisabled():
          // Shouldn't happen — we already coerced Privacy to onDevice above.
          final onDevice = await _tryOnDevice(
            input,
            persona,
            onProgress,
            cancel,
          );
          return onDevice ?? const SummaryBlockedByQuota();
      }
    }

    // On-device path.
    final r = await _tryOnDevice(input, persona, onProgress, cancel);
    if (r != null) return r;
    return const SummaryNeedsGemmaDownload();
  }

  Future<SummaryAttempt?> _tryOnDevice(
    SummaryInput input,
    Persona persona,
    void Function(SummaryProgress)? onProgress,
    CancelToken? cancel,
  ) async {
    // Priority order on-device:
    //   1. Ollama (desktop only) — runs 27B+ models, biggest quality jump
    //   2. Apple Foundation Models (iOS 26+ / macOS 15+ with Apple Intelligence)
    //   3. Gemma 4 E2B/E4B via flutter_gemma (everywhere)
    // Each gracefully falls through to the next if isAvailable() returns false.
    if (await ollama.isAvailable()) {
      try {
        final r = await _run(ollama, input, persona, onProgress, cancel);
        return SummaryReady(r, SummaryRoute.ollama);
      } on SummaryCancelled {
        rethrow;
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
        final r = await _run(appleFm, input, persona, onProgress, cancel);
        return SummaryReady(r, SummaryRoute.appleFoundationModels);
      } on SummaryCancelled {
        rethrow;
      } catch (e, s) {
        return SummaryFailed(e, s);
      }
    }
    if (await gemma.isAvailable()) {
      try {
        final r = await _run(gemma, input, persona, onProgress, cancel);
        return SummaryReady(r, SummaryRoute.gemma);
      } on SummaryCancelled {
        rethrow;
      } catch (e, s) {
        return SummaryFailed(e, s);
      }
    }
    return null;
  }

  Future<SummaryResult> _run(
    SummaryBackend backend,
    SummaryInput input,
    Persona persona,
    void Function(SummaryProgress)? onProgress,
    CancelToken? cancel,
  ) => _pipeline.run(
    backend: backend,
    input: input,
    persona: persona,
    onProgress: onProgress,
    cancel: cancel,
  );
}
