import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules "request a fresh export" reminders.
abstract interface class ReminderService {
  Future<void> init();

  /// Asks for notification permission. Returns false if denied.
  Future<bool> requestPermission();

  /// Replaces any pending reminders with a chain every [interval], starting
  /// one interval after [from].
  Future<void> schedule({
    required Duration interval,
    required DateTime from,
    required String title,
    required String body,
  });

  Future<void> cancel();
}

/// [ReminderService] using flutter_local_notifications. Everything is local;
/// no push server is involved.
///
/// Neither platform offers a native "every 14 days" repeat, so we schedule a
/// short chain of one-shot notifications and re-create it on every app start
/// and import.
class LocalNotificationReminderService implements ReminderService {
  LocalNotificationReminderService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _chainLength = 6;
  static const _baseId = 1000;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'export_reminders',
      'Export reminders',
      channelDescription: 'Reminders to request a fresh data export',
      importance: Importance.defaultImportance,
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Ask for permission only when the user enables reminders.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, badge: false, sound: true) ?? false;
    }
    return true;
  }

  @override
  Future<void> schedule({
    required Duration interval,
    required DateTime from,
    required String title,
    required String body,
  }) async {
    await init();
    await cancel();
    final now = DateTime.now();
    var next = from.add(interval);
    // If the app wasn't opened for a while, start from the next future slot.
    while (!next.isAfter(now)) {
      next = next.add(interval);
    }
    for (var i = 0; i < _chainLength; i++) {
      await _plugin.zonedSchedule(
        id: _baseId + i,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(next.add(interval * i), tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancel() async {
    await init();
    for (var i = 0; i < _chainLength; i++) {
      await _plugin.cancel(id: _baseId + i);
    }
  }
}
