// Every Arabic string of prayer times (feature 014, contracts/ui.md). They are proposals until the owner confirms them
// (Principle VI); changing one means changing this test first.
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/prayer/prayer_strings.dart';

void main() {
  test('the fixed strings', () {
    expect(kPrayerBarLabel, 'مواقيت');
    expect(kPrayerTitle, 'مواقيت الصلاة');
    expect(
      kPrayerIntro,
      'اعرف مواعيد الصلاة في مكانك، وتنبيه عند كل صلاة. كل ده بيتحسب على موبايلك من غير إنترنت.',
    );
    expect(kPrayerEnable, 'تشغيل مواقيت الصلاة');
    expect(kPrayerDisable, 'إيقاف مواقيت الصلاة');
    expect(kPlaceLocate, 'حدد موقعي');
    expect(kPlaceList, 'اختار المدينة من القائمة');
    expect(kPlaceSearch, 'ابحث عن مدينتك');
    expect(kPlaceFailed, 'مقدرناش نحدد موقعك. اختار مدينتك من القائمة.');
    expect(kOpenSettings, 'افتح الإعدادات');
    expect(kApprox, 'تقريبًا');
    expect(kNextPrayer, 'الصلاة القادمة');
    expect(kNextMark, 'القادمة');
    expect(kExactOff, 'التنبيهات ممكن تتأخر كام دقيقة.');
    expect(kExactAllow, 'اسمح بالتوقيت الدقيق');
    expect(kNotifOff, 'الإشعارات مقفولة للتطبيق.');
    expect(kZoneDiffers, 'توقيت موبايلك غير توقيت المكان ده.');
    expect(kHighLat, 'في المكان ده الفجر أو العشاء بيتحسب بطريقة تقريبية.');
    expect(kMonthTable, 'جدول الشهر');
    expect(kAdjust, 'ضبط المواقيت');
    expect(kTest, 'جرّب التنبيه');
    expect(kTestBody, 'كده التنبيه شغال.');
    expect(kBattery, 'لو التنبيه مبيوصلش');
    expect(
      kBatteryGuide,
      'بعض الموبايلات (زي سامسونج وشاومي) بتوقف التطبيقات في الخلفية. من إعدادات الموبايل افتح التطبيق، '
      'وخلي استخدام البطارية «غير مقيد»، وسيبه يشتغل في الخلفية.',
    );
    expect(kMethod, 'طريقة الحساب');
    expect(kMethodAuto, 'تلقائي (حسب البلد)');
    expect(kAsr, 'العصر');
    expect(kAsrStandard, 'الجمهور');
    expect(kAsrHanafi, 'الحنفي');
    expect(kOffsets, 'تعديل بالدقايق');
    expect(kNotifySound, 'بصوت');
    expect(kNotifySilent, 'صامت');
    expect(kNotifyOff, 'بدون');
    expect(kBefore, 'تذكير قبلها');
    expect(kBeforeOff, 'لا');
    expect(kChannelSound, 'تنبيه الصلاة');
    expect(kChannelSilent, 'تنبيه الصلاة (صامت)');
    expect(kChannelBefore, 'تذكير قبل الصلاة');
    expect(kHijriSuffix, 'هـ');
  });

  test('the six names and the methods', () {
    expect(kPrayerNames, [
      'الفجر',
      'الشروق',
      'الظهر',
      'العصر',
      'المغرب',
      'العشاء',
    ]);
    expect(kMethodNames['egyptian'], 'الهيئة المصرية العامة للمساحة');
    expect(kMethodNames['ummAlQura'], 'أم القرى (مكة)');
    expect(kMethodNames['muslimWorldLeague'], 'رابطة العالم الإسلامي');
    expect(kMethodNames['karachi'], 'جامعة العلوم الإسلامية (كراتشي)');
    expect(kMethodNames['dubai'], 'دبي');
    expect(kMethodNames['kuwait'], 'الكويت');
    expect(kMethodNames['qatar'], 'قطر');
    expect(kMethodNames['morocco'], 'المغرب');
    expect(kMethodNames['turkiye'], 'تركيا (ديانت)');
    expect(kMethodNames['northAmerica'], 'أمريكا الشمالية (إسنا)');
    expect(kMethodNames.length, 10);
  });

  test('the builders', () {
    expect(atPrayer('العصر'), 'حان الآن موعد صلاة العصر');
    expect(beforePrayer('العصر', 10), 'باقي ١٠ دقائق على صلاة العصر');
    expect(beforePrayer('الفجر', 5), 'باقي ٥ دقائق على صلاة الفجر');
    expect(prayerTime(16, 5), '٤:٠٥ م');
    expect(prayerTime(4, 32), '٤:٣٢ ص');
    expect(prayerTime(0, 7), '١٢:٠٧ ص');
    expect(prayerTime(12, 0), '١٢:٠٠ م');
    expect(
      countdown(const Duration(hours: 1, minutes: 23, seconds: 4)),
      'بعد ١:٢٣:٠٤',
    );
    expect(countdown(const Duration(minutes: 5, seconds: 9)), 'بعد ٠:٠٥:٠٩');
    expect(nextLine('العصر'), 'الصلاة القادمة: العصر');
    expect(atClock('٢:٣٨ م'), 'الساعة ٢:٣٨ م');
    expect(minutesLabel(15), '١٥ دقيقة');
    expect(offsetLabel(-3), '−٣');
    expect(offsetLabel(2), '+٢');
    expect(offsetLabel(0), '٠');
    expect(gregorianDate(DateTime(2026, 3, 1)), 'الأحد ١ مارس ٢٠٢٦');
    expect(gregorianDate(DateTime(2026, 11, 26)), 'الخميس ٢٦ نوفمبر ٢٠٢٦');
    expect(kPlaceChange, 'غيّر المكان');
    expect(monthTitle(2026, 2), 'فبراير ٢٠٢٦');
    expect(kPrevMonth, 'الشهر السابق');
    expect(kNextMonth, 'الشهر التالي');
    expect(kNotifySection, 'التنبيهات');
  });
}
