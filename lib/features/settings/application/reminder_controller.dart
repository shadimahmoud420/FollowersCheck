import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../snapshots/application/snapshot_providers.dart';
import '../data/reminder_service.dart';
import '../domain/app_settings.dart';
import 'settings_controller.dart';

/// Overridden in `main()`.
final reminderServiceProvider = Provider<ReminderService>(
  (ref) => throw UnimplementedError('reminderServiceProvider must be overridden'),
);

final reminderControllerProvider = Provider<ReminderController>(ReminderController.new);

/// Keeps scheduled reminders in sync with the user's settings.
class ReminderController {
  ReminderController(this._ref);

  final Ref _ref;

  /// Changes the frequency. Returns false if notification permission was
  /// denied (the setting is then left unchanged).
  Future<bool> setFrequency(ReminderFrequency frequency) async {
    final service = _ref.read(reminderServiceProvider);
    if (frequency != ReminderFrequency.off && !await service.requestPermission()) {
      return false;
    }
    await _ref.read(settingsControllerProvider.notifier).setReminder(frequency);
    await reschedule();
    return true;
  }

  /// Re-creates the reminder chain, counting from the latest import (or now).
  Future<void> reschedule({DateTime? lastImportAt}) async {
    final settings = _ref.read(settingsControllerProvider);
    final service = _ref.read(reminderServiceProvider);
    final interval = settings.reminder.interval;
    try {
      if (interval == null) {
        await service.cancel();
        return;
      }
      var from = lastImportAt;
      if (from == null) {
        final snapshots = await _ref.read(snapshotsProvider.future);
        from = snapshots.isEmpty ? DateTime.now() : snapshots.first.createdAt;
      }
      final l10n = lookupAppLocalizations(settings.locale);
      await service.schedule(
        interval: interval,
        from: from,
        title: l10n.reminderNotificationTitle,
        body: l10n.reminderNotificationBody,
      );
    } catch (_) {
      // Reminders are best-effort; never break the app because of them.
    }
  }
}
