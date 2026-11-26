// Every Arabic string of prayer times (feature 014, specs/014-prayer-times/contracts/ui.md).
//
// These are PROPOSALS until the owner confirms them (Principle VI, task T041). Changing one means changing
// test/prayer/prayer_strings_test.dart first. Digits are Arabic-Indic, like the large-ayah header.

const String kPrayerBarLabel = 'مواقيت';
const String kPrayerTitle = 'مواقيت الصلاة';
const String kPrayerIntro =
    'اعرف مواعيد الصلاة في مكانك، وتنبيه عند كل صلاة. كل ده بيتحسب على موبايلك من غير إنترنت.';
const String kPrayerEnable = 'تشغيل مواقيت الصلاة';
const String kPrayerDisable = 'إيقاف مواقيت الصلاة';

const String kPlaceLocate = 'حدد موقعي';
const String kPlaceList = 'اختار المدينة من القائمة';
const String kPlaceSearch = 'ابحث عن مدينتك';
const String kPlaceFailed = 'مقدرناش نحدد موقعك. اختار مدينتك من القائمة.';
const String kOpenSettings = 'افتح الإعدادات';
const String kApprox = 'تقريبًا';
const String kPlaceChange = 'غيّر المكان';

const String kNextPrayer = 'الصلاة القادمة';
const String kNextMark = 'القادمة';
const String kExactOff = 'التنبيهات ممكن تتأخر كام دقيقة.';
const String kExactAllow = 'اسمح بالتوقيت الدقيق';
const String kNotifOff = 'الإشعارات مقفولة للتطبيق.';
const String kZoneDiffers = 'توقيت موبايلك غير توقيت المكان ده.';
const String kHighLat = 'في المكان ده الفجر أو العشاء بيتحسب بطريقة تقريبية.';

const String kMonthTable = 'جدول الشهر';
const String kAdjust = 'ضبط المواقيت';
const String kTest = 'جرّب التنبيه';
const String kTestBody = 'كده التنبيه شغال.';
const String kBattery = 'لو التنبيه مبيوصلش';
const String kBatteryGuide =
    'بعض الموبايلات (زي سامسونج وشاومي) بتوقف التطبيقات في الخلفية. من إعدادات الموبايل افتح التطبيق، '
    'وخلي استخدام البطارية «غير مقيد»، وسيبه يشتغل في الخلفية.';

const String kMethod = 'طريقة الحساب';
const String kMethodAuto = 'تلقائي (حسب البلد)';
const String kAsr = 'العصر';
const String kAsrStandard = 'الجمهور';
const String kAsrHanafi = 'الحنفي';
const String kOffsets = 'تعديل بالدقايق';
const String kNotifySound = 'بصوت';
const String kNotifySilent = 'صامت';
const String kNotifyOff = 'بدون';
const String kBefore = 'تذكير قبلها';
const String kBeforeOff = 'لا';

const String kChannelSound = 'تنبيه الصلاة';
const String kChannelSilent = 'تنبيه الصلاة (صامت)';
const String kChannelBefore = 'تذكير قبل الصلاة';
const String kHijriSuffix = 'هـ';

/// Fajr, sunrise, Dhuhr, Asr, Maghrib, Isha: the order of `Prayer.values`.
const List<String> kPrayerNames = [
  'الفجر',
  'الشروق',
  'الظهر',
  'العصر',
  'المغرب',
  'العشاء',
];

/// The methods a reader can choose, by the name of `adhan_dart`'s `CalculationMethod`.
const Map<String, String> kMethodNames = {
  'egyptian': 'الهيئة المصرية العامة للمساحة',
  'ummAlQura': 'أم القرى (مكة)',
  'muslimWorldLeague': 'رابطة العالم الإسلامي',
  'karachi': 'جامعة العلوم الإسلامية (كراتشي)',
  'dubai': 'دبي',
  'kuwait': 'الكويت',
  'qatar': 'قطر',
  'morocco': 'المغرب',
  'turkiye': 'تركيا (ديانت)',
  'northAmerica': 'أمريكا الشمالية (إسنا)',
};

/// [n] in Arabic-Indic digits.
String indic(int n) => String.fromCharCodes(
  '$n'.codeUnits.map((c) => c >= 0x30 && c <= 0x39 ? 0x0660 + c - 0x30 : c),
);

String _two(int n) => indic(n).padLeft(2, '٠');

String atPrayer(String prayer) => 'حان الآن موعد صلاة $prayer';
String beforePrayer(String prayer, int minutes) =>
    'باقي ${indic(minutes)} دقائق على صلاة $prayer';
String nextLine(String prayer) => '$kNextPrayer: $prayer';

/// The next prayer's time under its name in the day view's hero (design A).
String atClock(String time) => 'الساعة $time';
String minutesLabel(int minutes) => '${indic(minutes)} دقيقة';

/// A local time on the 12-hour clock with «ص» before noon and «م» from noon: 16:05 is «٤:٠٥ م».
String prayerTime(int hour, int minute) {
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '${indic(h)}:${_two(minute)} ${hour < 12 ? 'ص' : 'م'}';
}

/// Time left to the next prayer: «بعد ١:٢٣:٠٤».
String countdown(Duration left) {
  final s = left.inSeconds < 0 ? 0 : left.inSeconds;
  return 'بعد ${indic(s ~/ 3600)}:${_two(s % 3600 ~/ 60)}:${_two(s % 60)}';
}

/// A minute offset with its sign: «−٣», «+٢», «٠».
String offsetLabel(int minutes) => minutes == 0
    ? indic(0)
    : '${minutes < 0 ? '−' : '+'}${indic(minutes.abs())}';

const List<String> _weekdays = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];
const List<String> _months = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

/// «الأحد ١ مارس ٢٠٢٦».
String gregorianDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${indic(d.day)} ${_months[d.month - 1]} ${indic(d.year)}';

/// «فبراير ٢٠٢٦».
String monthTitle(int year, int month) =>
    '${_months[month - 1]} ${indic(year)}';

const String kPrevMonth = 'الشهر السابق';
const String kNextMonth = 'الشهر التالي';
const String kNotifySection = 'التنبيهات';

/// A month's name alone, for the month chips (design C).
String monthName(int month) => _months[month - 1];

/// A weekday's name, for a day's badge in the month table.
String weekdayName(DateTime d) => _weekdays[d.weekday - 1];

/// The mark before today's date in the month table.
const String kToday = 'النهارده';

/// A closed day in the month table: its Fajr and Maghrib, the two times most looked up.
String monthSummary(String fajr, String maghrib) =>
    '${kPrayerNames[0]} $fajr · ${kPrayerNames[4]} $maghrib';
