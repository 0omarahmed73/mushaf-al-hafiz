// Feature 010 spike S1 (research.md D2): what Flutter 3.50's PageView does with `allowImplicitScrolling` and a 1 px
// `scrollCacheExtent`: are the neighbours built while the pager rests, are they invisible to finders (so the earlier
// tests, which look for one page number, still see one), and when is the page after the neighbour built. The plan
// relies on these three facts, so this test fails loudly if a Flutter upgrade changes them.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/motion_probe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(PageController, Set<int>)> pump(
    WidgetTester t, {
    required bool prewarm,
  }) async {
    t.view.physicalSize = const Size(400, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final controller = PageController(initialPage: 50);
    addTearDown(controller.dispose);
    final built = <int>{};
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PageView.builder(
          reverse: true,
          controller: controller,
          itemCount: 604,
          allowImplicitScrolling: prewarm,
          scrollCacheExtent: prewarm ? const ScrollCacheExtent.pixels(1) : null,
          itemBuilder: (context, index) {
            built.add(index);
            return Center(child: Text('page $index', key: ValueKey('p$index')));
          },
        ),
      ),
    );
    return (controller, built);
  }

  testWidgets('S1a: today the neighbour is built only when the finger moves', (
    t,
  ) async {
    final (controller, built) = await pump(t, prewarm: false);
    expect(built, {50}, reason: 'only the shown page at rest');
    final g = await t.startGesture(const Offset(100, 400));
    for (var i = 0; i < 5; i++) {
      await g.moveBy(const Offset(8, 0));
    }
    await t.pump();
    expect(built, {
      50,
      51,
    }, reason: 'the incoming page is built in the first frames of the slide');
    await g.up();
    await t.pumpAndSettle();
    expect(
      controller.page,
      closeTo(50, 0.01),
      reason: 'a short drag springs back',
    );
    motionLog(
      'S1a without prewarm: at rest built=${{50}}; after the first 40 px of a swipe built=$built',
    );
  });

  testWidgets(
    'S1b: with allowImplicitScrolling + 1 px cache both neighbours are built at rest and finders still see one page',
    (t) async {
      final (controller, built) = await pump(t, prewarm: true);
      expect(
        built,
        {49, 50, 51},
        reason:
            'both neighbours are ready before any finger touches the screen',
      );
      expect(find.byKey(const ValueKey('p50')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('p49')),
        findsNothing,
        reason: 'a neighbour outside the screen is offstage for finders',
      );
      expect(find.byKey(const ValueKey('p51')), findsNothing);
      expect(
        find.textContaining('page '),
        findsOneWidget,
        reason:
            'the earlier tests that look for one page number keep seeing one',
      );

      built.clear();
      final g = await t.startGesture(const Offset(100, 400));
      for (var i = 0; i < 5; i++) {
        await g.moveBy(const Offset(8, 0));
      }
      await t.pump();
      expect(
        built,
        isEmpty,
        reason: 'the first frames of the slide build nothing',
      );
      // Drag across most of the page: the page after the neighbour must not be built before the end of the slide.
      await g.moveBy(const Offset(300, 0));
      await t.pump();
      expect(built, isEmpty, reason: 'at 340 of 400 px nothing new is built');
      await g.moveBy(const Offset(50, 0));
      await t.pump();
      motionLog(
        'S1b with prewarm: built after 390 of 400 px of the slide: $built',
      );
      await g.up();
      await t.pumpAndSettle();
      expect(controller.page, closeTo(51, 0.01));
      motionLog(
        'S1b with prewarm: built after the slide settled (a new neighbour appears at its end): $built',
      );
      expect(built, contains(52));
    },
  );
}
