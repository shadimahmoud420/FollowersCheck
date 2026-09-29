import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../premium/application/premium_providers.dart';
import '../../snapshots/application/snapshot_providers.dart';
import '../application/reminder_controller.dart';
import '../application/settings_controller.dart';
import '../domain/app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever_outlined),
        title: Text(l10n.deleteAllTitle),
        content: Text(l10n.deleteAllBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(snapshotRepositoryProvider).deleteAll();
    ref.invalidate(snapshotsProvider);
    ref.invalidate(comparisonProvider);
    await ref.read(reminderControllerProvider).reschedule();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dataDeleted)));
    }
  }

  Future<void> _setReminder(BuildContext context, WidgetRef ref, ReminderFrequency f) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(reminderControllerProvider).setFrequency(f);
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(l10n.reminderPermissionDenied)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ListTile(
            leading: Icon(isPremium ? Icons.workspace_premium : Icons.workspace_premium_outlined),
            title: Text(isPremium ? l10n.premiumActive : l10n.upgrade),
            subtitle: isPremium ? null : Text(l10n.premiumInactive),
            onTap: isPremium ? null : () => context.push('/paywall'),
          ),
          const Divider(),
          _SectionHeader(l10n.language),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ar', label: Text('العربية')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {settings.locale.languageCode},
              onSelectionChanged: (v) async {
                await controller.setLocale(Locale(v.first));
                // Re-schedule so notification text follows the language.
                await ref.read(reminderControllerProvider).reschedule();
              },
            ),
          ),
          _SectionHeader(l10n.theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.themeSystem),
                  icon: const Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.themeLight),
                  icon: const Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.themeDark),
                  icon: const Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (v) => controller.setThemeMode(v.first),
            ),
          ),
          _SectionHeader(l10n.reminders),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l10n.remindersSubtitle, style: Theme.of(context).textTheme.bodySmall),
          ),
          RadioGroup<ReminderFrequency>(
            groupValue: settings.reminder,
            onChanged: (f) => f == null ? null : _setReminder(context, ref, f),
            child: Column(
              children: [
                for (final f in ReminderFrequency.values)
                  RadioListTile<ReminderFrequency>(
                    value: f,
                    title: Text(switch (f) {
                      ReminderFrequency.off => l10n.reminderOff,
                      ReminderFrequency.weekly => l10n.reminderWeekly,
                      ReminderFrequency.biweekly => l10n.reminderBiweekly,
                    }),
                  ),
              ],
            ),
          ),
          const Divider(),
          _SectionHeader(l10n.dataSection),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(l10n.showGuide),
            onTap: () => context.push('/guide'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyPolicy),
            onTap: () => context.push('/privacy'),
          ),
          ListTile(
            key: const Key('delete_all'),
            leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
            title: Text(l10n.deleteAllData, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () => _deleteAll(context, ref),
          ),
          if (kDebugMode)
            SwitchListTile(
              secondary: const Icon(Icons.bug_report_outlined),
              title: Text(l10n.debugPremium),
              value: settings.debugPremium,
              onChanged: controller.setDebugPremium,
            ),
          const Divider(),
          _SectionHeader(l10n.about),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(l10n.disclaimer, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}
