class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.readAt,
  });

  final int id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  String get title => switch (type) {
        'offer_received' => 'وصلك عرض تبادل جديد 🔄',
        'offer_countered' => 'وصلك عرض معاكس',
        'offer_accepted' => 'تم قبول عرضك 🎉',
        'offer_rejected' => 'تم رفض عرضك',
        'offer_cancelled' => 'تم إلغاء عرض',
        'swap_completed' => 'تم التبادل بنجاح ✅',
        'new_message' => 'رسالة جديدة',
        'listing_saved' => 'شخص حفظ إعلانك ❤️',
        'rating_received' => 'وصلك تقييم جديد ⭐',
        'match_found' => 'وجدنا تطابقاً لك 🎯',
        _ => 'إشعار',
      };

  String? get subtitle => switch (type) {
        'new_message' => payload['preview'] as String?,
        'listing_saved' => payload['title'] as String?,
        'rating_received' => '${payload['stars']} نجوم',
        'offer_cancelled' when payload['reason'] == 'items_reserved' =>
          'أحد الأغراض حُجز في صفقة أخرى',
        _ => null,
      };

  /// المسار داخل التطبيق عند الضغط على الإشعار
  String? get route => switch (type) {
        'new_message' => '/chat/${payload['conversation_id']}',
        'listing_saved' => '/listing/${payload['listing_id']}',
        'offer_accepted' when payload['conversation_id'] != null =>
          '/offer/${payload['offer_id']}',
        _ when payload['offer_id'] != null => '/offer/${payload['offer_id']}',
        _ => null,
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as int,
        type: j['type'] as String,
        payload: (j['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
        createdAt: DateTime.parse(j['created_at'] as String),
        readAt: j['read_at'] == null ? null : DateTime.parse(j['read_at'] as String),
      );
}
