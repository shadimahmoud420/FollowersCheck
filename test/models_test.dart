import 'package:badelha/features/listings/domain/listing.dart';
import 'package:badelha/features/listings/domain/listing_filter.dart';
import 'package:badelha/features/notifications/domain/app_notification.dart';
import 'package:badelha/features/offers/domain/offer.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> listingJson(String id, String owner, {String status = 'active'}) => {
      'id': id,
      'owner_id': owner,
      'title': 'لوح شمسي $id',
      'description': '',
      'category_id': 1,
      'condition': 'good',
      'estimated_value': 400,
      'images': ['$owner/a.jpg'],
      'governorate_id': 2,
      'area_id': 5,
      'wants_anything': false,
      'wants_note': '',
      'accepts_cash_difference': true,
      'status': status,
      'expires_at': null,
      'created_at': '2026-10-01T10:00:00Z',
    };

void main() {
  group('Listing', () {
    test('parses relations from Supabase JSON', () {
      final l = Listing.fromJson({
        ...listingJson('l1', 'u1'),
        'wants': [
          {'category_id': 2, 'keyword': 'سامسونج'},
        ],
        'owner': {
          'id': 'u1',
          'display_name': 'أحمد',
          'rating_avg': 4.9,
          'rating_count': 12,
          'completed_swaps': 27,
          'created_at': '2026-01-01T00:00:00Z',
        },
      });
      expect(l.condition, ItemCondition.good);
      expect(l.estimatedValue, 400);
      expect(l.coverImage, 'u1/a.jpg');
      expect(l.wants.single, const ListingWant(categoryId: 2, keyword: 'سامسونج'));
      expect(l.owner!.ratingAvg, 4.9);
      expect(l.owner!.completedSwaps, 27);
    });

    test('unknown enum values fall back safely', () {
      final l = Listing.fromJson({...listingJson('l1', 'u1'), 'condition': '???', 'status': '???'});
      expect(l.condition, ItemCondition.used);
      expect(l.status, ListingStatus.active);
    });

    test('ListingDraft.toRow computes expiry and trims text', () {
      final now = DateTime.utc(2026, 10, 2, 12);
      final row = ListingDraft(
        title: '  خيمة  ',
        description: ' جيدة ',
        categoryId: 5,
        condition: ItemCondition.good,
        governorateId: 4,
        duration: ListingDuration.threeDays,
      ).toRow(images: ['x.jpg'], now: now);
      expect(row['title'], 'خيمة');
      expect(row['description'], 'جيدة');
      expect(row['condition'], 'good');
      expect(row['expires_at'], '2026-10-05T12:00:00.000Z');
      expect(row['images'], ['x.jpg']);
    });

    test('open duration has no expiry', () {
      final row = ListingDraft(
        title: 'x', description: '', categoryId: 1,
        condition: ItemCondition.good, governorateId: 1,
      ).toRow(images: const []);
      expect(row['expires_at'], isNull);
    });
  });

  group('SwapOffer perspective', () {
    final offer = SwapOffer.fromJson({
      'id': 'o1',
      'sender_id': 'A',
      'receiver_id': 'B',
      'status': 'accepted',
      'cash_amount': 50,
      'cash_payer': 'receiver',
      'message': '',
      'sender_confirmed_at': '2026-10-02T10:00:00Z',
      'created_at': '2026-10-02T09:00:00Z',
      'items': [
        {'side': 'sender', 'listing': listingJson('a1', 'A', status: 'reserved')},
        {'side': 'receiver', 'listing': listingJson('b1', 'B', status: 'reserved')},
      ],
      'conversation': {'id': 'c1'},
    });

    test('splits items by side and reads conversation', () {
      expect(offer.senderItems.single.id, 'a1');
      expect(offer.receiverItems.single.id, 'b1');
      expect(offer.conversationId, 'c1');
    });

    test('my/their items depend on who is looking', () {
      expect(offer.myItems('A').single.id, 'a1');
      expect(offer.theirItems('A').single.id, 'b1');
      expect(offer.myItems('B').single.id, 'b1');
      expect(offer.otherPartyId('B'), 'A');
    });

    test('cash direction: receiver pays', () {
      expect(offer.cashFromMe('B'), 50);
      expect(offer.cashFromMe('A'), -50);
    });

    test('confirmation per party', () {
      expect(offer.confirmedBy('A'), isTrue);
      expect(offer.confirmedBy('B'), isFalse);
    });

    test('conversation as list (PostgREST one-to-many shape)', () {
      final o = SwapOffer.fromJson({
        'id': 'o2', 'sender_id': 'A', 'receiver_id': 'B', 'status': 'pending',
        'created_at': '2026-10-02T09:00:00Z', 'items': [],
        'conversation': [{'id': 'c9'}],
      });
      expect(o.conversationId, 'c9');
      expect(o.cashPayer, CashPayer.none);
    });
  });

  group('ListingFilter', () {
    test('copyWith can clear nullable fields', () {
      const f = ListingFilter(categoryId: 3, governorateId: 2);
      final cleared = f.copyWith(governorateId: () => null);
      expect(cleared.governorateId, isNull);
      expect(cleared.categoryId, 3);
    });

    test('activeCount ignores query and category', () {
      expect(const ListingFilter(query: 'x', categoryId: 1).activeCount, 0);
      expect(const ListingFilter(governorateId: 1, sort: ListingSort.valueHigh).activeCount, 2);
    });

    test('value equality (used to cache feed requests)', () {
      expect(const ListingFilter(query: 'a'), const ListingFilter(query: 'a'));
    });
  });

  group('AppNotification routing', () {
    AppNotification n(String type, Map<String, dynamic> payload) => AppNotification.fromJson(
        {'id': 1, 'type': type, 'payload': payload, 'created_at': '2026-10-02T09:00:00Z'});

    test('routes to the right screen', () {
      expect(n('new_message', {'conversation_id': 'c1'}).route, '/chat/c1');
      expect(n('offer_received', {'offer_id': 'o1'}).route, '/offer/o1');
      expect(n('listing_saved', {'listing_id': 'l1'}).route, '/listing/l1');
      expect(n('unknown', {}).route, isNull);
    });

    test('explains offers cancelled because items were reserved', () {
      expect(n('offer_cancelled', {'offer_id': 'o', 'reason': 'items_reserved'}).subtitle,
          contains('حُجز'));
    });
  });
}
