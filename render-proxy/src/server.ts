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

app.use((_req, res) => res.status(404).json({ error: 'not found' }));

app.listen(PORT, () => {
  console.log(
    `recap-proxy on :${PORT} — daily budget cap $${DAILY_BUDGET_USD}, ` +
      `auth ${AUTH_PER_HOUR}/h, register ${UNAUTH_PER_HOUR}/h/IP`,
  );
});

export { app };
