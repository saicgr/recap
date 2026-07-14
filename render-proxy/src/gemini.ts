/**
 * Gemini 3.1 Flash Lite call. Uses the REST endpoint directly via native fetch
 * (Node 18+ global) rather than an SDK — this is the exact call the retired
 * Cloudflare Worker made, so behaviour is unchanged across the migration.
 *
 * Non-streaming by design: the app's CloudBackend (lib/services/summarizer/
 * cloud_backend.dart) does a single POST and JSON-parses {text, model_id}. Do
 * not switch this to SSE without also changing the client.
 */

const GEMINI_ENDPOINT =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent';

export const GEMINI_MODEL_ID = 'gemini-3.1-flash-lite';

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
): Promise<{ text: string }> {
  const body = {
    contents: [
      { parts: [{ text: `${prompt.trim()}\n\nTranscript:\n${transcript}` }] },
    ],
    generationConfig: { temperature: 0.4, topK: 40, maxOutputTokens: 2048 },
  };

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
    candidates?: { content?: { parts?: { text?: string }[] } }[];
  };
  const text = jsonResp?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text || !text.trim()) {
    throw new UpstreamError('gemini returned no text', '');
  }
  return { text: text.trim() };
}
