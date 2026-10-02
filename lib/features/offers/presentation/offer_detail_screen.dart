import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../listings/domain/listing.dart';
import '../../listings/presentation/listing_providers.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../../profile/domain/profile.dart';
import '../../safety/presentation/safety_actions.dart';
import '../domain/offer.dart';
import 'offer_providers.dart';
import 'offers_screen.dart';

class OfferDetailScreen extends ConsumerWidget {
  const OfferDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(offerProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل العرض')),
      body: AsyncView(
        value: value,
        onRetry: () => ref.invalidate(offerProvider(id)),
        data: (o) => _Body(offer: o),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.offer});
  final SwapOffer offer;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  SwapOffer get o => widget.offer;

  void _refreshAll() {
    ref.invalidate(offerProvider(o.id));
    ref.invalidate(incomingOffersProvider);
    ref.invalidate(outgoingOffersProvider);
    ref.invalidate(myListingsProvider);
    ref.invalidate(feedProvider);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await runGuarded(context, action);
    if (!mounted) return;
    setState(() => _busy = false);
    _refreshAll();
  }

  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد')),
          ],
        ),
      ) ??
      false;

  Future<void> _accept() async {
    if (!await _confirm('قبول العرض؟',
        'ستُحجز الأغراض لهذه الصفقة وتُلغى العروض الأخرى عليها، وتُفتح محادثة مع الطرف الآخر.')) {
      return;
    }
    String? conv;
    await _run(() async {
      conv = await ref.read(offerRepositoryProvider).respond(o.id, accept: true);
    });
    if (conv != null && mounted) context.push('/chat/$conv');
  }

  Future<void> _confirmSwap(String uid) async {
    if (!await _confirm('تأكيد إتمام التبادل؟',
        'أكّد فقط بعد أن استلمت الغرض وفحصته. يكتمل التبادل عندما يؤكد الطرفان.')) {
      return;
    }
    OfferStatus? result;
    await _run(() async {
      result = await ref.read(offerRepositoryProvider).confirm(o.id);
    });
    if (!mounted) return;
    if (result == OfferStatus.completed) {
      await showSwapCompleteDialog(context, o, uid);
    } else if (result == OfferStatus.accepted) {
      showMessage(context, 'تم تأكيدك. بانتظار تأكيد الطرف الآخر.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserIdProvider) ?? '';
    final urls = ref.watch(storageUrlsProvider);
    final other = o.otherParty(uid);
    final incoming = o.isIncomingFor(uid);
    final color = offerStatusColor(o.status);

    return AbsorbPointer(
      absorbing: _busy,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_statusExplanation(uid),
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          if (other != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => context.push('/user/${other.id}'),
              leading: Avatar(name: other.displayName, url: urls.avatar(other.avatarPath)),
              title: Text(other.displayName),
              subtitle: Text('${other.completedSwaps} تبادل مكتمل'),
              trailing: RatingBadge(rating: other.ratingAvg, count: other.ratingCount),
            ),
          _side('أنت تعطي', o.myItems(uid)),
          const Center(child: Icon(Icons.swap_vert_rounded, size: 32, color: AppColors.primary)),
          _side('أنت تأخذ', o.theirItems(uid)),
          if (o.cashAmount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(cashLabel(o, uid), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          if (o.message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('💬 ${o.message}'),
            ),
          ],
          const SizedBox(height: 24),
          ..._actions(uid, incoming, other),
        ],
      ),
    );
  }

  String _statusExplanation(String uid) => switch (o.status) {
        OfferStatus.pending when o.isIncomingFor(uid) => 'وصلك هذا العرض. يمكنك القبول أو الرفض أو تقديم عرض معاكس.',
        OfferStatus.pending => 'بانتظار رد الطرف الآخر.',
        OfferStatus.accepted when o.confirmedBy(uid) => 'أكّدت الاستلام. بانتظار تأكيد الطرف الآخر.',
        OfferStatus.accepted => 'تم قبول العرض 🎉 تواصلا عبر المحادثة لترتيب التسليم.',
        OfferStatus.completed => 'تم التبادل بنجاح ✅',
        OfferStatus.rejected => 'تم رفض العرض.',
        OfferStatus.countered => 'تم الرد على هذا العرض بعرض معاكس.',
        OfferStatus.cancelled => 'تم إلغاء العرض.',
      };

  Widget _side(String title, List<Listing> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          for (final l in items) ListingTile(listing: l),
        ],
      );

  List<Widget> _actions(String uid, bool incoming, Profile? other) {
    final repo = ref.read(offerRepositoryProvider);
    const gap = SizedBox(height: 10);
    switch (o.status) {
      case OfferStatus.pending when incoming:
        return [
          FilledButton.icon(
            onPressed: _accept,
            icon: const Icon(Icons.check_rounded),
            label: const Text('قبول'),
          ),
          gap,
          OutlinedButton.icon(
            onPressed: () => context.push('/offer/${o.id}/counter'),
            icon: const Icon(Icons.sync_alt_rounded),
            label: const Text('عرض معاكس'),
          ),
          gap,
          TextButton(
            onPressed: () => _run(() => repo.respond(o.id, accept: false)),
            child: const Text('رفض', style: TextStyle(color: AppColors.danger)),
          ),
          ..._safety(other),
        ];
      case OfferStatus.pending:
        return [
          OutlinedButton(
            onPressed: () => _run(() => repo.cancel(o.id)),
            child: const Text('سحب العرض'),
          ),
        ];
      case OfferStatus.accepted:
        return [
          if (o.conversationId != null)
            FilledButton.icon(
              onPressed: () => context.push('/chat/${o.conversationId}'),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('المحادثة'),
            ),
          gap,
          if (!o.confirmedBy(uid))
            OutlinedButton.icon(
              onPressed: () => _confirmSwap(uid),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('استلمت الغرض — تأكيد الإتمام'),
            ),
          gap,
          TextButton(
            onPressed: () async {
              if (await _confirm('إلغاء الصفقة؟', 'ستعود الأغراض متاحة للتبادل.')) {
                await _run(() => repo.cancel(o.id));
              }
            },
            child: const Text('إلغاء الصفقة', style: TextStyle(color: AppColors.danger)),
          ),
          ..._safety(other),
        ];
      case OfferStatus.completed:
        final rated = ref.watch(hasRatedProvider(o.id)).value ?? true;
        return [
          if (!rated)
            FilledButton.icon(
              onPressed: () async {
                final done = await showRatingSheet(context, o.id, other?.displayName ?? '');
                if (done) ref.invalidate(hasRatedProvider(o.id));
              },
              icon: const Icon(Icons.star_rounded),
              label: Text('قيّم ${other?.displayName ?? ''}'),
            ),
          gap,
          OutlinedButton.icon(
            onPressed: () => shareSwap(o, uid),
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('شارك تبديلتك'),
          ),
          if (o.conversationId != null)
            TextButton(
              onPressed: () => context.push('/chat/${o.conversationId}'),
              child: const Text('المحادثة'),
            ),
        ];
      default:
        return const [];
    }
  }

  List<Widget> _safety(Profile? other) => [
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton.icon(
            onPressed: () => showReportSheet(context, userId: o.otherPartyId(ref.read(currentUserIdProvider)!)),
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('إبلاغ'),
          ),
          if (other != null)
            TextButton.icon(
              onPressed: () async {
                if (await confirmAndBlock(context, ref, other.id, other.displayName) && mounted) {
                  context.pop();
                }
              },
              icon: const Icon(Icons.block_rounded, size: 18),
              label: const Text('حظر'),
            ),
        ]),
      ];
}

