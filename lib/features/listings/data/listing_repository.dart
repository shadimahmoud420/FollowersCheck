import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/arabic.dart';
import '../domain/listing.dart';
import '../domain/listing_filter.dart';

abstract interface class ListingRepository {
  Future<List<Listing>> feed(ListingFilter filter, {int offset = 0, int limit = 30});
  Future<Listing> getById(String id);
  Future<List<Listing>> byOwner(String ownerId, {bool onlyActive = true});
  Future<Listing> create(ListingDraft draft, List<Uint8List> jpegImages);
  Future<void> setStatus(String id, ListingStatus status);
  Future<bool> isFavorite(String listingId);
  Future<void> setFavorite(String listingId, bool value);
  Future<List<Listing>> favorites();
}

class SupabaseListingRepository implements ListingRepository {
  SupabaseListingRepository(this._db);
  final SupabaseClient _db;

  String get _uid => _db.auth.currentUser!.id;

  @override
  Future<List<Listing>> feed(ListingFilter f, {int offset = 0, int limit = 30}) async {
    var q = _db.from('listings').select(Listing.selectWithRelations).eq('status', 'active');

    final text = normalizeArabic(toLatinDigits(f.query)).replaceAll(RegExp(r'[%_,()]'), ' ').trim();
    if (text.isNotEmpty) q = q.ilike('search_text', '%$text%');
    if (f.categoryId != null) q = q.eq('category_id', f.categoryId!);
    if (f.governorateId != null) q = q.eq('governorate_id', f.governorateId!);
    if (f.areaId != null) q = q.eq('area_id', f.areaId!);
    if (f.condition != null) q = q.eq('condition', f.condition!.db);
    if (f.minValue != null) q = q.gte('estimated_value', f.minValue!);
    if (f.maxValue != null) q = q.lte('estimated_value', f.maxValue!);
    // لا نُظهر الإعلانات المنتهية التي لم تمر عليها المهمة الدورية بعد
    q = q.or('expires_at.is.null,expires_at.gt.${DateTime.now().toUtc().toIso8601String()}');

    final ordered = switch (f.sort) {
      ListingSort.newest => q.order('created_at', ascending: false),
      ListingSort.endingSoon => q
          .not('expires_at', 'is', null)
          .order('expires_at', ascending: true),
      ListingSort.valueHigh => q
          .order('estimated_value', ascending: false, nullsFirst: false)
          .order('created_at', ascending: false),
      ListingSort.valueLow => q
          .order('estimated_value', ascending: true, nullsFirst: false)
          .order('created_at', ascending: false),
    };
    final rows = await ordered.range(offset, offset + limit - 1);
    return rows.map(Listing.fromJson).toList();
  }

  @override
  Future<Listing> getById(String id) async {
    final row = await _db
        .from('listings')
        .select(Listing.selectWithRelations)
        .eq('id', id)
        .single();
    return Listing.fromJson(row);
  }

  @override
  Future<List<Listing>> byOwner(String ownerId, {bool onlyActive = true}) async {
    var q = _db.from('listings').select(Listing.selectWithRelations).eq('owner_id', ownerId);
    if (onlyActive) {
      q = q.eq('status', 'active');
    } else {
      q = q.neq('status', 'removed');
    }
    final rows = await q.order('created_at', ascending: false);
    return rows.map(Listing.fromJson).toList();
  }

  @override
  Future<Listing> create(ListingDraft draft, List<Uint8List> jpegImages) async {
    final paths = <String>[];
    try {
      for (final bytes in jpegImages) {
        final path = '$_uid/${const Uuid().v4()}.jpg';
        await _db.storage.from('listing-images').uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
            );
        paths.add(path);
      }
      final row = await _db
          .from('listings')
          .insert({'owner_id': _uid, ...draft.toRow(images: paths)})
          .select('id')
          .single();
      final id = row['id'] as String;
      if (draft.wants.isNotEmpty) {
        await _db.from('listing_wants').insert([
          for (final w in draft.wants.toSet())
            {'listing_id': id, 'category_id': w.categoryId, 'keyword': w.keyword},
        ]);
      }
      return await getById(id);
    } catch (_) {
      // تنظيف الصور المرفوعة إذا فشل إنشاء الإعلان
      if (paths.isNotEmpty) {
        await _db.storage.from('listing-images').remove(paths).catchError((_) => <FileObject>[]);
      }
      rethrow;
    }
  }

  @override
  Future<void> setStatus(String id, ListingStatus status) =>
      _db.from('listings').update({'status': status.db}).eq('id', id);

  @override
  Future<bool> isFavorite(String listingId) async {
    final row = await _db
        .from('favorites')
        .select('listing_id')
        .eq('user_id', _uid)
        .eq('listing_id', listingId)
        .maybeSingle();
    return row != null;
  }

  @override
  Future<void> setFavorite(String listingId, bool value) async {
    if (value) {
      await _db.from('favorites').upsert({'user_id': _uid, 'listing_id': listingId});
    } else {
      await _db.from('favorites').delete().eq('user_id', _uid).eq('listing_id', listingId);
    }
  }

  @override
  Future<List<Listing>> favorites() async {
    final rows = await _db
        .from('favorites')
        .select('listing:listings(${Listing.selectWithRelations})')
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    return rows
        .map((r) => r['listing'])
        .whereType<Map<String, dynamic>>()
        .map(Listing.fromJson)
        .toList();
  }
}
