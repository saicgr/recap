// Recap Render proxy — the app's single backend keyholder.
//
// The app never holds the Gemini (or later Deepgram/R2) key. Requests come in
// authenticated with an install token = HMAC(installId, PEPPER); this server
// attaches the secret and forwards upstream. It replaces the Cloudflare Worker,
// whose isValidInstallToken() accepted ANY 64-hex string (an open proxy to a
// billed key). See render-proxy/README.md and ~/.claude/plans for the program.
//
// Wave 0 routes: GET /health, POST /v1/register, POST /v1/summarize.
// Future waves add /v1/transcribe (Deepgram), /v1/chat, /v1/r2/presign, OAuth.

import express from 'express';
import cors from 'cors';
import {
  requireInstallAuth,
  issueToken,
  INSTALL_ID_RE,
  type AuthedRequest,
} from './auth';
import { HourlyRateLimiter, DailyBudget } from './budget';
import { summarizeWithGemini, GEMINI_MODEL_ID, UpstreamError } from './gemini';
import { transcribeStream, DeepgramError, DG_MODEL } from './deepgram';
import { isLedgerConfigured } from './db';
import { reserve, settle, refund, remaining, QuotaExceeded } from './ledger';

/** Read a required secret or refuse to boot — never run a keyholder unconfigured. */
function requireEnv(name: string): string {
  const v = process.env[name];
  if (!v || !v.trim()) {
    console.error(`FATAL: required env ${name} is not set`);
    process.exit(1);
  }
  return v;
}

const GEMINI_API_KEY = requireEnv('GEMINI_API_KEY');
const PEPPER = requireEnv('INSTALL_TOKEN_PEPPER');

// Deepgram is OPTIONAL: cloud transcription is an opt-in upgrade, so the server
// must still boot (and summaries must still work) without a key. The route
// reports 503 "not configured" rather than the process refusing to start.
const DEEPGRAM_API_KEY = process.env.DEEPGRAM_API_KEY?.trim() ?? '';

// Nova-3 batch list price. Used only to charge the daily circuit breaker; the
// authoritative per-request duration comes back from Deepgram itself.
const DEEPGRAM_USD_PER_MIN = parseFloat(process.env.DEEPGRAM_USD_PER_MIN ?? '0.0043');

// Monthly per-install allowance. Deliberately modest: Recap is a ONE-TIME
// purchase, so every cloud minute is a permanent liability against a payment we
// already banked. Real per-tier quotas need store-receipt validation (a receipt
// is anonymous, so it does not break "no account required").
const FREE_AUDIO_SECONDS_PER_MONTH = parseInt(
  process.env.FREE_AUDIO_SECONDS_PER_MONTH ?? '1800', // 30 minutes
  10,
);

// Hard ceiling per request. An 8-hour upload is almost certainly a mistake or an
// attack, and we would rather 413 than silently bill for it.
const MAX_AUDIO_SECONDS = parseInt(process.env.MAX_AUDIO_SECONDS ?? '14400', 10); // 4h

const PORT = parseInt(process.env.PORT ?? '10000', 10);
const AUTH_PER_HOUR = parseInt(process.env.RATE_LIMIT_AUTH_PER_HOUR ?? '600', 10);
const UNAUTH_PER_HOUR = parseInt(process.env.RATE_LIMIT_UNAUTH_PER_HOUR ?? '60', 10);
const DAILY_BUDGET_USD = parseFloat(process.env.DAILY_BUDGET_USD ?? '10');
// Rough per-summary cost for the circuit breaker (safety backstop, not billing).
// Flash Lite is cheap: a few k input + ~2k output is well under a cent.
const EST_COST_PER_SUMMARY_USD = parseFloat(
  process.env.EST_COST_PER_SUMMARY_USD ?? '0.005',
);

const app = express();
// Native mobile clients send no Origin, so CORS is permissive — the real gate
// is the install token, not the browser same-origin policy.
app.use(cors());
app.use(express.json({ limit: '4mb' })); // transcripts are large but plain text

