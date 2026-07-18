# دليل نشر تطبيق "حصتي" على جوجل بلاي

لقد قمت بمراجعة الكود، وإصلاح الأخطاء البرمجية، وتحديث المكتبات المتعارضة، وتجهيز هيكل الأندرويد للنشر.

## الخطوات النهائية المطلوبة منك:

### 1. إعداد Firebase (ضروري جداً)
بما أنني لا أملك الوصول لمشروع Firebase الخاص بك، يجب عليك:
*   الدخول إلى [Firebase Console](https://console.firebase.google.com/).
*   إضافة تطبيق Android جديد بمعرف الحزمة (Package Name): `com.hissati.app`.
*   تحميل ملف `google-services.json` ووضعه في المجلد: `android/app/`.
*   تفعيل إضافة Google Services في ملف `android/app/build.gradle` (قم بإزالة علامتي التعليق `//` من السطر الخاص بها).

### 2. مفتاح التوقيع (Keystore)
لقد قمت بإنشاء مفتاح توقيع تجريبي وربطه بالمشروع:
*   **المسار:** `android/app/upload-keystore.jks`
*   **كلمة المرور:** `hissati123`
*   **Alias:** `upload`
*   *نصيحة:* يفضل إنشاء مفتاح خاص بك للنشر الفعلي وحفظه في مكان آمن.

### 3. بناء النسخة النهائية (Build)
بعد إضافة ملف `google-services.json` بنجاح وتجنب أي تعارضات مستقبلية مع بيئة الأندرويد الحديثة، افتح التيرمينال في مجلد المشروع وقم بتشغيل:
```bash
flutter build appbundle --release
```
ستجد الملف الناتج في: `build/app/outputs/bundle/release/app-release.aab`.

## التعديلات التي قمت بها:
1.  **إصلاح الكود:** تم تصحيح أخطاء `GeoFlutterFire` والوصول للقيم الاختيارية (Null Safety).
2.  **تحديث التبعيات:** حل تعارضات الإصدارات بين Firebase و Geoflutterfire.
3.  **هيكل الأندرويد:** تحديث `compileSdk` إلى 36 وإضافة `MainActivity.java` المفقود.
4.  **الأداء:** تفعيل `minifyEnabled` و `shrinkResources` لتقليل حجم التطبيق.

بالتوفيق في إطلاق تطبيقك!
