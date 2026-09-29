import 'snapshot.dart';

/// Outcome of comparing the latest snapshot with the previous one.
class ComparisonResult {
  const ComparisonResult({
    required this.latest,
    required this.previous,
    required this.unfollowedYou,
    required this.notFollowingBack,
    required this.newFollowers,
  });

  final Snapshot latest;
  final Snapshot? previous;

  /// In the previous snapshot's followers but not in the latest one.
  final List<String> unfollowedYou;

  /// Accounts you follow (latest) that do not follow you back (latest).
  final List<String> notFollowingBack;

  /// In the latest followers but not in the previous one.
  final List<String> newFollowers;

  bool get hasPrevious => previous != null;
}

/// Pure set arithmetic between snapshots. Results are sorted alphabetically.
class SnapshotDiff {
  const SnapshotDiff._();

  static ComparisonResult compare({required Snapshot latest, Snapshot? previous}) {
    List<String> sorted(Iterable<String> it) => it.toList()..sort();

    return ComparisonResult(
      latest: latest,
      previous: previous,
      unfollowedYou: previous == null ? const [] : sorted(previous.followers.difference(latest.followers)),
      notFollowingBack: sorted(latest.following.difference(latest.followers)),
      newFollowers: previous == null ? const [] : sorted(latest.followers.difference(previous.followers)),
    );
  }
}
