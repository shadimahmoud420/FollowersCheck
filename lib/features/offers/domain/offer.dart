import '../../listings/domain/listing.dart';
import '../../profile/domain/profile.dart';

enum OfferStatus {
  pending('pending', 'بانتظار الرد'),
  accepted('accepted', 'مقبول'),
  rejected('rejected', 'مرفوض'),
  countered('countered', 'عرض معاكس'),
  cancelled('cancelled', 'ملغي'),
  completed('completed', 'تم التبادل');

  const OfferStatus(this.db, this.label);
  final String db;
  final String label;

  static OfferStatus fromDb(String v) =>
      values.firstWhere((s) => s.db == v, orElse: () => OfferStatus.pending);
}

/// من يدفع فرق القيمة
enum CashPayer {
  none('none'),
  sender('sender'),
  receiver('receiver');

  const CashPayer(this.db);
  final String db;

  static CashPayer fromDb(String v) =>
      values.firstWhere((s) => s.db == v, orElse: () => CashPayer.none);
}

class SwapOffer {
  const SwapOffer({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.parentOfferId,
    required this.status,
    required this.cashAmount,
    required this.cashPayer,
    required this.message,
    this.senderConfirmedAt,
    this.receiverConfirmedAt,
    required this.createdAt,
    required this.senderItems,
    required this.receiverItems,
    this.sender,
    this.receiver,
    this.conversationId,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String? parentOfferId;
  final OfferStatus status;
  final double cashAmount;
  final CashPayer cashPayer;
  final String message;
  final DateTime? senderConfirmedAt;
  final DateTime? receiverConfirmedAt;
  final DateTime createdAt;

  /// ما يقدّمه المرسل
  final List<Listing> senderItems;

  /// ما يطلبه المرسل من المستقبل
  final List<Listing> receiverItems;
  final Profile? sender;
  final Profile? receiver;
  final String? conversationId;

  static const select =
      '*, items:swap_offer_items(side, listing:listings(*)), '
      'sender:profiles!swap_offers_sender_id_fkey(${Profile.publicColumns}), '
      'receiver:profiles!swap_offers_receiver_id_fkey(${Profile.publicColumns}), '
      'conversation:conversations(id)';

  bool isIncomingFor(String uid) => receiverId == uid;
  String otherPartyId(String uid) => uid == senderId ? receiverId : senderId;
  Profile? otherParty(String uid) => uid == senderId ? receiver : sender;

  /// ما أعطيه أنا / ما آخذه أنا، من منظور المستخدم الحالي
  List<Listing> myItems(String uid) => uid == senderId ? senderItems : receiverItems;
  List<Listing> theirItems(String uid) => uid == senderId ? receiverItems : senderItems;

  bool confirmedBy(String uid) =>
      uid == senderId ? senderConfirmedAt != null : receiverConfirmedAt != null;

  /// وصف الفرق من منظور المستخدم: موجب = أنا أدفع، سالب = أنا أستلم
  double cashFromMe(String uid) {
    if (cashPayer == CashPayer.none) return 0;
    final iPay = (cashPayer == CashPayer.sender && uid == senderId) ||
        (cashPayer == CashPayer.receiver && uid == receiverId);
    return iPay ? cashAmount : -cashAmount;
  }

  factory SwapOffer.fromJson(Map<String, dynamic> j) {
    final items = (j['items'] as List? ?? const []).cast<Map<String, dynamic>>();
    List<Listing> side(String s) => items
        .where((i) => i['side'] == s && i['listing'] is Map<String, dynamic>)
        .map((i) => Listing.fromJson(i['listing'] as Map<String, dynamic>))
        .toList();
    final conv = j['conversation'];
    final convId = switch (conv) {
      Map<String, dynamic> m => m['id'] as String?,
      List l when l.isNotEmpty => (l.first as Map)['id'] as String?,
      _ => null,
    };
    DateTime? date(String k) => j[k] == null ? null : DateTime.parse(j[k] as String);
    return SwapOffer(
      id: j['id'] as String,
      senderId: j['sender_id'] as String,
      receiverId: j['receiver_id'] as String,
      parentOfferId: j['parent_offer_id'] as String?,
      status: OfferStatus.fromDb(j['status'] as String),
      cashAmount: (j['cash_amount'] as num?)?.toDouble() ?? 0,
      cashPayer: CashPayer.fromDb(j['cash_payer'] as String? ?? 'none'),
      message: j['message'] as String? ?? '',
      senderConfirmedAt: date('sender_confirmed_at'),
      receiverConfirmedAt: date('receiver_confirmed_at'),
      createdAt: DateTime.parse(j['created_at'] as String),
      senderItems: side('sender'),
      receiverItems: side('receiver'),
      sender: j['sender'] is Map<String, dynamic>
          ? Profile.fromJson(j['sender'] as Map<String, dynamic>)
          : null,
      receiver: j['receiver'] is Map<String, dynamic>
          ? Profile.fromJson(j['receiver'] as Map<String, dynamic>)
          : null,
      conversationId: convId,
    );
  }
}
