/// إعدادات البيئة. القيم الافتراضية تشير إلى مشروع Supabase الأساسي،
/// ويمكن تجاوزها وقت البناء (مثلاً لمشروع تجريبي):
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
/// SUPABASE_KEY = المفتاح العام (publishable) — آمن داخل التطبيق لأن RLS يحمي البيانات.
/// لا تضع هنا أبداً مفتاح secret أو service_role.
class Env {
  static const _defaultUrl = 'https://xghlnygsnklooeisoawm.supabase.co';
  static const _defaultKey = 'sb_publishable_T7meWpEiNnw3u7d85jKz1w_dzdZlzY6';

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _key = String.fromEnvironment('SUPABASE_KEY');

  static String get supabaseUrl => _url.isEmpty ? _defaultUrl : _url;
  static String get supabaseKey => _key.isEmpty ? _defaultKey : _key;

  /// رابط صفحة الويب العامة للإعلانات (للمشاركة والـ Deep Links).
  static const webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'https://badelha.app',
  );

  /// رابط العودة إلى التطبيق بعد الضغط على رابط الدخول في البريد.
  /// يجب إضافته في Supabase: Authentication → URL Configuration → Redirect URLs
  static const authRedirectUrl = 'ps.badelha.app://login-callback';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
