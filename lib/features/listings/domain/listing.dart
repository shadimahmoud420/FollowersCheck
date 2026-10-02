import '../../profile/domain/profile.dart';

enum ItemCondition {
  newItem('new', 'جديد'),
  likeNew('like_new', 'مثل الجديد'),
  excellent('excellent', 'ممتاز'),
  good('good', 'جيد'),
  used('used', 'مستعمل'),
  needsRepair('needs_repair', 'يحتاج إصلاح');

  const ItemCondition(this.db, this.label);
  final String db;
  final String label;

  static ItemCondition fromDb(String v) =>
      values.firstWhere((c) => c.db == v, orElse: () => ItemCondition.used);
}

enum ListingStatus {
  active('active', 'معروض'),
  reserved('reserved', 'محجوز'),
  swapped('swapped', 'تم التبادل'),
  expired('expired', 'منتهي'),
  removed('removed', 'محذوف');

  const ListingStatus(this.db, this.label);
  final String db;
  final String label;

  static ListingStatus fromDb(String v) =>
      values.firstWhere((s) => s.db == v, orElse: () => ListingStatus.active);
}

/// مدة العرض عند الإضافة
enum ListingDuration {
  open('مفتوح', null),
  day('24 ساعة', Duration(hours: 24)),
  threeDays('3 أيام', Duration(days: 3)),
  week('7 أيام', Duration(days: 7)),
  month('30 يوماً', Duration(days: 30));

  const ListingDuration(this.label, this.duration);
  final String label;
  final Duration? duration;
}

/// رغبة منظّمة: «أريد مقابله شيئاً من فئة X» + كلمة اختيارية
class ListingWant {
  const ListingWant({required this.categoryId, this.keyword});
  final int categoryId;
  final String? keyword;

  factory ListingWant.fromJson(Map<String, dynamic> j) => ListingWant(
        categoryId: j['category_id'] as int,
        keyword: j['keyword'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is ListingWant &&
      other.categoryId == categoryId &&
      other.keyword == keyword;

  @override
  int get hashCode => Object.hash(categoryId, keyword);
}

class Listing {
  const Listing({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.condition,
    this.estimatedValue,
    required this.images,
    required this.governorateId,
    this.areaId,
    required this.wantsAnything,
    required this.wantsNote,
    required this.acceptsCashDifference,
    required this.status,
    this.expiresAt,
    required this.createdAt,
    this.wants = const [],
    this.owner,
  });

  final String id;
  final String ownerId;
  final String title;
  final String description;
  final int categoryId;
  final ItemCondition condition;
  final double? estimatedValue;
  final List<String> images;
  final int governorateId;
  final int? areaId;
  final bool wantsAnything;
  final String wantsNote;
  final bool acceptsCashDifference;
  final ListingStatus status;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final List<ListingWant> wants;
  final Profile? owner;

  String? get coverImage => images.isEmpty ? null : images.first;

  bool get isEndingSoon =>
      expiresAt != null &&
      expiresAt!.difference(DateTime.now()) < const Duration(hours: 24);

  /// الأعمدة مع الرغبات وصاحب الإعلان
  static const selectWithRelations =
      '*, wants:listing_wants(category_id, keyword), '
      'owner:profiles(${Profile.publicColumns})';

  factory Listing.fromJson(Map<String, dynamic> j) => Listing(
        id: j['id'] as String,
        ownerId: j['owner_id'] as String,
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        categoryId: j['category_id'] as int,
        condition: ItemCondition.fromDb(j['condition'] as String),
        estimatedValue: (j['estimated_value'] as num?)?.toDouble(),
        images: (j['images'] as List? ?? const []).cast<String>(),
        governorateId: j['governorate_id'] as int,
        areaId: j['area_id'] as int?,
        wantsAnything: j['wants_anything'] as bool? ?? false,
        wantsNote: j['wants_note'] as String? ?? '',
        acceptsCashDifference: j['accepts_cash_difference'] as bool? ?? true,
        status: ListingStatus.fromDb(j['status'] as String),
        expiresAt: j['expires_at'] == null
            ? null
            : DateTime.parse(j['expires_at'] as String),
        createdAt: DateTime.parse(j['created_at'] as String),
        wants: (j['wants'] as List? ?? const [])
            .map((w) => ListingWant.fromJson(w as Map<String, dynamic>))
            .toList(),
        owner: j['owner'] is Map<String, dynamic>
            ? Profile.fromJson(j['owner'] as Map<String, dynamic>)
            : null,
      );
}

/// بيانات نموذج إضافة/تعديل إعلان
class ListingDraft {
  ListingDraft({
    required this.title,
    required this.description,
    required this.categoryId,
    required this.condition,
    required this.governorateId,
    this.areaId,
    this.estimatedValue,
    this.wantsAnything = false,
    this.wantsNote = '',
    this.wants = const [],
    this.acceptsCashDifference = true,
    this.duration = ListingDuration.open,
  });

  final String title;
  final String description;
  final int categoryId;
  final ItemCondition condition;
  final int governorateId;
  final int? areaId;
  final double? estimatedValue;
  final bool wantsAnything;
  final String wantsNote;
  final List<ListingWant> wants;
  final bool acceptsCashDifference;
  final ListingDuration duration;

  Map<String, dynamic> toRow({required List<String> images, DateTime? now}) => {
        'title': title.trim(),
        'description': description.trim(),
        'category_id': categoryId,
        'condition': condition.db,
        'governorate_id': governorateId,
        'area_id': areaId,
        'estimated_value': estimatedValue,
        'wants_anything': wantsAnything,
        'wants_note': wantsNote.trim(),
        'accepts_cash_difference': acceptsCashDifference,
        'images': images,
        'expires_at': duration.duration == null
            ? null
            : (now ?? DateTime.now()).add(duration.duration!).toUtc().toIso8601String(),
      };
}
