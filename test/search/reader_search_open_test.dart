// Feature 011 T041 (window [R4] of reader_screen.dart): the reader receives what the index route pops. A plain int is a jump
// exactly as today; an AyahTarget shows its page in browse mode (or leaves wird mode alone when the page is the one shown)
// with the ayah highlighted the way the long press highlights it (spec FR-013, FR-015, FR-016, US4; research D4).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/mushaf_page_card.dart';
import 'package:mushaf/reminders/reminder_scheduler.dart';
import 'package:mushaf/search/ayah_target.dart';

import '../support/khatm_harness.dart' show pumpBrowseReader, untouched;
import '../support/reader_harness.dart';
import '../support/reader_search_harness.dart';

const _kursi = AyahRef(2, 255);
const _debt = AyahRef(2, 282);
const _makeMine = 'اجعلها موضعي';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(preloadReaderPages);

  test('an AyahTarget holds the ayah and the page where it begins', () {
    const target = AyahTarget(_kursi, 42);
    expect(target.ref, _kursi);
    expect(target.page, 42);
  });

  group('the reader follows a wird (page 50)', () {
    testWidgets(
      'a target on another page shows that page in browse mode, highlighted, and moves nothing of the wird',
      (t) async {
        final reader = await pumpSizedReader(t, startPage: 50);
        final before = await untouched(t, reader.repo);
        await loadAround(t, 42);
        final ids = await idsOn(t, 42, _kursi);
        final pageWords = (await realPage(
          t,
          42,
        )).lines.fold(0, (n, line) => n + line.words.length);
        expect(ids, isNotEmpty);
        expect(
          ids.length,
          lessThan(pageWords),
          reason: 'only the words of the ayah, not the page',
        );
        expect(find.text(_makeMine), findsNothing);

        await popIndexWith(t, const AyahTarget(_kursi, 42));

        expect(shownPage(t), '42');
        expect(find.text(_makeMine), findsOneWidget, reason: 'browse mode');
        expect(cardHighlight(t, 42), ids);
        expect(highlightedBoxes(t), ids.length);
        final wird = await t.runAsync(() => reader.repo.activeWird());
        expect(wird!.currentPage, 50, reason: 'a result moves no wird');
        expect(await untouched(t, reader.repo), before);
        expect(
          await t.runAsync(reader.repo.lastViewedPage),
          42,
          reason: 'the saved last viewed page is the page shown (FR-015)',
        );
      },
    );

    testWidgets('the reminders the app plans are the same after a result', (
      t,
    ) async {
      final reader = await pumpSizedReader(t, startPage: 50);
      final now = DateTime(2026, 11, 21, 6);
      final before = (await t.runAsync(
        () => buildReminderPlan(reader.repo, now),
      ))!;
      expect(before, isNotEmpty, reason: 'the default wird has a reminder');
      await loadAround(t, 42);

      await popIndexWith(t, const AyahTarget(_kursi, 42));

      expect(shownPage(t), '42');
      final after = (await t.runAsync(
        () => buildReminderPlan(reader.repo, now),
      ))!;
      expect(after, before);
    });

    testWidgets(
      'a target on the page already shown stays in wird mode: only the highlight appears',
      (t) async {
        final reader = await pumpSizedReader(t, startPage: 42);
        final ids = await idsOn(t, 42, _kursi);
        final lastViewed = await t.runAsync(reader.repo.lastViewedPage);
        expect(cardHighlight(t, 42), isEmpty);

        await popIndexWith(t, const AyahTarget(_kursi, 42));

        expect(shownPage(t), '42');
        expect(find.text(_makeMine), findsNothing, reason: 'no browse banner');
        expect(cardHighlight(t, 42), ids);
        expect(highlightedBoxes(t), ids.length);
        final wird = await t.runAsync(() => reader.repo.activeWird());
        expect(wird!.currentPage, 42);
        expect(
          await t.runAsync(reader.repo.lastViewedPage),
          lastViewed,
          reason: 'nothing was jumped to, so nothing was saved',
        );
        // Still in wird mode: a swipe moves the wird, as it always does there.
        await t.fling(find.byType(PageView), const Offset(400, 0), 1500);
        await settleReader(t);
        final moved = await t.runAsync(() => reader.repo.activeWird());
        expect(moved!.currentPage, 43);
      },
    );

    testWidgets(
      'a plain int is a jump exactly as today: browse mode, no highlight',
      (t) async {
        final reader = await pumpSizedReader(t, startPage: 50);
        await loadAround(t, 293);

        await popIndexWith(t, 293);

        expect(shownPage(t), '293');
        expect(find.text(_makeMine), findsOneWidget);
        expect(cardHighlight(t, 293), isEmpty);
        expect(highlightedBoxes(t), 0);
        final wird = await t.runAsync(() => reader.repo.activeWird());
        expect(wird!.currentPage, 50);
        expect(await t.runAsync(reader.repo.lastViewedPage), 293);
      },
    );

    testWidgets('leaving the index with no value changes nothing', (t) async {
      final reader = await pumpSizedReader(t, startPage: 50);
      await t.tap(keyed('open-index'));
      await settleReader(t);
      Navigator.of(t.element(find.byType(Navigator).last)).pop();
      await settleReader(t);
      expect(shownPage(t), '50');
      expect(find.text(_makeMine), findsNothing);
      expect(highlightedBoxes(t), 0);
      final wird = await t.runAsync(() => reader.repo.activeWird());
      expect(wird!.currentPage, 50);
    });

    testWidgets(
      '2:282 fills page 48: all its words are highlighted there and the next page shows none',
      (t) async {
        await pumpSizedReader(t, startPage: 50);
        final here = await idsOn(t, 48, _debt);
        final page = await realPage(t, 48);
        final all = {
          for (final line in page.lines)
            for (final w in line.words) w.id,
        };
        expect(here, isNotEmpty);
        expect(
          here,
          all,
          reason:
              'page 48 holds nothing but 2:282 (no ayah of this Mushaf goes '
              'on to another page)',
        );

        await popIndexWith(t, const AyahTarget(_debt, 48));

        expect(shownPage(t), '48');
        expect(cardHighlight(t, 48), here);
        expect(highlightedBoxes(t), here.length);
        expect(
          cardHighlight(t, 49) ?? <int>{},
          isEmpty,
          reason: 'nothing on the next page',
        );
      },
    );

    testWidgets('one result shows the page once', (t) async {
      await pumpSizedReader(t, startPage: 50);
      final ids = await idsOn(t, 42, _kursi);

      await popIndexWith(t, const AyahTarget(_kursi, 42));
      await t.pump(const Duration(seconds: 2));

      expect(shownPage(t), '42');
      final cards = t
          .widgetList<MushafPageCard>(find.byType(MushafPageCard))
          .where((c) => c.data?.page == 42)
          .length;
      expect(cards, 1);
      for (final id in ids) {
        expect(
          find.byKey(ValueKey('w$id')),
          findsOneWidget,
          reason: 'word $id',
        );
      }
    });

    testWidgets(
      '«اجعلها موضعي» after a result makes the shown page the wird position',
      (t) async {
        final reader = await pumpSizedReader(t, startPage: 50);
        await loadAround(t, 42);
        await popIndexWith(t, const AyahTarget(_kursi, 42));
        expect(find.text(_makeMine), findsOneWidget);

        await t.tap(find.text(_makeMine));
        await settleReader(t);

        final wird = await t.runAsync(() => reader.repo.activeWird());
        expect(wird!.currentPage, 42);
        expect(find.text(_makeMine), findsNothing);
      },
    );

    testWidgets('a swipe in browse mode after a result moves no wird', (
      t,
    ) async {
      final reader = await pumpSizedReader(t, startPage: 50);
      await loadAround(t, 42);
      await popIndexWith(t, const AyahTarget(_kursi, 42));

      await t.fling(find.byType(PageView), const Offset(400, 0), 1500);
      await settleReader(t);

      expect(shownPage(t), '43');
      final wird = await t.runAsync(() => reader.repo.activeWird());
      expect(wird!.currentPage, 50);
      expect(find.text(_makeMine), findsOneWidget);
    });
  });

  group('the reader has no wird', () {
    testWidgets('a target shows its page in browse mode, highlighted', (
      t,
    ) async {
      final repo = await pumpBrowseReader(t, startPage: 50);
      await loadAround(t, 42);
      final ids = await idsOn(t, 42, _kursi);
      expect(find.text('تصفح'), findsOneWidget, reason: 'the pill of browsing');

      await popIndexWith(t, const AyahTarget(_kursi, 42));

      expect(shownPage(t), '42');
      expect(find.text('تصفح'), findsOneWidget);
      expect(find.text(_makeMine), findsNothing, reason: 'there is no wird');
      expect(cardHighlight(t, 42), ids);
      expect(highlightedBoxes(t), ids.length);
      expect(await t.runAsync(repo.lastViewedPage), 42);
    });
  });
}
