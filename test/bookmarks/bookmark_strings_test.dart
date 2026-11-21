// The Arabic strings of the reader's bookmark icon (feature 006). They are proposals until the owner confirms them
// (task T015, Constitution VI): changing one means the owner must confirm it again.
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/mushaf/bookmark_strings.dart';

void main() {
  test(
    'the tooltip and label name the action and the page (Western digits)',
    () {
      expect(kBookmarkAdd(1), 'إضافة علامة للصفحة 1');
      expect(kBookmarkAdd(604), 'إضافة علامة للصفحة 604');
      expect(kBookmarkRemove(1), 'إزالة العلامة من الصفحة 1');
      expect(kBookmarkRemove(604), 'إزالة العلامة من الصفحة 604');
    },
  );

  test('the screen reader hears the state', () {
    expect(kBookmarkStateOn, 'عليها علامة');
    expect(kBookmarkStateOff, 'ليس عليها علامة');
  });

  test('the two messages and the undo button', () {
    expect(kBookmarkAdded(50), 'تمت إضافة علامة للصفحة 50');
    expect(kBookmarkRemoved(50), 'تمت إزالة العلامة من الصفحة 50');
    expect(kBookmarkUndo, 'تراجع');
  });

  test('the add text is the one the «علامات» sheet already uses', () {
    // test/wirds/bookmarks_ui_test.dart expects «إضافة علامة للصفحة 1» on the sheet's button.
    expect(kBookmarkAdd(1), 'إضافة علامة للصفحة 1');
  });
}
