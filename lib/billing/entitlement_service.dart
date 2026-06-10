import 'tier.dart';

enum SummaryMode { onDevice, cloud }

class TierUsage {
  final int cloudSummariesUsedThisMonth;
  final int meetingsStartedToday;
  final Duration recordedThisMonth;
  final int totalMeetings;
  final int topUpCreditsRemaining;
  const TierUsage({
    required this.cloudSummariesUsedThisMonth,
    required this.meetingsStartedToday,
    required this.recordedThisMonth,
    required this.totalMeetings,
    required this.topUpCreditsRemaining,
  });
}

sealed class StartRecordingDecision {
  const StartRecordingDecision();
}

class AllowRecording extends StartRecordingDecision {
  const AllowRecording();
}

// Recording-cap blocks (BlockedDailyMeetings, BlockedMonthlyHours) used to
// live here. Removed when we dropped recording quotas — see TIERS.md "Where
// the walls actually live." Capture is unlimited on every tier; only cloud
// summary calls and feature presence gate.

sealed class SummaryDecision {
  const SummaryDecision();
}

class AllowSummary extends SummaryDecision {
  final SummaryMode mode;
  const AllowSummary(this.mode);
}

class BlockedCloudQuota extends SummaryDecision {
  /// Whether the user has on-device fallback available right now.
  final bool onDeviceAvailable;
  const BlockedCloudQuota({required this.onDeviceAvailable});
}

class BlockedCloudDisabled extends SummaryDecision {
  /// Privacy tier — cloud is verifiably disabled by design.
  const BlockedCloudDisabled();
}

abstract class EntitlementService {
  Tier get currentTier;

  Stream<TierUsage> watchUsage();

  /// Can the user start recording right now (under daily-session cap)?
  Future<StartRecordingDecision> decideStartRecording();

  /// Hard cap on a single recording. Always null after we dropped recording
  /// quotas — kept for binary compatibility with existing call sites; can be
  /// deleted once those sites stop referencing it.
  Duration? get maxMeetingDuration => null;

  /// Decide whether a summary call is allowed. Mode is what the user requested
  /// in Settings (defaults to onDevice if available; cloud requires quota).
  Future<SummaryDecision> decideSummary(SummaryMode requested);

  Future<void> recordMeetingStarted();
  Future<void> recordMeetingFinished({required Duration duration});
  Future<void> recordCloudSummaryUsed();

  Future<void> applyTopUp(TopUpPack pack);
}

/// v1 stub: always Free tier, never blocks. Replace with a real implementation
/// once `in_app_purchase` + usage persistence is wired in.
class StubEntitlementService implements EntitlementService {
  @override
  Tier get currentTier => Tier.free;

  @override
  Stream<TierUsage> watchUsage() => Stream.value(const TierUsage(
        cloudSummariesUsedThisMonth: 0,
        meetingsStartedToday: 0,
        recordedThisMonth: Duration.zero,
        totalMeetings: 0,
        topUpCreditsRemaining: 0,
      ));

  @override
  Future<StartRecordingDecision> decideStartRecording() async =>
      const AllowRecording();

  @override
  Duration? get maxMeetingDuration => null;

  @override
  Future<SummaryDecision> decideSummary(SummaryMode requested) async =>
      AllowSummary(requested);

  @override
  Future<void> recordMeetingStarted() async {}

  @override
  Future<void> recordMeetingFinished({required Duration duration}) async {}

  @override
  Future<void> recordCloudSummaryUsed() async {}

  @override
  Future<void> applyTopUp(TopUpPack pack) async {}
}
