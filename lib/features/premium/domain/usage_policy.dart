/// Free-tier rules. Pure so it can be unit-tested without Flutter.
class UsagePolicy {
  const UsagePolicy({this.freeComparisonInterval = const Duration(days: 7), this.freeHistoryLimit = 2});

  /// Free users may run one comparison (import a new snapshot) per interval.
  final Duration freeComparisonInterval;

  /// Number of most recent snapshots visible in history for free users.
  final int freeHistoryLimit;

  /// Whether a new import is allowed right now.
  ///
  /// [lastImportAt] is the date of the latest stored snapshot. The first
  /// import is always allowed, so every user can create a baseline.
  bool canImport({required bool isPremium, required DateTime? lastImportAt, required DateTime now}) {
    if (isPremium || lastImportAt == null) return true;
    return !now.isBefore(lastImportAt.add(freeComparisonInterval));
  }

  /// When the next free import becomes available, or null if it is now.
  DateTime? nextFreeImportAt({required bool isPremium, required DateTime? lastImportAt, required DateTime now}) {
    if (canImport(isPremium: isPremium, lastImportAt: lastImportAt, now: now)) return null;
    return lastImportAt!.add(freeComparisonInterval);
  }

  /// How many history rows are visible.
  int visibleHistoryCount({required bool isPremium, required int total}) =>
      isPremium ? total : (total < freeHistoryLimit ? total : freeHistoryLimit);

  bool canViewCharts({required bool isPremium}) => isPremium;
}
