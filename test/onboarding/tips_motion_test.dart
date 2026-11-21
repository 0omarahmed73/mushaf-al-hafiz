// Motion in the first-run tips (feature 008, spec FR-013, SC-006, research D7, D10): the ring on the long-press drawing,
// the slide of «التالي» and the dots growing all stand still when the phone asks for reduced motion, and the ring runs
// only on its own step otherwise.
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/onboarding/tip_steps.dart';
import 'package:mushaf/onboarding/tips_dialog.dart';

import '../support/tips_harness.dart';

int running(WidgetTester t) => t.binding.transientCallbackCount;

/// The horizontal distance between the centre of step [i]'s title and the centre of the card.
double offCentre(WidgetTester t, int i) =>
    (t.getCenter(key('tips-step-title-$i')).dx -
            t.getCenter(key('tips-dialog')).dx)
        .abs();

void main() {
  group('reduced motion is on', () {
    testWidgets('step 1 draws no animation at all: the ring is still', (
      t,
    ) async {
      await pumpTipsDialog(t, disableAnimations: true);
      await t.pump(const Duration(milliseconds: 300));
      expect(running(t), 0);
    });

    testWidgets(
      '«التالي» shows the next step in the next frame, with no slide, and the dots change at once',
      (t) async {
        await pumpTipsDialog(t, disableAnimations: true);
        await t.tap(nextButton);
        await t.pump();
        await t.pump();
        expect(
          offCentre(t, 1),
          lessThan(1),
          reason: 'step 2 is in place, no time has passed',
        );
        expect(key('tips-step-title-0'), findsNothing);
        expect(currentStep(t), 1);
        // The button's own touch ripple is the phone's, not ours: let it end.
        await t.pump(const Duration(seconds: 1));
        expect(running(t), 0);
      },
    );

    testWidgets('one tap is one step and the last step is never passed', (
      t,
    ) async {
      await pumpTipsDialog(t, disableAnimations: true);
      for (var i = 1; i < kTipSteps.length; i++) {
        await t.tap(nextButton);
        await t.pump();
        await t.pump();
        expect(currentStep(t), i);
      }
      expect(startButton, findsOneWidget);
      expect(find.byType(TipsDialog), findsOneWidget);
    });

    testWidgets('no step has anything running, whichever is shown', (t) async {
      await pumpTipsDialog(t, disableAnimations: true);
      for (var i = 0; i < kTipSteps.length; i++) {
        await t.pump(const Duration(milliseconds: 200));
        expect(running(t), 0, reason: 'step ${i + 1}');
        if (i < kTipSteps.length - 1) {
          await t.tap(nextButton);
          await t.pump();
          await t.pump();
          await t.pump(const Duration(seconds: 1));
        }
      }
    });
  });

  group('reduced motion is off', () {
    testWidgets('the ring runs on step 1', (t) async {
      await pumpTipsDialog(t);
      await t.pump(const Duration(milliseconds: 300));
      expect(running(t), greaterThan(0));
    });

    testWidgets(
      'the ring stops when the step is left, and no other step runs anything',
      (t) async {
        await pumpTipsDialog(t);
        for (var i = 1; i < kTipSteps.length; i++) {
          await tapNext(t);
          await t.pump(const Duration(milliseconds: 200));
          expect(running(t), 0, reason: 'step ${i + 1}');
        }
      },
    );

    testWidgets(
      '«التالي» slides: half way, the next step is not yet in place',
      (t) async {
        await pumpTipsDialog(t);
        await t.tap(nextButton);
        await t.pump();
        await t.pump(const Duration(milliseconds: 80));
        expect(
          offCentre(t, 1),
          greaterThan(20),
          reason: 'step 2 is still coming in',
        );
        await settleTips(t);
        expect(offCentre(t, 1), lessThan(1));
      },
    );

    testWidgets('two quick taps during the slide move one step', (t) async {
      await pumpTipsDialog(t);
      await t.tap(nextButton);
      await t.tap(nextButton);
      await settleTips(t);
      expect(currentStep(t), 1);
    });
  });

  group('the setting of the phone, through the gate', () {
    testWidgets(
      'with "remove animations" on, the popup opens and stands with nothing running',
      (t) async {
        tipsPhoneScreen(t);
        t.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
        final repo = await openTipsRepository(t);
        await t.pumpWidget(tipsGateApp(repo));
        await settleGate(t);
        expect(find.byType(TipsDialog), findsOneWidget);
        expect(running(t), 0, reason: 'no route transition, no ring, nothing');
        await t.tap(nextButton);
        await t.pump();
        await t.pump();
        expect(currentStep(t), 1);
        await t.pump(const Duration(seconds: 1));
        expect(running(t), 0);
      },
    );

    testWidgets('with it off, the ring runs on step 1', (t) async {
      tipsPhoneScreen(t);
      final repo = await openTipsRepository(t);
      await t.pumpWidget(tipsGateApp(repo));
      await settleGate(t);
      expect(find.byType(TipsDialog), findsOneWidget);
      expect(running(t), greaterThan(0));
    });
  });
}
