# Recap Browser Extension

Chrome / Edge / Firefox Manifest V3 extension that captures audio from the active tab and relays it to the user's Recap desktop install. **No meeting bot joins the call** — the user is already in the call, we just record what their browser tab is already playing.

## Why a browser extension instead of a meeting bot

Compared to Otter/Fathom/Fireflies bots:
- No third party joins the participants list
- No "Recap is recording" notification to other participants
- No invite-the-bot setup flow
- Same legal posture as the user recording themselves (one-party consent)

## Architecture

```
┌──────────────────────────┐         ┌─────────────────────┐
│ Browser tab (Zoom/Meet/  │         │ Recap desktop app   │
│  Teams call in progress) │         │ (Mac / Win)         │
└──────────┬───────────────┘         └──────────▲──────────┘
           │ tabCapture API                     │
           ▼                                    │
┌──────────────────────────┐  WebSocket         │
│ Extension service worker │──────────────────► │
│ (background.js)          │  ws://localhost:7474
└──────────┬───────────────┘                    │
           │ chrome.runtime.sendMessage         │
           ▼                                    │
┌──────────────────────────┐                    │
│ Side panel (live captions)│◄─────────────────┘
└──────────────────────────┘  desktop relays captions back
```

When the desktop app isn't running (or isn't reachable), the extension buffers audio in `chrome.storage.local` and flushes when the desktop comes online.

## Files

- `manifest.json` — Manifest V3, scoped permissions
- `src/background.js` — service worker; tab audio capture + WebSocket relay
- `src/popup.html` + `popup.js` — toolbar popup with record / stop
- `src/sidepanel.html` + `sidepanel.js` — Chrome side panel with live captions
- `icons/` — 16/32/48/128 px icons (TODO: generate from app icon)

## Privacy

Zero network calls outside:
- `ws://localhost:7474/recap` (or user-configured URL) — the desktop Recap install
- Tab content being recorded (which is the user's choice)

No analytics, no telemetry, no third-party scripts. The `host_permissions` in the manifest scope to Meet/Zoom/Teams *for UI context only* (so we can show "Record this meeting?" prompts) — no data is sent to those hosts.

## Build / load

Development:
```
# Chrome:  chrome://extensions/ → Load unpacked → select this folder
# Firefox: about:debugging#/runtime/this-firefox → Load Temporary Add-on → manifest.json
```

Production: stub for now. Will add `package.json` + `npm run build` once we have a real bundler (likely Vite or plain esbuild). The current code is hand-rolled vanilla JS so no bundling is strictly needed.

## Distribution

- Chrome Web Store
- Microsoft Edge Add-ons
- Mozilla AMO (Firefox)
- Direct download from recapfreenote.com for users who don't want to go through the stores

## Known TODOs

- Bundle a tiny Whisper WASM build (~75 MB) for in-extension live captions when desktop isn't reachable
- Generate proper icons (currently placeholder)
- Add `options_page` for the WebSocket URL setting + license-key pairing
- Test thoroughly on Firefox (MV3 quirks)
- Reject DRM-protected streams gracefully (Netflix, Spotify, paid courses)
