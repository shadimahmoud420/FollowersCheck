import 'package:follower_check/features/snapshots/domain/snapshot.dart';
import 'package:follower_check/features/snapshots/domain/snapshot_diff.dart';
import 'package:flutter_test/flutter_test.dart';

Snapshot _snap(int id, Set<String> followers, Set<String> following) => Snapshot(
  id: id,
  createdAt: DateTime(2026, 1, id),
  followers: followers,
  following: following,
  hasFollowingData: true,
);

void main() {
  test('computes unfollowers, non-followers-back and new followers', () {
    final previous = _snap(1, {'a', 'b', 'c'}, {'a', 'b'});
    final latest = _snap(2, {'a', 'd', 'e'}, {'a', 'b', 'z'});

    final r = SnapshotDiff.compare(latest: latest, previous: previous);

    expect(r.unfollowedYou, ['b', 'c']);
    expect(r.newFollowers, ['d', 'e']);
    expect(r.notFollowingBack, ['b', 'z']);
    expect(r.hasPrevious, isTrue);
  });

  test('without a previous snapshot only notFollowingBack is filled', () {
    final r = SnapshotDiff.compare(latest: _snap(1, {'a'}, {'a', 'y', 'x'}));
    expect(r.unfollowedYou, isEmpty);
    expect(r.newFollowers, isEmpty);
    expect(r.notFollowingBack, ['x', 'y']);
    expect(r.hasPrevious, isFalse);
  });

  test('identical snapshots produce no changes', () {
    final s = _snap(1, {'a', 'b'}, {'a', 'b'});
    final r = SnapshotDiff.compare(latest: s, previous: s);
    expect(r.unfollowedYou, isEmpty);
    expect(r.newFollowers, isEmpty);
    expect(r.notFollowingBack, isEmpty);
  });
}
