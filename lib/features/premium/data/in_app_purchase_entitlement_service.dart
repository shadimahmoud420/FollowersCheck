import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entitlement_service.dart';

/// Placeholder store integration using `in_app_purchase`.
///
/// NOT wired to real products yet: [productId] must be created in App Store
/// Connect / Google Play Console before purchases work. Until then
/// [isStoreAvailable] returns false and the paywall shows a friendly notice.
///
/// TODO(premium): verify receipts (ideally on-device via StoreKit 2 /
/// Play Integrity, since the app has no backend) before unlocking.
class InAppPurchaseEntitlementService implements EntitlementService {
  InAppPurchaseEntitlementService(this._prefs, {InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance {
    _isPremium = _prefs.getBool(_prefsKey) ?? false;
    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (_) {});
  }

  static const productId = 'follower_check_premium';
  static const _prefsKey = 'premium_unlocked';

  final SharedPreferencesWithCache _prefs;
  final InAppPurchase _iap;
  final _controller = StreamController<bool>.broadcast();
  late final StreamSubscription<List<PurchaseDetails>> _sub;
  late bool _isPremium;
  ProductDetails? _product;

  @override
  bool get isPremium => _isPremium;

  @override
  Stream<bool> watchIsPremium() async* {
    yield _isPremium;
    yield* _controller.stream;
  }

  @override
  Future<bool> isStoreAvailable() async => (await _loadProduct()) != null;

  @override
  Future<String?> priceLabel() async => (await _loadProduct())?.price;

  @override
  Future<bool> purchasePremium() async {
    final product = await _loadProduct();
    if (product == null) return false;
    return _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  @override
  Future<void> restorePurchases() async {
    if (!await _iap.isAvailable()) return;
    await _iap.restorePurchases();
  }

  @override
  Future<void> dispose() async {
    await _sub.cancel();
    await _controller.close();
  }

  Future<ProductDetails?> _loadProduct() async {
    if (_product != null) return _product;
    try {
      if (!await _iap.isAvailable()) return null;
      final response = await _iap.queryProductDetails({productId});
      if (response.productDetails.isEmpty) return null;
      return _product = response.productDetails.first;
    } catch (_) {
      return null;
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != productId) continue;
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        await _setPremium(true);
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  Future<void> _setPremium(bool value) async {
    _isPremium = value;
    await _prefs.setBool(_prefsKey, value);
    _controller.add(value);
  }
}
