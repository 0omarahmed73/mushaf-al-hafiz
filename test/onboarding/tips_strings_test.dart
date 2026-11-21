// The Arabic strings of the first-run tips (feature 008, contracts/ui.md). They are proposals until the owner confirms
// them (task T020, Constitution VI): changing one means the owner must confirm it again, so every one is pinned here.
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/onboarding/tips_strings.dart';

void main() {
  test('the dialog name and the buttons', () {
    expect(kTipsDialogLabel, 'نصائح لاستخدام التطبيق');
    expect(kTipsNext, 'التالي');
    expect(kTipsSkip, 'تخطي');
    expect(kTipsStart, 'ابدأ');
  });

  test('the step counter uses Western digits', () {
    expect(kTipsStepOf(1, 6), 'الخطوة 1 من 6');
    expect(kTipsStepOf(2, 6), 'الخطوة 2 من 6');
    expect(kTipsStepOf(6, 6), 'الخطوة 6 من 6');
  });

  test('step 1: the long press', () {
    expect(kTipLongPressTitle, 'اضغط مطوّلاً على الآية');
    expect(
      kTipLongPressBody,
      'اضغط مطوّلاً على أي كلمة من الآية، فتظهر قائمتها. '
      'منها تفتح تفسير السعدي والترجمة الإنجليزية ومعاني الكلمات، '
      'وتشارك الآية أو الصفحة أو السورة.',
    );
  });

  test('step 2: turning pages and jumping', () {
    expect(kTipTurnPagesTitle, 'التنقل بين الصفحات');
    expect(
      kTipTurnPagesBody,
      'اسحب الصفحة من اليسار إلى اليمين لتنتقل إلى التالية، كما في المصحف الورقي. '
      'اضغط اسم السورة في الأعلى لتفتح الفهرس، أو رقم الصفحة لتنتقل إلى صفحة محددة.',
    );
  });

  test('step 3: the bars and the zoom', () {
    expect(kTipBarsZoomTitle, 'إخفاء الشريطين والتكبير');
    expect(
      kTipBarsZoomBody,
      'اضغط على الصفحة مرة لإخفاء الشريطين العلوي والسفلي، ومرة أخرى لإظهارهما. '
      'ضع إصبعين على الصفحة وباعد بينهما لتكبّرها.',
    );
  });

  test('step 4: the daily wird', () {
    expect(kTipWirdTitle, 'وردك اليومي');
    expect(
      kTipWirdBody,
      'في أعلى الصفحة اسم وردك وزر «ملخص اليوم»؛ اضغطه لترى ما عليك قراءته اليوم، '
      'ثم اضغط «تم» حين تنتهي منه. ومن «أوراد» في الأسفل تضيف أورادًا أخرى.',
    );
  });

  test('step 5: the bookmarks', () {
    expect(kTipBookmarksTitle, 'علاماتك');
    expect(
      kTipBookmarksBody,
      'اضغط أيقونة العلامة تحت رقم الجزء لتعلّم الصفحة، واضغطها مرة أخرى لإزالة العلامة. '
      'وتجد كل علاماتك في «علامات» في الأسفل.',
    );
  });

  test('step 6: the size and the look', () {
    expect(kTipSizeLookTitle, 'الحجم والمظهر');
    expect(
      kTipSizeLookBody,
      'اضغط «القائمة» في الأسفل لتفتح الإعدادات. '
      'غيّر منها حجم الخط، واختر المظهر: «زمردي وذهبي» أو «القارئ الليلي».',
    );
  });
}
