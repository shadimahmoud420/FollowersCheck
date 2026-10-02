import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_notification.dart';

abstract interface class NotificationRepository {
  Stream<List<AppNotification>> watch();
  Future<void> markAllRead();
}

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this._db);
  final SupabaseClient _db;

  @override
  Stream<List<AppNotification>> watch() => _db
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', _db.auth.currentUser!.id)
      .order('id', ascending: false)
      .limit(100)
      .map((rows) => rows.map(AppNotification.fromJson).toList());

  @override
  Future<void> markAllRead() => _db
      .from('notifications')
      .update({'read_at': DateTime.now().toUtc().toIso8601String()})
      .eq('user_id', _db.auth.currentUser!.id)
      .isFilter('read_at', null);
}
