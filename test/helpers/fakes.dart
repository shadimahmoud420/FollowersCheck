import 'dart:async';

import 'package:follower_check/features/import/data/export_file_source.dart';
import 'package:follower_check/features/import/domain/parsed_export.dart';
import 'package:follower_check/features/premium/domain/entitlement_service.dart';
import 'package:follower_check/features/settings/data/reminder_service.dart';
import 'package:follower_check/features/snapshots/domain/snapshot.dart';
import 'package:follower_check/features/snapshots/domain/snapshot_repository.dart';

class InMemorySnapshotRepository implements SnapshotRepository {
  final _items = <Snapshot>[];
  var _nextId = 1;

  @override
  Future<int> saveSnapshot({
    required DateTime createdAt,
    required Set<String> followers,
    required Set<String> following,
    required bool hasFollowingData,
  }) async {
    final id = _nextId++;
    _items.add(
      Snapshot(
        id: id,
        createdAt: createdAt,
        followers: followers,
        following: following,
        hasFollowingData: hasFollowingData,
      ),
    );
    return id;
  }

  List<Snapshot> get _sorted => [..._items]
    ..sort((a, b) {
      final c = b.createdAt.compareTo(a.createdAt);
      return c != 0 ? c : b.id.compareTo(a.id);
    });

  @override
  Future<List<SnapshotSummary>> listSnapshots() async => [
    for (final s in _sorted)
      SnapshotSummary(
        id: s.id,
        createdAt: s.createdAt,
        followerCount: s.followers.length,
        followingCount: s.following.length,
        hasFollowingData: s.hasFollowingData,
      ),
  ];

  @override
  Future<Snapshot?> getSnapshot(int id) async => _items.where((s) => s.id == id).firstOrNull;

  @override
  Future<Snapshot?> getPreviousSnapshot(int id) async {
    final sorted = _sorted;
    final i = sorted.indexWhere((s) => s.id == id);
    return i < 0 || i + 1 >= sorted.length ? null : sorted[i + 1];
  }

  @override
  Future<void> deleteSnapshot(int id) async => _items.removeWhere((s) => s.id == id);

  @override
  Future<void> deleteAll() async => _items.clear();
}

class FakeEntitlementService implements EntitlementService {
  FakeEntitlementService();

  bool _premium = false;
  final _controller = StreamController<bool>.broadcast();

  set premium(bool value) {
    _premium = value;
    _controller.add(value);
  }

  @override
  bool get isPremium => _premium;

  @override
  Stream<bool> watchIsPremium() async* {
    yield _premium;
    yield* _controller.stream;
  }

  @override
  Future<bool> isStoreAvailable() async => false;

  @override
  Future<String?> priceLabel() async => null;

  @override
  Future<bool> purchasePremium() async => false;

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> dispose() => _controller.close();
}

class FakeReminderService implements ReminderService {
  final scheduled = <Duration>[];
  var cancelled = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule({
    required Duration interval,
    required DateTime from,
    required String title,
    required String body,
  }) async => scheduled.add(interval);

  @override
  Future<void> cancel() async => cancelled++;
}

/// Returns queued file sets, one per call to [pick].
class FakeExportFileSource implements ExportFileSource {
  final queue = <List<ExportInputFile>>[];

  @override
  Future<List<ExportInputFile>> pick() async => queue.isEmpty ? const [] : queue.removeAt(0);
}
