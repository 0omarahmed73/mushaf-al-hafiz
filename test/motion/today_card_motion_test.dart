// Feature 010 T022 (FR-009): the «ملخص اليوم» card fades and slides a little, and its modal barrier follows the open state.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/motion_geometry.dart';
import '../support/motion_harness.dart';

const _card = ValueKey('today-card');
const _barrier = ValueKey('today-barrier');

double _opacity(WidgetTester t) => t
    .widget<FadeTransition>(
      find
          .ancestor(
            of: find.byKey(_card),
            matching: find.byType(FadeTransition),
          )
          .first,
    )
    .opacity
    .value;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  testWidgets(
    'the chip opens the card with a fade in 220 ms, the barrier is there at once',
    (t) async {
      await pumpMotionReader(t, startPage: 50, withWird: true);
      await t.tap(find.byKey(const ValueKey('today-chip')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 16));
      expect(
        find.byKey(_barrier),
        findsOneWidget,
        reason: 'the barrier does not wait for the animation',
      );
      expect(find.byKey(_card), findsOneWidget);
      expect(_opacity(t), lessThan(0.3));
      await t.pump(const Duration(milliseconds: 100));
      expect(_opacity(t), allOf(greaterThan(0.3), lessThan(1)));
      await t.pump(const Duration(milliseconds: 150));
      expect(_opacity(t), 1);
    },
  );

  testWidgets(
    'closing fades it in 160 ms; the barrier goes at once and a tap during the fade reaches the page',
    (t) async {
      await pumpMotionReader(t, startPage: 50, withWird: true);
      await t.tap(find.byKey(const ValueKey('today-chip')));
      // The first pump only starts the ticker (elapsed 0), so 4 rounds of 60 ms are 180 ms of a 220 ms fade: 6 rounds.
      await settleMotion(t, rounds: 6);
      expect(_opacity(t), 1);

      await t.tap(find.byKey(const ValueKey('today-close')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 16));
      expect(
        find.byKey(_barrier),
        findsNothing,
        reason: 'the barrier follows the open state, not the animation',
      );
      expect(
        find.byKey(_card),
        findsOneWidget,
        reason: 'the card is still fading out',
      );
      await t.pump(const Duration(milliseconds: 60));
      expect(_opacity(t), allOf(greaterThan(0), lessThan(1)));

      // A tap on the page while the card leaves: it reaches the page and hides the bars.
      expect(find.byKey(const ValueKey('top-bar')), findsOneWidget);
      await t.tapAt(const Offset(206, 700));
      await t.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(const ValueKey('top-bar')),
        findsNothing,
        reason: 'the tap reached the page',
      );
      expect(find.byKey(_card), findsNothing);
    },
  );

  testWidgets('the page does not move while the card opens and closes', (
    t,
  ) async {
    await pumpMotionReader(t, startPage: 50, withWird: true);
    final before = pageRects(t);
    await t.tap(find.byKey(const ValueKey('today-chip')));
    await expectRectsStable(t, before, reason: 'card arriving');
    await t.tap(find.byKey(const ValueKey('today-close')));
    await expectRectsStable(t, before, reason: 'card leaving');
  });

  testWidgets(
    'with «remove animations» on the card is there, and gone, in the next frame',
    (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await pumpMotionReader(t, startPage: 50, withWird: true);
      await t.tap(find.byKey(const ValueKey('today-chip')));
      await t.pump();
      expect(find.byKey(_card), findsOneWidget);
      expect(_opacity(t), 1);
      await t.tap(find.byKey(const ValueKey('today-close')));
      await t.pump();
      expect(find.byKey(_card), findsNothing);
    },
  );
}
