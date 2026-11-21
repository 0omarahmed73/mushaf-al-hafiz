// Feature 011, T053: the search keeps its query, its rows and its place through a rotation and a trip to the background,
// and forgets them when it is closed (spec FR-017, FR-029, Clarifications). The screen runs over the prepared real
// service.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/search/search_screen.dart';
import 'package:mushaf/search/search_service.dart';
import 'package:mushaf/search/search_strings.dart';

import '../support/search_harness.dart';
import '../support/search_quality_harness.dart';

/// More than 100 ayat hold it: a hundred rows, enough to scroll far in both orientations.
const _many = 'ال';

const _portrait = Size(412, 915);
const _landscape = Size(915, 412);

/// The ayah rows that are inside the list's viewport now, in order.
List<String> rowsInView(WidgetTester t) {
  final view = t.getRect(searchList);
  return [
    for (final key in ayahRowsBuilt(t))
      if (t.getRect(skey('ayah-row-$key')).overlaps(view)) key,
  ];
}

Future<void> rotate(WidgetTester t, Size size) async {
  t.view.physicalSize = size;
  await t.pump();
  await t.pump();
}

/// Types [_many] and scrolls the results well into the ayah rows (to the 40th, then a little further so the offset is
/// not the edge of a row).
Future<void> typeAndScroll(WidgetTester t, AyahSearchResult many) async {
  await typeQuery(t, _many);
  await t.scrollUntilVisible(
    skey('ayah-row-${many.hits[40].ref.key}'),
    300,
    scrollable: searchList,
    maxScrolls: 400,
  );
  final position = searchPosition(t);
  position.jumpTo(position.pixels + 37);
  await t.pump();
  expect(position.pixels, greaterThan(1000));
  expect(
    rowsInView(t),
    isNotEmpty,
    reason: 'ayah rows are in view after the scroll',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AyahSearchResult many;
  setUpAll(() async {
    many = (await realAnswers([_many])).values.single;
  });

  test('the query of this file fills the list', () {
    expect(many.hits, hasLength(AyahSearchResult.maxRows));
    expect(many.total, greaterThan(AyahSearchResult.maxRows));
  });

  testWidgets(
    'rotating to landscape and back keeps the query, the rows and the scroll offset',
    (t) async {
      await pumpSearch(t, screen: _portrait);
      await typeAndScroll(t, many);
      final state = t.state(find.byType(SearchScreen));
      final offset = searchPosition(t).pixels;
      final inView = rowsInView(t);
      final heading = kAyahHeading(many.total);

      await rotate(t, _landscape);
      expect(t.takeException(), isNull);
      expect(
        t.state(find.byType(SearchScreen)),
        same(state),
        reason: 'the screen was not built anew',
      );
      expect(fieldText(t), _many);
      expect(
        searchPosition(t).pixels,
        offset,
        reason: 'the offset in landscape',
      );
      expect(rowsInView(t), isNotEmpty);
      expect(
        rowsInView(t),
        everyElement(isIn(many.hits.map((h) => h.ref.key))),
        reason: 'the rows are those of the same answer',
      );
      expect(find.text(kSearchHint), findsNothing);

      await rotate(t, _portrait);
      expect(t.takeException(), isNull);
      expect(fieldText(t), _many);
      expect(
        searchPosition(t).pixels,
        offset,
        reason: 'the offset back in portrait',
      );
      expect(rowsInView(t), inView, reason: 'the same rows are in view again');

      // the heading still says the same total, at the top
      searchPosition(t).jumpTo(0);
      await t.pump();
      await t.scrollUntilVisible(
        ayatHeading,
        300,
        scrollable: searchList,
        maxScrolls: 400,
      );
      expect(
        find.descendant(of: ayatHeading, matching: find.text(heading)),
        findsOneWidget,
      );
    },
  );

  testWidgets('a rotation asks the service nothing new and types nothing', (
    t,
  ) async {
    var asked = 0;
    final service = ScriptedSearchService(
      answerOf: (_) {
        asked++;
        return many;
      },
    );
    await pumpSearch(t, service: service);
    await typeAndScroll(t, many);
    final before = asked;
    expect(before, greaterThan(0));
    await rotate(t, _landscape);
    await rotate(t, _portrait);
    expect(
      asked,
      before,
      reason: 'the answer on screen is kept, not asked for again',
    );
    expect(fieldText(t), _many);
  });

  testWidgets(
    'a trip to the background and back keeps the query, the rows and the scroll offset',
    (t) async {
      await pumpSearch(t);
      await typeAndScroll(t, many);
      final state = t.state(find.byType(SearchScreen));
      final offset = searchPosition(t).pixels;
      final inView = rowsInView(t);

      for (final step in const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        t.binding.handleAppLifecycleStateChanged(step);
        await t.pump();
      }
      addTearDown(
        () =>
            t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      await t.pump(const Duration(seconds: 1));

      expect(t.takeException(), isNull);
      expect(t.state(find.byType(SearchScreen)), same(state));
      expect(fieldText(t), _many);
      expect(searchPosition(t).pixels, offset);
      expect(rowsInView(t), inView);
    },
  );

  testWidgets(
    'closing and opening search again starts empty: no memory of the last query',
    (t) async {
      final run = await pumpSearch(t);
      await typeAndScroll(t, many);

      await closeSearch(t);
      expect(run.popped, isTrue);
      expect(find.byType(SearchScreen), findsNothing);

      await reopenSearch(t, run);
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(fieldText(t), isEmpty);
      expect(find.text(kSearchHint), findsOneWidget);
      expect(searchClear, findsNothing);
      expect(surahsHeading, findsNothing);
      expect(ayatHeading, findsNothing);
      expect(surahRowsBuilt(t), isEmpty);
      expect(ayahRowsBuilt(t), isEmpty);
      expect(searchPosition(t).pixels, 0);

      // and the same text typed again starts at the top
      await typeQuery(t, _many);
      expect(searchPosition(t).pixels, 0);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('choosing a result and opening search again also starts empty', (
    t,
  ) async {
    final run = await pumpSearch(t);
    await typeQuery(t, 'كهف');
    await t.tap(surahRow(18));
    await settleSearch(t);
    expect(run.popped, isTrue);

    await reopenSearch(t, run);
    expect(fieldText(t), isEmpty);
    expect(find.text(kSearchHint), findsOneWidget);
    expect(surahRowsBuilt(t), isEmpty);
  });
}
