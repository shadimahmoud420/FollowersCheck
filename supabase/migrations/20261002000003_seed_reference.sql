-- =====================================================================
-- بدّلها — البيانات المرجعية: المحافظات، المناطق، الفئات
-- المناطق قابلة للتعديل من لوحة الإشراف (النزوح يغيّر الواقع باستمرار).
-- =====================================================================

insert into governorates (id, slug, name_ar, name_en, sort_order) values
  (1, 'north_gaza',    'شمال غزة',  'North Gaza',    1),
  (2, 'gaza',          'غزة',       'Gaza City',     2),
  (3, 'deir_al_balah', 'الوسطى',    'Deir al-Balah', 3),
  (4, 'khan_younis',   'خانيونس',   'Khan Younis',   4),
  (5, 'rafah',         'رفح',       'Rafah',         5);

insert into areas (governorate_id, name_ar, name_en, sort_order) values
  (1, 'جباليا',        'Jabalia',        1),
  (1, 'مخيم جباليا',   'Jabalia Camp',   2),
  (1, 'بيت لاهيا',     'Beit Lahia',     3),
  (1, 'بيت حانون',     'Beit Hanoun',    4),
  (2, 'الرمال',        'Al-Rimal',       1),
  (2, 'تل الهوى',      'Tal al-Hawa',    2),
  (2, 'الشيخ رضوان',   'Sheikh Radwan',  3),
  (2, 'النصر',         'An-Nasr',        4),
  (2, 'الشاطئ',        'Al-Shati',       5),
  (2, 'الشجاعية',      'Shuja''iyya',    6),
  (2, 'التفاح',        'At-Tuffah',      7),
  (2, 'الدرج',         'Ad-Daraj',       8),
  (2, 'الزيتون',       'Az-Zaytun',      9),
  (2, 'الصبرة',        'As-Sabra',      10),
  (2, 'الشيخ عجلين',   'Sheikh Ajleen', 11),
  (3, 'دير البلح',     'Deir al-Balah',  1),
  (3, 'النصيرات',      'Nuseirat',       2),
  (3, 'البريج',        'Bureij',         3),
  (3, 'المغازي',       'Maghazi',        4),
  (3, 'الزوايدة',      'Az-Zawayda',     5),
  (4, 'خانيونس البلد', 'Khan Younis City', 1),
  (4, 'المواصي',       'Al-Mawasi',      2),
  (4, 'بني سهيلا',     'Bani Suheila',   3),
  (4, 'عبسان',         'Abasan',         4),
  (4, 'القرارة',       'Al-Qarara',      5),
  (4, 'خزاعة',         'Khuza''a',       6),
  (5, 'رفح',           'Rafah',          1),
  (5, 'تل السلطان',    'Tal as-Sultan',  2),
  (5, 'الشابورة',      'Shaboura',       3);

-- icon = اسم أيقونة Material Icons في التطبيق
insert into categories (id, slug, name_ar, name_en, icon, sort_order) values
  (1,  'energy',      'طاقة وشحن',           'Energy & charging',   'solar_power',          1),
  (2,  'phones',      'هواتف',               'Phones',              'smartphone',           2),
  (3,  'electronics', 'إلكترونيات',          'Electronics',         'devices',              3),
  (4,  'computers',   'لابتوب وكمبيوتر',     'Computers',           'laptop',               4),
  (5,  'shelter',     'خيام وأغطية وفرشات',  'Shelter & bedding',   'night_shelter',        5),
  (6,  'kids',        'ملابس وأغراض أطفال',  'Kids',                'child_care',           6),
  (7,  'clothes',     'ملابس',               'Clothes',             'checkroom',            7),
  (8,  'kitchen',     'مطبخ وغاز ومياه',     'Kitchen, gas & water','kitchen',              8),
  (9,  'books',       'كتب ودراسة',          'Books & study',       'menu_book',            9),
  (10, 'tools',       'أدوات ومعدات',        'Tools',               'handyman',            10),
  (11, 'bikes',       'دراجات',              'Bikes',               'pedal_bike',          11),
  (12, 'furniture',   'أثاث',                'Furniture',           'chair',               12),
  (13, 'games',       'ألعاب',               'Games & toys',        'sports_esports',      13),
  (14, 'other',       'أخرى',                'Other',               'category',            99);
