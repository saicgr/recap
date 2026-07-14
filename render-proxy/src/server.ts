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
import {
  summarizeWithGemini,
  clampOutputTokens,
  GEMINI_MODEL_ID,
  MAX_OUTPUT_TOKENS,
  UpstreamError,
} from './gemini';
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

// Floor for the per-summary circuit-breaker charge (safety backstop, not
// billing). Raised 0.005 -> 0.02 by the summarizer rebuild: the single-pass
// prompt now asks for up to 8192 output tokens instead of 2048, and output is
// the expensive half. A guard that under-counts is not a guard.
//
// NOTE: render.yaml pins EST_COST_PER_SUMMARY_USD in the service env, which
// OVERRIDES this default in production. It has been raised to "0.02" to match;
// keep the two in step, or the pin silently reinstates the old under-count.
// Independently of the floor, estimateSummaryCostUsd() below prices each request
// from its actual size, so a large request can never be charged as if it were
// small.
const EST_COST_PER_SUMMARY_USD = parseFloat(
  process.env.EST_COST_PER_SUMMARY_USD ?? '0.02',
);

// Gemini 3.1 Flash Lite list price, USD per 1M tokens. Used ONLY to size the
// daily circuit breaker; nothing here bills a user.
const GEMINI_USD_PER_M_INPUT = parseFloat(process.env.GEMINI_USD_PER_M_INPUT ?? '0.10');
const GEMINI_USD_PER_M_OUTPUT = parseFloat(
  process.env.GEMINI_USD_PER_M_OUTPUT ?? '0.40',
);

// A system instruction is the anti-hallucination preamble + glossary: ~600
// tokens today, ~2 KB of text. 16 KB leaves generous headroom for a long
// glossary while still refusing an attempt to smuggle a novel through it.
const MAX_SYSTEM_INSTRUCTION_CHARS = parseInt(
  process.env.MAX_SYSTEM_INSTRUCTION_CHARS ?? '16384',
  10,
);

/**
 * Price a summarize request from what it actually asks for, floored at
 * EST_COST_PER_SUMMARY_USD. The chars/3.6 ratio matches the app's deliberately
 * pessimistic token_estimator.dart — over-estimating costs us a little daily
 * headroom; under-estimating costs money.
 */
function estimateSummaryCostUsd(inputChars: number, maxOutputTokens: number): number {
  const inputTokens = Math.ceil(inputChars / 3.6);
  const usd =
    (inputTokens / 1_000_000) * GEMINI_USD_PER_M_INPUT +
    (maxOutputTokens / 1_000_000) * GEMINI_USD_PER_M_OUTPUT;
  return Math.max(EST_COST_PER_SUMMARY_USD, usd);
}

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

// ---------------------------------------------------------------------------
// Cloud summaries (Gemini). OPT-IN, and structurally unreachable on the Privacy
// tier — the client never constructs a CloudBackend there. This route is the
// ONLY network call the app makes for a summary.
//
// Request (all fields optional except `prompt`):
//   prompt              string  — the instruction, or, for the rebuilt client,
//                                 the whole composed single-pass prompt.
//   transcript          string  — legacy split form; appended under "Transcript:".
//                                 Omit it when `prompt` already contains the
//                                 transcript. At least one of the two must carry it.
//   system_instruction  string  — anti-hallucination preamble + glossary.
//   max_output_tokens   number  — clamped to [256, 8192]; defaults to 2048.
//   persona_key         string  — accepted and ignored; the client composes the
//                                 persona lens into `prompt` itself.
//
// Response: { text, model_id, truncated? }. `truncated` is additive; clients
// that predate it ignore it.
// ---------------------------------------------------------------------------
app.post(
  '/v1/summarize',
  requireInstallAuth(PEPPER),
  async (req: AuthedRequest, res) => {
    const installId = req.installId!;
    if (!perInstall.hit(`sum:${installId}`)) {
      res.status(429).json({ error: 'rate limited' });
      return;
    }

    const prompt = req.body?.prompt;
    // Legacy clients send prompt + transcript separately. The rebuilt client
    // composes the transcript into the prompt (its SummaryBackend.generate()
    // takes one prompt string), so `transcript` may be absent or empty — but
    // one of the two must actually carry the meeting, hence the prompt check.
    const rawTranscript = req.body?.transcript;
    if (typeof prompt !== 'string' || !prompt.trim()) {
      res.status(400).json({ error: 'prompt required' });
      return;
    }
    if (
      rawTranscript !== undefined &&
      rawTranscript !== null &&
      typeof rawTranscript !== 'string'
    ) {
      res.status(400).json({ error: 'transcript must be a string' });
      return;
    }
    const transcript = typeof rawTranscript === 'string' ? rawTranscript : '';

    const rawSystem = req.body?.system_instruction;
    if (rawSystem !== undefined && rawSystem !== null && typeof rawSystem !== 'string') {
      res.status(400).json({ error: 'system_instruction must be a string' });
      return;
    }
    const systemInstruction = typeof rawSystem === 'string' ? rawSystem.trim() : '';
    if (systemInstruction.length > MAX_SYSTEM_INSTRUCTION_CHARS) {
      res.status(400).json({
        error: `system_instruction too long (max ${MAX_SYSTEM_INSTRUCTION_CHARS} chars)`,
      });
      return;
    }

    const rawMaxOut = req.body?.max_output_tokens;
    if (
      rawMaxOut !== undefined &&
      rawMaxOut !== null &&
      (typeof rawMaxOut !== 'number' || !Number.isFinite(rawMaxOut))
    ) {
      res.status(400).json({ error: 'max_output_tokens must be a number' });
      return;
    }
    // Out-of-range is clamped rather than rejected: a client asking for more
    // than we allow should still get its summary, just a shorter one.
    const maxOutputTokens = clampOutputTokens(
      typeof rawMaxOut === 'number' ? rawMaxOut : undefined,
    );

    // Priced AFTER validation so the charge reflects the real request size —
    // an 8192-token single pass over a 3-hour transcript is not the same spend
    // as the old 2048-token 4-section template.
    const estUsd = estimateSummaryCostUsd(
      prompt.length + transcript.length + systemInstruction.length,
      maxOutputTokens,
    );
    if (!budget.canSpend(estUsd)) {
      res
        .status(503)
        .json({ error: 'daily budget exhausted; try later or use on-device' });
      return;
    }

    try {
      const { text, truncated } = await summarizeWithGemini(
        GEMINI_API_KEY,
        prompt,
        transcript,
        { system: systemInstruction, maxOutputTokens },
      );
      budget.record(estUsd);
      if (truncated) {
        // Never pass a cut-off summary off as a complete one.
        console.warn(
          `summarize hit maxOutputTokens (${maxOutputTokens}) for install ${installId}`,
        );
      }
      res.json({ text, model_id: GEMINI_MODEL_ID, truncated });
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
      `auth ${AUTH_PER_HOUR}/h, register ${UNAUTH_PER_HOUR}/h/IP, ` +
      `summary floor $${EST_COST_PER_SUMMARY_USD}/max ${MAX_OUTPUT_TOKENS} out-tokens`,
  );
});

export { app };