const perInstall = new HourlyRateLimiter(AUTH_PER_HOUR);
const perIp = new HourlyRateLimiter(UNAUTH_PER_HOUR);
const budget = new DailyBudget(DAILY_BUDGET_USD);

const sweep = setInterval(() => {
  perInstall.sweep();
  perIp.sweep();
}, 600_000);
sweep.unref();

function clientIp(req: express.Request): string {
  const xff = req.header('x-forwarded-for');
  return (xff ? xff.split(',')[0].trim() : req.ip) || 'unknown';
}

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'recap-proxy',
    budgetSpentUsd: Number(budget.spent.toFixed(4)),
    budgetCapUsd: DAILY_BUDGET_USD,
  });
});

// Hand out an install token = HMAC(installId, PEPPER). Open by design (no
// account required to summarize), so it is hard per-IP rate-limited and the
// real cost backstop is the daily budget. This is a handshake, not an
// authorization.
app.post('/v1/register', (req, res) => {
  if (!perIp.hit(`reg:${clientIp(req)}`)) {
    res.status(429).json({ error: 'rate limited' });
    return;
  }
  const installId = String(req.body?.install_id ?? '').trim();
  if (!INSTALL_ID_RE.test(installId)) {
    res.status(400).json({ error: 'install_id must be 16-128 url-safe chars' });
    return;
  }
  res.json({ token: issueToken(installId, PEPPER), model_hint: GEMINI_MODEL_ID });
});

app.post(
  '/v1/summarize',
  requireInstallAuth(PEPPER),
  async (req: AuthedRequest, res) => {
    const installId = req.installId!;
    if (!perInstall.hit(`sum:${installId}`)) {
      res.status(429).json({ error: 'rate limited' });
      return;
    }
    if (!budget.canSpend(EST_COST_PER_SUMMARY_USD)) {
      res
        .status(503)
        .json({ error: 'daily budget exhausted; try later or use on-device' });
      return;
    }

    const prompt = req.body?.prompt;
    const transcript = req.body?.transcript;
    if (
      typeof prompt !== 'string' ||
      typeof transcript !== 'string' ||
      !prompt.trim() ||
      !transcript.trim()
    ) {
      res.status(400).json({ error: 'prompt + transcript required' });
      return;
    }

    try {
      const { text } = await summarizeWithGemini(GEMINI_API_KEY, prompt, transcript);
      budget.record(EST_COST_PER_SUMMARY_USD);
      res.json({ text, model_id: GEMINI_MODEL_ID });
    } catch (err) {
      if (err instanceof UpstreamError) {
        res.status(502).json({ error: err.message, detail: err.detail });
        return;
      }
      console.error('summarize error', err);
      res.status(500).json({ error: 'internal error' });
    }
  },
);

