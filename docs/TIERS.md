# Recap — Tier Specification

> **On-device first, always.** Transcription runs locally on every tier (Whisper). On-device AI summaries are **available to every tier** (Apple Foundation Models on capable iPhones, Gemma 4 via `flutter_gemma` everywhere else). Cloud summaries (Gemini 3.1 Flash Lite via Cloudflare Worker proxy) are an opt-in upgrade for quality — never required, never the default for Privacy users.
>
> **No account required for any AI feature.** Transcription, summaries (on-device and cloud), exports, top-ups — none require sign-in. (Sign-in exists only as an optional convenience for IAP restore / cross-device settings sync; it never gates a tier or an AI feature.) This is the explicit contrast vs Samsung Galaxy AI, which requires a Samsung Account to use the Summary feature — confirmed verbatim in Samsung's own support docs (see `MARKET_ANALYSIS.md` §4 for the citation).
>
> Lifetime pricing. No subscriptions. No account required, ever.
>
> **See `MARKET_ANALYSIS.md`** for the full competitive landscape, market sizing, and the source-cited business case behind these prices.
>
> **Terminology:** a *session* = a *meeting* = one recording. Tap **Record** → start a session. Tap **Stop** → end it. Sessions and meetings are the same thing; the table uses "meetings" for clarity.
>
> All monthly limits reset on the user's local timezone, anchored to first-use date of the month. Daily limits reset at local midnight.

## Tiers

**Recording is unlimited on every tier.** Whisper runs on-device, so the marginal cost to us is zero. Voice Memos, Samsung Recorder, and Google Recorder all give unlimited recording; capping ours would lose the comparison instantly. The pricing walls live on **cloud calls** (real $ to us), **feature presence** (engineering moat — translation, viral clips, voice ID, exports, search), **model quality** (Whisper / on-device LLM upgrades), and **watermarks** (marketing lever).

**4-tier ladder** (collapsed from 6 after market research — Otter / Granola / Fathom / MacWhisper / SuperWhisper all settled at 3-4 SKUs). Free+ was dropped because it required sign-in for a trivial cloud-quota bump — violated the no-account Karpathy invariant. Starter was redundant with Pro.

| Tier | Price | Cloud summaries (Gemini Flash Lite) | Top-up credits | Persona templates | Exports | Cross-meeting search | Watermark |
|---|---|---|---|---|---|---|---|
| **Free** | $0 | 5/mo | ✓ | 1 (basic) | Copy / share-sheet | ❌ | Yes |
| **Pro** | $49 IAP | 100/mo | ✓ | All 7 | Copy / share-sheet / Reminders / Notes / Markdown | ✓ | No |
| **Privacy** | $69 IAP | **Disabled — verifiable no-network** | N/A | All 7 | All offline (no Notion/Slack/GDocs cloud) | ✓ | No |
| **Power** | $99 IAP | **BYOK — unlimited via your key** | N/A | All + custom | All (Notion / Obsidian / Slack / GDocs) | ✓ | No |

Recording, meetings/day, hours/month, and on-device summaries are **unlimited on every tier** — Whisper + Gemma 4 run on-device with zero marginal cost to us, and Voice Memos / Samsung / Google Recorder all give unlimited capture. Capping ours would lose that comparison instantly.

### Where the walls actually live

| Wall | Free | Pro | Privacy | Power |
|---|---|---|---|---|
| **Cloud Gemini summary calls** | 5/mo | 100/mo | disabled | BYOK ∞ |
| **Whisper model ceiling** | tiny.en | small.en | small.en | small.en |
| **On-device summary model ceiling** | Gemma 4 E2B (~2.4 GB) | + Apple FM + Gemma 4 E4B (~4.3 GB) | + Apple FM + Gemma 4 E4B | + Apple FM + Gemma 4 E4B + BYO |
| **Watermark on PDFs + viral clips** | yes | no | no | no |
| **Translation (offline pairs)** | basic | unlimited | unlimited | unlimited |
| **Translation (cloud / Gemini)** | counts as cloud | counts | disabled | BYOK ∞ |
| **Viral Clip Studio** | 1/wk watermarked | ∞ no wm | ∞ no wm | ∞ no wm + branded |
| **Voice enrollment / voice ID** | ✓ | ✓ | ✓ | ✓ |
| **Cross-meeting search** | ❌ | ✓ | ✓ | ✓ |
| **Auto-chapters** | ❌ | ✓ | ✓ | ✓ |
| **Workflow exports (Notion / Slack / Obsidian / GDocs)** | ❌ | ❌ (cloud-only path) | offline-only path | all |
| **Wake word (Hey Recap)** | ❌ | ✓ | local-only path | ✓ |
| **MCP companion** | ❌ | ❌ | ❌ | ✓ |
| **Custom personas** | ❌ | ❌ | ❌ | ✓ |
| **Branded clip output (logo + colors on viral clips / PDFs)** | ❌ | ❌ | ❌ | ✓ |

