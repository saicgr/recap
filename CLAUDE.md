# Recap — Entry Point

> Recap = Flutter meeting recorder for iOS + Android. Lifetime pricing, no subscriptions, 4-tier ladder (Free / Pro $49 / Privacy $69 / Power $99). **Recording always unlimited on every tier** (Whisper runs on-device, marginal cost = 0). **Transcription always on-device** (Whisper). **On-device AI summaries available to every tier** (Apple Foundation Models on capable iPhones; Gemma 4 E2B/E4B via `flutter_gemma` everywhere else). **Cloud summaries are an opt-in quality upgrade** (Gemini 3.1 Flash Lite via Render proxy) — never required, hidden entirely on the Privacy tier.

## What Recap is

A single product, not a phased rollout. Everything in `docs/TIERS.md` is part of Recap.

- Record + Whisper on-device transcription (99 languages, auto-detect)
- Live captions during recording (chunked Whisper, partial display)
- Live translation (optional toggle — Apple Translation / ML Kit / Gemma 4 on-device)
- Background recording (foreground service on Android, background-audio mode on iOS)
- Universal import — files, gallery, URLs, YouTube captions, share-sheet receive
- On-device AI summaries (Apple Foundation Models on iPhone 15 Pro+/16+, `flutter_gemma` with Gemma 4 E2B/E4B elsewhere, Ollama on desktop)
- Cloud summaries via Render proxy → Gemini 3.1 Flash Lite (opt-in)
- All 7 persona templates (basic, 1:1, standup, sales call, interview, lecture, doctor visit)
- Custom persona prompts (Power tier)
- Speaker diarization (Pyannote ONNX via sherpa_onnx, post-record + post-import)
- Voice ID / speaker enrollment — auto-label known speakers across meetings
- Cross-meeting search (SQLite FTS5 + on-device MiniLM embeddings)
- Auto-chapters (heuristic on speaker change + silence + embedding shift)
- Action items tracker
- Local insights (talk time, weekly summary)
- Workflow exports — Notion, Obsidian, Slack, Google Docs, Markdown, Apple Reminders / Notes, share-sheet
- MCP companion (Power tier — exports meeting JSON to a sync folder; companion binary serves to Claude Desktop)
- Viral Clip Studio — on-device 9:16 vertical clips with kinetic captions for Reels / TikTok / Shorts
- Wake word (Pro+, "Hey Recap, bookmark this")
- 4 tiers wired through `in_app_purchase` (Free / Pro / Privacy / Power)
- Top-up packs for cloud summaries
- Settings: locale (36 UI languages), summary mode, model size, auto-delete, restore-on-launch, App Lock, ASR engine
- Calendar integration (auto-title + propose attendees as speaker labels)
- Backup & restore (user-controlled, E2E-encrypted zip)
- App Lock + per-meeting confidential flag
- Privacy dashboard — interactive Karpathy-criteria audit
- Audio playback + tap-to-seek transcripts
- Mobile (iOS + Android) + Desktop (macOS + Windows) + Browser extension (Chrome / Edge / Firefox)
- System audio capture on desktop (ScreenCaptureKit on macOS, WASAPI loopback on Windows) — no meeting bot, no Otter-style participant in the call
- 36-language UI (en + 35 translated via the i18n_fill_translations.py pipeline)
- Karpathy-criteria privacy invariants (no analytics, no telemetry, verifiable Privacy tier)

## Workflow (every non-trivial task)

1. **Plan before code, every time** — enumerate edge cases (mic permission denied, audio interruption / phone call, background kill, OOM on long recordings, model download failure, low disk, airplane mode, app force-quit mid-record, etc.) before writing a line.
2. **No duplication.** Search-before-write. One source of truth per concern.
3. **No mock/fallback data.** Throw `StateError` with context; never silently degrade. A broken transcription must surface, not return `""` pretending success.
4. **Verify cleanly before declaring done.** `flutter analyze` must be 0-error 0-warning; app must launch on at least one simulator and execute the golden path (record → stop → transcript visible).
5. **Swarm-eligible tasks delegate to `swarm-coordinator` agent.** Triggers + decomposition live in `.claude/agents/swarm-coordinator.md`. Default single-thread for trivial work; swarm for cross-layer (≥2 subsystems / ≥4 files / ≥30min).
6. **Per-folder CLAUDE.md auto-loads.** Once a folder (e.g. `lib/features/recording/`, `lib/data/`) grows non-trivial, drop a CLAUDE.md there.

