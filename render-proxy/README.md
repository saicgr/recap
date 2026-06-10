# Recap Render Proxy

Tiny Express server deployed on [Render](https://render.com) that proxies cloud summary calls from the Recap app to Google Gemini 3.1 Flash Lite.

## Why this exists

Recap's app never holds the Gemini API key. When a user taps "Cloud summary," the app sends the transcript + persona to this proxy, the proxy adds the Gemini key from its environment, calls Gemini, and streams the response back. App stays key-free; CLAUDE.md's Karpathy invariant holds.

## Endpoints

- `POST /summarize` — body `{transcript, persona, installToken}` → SSE stream of summary tokens.
- `POST /summarize-byok` — Power-tier BYOK path. Body includes the user's own Gemini key in an encrypted blob; proxy forwards but does not store. We hold zero keys in this path.
- `GET /health` — Render uptime probe.

## Security

- `GEMINI_API_KEY` lives in Render's dashboard env vars (not in code, not in git).
- Per-IP rate limiting via `express-rate-limit` — 60 req/h for unauth, 600 for authed Free+.
- Daily budget cap tracked in Upstash Redis (Render add-on) — falls over to "service unavailable" before billing surprises.
- CORS restricts origins to the app's bundle ID.
- No request logging beyond IP + timestamp. Transcripts never persisted to disk.

## Deployment

```sh
# One-time: link this dir to a Render service
render deploy
```

`render.yaml` declares the service spec; Render auto-deploys on push to `main`.

## Files

- `package.json` — Node 22 + Express + @google/genai
- `render.yaml` — service spec (instance type, env vars, health check path)
- `src/server.ts` — Express setup + routes
- `src/rate_limit.ts` — per-IP + per-day caps
- `src/gemini.ts` — Gemini SDK wrapper, streaming bridge

## Status

**Scaffolding only.** This directory has the README + .yaml declarations; the TypeScript source lives in a sibling repo (`recap-proxy`) that we'll mirror here once the deploy pipeline is dialed in.
