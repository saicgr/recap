# recap-worker

Cloudflare Worker proxy for cloud summaries. Sits between the Recap app and Gemini 3.1 Flash Lite so the Gemini API key never ships in the app binary.

## Deploy

```bash
npm install
npx wrangler login                 # once
npx wrangler kv:namespace create recap-rate-limit
# paste the returned id into wrangler.toml

npx wrangler secret put GEMINI_API_KEY
npx wrangler secret put INSTALL_TOKEN_PEPPER  # any 32+ char random string

npm run deploy
```

Note the deployed URL (e.g. `https://recap-worker.<account>.workers.dev`) and put it in the Flutter app's `CloudBackend(workerUrl: ...)`.

## What goes over the wire

The app sends:
- `Authorization: Bearer <install_token>` (64-hex token, per install)
- JSON body: `{persona_key, prompt, transcript}`

The Worker validates the token, rate-limits per token (60/hr), forwards to Gemini, returns `{text, model_id}`. **No audio is ever sent — only the text transcript.**

## What this Worker does NOT do

- No user accounts, no email collection, no analytics — by design.
- No persistence of transcripts. KV is used only for hourly per-token rate-limit counters (60 buckets max per install per day, auto-expire).
- No CORS — the Recap app is the only client.
