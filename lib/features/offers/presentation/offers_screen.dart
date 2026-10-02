import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/widgets/common.dart';
import '../domain/offer.dart';
import 'offer_providers.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref.watch(incomingOffersProvider);
    final pendingIn =
        incoming.value?.where((o) => o.status == OfferStatus.pending).length ?? 0;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عروضي'),
          bottom: TabBar(tabs: [
            Tab(
              child: Badge(
                isLabelVisible: pendingIn > 0,
                label: Text('$pendingIn'),
                offset: const Offset(-14, -4),
                child: const Text('الواردة'),
              ),
            ),
            const Tab(text: 'المرسلة'),
          ]),
        ),
        body: TabBarView(children: [
          _OfferList(provider: incomingOffersProvider, emptyText: 'لم تصلك عروض بعد'),
          _OfferList(provider: outgoingOffersProvider, emptyText: 'لم ترسل أي عرض بعد'),
        ]),
      ),
    );
  }
}

class _OfferList extends ConsumerWidget {
  const _OfferList({required this.provider, required this.emptyText});
  final FutureProvider<List<SwapOffer>> provider;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(provider.future),
      child: AsyncView(
        value: ref.watch(provider),
        onRetry: () => ref.invalidate(provider),
        data: (offers) => offers.isEmpty
            ? ListView(children: [
                const SizedBox(height: 80),
                EmptyView(icon: Icons.swap_horiz_rounded, title: emptyText),
              ])
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: offers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => OfferCard(offer: offers[i]),
              ),
      ),
    );
  }
}

Color offerStatusColor(OfferStatus s) => switch (s) {
      OfferStatus.pending => AppColors.warning,
      OfferStatus.accepted => AppColors.primary,
      OfferStatus.completed => AppColors.success,
      OfferStatus.rejected || OfferStatus.cancelled => AppColors.muted,
      OfferStatus.countered => AppColors.primary,
    };

class OfferCard extends ConsumerWidget {
  const OfferCard({super.key, required this.offer});
  final SwapOffer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider) ?? '';
    final other = offer.otherParty(uid);
    String titles(List items) => items.map((l) => l.title).join(' + ');
    final color = offerStatusColor(offer.status);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/offer/${offer.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(other?.displayName ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(offer.status.label, style: TextStyle(color: color, fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 10),
              Text('تعطي: ${titles(offer.myItems(uid))}', maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('تأخذ: ${titles(offer.theirItems(uid))}', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.primary)),
              if (offer.cashAmount > 0)
                Text(cashLabel(offer, uid), style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 6),
              Text(timeAgo(offer.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

String cashLabel(SwapOffer o, String uid) {
  final v = o.cashFromMe(uid);
  if (v == 0) return '';
  final amount = v.abs().toStringAsFixed(v.abs() % 1 == 0 ? 0 : 2);
  return v > 0 ? '💵 + تدفع فرق $amount ₪' : '💵 + تستلم فرق $amount ₪';
}
