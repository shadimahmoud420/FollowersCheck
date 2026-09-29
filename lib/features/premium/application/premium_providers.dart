import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_controller.dart';
import '../domain/entitlement_service.dart';

/// Overridden in `main()` with the store-backed implementation.
final entitlementServiceProvider = Provider<EntitlementService>(
  (ref) => throw UnimplementedError('entitlementServiceProvider must be overridden'),
);

final _storePremiumProvider = StreamProvider<bool>((ref) => ref.watch(entitlementServiceProvider).watchIsPremium());

/// Whether premium features are unlocked (store purchase, or the debug
/// override in debug builds).
final isPremiumProvider = Provider<bool>((ref) {
  final debugOverride = kDebugMode && ref.watch(settingsControllerProvider.select((s) => s.debugPremium));
  final store = ref.watch(_storePremiumProvider).value ?? ref.watch(entitlementServiceProvider).isPremium;
  return debugOverride || store;
});
