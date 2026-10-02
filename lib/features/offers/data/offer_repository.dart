import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/offer.dart';

abstract interface class OfferRepository {
  Future<String> create({
    required List<String> requestedListingIds,
    required List<String> offeredListingIds,
    double cashAmount = 0,
    CashPayer cashPayer = CashPayer.none,
    String message = '',
    String? parentOfferId,
  });
  Future<List<SwapOffer>> incoming();
  Future<List<SwapOffer>> outgoing();
  Future<SwapOffer> getById(String id);
  Future<String?> respond(String offerId, {required bool accept});
  Future<void> cancel(String offerId);
  Future<OfferStatus> confirm(String offerId);
  Future<void> rate(String offerId, {required int stars, List<String> tags, String comment});
  Future<bool> hasRated(String offerId);
}

class SupabaseOfferRepository implements OfferRepository {
  SupabaseOfferRepository(this._db);
  final SupabaseClient _db;

  String get _uid => _db.auth.currentUser!.id;

  @override
  Future<String> create({
    required List<String> requestedListingIds,
    required List<String> offeredListingIds,
    double cashAmount = 0,
    CashPayer cashPayer = CashPayer.none,
    String message = '',
    String? parentOfferId,
  }) async {
    final id = await _db.rpc('create_offer', params: {
      'p_requested_listing_ids': requestedListingIds,
      'p_offered_listing_ids': offeredListingIds,
      'p_cash_amount': cashPayer == CashPayer.none ? 0 : cashAmount,
      'p_cash_payer': cashAmount == 0 ? 'none' : cashPayer.db,
      'p_message': message.trim(),
      'p_parent_offer_id': parentOfferId,
    });
    return id as String;
  }

  Future<List<SwapOffer>> _list(String column) async {
    final rows = await _db
        .from('swap_offers')
        .select(SwapOffer.select)
        .eq(column, _uid)
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(SwapOffer.fromJson).toList();
  }

  @override
  Future<List<SwapOffer>> incoming() => _list('receiver_id');

  @override
  Future<List<SwapOffer>> outgoing() => _list('sender_id');

  @override
  Future<SwapOffer> getById(String id) async {
    final row = await _db.from('swap_offers').select(SwapOffer.select).eq('id', id).single();
    return SwapOffer.fromJson(row);
  }

  @override
  Future<String?> respond(String offerId, {required bool accept}) async {
    final conv = await _db.rpc('respond_offer', params: {
      'p_offer_id': offerId,
      'p_accept': accept,
    });
    return conv as String?;
  }

  @override
  Future<void> cancel(String offerId) =>
      _db.rpc('cancel_offer', params: {'p_offer_id': offerId});

  @override
  Future<OfferStatus> confirm(String offerId) async {
    final s = await _db.rpc('confirm_swap', params: {'p_offer_id': offerId});
    return OfferStatus.fromDb(s as String);
  }

  @override
  Future<void> rate(String offerId,
          {required int stars, List<String> tags = const [], String comment = ''}) =>
      _db.rpc('rate_swap', params: {
        'p_offer_id': offerId,
        'p_stars': stars,
        'p_tags': tags,
        'p_comment': comment.trim(),
      });

  @override
  Future<bool> hasRated(String offerId) async {
    final row = await _db
        .from('ratings')
        .select('id')
        .eq('offer_id', offerId)
        .eq('from_user', _uid)
        .maybeSingle();
    return row != null;
  }
}
