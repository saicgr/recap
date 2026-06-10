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

  static const all = <String>{
    pro,
    privacy,
    power,
    topUp25,
    topUp100,
    topUp500,
  };

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

  Future<void> restore() => _iap.restorePurchases();

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
    if (tier != null) {
      await entitlements.setTier(tier);
      return;
    }
    final topUp = ProductIds.topUpForProduct(p.productID);
    if (topUp != null) {
      await entitlements.applyTopUp(topUp);
      return;
    }
  }
}
