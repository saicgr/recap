# Recap — Changelog

> Architectural / rule / spec / positioning decisions, newest first.
> Format: **Decision / Why / Updated / Origin** (see `.claude/skills/changelog-curator/SKILL.md`).
> Never edit a historical entry — append a superseding entry instead.

## 2026-06-03 — Surface differentiation in-app + sync strategy docs

- **Decision:** Added a capability-framed "What makes Recap different" screen (`lib/screens/compare_screen.dart`), wired from Settings → About and via a "Why Recap?" link on the paywall; sharpened onboarding (added the "no background pings" pillar) and the Help FAQ (added a no-competitor-named positioning Q&A). Synced `CLAUDE.md`, `docs/TIERS.md`, and `TODO/roadmap.md` with the verified research and corrected stale/refuted facts.
- **Why:** The app previously surfaced zero differentiation; the verified market analysis identified the moat as the *combination* (no-account + cross-platform + on-device + lifetime), and the no-competitor-named framing keeps the understated, Karpathy-minimalist brand intact. Corrected facts prevent shipping confidently-wrong numbers: removed the dropped Free+/Starter tier references, fixed the Granola payback price (~$14/mo → ~7 months, not "$20/mo → 5 months"), and removed the **refuted** "SuperWhisper $249→$849" claim and the stale $39/$79 prices ($49/$99 actual).
- **Updated:** `lib/screens/compare_screen.dart` (new), `lib/screens/settings_screen.dart §_aboutGroup`, `lib/screens/paywall_screen.dart` (Why-Recap link), `lib/screens/onboarding_screen.dart §_privacyPitch`, `lib/screens/help_screen.dart §_faqs`, `CLAUDE.md §Positioning`, `docs/TIERS.md` (intro, top-ups, pricing rationale), `TODO/roadmap.md`.
- **Origin:** User request — "document all this and also update the app accordingly" (scope confirmed via AskUserQuestion: comparison screen + understated/unnamed tone + sync all docs).

## 2026-06-03 — Added source-cited market analysis & business case

- **Decision:** Created `docs/MARKET_ANALYSIS.md` — TAM/SAM/SOM sizing, a 12-product competitive table, the Samsung-Account/device-lockout deep-dive, a 10-pillar moat, the build case, an honest bear case, GTM, and pricing validation — produced by a fan-out research workflow with an adversarial verification pass (108 claims re-checked; 73 confirmed, 20 refuted, 15 uncertain).
- **Why:** The "is there a market, and how do we differentiate vs Samsung Voice Recorder AI etc." question needed an evidence base, not assertion. The verification pass is the integrity firewall — refuted figures (e.g., fabricated subscription-fatigue stats, wrong Android share, a device-count conflation) are flagged inline rather than relied on.
- **Updated:** `docs/MARKET_ANALYSIS.md` (new).
- **Origin:** User request — "Can you see if there is a market for this app especially with samsung voice recorder AI etc?"
