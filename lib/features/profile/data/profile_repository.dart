import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/profile.dart';

abstract interface class ProfileRepository {
  Future<Profile?> getMine();
  Future<Profile> getById(String id);
  Future<void> upsertMine({
    required String displayName,
    required int governorateId,
    int? areaId,
    String? bio,
    String? avatarPath,
  });
  Future<String> uploadAvatar(Uint8List jpegBytes);
  Future<List<Rating>> ratingsOf(String userId);
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._db);
  final SupabaseClient _db;

  String get _uid => _db.auth.currentUser!.id;

  @override
  Future<Profile?> getMine() async {
    final user = _db.auth.currentUser;
    if (user == null) return null;
    final row = await _db
        .from('profiles')
        .select('${Profile.publicColumns}, is_admin')
        .eq('id', user.id)
        .maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }

  @override
  Future<Profile> getById(String id) async {
    final row = await _db
        .from('profiles')
        .select(Profile.publicColumns)
        .eq('id', id)
        .single();
    return Profile.fromJson(row);
  }

  @override
  Future<void> upsertMine({
    required String displayName,
    required int governorateId,
    int? areaId,
    String? bio,
    String? avatarPath,
  }) async {
    final values = {
      'display_name': displayName.trim(),
      'governorate_id': governorateId,
      'area_id': areaId,
      'bio': bio,
      'avatar_path': ?avatarPath,
    };
    final existing =
        await _db.from('profiles').select('id').eq('id', _uid).maybeSingle();
    if (existing == null) {
      await _db.from('profiles').insert({'id': _uid, ...values});
    } else {
      await _db.from('profiles').update(values).eq('id', _uid);
    }
  }

  @override
  Future<String> uploadAvatar(Uint8List jpegBytes) async {
    final path = '$_uid/${const Uuid().v4()}.jpg';
    await _db.storage.from('avatars').uploadBinary(
          path,
          jpegBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return path;
  }

  @override
  Future<List<Rating>> ratingsOf(String userId) async {
    final rows = await _db
        .from('ratings')
        .select('stars, tags, comment, created_at, from:profiles!ratings_from_user_fkey(display_name)')
        .eq('to_user', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(Rating.fromJson).toList();
  }
}
