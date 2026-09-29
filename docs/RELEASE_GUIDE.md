# دليل Follower Check الكامل: من التشغيل إلى النشر في المتاجر

يغطي هذا الدليل كل الخطوات بالترتيب: الخطوات المشتركة أولاً، ثم Google Play، ثم App Store.

---

## 0) ما تحتاجه قبل البدء

| الأداة / الحساب | لماذا | التكلفة |
|---|---|---|
| Flutter SDK (الإصدار المستقر 3.47 أو أحدث) | بناء التطبيق | مجاني |
| Android Studio | Android SDK ومحاكي أندرويد | مجاني |
| حساب Google Play Console | النشر على Google Play | 25$ مرة واحدة |
| حساب Apple Developer Program | النشر على App Store | 99$ سنوياً |
| جهاز Mac مع Xcode **أو** حساب Codemagic | بناء نسخة iOS | في Codemagic خطة مجانية بدقائق محدودة |

تحقق من البيئة بتشغيل:
```bash
flutter doctor
```

---

## 1) التشغيل لأول مرة

```bash
cd FollowersCheck
bash tool/setup.sh   # مرة واحدة
flutter run
```

مجلدا `android/` و `ios/` موجودان مسبقاً في المشروع ومضبوطان، لذلك لا يحتاج السكربت إلى `flutter create`. يقوم `tool/setup.sh` بما يلي:
1. يثبّت الحزم ويولّد ملفات اللغتين العربية والإنجليزية.
2. ينشئ الأيقونة عبر `tool/make_icon.py` (يحتاج مكتبة Pillow: `pip install pillow`، وإن لم تتوفر يستخدم الأيقونة المحفوظة)، ثم يثبّت أيقونات التطبيق وشاشة البداية.
3. يشغّل الفحص والاختبارات.

لتعديل تصميم الأيقونة: عدّل الألوان أو الرسم في `tool/make_icon.py`، ثم شغّل السكربت من جديد. واحرص على ألا تشبه الأيقونة شعار إنستغرام أو ألوانه.

الإعدادات الأصلية المضبوطة مسبقاً:
- **في iOS:** اسم التطبيق «Follower Check»، واللغتان العربية والإنجليزية، والوضع العمودي فقط، و iPhone فقط (فلا تُطلب لقطات iPad)، وخيار `ITSAppUsesNonExemptEncryption = NO`.
- **في Android:** بدون إذن الإنترنت، وأذونات الإشعارات (`POST_NOTIFICATIONS` و `RECEIVE_BOOT_COMPLETED`) للتذكيرات فقط، وتوقيع نسخة الإصدار من ملف `key.properties`.

> **مهم:** لا يمكن تغيير معرّف التطبيق (Bundle ID / Application ID) بعد أول رفع، لذلك ثبّته قبل النشر. المعرّفات الحالية:
> - Android: `com.followercheck.follower_check` (في `android/app/build.gradle.kts`)
> - iOS: `com.followercheck.followerCheck` (في Xcode، وفي `BUNDLE_ID` داخل `codemagic.yaml`)
>
> لا تستخدم كلمة «Instagram» أو «Insta» في المعرّف أو الاسم أو الأيقونة.

### الاختبارات
```bash
flutter analyze
flutter test
```

---

## 2) تجهيز اشتراك Premium (قبل تفعيل الشراء)

الشراء داخل التطبيق مجهّز كواجهة (`EntitlementService`)، لكنه غير مربوط بمنتج حقيقي بعد. قبل تفعيله:

1. أنشئ منتجاً **غير مستهلك (Non-consumable)** بالمعرّف `follower_check_premium`:
   - في Play Console: **Monetize** ثم **In-app products**.
   - في App Store Connect: **In-App Purchases** ثم **+**.
2. في App Store Connect وقّع اتفاقية **Paid Apps** وأكمل بيانات البنك والضرائب، وإلا فلن تظهر المنتجات.
3. جرّب الشراء بحساب **Sandbox** في iOS، وبحساب **License tester** في Google Play.
4. يُنصح بإضافة التحقق من الإيصال قبل النشر (راجع `TODO(premium)` في `lib/features/premium/data/in_app_purchase_entitlement_service.dart`).

قبل إنشاء المنتج تعرض شاشة Premium رسالة «الشراء غير متاح حالياً»، ويبقى التطبيق يعمل بالخطة المجانية (مقارنة واحدة أسبوعياً).

---

## 3) اختبار شامل قبل النشر (Checklist)

