import 'package:flutter_test/flutter_test.dart';
import 'package:recap/billing/entitlement_service.dart';
import 'package:recap/billing/tier.dart';
import 'package:recap/services/summarizer/summary_router.dart';
import 'package:recap/services/summarizer/summary_types.dart';

/// The offer-a-choice escalation for long meetings. Pure decision, so it is
/// fully testable without a model or a UI.
void main() {
  const long = SummaryPlan(willMapReduce: true, chunkCount: 6);
  const short = SummaryPlan(willMapReduce: false, chunkCount: 1);

  test('Privacy tier is NEVER offered cloud, even for a long meeting', () {
    expect(
      shouldOfferCloudUpgrade(
        tier: Tier.privacy,
        mode: SummaryMode.onDevice,
        plan: long,
        cloudUsable: true,
      ),
      isFalse,
      reason:
          'cloud is structurally unreachable on Privacy — Karpathy invariant',
    );
  });

  test(
    'a long meeting on Pro (on-device default, quota OK) IS offered cloud',
    () {
      expect(
        shouldOfferCloudUpgrade(
          tier: Tier.pro,
          mode: SummaryMode.onDevice,
          plan: long,
          cloudUsable: true,
        ),
        isTrue,
      );
    },
  );

  test(
    'a SHORT meeting is never offered — on-device is reliable + free there',
    () {
      expect(
        shouldOfferCloudUpgrade(
          tier: Tier.pro,
          mode: SummaryMode.onDevice,
          plan: short,
          cloudUsable: true,
        ),
        isFalse,
      );
    },
  );

  test('no offer when the user already chose cloud', () {
    expect(
      shouldOfferCloudUpgrade(
        tier: Tier.pro,
        mode: SummaryMode.cloud,
        plan: long,
        cloudUsable: true,
      ),
      isFalse,
    );
  });

  test('no offer when cloud is not usable (out of quota / offline)', () {
    expect(
      shouldOfferCloudUpgrade(
        tier: Tier.pro,
        mode: SummaryMode.onDevice,
        plan: long,
        cloudUsable: false,
      ),
      isFalse,
    );
  });

  test(
    'Free tier long meeting IS offered (cloud enabled with a monthly quota)',
    () {
      expect(
        shouldOfferCloudUpgrade(
          tier: Tier.free,
          mode: SummaryMode.onDevice,
          plan: long,
          cloudUsable: true,
        ),
        isTrue,
      );
    },
  );
}
