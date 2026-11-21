import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/splash/splash_screen.dart';
import 'package:mushaf/splash/splash_strings.dart';

import 'support/splash_harness.dart';

Widget host({required bool ready, VoidCallback? onGone}) => Directionality(
  textDirection: TextDirection.rtl,
  child: SplashScreen(ready: ready, onGone: onGone),
);

void reduceMotion(WidgetTester tester, bool on) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: on);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// The outermost `Opacity` of the splash: 1 unless it is fading out.
double fadeOf(WidgetTester tester) => tester
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
    'with reduced motion the first frame is already the finished drawing',
    (tester) async {
      reduceMotion(tester, true);
      await startSplash(tester, host(ready: false));
      expect(shownAmount(tester, iconTile), 1);
      expect(shownAmount(tester, find.text(kSplashName)), 1);
      expect(shownAmount(tester, find.text(kSplashTagline)), 1);
      expect(lineProgress(tester), 1);
      expect(iconPainter(tester).twinkle, 0);
      // The tile is at its full size and the text at its final place: no scale and no rise.
      final tile = tester.widget<Transform>(
        find.ancestor(of: iconTile, matching: find.byType(Transform)).first,
      );
      expect(tile.transform.getMaxScaleOnAxis(), 1);
      await advance(tester, 250);
      expect(shownAmount(tester, find.text(kSplashName)), 1);
      expect(iconPainter(tester).twinkle, 0); // nothing moves
    },
  );

  testWidgets(
    'a ready app: shown at 299 ms, gone at 300 ms, with no fade in between',
    (tester) async {
      reduceMotion(tester, true);
      var gone = 0;
      await startSplash(tester, host(ready: true, onGone: () => gone++));
      for (var ms = 1; ms < 300; ms++) {
        await tester.pump(const Duration(milliseconds: 1));
        expect(fadeOf(tester), 1, reason: '$ms ms');
        expect(gone, 0, reason: '$ms ms');
      }
      await tester.pump(const Duration(milliseconds: 1)); // 300 ms
      expect(gone, 1);
    },
  );

  testWidgets(
    'an app that is not ready keeps the static splash, and it leaves at once when ready',
    (tester) async {
      reduceMotion(tester, true);
      var gone = 0;
      await startSplash(tester, host(ready: false, onGone: () => gone++));
      await advance(tester, 3000, step: 100);
      expect(gone, 0);
      expect(fadeOf(tester), 1);
      await tester.pumpWidget(host(ready: true, onGone: () => gone++));
      await advance(tester, 20);
      expect(gone, 1);
    },
  );

  testWidgets('a tap with a ready app leaves at once', (tester) async {
    reduceMotion(tester, true);
    var gone = 0;
    await startSplash(tester, host(ready: true, onGone: () => gone++));
    await advance(tester, 50);
    await tester.tap(find.byType(SplashScreen));
    await advance(tester, 20);
    expect(gone, 1);
  });

  testWidgets(
    'turning reduced motion on while the splash plays drops it to the static drawing',
    (tester) async {
      reduceMotion(tester, false);
      var gone = 0;
      await startSplash(tester, host(ready: false, onGone: () => gone++));
      await advance(tester, 200);
      expect(
        shownAmount(tester, find.text(kSplashName)),
        0,
      ); // not yet, the name starts at 350 ms
      reduceMotion(tester, true);
      await tester.pump();
      expect(shownAmount(tester, find.text(kSplashName)), 1);
      expect(lineProgress(tester), 1);
      // The clock was not restarted: 350 ms have passed in all, so once the app is ready it leaves at once.
      await advance(tester, 150);
      expect(gone, 0);
      await tester.pumpWidget(host(ready: true, onGone: () => gone++));
      await advance(tester, 20);
      expect(gone, 1);
    },
  );
}
