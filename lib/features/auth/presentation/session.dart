import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../profile/domain/profile.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.watch(supabaseClientProvider).auth),
);

enum SessionStatus { loading, signedOut, needsProfile, ready, error }

class SessionState {
  const SessionState(this.status, {this.profile});
  final SessionStatus status;
  final Profile? profile;
}

/// حالة الجلسة: مسجّل؟ لديه ملف شخصي؟ — يعتمد عليها التوجيه.
class SessionController extends Notifier<SessionState> {
  StreamSubscription<AuthState>? _sub;

  @override
  SessionState build() {
    final auth = ref.watch(supabaseClientProvider).auth;
    _sub = auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn ||
          event.event == AuthChangeEvent.signedOut ||
          event.event == AuthChangeEvent.userUpdated) {
        refresh();
      }
    });
    ref.onDispose(() => _sub?.cancel());
    Future.microtask(refresh);
    return const SessionState(SessionStatus.loading);
  }

  Future<void> refresh() async {
    final auth = ref.read(supabaseClientProvider).auth;
    if (auth.currentUser == null) {
      state = const SessionState(SessionStatus.signedOut);
      return;
    }
    try {
      final profile = await ref.read(profileRepositoryProvider).getMine();
      state = profile == null
          ? const SessionState(SessionStatus.needsProfile)
          : SessionState(SessionStatus.ready, profile: profile);
    } catch (_) {
      // بدون إنترنت: نحاول لاحقاً ولا نُخرج المستخدم
      state = const SessionState(SessionStatus.error);
    }
  }
}

final sessionProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

/// ملفي الشخصي (مضمون الوجود بعد شاشة الإعداد)
final myProfileProvider = Provider<Profile?>(
  (ref) => ref.watch(sessionProvider).profile,
);
