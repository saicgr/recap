import 'dart:async';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import 'entitlement_service.dart';
import 'tier.dart';

class DriftEntitlementService implements EntitlementService {
  DriftEntitlementService({required this.db, Tier? initialTier})
      : _tier = initialTier ?? Tier.free;

  final AppDb db;
  Tier _tier;
  bool _initialized = false;

  final _usageController = StreamController<TierUsage>.broadcast();

  @override
  Tier get currentTier {
    // Reading the tier before it has been rehydrated from disk would hand back
    // Free — which is exactly the bug this class used to have (every relaunch
    // silently downgraded a paying customer). main.dart must await init()
    // before resolving the Whisper ceiling, the Gemma variant, or the
    // translator chain, all of which branch on the tier.
    assert(
      _initialized,
      'DriftEntitlementService.currentTier read before init(). '
      'Await entitlements.init() during startup.',
    );
    return _tier;
  }

  /// Rehydrate the tier from persisted purchases.
  ///
  /// Deliberately does NOT catch: if the read fails we let it throw rather than
  /// defaulting to Free. Free has cloud summaries enabled, so a silent fallback
  /// would hand a Privacy-tier user a cloud-capable build — the one invariant
  /// we cannot break. Failing loudly beats degrading quietly.
  Future<void> init() async {
    final rows = await db.select(db.purchases).get();
    _tier = _resolveTier(rows);
    _initialized = true;
    await _emitUsage();
  }

  /// Reduce the persisted purchase rows to a single effective tier.
  static Tier _resolveTier(List<Purchase> rows) {
    // A debug override wins outright (debug builds only) so the tier switcher
    // in Settings can preview *lower* tiers too, not just higher ones.
    for (final r in rows) {
      if (r.source == 'debug_override') {
        final t = _tierFromName(r.tier);
        if (t != null) return t;
      }
    }
    // Otherwise the most expensive tier the user owns. Owning both Privacy and
    // Power is pathological; if it happens, the later/pricier deliberate
    // purchase (Power) wins.
    var best = Tier.free;
    for (final r in rows) {
      if (r.source != 'store') continue;
      final t = _tierFromName(r.tier);
      if (t != null && t.priceUsd > best.priceUsd) best = t;
    }
    return best;
  }

  static Tier? _tierFromName(String? name) {
    if (name == null) return null;
    for (final t in Tier.values) {
      if (t.name == name) return t;
    }
    return null;
  }