- [ ] جرّب على شاشة صغيرة (iPhone SE أو أندرويد بعرض 360dp) وعلى شاشة كبيرة (Pro Max).
- [ ] جرّب الواجهة باللغتين العربية والإنجليزية، وبالوضعين الفاتح والداكن.
- [ ] صدّر بياناتك الحقيقية من إنستغرام بصيغة **JSON** واستورد ملف ZIP كما هو.
- [ ] استورد الملفين `followers_1.json` و `following.json` منفردين (اختيار أكثر من ملف).
- [ ] جرّب ملف تصدير بصيغة **HTML**، وتأكد من ظهور رسالة «صدّر مرة أخرى بصيغة JSON».
- [ ] جرّب حد الخطة المجانية: استورد مرتين في الأسبوع نفسه.
- [ ] فعّل التذكير الأسبوعي، ثم ارفض إذن الإشعارات وتأكد من ظهور رسالة واضحة دون أن يتعطل التطبيق.
- [ ] جرّب زر فتح الملف الشخصي (يفتح المتصفح أو تطبيق إنستغرام).
- [ ] جرّب «حذف جميع البيانات».
- [ ] شغّل نسخة الإصدار: `flutter run --release`.

لتجربة سريعة بدون تصدير حقيقي، يمكنك إنشاء ملفين من بيانات الاختبار:
```bash
(cd test/fixtures/legacy && zip -r /tmp/export_week1.zip .)
(cd test/fixtures/current && zip -r /tmp/export_week2.zip .)
```

---

## 4) Google Play

