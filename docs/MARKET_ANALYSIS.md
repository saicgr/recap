# Recap — Market Analysis & Differentiation

*Prepared 2026-06-03. All figures drawn from a verified research corpus; claims that were refuted or are uncertain in the verification pass are flagged inline or omitted.*

---

## 1. Executive Summary & Verdict

**Thesis.** There is a real, fast-growing market for AI meeting capture, and there is a genuinely empty quadrant inside it. The on-device-and-one-time tools (MacWhisper, SuperWhisper, Aiko) are all Apple-only dictation/file utilities with no meeting corpus and no Android; the meeting-first tools (Otter, Granola, Fathom, Fireflies, Jamie, Plaud, Notta) are all cloud, account-required, and subscription (or hardware+subscription). No competitor occupies the intersection Recap targets: **meeting-first AND fully on-device AND one-time-purchase AND cross-platform including Android**. That gap, sitting on top of three converging tailwinds — NPU-equipped phones going mainstream, acute subscription fatigue, and a measurable AI-privacy/recording-consent backlash — is the opportunity.

**Verdict: BUILD (with caveats).**

The three strongest reasons to build:

1. **The quadrant is verifiably empty.** Every on-device/one-time competitor is a single-purpose Apple-only utility; every meeting-first competitor is cloud + subscription + account-gated. ([Karpathy criteria / gap analysis](https://x.com/karpathy/status/1889036923655860247))
2. **The unit economics actually work for lifetime pricing.** On-device Whisper + on-device LLM summaries push marginal inference cost toward $0 — the one condition under which one-time AI pricing is sustainable, per Freemius's own analysis, and proven at scale by MacWhisper (~$69 lifetime, on-device, solo dev). ([Freemius](https://freemius.com/blog/ai-app-pricing-model/), [MacWhisper pricing](https://www.getvoibe.com/resources/macwhisper-pricing/))
3. **The privacy/no-account story is concrete, not aspirational.** Samsung's AI summary *requires a Samsung Account*; Otter faces consolidated federal privacy class actions; universities are banning notetaker bots. Recap's no-account, on-device posture is a structural counter to all three. ([Samsung Transcribe Assist](https://www.samsung.com/sg/support/mobile-devices/how-to-use-transcribe-assist-on-the-galaxy-s24/), [Otter litigation](https://www.npr.org/2025/08/15/g-s1-83087/otter-ai-transcription-class-action-lawsuit), [Oxford bot ban](https://www.infosec.ox.ac.uk/article/are-your-online-meetings-safe-from-third-party-ai-bots))

**The caveats** (developed in §7): on-device transcription is commoditizing, distribution without telemetry/ads is genuinely hard, lifetime pricing caps recurring revenue, and Apple/Samsung can bundle "good enough" for free. None are fatal; all require explicit mitigation.

---

## 2. Market Opportunity

### 2.1 Market sizing (TAM / SAM / SOM)

Market-size figures vary by firm and definition; below we prefer the higher-confidence houses (Grand View, MarketsandMarkets, IDC, Gartner) and flag what is single-source.

| Layer | Market | Size | CAGR | Source (firm, year) | Confidence |
|---|---|---|---|---|---|
| **TAM (most relevant)** | AI meeting assistant | $3.47B (2025) → $21.48B (2033) | 25.8% (2026–2033) | [Grand View Research](https://www.grandviewresearch.com/industry-analysis/ai-meeting-assistant-market-report) | High (triangulated: MRF independently puts 2025 at $3.50B) |
| **Adjacent (established)** | Speech & voice recognition | $8.49B (2024) → $23.11B (2030) | 19.1% (2025–2030) | [MarketsandMarkets](https://www.marketsandmarkets.com/Market-Reports/speech-voice-recognition-market-202401714.html) | High (firm-specific scope) |
| **Conservative floor** | Speech-to-text API (software) | $3.81B (2024) → $8.57B (2030) | 14.4% (2025–2030) | [Grand View Research](https://www.grandviewresearch.com/industry-analysis/speech-to-text-api-market-report) | High |
| **Context (over-broad)** | U.S. transcription (software+services) | $30.42B (2024) → $41.93B (2030) | 5.2% (2025–2030) | [Grand View Research](https://www.grandviewresearch.com/industry-analysis/us-transcription-market) | High — but includes human legal/medical transcription; only the software slice is addressable |

**Framing.**
- **TAM** ≈ the AI meeting-assistant market: **$3.47B today, ~$21.5B by 2033 @ 25.8%**. This clusters tightly with an independent Market Research Future estimate ($3.50B), so it is a real category sizing, not an outlier.
- **SAM** ≈ the privacy-conscious / no-account / on-device-preferring slice of consumers and prosumers across iOS + Android, plus the "Android users locked out of Mac tools" segment. Not separately quantified in credible sources — sized below via the device base and demand signals rather than a dollar figure (to avoid inventing a statistic).
- **SOM** ≈ realistically, an indie/prosumer wedge: a few hundred-thousand lifetime buyers is a proven outcome for a single on-device tool (MacWhisper sold ~300k copies — though note this number is *secondary-sourced and may conflate free downloads with paid copies*, so treat as directional). At a $49–$99 blended price, even a fraction of that is a meaningful business with ~$0 marginal cost.

### 2.2 Addressable device install base

| Metric | Value | Source | Note |
|---|---|---|---|
| iOS global share (usage) | ~28% (StatCounter); ~24–25% active install base (Counterpoint) | [9to5Mac/Counterpoint](https://9to5mac.com/2026/02/10/iphone-now-accounts-for-nearly-one-in-four-active-smartphones-worldwide-report/), [StatCounter](https://gs.statcounter.com/os-market-share/mobile/worldwide) | "~1 in 4 active phones is an iPhone"; >1B device base for Apple Foundation Models path |
| Android global share | ~71.9% (Nov 2025, StatCounter) | [StatCounter](https://gs.statcounter.com/os-market-share/mobile/worldwide) | The claimed "72.8%" was **refuted** — actual Nov 2025 is 71.90% |
| **Active smartphone devices worldwide** | **~7.3–7.6B** | [DataReportal/GSMA](https://datareportal.com/reports/digital-2025-april-global-statshot) | The research's "~4.7–4.8B active smartphones" figure was **refuted** as a conflation; ~4.7B is at most a *unique-owner* estimate, ~5.8B unique users, ~7.3–7.6B devices |

> **Honesty note:** an earlier draft of the research claimed "~4.7–4.8B active smartphones." Verification refuted that as a definitional error. The correct framing: **~7.3–7.6B active devices, ~5.8B unique users.** Recap's cross-platform iOS+Android reach addresses essentially the entire base — unlike Samsung (Galaxy-only) or Apple (iPhone-only).

### 2.3 The macro tailwinds (why now)

| Tailwind | Evidence | Source | Confidence |
|---|---|---|---|
| **On-device AI going mainstream** | GenAI smartphones: ~370M shipped 2025 (30% of shipments) → 912M by 2028 (70% of market), 78.4% CAGR | [IDC](https://my.idc.com/getdoc.jsp?containerId=prUS52478124) | High |
| **NPU substrate spending** | $298.2B GenAI-smartphone end-user spend in 2025; 41% of *basic* GenAI phones have NPUs; nearly all premium do | [Gartner, Sep 2025](https://www.gartner.com/en/newsroom/press-releases/2025-09-09-gartner-says-worldwide-generative-artificial-intelligence-smartphone-end-user-spending-to-total-us-dollars-298-billion-by-the-end-of-2025) | High |
| **Hybrid meetings = default** | 64% of (pandemic-era WFH) employees prefer hybrid video calls | [Owl Labs 2021](https://owllabs.com/state-of-remote-work/2021) | Medium — **note**: the cited "Archie/64%" was *misattributed*; real source is Owl Labs **2021**, scoped to pandemic WFH employees, not current/all employees |
| **Recording-consent regulation tightening** | ~12–13 all-party-consent US states (recording can be a felony in MA/IL/PA); 23 states regulate biometric data; $1.375B Google Texas voiceprint settlement | [Recording Law](https://www.recordinglaw.com/us-laws/ai-meeting-recording-laws/), [NPR/NCSL](https://www.npr.org/2025/08/28/nx-s1-5519756/biometrics-facial-recognition-laws-privacy), [TX AG](https://www.texasattorneygeneral.gov/news/releases/attorney-general-ken-paxton-finalizes-historic-settlement-google-and-secures-1375-billion-big-tech) | High — **note**: "12 states + DC" was *refuted*; DC is one-party consent. Use "~12–13 all-party states." |
| **Subscription fatigue** | Directionally real and rising; ~40.8% of subscribers canceled ≥1 sub in the past year (Self Financial, 2025); average US household trimmed subs 4.1→2.8 (-32%) | [Self Financial via StudyFinds](https://studyfinds.org/subscription-boom-bursting-streaming-food-delivey-americans-purge/) | Medium — see honesty note below |
| **AI-privacy backlash** | ~70% worry about data privacy; 82% say AI could be misused (up from 74% in 2024); ~1/3 reject on-device AI partly over privacy | [Tom's Hardware](https://www.tomshardware.com/tech-industry/artificial-intelligence/one-third-of-consumers-reject-ai-on-their-devices-with-most-saying-they-simply-dont-need-it-latest-report-highlights-privacy-fears-and-potential-costs-among-other-real-world-concerns) | Medium |

> **Honesty note on subscription-fatigue stats:** Several widely-circulated figures (the "47% canceled in 2026 vs 31% in 2024" Zuora number; "41% report fatigue up from 35% in 2024") were **refuted** in verification as fabricated, miscited, or conflated streaming-only stats. The *direction* — fatigue is real, mainstream, and growing — holds and is supported by genuine primary data (Self Financial's 4.1→2.8 household decline; Deloitte's ~39–47% streaming cancellation; Recurly's confirmed 71% "price increases are the #1 reason businesses lose customers"). We use only the verifiable figures.

---

## 3. Competitive Landscape

### 3.1 Master comparison

| Product | Pricing / Model | On-device vs Cloud | Account required? | Platforms | Meeting-first? | Key weakness |
|---|---|---|---|---|---|---|
| **Samsung (Transcript Assist)** | Free (basic Galaxy AI) | Hybrid (cloud by default; on-device opt-in) | **Yes — for Summary** | Galaxy only (S22–S26, Z Fold/Flip; A-series excluded) | Partly (voice recorder + calls) | Account-gated AI; Galaxy-only; mid-range lockout; future paid tier reserved |
| **Apple (Voice Memos + on-device)** | Free (bundled) | On-device | No | iPhone only | No (voice recorder) | iPhone-only; not meeting-first; no diarization/personas/integrations |
| **Otter.ai** | Subscription ($8.33–$30/user/mo) | Cloud | Yes | Web, iOS, Android, bot | Yes | Federal privacy class actions; trains AI on recordings; tight free caps |
| **Granola** | Subscription (~$14/user/mo Business) | Hybrid (local capture, cloud transcribe/store on AWS US) | Yes | macOS, Windows, iOS — **no Android** | Yes | Bot-free ≠ on-device; cloud storage; free tier cut to 25 notes lifetime; no Android |
| **Fathom** | Subscription ($16–$25/user/mo) | Cloud | Yes | Web, macOS/Windows, iOS (rolling out), bot + bot-free | Yes | Cloud-processed; once-unlimited free AI summaries now 5/mo |
| **Fireflies.ai** | Subscription ($10–$39/user/mo) | Cloud | Yes | Web, iOS, Android, bot | Yes | Cloud bot; Illinois BIPA voiceprint class actions; AI-credit metering |
| **Jamie** | Subscription (€25–€47/mo) | Cloud | Yes | macOS, Windows — no native mobile parity | Yes | Bot-free but still cloud; desktop-only; relatively expensive |
| **MacWhisper** | **One-time ~$69 lifetime** (Gumroad) | **On-device** | **No** | macOS only — **no iOS/Android** | No (file transcriber) | Mac-only; not meeting-first; no cross-meeting search/personas/integrations |
| **SuperWhisper** | Subscription ($8.49/mo, $84.99/yr) + $249.99 lifetime | Hybrid | Optional | macOS, Windows, iOS — no Android | No (dictation-first) | Dictation, not meetings; no meeting corpus/search/integrations |
| **Plaud** | Hardware $159–$189 **+** required subscription (to $239.99/yr) | Cloud | Yes | Dedicated device + iOS/Android app | Yes (ambient) | Device + sub + overage stacking; cloud; documented backlash |
| **Aiko** | **One-time $24** | **On-device** | **No** | iOS/iPadOS/macOS/visionOS — **Apple-only** | No (file transcriber) | Apple-only; pure file transcriber; no meeting features/diarization |
| **🟢 Recap** | **Lifetime $49 / $69 / $99 + top-ups** | **On-device (cloud opt-in)** | **No** | **iOS + Android + macOS + Windows + browser ext** | **Yes** | New entrant; distribution + commoditization risk (see §7) |

### 3.2 Rival profiles (the ones that matter)

**Samsung — the headline foil (full deep-dive in §4).** Free and bundled on Galaxy flagships, with native call/recorder transcription and decent language coverage. But: the AI Summary *requires a Samsung Account*; it is Galaxy-only; mid-range A-series (A56/A36/A26/A17) is locked out entirely; processing is hybrid (cloud by default); and Samsung has explicitly reserved a future paid tier for "enhanced/new" services. ([Samsung support](https://www.samsung.com/sg/support/mobile-devices/how-to-use-transcribe-assist-on-the-galaxy-s24/))

**Otter.ai — the privacy cautionary tale.** Market incumbent (35M+ users, 1B+ meetings — *note: the research's "15M+" was refuted as outdated; Otter's own 2025 release cites 35M+*). Hit with **four consolidated federal class actions** ([In re Otter.AI Privacy Litigation](https://natlawreview.com/article/take-note-new-wave-privacy-litigation-targets-ai-notetaker-otterai), N.D. Cal., MTD hearing May 20, 2026) alleging recording without all-party consent and training its AI on those recordings. This is the single strongest external validation of an on-device, no-cloud-training posture.

**Granola — the privacy benchmark among cloud rivals, and the bot-free pioneer.** SOC 2 Type II, contractually blocks OpenAI/Anthropic from training on customer data, deletes audio after transcription. But it is still cloud: transcripts/notes are stored in AWS US, sign-in is required, **there is no Android**, and the Feb 2026 rebrand cut the free tier to a 25-note lifetime cap. "Bot-free is not on-device" is the precise wedge against Granola. ([Granola security](https://www.granola.ai/security))

**Fathom — the incumbent chasing the bot-free model.** On April 15, 2026 Fathom shipped bot-free capture (plus desktop/iOS roadmap) explicitly to take on Granola. ([TechCrunch](https://techcrunch.com/2026/04/15/fathom-adds-a-bot-less-meeting-mode-in-a-bid-to-take-on-granola/)) — *note: verification clarified the iOS and Windows apps were announced as "coming soon," not shipped on that date.* Still cloud, still account-required; free AI summaries now capped at 5/mo.

**MacWhisper — the proof that the model works.** The cleanest match to the Karpathy criteria (on-device, never phones home, ~$69 one-time) and the app Karpathy flagged as his next pick. But it is Mac-only and a file-transcription utility — no meeting flow, no cross-meeting search, no personas, no Notion/Slack. It proves the *pricing-and-privacy model* is sustainable; Recap takes that model meeting-first and cross-platform.

**Plaud — the anti-pattern.** Buy a $159–$189 device, *then* pay a subscription (to $239.99/yr) for cloud transcription, *then* buy overage quota packs when you exceed the cap. Account required; cloud-processed; documented Reddit backlash over the layered cost model. This is precisely what Recap's local-only, no-account, one-time model is built against.

---

## 4. The Samsung Problem (deep dive)

Samsung Galaxy AI is the closest thing to a "free, bundled, on-device-ish" meeting transcriber on Android — and it is exactly why Recap exists. For the target user, it fails on five concrete, cited dimensions.

### 4.1 It requires a Samsung Account to summarize — even for on-device features

Samsung's official Transcribe Assist support page states **verbatim**: *"You must be logged in to your Samsung account to use the Summary feature."* ([Samsung SG](https://www.samsung.com/sg/support/mobile-devices/how-to-use-transcribe-assist-on-the-galaxy-s24/)) The Note Assist page similarly requires a Samsung Account + connectivity. As of 2026 the requirement has, if anything, *tightened*: Samsung's general Galaxy AI page now states that without a Samsung Account *"you won't be able to use any Galaxy AI features, including the ones that run on-device."* ([Samsung US Galaxy AI](https://www.samsung.com/us/galaxy-ai/))

> A Galaxy owner who refuses to give Samsung an email **cannot summarize their own recordings on stock OS.** In Recap, they can — no account, ever. This is the cleanest single-sentence differentiation in the entire product.

### 4.2 Device lockout — millions of Galaxy phones are excluded

| Excluded / limited | Detail | Source |
|---|---|---|
| **Galaxy A-series** (A56 5G, A36 5G, A26 5G, A17 5G) | Samsung docs state verbatim: *"Transcript assist is not available on the Galaxy A56 5G, A36 5G, A26 5G, or A17 5G… call transcripts and summaries are not available on these devices."* | [Samsung US, ANS10004613](https://www.samsung.com/us/support/answer/ANS10004613/) — *verification corrected the citation from ANS10000942; substance confirmed* |
| **Pre-S22 flagships** | Effectively at/below the support edge | [Samsung device support](https://www.samsung.com/us/support/answer/ANS10000753/) |
| **OS floor** | Requires One UI 6.1 / Android 14; call transcription needs One UI 7 / Android 15 (S24/S23/S22/S21) | [Samsung US, ANS10000942](https://www.samsung.com/us/support/answer/ANS10000942/) |

Recap, by contrast, "runs everywhere Whisper + a small LLM fit" — the entire installed base of capable A-series and older flagships that Samsung's NPU/hardware gating excludes.

### 4.3 Galaxy-only — no iPhone, no other Android brands

Transcript Assist is Samsung-Galaxy-only and works only inside Samsung's *native* Voice Recorder app (not third-party recorders). Recap is iOS + Android + desktop + browser extension — addressing the ~28% iOS base and all non-Samsung Android that Galaxy AI structurally cannot reach.

### 4.4 Cloud/privacy posture — not verifiably offline

Samsung's processing is **hybrid on-device/cloud with an opt-in "Process data only on device" toggle** — so by default some work can go to the cloud. ([Samsung Newsroom](https://news.samsung.com/global/your-privacy-secured-how-galaxy-ai-empowers-you-to-take-control-of-your-data)) This is not a verifiable no-network guarantee. Recap's **Privacy tier is structurally unreachable to the network** and reviewable in code.

### 4.5 The "free, but for how long?" overhang

In Jan 2026 Samsung removed the old "complimentary through 2025" deadline and confirmed ~13 basic features (including Transcript Assist and Note Assist) are free indefinitely. ([Android Authority](https://www.androidauthority.com/samsung-galaxy-ai-features-free-3632510/)) **But** the revised footnote explicitly reserves a future paid tier: *"Future releases may include enhanced features or new services that are offered on a paid basis."* ([PhoneArena](https://www.phonearena.com/news/galaxy-ai-policy-changes_id177350)) Free today; paid-tier ambiguity baked in — the kind of uncertainty Recap's lifetime price eliminates. (Also note: *free ≠ account-free*. The account gate remains regardless of price.)

---

## 5. Why Recap Wins — The Moat

Each pillar is tied to a named competitor's documented gap.

| # | Moat pillar | The competitor gap it exploits |
|---|---|---|
| **a** | **Meeting-first, not recorder-with-AI** | MacWhisper, SuperWhisper, Aiko are dictation/file utilities — no meeting flow, no corpus, no cross-meeting search ([gap analysis](https://x.com/karpathy/status/1889036923655860247)) |
| **b** | **Truly cross-platform (iOS + Android + desktop)** | Granola/SuperWhisper/MacWhisper/Aiko all **lack Android**; Samsung is Galaxy-only; Apple is iPhone-only; Jamie is desktop-only |
| **c** | **No account, ever** | Samsung *requires* a Samsung Account for Summary ([Samsung](https://www.samsung.com/sg/support/mobile-devices/how-to-use-transcribe-assist-on-the-galaxy-s24/)); every commercial SaaS rival (Otter, Granola, Fathom, Fireflies, Jamie, Plaud, Notta) requires sign-up |
| **d** | **Runs on devices Samsung/Apple lock out** | Samsung excludes A56/A36/A26/A17 and pre-S22 entirely ([Samsung](https://www.samsung.com/us/support/answer/ANS10004613/)); Apple is iPhone-only |
| **e** | **Lifetime, not subscription** | Otter/Granola/Fathom/Fireflies/Jamie are all recurring; productivity subs churn (~60% first-renewal retention) — a churn problem lifetime sidesteps ([Adapty](https://adapty.io/blog/productivity-app-subscription-benchmarks/)) |
| **f** | **On-device AI summaries on every tier** | Samsung's summary is account-gated + hybrid; Granola/Otter/Fathom/Fireflies/Jamie all summarize in the cloud |
| **g** | **On-device diarization even on Free** | Samsung's diarization degrades sharply with speaker count and requires the account; among on-device rivals only MacWhisper offers diarization (beta), Aiko has none |
| **h** | **Workflow integrations (Notion/Obsidian/Slack/GDocs)** | None of the on-device set (MacWhisper/SuperWhisper/Aiko) ships these; Samsung/Apple won't |
| **i** | **Cross-meeting search (own the corpus over time)** | MacWhisper/SuperWhisper/Aiko have none; cloud rivals only search within their own account/cloud |
| **j** | **Verifiable Karpathy-criteria privacy** | The named market signal: Karpathy prefers *"fully super duper fully offline apps (no pinging home, no updating unless I ask, no analytics no nothing)"* — no cloud rival can meet this; Recap's Privacy tier is structurally no-network ([Karpathy, X](https://x.com/karpathy/status/1889036923655860247)) |

**The combination is the moat.** Any single pillar is matchable (Aiko is on-device + no-account; Otter is meeting-first; Plaud has Android). *No competitor matches the full set.* The empty quadrant — meeting-first ∧ on-device ∧ one-time ∧ cross-platform-incl-Android — is Recap's open lane.

---

## 6. The Case for Building It

### 6.1 The wedge

Lead with the **single sharpest, most defensible message**: *"Summarize your meetings on any phone — with no account, no subscription, and nothing leaving your device."* Every clause is a competitor's documented weakness (account → Samsung; subscription → Otter/Granola; data leaving device → Otter litigation/Plaud cloud).

### 6.2 Beachhead customers

| Segment | Why they switch | Evidence anchor |
|---|---|---|
| **Privacy-conscious prosumers (the Karpathy / HN / r/privacy crowd)** | Want fully-offline, one-time, no-telemetry tools; Karpathy publicly named the exact criteria | [Karpathy](https://x.com/karpathy/status/1889036923655860247) |
| **Android users locked out of Mac on-device tools** | MacWhisper/SuperWhisper/Aiko have no Android; Granola has no Android | gap analysis |
| **Galaxy owners who refuse a Samsung Account, or own a locked-out A-series** | Cannot summarize on stock OS at all | [Samsung](https://www.samsung.com/us/support/answer/ANS10004613/) |
| **Enterprises/universities banning notetaker bots** | Oxford, UW, Chapman, UC Riverside, Cornell block third-party bots; Teams/Zoom now auto-block external bots — an on-device, no-bot recorder is a sanctioned alternative | [Oxford](https://www.infosec.ox.ac.uk/article/are-your-online-meetings-safe-from-third-party-ai-bots), [UC Today](https://www.uctoday.com/security-compliance-risk/ai-meeting-bots-controls-microsoft-zoom-google/) |
| **Subscription-fatigued buyers** | Households actively cutting subs (4.1→2.8) and price-sensitive | [Self Financial](https://studyfinds.org/subscription-boom-bursting-streaming-food-delivey-americans-purge/) |

### 6.3 Why now

Three curves cross in 2026: **(1) NPU ubiquity** — GenAI phones go from 30% of shipments (2025) to 70% (2028), so the hardware to run on-device Whisper + a small LLM is becoming the default ([IDC](https://my.idc.com/getdoc.jsp?containerId=prUS52478124)); **(2) subscription fatigue** — measurable household sub-cutting ([Self Financial](https://studyfinds.org/subscription-boom-bursting-streaming-food-delivey-americans-purge/)); **(3) privacy/recording-consent backlash** — Otter/Fireflies litigation, bot bans, GDPR/biometric law, the $1.375B Google Texas settlement ([NPR](https://www.npr.org/2025/08/28/nx-s1-5519756/biometrics-facial-recognition-laws-privacy)). A product that is on-device + no-account + lifetime sits exactly at the intersection.

### 6.4 The unit-economics advantage (the load-bearing argument)

Lifetime pricing normally fails for AI because **revenue happens once but inference cost recurs**. Freemius documents the failure mode precisely: a $19 lifetime AI add-on lost 30% of revenue to its top 5% of users within three months, and one-time AI licensing "works only… where usage is bounded at the point of sale." ([Freemius](https://freemius.com/blog/ai-app-pricing-model/)) *(Verification flags those specific figures as single-source anecdotes from a vendor blog — but the underlying phenomenon of inference-cost concentration breaking flat/lifetime economics is independently well-corroborated.)*

**On-device compute is the structural fix.** Pushing Whisper + Gemma/Apple-FM summaries to the device makes marginal inference cost ≈ $0 — the on-device equivalent of "usage bounded at sale." This is empirically validated: **MacWhisper sustains a solo dev at ~$69 lifetime precisely because transcription is on-device** ([MacWhisper](https://www.getvoibe.com/resources/macwhisper-pricing/)). And it explains the contrast with the AppSumo lifetime-deal collapse (AppSumo revenue down ~50% over two years, confirmed directly by founder Noah Kagan): those products carried recurring *cloud/server* cost with no recurring revenue. ([Kagan/LinkedIn](https://www.linkedin.com/posts/noahkagan_appsumo-revenue-is-down-50-in-the-past-2-activity-7427012878395777024-0S4-)) Lifetime pricing fails when there's ongoing cloud cost; on-device compute removes it.

The small opt-in cloud-summary path is funded by **consumable top-up packs** (25/$2.99, 100/$9.99, 500/$39.99), an established pattern that pairs cleanly with a no-subscription base and segments by willingness-to-pay without gating core functionality.

---

## 7. Risks & Honest Counterarguments (the bear case)

| Risk | Steelman | Mitigation |
|---|---|---|
| **Commoditization** | Everyone ships "on-device transcription" — Apple, Samsung, MacWhisper, Aiko. Transcription is table stakes. | Recap's moat is the *combination* (meeting-first + cross-platform + no-account + lifetime + integrations + cross-meeting search), not transcription alone. Compete on the corpus, workflow, and privacy verifiability — none of which Apple/Samsung/Aiko offer. |
| **Distribution without ads or telemetry** | No analytics means no funnel optimization; no growth loops; privacy purists are a hard audience to reach at scale. | Lean into channels that *reward* the no-telemetry stance (HN, r/privacy, Product Hunt, privacy press), comparison landing pages, and the Karpathy-criteria narrative. Accept a narrower, higher-intent top-of-funnel. |
| **Lifetime revenue ceiling** | One-time revenue caps LTV; no recurring base to fund ongoing dev. AppSumo shows lifetime models can starve. | On-device = ~$0 marginal cost (the AppSumo failure was *cloud* cost, not pricing). Fund ongoing dev via tier upgrades, top-up packs, and grandfathered price increases for *new* buyers. |
| **Big-platform bundling** | Apple/Samsung bundle "good enough" summaries for free; most users won't pay $49 for marginally better. | Target the segments the platforms *exclude or gate*: Samsung's account requirement + A-series lockout + Galaxy-only; Apple's iPhone-only. Cross-platform + no-account is structurally un-bundleable by either. |
| **Model-size / storage friction** | Multi-GB model downloads (Gemma 4 E2B ~2.4 GB / E4B ~4.3 GB; Whisper) deter casual users on low-storage devices. | Tiered model sizes (tiny/small Whisper, E2B vs E4B), Apple Foundation Models where available (no download), download-on-first-summary, and clear progress/cancel UX. |
| **Diarization/quality vs cloud** | Cloud LLMs (Gemini, GPT) still produce better summaries than small on-device models. | Cloud is the *opt-in upgrade*, not the default; users who want max quality top up. On-device is "good and private"; cloud is "best, your choice." |

---

## 8. Go-to-Market & Positioning

**One-line positioning:** *"Recap is the meeting recorder that summarizes on-device on any phone — no account, no subscription, nothing leaves your device."*

**Messaging pillars (each maps to a competitor weakness):**
1. **No account, ever** → vs Samsung's account-gated Summary.
2. **Lifetime, not subscription** → vs Otter/Granola/Fathom/Fireflies monthly stacking.
3. **On-device by default; verifiable Privacy tier** → vs cloud rivals and the Otter litigation narrative.
4. **Works on every phone** → vs Galaxy-only / iPhone-only / no-Android tools.
5. **Meeting-first with the corpus** → vs single-purpose Mac transcribers.

**Launch channels (fit a no-telemetry product):**
- **Hacker News** — the Karpathy/SuperWhisper thread audience is the exact target; a Show HN leaning on "fully offline, one-time, no telemetry."
- **Reddit** — r/privacy, r/Android (the locked-out-of-Mac-tools crowd), r/degoogle, Galaxy/Samsung subs (the account-gripe audience).
- **Product Hunt** — prosumer productivity launch.
- **Privacy press / indie-Mac press** — the lineage that covered MacWhisper "never phones home."

**Comparison landing pages (high-intent SEO/conversion):**
- *"Recap vs Samsung Galaxy AI"* — lead with "no Samsung Account required" + the A-series lockout table.
- *"Recap vs Otter"* — lead with on-device + the all-party-consent/litigation angle.
- *"Recap vs Granola"* — "bot-free is not on-device" + "now with Android."
- *"Recap vs MacWhisper"* — "everything you love about MacWhisper, now meeting-first and on Android."

---

## 9. Pricing Validation

### 9.1 Does $49 / $69 / $99 + top-ups hold up?

**Yes.** Willingness-to-pay for pro-grade prosumer tools clusters at ~$49.99 one-time and extends to ~$99 lifetime. Confirmed anchors: **Things 3 $49.99** one-time, **CleanShot X $29** one-time, **MacWhisper $69 lifetime ($99.99 App Store lifetime IAP)**, **SuperWhisper $249.99 lifetime**. ([MacWhisper](https://www.getvoibe.com/resources/macwhisper-pricing/), [Things 3](https://apps.apple.com/us/app/things-3/id904280696), [CleanShot](https://cleanshot.com/pricing))

> *Honesty note:* the research's claim that "OmniFocus $49.99, Typinator $49.99" anchor the band was **refuted** — OmniFocus's one-time license is $74.99/$149.99 and Typinator is ~$30–$40. Things 3 ($49.99) and CleanShot ($29) are the verified one-time anchors, and MacWhisper ($69/$99.99) is the on-point category comparable. Recap's $49/$69/$99 ladder sits squarely in the validated band, *below* SuperWhisper's $249.99.

The $9.99 "sell-volume threshold" framing is also unverified; we don't rely on it. The relevant point stands: a $49–$99 price *signals a pro tool* and self-selects committed buyers.

### 9.2 Lifetime cost-of-ownership vs paying subscriptions

Annualized individual subscription spend, verified against official pricing pages (2026-06-03):

| Competitor | Annual cost | Recap break-even vs this sub |
|---|---|---|
| Otter Pro | ~$100/yr ([Otter](https://otter.ai/pricing)) | **Recap $49 ≈ 6 months; $99 ≈ 12 months** |
| Fireflies Pro | $120/yr ([Fireflies](https://fireflies.ai/pricing)) | $49 ≈ 5 mo; $99 ≈ 10 mo |
| Granola Business | ~$168/yr ([Granola](https://www.granola.ai/pricing)) | $49 ≈ 3.5 mo; $99 ≈ 7 mo |
| Read.ai Pro | $180/yr ([Read.ai](https://www.read.ai/plans-pricing)) | $49 ≈ 3 mo; $99 ≈ 7 mo |
| Fathom Premium | $192/yr ([Fathom](https://www.fathom.ai/pricing)) | $49 ≈ 3 mo; $99 ≈ 6 mo |
| tl;dv Pro | $216/yr ([tl;dv](https://tldv.io/app/pricing/)) | $49 ≈ 3 mo; $99 ≈ 5.5 mo |
| Jamie Pro | ~€470/yr (≈$505) ([Jamie](https://www.meetjamie.ai/pricing)) | $49 ≈ 1.2 mo; $99 ≈ 2.4 mo |

> *Honesty note:* the research's "Granola Individual ~$168/yr" and "Jamie Pro €564/yr" were corrected in verification — Granola's cheapest paid tier is **Business $14/mo** (no "Individual" plan), and Jamie Pro's official price is **€39/mo (€470/yr)**, not €47/€564. The corrected range of individual subscription spend is **~$100–$505/yr**.

**The takeaway is unchanged and strong:** a single Recap purchase of $49–$99 is recovered in **~3–12 months** versus *any* of these subscriptions — and then costs $0 forever, with no churn, no price hikes (existing buyers grandfathered), and no account. Against subscription fatigue (households actively cutting subs) and a confirmed "price increases are the #1 reason businesses lose customers" finding ([Recurly](https://recurly.com/research/churn-rate-benchmarks/)), the lifetime model is the right counter-positioning.

---

## 10. Appendix: Sources & Confidence Notes

### 10.1 Source list (by theme)

**Samsung / Galaxy AI**
- https://www.samsung.com/sg/support/mobile-devices/how-to-use-transcribe-assist-on-the-galaxy-s24/
- https://www.samsung.com/us/galaxy-ai/
- https://www.samsung.com/us/support/answer/ANS10004613/ (A-series exclusion)
- https://www.samsung.com/us/support/answer/ANS10000942/ (OS floor)
- https://www.samsung.com/us/support/answer/ANS10000753/ (device support)
- https://news.samsung.com/global/your-privacy-secured-how-galaxy-ai-empowers-you-to-take-control-of-your-data
- https://www.androidauthority.com/samsung-galaxy-ai-features-free-3632510/
- https://www.phonearena.com/news/galaxy-ai-policy-changes_id177350

**Cloud meeting-AI competitors**
- https://otter.ai/pricing · https://www.npr.org/2025/08/15/g-s1-83087/otter-ai-transcription-class-action-lawsuit · https://natlawreview.com/article/take-note-new-wave-privacy-litigation-targets-ai-notetaker-otterai
- https://www.granola.ai/pricing · https://www.granola.ai/security
- https://www.fathom.ai/pricing · https://techcrunch.com/2026/04/15/fathom-adds-a-bot-less-meeting-mode-in-a-bid-to-take-on-granola/
- https://fireflies.ai/pricing · https://www.workplaceprivacyreport.com/2026/04/articles/artificial-intelligence/ai-meeting-assistants-and-biometric-privacy-governance-lessons-from-the-fireflies-ai-lawsuit/
- https://www.meetjamie.ai/pricing · https://tldv.io/app/pricing/ · https://www.read.ai/plans-pricing · https://sonix.ai/resources/notta-pricing/

**On-device / lifetime tools**
- https://www.getvoibe.com/resources/macwhisper-pricing/ · https://goodsnooze.gumroad.com/l/macwhisper
- https://superwhisper.com/ · https://apps.apple.com/us/app/aiko/id1672085276
- https://www.plaud.ai/pages/plaud-ai-plan-pricing · https://techcrunch.com/2025/12/05/meta-acquires-ai-device-startup-limitless/
- https://x.com/karpathy/status/1889036923655860247 (the Karpathy criteria)

**Market size & macro trends**
- https://www.grandviewresearch.com/industry-analysis/ai-meeting-assistant-market-report
- https://www.marketsandmarkets.com/Market-Reports/speech-voice-recognition-market-202401714.html
- https://www.grandviewresearch.com/industry-analysis/speech-to-text-api-market-report
- https://my.idc.com/getdoc.jsp?containerId=prUS52478124 · https://www.gartner.com/en/newsroom/press-releases/2025-09-09-gartner-says-worldwide-generative-artificial-intelligence-smartphone-end-user-spending-to-total-us-dollars-298-billion-by-the-end-of-2025
- https://gs.statcounter.com/os-market-share/mobile/worldwide · https://9to5mac.com/2026/02/10/iphone-now-accounts-for-nearly-one-in-four-active-smartphones-worldwide-report/

**Regulatory / privacy / pricing strategy**
- https://www.recordinglaw.com/us-laws/ai-meeting-recording-laws/ · https://www.npr.org/2025/08/28/nx-s1-5519756/biometrics-facial-recognition-laws-privacy · https://www.texasattorneygeneral.gov/news/releases/attorney-general-ken-paxton-finalizes-historic-settlement-google-and-secures-1375-billion-big-tech
- https://www.infosec.ox.ac.uk/article/are-your-online-meetings-safe-from-third-party-ai-bots · https://www.uctoday.com/security-compliance-risk/ai-meeting-bots-controls-microsoft-zoom-google/
- https://freemius.com/blog/ai-app-pricing-model/ · https://recurly.com/research/churn-rate-benchmarks/ · https://studyfinds.org/subscription-boom-bursting-streaming-food-delivey-americans-purge/ · https://adapty.io/blog/productivity-app-subscription-benchmarks/

### 10.2 Confidence notes — what's confirmed vs uncertain vs refuted

**High-confidence / confirmed (load-bearing claims):**
- Samsung AI Summary **requires a Samsung Account** (verbatim, official) — and the requirement extended to all Galaxy AI incl. on-device features in 2026.
- A-series (A56/A36/A26/A17) excluded from Transcript Assist (substance confirmed; correct cite is ANS10004613).
- Otter faces **four consolidated federal class actions**; Fireflies faces **Illinois BIPA** voiceprint suits.
- Karpathy's offline/no-telemetry/one-time criteria — verbatim primary source confirmed.
- All competitor pricing in §9 re-verified against official pages (with Granola/Jamie corrected).
- Market sizes: AI meeting assistant $3.47B→$21.48B @25.8% (GVR, triangulated); speech & voice $8.49B→$23.11B @19.1% (MarketsandMarkets); GenAI smartphones 30%→70% of shipments (IDC); $298.2B GenAI spend (Gartner).
- MacWhisper one-time on-device model is sustainable; AppSumo revenue down ~50% (Kagan, primary).

**Uncertain (used with hedges or directional only):**
- Samsung transcription/diarization accuracy percentages (87%/76%; 95/80/55) — **unsourced AI-content; not cited as fact.**
- Subscription-fatigue percentages — direction confirmed via Self Financial/Deloitte/Recurly; the specific "47%/31% Zuora" and "41%/35%" figures **refuted/conflated** and excluded.
- MacWhisper "~300,000 copies" — secondary-sourced, may conflate downloads with sales; treated as directional.
- Freemius $19-add-on / 8%-of-customers figures — single-source vendor anecdotes; underlying phenomenon independently corroborated.

**Refuted (corrected in-line above; not relied upon):**
- "~4.7–4.8B active smartphones" → actually ~7.3–7.6B devices / ~5.8B users.
- Android "72.8%" → 71.90% (Nov 2025).
- "12 all-party states **+ DC**" → DC is **one-party**; ~12–13 all-party states.
- Otter "15M users" → **35M+** (Otter's own 2025 release).
- SuperWhisper lifetime "$849 hike" → **refuted** (single competitor blog); actual lifetime $249.99.
- Granola "Individual ~$168/yr" → no Individual plan; Business $14/mo. Jamie "Pro €47/€564" → €39/€470.
- "OmniFocus/Typinator $49.99" price anchors → incorrect; Things 3 ($49.99) and CleanShot ($29) are the verified anchors.
- Fathom iOS/Windows apps "launched April 15, 2026" → announced as coming soon, not shipped.
