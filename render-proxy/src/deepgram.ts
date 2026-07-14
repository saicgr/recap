import { Readable } from 'node:stream';
import type { Request } from 'express';

/**
 * Deepgram Nova-3 batch transcription.
 *
 * The request body is STREAMED straight through to Deepgram — we never call
 * req.body / arrayBuffer() on it. A one-hour recording is ~55 MB as FLAC (and
 * ~115 MB as WAV); buffering that per concurrent request is how a small
 * instance dies. Piping keeps memory O(1) regardless of file size.
 */

const DG_URL = 'https://api.deepgram.com/v1/listen';

export const DG_MODEL = 'nova-3';

export class DeepgramError extends Error {
  constructor(
    message: string,
    readonly status: number,
    readonly detail: string,
  ) {
    super(message);
    this.name = 'DeepgramError';
  }
}

export interface DgWord {
  word: string;
  start: number;
  end: number;
  confidence: number;
  speaker?: number;
  punctuated_word?: string;
}

export interface DgResult {
  transcript: string;
  words: DgWord[];
  /** Deepgram's OWN duration, in seconds. This is the number we bill against —
   *  never the client's claim, which a patched client would under-report. */
  durationSeconds: number;
  modelId: string;
  detectedLanguage?: string;
}

export interface DgOptions {
  /** BCP-47, or omitted to let Deepgram detect. */
  language?: string;
  /** Names/jargon to bias toward — fed from the app's GlossaryTerms table. */
  keyterms?: string[];
  contentType: string;
}

export async function transcribeStream(
  apiKey: string,
  req: Request,
  opts: DgOptions,
): Promise<DgResult> {
  const qs = new URLSearchParams({
    model: DG_MODEL,
    smart_format: 'true',
    punctuate: 'true',
    paragraphs: 'true',
    diarize: 'true',
    utterances: 'true',
    // Deepgram's pay-as-you-go default OPTS YOU IN to model training. The whole
    // product promise is that we do not feed user audio to anyone's training
    // set, so this is not optional and must never be dropped.
    mip_opt_out: 'true',
  });
  if (opts.language) qs.set('language', opts.language);
  else qs.set('detect_language', 'true');

  // Keyterm biasing. NOTE: only the user's own glossary terms belong here —
  // never calendar attendee names or meeting titles, which would leak the
  // user's social graph into a query string.
  for (const t of opts.keyterms ?? []) {
    if (t.trim()) qs.append('keyterm', t.trim());
  }

  const resp = await fetch(`${DG_URL}?${qs.toString()}`, {
    method: 'POST',
    headers: {
      Authorization: `Token ${apiKey}`,
      'Content-Type': opts.contentType,
    },
    // Stream the client's upload straight into the upstream request.
    body: Readable.toWeb(req) as ReadableStream<Uint8Array>,
    // Required by undici when the body is a stream: we finish sending before
    // we start reading the response.
    // @ts-expect-error -- `duplex` is valid at runtime but missing from the DOM types
    duplex: 'half',
  });

  if (!resp.ok) {
    const detail = (await resp.text()).slice(0, 500);
    throw new DeepgramError(`deepgram ${resp.status}`, resp.status, detail);
  }

  const json = (await resp.json()) as {
    metadata?: { duration?: number; model_info?: Record<string, unknown> };
    results?: {
      channels?: {
        alternatives?: {
          transcript?: string;
          words?: DgWord[];
          languages?: string[];
        }[];
      }[];
    };
  };

  const alt = json.results?.channels?.[0]?.alternatives?.[0];
  const transcript = alt?.transcript;
  const duration = json.metadata?.duration;

  if (typeof transcript !== 'string' || typeof duration !== 'number') {
    // Never invent a duration: we bill against it, and a fabricated value is
    // either theft from the user or from us.
    throw new DeepgramError('deepgram returned an unusable payload', 502, '');
  }

  return {
    transcript: transcript.trim(),
    words: alt?.words ?? [],
    durationSeconds: duration,
    modelId: DG_MODEL,
    detectedLanguage: alt?.languages?.[0],
  };
}
