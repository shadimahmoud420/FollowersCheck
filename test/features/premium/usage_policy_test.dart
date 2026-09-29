import 'package:follower_check/features/premium/domain/usage_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = UsagePolicy();
  final now = DateTime(2026, 9, 29, 12);

  test('first import is always allowed', () {
    expect(policy.canImport(isPremium: false, lastImportAt: null, now: now), isTrue);
  });

  test('free users get one comparison per 7 days', () {
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    expect(policy.canImport(isPremium: false, lastImportAt: threeDaysAgo, now: now), isFalse);
    expect(
      policy.nextFreeImportAt(isPremium: false, lastImportAt: threeDaysAgo, now: now),
      threeDaysAgo.add(const Duration(days: 7)),
    );

    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    expect(policy.canImport(isPremium: false, lastImportAt: sevenDaysAgo, now: now), isTrue);
    expect(policy.nextFreeImportAt(isPremium: false, lastImportAt: sevenDaysAgo, now: now), isNull);
  });

  test('premium is unlimited', () {
    expect(policy.canImport(isPremium: true, lastImportAt: now, now: now), isTrue);
  });

  test('history and charts are limited for free users', () {
    expect(policy.visibleHistoryCount(isPremium: false, total: 10), 2);
    expect(policy.visibleHistoryCount(isPremium: false, total: 1), 1);
    expect(policy.visibleHistoryCount(isPremium: true, total: 10), 10);
    expect(policy.canViewCharts(isPremium: false), isFalse);
    expect(policy.canViewCharts(isPremium: true), isTrue);
  });
}
