/// تطبيع النص العربي للبحث. يجب أن يطابق normalize_ar() في قاعدة البيانات.
String normalizeArabic(String input) {
  const from = 'أإآٱةى';
  const to = 'ااااهي';
  final diacritics = RegExp('[ً-ْـ]');
  final buffer = StringBuffer();
  for (final ch in input.replaceAll(diacritics, '').split('')) {
    final i = from.indexOf(ch);
    buffer.write(i >= 0 ? to[i] : ch);
  }
  return buffer.toString().toLowerCase().trim();
}

/// يحوّل الأرقام الهندية (٠-٩) إلى لاتينية، لأن كثيراً من لوحات المفاتيح تكتبها.
String toLatinDigits(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  return input.split('').map((c) {
    final i = arabic.indexOf(c);
    return i >= 0 ? '$i' : c;
  }).join();
}