  /// Persist a verified store purchase.
  ///
  /// Idempotent on [purchaseId]: `restorePurchases()` replays every past
  /// transaction through `purchaseStream`, so without this guard each restore
  /// would re-grant consumable top-up credits. Returns true only if the row was
  /// newly inserted — callers use that to decide whether to grant credits.
  Future<bool> recordPurchase({
    required String purchaseId,
    required String productId,
    Tier? tier,
    DateTime? purchasedAt,
  }) async {
    // insertReturningOrNull, NOT insert(): with insertOrIgnore, insert() hands
    // back a rowid even when the row was ignored (SQLite does not reset
    // last_insert_rowid on a no-op), so it reports a replayed purchase as new —
    // which would mint free top-up credits on every restore.
    // insertReturningOrNull returns null when nothing was inserted.
    final row = await db.into(db.purchases).insertReturningOrNull(
          PurchasesCompanion.insert(
            id: purchaseId,
            productId: productId,
            tier: Value(tier?.name),
            purchasedAt: Value(purchasedAt),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    if (tier != null) await _refreshTier();
    return row != null;
  }

  /// Debug-only tier override (the Settings → Switch tier picker). Persisted
  /// with source 'debug_override' so it can never be confused with a real
  /// purchase, and so it survives a restart like a real tier does.
  Future<void> setTier(Tier tier) async {
    await db.into(db.purchases).insertOnConflictUpdate(
          PurchasesCompanion.insert(
            id: 'debug_override',
            productId: 'debug_override',
            tier: Value(tier.name),
            source: const Value('debug_override'),
          ),
        );
    await _refreshTier();
  }

  Future<void> _refreshTier() async {
    _tier = _resolveTier(await db.select(db.purchases).get());
    _initialized = true;
    await _emitUsage();
  }

  @override
  Stream<TierUsage> watchUsage() async* {
    yield await _currentUsage();
    yield* _usageController.stream;
  }

  Future<void> _emitUsage() async {
    _usageController.add(await _currentUsage());
  }

  String _dayKey(DateTime t) => DateFormat('yyyy-MM-dd').format(t);
  String _monthKey(DateTime t) => DateFormat('yyyy-MM').format(t);

  Future<TierUsage> _currentUsage() async {
    final now = DateTime.now();
    final day = await (db.select(db.usageDays)
          ..where((t) => t.day.equals(_dayKey(now))))
        .getSingleOrNull();
    final month = await (db.select(db.usageMonths)
          ..where((t) => t.month.equals(_monthKey(now))))
        .getSingleOrNull();
    final credits = await db.select(db.topUpCredits).get();
    final totalCredits = credits.fold<int>(0, (sum, c) => sum + c.remaining);
    final totalMeetings = (await db.select(db.meetings).get()).length;

    return TierUsage(
      cloudSummariesUsedThisMonth: month?.cloudSummariesUsed ?? 0,
      meetingsStartedToday: day?.meetingsStarted ?? 0,
      recordedThisMonth: Duration(milliseconds: month?.recordedMs ?? 0),
      totalMeetings: totalMeetings,
      topUpCreditsRemaining: totalCredits,
    );
  }

  @override
  Duration? get maxMeetingDuration => null; // unlimited on every tier

  @override
  Future<StartRecordingDecision> decideStartRecording() async {
    // Recording is unlimited on every tier. Cap checks live on summary +
    // feature presence, not on capture. We still record meetingsStarted +
    // recordedMs in TierUsage for the user's own analytics screen (D14.10).
    return const AllowRecording();
  }

  @override
  Future<SummaryDecision> decideSummary(SummaryMode requested) async {
    if (requested == SummaryMode.onDevice) {
      return const AllowSummary(SummaryMode.onDevice);
    }
    // Cloud requested.
    if (!_tier.cloudSummariesEnabled) {
      return const BlockedCloudDisabled();
    }
    if (_tier.byok) {
      // Power tier: unlimited via user's own key.
      return const AllowSummary(SummaryMode.cloud);
    }
    final cap = _tier.cloudSummariesPerMonth;
    if (cap == null) return const AllowSummary(SummaryMode.cloud);

    final usage = await _currentUsage();
    if (usage.cloudSummariesUsedThisMonth < cap) {
      return const AllowSummary(SummaryMode.cloud);
    }
    // Out of monthly quota. Top-up credits?
    if (usage.topUpCreditsRemaining > 0) {
      return const AllowSummary(SummaryMode.cloud);
    }
    // No credits. On-device may still be possible (caller decides whether to
    // offer the fallback).
    return const BlockedCloudQuota(onDeviceAvailable: true);
  }

  @override
  Future<void> recordMeetingStarted() async {
    final key = _dayKey(DateTime.now());
    await db.transaction(() async {
      final existing = await (db.select(db.usageDays)
            ..where((t) => t.day.equals(key)))
          .getSingleOrNull();
      if (existing == null) {
        await db.into(db.usageDays).insert(UsageDaysCompanion.insert(
              day: key,
              meetingsStarted: const Value(1),
            ));
      } else {
        await (db.update(db.usageDays)..where((t) => t.day.equals(key))).write(
            UsageDaysCompanion(
                meetingsStarted: Value(existing.meetingsStarted + 1)));
      }
    });
    await _emitUsage();
  }

  @override
  Future<void> recordMeetingFinished({required Duration duration}) async {
    final now = DateTime.now();
    final dayKey = _dayKey(now);
    final monthKey = _monthKey(now);
    final ms = duration.inMilliseconds;
    await db.transaction(() async {
      final day = await (db.select(db.usageDays)
            ..where((t) => t.day.equals(dayKey)))
          .getSingleOrNull();
      if (day == null) {
        await db.into(db.usageDays).insert(UsageDaysCompanion.insert(
              day: dayKey,
              recordedMs: Value(ms),
            ));
      } else {
        await (db.update(db.usageDays)..where((t) => t.day.equals(dayKey)))
            .write(UsageDaysCompanion(recordedMs: Value(day.recordedMs + ms)));
      }
      final month = await (db.select(db.usageMonths)
            ..where((t) => t.month.equals(monthKey)))
          .getSingleOrNull();
      if (month == null) {
        await db.into(db.usageMonths).insert(UsageMonthsCompanion.insert(
              month: monthKey,
              recordedMs: Value(ms),
            ));
      } else {
        await (db.update(db.usageMonths)
              ..where((t) => t.month.equals(monthKey)))
            .write(
                UsageMonthsCompanion(recordedMs: Value(month.recordedMs + ms)));
      }
    });
    await _emitUsage();
  }

  @override
  Future<void> recordCloudSummaryUsed() async {
    final now = DateTime.now();
    final monthKey = _monthKey(now);
    final cap = _tier.cloudSummariesPerMonth;

    await db.transaction(() async {
      final month = await (db.select(db.usageMonths)
            ..where((t) => t.month.equals(monthKey)))
          .getSingleOrNull();
      final current = month?.cloudSummariesUsed ?? 0;

      // Are we within free quota, or do we need to burn a top-up credit?
      final withinQuota = cap == null || current < cap;

      if (withinQuota) {
        if (month == null) {
          await db.into(db.usageMonths).insert(UsageMonthsCompanion.insert(
                month: monthKey,
                cloudSummariesUsed: const Value(1),
              ));
        } else {
          await (db.update(db.usageMonths)
                ..where((t) => t.month.equals(monthKey)))
              .write(
                  UsageMonthsCompanion(cloudSummariesUsed: Value(current + 1)));
        }
      } else {
        // Burn one top-up credit. Take from the oldest pack with remaining > 0.
        final pack = await (db.select(db.topUpCredits)
              ..where((t) => t.remaining.isBiggerThanValue(0))
              ..orderBy([(t) => OrderingTerm.asc(t.purchasedAt)])
              ..limit(1))
            .getSingleOrNull();
        if (pack == null) {
          throw StateError(
              'recordCloudSummaryUsed called with no quota and no credits');
        }
        await (db.update(db.topUpCredits)..where((t) => t.id.equals(pack.id)))
            .write(TopUpCreditsCompanion(remaining: Value(pack.remaining - 1)));
      }
    });
    await _emitUsage();
  }

  @override
  Future<void> applyTopUp(TopUpPack pack) async {
    await db.into(db.topUpCredits).insert(TopUpCreditsCompanion.insert(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          remaining: pack.summaries,
          purchasedAt: DateTime.now(),
          productId: 'topup_${pack.name}',
        ));
    await _emitUsage();
  }
}
