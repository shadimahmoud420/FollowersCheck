// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Follower Check';

  @override
  String get next => 'التالي';

  @override
  String get back => 'رجوع';

  @override
  String get skip => 'تخطي';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get ok => 'حسنًا';

  @override
  String get neverPassword => 'لن نطلب كلمة المرور أبدًا';

  @override
  String get onboardingTitle1 => 'اعرف من ألغى متابعتك';

  @override
  String get onboardingBody1 =>
      'يقارن Follower Check نسختين من ملف بياناتك الذي تصدّره من Instagram، ويعرض لك من ألغى متابعتك، ومن لا يتابعك بالمقابل، ومن هم متابعوك الجدد.';

  @override
  String get onboardingTitle2 => 'صدّر بياناتك بصيغة JSON';

  @override
  String get onboardingBody2 =>
      'من تطبيق Instagram اطلب نسخة من \"المتابِعون والمتابَعون\" بصيغة JSON، وسيُعلمك Instagram عندما يصبح الملف جاهزًا للتنزيل.';

  @override
  String get onboardingTitle3 => 'الخصوصية أولًا';

  @override
  String get onboardingBody3 =>
      'لا نطلب كلمة المرور ولا نسجّل الدخول إلى حسابك أبدًا. تتم معالجة ملفاتك على هذا الجهاز فقط ولا تُرفع إلى أي مكان.';

  @override
  String get exportStepsTitle => 'طريقة التصدير';

  @override
  String get exportStep1 => 'افتح الإعدادات › مركز الحسابات';

  @override
  String get exportStep2 => 'معلوماتك وأذوناتك › تصدير معلوماتك';

  @override
  String get exportStep3 => 'إنشاء تصدير › التصدير إلى الجهاز';

  @override
  String get exportStep4 => 'تخصيص المعلومات: اختر \"المتابِعون والمتابَعون\" فقط';

  @override
  String get exportStep5 => 'النطاق الزمني: كل الأوقات · الصيغة: JSON';

  @override
  String get exportStep6 => 'نزّل ملف ZIP عندما يصبح جاهزًا ثم استورده هنا';

  @override
  String get navResults => 'النتائج';

  @override
  String get navHistory => 'السجل';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get importTitle => 'استيراد ملف';

  @override
  String get importIntro => 'اختر ملف ZIP الذي نزّلته، أو ملفَي followers_1.json و following.json من داخله.';

  @override
  String get importPick => 'اختر ملف ZIP أو JSON';

  @override
  String get importProcessing => 'جارٍ قراءة ملفاتك على هذا الجهاز…';

  @override
  String get importSuccessTitle => 'اكتمل الاستيراد';

  @override
  String importSuccessBody(int followers, int following) {
    return 'المتابِعون: $followers · المتابَعون: $following';
  }

  @override
  String get importMissingFollowing =>
      'لم يتم العثور على قائمة المتابَعين، لذلك لن تتوفر قائمة \"لا يتابعونك\" لهذه النسخة.';

  @override
  String get viewResults => 'عرض النتائج';

  @override
  String get errorHtml => 'هذا الملف بصيغة HTML. يُرجى التصدير مرة أخرى واختيار صيغة JSON.';

  @override
  String get errorCorrupt => 'تعذّر فتح ملف ZIP. يُرجى تنزيله مرة أخرى والمحاولة من جديد.';

  @override
  String get errorNothing =>
      'لم نعثر على بيانات المتابِعين في هذه الملفات. تأكد من اختيار \"المتابِعون والمتابَعون\" وصيغة JSON.';

  @override
  String get errorMissingFollowers =>
      'تم العثور على قائمة المتابَعين فقط. يُرجى إضافة ملف المتابِعين (followers_1.json) أيضًا.';

  @override
  String get errorGeneric => 'حدث خطأ أثناء قراءة الملف. حاول مرة أخرى.';

  @override
  String freeLimitReached(String date) {
    return 'تتضمن الخطة المجانية مقارنة واحدة أسبوعيًا. مقارنتك المجانية التالية متاحة في $date.';
  }

  @override
  String get upgrade => 'الترقية إلى Premium';

  @override
  String get resultsTitle => 'النتائج';

  @override
  String get tabUnfollowed => 'ألغوا متابعتك';

  @override
  String get tabNotFollowingBack => 'لا يتابعونك';

  @override
  String get tabNewFollowers => 'متابعون جدد';

  @override
  String get searchHint => 'ابحث عن اسم مستخدم';

  @override
  String get openProfile => 'فتح الملف الشخصي';

  @override
  String get couldNotOpenLink => 'تعذّر فتح الرابط.';

  @override
  String get noDataTitle => 'لا توجد بيانات بعد';

  @override
  String get noDataBody => 'استورد أول ملف لتبدأ.';

  @override
  String get needsTwoSnapshots =>
      'هذه أول نسخة لديك. استورد ملفًا أحدث لاحقًا لمعرفة من ألغى متابعتك ومن تابعك حديثًا.';

  @override
  String get emptyList => 'لا أحد هنا';

  @override
  String get noSearchResults => 'لا توجد أسماء مطابقة لبحثك';

  @override
  String get followingUnavailable => 'هذه النسخة لا تحتوي على قائمة المتابَعين. استورد ملفًا يتضمن following.json.';

  @override
  String comparing(String previous, String latest) {
    return '$previous ← $latest';
  }

  @override
  String snapshotFrom(String date) {
    return 'نسخة بتاريخ $date';
  }

  @override
  String shownCount(int shown, int total) {
    return '$shown من $total';
  }

  @override
  String totalCount(int count) {
    return 'العدد: $count';
  }

  @override
  String get newImport => 'استيراد جديد';

  @override
  String get historyTitle => 'السجل';

  @override
  String get historyEmpty => 'ستظهر نسخك المحفوظة هنا.';

  @override
  String followersLabel(int count) {
    return 'المتابِعون: $count';
  }

  @override
  String followingLabel(int count) {
    return 'المتابَعون: $count';
  }

  @override
  String get chartTitle => 'المتابِعون عبر الزمن';

  @override
  String get chartLocked => 'الرسوم البيانية ميزة Premium';

  @override
  String get chartNeedsTwo => 'استورد نسختين على الأقل لعرض الرسم البياني.';

  @override
  String historyLocked(int count) {
    return '$count نسخ أقدم متاحة مع Premium';
  }

  @override
  String get deleteSnapshotTitle => 'حذف النسخة؟';

  @override
  String get deleteSnapshotBody => 'سيتم حذف هذه النسخة نهائيًا من هذا الجهاز.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get reminders => 'تذكير بالتصدير';

  @override
  String get remindersSubtitle => 'إشعار محلي يذكّرك بطلب ملف تصدير جديد';

  @override
  String get reminderOff => 'متوقف';

  @override
  String get reminderWeekly => 'أسبوعيًا';

  @override
  String get reminderBiweekly => 'كل أسبوعين';

  @override
  String get reminderNotificationTitle => 'حان وقت تصدير جديد';

  @override
  String get reminderNotificationBody => 'اطلب تصديرًا جديدًا لـ\"المتابِعون والمتابَعون\" لمعرفة من ألغى متابعتك.';

  @override
  String get reminderPermissionDenied => 'الإشعارات معطّلة لهذا التطبيق. فعّلها من إعدادات النظام.';

  @override
  String get dataSection => 'البيانات والخصوصية';

  @override
  String get deleteAllData => 'حذف جميع البيانات';

  @override
  String get deleteAllTitle => 'حذف جميع البيانات؟';

  @override
  String get deleteAllBody => 'سيتم حذف جميع النسخ نهائيًا من هذا الجهاز. لا يمكن التراجع عن ذلك.';

  @override
  String get dataDeleted => 'تم حذف جميع البيانات';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get showGuide => 'عرض دليل التصدير';

  @override
  String get premium => 'Premium';

  @override
  String get premiumActive => 'اشتراك Premium مفعّل';

  @override
  String get premiumInactive => 'مقارنات غير محدودة وسجل كامل ورسوم بيانية';

  @override
  String get debugPremium => 'محاكاة Premium (نسخ التطوير فقط)';

  @override
  String get about => 'حول';

  @override
  String get disclaimer =>
      'Follower Check تطبيق مستقل، ولا يرتبط بـ Instagram أو Meta ولا يحظى برعايتهما أو اعتمادهما.';

  @override
  String get paywallTitle => 'Follower Check Premium';

  @override
  String get paywallFeature1 => 'مقارنات غير محدودة';

  @override
  String get paywallFeature2 => 'سجل كامل لجميع النسخ';

  @override
  String get paywallFeature3 => 'رسوم بيانية للمتابِعين';

  @override
  String paywallBuy(String price) {
    return 'ترقية · $price';
  }

  @override
  String get paywallRestore => 'استعادة المشتريات';

  @override
  String get paywallUnavailable => 'الشراء غير متاح حاليًا. يُرجى المحاولة لاحقًا.';

  @override
  String get privacyTitle => 'سياسة الخصوصية';

  @override
  String get privacyBody =>
      'يعمل Follower Check بالكامل على جهازك.\n\n• لا نطلب كلمة مرور Instagram ولا نسجّل الدخول إلى حسابك أبدًا.\n• لا نستخدم أي واجهة برمجية غير رسمية ولا نتصل بأي خادم.\n• تُقرأ ملفات التصدير التي تختارها على هذا الجهاز فقط، ولا يُحفظ سوى أسماء المستخدمين والتواريخ في قاعدة بيانات محلية داخل التطبيق.\n• لا توجد أدوات تحليل أو إعلانات أو تتبّع.\n• التذكيرات إشعارات محلية تُجدول على جهازك.\n• يمكنك حذف جميع البيانات في أي وقت من الإعدادات › حذف جميع البيانات، أو بحذف التطبيق.\n\nFollower Check تطبيق مستقل ولا يرتبط بـ Instagram أو Meta.';
}