Future<void> shareSwap(SwapOffer o, String uid) {
  final gave = o.myItems(uid).map((l) => l.title).join(' + ');
  final got = o.theirItems(uid).map((l) => l.title).join(' + ');
  return SharePlus.instance.share(ShareParams(
    text: 'بدّلت $gave مقابل $got 🔄\n'
        'أنت تملك ما لا تحتاجه، وغيرك يملك ما تحتاجه. بدّلها!\n${Env.webBaseUrl}',
  ));
}

Future<void> showSwapCompleteDialog(BuildContext context, SwapOffer o, String uid) => showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.celebration_rounded, size: 56, color: AppColors.success),
        title: const Text('🎉 تم التبادل!'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(o.myItems(uid).map((l) => l.title).join(' + '), textAlign: TextAlign.center),
          const Icon(Icons.swap_vert_rounded, color: AppColors.primary),
          Text(o.theirItems(uid).map((l) => l.title).join(' + '),
              textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لاحقاً')),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              shareSwap(o, uid);
            },
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('شارك تبديلتك'),
          ),
        ],
      ),
    );

/// التقييم بعد الإتمام. يرجع true عند الإرسال.
Future<bool> showRatingSheet(BuildContext context, String offerId, String name) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RatingSheet(offerId: offerId, name: name),
    ) ??
    false;

class _RatingSheet extends ConsumerStatefulWidget {
  const _RatingSheet({required this.offerId, required this.name});
  final String offerId;
  final String name;

  @override
  ConsumerState<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends ConsumerState<_RatingSheet> {
  int _stars = 0;
  final _tags = <String>{};
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('كيف كان التبادل مع ${widget.name}؟',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                iconSize: 40,
                onPressed: () => setState(() => _stars = i),
                icon: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.warning),
              ),
          ]),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            for (final e in Rating.tagLabels.entries)
              FilterChip(
                label: Text(e.value),
                selected: _tags.contains(e.key),
                onSelected: (v) => setState(() => v ? _tags.add(e.key) : _tags.remove(e.key)),
              ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _comment,
            maxLength: 500,
            decoration: const InputDecoration(hintText: 'تعليق (اختياري)'),
          ),
          FilledButton(
            onPressed: _stars == 0 || _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    final ok = await runGuarded(
                      context,
                      () => ref.read(offerRepositoryProvider).rate(
                            widget.offerId,
                            stars: _stars,
                            tags: _tags.toList(),
                            comment: _comment.text,
                          ),
                    );
                    if (!mounted) return;
                    setState(() => _busy = false);
                    if (ok) Navigator.pop(this.context, true);
                  },
            child: const Text('إرسال التقييم'),
          ),
        ],
      ),
    );
  }
}
