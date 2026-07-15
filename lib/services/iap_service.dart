import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../billing/entitlement_service_impl.dart';
import '../billing/tier.dart';

/// Product IDs registered in App Store Connect + Play Console.
/// Use the same string in both stores so lookups stay simple.
class ProductIds {
  static const pro = 'recap_pro_lifetime';
  static const privacy = 'recap_privacy_lifetime';
  static const power = 'recap_power_lifetime';

  static const topUp25 = 'recap_topup_25';
  static const topUp100 = 'recap_topup_100';
  static const topUp500 = 'recap_topup_500';

  static const all = <String>{pro, privacy, power, topUp25, topUp100, topUp500};

  static Tier? tierForProduct(String productId) => switch (productId) {
    pro => Tier.pro,
    privacy => Tier.privacy,
    power => Tier.power,
    _ => null,
  };

  static TopUpPack? topUpForProduct(String productId) => switch (productId) {
    topUp25 => TopUpPack.small,
    topUp100 => TopUpPack.medium,
    topUp500 => TopUpPack.large,
    _ => null,
  };
}

class IapService {
  IapService({required this.entitlements});

  final DriftEntitlementService entitlements;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _available = false;
  Map<String, ProductDetails> _products = const {};

  bool get isAvailable => _available;
  Map<String, ProductDetails> get products => _products;

  Future<void> init() async {
    _available = await _iap.isAvailable();
    if (!_available) return;

    _sub = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _sub?.cancel(),
      onError: (Object e) {
        // Karpathy invariant: no analytics SDK. Surface to console only.
        // ignore: avoid_print
        print('IAP purchaseStream error: $e');
      },
    );

    final response = await _iap.queryProductDetails(ProductIds.all);
    _products = {for (final p in response.productDetails) p.id: p};
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }

  Future<bool> buy(String productId) async {
    final product = _products[productId];
    if (product == null) {
      throw StateError('Unknown product: $productId');
    }
    final purchaseParam = PurchaseParam(productDetails: product);
    // All Recap products are non-consumable (lifetime tiers) except top-ups,
    // which are consumable.
    final isConsumable = ProductIds.topUpForProduct(productId) != null;
    return isConsumable
        ? _iap.buyConsumable(purchaseParam: purchaseParam)
        : _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restore past purchases. Safe to call on every launch: purchase rows are
  /// keyed by the store's own purchase id, so replayed transactions are
  /// idempotent and cannot double-grant consumable top-ups.
  ///
  /// This repairs a reinstall or a new device. It is NOT what makes the tier
  /// survive a restart — the persisted Purchases table does that, synchronously
  /// and offline, in [DriftEntitlementService.init].
  ///
  /// Deliberately does not delete rows the store fails to report. A restore can
  /// come back empty simply because the device is offline, and revoking a
  /// paying customer's lifetime tier on a transient error is far worse than
  /// briefly honouring a refunded one. Refund revocation needs a trustworthy
  /// "this is the complete entitled set" signal, which in_app_purchase does not
  /// give us; it belongs with server-side receipt validation.
  Future<void> restore() => _iap.restorePurchases();

  /// Parse a store transaction date.
  ///
  /// The two stores disagree: Google Play sends milliseconds-since-epoch,
  /// StoreKit sends a date string. Returns null rather than falling back to
  /// DateTime.now() — the lifetime-grandfathering invariant is enforced against
  /// this value, so a fabricated date silently corrupts it. "Unknown" is a
  /// truthful answer; "today" is not.
  static DateTime? parsePurchaseDate(String? raw) {
    final s = raw?.trim();
    if (s == null || s.isEmpty) return null;

    final ms = int.tryParse(s);
    if (ms != null) {
      // Range-check BEFORE constructing: fromMillisecondsSinceEpoch throws a
      // RangeError outside ±8.64e15, so a garbage value would crash rather than
      // parse to null.
      if (ms.abs() > 8640000000000000) return null;
      final d = DateTime.fromMillisecondsSinceEpoch(ms);
      // Then bound it to plausible store history: anything outside this window
      // means we misread the unit (seconds vs milliseconds) and the value is
      // not trustworthy.
      if (d.isAfter(DateTime(2008)) && d.isBefore(DateTime(2100))) return d;
      return null;
    }
    return DateTime.tryParse(s);
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> updates) async {
    for (final p in updates) {
      switch (p.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _applyPurchase(p);
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
      }
    }
  }

  Future<void> _applyPurchase(PurchaseDetails p) async {
    // TODO: receipt validation. For lifetime IAP an honest validator is
    // basically "did the store accept this purchase?" + a server-side
    // double-check if you want anti-piracy. We trust the store for v1.
    final tier = ProductIds.tierForProduct(p.productID);
    final topUp = ProductIds.topUpForProduct(p.productID);
    if (tier == null && topUp == null) return; // unknown product — ignore

    // Persist first, keyed by the store's purchase id. This is what makes the
    // tier survive a restart, and what makes restores idempotent.
    final isNew = await entitlements.recordPurchase(
      // Some stores omit purchaseID on restore; the product id is a stable
      // fallback for non-consumables (a user owns each tier at most once).
      purchaseId: p.purchaseID ?? p.productID,
      productId: p.productID,
      tier: tier,
      purchasedAt: parsePurchaseDate(p.transactionDate),
    );

    // recordPurchase already recomputed the tier from all persisted rows.
    if (tier != null) return;

    // Top-ups are consumable and additive, so they may only be granted for a
    // transaction we have never seen. restorePurchases() replays consumables on
    // iOS — without this guard, every restore would mint free credits.
    if (topUp != null && isNew) {
      await entitlements.applyTopUp(topUp);
    }
  }
}
