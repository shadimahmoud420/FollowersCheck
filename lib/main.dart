import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'app.dart';
import 'core/providers.dart';
import 'features/premium/application/premium_providers.dart';
import 'features/premium/data/in_app_purchase_entitlement_service.dart';
import 'features/settings/application/reminder_controller.dart';
import 'features/settings/data/reminder_service.dart';
import 'features/snapshots/application/snapshot_providers.dart';
import 'features/snapshots/data/sqflite_snapshot_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
  final repository = await SqfliteSnapshotRepository.open(p.join(await getDatabasesPath(), 'follower_check.db'));

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      snapshotRepositoryProvider.overrideWithValue(repository),
      entitlementServiceProvider.overrideWithValue(InAppPurchaseEntitlementService(prefs)),
      reminderServiceProvider.overrideWithValue(LocalNotificationReminderService()),
    ],
  );

  // Keep the reminder chain topped up (best-effort, not awaited).
  container.read(reminderControllerProvider).reschedule();

  runApp(UncontrolledProviderScope(container: container, child: const FollowerCheckApp()));
}
