// The widget that gives one page its size: centred when smaller, scrolling when taller, moving both ways
// when wider, with a swipe from the side edge asking the reader for the next or previous page (spec FR-007,
// FR-008, FR-010; research D3).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/page_scale.dart';
import 'package:mushaf/mushaf/page_viewport.dart';

const Size kPortrait = Size(412, 763);
const Size kLandscape = Size(915, 340);

Finder key(String k) => find.byKey(ValueKey(k));

class Spy {
  final List<(int, bool)> locks = [];
  final List<PageTurn> turns = [];
  int taps = 0, longPresses = 0;
}

Widget host(
  Spy spy, {
  required double factor,
  Size viewport = kPortrait,
  int page = 7,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: viewport.width,
          height: viewport.height,
          child: PageViewport(
            page: page,
            factor: factor,
            onLockChanged: (p, locked) => spy.locks.add((p, locked)),
            onEdgeTurn: spy.turns.add,
            child: GestureDetector(
              key: const ValueKey('page-child'),
              behavior: HitTestBehavior.opaque,
              onTap: () => spy.taps++,
              onLongPress: () => spy.longPresses++,
              child: const ColoredBox(color: Color(0xFFFBF5E3)),
            ),
          ),
        ),
      ),
    ),
  );
}

Rect childRect(WidgetTester t) => t.getRect(key('page-child'));

double scaleOf(WidgetTester t) => t
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!
    .value
    .getMaxScaleOnAxis();

/// A two-finger pinch in small steps (the scale gesture measures from where it is accepted, so one big jump
/// would only count the part after the first finger moved).
Future<void> pinch(
  WidgetTester t,
  Offset center, {
  double from = 40,
  double to = 140,
}) async {
  final a = await t.startGesture(center - Offset(from, 0));
  final b = await t.startGesture(center + Offset(from, 0));
  await t.pump();
  const steps = 12;
  for (var i = 1; i <= steps; i++) {
    final d = from + (to - from) * i / steps;
    await a.moveTo(center - Offset(d, 0));
    await b.moveTo(center + Offset(d, 0));
    await t.pump();
  }
  await a.up();
  await b.up();
  await t.pump();
}

