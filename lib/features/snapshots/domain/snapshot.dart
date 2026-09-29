/// A single import of the user's followers / following lists.
class Snapshot {
  const Snapshot({
    required this.id,
    required this.createdAt,
    required this.followers,
    required this.following,
    required this.hasFollowingData,
  });

  final int id;
  final DateTime createdAt;
  final Set<String> followers;
  final Set<String> following;

  /// False when the import only contained a followers file.
  final bool hasFollowingData;
}

/// Lightweight row used by lists and charts.
class SnapshotSummary {
  const SnapshotSummary({
    required this.id,
    required this.createdAt,
    required this.followerCount,
    required this.followingCount,
    required this.hasFollowingData,
  });

  final int id;
  final DateTime createdAt;
  final int followerCount;
  final int followingCount;
  final bool hasFollowingData;
}
