import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recap/billing/entitlement_service_impl.dart';
import 'package:recap/billing/tier.dart';
import 'package:recap/data/database.dart';
import 'package:recap/services/iap_service.dart';

/// The regression test that could not exist before Purchases was persisted.
///
/// The bug: DriftEntitlementService held the tier in a plain memory field, so
/// every app relaunch silently downgraded a paying customer to Free — and
/// main.dart resolves the Whisper model, the Gemma variant, and the translator
/// chain from that tier at startup.
void main() {
  late AppDb db;

  setUp(() => db = AppDb.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// A fresh service over the same database == an app relaunch.
  Future<DriftEntitlementService> relaunch() async {
    final svc = DriftEntitlementService(db: db);
    await svc.init();
    return svc;
  }

  group('tier persistence', () {
    test('a new install starts on Free', () async {
      final svc = await relaunch();
      expect(svc.currentTier, Tier.free);
    });

    test('a purchased tier survives a restart', () async {
      final first = await relaunch();
      await first.recordPurchase(
        purchaseId: 'txn-1',
        productId: ProductIds.pro,
        tier: Tier.pro,
        purchasedAt: DateTime(2026, 7, 1),
      );
      expect(first.currentTier, Tier.pro);

      // Force-quit and relaunch. This is the assertion that was failing in
      // production: the user paid $49 and came back to Free.
      final second = await relaunch();
      expect(second.currentTier, Tier.pro);
    });

    test('the most expensive owned tier wins', () async {
      final svc = await relaunch();
      await svc.recordPurchase(
        purchaseId: 'txn-pro',
        productId: ProductIds.pro,
        tier: Tier.pro,
      );
      await svc.recordPurchase(
        purchaseId: 'txn-power',
        productId: ProductIds.power,
        tier: Tier.power,
      );
      expect((await relaunch()).currentTier, Tier.power);
    });

    test('a debug override wins and can preview a LOWER tier', () async {
      final svc = await relaunch();
      await svc.recordPurchase(
        purchaseId: 'txn-power',
        productId: ProductIds.power,
        tier: Tier.power,
      );
      // The Settings tier switcher must be able to preview Free while the user
      // actually owns Power — "highest wins" alone would make that impossible.
      await svc.setTier(Tier.free);
      expect((await relaunch()).currentTier, Tier.free);
    });

    test(
      'the purchase date is preserved for lifetime grandfathering',
      () async {
        final svc = await relaunch();
        await svc.recordPurchase(
          purchaseId: 'txn-1',
          productId: ProductIds.pro,
          tier: Tier.pro,
          purchasedAt: DateTime(2026, 3, 15),
        );
        final row = (await db.select(db.purchases).get()).firstWhere(
          (r) => r.id == 'txn-1',
        );
        expect(row.purchasedAt, DateTime(2026, 3, 15));
        expect(row.source, 'store');
      },
    );
  });

  group('restore idempotency', () {
    test('replaying the same top-up does not mint free credits', () async {
      final svc = await relaunch();

      Future<bool> deliver() => svc.recordPurchase(
        purchaseId: 'txn-topup-1',
        productId: ProductIds.topUp25,
        tier: null, // top-ups grant credits, not a tier
      );

      expect(await deliver(), isTrue, reason: 'first delivery is new');
      if (await deliver()) fail('a replayed purchase must not read as new');

      // restorePurchases() replays consumables on iOS. Only the first delivery
      // may grant credits, or every restore would be free money.
      await svc.applyTopUp(TopUpPack.small);
      final usage = await svc.watchUsage().first;
      expect(usage.topUpCreditsRemaining, TopUpPack.small.summaries);
    });

    test('replaying a tier purchase keeps the tier stable', () async {
      final svc = await relaunch();
      for (var i = 0; i < 3; i++) {
        await svc.recordPurchase(
          purchaseId: 'txn-pro',
          productId: ProductIds.pro,
          tier: Tier.pro,
        );
      }
      expect(svc.currentTier, Tier.pro);
      expect((await db.select(db.purchases).get()).length, 1);
    });
  });

  group('purchase-date parsing', () {
    test('Google Play sends milliseconds since epoch', () {
      final d = IapService.parsePurchaseDate('1773532800000');
      expect(d, isNotNull);
      expect(d!.year, 2026);
    });

    test('StoreKit sends a date string', () {
      expect(
        IapService.parsePurchaseDate('2026-03-15T10:30:00Z'),
        DateTime.utc(2026, 3, 15, 10, 30),
      );
    });

    test('unparseable input returns null, never DateTime.now()', () {
      // Fabricating "today" would silently corrupt lifetime grandfathering,
      // which is enforced against this value. Unknown must stay unknown.
      for (final junk in ['', '   ', 'not-a-date', '0', '99999999999999999']) {
        expect(IapService.parsePurchaseDate(junk), isNull, reason: junk);
      }
      expect(IapService.parsePurchaseDate(null), isNull);
    });
  });
}
