import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_providers.dart';
import '../features/chat/data/chat_repository.dart';
import '../features/listings/data/listing_repository.dart';
import '../features/matches/data/match_repository.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/offers/data/offer_repository.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/safety/data/safety_repository.dart';

// حقن الاعتماديات: الواجهة تعتمد على الواجهات المجردة (interfaces) فقط،
// ويمكن استبدال Supabase لاحقاً أو استخدام نسخ وهمية في الاختبارات.

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SupabaseProfileRepository(ref.watch(supabaseClientProvider)),
);

final listingRepositoryProvider = Provider<ListingRepository>(
  (ref) => SupabaseListingRepository(ref.watch(supabaseClientProvider)),
);

final offerRepositoryProvider = Provider<OfferRepository>(
  (ref) => SupabaseOfferRepository(ref.watch(supabaseClientProvider)),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => SupabaseChatRepository(ref.watch(supabaseClientProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => SupabaseNotificationRepository(ref.watch(supabaseClientProvider)),
);

final safetyRepositoryProvider = Provider<SafetyRepository>(
  (ref) => SupabaseSafetyRepository(ref.watch(supabaseClientProvider)),
);

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => SupabaseMatchRepository(ref.watch(supabaseClientProvider)),
);
