/**
 * In-memory abuse mitigation for a single Render instance. State resets on
 * redeploy/restart — acceptable for the Wave 0 Gemini backstop. The durable,
 * receipt-keyed minute/storage ledger (a table in the same Neon DB) arrives
 * with Deepgram metering in Wave 3. If this service is ever scaled past one
 * instance, these move to Neon too.
 */

interface Bucket {
  count: number;
  resetAt: number;
}

/** Fixed-window per-key hourly limiter. */
export class HourlyRateLimiter {
  private readonly buckets = new Map<string, Bucket>();

  constructor(private readonly perHour: number) {}

  /** Returns true if the hit is allowed, false if the key is over its limit. */
  hit(key: string, now: number = Date.now()): boolean {
    const b = this.buckets.get(key);
    if (!b || now >= b.resetAt) {
      this.buckets.set(key, { count: 1, resetAt: now + 3_600_000 });
      return true;
    }
    if (b.count >= this.perHour) return false;
    b.count += 1;
    return true;
  }

  /** Drop expired buckets so the map does not grow unbounded. */
  sweep(now: number = Date.now()): void {
    for (const [k, b] of this.buckets) {
      if (now >= b.resetAt) this.buckets.delete(k);
    }
  }
}

/**
 * Global daily-spend circuit breaker. Tracks an ESTIMATED USD spend against a
 * cap and rolls over at UTC midnight. This is a safety backstop against a
 * runaway bill, not billing-grade accounting.
 */
export class DailyBudget {
  private spentUsd = 0;
  private dayKey = DailyBudget.utcDay();

  constructor(private readonly capUsd: number) {}

  private static utcDay(now: number = Date.now()): string {
    return new Date(now).toISOString().slice(0, 10);
  }

  private roll(now: number = Date.now()): void {
    const d = DailyBudget.utcDay(now);
    if (d !== this.dayKey) {
      this.dayKey = d;
      this.spentUsd = 0;
    }
  }

  /** True if there is room for an estimated spend of `estUsd` today. */
  canSpend(estUsd: number, now: number = Date.now()): boolean {
    this.roll(now);
    return this.spentUsd + estUsd <= this.capUsd;
  }

  record(estUsd: number, now: number = Date.now()): void {
    this.roll(now);
    this.spentUsd += estUsd;
  }

  get spent(): number {
    this.roll();
    return this.spentUsd;
  }
}