// ---------------------------------------------------------------------------
// Cloud transcription (Deepgram Nova-3). OPT-IN and metered.
//
// On-device Whisper remains the default and the only always-available path;
// this route exists solely for the user who explicitly turns on "Cloud
// transcription" in Settings and then taps "Improve this transcript" on a
// specific meeting. It is never called implicitly.
//
// The Privacy tier can never reach this: the client never constructs the
// Deepgram engine. That is a client-side structural guarantee, so we ALSO
// enforce a server-side quota here — defence in depth, and the only thing that
// actually protects the bill.
//
// NOTE: no express.json() runs on this path. The client sends audio with
// Content-Type: audio/flac (or audio/wav), which the JSON parser ignores,
// leaving `req` readable so we can stream it straight to Deepgram.
// ---------------------------------------------------------------------------
app.post(
  '/v1/transcribe',
  requireInstallAuth(PEPPER),
  async (req: AuthedRequest, res) => {
    const installId = req.installId!;

    if (!DEEPGRAM_API_KEY) {
      res.status(503).json({ error: 'cloud transcription is not configured' });
      return;
    }
    if (!isLedgerConfigured()) {
      // Fail closed. Running an unmetered per-minute paid API against a
      // one-time-purchase product is how the business dies.
      res.status(503).json({ error: 'metering unavailable; refusing to spend' });
      return;
    }
    if (!perInstall.hit(`dg:${installId}`)) {
      res.status(429).json({ error: 'rate limited' });
      return;
    }

    const contentType = req.header('content-type') ?? '';
    if (!/^audio\//i.test(contentType)) {
      res.status(415).json({ error: 'body must be audio/* (flac or wav)' });
      return;
    }

    // The client tells us how long its audio is so we can hold quota BEFORE
    // spending. It is not trusted: we settle against Deepgram's own duration.
    const claimedSeconds = Number(req.header('x-audio-duration-seconds') ?? '0');
    if (!Number.isFinite(claimedSeconds) || claimedSeconds <= 0) {
      res.status(400).json({ error: 'X-Audio-Duration-Seconds required (> 0)' });
      return;
    }
    if (claimedSeconds > MAX_AUDIO_SECONDS) {
      res.status(413).json({
        error: `recording too long (${Math.round(claimedSeconds / 60)} min); max ${MAX_AUDIO_SECONDS / 60} min`,
      });
      return;
    }

    const estUsd = (claimedSeconds / 60) * DEEPGRAM_USD_PER_MIN;
    if (!budget.canSpend(estUsd)) {
      res.status(503).json({ error: 'daily budget exhausted; try later or use on-device' });
      return;
    }

    let reservation;
    try {
      reservation = await reserve(installId, claimedSeconds, FREE_AUDIO_SECONDS_PER_MONTH);
    } catch (err) {
      if (err instanceof QuotaExceeded) {
        res.status(402).json({
          error: 'monthly cloud-transcription quota exhausted',
          used_seconds: err.usedSeconds,
          limit_seconds: err.limitSeconds,
        });
        return;
      }
      console.error('reserve failed', err);
      res.status(500).json({ error: 'could not reserve quota' });
      return;
    }

    const language = req.header('x-language') || undefined;
    const keyterms = (req.header('x-keyterms') ?? '')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean)
      .slice(0, 100);

    try {
      const result = await transcribeStream(DEEPGRAM_API_KEY, req, {
        contentType,
        language,
        keyterms,
      });
      // True the hold up to Deepgram's authoritative duration, then charge.
      await settle(installId, reservation, result.durationSeconds);
      budget.record((result.durationSeconds / 60) * DEEPGRAM_USD_PER_MIN);

      res.json({
        transcript: result.transcript,
        words: result.words,
        duration_seconds: result.durationSeconds,
        model_id: result.modelId,
        detected_language: result.detectedLanguage,
        remaining_seconds: await remaining(installId, FREE_AUDIO_SECONDS_PER_MONTH),
      });
    } catch (err) {
      // The user must not pay for our failure.
      await refund(installId, reservation).catch((e) =>
        console.error('refund failed', e),
      );
      if (err instanceof DeepgramError) {
        res.status(502).json({ error: err.message, detail: err.detail });
        return;
      }
      console.error('transcribe error', err);
      res.status(500).json({ error: 'internal error' });
    }
  },
);

/** Remaining cloud-transcription seconds, so the client can show a balance. */
app.get('/v1/quota', requireInstallAuth(PEPPER), async (req: AuthedRequest, res) => {
  if (!isLedgerConfigured()) {
    res.status(503).json({ error: 'metering unavailable' });
    return;
  }
  try {
    res.json({
      remaining_seconds: await remaining(req.installId!, FREE_AUDIO_SECONDS_PER_MONTH),
      limit_seconds: FREE_AUDIO_SECONDS_PER_MONTH,
      model_id: DG_MODEL,
    });
  } catch (err) {
    console.error('quota error', err);
    res.status(500).json({ error: 'internal error' });
  }
});

app.use((_req, res) => res.status(404).json({ error: 'not found' }));

app.listen(PORT, () => {
  console.log(
    `recap-proxy on :${PORT} — daily budget cap $${DAILY_BUDGET_USD}, ` +
      `auth ${AUTH_PER_HOUR}/h, register ${UNAUTH_PER_HOUR}/h/IP`,
  );
});

export { app };
