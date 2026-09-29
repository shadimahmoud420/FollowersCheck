import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/premium_providers.dart';

final _storeInfoProvider = FutureProvider.autoDispose<({bool available, String? price})>((ref) async {
  final service = ref.watch(entitlementServiceProvider);
  final available = await service.isStoreAvailable();
  return (available: available, price: available ? await service.priceLabel() : null);
});

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isPremium = ref.watch(isPremiumProvider);
    final store = ref.watch(_storeInfoProvider);
    final service = ref.read(entitlementServiceProvider);

    final features = [
      (Icons.all_inclusive, l10n.paywallFeature1),
      (Icons.history, l10n.paywallFeature2),
      (Icons.show_chart, l10n.paywallFeature3),
    ];

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.workspace_premium, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(l10n.paywallTitle, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          for (final (icon, text) in features)
            ListTile(
              leading: Icon(icon, color: theme.colorScheme.primary),
              title: Text(text),
            ),
          const SizedBox(height: 24),
          if (isPremium)
            Card.filled(
              child: ListTile(leading: const Icon(Icons.check_circle), title: Text(l10n.premiumActive)),
            )
          else
            store.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Text(l10n.paywallUnavailable, textAlign: TextAlign.center),
              data: (info) => info.available
                  ? FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      onPressed: service.purchasePremium,
                      child: Text(info.price == null ? l10n.upgrade : l10n.paywallBuy(info.price!)),
                    )
                  : Text(l10n.paywallUnavailable, textAlign: TextAlign.center),
            ),
          const SizedBox(height: 8),
          if (!isPremium) TextButton(onPressed: service.restorePurchases, child: Text(l10n.paywallRestore)),
        ],
      ),
    );
  }
}
