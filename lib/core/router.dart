import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/history/presentation/history_screen.dart';
import '../features/import/presentation/import_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/premium/presentation/paywall_screen.dart';
import '../features/results/presentation/results_screen.dart';
import '../features/settings/application/settings_controller.dart';
import '../features/settings/presentation/guide_screen.dart';
import '../features/settings/presentation/privacy_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../l10n/generated/app_localizations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Read once: the initial location only matters at start-up, and watching
  // would rebuild the router (and lose navigation state) on every change.
  final onboardingDone = ref.read(settingsControllerProvider).onboardingDone;
  final router = GoRouter(
    initialLocation: onboardingDone ? '/results' : '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/results', builder: (_, _) => const ResultsScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (_, _) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => ResultsScreen(snapshotId: int.tryParse(state.pathParameters['id'] ?? '')),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen())],
          ),
        ],
      ),
      GoRoute(path: '/import', builder: (_, _) => const ImportScreen()),
      GoRoute(path: '/paywall', builder: (_, _) => const PaywallScreen()),
      GoRoute(path: '/privacy', builder: (_, _) => const PrivacyScreen()),
      GoRoute(path: '/guide', builder: (_, _) => const GuideScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.compare_arrows), label: l10n.navResults),
          NavigationDestination(icon: const Icon(Icons.history), label: l10n.navHistory),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
