import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/splash/splash_gate.dart';
import 'package:mushaf/splash/splash_screen.dart';

import 'support/splash_harness.dart';

Widget host({required bool ready, VoidCallback? onGone}) => Directionality(
  textDirection: TextDirection.rtl,
  child: SplashScreen(ready: ready, onGone: onGone),
);

/// 1 while the splash is shown in full, less while it fades (the outermost `Opacity` of the splash).
double shown(WidgetTester tester) => tester
    .widget<Opacity>(
      find
          .descendant(
            of: find.byType(SplashScreen),
            matching: find.byType(Opacity),
          )
          .first,
    )
    .opacity;

void main() {
  testWidgets(
    'a ready app: still whole at 899 ms, leaving at 900 ms, gone when the fade ends at 1120 ms',
    (tester) async {
      var gone = 0;
      await startSplash(tester, host(ready: true, onGone: () => gone++));
      await advance(tester, 899, step: 1);
      expect(shown(tester), 1);
      expect(gone, 0);
      await advance(tester, 11, step: 1); // 910 ms: the fade has begun
      expect(shown(tester), lessThan(1));
      await advance(tester, 209, step: 1); // 1119 ms
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(gone, 0);
      await advance(tester, 1, step: 1); // 1120 ms
      expect(gone, 1);
    },
  );

  testWidgets(
    'an app that is not ready keeps the splash for as long as it takes',
    (tester) async {
      var gone = 0;
      await startSplash(tester, host(ready: false, onGone: () => gone++));
      await advance(tester, 5000, step: 50);
      expect(shown(tester), 1);
      expect(gone, 0);
      expect(find.byType(SplashScreen), findsOneWidget);
    },
  );

  testWidgets(
    'an app that becomes ready late: the splash leaves within the fade, not before',
    (tester) async {
      var gone = 0;
      await startSplash(tester, host(ready: false, onGone: () => gone++));
      await advance(tester, 2500, step: 50);
      expect(gone, 0);
      await tester.pumpWidget(host(ready: true, onGone: () => gone++));
      await advance(tester, 219);
      expect(gone, 0);
      await advance(tester, 1);
      expect(gone, 1);
    },
  );

  testWidgets('a tap with a ready app ends the splash within the fade', (
    tester,
  ) async {
    var gone = 0;
    await startSplash(tester, host(ready: true, onGone: () => gone++));
    await advance(tester, 300);
    expect(shown(tester), 1);
    await tester.tap(find.byType(SplashScreen));
    await advance(tester, 219);
    expect(gone, 0);
    await advance(tester, 1);
    expect(gone, 1);
  });

  testWidgets(
    'a tap while the app is not ready waits for it: it never shows an unfinished app',
    (tester) async {
      var gone = 0;
      await startSplash(tester, host(ready: false, onGone: () => gone++));
      await advance(tester, 300);
      await tester.tap(find.byType(SplashScreen));
      await advance(tester, 2000, step: 50);
      expect(gone, 0);
      expect(shown(tester), 1);
      await tester.pumpWidget(host(ready: true, onGone: () => gone++));
      await advance(tester, 220);
      expect(gone, 1);
    },
  );

  testWidgets(
    'two taps and a tap during the fade report once and throw nothing',
    (tester) async {
      var gone = 0;
      await startSplash(tester, host(ready: true, onGone: () => gone++));
      await advance(tester, 300);
      await tester.tap(find.byType(SplashScreen));
      await tester.tap(find.byType(SplashScreen));
      await advance(tester, 100);
      await tester.tap(find.byType(SplashScreen), warnIfMissed: false);
      await advance(tester, 500);
      expect(gone, 1);
      expect(tester.takeException(), isNull);
    },
  );

  group('through the gate', () {
    Widget gate({Future<void>? ready, VoidCallback? onFinished}) => SplashGate(
      ready: ready,
      onFinished: onFinished,
      child: const SizedBox.expand(),
    );

    testWidgets('no ready future means ready at once', (tester) async {
      await startSplash(tester, gate());
      await advance(tester, 890);
      expect(find.byType(SplashScreen), findsOneWidget);
      await advance(tester, 250);
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets(
      'the splash waits for the ready future and leaves within the fade after it',
      (tester) async {
        final ready = Completer<void>();
        await startSplash(tester, gate(ready: ready.future));
        await advance(tester, 2000, step: 50);
        expect(find.byType(SplashScreen), findsOneWidget);
        ready.complete();
        await tester.pump();
        await tester.pump();
        await advance(tester, 219);
        expect(find.byType(SplashScreen), findsOneWidget);
        await advance(tester, 1);
        expect(find.byType(SplashScreen), findsNothing);
      },
    );

    testWidgets(
      'a ready future that fails also ends the splash (it never hangs)',
      (tester) async {
        final ready = Completer<void>();
        await startSplash(tester, gate(ready: ready.future));
        await advance(tester, 1000, step: 50);
        ready.completeError(StateError('boom'));
        await tester.pump();
        await tester.pump();
        await advance(tester, 230);
        expect(find.byType(SplashScreen), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
