import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authStateChangesProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(supabaseClientProvider).auth.onAuthStateChange,
);

/// معرّف المستخدم الحالي، ويتحدّث عند تسجيل الدخول/الخروج.
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseClientProvider).auth.currentUser?.id;
});

/// روابط الصور العامة من مسارات التخزين.
class StorageUrls {
  StorageUrls(this._client);
  final SupabaseClient _client;

  String listingImage(String path) =>
      _client.storage.from('listing-images').getPublicUrl(path);

  String? avatar(String? path) => path == null || path.isEmpty
      ? null
      : _client.storage.from('avatars').getPublicUrl(path);
}

final storageUrlsProvider = Provider<StorageUrls>(
  (ref) => StorageUrls(ref.watch(supabaseClientProvider)),
);
