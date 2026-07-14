/**
 * Gemini 3.1 Flash Lite call. Uses the REST endpoint directly via native fetch
 * (Node 18+ global) rather than an SDK — this is the exact call the retired
 * Cloudflare Worker made, so behaviour is unchanged across the migration.
 *
 * Non-streaming by design: the app's CloudBackend (lib/services/summarizer/
 * cloud_backend.dart) does a single POST and JSON-parses {text, model_id}. Do
 * not switch this to SSE without also changing the client.
 *
 * The summarizer rebuild added two OPTIONAL knobs — `system` (Gemini's
 * systemInstruction, which carries every anti-hallucination rule) and
 * `maxOutputTokens` (the new single-pass prompt emits far more than the old
 * 4-section template). Both default to the pre-rebuild behaviour, so an app
 * build that predates the rebuild gets a byte-identical request.
 */

const GEMINI_ENDPOINT =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent';

export const GEMINI_MODEL_ID = 'gemini-3.1-flash-lite';

/**
 * Output-token bounds. The floor stops a client asking for an output so small
 * the notes are guaranteed to be cut off mid-section; the ceiling is what the
 * daily budget guard is sized against (see EST_COST_PER_SUMMARY_USD in
 * server.ts) and what the client's BackendCapabilities advertises.
 */
export const MIN_OUTPUT_TOKENS = 256;
export const MAX_OUTPUT_TOKENS = 8192;
/** Pre-rebuild value. Keeping it as the default is what makes old clients safe. */
export const DEFAULT_OUTPUT_TOKENS = 2048;

/** Clamp to [MIN, MAX]; a missing/NaN value falls back to the legacy default. */
export function clampOutputTokens(n?: number): number {
  if (typeof n !== 'number' || !Number.isFinite(n)) return DEFAULT_OUTPUT_TOKENS;
  return Math.min(MAX_OUTPUT_TOKENS, Math.max(MIN_OUTPUT_TOKENS, Math.floor(n)));
}

export interface SummarizeOptions {
  /** Gemini systemInstruction. Omitted from the request when blank. */
  system?: string;
  /** Clamped to [MIN_OUTPUT_TOKENS, MAX_OUTPUT_TOKENS]. */
  maxOutputTokens?: number;
}

export interface SummarizeResult {
  text: string;
  /**
   * True when Gemini stopped because it hit maxOutputTokens rather than
   * finishing. The text is still useful, so we return it — but we must not
   * pretend it is complete (CLAUDE.md: never silently degrade). The route
   * surfaces this to the client as `truncated: true`.
   */
  truncated: boolean;
}

/** Upstream (Gemini) failure — surfaced to the client as HTTP 502. */
export class UpstreamError extends Error {
  constructor(
    message: string,
    readonly detail: string,
  ) {
    super(message);
    this.name = 'UpstreamError';
  }
}

export async function summarizeWithGemini(
  apiKey: string,
  prompt: string,
  transcript: string,
  opts: SummarizeOptions = {},
): Promise<SummarizeResult> {
  const system = opts.system?.trim() ?? '';
  const maxOutputTokens = clampOutputTokens(opts.maxOutputTokens);

  // Legacy clients send the persona prompt and the transcript separately, and
  // we stitch them exactly as before. The rebuilt client composes the whole
  // single-pass prompt (transcript included) itself and sends no transcript
  // field; in that case there is nothing to append.
  const trimmedTranscript = transcript.trim();
  const text = trimmedTranscript
    ? `${prompt.trim()}\n\nTranscript:\n${transcript}`
    : prompt.trim();

  const body: Record<string, unknown> = {
    contents: [{ parts: [{ text }] }],
    generationConfig: { temperature: 0.4, topK: 40, maxOutputTokens },
  };
  if (system) {
    body.systemInstruction = { parts: [{ text: system }] };
  }

  const resp = await fetch(`${GEMINI_ENDPOINT}?key=${encodeURIComponent(apiKey)}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (!resp.ok) {
    const detail = (await resp.text()).slice(0, 500);
    throw new UpstreamError(`gemini ${resp.status}`, detail);
  }

  const jsonResp = (await resp.json()) as {
    candidates?: {
      content?: { parts?: { text?: string }[] };
      finishReason?: string;
    }[];
    promptFeedback?: { blockReason?: string };
  };
  const candidate = jsonResp?.candidates?.[0];
  // A long transcript can arrive as several parts; joining them is a no-op for
  // the single-part case and stops us silently dropping the tail otherwise.
  const out = (candidate?.content?.parts ?? [])
    .map((p) => p.text ?? '')
    .join('')
    .trim();

  if (!out) {
    // Empty means blocked, or a finishReason we do not handle. Say which —
    // "no text" alone is undiagnosable in production.
    const reason =
      jsonResp?.promptFeedback?.blockReason ?? candidate?.finishReason ?? '';
    throw new UpstreamError('gemini returned no text', reason);
  }

  return { text: out, truncated: candidate?.finishReason === 'MAX_TOKENS' };
}
