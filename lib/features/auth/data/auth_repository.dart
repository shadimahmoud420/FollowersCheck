import 'package:supabase_flutter/supabase_flutter.dart';

/// تسجيل الدخول برمز يُرسل إلى البريد (لا يعتمد على SMS غير المستقر).
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
      _auth.signInWithOtp(email: email.trim().toLowerCase(), shouldCreateUser: true);

  @override
  Future<void> verifyEmailCode(String email, String code) => _auth.verifyOTP(
        type: OtpType.email,
        email: email.trim().toLowerCase(),
        token: code.trim(),
      );

  @override
  Future<void> signOut() => _auth.signOut();
}
