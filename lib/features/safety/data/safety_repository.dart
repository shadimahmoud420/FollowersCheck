import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/report_reason.dart';

abstract interface class SafetyRepository {
  Future<void> report({
    required ReportReason reason,
    String? userId,
    String? listingId,
    int? messageId,
    String details,
  });
  Future<void> block(String userId);
  Future<void> unblock(String userId);
  Future<bool> isBlocked(String userId);
}

class SupabaseSafetyRepository implements SafetyRepository {
  SupabaseSafetyRepository(this._db);
  final SupabaseClient _db;

  String get _uid => _db.auth.currentUser!.id;

  @override
  Future<void> report({
    required ReportReason reason,
    String? userId,
    String? listingId,
    int? messageId,
    String details = '',
  }) =>
      _db.from('reports').insert({
        'reporter_id': _uid,
        'reported_user_id': userId,
        'listing_id': listingId,
        'message_id': messageId,
        'reason': reason.db,
        'details': details.trim(),
      });

  @override
  Future<void> block(String userId) =>
      _db.from('blocks').upsert({'blocker_id': _uid, 'blocked_id': userId});

  @override
  Future<void> unblock(String userId) =>
      _db.from('blocks').delete().eq('blocker_id', _uid).eq('blocked_id', userId);

  @override
  Future<bool> isBlocked(String userId) async {
    final row = await _db
        .from('blocks')
        .select('blocked_id')
        .eq('blocker_id', _uid)
        .eq('blocked_id', userId)
        .maybeSingle();
    return row != null;
  }
}