## Critical-every-turn invariants

### Privacy & trust (the Karpathy criteria — non-negotiable)

Karpathy publicly chose SuperWhisper because it's fully offline, no telemetry, no auto-updates, one-time purchase. Recap inherits that standard. These are **product invariants**, not preferences:

- **No account required for any AI feature.** Transcription, summaries (on-device and cloud), exports, top-ups — none require an account. **This is the explicit contrast vs Samsung Galaxy AI, which requires a Samsung Account to use the Summary feature.** A Galaxy user who refuses to give Samsung an email cannot summarize their recordings on stock OS; in Recap, they can. (We had a "Free+" tier that required sign-in for higher quotas, but dropped it — even *optional* sign-in for quota was inconsistent with this rule. Sign-in still exists as an optional feature for cross-device settings sync / IAP restore, but doesn't gate any tier.)
- **No analytics SDK.** No Firebase Analytics, no Mixpanel, no PostHog, no Amplitude. Ever.
- **No crash-reporting SDK that phones home automatically.** No Sentry, no Crashlytics. Local crash dumps the user can manually share are OK.
- **No background pings.** The app makes a network call only when the user explicitly taps a cloud-summary button, opts in to translation cloud upgrade, exports to a cloud destination (Notion/Slack/GDocs), or signs in for cross-device sync. No keepalives, no metrics, no "phone home for updates."
- **No auto-updates.** App Store / Play Store handle updates; we never bundle in-app silent update mechanisms.
- **Privacy tier is verifiable in code.** When `currentTier == Tier.privacy`, the cloud-summary code path is structurally unreachable — the UI button doesn't render, and the network call site is dead-code-eliminated or guarded with an assertion. Reviewable by anyone reading `lib/`.
- **Gemini key never ships in the app.** All Gemini traffic goes through the Cloudflare Worker proxy. App holds no API keys; no secrets in `pubspec.yaml`, `Info.plist`, or `AndroidManifest.xml`. Power-tier BYOK keys are stored in platform keychain (`flutter_secure_storage`), never plaintext on disk.

### Product invariants

- **On-device first.** Default summary mode is on-device. Cloud is the upgrade, never the default.
- **On-device LLM is available to every tier.** Apple Foundation Models on iPhone 15 Pro+ / iOS 26+; `flutter_gemma` with Gemma 4 E2B (~2.4 GB LiteRT) downloaded on first summary request elsewhere, or Gemma 4 E4B (~4.3 GB) on Pro+ where storage allows. Privacy tier has *only* this path; everyone else can toggle to cloud for quality.
- **Audio + transcription are the product.** Bugs in capture or transcription are P0; everything else is P1+.
- **Local-only storage.** Files live in app-private storage. Uninstalling the app deletes the data — warn the user before destructive ops.
- **Long recordings (≥1hr) must survive backgrounding + screen lock.** Foreground-service on Android, background audio mode on iOS — design for this from day one or retrofitting hurts.
- **Transcription is async + cancellable.** Whisper on a 1hr recording can take minutes on older devices; UI must show progress; user must be able to leave the screen without losing the job.
- **EntitlementService starts in a stub state** (`StubEntitlementService` returns Free). IAP wiring through `in_app_purchase` is part of the product — replace the stub when launching to real stores. Until then, the `Debug → Switch tier` setting (debug builds only) lets you preview paid features.
- **Drift codegen** — once `.g.dart` files are committed, do not run `dart run build_runner` blindly. Only regenerate when schema changes and commit the diff. (Flutter version + codegen drift is a known footgun — pin the Flutter version.)

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (latest stable; pin once chosen) |
| State | Riverpod (or plain `ChangeNotifier` while the surface is small) |
| Local DB | Drift (SQLite + FTS5) — meetings, transcripts, segments, summaries, bookmarks, voiceprints, action items, folders, tags, segment embeddings, translation cache, glossary, usage counters |
| Audio capture | `record` |
| Transcription | `whisper_ggml` with `whisper-small.en` (downloaded on first record, cached) |
| On-device summaries | Apple **Foundation Models** (iOS 26+ on iPhone 15 Pro+/16+) → fallback `flutter_gemma` with Gemma 4 E2B/E4B LiteRT |
| Cloud summaries (opt-in) | Gemini 3.1 Flash Lite via Cloudflare Worker proxy |
| Speaker diarization | Pyannote / wespeaker ONNX (post-record) |
| IAP (later) | `in_app_purchase` |
| Auth (optional — IAP restore + cross-device sync) | `sign_in_with_apple` + `google_sign_in` |
| Secure storage (BYOK) | `flutter_secure_storage` |

## Pricing tiers (see `docs/TIERS.md` for the full table)

| Tier | Price | Recording | On-device summaries | Cloud summaries | Notes |
|---|---|---|---|---|---|
| Free | $0 | Unlimited | Unlimited | 5/mo | Watermark on shared exports, top-ups available, Whisper tiny + Gemma 4 E2B |
| Pro | $49 IAP | Unlimited | Unlimited | 100/mo | All 7 personas, viral clips, voice ID, translation, cross-meeting search, Whisper small + Gemma 4 E4B + Apple FM |
| Privacy | $69 IAP | Unlimited | Unlimited (offline) | **Disabled — verifiable no-network** | Everything in Pro but cloud is structurally unreachable; verifiable by reading `lib/` |
| Power | $99 IAP | Unlimited | Unlimited | BYOK (unlimited) | Custom personas, MCP companion, Notion/Slack/Obsidian/GDocs exports, wake word, branded clips |

Top-up packs: 25/$2.99, 100/$9.99, 500/$39.99 (cloud summaries only; not for Privacy or Power).

**Why 4 tiers, not 6.** Free+ was dropped because it required sign-in for a trivial cloud-quota bump — violated the no-account Karpathy invariant. Starter was redundant with Pro (both had cloud, both had most features). Every mature lifetime-IAP competitor (MacWhisper, SuperWhisper, Granola, Fathom) settled at 3-4 SKUs; 6 is decision-paralysis territory.

**Lifetime grandfathering (invariant — non-negotiable).** If we ever raise lifetime prices post-launch, existing buyers keep their tier + all current and future features at their original purchase price. Only *new* purchases pay the higher price. Store IAP receipts include purchase date, so this is enforceable in code via `entitlements.purchaseDate` checks. This is structural; if SuperWhisper-style sustainability pressure ever forces a price hike, existing customers see zero change.

## Positioning (the moat)

> Full source-cited competitive analysis, market sizing (AI-meeting-assistant TAM ≈ $3.47B → ~$21.5B by 2033 @ 25.8% CAGR, Grand View Research), the Samsung deep-dive, and the business case live in `docs/MARKET_ANALYSIS.md`. Keep that doc and this section in sync.

Aiko, Apple Voice Memos, Samsung Voice Notes, MacWhisper all ship "on-device transcription." That's table stakes, not a moat. Recap's moat is the combination of:

1. **Meeting-first product** (not voice-recorder-with-AI-bolted-on)
2. **Cross-platform** (iOS + Android — Samsung is Galaxy-only, Apple is iPhone-only)
3. **No account required, ever** (Samsung requires a Samsung Account for summaries; Recap requires nothing for any AI feature)
4. **Available on devices Samsung locks out** — Galaxy A-series (no NPU), older Galaxy flagships (S22/S23), any iPhone 12+ — Recap runs everywhere Whisper + a small LLM fit
5. **Lifetime pricing vs. subscription competitors** (all recurring: Granola ~$14/mo, Otter ~$8–17/mo, Fathom ~$16–25/mo, Jamie ~€39/mo; Recap is one-time — pays back in ~3–12 months, then $0 forever. Verified pricing in `docs/MARKET_ANALYSIS.md` §9.)
6. **On-device AI summaries on every tier** (not just transcription; the AI step also runs on-device)
6a. **On-device speaker diarization on every tier, including Free** — Samsung's diarization works only on S24+ and requires the Samsung Account for the broader Galaxy AI features; Recap ships Pyannote-based speaker labels on Free with no account required
7. **Workflow integrations** (Notion, Obsidian, Slack, Google Docs — Samsung/Apple won't ship these)
8. **Cross-meeting search** (only works if you own the corpus across time)
9. **Karpathy-criteria privacy** (no analytics, no telemetry, verifiable Privacy tier)

If a PR threatens any of #3, #6–#9, flag it before merging.

## Conflict precedence

Root `CLAUDE.md` (process) > per-folder `CLAUDE.md` (folder-specific rules) > agent prompts. When in doubt, ask.
