# Where Recap genuinely loses (be honest)

> This is the bear case. Mitigations and the steelman are tracked in `docs/MARKET_ANALYSIS.md` §7.
> Keep this list honest — if a gap closes, move it to the changelog; don't quietly delete it.

1. **No meeting bot.** Otter, Fathom, Fireflies, Read.ai can join Zoom/Meet/Teams calls as a
   participant and capture every speaker cleanly. Recap only hears what the mic (or, on desktop,
   system audio) picks up. For remote-only knowledge workers on calls all day, this is a real gap.
   *Counter:* it's also the privacy/consent selling point — no third party in the call. Many
   enterprises and universities are now banning notetaker bots (see MARKET_ANALYSIS §6.2), which
   turns this gap into a wedge for that segment. On mobile, bot-capture is structurally impossible.

2. **Mobile-first is also a limitation.** Granola is Mac/Win, Otter is web, Jamie is Mac/Win.
   Lots of meeting culture lives on laptops. Desktop (macOS + Windows) + a browser extension are in
   scope for the product, but mobile is where we lead — and where the privacy-conscious, no-account,
   cross-platform story is strongest.

3. **No team features.** Otter / Granola / Fathom offer sharing, comments, assigned action items.
   Recap is single-player. Enterprise/team collaboration is out of scope for v1.

4. **First-launch friction is high.** Voice Memos works instantly. Recap bundles Whisper tiny.en so
   live captions work immediately, but the better Whisper (~140 MB), on-device summary model
   (Gemma 4 E2B ~2.4 GB), and Pyannote diarization (~80 MB) download before all features work.
   A stellar onboarding flow is the mitigation, or users bounce before reaching the moat.

5. **Reputation / track record = 0.** Otter has a decade. Granola is a YC darling with millions of
   users. SuperWhisper has Karpathy's public endorsement. We start from nothing — trust takes time.

6. **Lifetime sustainability question.** Lifetime pricing fails when there's ongoing per-user *cloud*
   cost with no recurring revenue (AppSumo's lifetime-deal revenue fell ~50% over two years, per
   founder Noah Kagan). The fix is structural: Recap pushes Whisper + Gemma/Apple-FM **on-device**,
   so marginal cost ≈ $0 — the same reason MacWhisper sustains a solo dev at ~$69 lifetime. The only
   recurring cost is the opt-in cloud-summary path, funded by tier quotas + one-time top-up packs.
   (Note: the often-repeated "SuperWhisper raised lifetime $249→$849" claim is **false** — verified;
   SuperWhisper's lifetime price is $249.99.) Current prices: **Pro $49 / Power $99**. If cloud
   quotas (5/100 per month) get abused or expanded, revisit pricing — that's the thing to watch.

7. **Community/open models vs big-tech research.** Apple's ASR has ~15 years of refinement; Samsung
   has Samsung Research. We ship open models (Whisper, Pyannote, Gemma) — excellent, but a
   coordinated big-tech effort can outpace us on raw accuracy. We compete on the product (meeting
   corpus, workflow, privacy verifiability), not on out-researching Apple on ASR.

8. **Battery impact.** Running Whisper + Gemma 4 + Pyannote across a 1-hour meeting drains battery
   faster than Apple's NPU-optimized native pipeline. Real impact on perception — mitigate with
   tiered model sizes, native ASR where available, and clear progress/cancel UX.
