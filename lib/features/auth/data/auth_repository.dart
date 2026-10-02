import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';

/// تسجيل الدخول عبر البريد (لا يعتمد على SMS غير المستقر).
/// الرسالة تحتوي رابطاً يفتح التطبيق مباشرة، ورمزاً من 6 أرقام إذا
/// كان قالب البريد يتضمن {{ .Token }} (يتطلب SMTP خاصاً في Supabase).
abstract interface class AuthRepository {
  Future<void> sendEmailCode(String email);
  Future<void> verifyEmailCode(String email, String code);
  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);
  final GoTrueClient _auth;

  @override
  Future<void> sendEmailCode(String email) =>
      _auth.signInWithOtp(
        email: email.trim().toLowerCase(),
        shouldCreateUser: true,
        emailRedirectTo: kIsWeb ? null : Env.authRedirectUrl,
      );

  @override
  Future<void> verifyEmailCode(String email, String code) => _auth.verifyOTP(
        type: OtpType.email,
        email: email.trim().toLowerCase(),
        token: code.trim(),
      );

  @override
  Future<void> signOut() => _auth.signOut();
}
