import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/admin_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/session.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/listings/presentation/add_listing_screen.dart';
import '../../features/listings/presentation/home_screen.dart';
import '../../features/listings/presentation/listing_detail_screen.dart';
import '../../features/matches/presentation/matches_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/offers/presentation/make_offer_screen.dart';
import '../../features/offers/presentation/offer_detail_screen.dart';
import '../../features/offers/presentation/offer_providers.dart';
import '../../features/offers/presentation/offers_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_screens.dart';
import '../widgets/common.dart';

/// يحوّل حالة الجلسة إلى توجيه تلقائي:
/// غير مسجّل → /login ، بلا ملف → /onboarding ، جاهز → التطبيق.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(sessionProvider).status;
      final loc = state.matchedLocation;
      switch (status) {
        case SessionStatus.loading:
          return loc == '/splash' ? null : '/splash';
        case SessionStatus.error:
          return loc == '/offline' ? null : '/offline';
        case SessionStatus.signedOut:
          return loc == '/login' ? null : '/login';
        case SessionStatus.needsProfile:
          return loc == '/onboarding' ? null : '/onboarding';
        case SessionStatus.ready:
          if (const ['/splash', '/login', '/onboarding', '/offline'].contains(loc)) return '/';
          return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _Splash()),
      GoRoute(path: '/offline', builder: (_, _) => const _Offline()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const EditProfileScreen(isOnboarding: true),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _Shell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/matches', builder: (_, _) => const MatchesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/offers', builder: (_, _) => const OffersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/me', builder: (_, _) => const MyProfileScreen())]),
        ],
      ),
      GoRoute(path: '/add', builder: (_, _) => const AddListingScreen()),
      GoRoute(
        path: '/listing/:id',
        builder: (_, s) => ListingDetailScreen(id: s.pathParameters['id']!),
      ),
      // روابط المشاركة: https://badelha.app/l/<id>
      GoRoute(path: '/l/:id', redirect: (_, s) => '/listing/${s.pathParameters['id']}'),
      GoRoute(
        path: '/offer/new/:listingId',
        builder: (_, s) => MakeOfferScreen.forListing(s.pathParameters['listingId']!),
      ),
      GoRoute(
        path: '/offer/:id',
        builder: (_, s) => OfferDetailScreen(id: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'counter',
            builder: (_, s) => MakeOfferScreen.counter(s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, s) => ChatScreen(conversationId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/user/:id',
        builder: (_, s) => UserProfileScreen(userId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/profile/edit', builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: '/favorites', builder: (_, _) => const FavoritesScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/admin', builder: (_, _) => const AdminScreen()),
    ],
  );
});

class _Shell extends ConsumerWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingIncoming = ref
            .watch(incomingOffersProvider)
            .value
            ?.where((o) => o.status.db == 'pending')
            .length ??
        0;
    void go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);
    return Scaffold(
      body: shell,
      floatingActionButton: FloatingActionButton.large(
        tooltip: 'أضف شيئاً للتبادل',
        onPressed: () => context.push('/add'),
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 40),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        height: 68,
        padding: EdgeInsets.zero,
        child: Row(children: [
          _NavItem(icon: Icons.home_rounded, label: 'الرئيسية', selected: shell.currentIndex == 0, onTap: () => go(0)),
          _NavItem(icon: Icons.track_changes_rounded, label: 'مطابقات', selected: shell.currentIndex == 1, onTap: () => go(1)),
          const SizedBox(width: 96),
          _NavItem(
            icon: Icons.swap_horiz_rounded,
            label: 'عروضي',
            selected: shell.currentIndex == 2,
            badge: pendingIncoming,
            onTap: () => go(2),
          ),
          _NavItem(icon: Icons.person_rounded, label: 'حسابي', selected: shell.currentIndex == 3, onTap: () => go(3)),
        ]),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).colorScheme.primary : Colors.black45;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Badge(
            isLabelVisible: badge > 0,
            label: Text('$badge'),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ]),
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Icon(Icons.swap_horiz_rounded, size: 72)),
      );
}

class _Offline extends ConsumerWidget {
  const _Offline();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: ErrorView(
          message: 'لا يوجد اتصال بالإنترنت.\nسنحاول مجدداً عند الضغط على إعادة المحاولة.',
          onRetry: () => ref.read(sessionProvider.notifier).refresh(),
        ),
      );
}
