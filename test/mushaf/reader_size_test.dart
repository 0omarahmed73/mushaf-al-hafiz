// The reader with the text size set: a bigger page moves sideways and an edge swipe turns it, a smaller page is
// centred, and everything the reader did at 100% still works (spec FR-007, FR-008, FR-010, FR-016).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ui/ayah_sheet.dart';
import 'package:mushaf/mushaf/mushaf_page_card.dart';

import '../support/reader_harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

String pageNumber(WidgetTester t) => t.widget<Text>(key('page-number')).data!;

Rect card(WidgetTester t) => t.getRect(find.byType(MushafPageCard));

Rect pager(WidgetTester t) => t.getRect(find.byType(PageView));

Future<void> dragBy(WidgetTester t, Offset from, Offset by) async {
  await t.dragFrom(from, by);
  await settleReader(t);
}

/// A two-finger pinch in small steps.
Future<void> pinch(
  WidgetTester t,
  Offset center, {
  double from = 20,
  double to = 180,
}) async {
  final a = await t.startGesture(center - Offset(from, 0));
  final b = await t.startGesture(center + Offset(from, 0));
  await t.pump();
  for (var i = 1; i <= 12; i++) {
    final d = from + (to - from) * i / 12;
    await a.moveTo(center - Offset(d, 0));
    await b.moveTo(center + Offset(d, 0));
    await t.pump();
  }
  await a.up();
  await b.up();
  await t.pump();
}

