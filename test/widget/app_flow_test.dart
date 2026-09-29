import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:follower_check/app.dart';
import 'package:follower_check/core/providers.dart';
import 'package:follower_check/features/import/application/import_controller.dart';
import 'package:follower_check/features/import/domain/parsed_export.dart';
import 'package:follower_check/features/premium/application/premium_providers.dart';
import 'package:follower_check/features/settings/application/reminder_controller.dart';
import 'package:follower_check/features/settings/application/settings_controller.dart';
import 'package:follower_check/features/snapshots/application/snapshot_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../helpers/fakes.dart';

ExportInputFile _fixture(String path) =>
    ExportInputFile(path.split('/').last, File('test/fixtures/$path').readAsBytesSync());

void main() {
  late InMemorySnapshotRepository repo;
  late FakeEntitlementService entitlements;
  late FakeExportFileSource files;
  late DateTime now;

  Future<void> pumpApp(WidgetTester tester, {Map<String, Object> prefsData = const {}}) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData(prefsData);
    final prefs = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          snapshotRepositoryProvider.overrideWithValue(repo),
          entitlementServiceProvider.overrideWithValue(entitlements),
          reminderServiceProvider.overrideWithValue(FakeReminderService()),
          exportFileSourceProvider.overrideWithValue(files),
          clockProvider.overrideWithValue(() => now),
        ],
        child: const FollowerCheckApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Taps the import button and waits for the import to finish. Parsing
  /// runs in a real isolate, so real async work must be allowed to complete.
  Future<void> tapImport(WidgetTester tester) async {
    final container = ProviderScope.containerOf(tester.element(find.byKey(const Key('import_pick'))));
    final before = container.read(importControllerProvider);
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('import_pick')));
      for (var i = 0; i < 200; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
        final state = container.read(importControllerProvider);
        if (!identical(state, before) && (state is ImportSuccess || state is ImportError)) break;
      }
    });
    await tester.pumpAndSettle();
  }

  setUp(() {
    repo = InMemorySnapshotRepository();
    entitlements = FakeEntitlementService();
    files = FakeExportFileSource();
    now = DateTime(2026, 9, 1, 10);
  });

  testWidgets('first launch shows Arabic RTL onboarding, then empty results', (tester) async {
    await pumpApp(tester);

    expect(find.text('اعرف من ألغى متابعتك'), findsOneWidget);
    final dir = Directionality.of(tester.element(find.text('اعرف من ألغى متابعتك')));
    expect(dir, TextDirection.rtl);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('onboarding_next')));
      await tester.pumpAndSettle();
    }
    expect(find.text('لا توجد بيانات بعد'), findsOneWidget);
  });

  testWidgets('import two exports, see results, search, and hit weekly limit', (tester) async {
    await pumpApp(tester, prefsData: {SettingsController.keyOnboarding: true, SettingsController.keyLocale: 'en'});
    expect(find.text('No data yet'), findsOneWidget);

    // First import: legacy fixture (followers: zoe, yan; following: zoe, xavier).
    files.queue.add([_fixture('legacy/followers_1.json'), _fixture('legacy/following.json')]);
    await tester.tap(find.byKey(const Key('empty_import')));
    await tester.pumpAndSettle();
    await tapImport(tester);
    expect(find.text('Import complete'), findsOneWidget);
    expect(find.text('Followers: 2 · Following: 2'), findsOneWidget);

    // A second import in the same week is blocked for free users.
    now = now.add(const Duration(days: 2));
    files.queue.add([_fixture('current/followers_1.json')]);
    await tapImport(tester);
    expect(find.byKey(const Key('import_error')), findsOneWidget);
    expect(find.textContaining('1 comparison per week'), findsOneWidget);

    // Premium lifts the limit.
    entitlements.premium = true;
    await tester.pump();
    await tapImport(tester);
    expect(find.text('Import complete'), findsOneWidget);

    await tester.tap(find.text('View results'));
    await tester.pumpAndSettle();

    // zoe & yan unfollowed (not in the current fixture's followers).
    expect(find.text('\u2066@yan\u2069'), findsOneWidget);
    expect(find.text('\u2066@zoe\u2069'), findsOneWidget);
    expect(find.text('Total: 2'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('results_search')), 'zo');
    await tester.pumpAndSettle();
    expect(find.text('\u2066@yan\u2069'), findsNothing);
    expect(find.text('1 of 2'), findsOneWidget);

    // New followers tab.
    await tester.tap(find.textContaining('New followers'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('results_search')), '');
    await tester.pumpAndSettle();
    expect(find.text('Total: 3'), findsOneWidget);
    expect(find.text('\u2066@carol\u2069'), findsOneWidget);
  });

  testWidgets('HTML export shows a re-export hint', (tester) async {
    await pumpApp(tester, prefsData: {SettingsController.keyOnboarding: true, SettingsController.keyLocale: 'en'});
    files.queue.add([_fixture('html/followers_1.html')]);
    await tester.tap(find.byKey(const Key('empty_import')));
    await tester.pumpAndSettle();
    await tapImport(tester);
    expect(find.textContaining('HTML format'), findsOneWidget);
  });
}
