import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../domain/match.dart';

final matchesProvider = FutureProvider.autoDispose<List<SwapMatch>>(
  (ref) => ref.watch(matchRepositoryProvider).findMatches(),
);

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(matchesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('🎯 مطابقات لك')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(matchesProvider.future),
        child: AsyncView(
          value: value,
          onRetry: () => ref.invalidate(matchesProvider),
          data: (matches) => matches.isEmpty
              ? ListView(children: [
                  const SizedBox(height: 60),
                  EmptyView(
                    icon: Icons.track_changes_rounded,
                    title: 'لا توجد مطابقات حالياً',
                    subtitle:
                        'نبحث عن أشخاص يملكون ما تريده ويريدون ما تملكه.\nأضف أغراضاً وحدّد بدقة ماذا تريد مقابلها.',
                    action: FilledButton.icon(
                      onPressed: () => context.push('/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('أضف شيئاً للتبادل'),
                    ),
                  ),
                ])
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('وجدنا ${matches.length} تطابقاً قد يناسبك',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    for (final m in matches) ...[
                      _MatchCard(match: m),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});
  final SwapMatch match;

  @override
  Widget build(BuildContext context) {
    final owner = match.theirs.owner;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🔥 تطابق', style: TextStyle(fontWeight: FontWeight.w800)),
              if (match.isNearby) ...[
                const SizedBox(width: 8),
                const Text('📍 قريب منك', style: TextStyle(color: AppColors.success)),
              ],
              const Spacer(),
              if (owner != null) RatingBadge(rating: owner.ratingAvg, count: owner.ratingCount),
            ]),
            const SizedBox(height: 4),
            const Text('أنت تملك:', style: TextStyle(color: AppColors.muted)),
            ListingTile(listing: match.mine),
            Text('${owner?.displayName ?? 'هو'} يملك ويريد ما لديك:',
                style: const TextStyle(color: AppColors.muted)),
            ListingTile(listing: match.theirs),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => context.push('/offer/new/${match.theirs.id}'),
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('اقترح التبادل'),
            ),
          ],
        ),
      ),
    );
  }
}
