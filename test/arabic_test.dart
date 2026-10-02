import 'package:badelha/core/utils/arabic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeArabic (must match normalize_ar in SQL)', () {
    test('unifies alef forms, taa marbuta and alef maqsura', () {
      expect(normalizeArabic('أحمد إبراهيم آمنة'), 'احمد ابراهيم امنه');
      expect(normalizeArabic('طاقة شمسية'), 'طاقه شمسيه');
      expect(normalizeArabic('مستشفى'), 'مستشفي');
    });

    test('removes diacritics and tatweel', () {
      expect(normalizeArabic('هَاتِفٌ'), 'هاتف');
      expect(normalizeArabic('بـــطارية'), 'بطاريه');
    });

    test('lowercases latin and trims', () {
      expect(normalizeArabic('  Samsung A54 '), 'samsung a54');
    });
  });

  test('toLatinDigits converts Arabic-Indic digits', () {
    expect(toLatinDigits('٣٠٠ واط'), '300 واط');
    expect(toLatinDigits('123'), '123');
  });
}
