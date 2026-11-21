// Helpers of the reader tests of feature 011 (window [R4], T041-T043). The search screen reaches the reader through the
// index route (T045): the reader pushes the index and the route is popped with a value. These tests do the popping
// themselves, so the reader can be tested before the search screen can be opened.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/index_screen.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_page_card.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';

import 'reader_harness.dart';

Finder keyed(String k) => find.byKey(ValueKey(k));

/// The number the reader's bottom line shows.
String shownPage(WidgetTester t) =>
    t.widget<Text>(find.byKey(const ValueKey('page-number'))).data!;

/// The colour of the page's highlight in the default look (Emerald & Gold).
const Color kHighlight = Color(0x55FFC107);

/// The pages of the page files these reader tests can ask for: the start pages, the targets and what the reader warms around
/// them after a jump or a swipe.
const List<(int, int)> kReaderTestPages = [(1, 10), (30, 60), (285, 300)];

/// Reads those pages in real time, outside any test's fake-async zone: call it from `setUpAll`. A page asset first read by the
/// reader inside a test (it warms the pages around the shown one after a swipe) leaves a Future in `rootBundle` that only that
/// test's fake clock can complete, and a later `loadAround` that awaits it never returns.
Future<void> preloadReaderPages() async {
  final mushaf = MushafRepository(rootBundle);
  await mushaf.loadMeta();
  for (final (from, to) in kReaderTestPages) {
    for (var p = from; p <= to; p++) {
      await mushaf.loadPage(p);
    }
  }
}

/// Reads [pages] in real time first: a page asset first read inside the fake-async zone of a widget test leaves a Future that
/// can never complete (the remark of `pumpReader` in test/mushaf/reader_screen_test.dart).
Future<void> loadPages(WidgetTester t, Iterable<int> pages) async {
  await t.runAsync(() async {
    final mushaf = MushafRepository(rootBundle);
    await mushaf.loadMeta();
    for (final p in pages) {
      await mushaf.loadPage(p);
    }
  });
}

/// Reads the pages around [page] (three on each side: the ones the reader warms after a jump) in real time.
Future<void> loadAround(WidgetTester t, int page) => loadPages(t, [
  for (var p = page - 3; p <= page + 3; p++)
    if (p >= 1 && p <= MushafMeta.pageCount) p,
]);

/// The data of [page] from the real asset.
Future<PageData> realPage(WidgetTester t, int page) async =>
    (await t.runAsync(() => MushafRepository(rootBundle).loadPage(page)))!;

/// The ids of the words of [ref] that are on [page] (what the reader must highlight).
Future<Set<int>> idsOn(WidgetTester t, int page, AyahRef ref) async =>
    wordIdsOfAyah(await realPage(t, page), ref);

/// Opens the index from the surah name in the top bar and pops its route with [value], as the search screen will, then lets
/// the reader settle.
Future<void> popIndexWith(WidgetTester t, Object value) async {
  await t.tap(keyed('open-index'));
  await settleReader(t);
  Navigator.of(t.element(find.byType(IndexScreen))).pop(value);
  await settleReader(t);
}

/// What the card of the shown [page] was given to highlight; null when no card of that page is on stage.
Set<int>? cardHighlight(WidgetTester t, int page) {
  for (final card in t.widgetList<MushafPageCard>(
    find.byType(MushafPageCard),
  )) {
    if (card.data?.page == page) return card.highlightedWordIds;
  }
  return null;
}

/// How many boxes of the page are drawn in the highlight colour.
int highlightedBoxes(WidgetTester t) => t
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .where(
      (d) =>
          d.decoration is BoxDecoration &&
          (d.decoration as BoxDecoration).color == kHighlight,
    )
    .length;
