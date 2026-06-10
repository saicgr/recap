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

  final _usageController = StreamController<TierUsage>.broadcast();

  @override
  Tier get currentTier => _tier;

  /// Called by IapService when a purchase is verified.
  Future<void> setTier(Tier tier) async {
    _tier = tier;
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
    final totalCredits =
        credits.fold<int>(0, (sum, c) => sum + c.remaining);
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
        await (db.update(db.usageDays)..where((t) => t.day.equals(key)))
            .write(UsageDaysCompanion(
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
            .write(UsageMonthsCompanion(recordedMs: Value(month.recordedMs + ms)));
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
              .write(UsageMonthsCompanion(
                  cloudSummariesUsed: Value(current + 1)));
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
        await (db.update(db.topUpCredits)
              ..where((t) => t.id.equals(pack.id)))
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
