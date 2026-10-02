import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/reference_repository.dart';
import '../domain/reference_models.dart';

final referenceRepositoryProvider = Provider<ReferenceRepository>(
  (ref) => SupabaseReferenceRepository(ref.watch(supabaseClientProvider)),
);

final referenceDataProvider = FutureProvider<ReferenceData>(
  (ref) => ref.watch(referenceRepositoryProvider).load(),
);

/// أيقونات الفئات (أسماء مخزنة في قاعدة البيانات).
IconData categoryIcon(String? name) => switch (name) {
      'solar_power' => Icons.solar_power_rounded,
      'smartphone' => Icons.smartphone_rounded,
      'devices' => Icons.devices_rounded,
      'laptop' => Icons.laptop_rounded,
      'night_shelter' => Icons.night_shelter_rounded,
      'child_care' => Icons.child_care_rounded,
      'checkroom' => Icons.checkroom_rounded,
      'kitchen' => Icons.kitchen_rounded,
      'menu_book' => Icons.menu_book_rounded,
      'handyman' => Icons.handyman_rounded,
      'pedal_bike' => Icons.pedal_bike_rounded,
      'chair' => Icons.chair_rounded,
      'sports_esports' => Icons.sports_esports_rounded,
      _ => Icons.category_rounded,
    };
