import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/listing.dart';
import '../domain/listing_filter.dart';

class FilterController extends Notifier<ListingFilter> {
  @override
  ListingFilter build() => const ListingFilter();

  void set(ListingFilter filter) => state = filter;
}

final listingFilterProvider =
    NotifierProvider<FilterController, ListingFilter>(FilterController.new);

class FeedPage {
  const FeedPage(this.items, {required this.hasMore, this.loadingMore = false});
  final List<Listing> items;
  final bool hasMore;
  final bool loadingMore;
}

/// صفحة الإعلانات مع التحميل التدريجي
class FeedController extends AsyncNotifier<FeedPage> {
  static const pageSize = 30;

  @override
  Future<FeedPage> build() async {
    final filter = ref.watch(listingFilterProvider);
    final items = await ref.read(listingRepositoryProvider).feed(filter, limit: pageSize);
    return FeedPage(items, hasMore: items.length == pageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(FeedPage(current.items, hasMore: true, loadingMore: true));
    try {
      final more = await ref.read(listingRepositoryProvider).feed(
            ref.read(listingFilterProvider),
            offset: current.items.length,
            limit: pageSize,
          );
      state = AsyncData(FeedPage([...current.items, ...more], hasMore: more.length == pageSize));
    } catch (_) {
      state = AsyncData(FeedPage(current.items, hasMore: true));
    }
  }
}

final feedProvider = AsyncNotifierProvider<FeedController, FeedPage>(FeedController.new);

final listingProvider = FutureProvider.autoDispose.family<Listing, String>(
  (ref, id) => ref.watch(listingRepositoryProvider).getById(id),
);

final isFavoriteProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, id) => ref.watch(listingRepositoryProvider).isFavorite(id),
);

/// أغراضي (لاختيار ما أقدّمه في العرض، ولصفحة حسابي)
final myListingsProvider = FutureProvider.autoDispose<List<Listing>>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const [];
  return ref.watch(listingRepositoryProvider).byOwner(uid, onlyActive: false);
});

final userListingsProvider = FutureProvider.autoDispose.family<List<Listing>, String>(
  (ref, uid) => ref.watch(listingRepositoryProvider).byOwner(uid),
);

final favoritesProvider = FutureProvider.autoDispose<List<Listing>>(
  (ref) => ref.watch(listingRepositoryProvider).favorites(),
);
