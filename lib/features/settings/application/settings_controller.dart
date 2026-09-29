import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';
import '../domain/app_settings.dart';

final settingsControllerProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// Persists user preferences in shared_preferences.
class SettingsController extends Notifier<AppSettings> {
  static const keyLocale = 'locale';
  static const keyTheme = 'theme_mode';
  static const keyReminder = 'reminder';
  static const keyOnboarding = 'onboarding_done';
  static const keyDebugPremium = 'debug_premium';
  static const allKeys = {keyLocale, keyTheme, keyReminder, keyOnboarding, keyDebugPremium};

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    const d = AppSettings.defaults;
    final lang = prefs.getString(keyLocale);
    return AppSettings(
      locale: AppSettings.supportedLocales.firstWhere((l) => l.languageCode == lang, orElse: () => d.locale),
      themeMode: ThemeMode.values.firstWhere((m) => m.name == prefs.getString(keyTheme), orElse: () => d.themeMode),
      reminder: ReminderFrequency.values.firstWhere(
        (r) => r.name == prefs.getString(keyReminder),
        orElse: () => d.reminder,
      ),
      onboardingDone: prefs.getBool(keyOnboarding) ?? d.onboardingDone,
      debugPremium: prefs.getBool(keyDebugPremium) ?? d.debugPremium,
    );
  }

  SharedPreferencesWithCache get _prefs => ref.read(sharedPreferencesProvider);

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(keyLocale, locale.languageCode);
    state = state.copyWith(locale: locale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(keyTheme, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setReminder(ReminderFrequency reminder) async {
    await _prefs.setString(keyReminder, reminder.name);
    state = state.copyWith(reminder: reminder);
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(keyOnboarding, true);
    state = state.copyWith(onboardingDone: true);
  }

  Future<void> setDebugPremium(bool value) async {
    await _prefs.setBool(keyDebugPremium, value);
    state = state.copyWith(debugPremium: value);
  }
}
