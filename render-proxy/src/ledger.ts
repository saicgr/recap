import { getPool } from './db';

/**
 * Server-authoritative audio-minute ledger for cloud transcription.
 *
 * Why this is not client-side: the app's Drift counters run against
 * DateTime.now() on the device. Roll the clock back, reset the quota. Any
 * client-side quota is an honour system, and Deepgram costs real money per
 * minute against a ONE-TIME app purchase — so the meter has to live somewhere
 * the user cannot edit.
 *
 * The flow is reserve -> settle, never "spend then record":
 *   1. reserve()  — check the quota and hold the CLAIMED duration up front.
 *      If we called Deepgram first and recorded after, a client that hangs up
 *      mid-response would get free transcription every time.
 *   2. settle()   — replace the claim with Deepgram's OWN reported duration.
 *      The client tells us how long its audio is, and a patched client would
 *      under-report to stretch its quota; Deepgram's metadata.duration is the
 *      authoritative number, so we true up against it.
 *   3. refund()   — release the hold if the upstream call failed. The user must
 *      not pay for our 502.
 *
 * HONEST LIMITATION: the quota is keyed to an install id, and /v1/register
 * hands one to anyone (no account is required to use Recap — that is the
 * product). So a determined user can mint fresh installs for fresh quota. The
 * real backstop is the GLOBAL daily spend cap, and the durable fix is App
 * Store / Play receipt validation, which ties quota to an actual purchase. Do
 * not mistake this for anti-piracy; it is anti-accident and anti-drive-by.
 */

export interface Reservation {
  jobId: string;
  month: string;
}

function monthKey(now = new Date()): string {
  return now.toISOString().slice(0, 7); // YYYY-MM (UTC — server clock, not the device's)
}

export class QuotaExceeded extends Error {
  constructor(
    readonly usedSeconds: number,
    readonly limitSeconds: number,
  ) {
    super('audio minute quota exceeded');
    this.name = 'QuotaExceeded';
  }
}

/**
 * Hold [claimedSeconds] against this install's monthly allowance.
 * Throws QuotaExceeded if it would go over.
 */
export async function reserve(
  installId: string,
  claimedSeconds: number,
  limitSeconds: number,
): Promise<Reservation> {
  const month = monthKey();
  const pool = getPool();
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Lock this install's row for the month so two concurrent uploads cannot
    // both pass the quota check and jointly blow past the limit.
    await client.query(
      `INSERT INTO metering.audio_minutes (install_id, month)
       VALUES ($1, $2) ON CONFLICT (install_id, month) DO NOTHING`,
      [installId, month],
    );
    const { rows } = await client.query<{
      seconds_used: string;
      seconds_reserved: string;
    }>(
      `SELECT seconds_used, seconds_reserved FROM metering.audio_minutes
       WHERE install_id = $1 AND month = $2 FOR UPDATE`,
      [installId, month],
    );

    const used = Number(rows[0]?.seconds_used ?? 0);
    const held = Number(rows[0]?.seconds_reserved ?? 0);
    if (used + held + claimedSeconds > limitSeconds) {
      await client.query('ROLLBACK');
      throw new QuotaExceeded(used + held, limitSeconds);
    }

    await client.query(
      `UPDATE metering.audio_minutes
       SET seconds_reserved = seconds_reserved + $3, updated_at = now()
       WHERE install_id = $1 AND month = $2`,
      [installId, month, claimedSeconds],
    );
    const job = await client.query<{ id: string }>(
      `INSERT INTO metering.jobs (install_id, month, claimed_seconds)
       VALUES ($1, $2, $3) RETURNING id`,
      [installId, month, claimedSeconds],
    );

    await client.query('COMMIT');
    return { jobId: job.rows[0].id, month };
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    throw err;
  } finally {
    client.release();
  }
}

/** Convert a hold into a charge, trued up to Deepgram's own reported duration. */
export async function settle(
  installId: string,
  res: Reservation,
  actualSeconds: number,
): Promise<void> {
  const pool = getPool();
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query<{ claimed_seconds: string }>(
      `SELECT claimed_seconds FROM metering.jobs
       WHERE id = $1 AND status = 'reserved' FOR UPDATE`,
      [res.jobId],
    );
    if (rows.length === 0) {
      await client.query('ROLLBACK'); // already settled/refunded — idempotent
      return;
    }
    const claimed = Number(rows[0].claimed_seconds);

    await client.query(
      `UPDATE metering.audio_minutes
       SET seconds_reserved = GREATEST(0, seconds_reserved - $3),
           seconds_used     = seconds_used + $4,
           updated_at       = now()
       WHERE install_id = $1 AND month = $2`,
      [installId, res.month, claimed, actualSeconds],
    );
    await client.query(
      `UPDATE metering.jobs SET status = 'settled', actual_seconds = $2 WHERE id = $1`,
      [res.jobId, actualSeconds],
    );
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    throw err;
  } finally {
    client.release();
  }
}

/** Release a hold — the upstream call failed, so the user owes nothing. */
export async function refund(installId: string, res: Reservation): Promise<void> {
  const pool = getPool();
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query<{ claimed_seconds: string }>(
      `SELECT claimed_seconds FROM metering.jobs
       WHERE id = $1 AND status = 'reserved' FOR UPDATE`,
      [res.jobId],
    );
    if (rows.length === 0) {
      await client.query('ROLLBACK');
      return;
    }
    await client.query(
      `UPDATE metering.audio_minutes
       SET seconds_reserved = GREATEST(0, seconds_reserved - $3), updated_at = now()
       WHERE install_id = $1 AND month = $2`,
      [installId, res.month, Number(rows[0].claimed_seconds)],
    );
    await client.query(
      `UPDATE metering.jobs SET status = 'refunded' WHERE id = $1`,
      [res.jobId],
    );
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    throw err;
  } finally {
    client.release();
  }
}

/** Remaining seconds this month, for the client to display. */
export async function remaining(
  installId: string,
  limitSeconds: number,
): Promise<number> {
  const { rows } = await getPool().query<{
    seconds_used: string;
    seconds_reserved: string;
  }>(
    `SELECT seconds_used, seconds_reserved FROM metering.audio_minutes
     WHERE install_id = $1 AND month = $2`,
    [installId, monthKey()],
  );
  const used = Number(rows[0]?.seconds_used ?? 0);
  const held = Number(rows[0]?.seconds_reserved ?? 0);
  return Math.max(0, limitSeconds - used - held);
}
