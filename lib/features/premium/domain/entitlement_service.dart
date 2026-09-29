/// Abstraction over whatever grants "premium" (store purchase, promo code,
/// debug override...). The rest of the app only depends on this interface,
/// so the real store integration can be implemented later without touching
/// the UI.
abstract interface class EntitlementService {
  /// Emits the current premium state immediately, then every change.
  Stream<bool> watchIsPremium();

  bool get isPremium;

  /// Whether purchasing is currently possible (store reachable, products
  /// configured).
  Future<bool> isStoreAvailable();

  /// Localized price of the premium product, if known.
  Future<String?> priceLabel();

  /// Starts the purchase flow. Returns true when the purchase was initiated.
  Future<bool> purchasePremium();

  Future<void> restorePurchases();

  Future<void> dispose();
}
