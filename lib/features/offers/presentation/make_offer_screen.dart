import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic.dart';
import '../../../core/widgets/common.dart';
import '../../listings/domain/listing.dart';
import '../../listings/presentation/listing_providers.dart';
import '../../listings/presentation/widgets/listing_card.dart';
import '../domain/offer.dart';
import 'offer_providers.dart';

/// إعداد العرض: من أين نبدأ (إعلان جديد أو رد بعرض معاكس)
class OfferSetup {
  const OfferSetup({
    required this.otherUserId,
    required this.otherUserName,
    this.initialRequested = const {},
    this.initialOffered = const {},
    this.parentOfferId,
  });

  final String otherUserId;
  final String otherUserName;
  final Set<String> initialRequested;
  final Set<String> initialOffered;
  final String? parentOfferId;

  bool get isCounter => parentOfferId != null;
}

/// يبني الإعداد من إعلان (اقترح تبادل)
final offerSetupFromListingProvider =
    FutureProvider.autoDispose.family<OfferSetup, String>((ref, listingId) async {
  final l = await ref.watch(listingProvider(listingId).future);
  return OfferSetup(
    otherUserId: l.ownerId,
    otherUserName: l.owner?.displayName ?? '',
    initialRequested: {l.id},
  );
});

/// يبني الإعداد من عرض وارد (عرض معاكس): الأدوار تنعكس
final offerSetupFromCounterProvider =
    FutureProvider.autoDispose.family<OfferSetup, String>((ref, offerId) async {
  final o = await ref.watch(offerProvider(offerId).future);
  return OfferSetup(
    otherUserId: o.senderId,
    otherUserName: o.sender?.displayName ?? '',
    initialRequested: o.senderItems.map((l) => l.id).toSet(),
    initialOffered: o.receiverItems.map((l) => l.id).toSet(),
    parentOfferId: o.id,
  );
});

class MakeOfferScreen extends ConsumerWidget {
  const MakeOfferScreen.forListing(String listingId, {super.key})
      : _listingId = listingId,
        _counterOfferId = null;

  const MakeOfferScreen.counter(String offerId, {super.key})
      : _listingId = null,
        _counterOfferId = offerId;

  final String? _listingId;
  final String? _counterOfferId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = _listingId != null
        ? ref.watch(offerSetupFromListingProvider(_listingId))
        : ref.watch(offerSetupFromCounterProvider(_counterOfferId!));
    return Scaffold(
      appBar: AppBar(title: Text(_counterOfferId != null ? 'عرض معاكس' : 'اقترح تبادل')),
      body: AsyncView(value: setup, data: (s) => _OfferForm(setup: s)),
    );
  }
}

class _OfferForm extends ConsumerStatefulWidget {
  const _OfferForm({required this.setup});
  final OfferSetup setup;

  @override
  ConsumerState<_OfferForm> createState() => _OfferFormState();
}

class _OfferFormState extends ConsumerState<_OfferForm> {
  late final Set<String> _requested = {...widget.setup.initialRequested};
  late final Set<String> _offered = {...widget.setup.initialOffered};
  final _cash = TextEditingController();
  final _message = TextEditingController();

  /// none = بدون فرق، me = أنا أدفع، them = هو يدفع
  String _cashMode = 'none';
  bool _busy = false;

  @override
  void dispose() {
    _cash.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_requested.isEmpty || _offered.isEmpty) {
      showMessage(context, 'اختر غرضاً واحداً على الأقل من كل طرف', error: true);
      return;
    }
    final amount = double.tryParse(toLatinDigits(_cash.text.trim())) ?? 0;
    if (_cashMode != 'none' && amount <= 0) {
      showMessage(context, 'اكتب مبلغ الفرق', error: true);
      return;
    }
    setState(() => _busy = true);
    String? id;
    final ok = await runGuarded(context, () async {
      id = await ref.read(offerRepositoryProvider).create(
            requestedListingIds: _requested.toList(),
            offeredListingIds: _offered.toList(),
            cashAmount: _cashMode == 'none' ? 0 : amount,
            // المرسل هو أنا: «أنا أدفع» = sender
            cashPayer: switch (_cashMode) {
              'me' => CashPayer.sender,
              'them' => CashPayer.receiver,
              _ => CashPayer.none,
            },
            message: _message.text,
            parentOfferId: widget.setup.parentOfferId,
          );
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok && id != null) {
      ref.invalidate(incomingOffersProvider);
      ref.invalidate(outgoingOffersProvider);
      if (widget.setup.parentOfferId != null) {
        ref.invalidate(offerProvider(widget.setup.parentOfferId!));
      }
      showMessage(context, 'تم إرسال العرض ✅');
      context.pushReplacement('/offer/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theirs = ref.watch(userListingsProvider(widget.setup.otherUserId));
    final mine = ref.watch(myListingsProvider);
    final name = widget.setup.otherUserName;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _header('تريد من $name'),
        AsyncView(
          value: theirs,
          data: (items) => _Selectable(
            items: items,
            selected: _requested,
            emptyText: 'لا توجد أغراض متاحة لدى $name',
            onToggle: (id) => setState(() => _requested.contains(id) ? _requested.remove(id) : _requested.add(id)),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: Icon(Icons.swap_vert_rounded, size: 36, color: AppColors.primary)),
        ),
        _header('تقدّم مقابله'),
        AsyncView(
          value: mine,
          data: (items) {
            final active = items.where((l) => l.status == ListingStatus.active).toList();
            if (active.isEmpty) {
              return EmptyView(
                icon: Icons.inventory_2_outlined,
                title: 'ليس لديك أغراض معروضة',
                subtitle: 'أضف غرضاً أولاً ثم ارجع لتقديم العرض',
                action: OutlinedButton(
                  onPressed: () => context.push('/add'),
                  child: const Text('أضف غرضاً'),
                ),
              );
            }
            return _Selectable(
              items: active,
              selected: _offered,
              emptyText: '',
              onToggle: (id) => setState(() => _offered.contains(id) ? _offered.remove(id) : _offered.add(id)),
            );
          },
        ),
        _header('💵 فرق نقدي'),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'none', label: Text('بدون')),
            ButtonSegment(value: 'me', label: Text('أنا أدفع')),
            ButtonSegment(value: 'them', label: Text('هو يدفع')),
          ],
          selected: {_cashMode},
          onSelectionChanged: (s) => setState(() => _cashMode = s.first),
        ),
        if (_cashMode != 'none') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _cash,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'المبلغ', suffixText: '₪'),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _message,
          maxLength: 500,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'رسالة قصيرة (اختياري)'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _busy ? null : _send,
          icon: const Icon(Icons.send_rounded),
          label: Text(widget.setup.isCounter ? 'أرسل العرض المعاكس' : 'أرسل عرض التبادل'),
        ),
      ],
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _Selectable extends StatelessWidget {
  const _Selectable({
    required this.items,
    required this.selected,
    required this.onToggle,
    required this.emptyText,
  });

  final List<Listing> items;
  final Set<String> selected;
  final void Function(String id) onToggle;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(emptyText, style: const TextStyle(color: AppColors.muted));
    }
    return Column(children: [
      for (final l in items)
        ListingTile(
          listing: l,
          onTap: () => onToggle(l.id),
          trailing: Checkbox(value: selected.contains(l.id), onChanged: (_) => onToggle(l.id)),
        ),
    ]);
  }
}
