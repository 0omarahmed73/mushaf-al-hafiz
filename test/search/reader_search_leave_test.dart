// Feature 011 T046, a sweep (test-only): searching never moves the wird or the place until a result is chosen. With a wird at
// page 50, opening search from the index and leaving it with back changes none of the six things (the page, the zoom, whether
// the bars are shown, the wird's position, the saved last viewed page, the settings table) and no row of any table; a result
// chosen on page 300 shows it in browse mode with the wird still on 50 (spec User Story 4 scenarios 1-2, FR-003, FR-015,
// FR-016, FR-017, SC-007).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/index_screen.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/search/search_screen.dart';

import '../support/reader_harness.dart';
import '../support/reader_search_harness.dart';
import '../support/search_harness.dart';

const _makeMine = 'اجعلها موضعي';
const _openSearch = ValueKey('open-search');

/// 18:60, an ayah of page 300.
const _onPage300 = AyahRef(18, 60);

/// Every row of every table of the database, by table name (the rows in rowid order, each as its column map).
Future<Map<String, List<String>>> _dump(WidgetTester t, SearchReader r) async {
  return (await t.runAsync(() async {
    final tables = await r.db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();
    final out = <String, List<String>>{};
    for (final table in tables) {
      final name = table.data['name'] as String;
      final rows = await r.db
          .customSelect('SELECT * FROM "$name" ORDER BY rowid')
          .get();
      out[name] = [for (final row in rows) row.data.toString()];
    }
    return out;
  }))!;
}

/// The zoom and pan of every page on stage.
List<String> _zoom(WidgetTester t) => [
  for (final v in t.widgetList<InteractiveViewer>(
    find.byType(InteractiveViewer),
  ))
    v.transformationController!.value.storage
        .map((x) => x.toStringAsFixed(3))
        .join(','),
];

/// The six things of SC-007 (and the page's rectangles, which hold the zoom as it is drawn).
Future<Map<String, Object?>> _six(WidgetTester t, SearchReader r) async {
  final wird = await t.runAsync(() => r.repo.activeWird());
  final dump = await _dump(t, r);
  return {
    '1 page': shownPage(t),
    '2 zoom': _zoom(t),
    '3 bars': [
      keyed('top-bar').evaluate().length,
      keyed('bottom-bar').evaluate().length,
    ],
    '4 wird position': (wird!.id, wird.currentPage),
    '5 last viewed page': await t.runAsync(r.repo.lastViewedPage),
    '6 settings table': dump['settings'],
    'browse banner': find.text(_makeMine).evaluate().length,
    'highlighted': highlightedBoxes(t),
  };
}

Future<void> _openSearchFromReader(WidgetTester t) async {
  await t.tap(keyed('open-index'));
  await settleReader(t);
  await t.tap(find.byKey(_openSearch));
  await settleReader(t);
  expect(find.byType(SearchScreen), findsOneWidget);
}

