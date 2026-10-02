import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/reference_models.dart';

abstract interface class ReferenceRepository {
  Future<ReferenceData> load();
}

class SupabaseReferenceRepository implements ReferenceRepository {
  SupabaseReferenceRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<ReferenceData> load() async {
    final results = await Future.wait([
      _db.from('governorates').select('id, name_ar').order('sort_order'),
      _db.from('areas').select('id, governorate_id, name_ar')
          .eq('is_active', true).order('sort_order'),
      _db.from('categories').select('id, slug, name_ar, icon')
          .eq('is_active', true).order('sort_order'),
    ]);
    return ReferenceData(
      governorates: results[0].map(Governorate.fromJson).toList(),
      areas: results[1].map(Area.fromJson).toList(),
      categories: results[2].map(Category.fromJson).toList(),
    );
  }
}
