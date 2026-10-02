import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/widgets/common.dart';
import '../../reference/presentation/reference_providers.dart';
import '../../safety/presentation/safety_actions.dart';
import '../domain/listing.dart';
import 'listing_providers.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(listingProvider(id));
    return Scaffold(
      body: AsyncView(
        value: value,
        onRetry: () => ref.invalidate(listingProvider(id)),
        data: (l) => _Body(listing: l),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.listing});
  final Listing listing;

  Future<void> _share(Listing l) => SharePlus.instance.share(ShareParams(
        text: '🔄 ${l.title}\nللتبادل على بدّلها:\n${Env.webBaseUrl}/l/${l.id}',
      ));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = listing;
    final urls = ref.watch(storageUrlsProvider);
    final refData = ref.watch(referenceDataProvider).value;
    final uid = ref.watch(currentUserIdProvider);
    final isMine = l.ownerId == uid;
    final fav = ref.watch(isFavoriteProvider(l.id)).value ?? false;
    final owner = l.owner;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: MediaQuery.sizeOf(context).width.clamp(250, 420),
              pinned: true,
              actions: [
                IconButton(
                  tooltip: 'مشاركة',
                  icon: const Icon(Icons.ios_share_rounded),
                  onPressed: () => _share(l),
                ),
                if (!isMine)
                  IconButton(
                    tooltip: 'حفظ',
                    icon: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: fav ? AppColors.danger : null),
                    onPressed: () async {
                      await runGuarded(context,
                          () => ref.read(listingRepositoryProvider).setFavorite(l.id, !fav));
                      ref.invalidate(isFavoriteProvider(l.id));
                    },
                  ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    switch (v) {
                      case 'report':
                        showReportSheet(context, listingId: l.id, userId: l.ownerId);
                      case 'remove':
                        final ok = await runGuarded(context,
                            () => ref.read(listingRepositoryProvider).setStatus(l.id, ListingStatus.removed));
                        if (ok && context.mounted) {
                          ref.invalidate(myListingsProvider);
                          ref.invalidate(feedProvider);
                          context.pop();
                        }
                      case 'renew':
                        await runGuarded(context,
                            () => ref.read(listingRepositoryProvider).setStatus(l.id, ListingStatus.active));
                        ref.invalidate(listingProvider(l.id));
                    }
                  },
                  itemBuilder: (_) => [
                    if (!isMine) const PopupMenuItem(value: 'report', child: Text('🚩 إبلاغ')),
                    if (isMine && l.status == ListingStatus.active)
                      const PopupMenuItem(value: 'remove', child: Text('حذف الإعلان')),
                    if (isMine && (l.status == ListingStatus.expired || l.status == ListingStatus.removed))
                      const PopupMenuItem(value: 'renew', child: Text('إعادة النشر')),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: l.images.isEmpty
                    ? const NetImage(null)
                    : PageView(
                        children: [
                          for (final p in l.images) NetImage(urls.listingImage(p), fit: BoxFit.cover),
                        ],
                      ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              sliver: SliverList.list(children: [
                if (l.images.length > 1)
                  Text('${l.images.length} صور — اسحب للمزيد',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                Text(l.title,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  Chip(
                    avatar: Icon(categoryIcon(refData?.category(l.categoryId)?.icon), size: 18),
                    label: Text(refData?.category(l.categoryId)?.nameAr ?? ''),
                  ),
                  Chip(label: Text(l.condition.label)),
                  if (l.estimatedValue != null)
                    Chip(label: Text('≈ ${NumberFormat.decimalPattern().format(l.estimatedValue)} ₪')),
                  if (l.status != ListingStatus.active) Chip(label: Text(l.status.label)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.place_outlined, size: 18, color: AppColors.muted),
                  const SizedBox(width: 4),
                  Text(refData?.placeLabel(l.governorateId, l.areaId) ?? ''),
                  const Spacer(),
                  Text(timeAgo(l.createdAt), style: const TextStyle(color: AppColors.muted)),
                ]),
                if (l.expiresAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        'ينتهي العرض: ${DateFormat('d MMM، h:mm a', 'ar').format(l.expiresAt!.toLocal())}',
                        style: TextStyle(
                            color: l.isEndingSoon ? AppColors.danger : AppColors.muted)),
                  ),
                const SizedBox(height: 20),
                _Section(
                  title: '🔄 ماذا يريد مقابله؟',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final w in l.wants)
                          Chip(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                            label: Text([
                              refData?.category(w.categoryId)?.nameAr,
                              w.keyword,
                            ].whereType<String>().join(' · ')),
                          ),
                        if (l.wantsAnything) const Chip(label: Text('أي شيء مناسب')),
                      ]),
                      if (l.wantsNote.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(l.wantsNote),
                      ],
                      if (l.acceptsCashDifference)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('💵 يقبل تبادل + فرق',
                              style: TextStyle(color: AppColors.muted)),
                        ),
                    ],
                  ),
                ),
                if (l.description.isNotEmpty)
                  _Section(title: 'الوصف', child: Text(l.description, style: const TextStyle(height: 1.6))),
                if (owner != null)
                  _Section(
                    title: 'صاحب الإعلان',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => context.push('/user/${owner.id}'),
                      leading: Avatar(name: owner.displayName, url: urls.avatar(owner.avatarPath)),
                      title: Text(owner.displayName),
                      subtitle: Text(
                          '${owner.completedSwaps} تبادل مكتمل · عضو منذ ${DateFormat.yMMM('ar').format(owner.createdAt)}'),
                      trailing: RatingBadge(rating: owner.ratingAvg, count: owner.ratingCount),
                    ),
                  ),
                const _SafetyTip(),
              ]),
            ),
          ],
        ),
        if (!isMine && l.status == ListingStatus.active)
          Positioned(
            left: 16, right: 16, bottom: 16,
            child: SafeArea(
              child: FilledButton.icon(
                onPressed: () => context.push('/offer/new/${l.id}'),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('اقترح تبادل'),
              ),
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}

class _SafetyTip extends StatelessWidget {
  const _SafetyTip();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '🛡️ للتبادل الآمن: التقِ في مكان عام ومعروف، افحص الغرض قبل التسليم، ولا تدفع أي مبلغ مسبقاً.',
          style: TextStyle(height: 1.5),
        ),
      );
}
