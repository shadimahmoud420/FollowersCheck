import 'package:supabase_flutter/supabase_flutter.dart';

import '../../listings/domain/listing.dart';
import '../domain/match.dart';

abstract interface class MatchRepository {
  Future<List<SwapMatch>> findMatches({int limit = 50});
}

class SupabaseMatchRepository implements MatchRepository {
  SupabaseMatchRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<List<SwapMatch>> findMatches({int limit = 50}) async {
    final rows = (await _db.rpc('find_matches', params: {'p_limit': limit}) as List)
        .cast<Map<String, dynamic>>();
    if (rows.isEmpty) return const [];
    final ids = {
      for (final r in rows) ...[r['my_listing_id'] as String, r['their_listing_id'] as String],
    };
    final listings = await _db
        .from('listings')
        .select(Listing.selectWithRelations)
        .inFilter('id', ids.toList());
    final byId = {for (final l in listings.map(Listing.fromJson)) l.id: l};
    return [
      for (final r in rows)
        if (byId[r['my_listing_id']] != null && byId[r['their_listing_id']] != null)
          SwapMatch(
            mine: byId[r['my_listing_id']]!,
            theirs: byId[r['their_listing_id']]!,
            score: r['score'] as int,
          ),
    ];
  }
}
