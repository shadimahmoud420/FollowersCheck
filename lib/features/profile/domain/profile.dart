class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    this.avatarPath,
    this.governorateId,
    this.areaId,
    this.bio,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.completedSwaps = 0,
    this.isAdmin = false,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String? avatarPath;
  final int? governorateId;
  final int? areaId;
  final String? bio;
  final double ratingAvg;
  final int ratingCount;
  final int completedSwaps;
  final bool isAdmin;
  final DateTime createdAt;

  /// الأعمدة العامة الآمنة للعرض في الإعلانات والعروض
  static const publicColumns =
      'id, display_name, avatar_path, governorate_id, area_id, bio, '
      'rating_avg, rating_count, completed_swaps, created_at';

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        displayName: j['display_name'] as String,
        avatarPath: j['avatar_path'] as String?,
        governorateId: j['governorate_id'] as int?,
        areaId: j['area_id'] as int?,
        bio: j['bio'] as String?,
        ratingAvg: (j['rating_avg'] as num?)?.toDouble() ?? 0,
        ratingCount: j['rating_count'] as int? ?? 0,
        completedSwaps: j['completed_swaps'] as int? ?? 0,
        isAdmin: j['is_admin'] as bool? ?? false,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class Rating {
  const Rating({
    required this.stars,
    required this.tags,
    required this.comment,
    required this.createdAt,
    this.fromName,
  });

  final int stars;
  final List<String> tags;
  final String comment;
  final DateTime createdAt;
  final String? fromName;

  static const tagLabels = {
    'committed': 'ملتزم',
    'honest': 'صادق في الوصف',
    'fast_reply': 'سريع في الرد',
    'on_time': 'التزم بالموعد',
    'as_described': 'الغرض مطابق للوصف',
  };

  factory Rating.fromJson(Map<String, dynamic> j) => Rating(
        stars: j['stars'] as int,
        tags: (j['tags'] as List? ?? const []).cast<String>(),
        comment: j['comment'] as String? ?? '',
        createdAt: DateTime.parse(j['created_at'] as String),
        fromName: (j['from'] as Map?)?['display_name'] as String?,
      );
}
