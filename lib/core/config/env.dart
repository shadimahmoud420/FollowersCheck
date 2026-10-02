/// إعدادات البيئة تُمرَّر وقت البناء:
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
/// SUPABASE_KEY = المفتاح العام (publishable / anon) — آمن داخل التطبيق لأن RLS يحمي البيانات.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

  /// رابط صفحة الويب العامة للإعلانات (للمشاركة والـ Deep Links).
  static const webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'https://badelha.app',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
