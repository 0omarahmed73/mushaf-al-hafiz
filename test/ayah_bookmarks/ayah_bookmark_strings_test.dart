// Every Arabic string of the ayah bookmark (feature 013, the spec's Assumptions table). They are PROPOSALS until the owner
// confirms them word by word (task T048, Constitution VI); «ملاحظة للآية» is the owner's own wording. Changing one means
// changing this test first and asking the owner again.
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/mushaf/ayah_bookmark_strings.dart';
import 'package:mushaf/mushaf/bookmark_strings.dart';

void main() {
  const surah = 'البقرة';
  const ayah = 282;
  const page = 48;

  test(
    'the bookmark row: its two labels and the state a screen reader hears',
    () {
      expect(kAyahBookmarkAddLabel, 'إضافة علامة على الآية');
      expect(kAyahBookmarkRemoveLabel, 'إزالة العلامة من الآية');
      expect(kAyahStateOff, 'ليس عليها علامة');
      expect(kAyahStateOn, 'عليها علامة');
      // The same words as the page icon of feature 006.
      expect(kAyahStateOn, kBookmarkStateOn);
      expect(kAyahStateOff, kBookmarkStateOff);
    },
  );

  test('the two messages of the bookmark row, and «تراجع» of feature 006', () {
    expect(
      kAyahBookmarkAdded(surah, ayah),
      'تمت إضافة علامة على سورة البقرة · آية 282',
    );
    expect(
      kAyahBookmarkRemoved(surah, ayah),
      'تمت إزالة العلامة من سورة البقرة · آية 282',
    );
    expect(kBookmarkUndo, 'تراجع');
  });

  test('the note row', () {
    expect(kAyahNoteLabel, 'ملاحظة للآية');
    expect(kAyahNoteHas, 'عليها ملاحظة');
    expect(kAyahNoteNone, 'ليس عليها ملاحظة');
  });

  test('the note field', () {
    expect(kAyahNoteTitle(surah, ayah), 'ملاحظة على سورة البقرة · آية 282');
    expect(kAyahNoteField, 'الملاحظة');
    expect(kAyahNoteHintNew, 'ستُضاف علامة على الآية مع الملاحظة');
    expect(
      kAyahNoteHintExisting,
      'اترك الحقل فارغًا لإزالة الملاحظة وإبقاء العلامة',
    );
    expect(kAyahNoteCancel, 'إلغاء');
    expect(kAyahNoteSave, 'حفظ');
    expect(kAyahNoteFailed, 'تعذّر الحفظ، حاول مرة أخرى');
  });

  test('the three messages of the note', () {
    expect(
      kAyahNoteCreated(surah, ayah),
      'تمت إضافة علامة مع ملاحظة على سورة البقرة · آية 282',
    );
    expect(
      kAyahNoteSaved(surah, ayah),
      'تم حفظ الملاحظة على سورة البقرة · آية 282',
    );
    expect(
      kAyahNoteRemoved(surah, ayah),
      'تمت إزالة الملاحظة من سورة البقرة · آية 282',
    );
  });

  test('the list row', () {
    expect(kAyahRowTitle(surah, ayah), 'سورة البقرة · آية 282');
    expect(kAyahRowPage(page), 'ص 48');
    expect(kAyahRowWord, 'آية');
    expect(kAyahOwnerGeneral, 'عامة');
    expect(
      kAyahRowLabel(surah, ayah, page, 'الورد اليومي'),
      'علامة على سورة البقرة آية 282، صفحة 48، الورد اليومي',
    );
    expect(
      kAyahRowLabel(surah, ayah, page, kAyahOwnerGeneral),
      'علامة على سورة البقرة آية 282، صفحة 48، عامة',
    );
    // The title and the label carry the word «آية», so the row is told apart without colour.
    expect(kAyahRowTitle(surah, ayah), contains(kAyahRowWord));
    expect(
      kAyahRowLabel(surah, ayah, page, kAyahOwnerGeneral),
      contains(kAyahRowWord),
    );
  });

  test('the Settings switch', () {
    expect(kAyahTintTitle, 'تظليل الآيات التي عليها علامة');
    expect(kAyahTintSubtitle, 'ظلّ خفيف خلف كل آية عليها علامة في صفحة المصحف');
  });

  test('numbers are Western digits, as the page number', () {
    expect(kAyahBookmarkAdded('الفاتحة', 1), endsWith('آية 1'));
    expect(kAyahRowTitle('الناس', 6), 'سورة الناس · آية 6');
    expect(kAyahRowPage(604), 'ص 604');
  });
}