/// Back out of the search, then out of the index.
Future<void> _backToReader(WidgetTester t) async {
  await t.binding.handlePopRoute();
  await settleReader(t);
  expect(find.byType(SearchScreen), findsNothing);
  expect(find.byType(IndexScreen), findsOneWidget);
  await t.binding.handlePopRoute();
  await settleReader(t);
  expect(find.byType(IndexScreen), findsNothing);
  expect(find.byType(ReaderScreen), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await preloadReaderPages();
    await realIndex();
  });

  group(
    'a wird at page 50: search opened from the index and closed with back',
    () {
      testWidgets('without a query: 6 of 6 unchanged and no row of any table', (
        t,
      ) async {
        final reader = await pumpSearchReader(t, startPage: 50);
        final six = await _six(t, reader);
        final rows = await _dump(t, reader);
        expect(six['1 page'], '50');
        expect(six['3 bars'], [1, 1]);
        expect(six['4 wird position'].toString(), contains('50'));
        expect(rows['settings'], isNotEmpty);
        expect(rows['wirds'], isNotEmpty);

        await _openSearchFromReader(t);
        await _backToReader(t);

        expect(await _six(t, reader), six);
        expect(await _dump(t, reader), rows);
      });

      testWidgets(
        'with a query typed: 6 of 6 unchanged and no row of any table',
        (t) async {
          final reader = await pumpSearchReader(t, startPage: 50);
          final six = await _six(t, reader);
          final rows = await _dump(t, reader);

          await _openSearchFromReader(t);
          await typeQuery(t, 'مجمع البحرين');
          expect(
            find.byKey(ValueKey('ayah-row-${_onPage300.key}')),
            findsOneWidget,
            reason: 'a result was on the screen and was not chosen',
          );
          await _backToReader(t);

          expect(await _six(t, reader), six);
          expect(await _dump(t, reader), rows);
        },
      );

      testWidgets(
        'zoomed in: the zoom is the same after search is opened and closed',
        (t) async {
          final reader = await pumpSearchReader(t, startPage: 50);
          final unzoomed = _zoom(t);
          final centre = t.getCenter(find.byType(PageView));
          final a = await t.startGesture(centre - const Offset(20, 0));
          final b = await t.startGesture(centre + const Offset(20, 0));
          await a.moveBy(const Offset(-60, 0));
          await b.moveBy(const Offset(60, 0));
          await t.pump(const Duration(milliseconds: 50));
          await a.up();
          await b.up();
          await settleReader(t);
          expect(
            _zoom(t),
            isNot(unzoomed),
            reason: 'the pinch zoomed the page',
          );
          if (keyed('top-bar').evaluate().isEmpty) {
            // the bars are needed to reach the index: bring them back with a tap on the page
            await t.tapAt(centre);
            await settleReader(t);
          }
          final six = await _six(t, reader);
          final rows = await _dump(t, reader);
          expect(six['3 bars'], [1, 1]);

          await _openSearchFromReader(t);
          await typeQuery(t, 'كهف');
          await _backToReader(t);

          expect(await _six(t, reader), six);
          expect(await _dump(t, reader), rows);
        },
      );

      testWidgets(
        'typing, scrolling the results and leaving changes no table (every row before and after)',
        (t) async {
          final reader = await pumpSearchReader(t, startPage: 50);
          final six = await _six(t, reader);
          final rows = await _dump(t, reader);

          await _openSearchFromReader(t);
          for (final query in ['ق', 'كهف', 'قل هو الله احد', 'ال']) {
            await typeQuery(t, query);
            expect(
              await _dump(t, reader),
              rows,
              reason: 'after typing «$query»',
            );
          }
          // «ال»: 100 rows and the more-line; scroll them down and up again.
          final list = find.byKey(const ValueKey('search-results'));
          final scrollable = t.state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)).first,
          );
          for (var i = 0; i < 6; i++) {
            await t.drag(list, const Offset(0, -500));
            await t.pump(const Duration(milliseconds: 100));
          }
          expect(scrollable.position.pixels, greaterThan(1000));
          await t.drag(list, const Offset(0, 300));
          await t.pump(const Duration(milliseconds: 100));
          expect(await _dump(t, reader), rows, reason: 'after scrolling');
          await typeQuery(t, '');
          expect(await _dump(t, reader), rows, reason: 'after clearing');

          await _backToReader(t);

          expect(await _dump(t, reader), rows);
          expect(await _six(t, reader), six);
        },
      );
    },
  );

  testWidgets(
    'a result chosen on page 300 shows it in browse mode, the wird still on 50 and the last viewed page 300',
    (t) async {
      final reader = await pumpSearchReader(t, startPage: 50, pages: [300]);
      final before = await _six(t, reader);
      final rows = await _dump(t, reader);
      final ids = await idsOn(t, 300, _onPage300);
      expect(ids, isNotEmpty);

      await _openSearchFromReader(t);
      await typeQuery(t, 'مجمع البحرين');
      await t.tap(find.byKey(ValueKey('ayah-row-${_onPage300.key}')));
      await settleReader(t);

      expect(find.byType(SearchScreen), findsNothing);
      expect(find.byType(IndexScreen), findsNothing);
      expect(shownPage(t), '300');
      expect(find.text(_makeMine), findsOneWidget, reason: 'browse mode');
      expect(cardHighlight(t, 300), ids);
      final after = await _six(t, reader);
      expect(after['4 wird position'], before['4 wird position']);
      expect(after['5 last viewed page'], 300);
      expect(after['2 zoom'], before['2 zoom']);
      expect(after['3 bars'], before['3 bars']);
      // The database: the saved last viewed page is the one row that was written (FR-015); every other row is equal.
      final now = await _dump(t, reader);
      expect(now.keys.toSet(), rows.keys.toSet());
      for (final table in rows.keys) {
        if (table == 'settings') continue;
        expect(now[table], rows[table], reason: 'table $table');
      }
      List<String> others(List<String> settings) => [
        for (final row in settings)
          if (!row.contains('lastViewedPage')) row,
      ];
      expect(others(now['settings']!), others(rows['settings']!));
      final written = now['settings']!.toSet().difference(
        rows['settings']!.toSet(),
      );
      expect(written, hasLength(1));
      expect(written.single, contains('lastViewedPage'));
      expect(written.single, contains('300'));
    },
  );
}