void main() {
  group('150% in portrait', () {
    testWidgets(
      'the page is 1.5 times bigger than the screen allows and starts at its top right',
      (t) async {
        await pumpSizedReader(t, percent: 150);
        final viewport = pager(t);
        expect(key('page-pan'), findsOneWidget);
        final r = card(t);
        expect(r.width, closeTo(viewport.width * 1.5, 0.5));
        expect(r.height, closeTo(viewport.height * 1.5, 0.5));
        expect(
          r.right,
          closeTo(viewport.right, 0.5),
          reason: 'the right side, where reading starts',
        );
        expect(r.top, closeTo(viewport.top, 0.5));
      },
    );

    testWidgets(
      'a sideways drag in the middle moves the page and does not turn it',
      (t) async {
        await pumpSizedReader(t, percent: 150);
        final right = card(t).right;
        await dragBy(t, const Offset(250, 400), const Offset(100, 0));
        expect(pageNumber(t), '50');
        expect(
          card(t).right,
          greaterThan(right + 50),
          reason: 'the page moved',
        );
      },
    );

    testWidgets(
      'from the left edge a swipe left to right brings the next page and saves the position',
      (t) async {
        final reader = await pumpSizedReader(t, percent: 150);
        await dragBy(
          t,
          const Offset(250, 400),
          const Offset(900, 0),
        ); // to the left edge
        expect(
          pageNumber(t),
          '50',
          reason: 'running into the edge turns nothing',
        );
        await dragBy(t, const Offset(250, 400), const Offset(250, 0));
        expect(pageNumber(t), '51');
        final wird = await t.runAsync(() => reader.repo.activeWird());
        expect(wird!.currentPage, 51);
      },
    );

    testWidgets(
      'from the right edge a swipe right to left brings the previous page',
      (t) async {
        final reader = await pumpSizedReader(t, percent: 150);
        await dragBy(t, const Offset(250, 400), const Offset(-250, 0));
        expect(pageNumber(t), '49');
        final wird = await t.runAsync(() => reader.repo.activeWird());
        expect(wird!.currentPage, 49);
      },
    );

    testWidgets(
      'the page that comes in starts at its top right, like the first one',
      (t) async {
        await pumpSizedReader(t, percent: 150);
        await dragBy(t, const Offset(250, 400), const Offset(-250, 0));
        final viewport = pager(t);
        expect(key('page-pan'), findsOneWidget);
        expect(card(t).right, closeTo(viewport.right, 0.5));
        expect(card(t).top, closeTo(viewport.top, 0.5));
      },
    );

    testWidgets('a tap on the page still shows and hides the bars', (t) async {
      await pumpSizedReader(t, percent: 150);
      expect(key('bottom-bar'), findsOneWidget);
      await t.tap(key('line-5'));
      await t.pump(const Duration(milliseconds: 300));
      expect(key('top-bar'), findsNothing);
      expect(key('bottom-bar'), findsNothing);
    });

    testWidgets(
      'a long press on a word opens its ayah menu with the ayah highlighted',
      (t) async {
        // Page 42 has words in its second line (page 50's second line is a basmala).
        await pumpSizedReader(t, startPage: 42, percent: 150);
        final viewport = pager(t);
        // A word of the second line that is on the screen (the page is wider than the screen).
        final onScreen = find
            .descendant(of: key('line-2'), matching: find.byType(Text))
            .evaluate()
            .map((e) => e.widget)
            .where((w) => viewport.contains(t.getCenter(find.byWidget(w))))
            .first;
        await t.longPress(find.byWidget(onScreen));
        await settleReader(t);
        expect(find.byType(AyahSheet), findsOneWidget);
        final highlighted = t
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .where(
              (d) =>
                  d.decoration is BoxDecoration &&
                  (d.decoration as BoxDecoration).color ==
                      const Color(0x55FFC107),
            );
        expect(highlighted, isNotEmpty);
      },
    );

    testWidgets('the page number at the bottom opens the go-to-page popup', (
      t,
    ) async {
      await pumpSizedReader(t, percent: 150);
      await dragBy(
        t,
        const Offset(250, 400),
        const Offset(0, -1500),
      ); // to the bottom edge
      await t.tap(key('page-number'));
      await settleReader(t);
      expect(key('goto-dialog'), findsOneWidget);
    });

    testWidgets('pinch zoom is limited to 1x..3x of the bigger page', (
      t,
    ) async {
      await pumpSizedReader(t, percent: 150);
      await pinch(t, const Offset(206, 400), from: 10, to: 190);
      final scale = t
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!
          .value
          .getMaxScaleOnAxis();
      expect(scale, closeTo(3, 0.001));
    });
  });

  group('landscape and smaller sizes', () {
    testWidgets(
      'landscape at 150% is a page 900 wide that scrolls up and down',
      (t) async {
        await pumpSizedReader(t, percent: 150, screen: const Size(915, 412));
        expect(key('landscape-scroll'), findsOneWidget);
        expect(card(t).width, closeTo(900, 0.5));
      },
    );

    testWidgets('landscape on a narrower screen at 150% moves sideways too', (
      t,
    ) async {
      await pumpSizedReader(t, percent: 150, screen: const Size(780, 412));
      expect(key('page-pan'), findsOneWidget);
    });

    testWidgets(
      '80% is a smaller, centred page and a swipe turns it as before',
      (t) async {
        await pumpSizedReader(t, percent: 80);
        final viewport = pager(t);
        final r = card(t);
        expect(key('page-pan'), findsNothing);
        expect(r.width, closeTo(viewport.width * 0.8, 0.5));
        expect(r.center.dx, closeTo(viewport.center.dx, 0.5));
        await t.fling(find.byType(PageView), const Offset(400, 0), 1500);
        await settleReader(t);
        expect(pageNumber(t), '51');
      },
    );

    testWidgets(
      'at 100% nothing changed: no panning view, the whole page fits, a swipe turns it',
      (t) async {
        await pumpSizedReader(t, percent: 100);
        expect(key('page-pan'), findsNothing);
        final viewport = pager(t);
        expect(card(t).size, viewport.size);
        await t.fling(find.byType(PageView), const Offset(400, 0), 1500);
        await settleReader(t);
        expect(pageNumber(t), '51');
      },
    );
  });

  group('changing the size', () {
    testWidgets(
      'while the reader is shown the page changes without a restart',
      (t) async {
        final reader = await pumpSizedReader(t, percent: 100);
        expect(key('page-pan'), findsNothing);
        await reader.setSize(t, 120);
        await settleReader(t);
        expect(key('page-pan'), findsOneWidget);
        final viewport = pager(t);
        expect(card(t).width, closeTo(viewport.width * 1.2, 0.5));
        await reader.setSize(t, 100);
        await settleReader(t);
        expect(key('page-pan'), findsNothing);
        expect(card(t).size, viewport.size);
        expect(pageNumber(t), '50', reason: 'still on the same page');
      },
    );
  });
}
