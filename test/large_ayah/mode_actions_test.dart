// The ayah sheet, the tint, the page bookmark and the looks in the large-ayah view (feature 015, User Story 3; FR-014,
// FR-015, FR-016).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ui/ayah_sheet.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/mushaf/page_look.dart';

import '../support/ayah_bookmark_harness.dart' show ayahBookmarkRow;
import '../support/large_ayah_harness.dart';
import '../support/reader_harness.dart';

Finder _word(int id) => find.byKey(ValueKey('lw$id'));

void main() {
  testWidgets('a long press opens the same ayah sheet for that ayah and its page, highlighted until it closes', (
    t,
  ) async {
    await pumpLargeReader(t, startPage: 3, on: true);
    final s = shownLargeScreen(t).screen;
    await t.longPress(_word(s.words.last.id));
    await settleReader(t);
    final sheet = t.widget<AyahSheet>(find.byType(AyahSheet));
    expect(sheet.ref, const AyahRef(2, 6));
    expect(sheet.page, 3);
    expect(ayahBookmarkRow, findsOneWidget);
    expect(shownLargeScreen(t).highlightedWordIds, containsAll(s.words.map((w) => w.id)));
    Navigator.of(t.element(find.byType(AyahSheet))).pop();
    await settleReader(t);
    expect(shownLargeScreen(t).highlightedWordIds, isEmpty);
  });

  testWidgets('a long press on a later part of 2:282 acts on the whole ayah', (t) async {
    await pumpLargeReader(t, startPage: 48, on: true, sizeStep: 3);
    await nextScreen(t);
    final part = shownLargeScreen(t).screen;
    expect(part.part?.number, 2);
    await t.longPress(_word(part.words.first.id));
    await settleReader(t);
    expect(t.widget<AyahSheet>(find.byType(AyahSheet)).ref, const AyahRef(2, 282));
    expect(shownLargeScreen(t).highlightedWordIds, containsAll(part.words.map((w) => w.id)));
    Navigator.of(t.element(find.byType(AyahSheet))).pop();
    await settleReader(t);
  });

  testWidgets('an ayah bookmark is tinted, and not with the tint switch off', (t) async {
    final r = await pumpLargeReader(t, startPage: 3, on: true);
    final first = shownLargeScreen(t).screen.words.first;
    await t.longPress(_word(first.id));
    await settleReader(t);
    await t.tap(ayahBookmarkRow);
    await settleReader(t);
    if (find.byType(AyahSheet).evaluate().isNotEmpty) {
      Navigator.of(t.element(find.byType(AyahSheet))).pop();
      await settleReader(t);
    }
    final ids = shownLargeScreen(t).screen.words.map((w) => w.id).toSet();
    BoxDecoration? deco(int id) => t
        .widgetList<DecoratedBox>(find.ancestor(of: _word(id), matching: find.byType(DecoratedBox)))
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .firstOrNull;
    expect(deco(ids.first)?.color, PageLook.screen.bookmarkTint);
    await t.runAsync(() => r.tint.set(false));
    await settleReader(t);
    expect(deco(ids.first)?.color, isNot(PageLook.screen.bookmarkTint));
  });

  testWidgets('the page bookmark icon acts on the screen\'s page', (t) async {
    final r = await pumpLargeReader(t, startPage: 3, on: true);
    var guard = 0;
    while (shownLargeScreen(t).screen.page != 4 && guard++ < 20) {
      await nextScreen(t);
    }
    await t.tap(find.byKey(const ValueKey('bookmark-button')));
    await settleReader(t);
    final marks = (await t.runAsync(r.repo.bookmarkRows))!;
    expect(marks.where((b) => b.surah == null).map((b) => b.page), [4]);
  });

  testWidgets('the Night look applies to the view', (t) async {
    await pumpLargeReader(t, startPage: 3, on: true, look: LookChoice.night);
    expect(shownLargeScreen(t).look, PageLook.night);
    final w = shownLargeScreen(t).screen.words.first;
    expect(t.widget<Text>(_word(w.id)).style!.color, PageLook.night.ink);
  });
}
