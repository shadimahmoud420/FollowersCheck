import 'snapshot.dart';

/// Local persistence for snapshots. Implementations must keep all data on
/// the device.
abstract interface class SnapshotRepository {
  /// Stores a new snapshot and returns its id.
  Future<int> saveSnapshot({
    required DateTime createdAt,
    required Set<String> followers,
    required Set<String> following,
    required bool hasFollowingData,
  });

  /// All snapshots, newest first.
  Future<List<SnapshotSummary>> listSnapshots();

  Future<Snapshot?> getSnapshot(int id);

  /// The snapshot taken just before [id], if any.
  Future<Snapshot?> getPreviousSnapshot(int id);

  Future<void> deleteSnapshot(int id);

  Future<void> deleteAll();
}
