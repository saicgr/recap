import { Pool } from 'pg';

/**
 * Service-role connection to Neon, used ONLY for the metering ledger.
 *
 * This is deliberately NOT the path the app uses. The Flutter client talks to
 * the Neon Data API with a per-user JWT and gets RLS-enforced tenancy; it never
 * sees a connection string. This pool is server-side and bypasses RLS, which is
 * exactly why the `metering` schema is REVOKEd from the `authenticated` role —
 * a client must not be able to read or edit its own usage counters.
 */
let pool: Pool | null = null;

export function getPool(): Pool {
  if (pool) return pool;
  const url = process.env.DATABASE_URL;
  if (!url || !url.trim()) {
    throw new Error('DATABASE_URL is not set — the metering ledger cannot run');
  }
  pool = new Pool({
    connectionString: url,
    max: 5,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 10_000,
  });
  return pool;
}

export function isLedgerConfigured(): boolean {
  return Boolean(process.env.DATABASE_URL && process.env.DATABASE_URL.trim());
}
