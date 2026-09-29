import 'package:flutter/material.dart';

enum ReminderFrequency {
  off(null),
  weekly(Duration(days: 7)),
  biweekly(Duration(days: 14));

  const ReminderFrequency(this.interval);

  final Duration? interval;
}

class AppSettings {
  const AppSettings({
    required this.locale,
    required this.themeMode,
    required this.reminder,
    required this.onboardingDone,
    required this.debugPremium,
  });

  static const supportedLocales = [Locale('ar'), Locale('en')];

  /// Arabic (RTL) is the default language.
  static const defaults = AppSettings(
    locale: Locale('ar'),
    themeMode: ThemeMode.system,
    reminder: ReminderFrequency.off,
    onboardingDone: false,
    debugPremium: false,
  );

  final Locale locale;
  final ThemeMode themeMode;
  final ReminderFrequency reminder;
  final bool onboardingDone;

  /// Only honoured in debug builds; lets developers test premium UI.
  final bool debugPremium;

  AppSettings copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    ReminderFrequency? reminder,
    bool? onboardingDone,
    bool? debugPremium,
  }) => AppSettings(
    locale: locale ?? this.locale,
    themeMode: themeMode ?? this.themeMode,
    reminder: reminder ?? this.reminder,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    debugPremium: debugPremium ?? this.debugPremium,
  );
}
