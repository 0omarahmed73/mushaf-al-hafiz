// The reader and the khatm dua (spec FR-001 to FR-006, FR-008; contracts/ui.md «The gesture»; research D1, D5).
// A forward swipe (a finger moving left to right) on page 604 opens the dua; nothing else does; «آمين» shows page 1.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/khatm/khatm_dua_screen.dart';
import 'package:mushaf/mushaf/page_viewport.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/khatm_harness.dart';
import '../support/reader_harness.dart';

/// A two-finger pinch in small steps.
Future<void> pinch(WidgetTester t, Offset center) async {
  final a = await t.startGesture(center - const Offset(20, 0));
  final b = await t.startGesture(center + const Offset(20, 0));
  await t.pump();
  for (var i = 1; i <= 12; i++) {
    final d = 20 + 160 * i / 12;
    await a.moveTo(center - Offset(d, 0));
    await b.moveTo(center + Offset(d, 0));
    await t.pump();
  }
  await a.up();
  await b.up();
  await settleReader(t);
}

void main() {
  group('the swipe at page 604 opens the dua', () {
    testWidgets('a forward drag of 120 px opens it', (t) async {
      await pumpSizedReader(t, startPage: 604);
      expect(pageNumber(t), '604');
      expect(duaOpen, isFalse);
      await drag(t, 120);
      expect(duaOpen, isTrue);
      expect(find.byType(KhatmDuaScreen), findsOneWidget);
    });

    testWidgets('a quick flick opens it', (t) async {
      await pumpSizedReader(t, startPage: 604);
      await flingForward(t);
      expect(duaOpen, isTrue);
    });

    testWidgets('a 12 px brush and a 30 px drag open nothing', (t) async {
      await pumpSizedReader(t, startPage: 604);
      await drag(t, 12);
      expect(duaOpen, isFalse);
      await drag(t, 30);
      expect(duaOpen, isFalse);
      expect(pageNumber(t), '604');
    });

    testWidgets('two flings in a row open one screen', (t) async {
      await pumpSizedReader(t, startPage: 604);
      await t.fling(find.byType(PageView), const Offset(400, 0), 1500);
      await t.pump(const Duration(milliseconds: 30));
      await t.fling(find.byType(PageView), const Offset(400, 0), 1500);
      await settleReader(t);
      expect(find.byType(KhatmDuaScreen), findsOneWidget);
      await t.tap(find.byType(BackButton));
      await settleReader(t);
      expect(
        find.byType(KhatmDuaScreen),
        findsNothing,
        reason: 'one back closes it: only one was open',
      );
      expect(pageNumber(t), '604');
    });

    testWidgets(
      'on a page wider than the screen (150%), the edge swipe opens it',
      (t) async {
        await pumpSizedReader(t, startPage: 604, percent: 150);
        expect(key('page-pan'), findsOneWidget);
        await drag(t, 900); // runs into the left edge: nothing yet
        expect(duaOpen, isFalse);
        expect(pageNumber(t), '604');
        await drag(t, 250); // a swipe that starts at the left edge
        expect(duaOpen, isTrue);
      },
    );
  });

  group('what must not open it', () {
    testWidgets('the same swipe on page 603 turns to 604 and opens nothing', (
      t,
    ) async {
      await pumpSizedReader(t, startPage: 603);
      await flingForward(t);
      expect(pageNumber(t), '604');
      expect(duaOpen, isFalse);
    });

    testWidgets('a backward drag on page 604 turns to 603 and opens nothing', (
      t,
    ) async {
      await pumpSizedReader(t, startPage: 604);
      await t.fling(find.byType(PageView), const Offset(-400, 0), 1500);
      await settleReader(t);
      expect(pageNumber(t), '603');
      expect(duaOpen, isFalse);
    });

    testWidgets(
      'a jump to page 604 through go-to-page opens nothing, a swipe after it does',
      (t) async {
        await pumpSizedReader(t, startPage: 50);
        await t.tap(key('page-number'));
        await settleReader(t);
        await t.enterText(key('goto-field'), '604');
        await t.tap(key('goto-go'));
        await settleReader(t);
        expect(pageNumber(t), '604');
        expect(duaOpen, isFalse);
        await flingForward(t);
        expect(duaOpen, isTrue);
      },
    );

    testWidgets('switching to a wird that is on page 604 opens nothing', (
      t,
    ) async {
      final reader = await pumpSizedReader(t, startPage: 50);
      final id = (await t.runAsync(
        () => reader.repo.create(
          const WirdDraft(
            name: 'ورد ثان',
            type: WirdType.reading,
            startPage: 604,
            dailyPages: 5,
            color: 0xFF1565C0,
          ),
        ),
      ))!;
      await settleReader(t);
      await t.tap(key('wird-pill'));
      await settleReader(t);
      await t.tap(key('wird-$id'));
      await settleReader(t);
      expect(pageNumber(t), '604');
      expect(duaOpen, isFalse);
    });

    testWidgets('a zoomed page 604 pans and opens nothing', (t) async {
      await pumpSizedReader(t, startPage: 604);
      await pinch(t, const Offset(206, 400));
      final zoom = t
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!
          .value
          .getMaxScaleOnAxis();
      expect(zoom, greaterThan(1.5));
      await drag(t, 300, from: const Offset(100, 400));
      expect(duaOpen, isFalse);
      expect(pageNumber(t), '604');
    });
  });

  group('«آمين» shows page 1', () {
    testWidgets(
      'for a reader following a wird: page 1 at once, the wird and the last page saved as 1',
      (t) async {
        final reader = await pumpSizedReader(t, startPage: 604);
        await t.runAsync(() => reader.repo.addBookmark(604, 'علامة'));
        final before = await untouched(t, reader.repo);
        await drag(t, 120);
        expect(duaOpen, isTrue);
        await tapAmen(t);
        expect(duaOpen, isFalse);
        expect(pageNumber(t), '1');
        expect(
          find.byType(PageViewport).evaluate().length,
          lessThanOrEqualTo(3),
          reason: 'jumpToPage(0) did not build the pages between (research D5)',
        );
        final wird = await t.runAsync(() => reader.repo.activeWird());
        expect(wird!.currentPage, 1);
        expect(await t.runAsync(() => reader.repo.lastViewedPage()), 1);
        final after = await untouched(t, reader.repo);
        expect(
          after[0],
          before[0],
          reason: 'the khatma count is only changed by «تم»',
        );
        expect(after[1], before[1], reason: 'today\'s portions and done marks');
        expect(after[2], before[2], reason: 'the bookmarks');
      },
    );

    testWidgets('in browse mode: page 1 and the last viewed page saved as 1', (
      t,
    ) async {
      final repo = await pumpBrowseReader(t, startPage: 604);
      expect(pageNumber(t), '604');
      await drag(t, 120);
      expect(duaOpen, isTrue);
      await tapAmen(t);
      expect(pageNumber(t), '1');
      expect(await t.runAsync(() => repo.lastViewedPage()), 1);
      expect(
        await t.runAsync(() => repo.activeWird()),
        isNull,
        reason: 'no wird was created or moved',
      );
    });

    testWidgets('after «آمين» a swipe on page 1 turns to page 2 as usual', (
      t,
    ) async {
      await pumpSizedReader(t, startPage: 604);
      await drag(t, 120);
      await tapAmen(t);
      await flingForward(t);
      expect(pageNumber(t), '2');
      expect(duaOpen, isFalse);
    });
  });
}
