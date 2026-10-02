enum ReportReason {
  fraud('fraud', 'احتيال'),
  fakeItem('fake_item', 'غرض مزيف'),
  notAsDescribed('not_as_described', 'غير مطابق للوصف'),
  prohibitedItem('prohibited_item', 'غرض ممنوع (أدوية، مساعدات للبيع...)'),
  inappropriate('inappropriate_content', 'محتوى مخالف'),
  suspicious('suspicious_account', 'حساب مشبوه'),
  priceGouging('price_gouging', 'استغلال واحتكار'),
  other('other', 'أخرى');

  const ReportReason(this.db, this.label);
  final String db;
  final String label;
}
