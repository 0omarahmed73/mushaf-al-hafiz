// Every Arabic string of the first-run tips (feature 008, contracts/ui.md).
//
// These are PROPOSALS until the owner confirms them word by word (task T020, Constitution VI). They were written in
// Arabic for this feature, not translated, and every name used inside a sentence is a name the app already shows
// («علامات», «أوراد», «القائمة», «ملخص اليوم», «تم», «زمردي وذهبي», «القارئ الليلي»). Changing one means the owner must
// confirm it again: test/onboarding/tips_strings_test.dart pins each of them, and
// test/onboarding/tips_reader_truth_test.dart checks on the real reader that what each step says exists.
//
// A step's body is at most two sentences and holds no Quran text (Constitution I). N is a number written with Western
// digits, like the page number the Mushaf page draws.

/// The dialog's name for a screen reader.
const String kTipsDialogLabel = 'نصائح لاستخدام التطبيق';

/// «التالي» on every step but the last.
const String kTipsNext = 'التالي';

/// «تخطي» on every step but the last.
const String kTipsSkip = 'تخطي';

/// The only button of the last step.
const String kTipsStart = 'ابدأ';

/// What a screen reader hears as the current step: «الخطوة 2 من 6».
String kTipsStepOf(int step, int total) => 'الخطوة $step من $total';

/// Step 1: a long press on a word of an ayah opens the ayah's menu (reader_screen.dart `_openAyahMenu`; the menu's rows
/// are «التفسير» (تفسير السعدي), «الترجمة» (English, Saheeh International), «معاني الكلمات» and the three shares).
const String kTipLongPressTitle = 'اضغط مطوّلاً على الآية';
const String kTipLongPressBody =
    'اضغط مطوّلاً على أي كلمة من الآية، فتظهر قائمتها. '
    'منها تفتح تفسير السعدي والترجمة الإنجليزية ومعاني الكلمات، '
    'وتشارك الآية أو الصفحة أو السورة.';

/// Step 2: the page turns with a swipe from left to right (Constitution VI); the surah name opens the index; the page
/// number opens «الانتقال إلى صفحة».
const String kTipTurnPagesTitle = 'التنقل بين الصفحات';
const String kTipTurnPagesBody =
    'اسحب الصفحة من اليسار إلى اليمين لتنتقل إلى التالية، كما في المصحف الورقي. '
    'اضغط اسم السورة في الأعلى لتفتح الفهرس، أو رقم الصفحة لتنتقل إلى صفحة محددة.';

/// Step 3: a tap on the page hides and shows both bars; two fingers apart zoom the page (1x to 3x).
const String kTipBarsZoomTitle = 'إخفاء الشريطين والتكبير';
const String kTipBarsZoomBody =
    'اضغط على الصفحة مرة لإخفاء الشريطين العلوي والسفلي، ومرة أخرى لإظهارهما. '
    'ضع إصبعين على الصفحة وباعد بينهما لتكبّرها.';

/// Step 4: the wird's name and «ملخص اليوم» at the top; «تم» in today's card; «أوراد» at the bottom adds wirds.
const String kTipWirdTitle = 'وردك اليومي';
const String kTipWirdBody =
    'في أعلى الصفحة اسم وردك وزر «ملخص اليوم»؛ اضغطه لترى ما عليك قراءته اليوم، '
    'ثم اضغط «تم» حين تنتهي منه. ومن «أوراد» في الأسفل تضيف أورادًا أخرى.';

/// Step 5: the bookmark icon under the juz text (feature 006) toggles a bookmark on the page; «علامات» lists them.
const String kTipBookmarksTitle = 'علاماتك';
const String kTipBookmarksBody =
    'اضغط أيقونة العلامة تحت رقم الجزء لتعلّم الصفحة، واضغطها مرة أخرى لإزالة العلامة. '
    'وتجد كل علاماتك في «علامات» في الأسفل.';

/// Step 6: «القائمة» opens Settings with «حجم الخط» and «المظهر».
const String kTipSizeLookTitle = 'الحجم والمظهر';
const String kTipSizeLookBody =
    'اضغط «القائمة» في الأسفل لتفتح الإعدادات. '
    'غيّر منها حجم الخط، واختر المظهر: «زمردي وذهبي» أو «القارئ الليلي».';
