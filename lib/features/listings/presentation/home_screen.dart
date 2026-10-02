import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/session.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../reference/presentation/reference_providers.dart';
import 'filter_sheet.dart';
import 'listing_providers.dart';
import 'widgets/listing_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search.text = ref.read(listingFilterProvider).query;
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) {
        ref.read(feedProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      final f = ref.read(listingFilterProvider);
      ref.read(listingFilterProvider.notifier).set(f.copyWith(query: text));
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(listingFilterProvider);
    final feed = ref.watch(feedProvider);
    final refData = ref.watch(referenceDataProvider).value;
    final me = ref.watch(myProfileProvider);
    final nearMe = me?.governorateId != null && filter.governorateId == me!.governorateId;

    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 30),
          SizedBox(width: 6),
          Text('بدّلها'),
        ]),
        actions: const [NotificationBell()],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(feedProvider.future),
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: _onSearch,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'ابحث: لوح شمسي، هاتف، خيمة…',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'الفلاتر',
                    onPressed: () => showFilterSheet(context),
                    icon: Badge(
                      isLabelVisible: filter.activeCount > 0,
                      label: Text('${filter.activeCount}'),
                      child: const Icon(Icons.tune_rounded),
                    ),
                  ),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (me?.governorateId != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: FilterChip(
                          avatar: const Icon(Icons.place_rounded, size: 18),
                          label: const Text('قريب مني'),
                          selected: nearMe,
                          onSelected: (v) => ref.read(listingFilterProvider.notifier).set(
                              filter.copyWith(
                                  governorateId: () => v ? me!.governorateId : null,
                                  areaId: () => null)),
                        ),
                      ),
                    for (final c in refData?.categories ?? const [])
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          avatar: Icon(categoryIcon(c.icon), size: 18),
                          label: Text(c.nameAr),
                          selected: filter.categoryId == c.id,
                          onSelected: (v) => ref
                              .read(listingFilterProvider.notifier)
                              .set(filter.copyWith(categoryId: () => v ? c.id : null)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ...feed.when(
              loading: () => [
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  child: ErrorView(
                    message: 'تعذّر تحميل الإعلانات. تحقق من الاتصال.',
                    onRetry: () => ref.invalidate(feedProvider),
                  ),
                ),
              ],
              data: (page) => page.items.isEmpty
                  ? [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyView(
                          icon: Icons.inventory_2_outlined,
                          title: 'لا توجد أغراض مطابقة',
                          subtitle: 'جرّب بحثاً آخر أو أضف غرضك ليبدأ الآخرون بالتبديل معك',
                          action: FilledButton.icon(
                            onPressed: () => context.push('/add'),
                            icon: const Icon(Icons.add),
                            label: const Text('أضف شيئاً للتبادل'),
                          ),
                        ),
                      ),
                    ]
                  : [
                      ListingGrid(listings: page.items),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: page.loadingMore
                                ? const CircularProgressIndicator()
                                : const SizedBox(height: 60),
                          ),
                        ),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}
