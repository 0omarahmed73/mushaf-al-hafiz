import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/splash/splash_gate.dart';
import 'package:mushaf/splash/splash_screen.dart';

import 'support/splash_harness.dart';

/// Under `runApp` nothing above the gate provides a `MediaQuery` (the test binding does), so the gate builds one of its own from the
/// view for the splash: the production path, which every run must take (convergence task T029).
void main() {
  testWidgets(
    'the gate gives the splash a MediaQuery of its own, built from the view',
    (tester) async {
      await startSplash(tester, const SplashGate(child: SizedBox.expand()));
      expect(
        find.descendant(
          of: find.byType(SplashGate),
          matching: find.byType(MediaQuery),
        ),
        findsWidgets,
      );
      expect(
        find.ancestor(
          of: find.byType(SplashScreen),
          matching: find.byType(MediaQuery),
        ),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'the splash sees the phone\'s text scale, size and reduce-motion setting',
    (tester) async {
      setWindow(tester, 400, 700);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await startSplash(tester, const SplashGate(child: SizedBox.expand()));
      final inside = tester.element(find.byType(SplashScreen));
      expect(MediaQuery.sizeOf(inside), const Size(400, 700));
      expect(MediaQuery.textScalerOf(inside).scale(10), 15);
      expect(MediaQuery.disableAnimationsOf(inside), isTrue);
    },
  );

  testWidgets('the splash follows a change of the reduce-motion setting', (
    tester,
  ) async {
    await startSplash(tester, const SplashGate(child: SizedBox.expand()));
    expect(
      MediaQuery.disableAnimationsOf(tester.element(find.byType(SplashScreen))),
      isFalse,
    );
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    expect(
      MediaQuery.disableAnimationsOf(tester.element(find.byType(SplashScreen))),
      isTrue,
    );
  });
}