### 4.1 مفتاح التوقيع (مرة واحدة فقط، واحتفظ به بأمان)
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```
انسخ `android/key.properties.example` إلى `android/key.properties` واملأ القيم.
**لا ترفع هذا الملف ولا ملف `.jks` إلى git.** الملف `.gitignore` يستثنيهما مسبقاً.

### 4.2 بناء الحزمة
```bash
flutter build appbundle --release
# الناتج: build/app/outputs/bundle/release/app-release.aab
```

### 4.3 Play Console
1. **Create app**: الاسم `Follower Check: Unfollow Tracker`، واللغة الافتراضية العربية، والنوع App، والتطبيق مجاني (مع مشتريات داخلية).
2. **App content** (محتوى التطبيق):
   - **Privacy policy**: ارفع `docs/privacy-policy.html` على رابط عام (مثل GitHub Pages، انظر القسم 6)، ثم ضع الرابط هنا.
   - **Data safety**: التطبيق **لا يجمع أي بيانات ولا يشاركها**. الملفات تُعالج على الجهاز فقط.
   - **Ads**: لا يوجد.
   - **Content rating**: أجب على الاستبيان. الفئة Utility، والنتيجة المتوقعة Everyone أو 3+.
   - **Target audience**: 13+.
   - **Permissions**: وضّح أن `POST_NOTIFICATIONS` للتذكير المحلي بطلب تصدير جديد.
3. **Store listing**: انسخ النصوص من `docs/STORE_LISTING.md`، وارفع الأيقونة `assets/icon/icon.png` بعد تصغيرها إلى 512×512، وصورة Feature graphic بمقاس 1024×500، ومن 2 إلى 8 لقطات شاشة.
   - **لا تستخدم شعار إنستغرام ولا ألوانه ولا لقطات من واجهته** في الأيقونة أو الصور.
4. **Testing**:
   - الحسابات الشخصية الجديدة مطالَبة بـ **Closed testing** مع **12 مختبراً على الأقل لمدة 14 يوماً متواصلة** قبل السماح بالنشر للجميع.
   - ارفع ملف `.aab` في Closed testing، وأضف قائمة بريد المختبرين، ثم شارك معهم رابط الاشتراك.
5. بعد مرور 14 يوماً: **Apply for production**، ثم **Production** ثم **Create release**، ارفع الحزمة ثم **Send for review**.

### 4.4 التحديثات
زِد رقم البناء في `pubspec.yaml` مع كل رفع جديد، مثلاً `version: 1.0.1+2`.

---

## 5) App Store (iOS)

### 5.1 التسجيل
1. اشترك في Apple Developer Program: https://developer.apple.com/programs
2. في **Certificates, Identifiers & Profiles** ثم **Identifiers**: أنشئ App ID بالمعرّف `com.followercheck.followerCheck`.
3. في App Store Connect: **My Apps** ثم **+** ثم **New App**:
   - الاسم: `Follower Check: Unfollowers`. إذا كان الاسم محجوزاً فجرّب `Follower Check – Tracker`.
   - Primary language: Arabic، و SKU: `followercheck-001`.

### 5.2 البناء على جهاز Mac
```bash
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```
في Xcode: **Runner** ثم **Signing & Capabilities** ثم اختر **Team** وفعّل **Automatically manage signing**. أضف أيضاً قدرة **In-App Purchase**.

```bash
flutter build ipa --release
```
بعد ذلك ارفع الملف `build/ios/ipa/*.ipa` باستخدام تطبيق **Transporter** من Mac App Store، أو عبر Xcode من **Window** ثم **Organizer** ثم **Distribute App**.

### 5.3 بدون جهاز Mac (Codemagic)
1. أنشئ حساباً على https://codemagic.io واربط مستودع git.
2. في App Store Connect: **Users and Access** ثم **Integrations** ثم **App Store Connect API**، وأنشئ مفتاحاً بصلاحية App Manager، ثم نزّل ملف `.p8`.
3. في Codemagic: **Team settings** ثم **Integrations** ثم **Developer Portal**، وأضف المفتاح باسم `FollowerCheck ASC`.
4. أنشئ مجموعة متغيرات باسم `ios_signing` تحتوي على `CERTIFICATE_PRIVATE_KEY` (مفتاح RSA خاص؛ أنشئه بالأمر `ssh-keygen -t rsa -b 2048 -m PEM -f cert_key -q -N ""` وانسخ محتوى `cert_key`).
5. في `codemagic.yaml`: ضع قيمة `APP_STORE_APPLE_ID`، وتأكد من `BUNDLE_ID`.
6. شغّل workflow **ios-release**، وسيصل البناء إلى TestFlight تلقائياً.

ولأندرويد عبر Codemagic: ارفع ملف `.jks` في **Team → Code signing identities** باسم `followercheck_upload_key`، وأنشئ مجموعة `google_play` تحتوي على `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` (ملف JSON لحساب خدمة Play Console)، ثم شغّل workflow **android-release**.

### 5.4 صفحة التطبيق في App Store Connect
- **App Privacy**: اختر **Data Not Collected**.
- **Age rating**: أجب على الاستبيان، والنتيجة المتوقعة 4+.
- **Screenshots**: لقطات iPhone بمقاس 6.9 بوصة (1320×2868) إلزامية، ويمكن إضافة مقاس 6.5 بوصة (1284×2778).
- **Category**: Utilities، والفئة الثانوية Social Networking.
- **In-App Purchases**: أرفق منتج `follower_check_premium` بأول نسخة ترسلها للمراجعة.
- **App Review Information**: التطبيق لا يحتاج تسجيل دخول. أرفق ملفَي ZIP للتجربة (من القسم 3) واكتب ملاحظة للمراجع:
  > Follower Check compares two data-export files that the user downloads from their own Instagram account (Settings › Accounts Center › Your information and permissions › Export your information, JSON format). The app never asks for a password, never signs in, uses no unofficial API and makes no network requests; everything is processed on-device. To test: import export_week1.zip, then export_week2.zip, and open the Results tab. The free plan allows one comparison per week; use a sandbox purchase of Premium to import twice.
- اختر البناء من TestFlight ثم **Add for Review** ثم **Submit**.

---

## 6) رفع سياسة الخصوصية وصفحة الدعم (GitHub Pages)

1. في GitHub افتح المستودع ثم **Settings** ثم **Pages**.
2. في **Source** اختر الفرع `main` والمجلد `/docs`، ثم **Save**.
3. بعد دقائق ستصبح الروابط متاحة:
   - صفحة الدعم: `https://<اسم-المستخدم>.github.io/FollowersCheck/`
   - سياسة الخصوصية: `https://<اسم-المستخدم>.github.io/FollowersCheck/privacy-policy.html`
4. ضع رابط سياسة الخصوصية في Play Console و App Store Connect، وضع رابط الدعم في حقل **Support URL** في App Store.

---

## 7) أسباب الرفض الشائعة وطريقة تجنبها

| السبب | ما فعلناه |
|---|---|
| استخدام علامة Instagram في الاسم أو الأيقونة أو المعرّف | الاسم Follower Check، والمعرّف لا يحتوي الكلمة. لا تضع «Instagram» في الاسم أو العنوان الفرعي أو الكلمات المفتاحية. يمكن ذكرها في الوصف فقط مع عبارة إخلاء المسؤولية. |
| الاشتباه بجمع كلمات المرور أو استخدام API غير رسمي | التطبيق لا يطلب كلمة مرور ولا يسجّل الدخول ولا يتصل بالإنترنت أصلاً (لا يوجد إذن INTERNET). وضّح ذلك في ملاحظة المراجع. |
| غياب سياسة الخصوصية | موجودة في `docs/privacy-policy.html`، وداخل التطبيق من الإعدادات. ارفعها وضع رابطها. |
| الشراء خارج نظام المتجر (Guideline 3.1.1) | الشراء عبر `in_app_purchase` فقط، مع زر «استعادة المشتريات». |
| تطبيق «بسيط جداً» (Guideline 4.2) | ثلاث قوائم نتائج مع بحث، وسجل ورسم بياني، وتذكيرات، ولغتان. قدّم لقطات شاشة تُظهر هذه الميزات. |
| المراجع لا يستطيع التجربة | أرفق ملفَي ZIP تجريبيين واشرح الخطوات في ملاحظة المراجعة. |

للمزيد من التفاصيل بالإنجليزية راجع [`STORE_NOTES.md`](../STORE_NOTES.md).
