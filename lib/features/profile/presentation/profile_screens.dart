import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/session.dart';
import '../../listings/presentation/listing_providers.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../../reference/presentation/reference_providers.dart';
import '../../safety/presentation/safety_actions.dart';
import '../domain/profile.dart';

final profileByIdProvider = FutureProvider.autoDispose.family<Profile, String>(
  (ref, id) => ref.watch(profileRepositoryProvider).getById(id),
);

final ratingsProvider = FutureProvider.autoDispose.family<List<Rating>, String>(
  (ref, id) => ref.watch(profileRepositoryProvider).ratingsOf(id),
);

/// رأس الملف الشخصي المشترك
class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key, required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urls = ref.watch(storageUrlsProvider);
    final refData = ref.watch(referenceDataProvider).value;
    final p = profile;
    return Column(children: [
      Avatar(name: p.displayName, url: urls.avatar(p.avatarPath), radius: 44),
      const SizedBox(height: 12),
      Text(p.displayName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(refData?.placeLabel(p.governorateId, p.areaId) ?? '',
          style: const TextStyle(color: AppColors.muted)),
      if (p.bio?.isNotEmpty ?? false)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(p.bio!, textAlign: TextAlign.center),
        ),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _Stat(
          value: p.ratingCount == 0 ? '—' : '${p.ratingAvg.toStringAsFixed(1)} ⭐',
          label: '${p.ratingCount} تقييم',
        ),
        _Stat(value: '${p.completedSwaps}', label: 'تبادل مكتمل'),
        _Stat(value: DateFormat.y('ar').format(p.createdAt), label: 'عضو منذ'),
      ]),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ]);
}

/// تبويب «حسابي»
class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(myProfileProvider);
    final listings = ref.watch(myListingsProvider);
    if (me == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        actions: [
          IconButton(
            tooltip: 'تعديل',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(sessionProvider.notifier).refresh();
          ref.invalidate(myListingsProvider);
        },
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                ProfileHeader(profile: me),
                const SizedBox(height: 16),
                Card(
                  child: Column(children: [
                    ListTile(
                      leading: const Icon(Icons.favorite_border_rounded),
                      title: const Text('المفضلة'),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => context.push('/favorites'),
                    ),
                    if (me.isAdmin)
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings_outlined),
                        title: const Text('لوحة الإشراف'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => context.push('/admin'),
                      ),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                      title: const Text('تسجيل الخروج'),
                      onTap: () => ref.read(authRepositoryProvider).signOut(),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('أغراضي', style: Theme.of(context).textTheme.titleMedium),
                ),
              ]),
            ),
          ),
          ...listings.when(
            loading: () => [const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))],
            error: (e, _) => [SliverToBoxAdapter(child: ErrorView(message: 'تعذّر التحميل', onRetry: () => ref.invalidate(myListingsProvider)))],
            data: (items) => items.isEmpty
                ? [
                    SliverToBoxAdapter(
                      child: EmptyView(
                        icon: Icons.inventory_2_outlined,
                        title: 'لم تضف أي غرض بعد',
                        action: FilledButton(
                          onPressed: () => context.push('/add'),
                          child: const Text('أضف أول غرض'),
                        ),
                      ),
                    ),
                  ]
                : [ListingGrid(listings: items)],
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
    );
  }
}

/// ملف مستخدم آخر
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileByIdProvider(userId));
    final listings = ref.watch(userListingsProvider(userId));
    final ratings = ref.watch(ratingsProvider(userId));
    final isMe = ref.watch(currentUserIdProvider) == userId;
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (!isMe && profile.hasValue)
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'report') showReportSheet(context, userId: userId);
                if (v == 'block' &&
                    await confirmAndBlock(context, ref, userId, profile.value!.displayName) &&
                    context.mounted) {
                  ref.invalidate(feedProvider);
                  context.pop();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'report', child: Text('🚩 إبلاغ')),
                PopupMenuItem(value: 'block', child: Text('حظر')),
              ],
            ),
        ],
      ),
      body: AsyncView(
        value: profile,
        onRetry: () => ref.invalidate(profileByIdProvider(userId)),
        data: (p) => CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(padding: const EdgeInsets.all(20), child: ProfileHeader(profile: p)),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('الأغراض المعروضة', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          if (listings.value case final items?)
            items.isEmpty
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('لا توجد أغراض معروضة حالياً', style: TextStyle(color: AppColors.muted)),
                    ),
                  )
                : ListingGrid(listings: items)
          else
            const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text('التقييمات', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          SliverList.list(children: [
            for (final r in ratings.value ?? const <Rating>[])
              ListTile(
                title: Row(children: [
                  Text('⭐' * r.stars),
                  const SizedBox(width: 8),
                  Text(r.fromName ?? '', style: const TextStyle(fontSize: 13)),
                ]),
                subtitle: Text([
                  ...r.tags.map((t) => Rating.tagLabels[t] ?? t),
                  if (r.comment.isNotEmpty) r.comment,
                ].join(' · ')),
                trailing: Text(timeAgo(r.createdAt), style: const TextStyle(fontSize: 12)),
              ),
            if (ratings.value?.isEmpty ?? false)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('لا توجد تقييمات بعد', style: TextStyle(color: AppColors.muted)),
              ),
            const SizedBox(height: 40),
          ]),
        ]),
      ),
    );
  }
}

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: AsyncView(
        value: value,
        onRetry: () => ref.invalidate(favoritesProvider),
        data: (items) => items.isEmpty
            ? const EmptyView(icon: Icons.favorite_border_rounded, title: 'لم تحفظ أي غرض بعد')
            : CustomScrollView(slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ListingGrid(listings: items),
              ]),
      ),
    );
  }
}
