// The large-ayah view in the reader (feature 015, User Story 1; constitution 2.2.0 Principle II; FR-005, FR-011, FR-013,
// FR-017; SC-003).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/khatm/khatm_dua_screen.dart';
import 'package:mushaf/large_ayah/large_ayah_screen.dart';
import 'package:mushaf/large_ayah/large_ayah_strings.dart';
import 'package:mushaf/mushaf/mushaf_page.dart';

import '../support/large_ayah_harness.dart';
import '../support/reader_harness.dart';

Finder get _back => find.byKey(const ValueKey('large-back'));

void main() {
  testWidgets('off (a first install): the reader shows the Mushaf page as before', (t) async {
    await pumpLargeReader(t);
    expect(find.byType(MushafPage), findsOneWidget);
    expect(find.byType(LargeAyahScreen), findsNothing);
    expect(_back, findsNothing);
  });

  testWidgets('on at start: the app opens in the view, at the first ayah of the position\'s page', (t) async {
    await pumpLargeReader(t, on: true);
    expect(find.byType(MushafPage), findsNothing);
    expect(largeHeader(t), 'آل عمران ١ · صفحة ٥٠');
    expect(find.text('سورة آل عمران'), findsOneWidget);
    expect(find.text(kBasmallah), findsOneWidget);
    expect(_back, findsOneWidget);
    expect(find.descendant(of: _back, matching: find.text(LargeAyahStrings.backToMushaf)), findsOneWidget);
    expect(t.getSize(_back).height, greaterThanOrEqualTo(48));
  });

  testWidgets('swiping reads on; «المصحف» turns it off and shows the Mushaf page of the screen', (t) async {
    final r = await pumpLargeReader(t, on: true);
    var guard = 0;
    while (!largeHeader(t).contains('صفحة ٥١') && guard++ < 30) {
      await nextScreen(t);
    }
    expect(largeHeader(t), contains('صفحة ٥١'));
    await t.tap(_back);
    await settleReader(t);
    expect(r.settings.on, isFalse);
    expect(find.byType(LargeAyahScreen), findsNothing);
    final page = t.widget<MushafPage>(find.byType(MushafPage));
    expect(page.data.page, 51);
    expect(await r.wirdPage(t), 51, reason: 'inside the active wird the position followed the screens');
  });

  testWidgets('turned on from Settings (the menu, then the switch): two taps, back in the reader in the view', (
    t,
  ) async {
    final r = await pumpLargeReader(t);
    await t.tap(find.byKey(const ValueKey('open-settings')));
    await settleReader(t);
    await t.tap(find.byKey(const ValueKey('large-ayah-switch')));
    await settleReader(t);
    expect(r.settings.on, isTrue);
    expect(find.byType(LargeAyahScreen), findsOneWidget);
    expect(largeHeader(t), 'آل عمران ١ · صفحة ٥٠');
  });

  testWidgets('the Mushaf page is the same with the view off', (t) async {
    await pumpLargeReader(t, startPage: 3);
    final page = t.widget<MushafPage>(find.byType(MushafPage));
    expect(page.data.page, 3);
    expect(page.tintedWordIds, isEmpty);
  });

  testWidgets('past the last screen of page 604 a forward swipe opens the khatm supplication', (t) async {
    await pumpLargeReader(t, startPage: 604, on: true, count: 3);
    var guard = 0;
    while (find.byType(KhatmDuaScreen).evaluate().isEmpty && guard++ < 15) {
      await nextScreen(t);
    }
    expect(find.byType(KhatmDuaScreen), findsOneWidget);
  });
}
