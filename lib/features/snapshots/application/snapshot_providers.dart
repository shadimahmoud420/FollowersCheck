import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/snapshot.dart';
import '../domain/snapshot_diff.dart';
import '../domain/snapshot_repository.dart';

/// Overridden in `main()` with the SQLite repository.
final snapshotRepositoryProvider = Provider<SnapshotRepository>(
  (ref) => throw UnimplementedError('snapshotRepositoryProvider must be overridden'),
);

/// All snapshots, newest first.
final snapshotsProvider = FutureProvider<List<SnapshotSummary>>(
  (ref) => ref.watch(snapshotRepositoryProvider).listSnapshots(),
);

/// Comparison for snapshot [snapshotId] (or the latest one when null)
/// against the snapshot taken right before it. Null when there is no data.
final comparisonProvider = FutureProvider.family<ComparisonResult?, int?>((ref, snapshotId) async {
  final repo = ref.watch(snapshotRepositoryProvider);
  final summaries = await ref.watch(snapshotsProvider.future);
  if (summaries.isEmpty) return null;
  final id = snapshotId ?? summaries.first.id;
  final latest = await repo.getSnapshot(id);
  if (latest == null) return null;
  final previous = await repo.getPreviousSnapshot(id);
  return SnapshotDiff.compare(latest: latest, previous: previous);
});
