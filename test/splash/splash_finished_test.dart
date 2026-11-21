import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/splash/splash_gate.dart';
import 'package:mushaf/splash/splash_screen.dart';

import 'support/splash_harness.dart';

/// Records every call of `onFinished` and whether the splash was already out of the tree at that moment.
class Finished {
  int calls = 0;
  final List<bool> splashGoneAtCall = [];

  void call() {
    calls++;
    splashGoneAtCall.add(find.byType(SplashScreen).evaluate().isEmpty);
  }
}

void main() {
  const app = SizedBox.expand();

  testWidgets('a normal end calls it once, after the splash is gone', (
    tester,
  ) async {
    final finished = Finished();
    await startSplash(
      tester,
      SplashGate(onFinished: finished.call, child: app),
    );
    await advance(tester, 800);
    expect(finished.calls, 0);
    await advance(tester, 400);
    await advance(tester, 100);
    expect(finished.calls, 1);
    expect(finished.splashGoneAtCall, [true]);
    await advance(tester, 3000, step: 100);
    expect(finished.calls, 1);
  });

  testWidgets('it is not called while the app is still loading', (
    tester,
  ) async {
    final finished = Finished();
    final ready = Completer<void>();
    await startSplash(
      tester,
      SplashGate(ready: ready.future, onFinished: finished.call, child: app),
    );
    await advance(tester, 4000, step: 100);
    expect(finished.calls, 0);
    ready.complete();
    await tester.pump();
    await tester.pump();
    await advance(tester, 300);
    expect(finished.calls, 1);
  });

  testWidgets('a tap ends it and calls it once, even with two taps', (
    tester,
  ) async {
    final finished = Finished();
    await startSplash(
      tester,
      SplashGate(onFinished: finished.call, child: app),
    );
    await advance(tester, 200);
    await tester.tap(find.byType(SplashScreen));
    await tester.tap(find.byType(SplashScreen));
    await advance(tester, 400);
    expect(finished.calls, 1);
    expect(finished.splashGoneAtCall, [true]);
  });

  testWidgets('reduced motion calls it once', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final finished = Finished();
    await startSplash(
      tester,
      SplashGate(onFinished: finished.call, child: app),
    );
    await advance(tester, 400);
    expect(finished.calls, 1);
    expect(finished.splashGoneAtCall, [true]);
  });

  testWidgets('a failed loading also ends the splash and calls it once', (
    tester,
  ) async {
    final finished = Finished();
    final ready = Completer<void>();
    await startSplash(
      tester,
      SplashGate(ready: ready.future, onFinished: finished.call, child: app),
    );
    ready.completeError(StateError('boom'));
    await tester.pump();
    await tester.pump();
    await advance(tester, 1200);
    expect(finished.calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rebuilding the gate does not call it, and the last callback given is the one called',
    (tester) async {
      final first = Finished();
      final second = Finished();
      await startSplash(tester, SplashGate(onFinished: first.call, child: app));
      await advance(tester, 500);
      await tester.pumpWidget(SplashGate(onFinished: second.call, child: app));
      expect(first.calls + second.calls, 0);
      await advance(tester, 1000);
      expect(first.calls, 0);
      expect(second.calls, 1);
    },
  );

  testWidgets('without a callback nothing happens', (tester) async {
    await startSplash(tester, const SplashGate(child: app));
    await advance(tester, 1500);
    expect(find.byType(SplashScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
