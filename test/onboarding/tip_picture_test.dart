// The six drawings of the first-run tips (feature 008, research D10): shapes and the app's own icons, no text, scaled to
// fit, and one gentle pulse that runs only on the long-press drawing while its step is shown.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/onboarding/tip_picture.dart';
import 'package:mushaf/onboarding/tip_steps.dart';
import 'package:mushaf/theme.dart';

Future<void> pumpPicture(
  WidgetTester t,
  TipPicture picture, {
  bool active = true,
  Size box = const Size(240, 112),
  AppLook look = AppLook.emerald,
}) async {
  await t.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(look: look),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: box.width,
            height: box.height,
            child: TipPictureView(picture: picture, active: active),
          ),
        ),
      ),
    ),
  );
  await t.pump();
}

void main() {
  for (final look in [AppLook.emerald, AppLook.night]) {
    final name = look == AppLook.emerald ? 'Emerald & Gold' : 'Night Reader';
    for (final picture in TipPicture.values) {
      testWidgets(
        '${picture.name} builds in $name at 240 x 112 and scaled down to 100 x 60',
        (t) async {
          await pumpPicture(t, picture, look: look);
          expect(t.takeException(), isNull);
          await pumpPicture(t, picture, box: const Size(100, 60), look: look);
          expect(t.takeException(), isNull);
          final drawn = t.getSize(find.byType(TipPictureView));
          expect(drawn, const Size(100, 60));
        },
      );
    }
  }

  for (final picture in TipPicture.values) {
    testWidgets(
      '${picture.name} holds no text and no image, and is silent for a screen reader',
      (t) async {
        await pumpPicture(t, picture);
        final inside = find.byType(TipPictureView);
        expect(
          find.descendant(of: inside, matching: find.byType(Text)),
          findsNothing,
        );
        // An Icon is drawn as one private-use character of the icon font (the BMP or the supplementary planes); anything else would be real text.
        final words = find.descendant(
          of: inside,
          matching: find.byWidgetPredicate(
            (w) =>
                w is RichText &&
                RegExp(
                  '[^\\u{E000}-\\u{F8FF}\\u{F0000}-\\u{10FFFF}]',
                  unicode: true,
                ).hasMatch(w.text.toPlainText()),
          ),
        );
        expect(words, findsNothing);
        expect(
          find.descendant(of: inside, matching: find.byType(Image)),
          findsNothing,
        );
        final exclude = find.descendant(
          of: inside,
          matching: find.byType(ExcludeSemantics),
        );
        expect(exclude, findsWidgets);
        expect(t.widget<ExcludeSemantics>(exclude.first).excluding, isTrue);
      },
    );
  }

  group('the pulse', () {
    testWidgets('runs on the long-press drawing while its step is shown', (
      t,
    ) async {
      await pumpPicture(t, TipPicture.longPress);
      await t.pump(const Duration(milliseconds: 300));
      expect(t.binding.transientCallbackCount, greaterThan(0));
    });

    testWidgets('does not run when its step is not shown', (t) async {
      await pumpPicture(t, TipPicture.longPress, active: false);
      await t.pump(const Duration(milliseconds: 300));
      expect(t.binding.transientCallbackCount, 0);
    });

    for (final picture in TipPicture.values.where(
      (p) => p != TipPicture.longPress,
    )) {
      testWidgets('never runs on ${picture.name}', (t) async {
        await pumpPicture(t, picture);
        await t.pump(const Duration(milliseconds: 300));
        expect(t.binding.transientCallbackCount, 0);
      });
    }

    testWidgets(
      'stops when the step is left and starts again when it comes back',
      (t) async {
        await pumpPicture(t, TipPicture.longPress);
        await t.pump(const Duration(milliseconds: 300));
        expect(t.binding.transientCallbackCount, greaterThan(0));
        await pumpPicture(t, TipPicture.longPress, active: false);
        await t.pump(const Duration(milliseconds: 300));
        expect(t.binding.transientCallbackCount, 0);
        await pumpPicture(t, TipPicture.longPress);
        await t.pump(const Duration(milliseconds: 300));
        expect(t.binding.transientCallbackCount, greaterThan(0));
      },
    );
  });
}
