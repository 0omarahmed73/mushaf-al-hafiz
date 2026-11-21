import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/splash/splash_palette.dart';
import 'package:mushaf/splash/splash_screen.dart';
import 'package:mushaf/splash/splash_strings.dart';

import 'support/splash_harness.dart';

Widget host({bool ready = false, VoidCallback? onGone}) => Directionality(
  textDirection: TextDirection.rtl,
  child: SplashScreen(ready: ready, onGone: onGone),
);

void main() {
  testWidgets('the first frame is flat: nothing shown yet', (tester) async {
    await startSplash(tester, host());
    expect(shownAmount(tester, find.text(kSplashName)), 0);
    expect(shownAmount(tester, find.text(kSplashTagline)), 0);
    expect(shownAmount(tester, iconTile), 0);
    expect(lineProgress(tester), 0);
  });

  testWidgets(
    'the tile, the name and the line fade in and the thin line fills',
    (tester) async {
      await startSplash(tester, host());
      await after(tester, 300);
      expect(shownAmount(tester, iconTile), inExclusiveRange(0.5, 1));
      expect(shownAmount(tester, find.text(kSplashName)), 0);
      await after(tester, 700); // 1000 ms
      expect(shownAmount(tester, iconTile), 1);
      expect(shownAmount(tester, find.text(kSplashName)), 1);
      expect(shownAmount(tester, find.text(kSplashTagline)), 1);
      final at1000 = lineProgress(tester);
      expect(at1000, inExclusiveRange(0.9, 1));
      await after(tester, 400); // 1400 ms
      expect(lineProgress(tester), 1);
    },
  );

  testWidgets('the star twinkles once', (tester) async {
    await startSplash(tester, host());
    await after(tester, 300);
    expect(iconPainter(tester).twinkle, 0);
    await after(tester, 300); // 600 ms: the peak
    expect(iconPainter(tester).twinkle, closeTo(1, 0.01));
    await after(tester, 400); // 1000 ms
    expect(iconPainter(tester).twinkle, 0);
  });

  testWidgets('the text is set as designed', (tester) async {
    await startSplash(tester, host());
    final name = tester.widget<Text>(find.text(kSplashName));
    expect(name.style!.fontFamily, 'ReemKufi');
    expect(name.style!.fontSize, 44);
    expect(name.style!.color, SplashColors.name);
    expect(name.style!.decoration, TextDecoration.none);
    final line = tester.widget<Text>(find.text(kSplashTagline));
    expect(line.style!.fontFamily, 'Cairo');
    expect(line.style!.fontSize, 15);
    expect(line.style!.color, SplashColors.tagline);
    expect(line.textAlign, TextAlign.center);
  });

  testWidgets(
    'the tile is 132 px and the thin line 120 x 3 at the design\'s 390 x 844',
    (tester) async {
      setWindow(tester, 390, 844);
      await startSplash(tester, host());
      expect(
        tester.getSize(find.byKey(const ValueKey('splash-tile'))),
        const Size(132, 132),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('splash-progress'))),
        const Size(120, 3),
      );
      // 64 px above the bottom edge, centred.
      final line = tester.getRect(
        find.byKey(const ValueKey('splash-progress')),
      );
      expect(line.bottom, 844 - 64);
      expect(line.center.dx, 195);
    },
  );

  testWidgets(
    'it ends by itself: still there at 800 ms, gone and reported once by the end of the fade',
    (tester) async {
      var gone = 0;
      await startSplash(tester, host(ready: true, onGone: () => gone++));
      await advance(tester, 800);
      expect(gone, 0);
      expect(find.byType(SplashScreen), findsOneWidget);
      await advance(tester, 1400 + 220 - 800);
      expect(gone, 1);
      await advance(tester, 2000);
      expect(gone, 1);
    },
  );
}
