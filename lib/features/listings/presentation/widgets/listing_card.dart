import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import '../../../reference/domain/reference_models.dart';
import '../../../reference/presentation/reference_providers.dart';
import '../../domain/listing.dart';

/// نص «ماذا يريد مقابله؟» المختصر
String wantsSummary(Listing l, ReferenceData? ref) {
  final parts = <String>[
    for (final w in l.wants)
      w.keyword?.isNotEmpty == true
          ? w.keyword!
          : (ref?.category(w.categoryId)?.nameAr ?? ''),
  ].where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty && l.wantsNote.isNotEmpty) parts.add(l.wantsNote);
  if (l.wantsAnything) parts.add('أي شيء مناسب');
  return parts.isEmpty ? 'مفتوح للعروض' : parts.join('، ');
}

class ListingCard extends ConsumerWidget {
  const ListingCard({super.key, required this.listing, this.onTap});
  final Listing listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urls = ref.watch(storageUrlsProvider);
    final refData = ref.watch(referenceDataProvider).value;
    final l = listing;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.push('/listing/${l.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(l.coverImage == null ? null : urls.listingImage(l.coverImage!)),
                  Positioned(top: 8, right: 8, child: Pill(l.condition.label)),
                  if (l.status != ListingStatus.active)
                    Positioned(
                        top: 8, left: 8, child: Pill(l.status.label, color: AppColors.warning))
                  else if (l.isEndingSoon)
                    const Positioned(
                        top: 8, left: 8, child: Pill('⚡ ينتهي قريباً', color: AppColors.danger)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(wantsSummary(l, refData),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.place_outlined, size: 14, color: AppColors.muted),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(refData?.placeLabel(l.governorateId, l.areaId) ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color ?? Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
      );
}

/// شبكة إعلانات متجاوبة (Sliver)
class ListingGrid extends StatelessWidget {
  const ListingGrid({super.key, required this.listings});
  final List<Listing> listings;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        itemCount: listings.length,
        itemBuilder: (_, i) => ListingCard(listing: listings[i]),
      ),
    );
  }
}

/// بطاقة صغيرة أفقية (للعروض والمطابقات)
class ListingTile extends ConsumerWidget {
  const ListingTile({super.key, required this.listing, this.trailing, this.onTap});
  final Listing listing;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urls = ref.watch(storageUrlsProvider);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap ?? () => context.push('/listing/${listing.id}'),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 56,
          height: 56,
          child: NetImage(
              listing.coverImage == null ? null : urls.listingImage(listing.coverImage!)),
        ),
      ),
      title: Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(listing.condition.label),
      trailing: trailing,
    );
  }
}
