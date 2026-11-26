import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/look/contrast.dart';
import 'package:mushaf/splash/splash_gate.dart';
import 'package:mushaf/splash/splash_palette.dart';
import 'package:mushaf/splash/splash_screen.dart';
import 'package:mushaf/splash/splash_strings.dart';
import 'package:mushaf/theme.dart';

import 'support/splash_harness.dart';

/// A stand-in for the app: a full-screen tap target with some readable text.
class FakeApp extends StatelessWidget {
  const FakeApp({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: const Center(child: Text('الآية', textDirection: TextDirection.rtl)),
  );
}

void textScale(WidgetTester tester, double factor) {
  tester.platformDispatcher.textScaleFactorTestValue = factor;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  group('no overflow and no exception', () {
    for (final (name, width, height, scale) in [
      ('320 x 640 with a 2x system font', 320.0, 640.0, 2.0),
      ('320 x 640 with a 3x system font', 320.0, 640.0, 3.0),
      ('landscape 640 x 320 with a 2x system font', 640.0, 320.0, 2.0),
      ('the design\'s 390 x 844 with no scaling', 390.0, 844.0, 1.0),
      ('a tiny 200 x 300 window with a 2x system font', 200.0, 300.0, 2.0),
    ]) {
      testWidgets(name, (tester) async {
        setWindow(tester, width, height);
        textScale(tester, scale);
        await startSplash(tester, const SplashGate(child: FakeApp()));
        // The text scale really reached the splash (a test that scales nothing proves nothing).
        expect(
          MediaQuery.textScalerOf(tester.element(find.byType(SplashScreen)))
              .scale(10),
          10 * scale,
        );
        for (final ms in [0, 200, 400, 300, 600, 600, 500]) {
          await advance(tester, ms, step: 50);
          expect(tester.takeException(), isNull, reason: '$name at +$ms ms');
        }
        // Everything stays on the screen.
        final screen = Offset.zero & Size(width, height);
        for (final text in [kSplashName, kSplashTagline]) {
          if (find.text(text).evaluate().isEmpty) continue;
          final box = tester.getRect(find.text(text));
          expect(
            screen.inflate(1).contains(box.topLeft),
            isTrue,
            reason: '$text top-left $box',
          );
          expect(
            screen.inflate(1).contains(box.bottomRight),
            isTrue,
            reason: '$text bottom-right $box',
          );
        }
      });
    }
  });

  testWidgets('a resize in the middle of the splash does not restart it', (
    tester,
  ) async {
    setWindow(tester, 320, 640);
    await startSplash(tester, const SplashGate(child: FakeApp()));
    await advance(tester, 800);
    setWindow(tester, 640, 320);
    await tester.pump();
    expect(
      shownAmount(tester, find.text(kSplashName)),
      1,
    ); // the 800 ms frame, not the first one
    expect(tester.takeException(), isNull);
    await advance(tester, 600);
    expect(find.byType(SplashScreen), findsNothing);
  });

  group(
    'contrast (spec FR-014): at least 4.5:1 on both ends of the background',
    () {
      for (final (what, colour) in [
        ('the name', SplashColors.name),
        ('the line', SplashColors.tagline),
      ]) {
        test(what, () {
          expect(
            contrastRatio(colour, SplashColors.background),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrastRatio(colour, SplashColors.backdropGlow),
            greaterThanOrEqualTo(4.5),
          );
        });
      }
    },
  );

  test('the fonts are the ones the app already bundles', () {
    // The headings moved to Cairo on 2026-11-26 (the owner); Reem Kufi stays for the surah title in the Mushaf.
    expect(kHeadingFont, 'Cairo');
    expect(kUiFont, 'Cairo');
  });

  testWidgets(
    'a screen reader hears the name and the line once, and not the app behind',
    (tester) async {
      final handle = tester.ensureSemantics();
      await startSplash(tester, const SplashGate(child: FakeApp()));
      expect(find.bySemanticsLabel(RegExp(kSplashName)), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(kSplashTagline)), findsOneWidget);
      expect(find.bySemanticsLabel('الآية'), findsNothing);
      await advance(tester, 1400);
      await advance(tester, 300);
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.bySemanticsLabel(RegExp(kSplashName)), findsNothing);
      expect(find.bySemanticsLabel('الآية'), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets(
    'the app behind gets no touches while the splash shows, and does after',
    (tester) async {
      var taps = 0;
      await startSplash(
        tester,
        SplashGate(
          ready: Future<void>.value(),
          child: FakeApp(onTap: () => taps++),
        ),
      );
      await advance(tester, 100);
      // A tap on the middle of the screen ends the splash (it is the splash's own tap) and never reaches the app.
      await tester.tapAt(const Offset(400, 300));
      expect(taps, 0);
      await advance(tester, 300);
      expect(find.byType(SplashScreen), findsNothing);
      await tester.tapAt(const Offset(400, 300));
      expect(taps, 1);
    },
  );

  testWidgets(
    'the app behind is ignored for pointers and semantics only while the splash shows',
    (tester) async {
      await startSplash(tester, const SplashGate(child: FakeApp()));
      IgnorePointer ignore() => tester.widget<IgnorePointer>(
        find
            .ancestor(
              of: find.byType(FakeApp),
              matching: find.byType(IgnorePointer),
            )
            .first,
      );
      ExcludeSemantics exclude() => tester.widget<ExcludeSemantics>(
        find
            .ancestor(
              of: find.byType(FakeApp),
              matching: find.byType(ExcludeSemantics),
            )
            .first,
      );
      expect(ignore().ignoring, isTrue);
      expect(exclude().excluding, isTrue);
      await advance(tester, 1400 + 300);
      expect(ignore().ignoring, isFalse);
      expect(exclude().excluding, isFalse);
    },
  );
}