void main() {
  late Spy spy;

  setUp(() => spy = Spy());

  Future<void> pump(
    WidgetTester t,
    double factor, {
    Size viewport = kPortrait,
  }) async {
    t.view.physicalSize = const Size(1000, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(host(spy, factor: factor, viewport: viewport));
    await t.pump();
  }

  group('fits', () {
    testWidgets(
      'portrait at 100% gives the page the whole viewport and does not lock the pager',
      (t) async {
        await pump(t, 1.0);
        expect(childRect(t), const Rect.fromLTWH(0, 0, 412, 763));
        expect(key('page-pan'), findsNothing);
        expect(key('landscape-scroll'), findsNothing);
        expect(spy.locks, [(7, false)]);
      },
    );

    testWidgets('portrait at 80% is a smaller page, centred', (t) async {
      await pump(t, 0.8);
      final r = childRect(t);
      expect(r.width, closeTo(329.6, 0.01));
      expect(r.height, closeTo(610.4, 0.01));
      expect(r.center.dx, closeTo(206, 0.01));
      expect(r.center.dy, closeTo(381.5, 0.01));
      expect(spy.locks, [(7, false)]);
    });

    testWidgets('a smaller page does not pan, and a drag does not move it', (
      t,
    ) async {
      await pump(t, 0.8);
      final before = childRect(t);
      await t.drag(key('page-child'), const Offset(150, 100));
      await t.pump();
      expect(childRect(t), before);
      expect(spy.turns, isEmpty);
    });
  });

  group('scrolls vertically', () {
    testWidgets(
      'landscape at 100% is the portrait-shaped page, 600 wide, in the old scroll view',
      (t) async {
        await pump(t, 1.0, viewport: kLandscape);
        expect(key('landscape-scroll'), findsOneWidget);
        expect(key('page-pan'), findsNothing);
        expect(t.getSize(key('page-child')), const Size(600, 1050));
        expect(childRect(t).center.dx, closeTo(457.5, 0.01));
        expect(spy.locks, [
          (7, false),
        ], reason: 'horizontal swipes stay with the pager');
      },
    );

    testWidgets(
      'a vertical drag scrolls it and a horizontal one does not move it',
      (t) async {
        await pump(t, 1.0, viewport: kLandscape);
        final top = childRect(t).top;
        await t.dragFrom(const Offset(450, 200), const Offset(0, -200));
        await t.pump();
        expect(childRect(t).top, lessThan(top - 100));
        final left = childRect(t).left;
        await t.dragFrom(const Offset(450, 200), const Offset(200, 0));
        await t.pump();
        expect(childRect(t).left, left);
        expect(spy.turns, isEmpty);
      },
    );

    testWidgets(
      'landscape at 150% still only scrolls up and down while the page fits the width',
      (t) async {
        await pump(t, 1.5, viewport: kLandscape);
        expect(key('landscape-scroll'), findsOneWidget);
        expect(t.getSize(key('page-child')), const Size(900, 1575));
        expect(spy.locks, [(7, false)]);
      },
    );
  });

  group('pans both ways', () {
    testWidgets(
      'portrait at 150% is 618 wide, starts at the top right and locks the pager',
      (t) async {
        await pump(t, 1.5);
        expect(key('page-pan'), findsOneWidget);
        expect(key('landscape-scroll'), findsNothing);
        final r = childRect(t);
        expect(r.width, closeTo(618, 0.01));
        expect(r.height, closeTo(1144.5, 0.01));
        expect(r.top, closeTo(0, 0.01));
        expect(
          r.right,
          closeTo(412, 0.01),
          reason: 'the right side is shown first',
        );
        expect(spy.locks, [(7, true)]);
      },
    );

    testWidgets('the page moves with the finger and stops at its own edges', (
      t,
    ) async {
      await pump(t, 1.5);
      await t.drag(key('page-child'), const Offset(100, 0));
      await t.pump();
      expect(
        childRect(t).left,
        closeTo(-106, 20),
        reason: 'moved about 100 px (less the touch slop)',
      );
      await t.drag(key('page-child'), const Offset(900, 0));
      await t.pump();
      expect(
        childRect(t).left,
        closeTo(0, 0.01),
        reason: 'stops at the left edge, never beyond',
      );
      await t.drag(key('page-child'), const Offset(0, -300));
      await t.pump();
      expect(childRect(t).top, lessThan(-200));
      await t.drag(key('page-child'), const Offset(0, -2000));
      await t.pump();
      expect(
        childRect(t).bottom,
        closeTo(763, 0.01),
        reason: 'stops at the bottom edge',
      );
      await t.drag(key('page-child'), const Offset(0, 2000));
      await t.pump();
      expect(childRect(t).top, closeTo(0, 0.01), reason: 'and at the top edge');
    });

    testWidgets(
      'a swipe that starts at the left edge and moves right asks for the next page',
      (t) async {
        await pump(t, 1.5);
        await t.drag(
          key('page-child'),
          const Offset(900, 0),
        ); // to the left edge
        await t.pump();
        expect(
          spy.turns,
          isEmpty,
          reason: 'from the right edge, moving right only moves the page',
        );
        await t.drag(key('page-child'), const Offset(200, 0));
        await t.pump();
        expect(spy.turns, [PageTurn.next]);
      },
    );

    testWidgets(
      'a swipe that starts at the right edge and moves left asks for the previous page',
      (t) async {
        await pump(t, 1.5);
        await t.drag(key('page-child'), const Offset(-200, 0));
        await t.pump();
        expect(spy.turns, [PageTurn.previous]);
      },
    );

    testWidgets(
      'a drag that starts in the middle and runs past the edge only stops at the edge',
      (t) async {
        await pump(t, 1.5);
        await t.drag(key('page-child'), const Offset(110, 0));
        await t.pump();
        await t.drag(key('page-child'), const Offset(500, 0));
        await t.pump();
        expect(childRect(t).left, closeTo(0, 0.01));
        expect(spy.turns, isEmpty);
      },
    );

    testWidgets('a mostly vertical drag at an edge does not turn the page', (
      t,
    ) async {
      await pump(t, 1.5);
      await t.drag(key('page-child'), const Offset(-60, 300));
      await t.pump();
      expect(spy.turns, isEmpty);
    });

    testWidgets('a quick flick from the edge turns the page', (t) async {
      await pump(t, 1.5);
      await t.fling(key('page-child'), const Offset(-60, 0), 2000);
      await t.pump();
      expect(spy.turns, [PageTurn.previous]);
    });

    testWidgets('a tap and a long press still reach the page', (t) async {
      await pump(t, 1.5);
      await t.tap(key('page-child'));
      await t.pump(const Duration(milliseconds: 400));
      expect(spy.taps, 1);
      await t.longPress(key('page-child'));
      await t.pump();
      expect(spy.longPresses, 1);
      expect(spy.turns, isEmpty);
    });

    testWidgets(
      'pinch zoom is limited to 1x..3x of the bigger page and no edge turn happens while zoomed',
      (t) async {
        await pump(t, 1.5);
        await pinch(t, const Offset(206, 380), from: 20, to: 190);
        expect(scaleOf(t), closeTo(3, 0.001));
        expect(spy.locks.last, (7, true));
        await t.dragFrom(const Offset(300, 380), const Offset(-250, 0));
        await t.pump();
        expect(spy.turns, isEmpty);
        await pinch(t, const Offset(206, 380), from: 190, to: 10);
        expect(scaleOf(t), closeTo(1, 0.05));
      },
    );

    testWidgets(
      'a pinch on a page that fits locks the pager while zoomed and releases it again',
      (t) async {
        await pump(t, 1.0);
        await pinch(t, const Offset(206, 380));
        expect(scaleOf(t), greaterThan(1.01));
        expect(spy.locks.last, (7, true));
        await pinch(t, const Offset(206, 380), from: 140, to: 10);
        expect(scaleOf(t), lessThan(1.01));
        expect(spy.locks.last, (7, false));
      },
    );
  });

  group('changing the size', () {
    testWidgets('from 150% to 100% the page fits again, unlocked', (t) async {
      await pump(t, 1.5);
      await t.pumpWidget(host(spy, factor: 1.0));
      await t.pump();
      expect(key('page-pan'), findsNothing);
      expect(childRect(t), const Rect.fromLTWH(0, 0, 412, 763));
      expect(spy.locks.last, (7, false));
    });

    testWidgets('from 100% to 150% the page starts at its top right', (
      t,
    ) async {
      await pump(t, 1.0);
      await t.pumpWidget(host(spy, factor: 1.5));
      await t.pump();
      expect(childRect(t).right, closeTo(412, 0.01));
      expect(childRect(t).top, closeTo(0, 0.01));
      expect(spy.locks.last, (7, true));
    });

    testWidgets(
      'a rebuild with the same size keeps where the page was moved to',
      (t) async {
        await pump(t, 1.5);
        await t.drag(key('page-child'), const Offset(150, 0));
        await t.pump();
        final moved = childRect(t);
        await t.pumpWidget(host(spy, factor: 1.5));
        await t.pump();
        expect(childRect(t), moved);
      },
    );

    testWidgets('each page reports its own lock', (t) async {
      await pump(t, 1.5);
      expect(spy.locks, [(7, true)]);
    });
  });
}