## Top-up credits

One-time IAP packs, never expire, apply only to cloud summaries (on-device summaries are always unlimited and don't consume credits). Available on Free and Pro. Not applicable to Privacy (no cloud) or Power (BYOK covers it).

| Pack | Price |
|---|---|
| 25 cloud summaries | $2.99 |
| 100 cloud summaries | $9.99 |
| 500 cloud summaries | $39.99 |

## What stays on-device, always

- Audio capture
- Live captions (chunked Whisper)
- Final transcript
- Storage
- Summaries on the Privacy tier
- Summaries on any tier when "Summary mode = on-device" in Settings

## What touches the cloud (only when the user opts in)

- **Cloud summaries** — only the transcript text (not audio) sent via the Cloudflare Worker proxy to Gemini 3.1 Flash Lite. Used by Free and Pro within their monthly quota or via top-ups.
- **Power BYOK** — user-supplied API key for Gemini / OpenAI / Anthropic. Routes summaries directly to the chosen provider, bypassing our Worker. Their key, their bill.
- **Privacy tier never touches the cloud** — the cloud button doesn't exist in the UI. Verifiable in code.

## Why these prices

**On-device is cheap for us, cloud isn't.** The only per-user variable cost is cloud-summary API calls. So caps and top-ups apply only to cloud — everything else is unlimited on paid tiers.

**Power = $99 reflects real operating costs.** A mobile / cross-platform app has higher structural costs than a desktop one (App Store 15–30% cut, two OSes, mobile App-Store rejection cycles, model CDN hosting, Worker proxy ops, ongoing iOS/Android maintenance). MacWhisper at ~$69 lifetime (Gumroad; ~$99.99 App Store) works because it's a single-developer Mac-only desktop app. SuperWhisper sits at $249.99 lifetime because it earns premium pricing on a mature desktop product. **Recap at $99 is ~40% of SuperWhisper, roughly on par with MacWhisper's App Store lifetime price, and pays back vs. a cloud meeting subscription within ~3–12 months** (e.g. Granola Business ≈ $14/mo → ~7 months; Otter Pro ≈ $100/yr → ~12 months). Verified competitor pricing and the full payback table are in `MARKET_ANALYSIS.md` §9.

## What ships

Every row in the tables above is a real feature in the product, not a roadmap item. Recap is one product:

- Record + Whisper on-device transcription (99 languages, auto-detect)
- Live captions during recording, plus optional live translation to your UI locale
- Universal import — files, gallery, URLs, YouTube captions, share-sheet receive
- Background recording (foreground service on Android, background-audio mode on iOS)
- On-device AI summaries (Apple Foundation Models on iPhone 15 Pro+/16+, Gemma 4 E2B/E4B elsewhere, Ollama on desktop, BYOK on Power)
- Cloud summaries via Render proxy → Gemini Flash Lite (opt-in, hidden on Privacy)
- All 7 persona templates + custom persona prompts (Power)
- Speaker diarization (Pyannote via sherpa_onnx)
- Voice ID / speaker enrollment — auto-label known speakers
- Cross-meeting search (SQLite FTS5 + MiniLM embeddings)
- Auto-chapters
- Action items tracker + Apple Reminders sync
- Local insights (talk time, weekly summary — never reported anywhere)
- Workflow exports: Notion, Obsidian, Slack, Google Docs, Markdown, Apple Reminders / Notes, share-sheet
- MCP companion (Power)
- Viral Clip Studio — on-device 9:16 vertical clips with kinetic captions
- Wake word (Pro+)
- Backup & restore (user-controlled, encrypted)
- App Lock + per-meeting confidential flag
- Privacy dashboard — interactive Karpathy-criteria audit
- Audio playback + tap-to-seek transcripts
- Mobile (iOS + Android) + Desktop (macOS + Windows) + Browser extension (Chrome / Edge / Firefox)
- System audio capture on desktop — no meeting bot
- 36-language UI

## Enforcement levers in `EntitlementService`

- `cloudSummariesPerMonth` — block cloud summary call when exhausted; offer top-up or upgrade.
- `cloudSummariesEnabled` — false for Privacy; the cloud option is hidden from the UI entirely.
- `byok` — Power only; user provides their own API key for unlimited cloud summaries.
- `personaTemplates` — gate which summary styles are selectable.
- `exports` — gate which export targets appear in the share sheet.
- `speakerLabels` — every tier (true on all four).
- `crossMeetingSearch` — Pro / Privacy / Power.
- `autoSegment` — Pro / Privacy / Power.
- `watermark` — append "Made with Recap" footer to exported summaries (Free only).
- `gemmaVariant` — Free downloads Gemma 4 E2B; Pro / Privacy / Power downloads Gemma 4 E4B.
- `whisperCeiling` — Free downloads `base.en`; Pro / Privacy / Power downloads `small.en`.

Recording length / meetings-per-day / hours-per-month are intentionally **not** capped at any tier — Whisper is on-device with zero marginal cost, and the OS-bundled voice recorders all give unlimited capture. Walls live on cloud calls + feature presence + model quality + watermark.

## Multilingual recording flow

Three independent locale axes — don't conflate them:

| Axis | Where it lives | Example |
|---|---|---|
| **App UI locale** | `Settings → App language` → 36 ARB files | "Settings" / "設定" / "Configuración" |
| **Transcription source language** | Auto-detected by Whisper, per-meeting | Audio is Spanish → transcript is Spanish |
| **Summary output locale** | `Summary tab → Language ▼` per-meeting picker (defaults to UI locale) | Spanish transcript + Hindi UI → Hindi summary |

### End-to-end flow

1. **Recording starts.** `RecorderService` captures 16 kHz mono PCM — language-agnostic.
2. **Live captions every 5s.** `LiveCaptionsService` reads the in-progress WAV, hands the unread chunk to Whisper. Whisper runs language ID before transcription on each chunk and produces text in the detected source language.
3. **Optional live translation.** If "Show translation" is toggled on the recording screen, `LiveTranslationService` subscribes to the caption stream and emits a parallel translated stream via Apple Translation (iOS), ML Kit (non-Privacy Android), Gemma 4 (Privacy Android / desktop fallback), or Gemini cloud (high-quality opt-in). Both captions display side-by-side or stacked.
4. **Recording stops.** Higher-accuracy Whisper pass runs over the merged WAV — `base.en` on Free for English (multilingual `base` for non-en), `small.en`/`small` on Pro+. This catches errors the 5s chunks missed because Whisper does better with longer context.
5. **Diarization runs.** Pyannote + WeSpeaker via sherpa_onnx tags each segment with `Speaker N`. Language-agnostic.
6. **Voice ID matching.** Each speaker centroid is cosine-matched against enrolled voiceprints (`Settings → Voice enrollment`). Above threshold (0.75) the label auto-fills to the real name.
7. **AI summary.** The summarizer prompt includes `"Respond in {summary locale}. The transcript may be in any language; translate to {summary locale} for the summary."` Backends used in priority order:
   - **Ollama** (desktop only, any installed model — gemma3:27b / llama3.3:70b / qwen2.5:32b)
   - **Apple Foundation Models** (iOS 26+ on iPhone 15 Pro+ / 16+ / macOS 15+ with Apple Intelligence)
   - **Gemma 4 E2B** (Free) or **E4B** (Pro+) via flutter_gemma
   - **Cloud Gemini 3.1 Flash Lite** (opt-in, non-Privacy, quota-tracked) or **BYOK** on Power

Apple FM supports the major locales natively; Gemma 4 supports 140+ languages; Gemini supports all major ones. For locales an engine can't produce (rare — Hausa, Javanese, Odia with Apple FM), the router falls through to the next engine. The router never silently produces English when the user asked for another language — it surfaces a soft warning.

## What we removed from earlier drafts

- **Cloud transcription hours.** Conflicts with on-device-first positioning. Whisper is on-device for every tier.
- **History limits.** Storage is local; throttling history is artificial and user-hostile. All tiers keep everything.
- **`transcriptionMode` column on `Meetings`.** All recordings transcribe on-device; no branching.
- **On-device summaries gated to Privacy tier.** Now available everywhere; Privacy is differentiated by *forced* offline behavior, not by *being the only* offline option.
