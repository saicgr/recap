import crypto from 'node:crypto';
import type { Request, Response, NextFunction } from 'express';

/**
 * Install token = HMAC-SHA256(installId, PEPPER), hex-encoded.
 *
 * PEPPER is a server-only secret. The token is issued by POST /v1/register
 * and cached by the app in secure storage. It is NOT stored server-side — the
 * server recomputes and compares on every request, so there is no per-install
 * state to keep.
 */
export function issueToken(installId: string, pepper: string): string {
  return crypto.createHmac('sha256', pepper).update(installId).digest('hex');
}

/** Constant-time compare of two hex strings (returns false on any malformation). */
function safeEqualHex(a: string, b: string): boolean {
  if (a.length !== b.length || a.length === 0) return false;
  let ba: Buffer;
  let bb: Buffer;
  try {
    ba = Buffer.from(a, 'hex');
    bb = Buffer.from(b, 'hex');
  } catch {
    return false;
  }
  if (ba.length !== bb.length || ba.length === 0) return false;
  return crypto.timingSafeEqual(ba, bb);
}

/** installId shape: url-safe, 16–128 chars. Rejects junk before any HMAC work. */
export const INSTALL_ID_RE = /^[A-Za-z0-9_-]{16,128}$/;

export interface AuthedRequest extends Request {
  installId?: string;
}

/**
 * Auth middleware. Requires both:
 *   Authorization: Bearer <token>
 *   X-Install-Id:  <installId>
 * with token === HMAC(installId, PEPPER). A random or forged token 401s — which
 * is the whole point of Wave 0 (the old Cloudflare Worker accepted ANY 64-hex
 * string).
 *
 * This does NOT make the anonymous free tier unforgeable — /v1/register hands a
 * token to anyone, by design (no account required to summarize). It raises the
 * bar from "any string" to "a token we issued", and the real cost backstops are
 * the per-install rate limit + the global daily budget. Paid/metered routes
 * (Deepgram, Wave 3) layer store-receipt validation on top of this.
 */
export function requireInstallAuth(pepper: string) {
  return (req: AuthedRequest, res: Response, next: NextFunction): void => {
    const auth = req.header('authorization') ?? '';
    if (!auth.startsWith('Bearer ')) {
      res.status(401).json({ error: 'missing bearer token' });
      return;
    }
    const token = auth.slice('Bearer '.length).trim();
    const installId = (req.header('x-install-id') ?? '').trim();
    if (!INSTALL_ID_RE.test(installId)) {
      res.status(401).json({ error: 'missing or malformed install id' });
      return;
    }
    if (!safeEqualHex(token, issueToken(installId, pepper))) {
      res.status(401).json({ error: 'invalid install token' });
      return;
    }
    req.installId = installId;
    next();
  };
}
