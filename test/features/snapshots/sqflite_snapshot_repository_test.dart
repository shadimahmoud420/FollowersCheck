import 'package:follower_check/features/snapshots/data/sqflite_snapshot_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late SqfliteSnapshotRepository repo;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    repo = await SqfliteSnapshotRepository.open(inMemoryDatabasePath, factory: databaseFactoryFfiNoIsolate);
  });

  tearDown(() => repo.close());

  test('saves, lists newest first and loads snapshots', () async {
    final id1 = await repo.saveSnapshot(
      createdAt: DateTime(2026, 1, 1),
      followers: {'a', 'b'},
      following: {'a', 'c'},
      hasFollowingData: true,
    );
    final id2 = await repo.saveSnapshot(
      createdAt: DateTime(2026, 1, 8),
      followers: {'a'},
      following: {},
      hasFollowingData: false,
    );

    final list = await repo.listSnapshots();
    expect(list.map((s) => s.id), [id2, id1]);
    expect(list.first.followerCount, 1);
    expect(list.last.followingCount, 2);
    expect(list.first.hasFollowingData, isFalse);

    final s1 = await repo.getSnapshot(id1);
    expect(s1!.followers, {'a', 'b'});
    expect(s1.following, {'a', 'c'});

    final prev = await repo.getPreviousSnapshot(id2);
    expect(prev!.id, id1);
    expect(await repo.getPreviousSnapshot(id1), isNull);
  });

  test('deletes one or all snapshots', () async {
    final id = await repo.saveSnapshot(
      createdAt: DateTime(2026),
      followers: {'a'},
      following: {'b'},
      hasFollowingData: true,
    );
    await repo.saveSnapshot(createdAt: DateTime(2026, 2), followers: {'a'}, following: {'b'}, hasFollowingData: true);

    await repo.deleteSnapshot(id);
    expect(await repo.listSnapshots(), hasLength(1));
    expect(await repo.getSnapshot(id), isNull);

    await repo.deleteAll();
    expect(await repo.listSnapshots(), isEmpty);
  });
}
