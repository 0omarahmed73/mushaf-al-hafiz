// The tips card in both looks, on a phone and on the smallest phone with a 2x system font (feature 008, spec User Story 4,
// FR-010, FR-011, SC-004): no overflow, contrast, 48 px targets, what scrolls and what stays in view. The real fonts of the
// app are loaded, so the lines break as they do on the phone.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/onboarding/tip_steps.dart';
import 'package:mushaf/onboarding/tips_dialog.dart';
import 'package:mushaf/theme.dart';

import '../support/contrast_walk.dart';
import '../support/tips_harness.dart';

Future<void> loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      Future.value(
        ByteData.sublistView(Uint8List.fromList(File(file).readAsBytesSync())),
      ),
    );
  }
  await loader.load();
}

const looks = <(String, AppLook)>[
  ('Emerald & Gold', AppLook.emerald),
  ('Night Reader', AppLook.night),
];

/// A screen, and the system text scale it is tried with.
const screens = <(String, Size, double)>[
  ('412 x 915 at 1x', Size(412, 915), 1.0),
  ('320 x 640 at 2x', Size(320, 640), 2.0),
  ('640 x 360 landscape at 1x', Size(640, 360), 1.0),
  ('640 x 360 landscape at 2x', Size(640, 360), 2.0),
];

Finder get pageScroll => find.descendant(
  of: key('tips-pages'),
  matching: find.byWidgetPredicate(
    (w) => w is Scrollable && w.axis == Axis.vertical,
  ),
);

/// How far the current step can be scrolled.
double scrollExtent(WidgetTester t) =>
    t.state<ScrollableState>(pageScroll.first).position.maxScrollExtent;

void main() {
  setUpAll(() async {
    await loadFont('Cairo', [
      'assets/fonts/cairo/Cairo-Regular.ttf',
      'assets/fonts/cairo/Cairo-Medium.ttf',
      'assets/fonts/cairo/Cairo-SemiBold.ttf',
      'assets/fonts/cairo/Cairo-Bold.ttf',
    ]);
    await loadFont('ReemKufi', ['assets/fonts/reemkufi/ReemKufi.ttf']);
  });

  for (final (lookName, look) in looks) {
    for (final (screenName, size, scale) in screens) {
      group('$lookName, $screenName', () {
        for (var step = 0; step < kTipSteps.length; step++) {
          testWidgets(
            'step ${step + 1}: nothing overflows, contrast, targets, and the controls stay in view',
            (t) async {
              await pumpTipsDialog(
                t,
                look: look,
                screen: size,
                textScale: scale,
              );
              for (var i = 0; i < step; i++) {
                await tapNext(t);
              }
              expect(
                t.takeException(),
                isNull,
                reason: 'no overflow or other error',
              );

              // The card is on the screen, within the inset, and not taller than its limit.
              final card = t.getRect(key('tips-dialog'));
              expect(card.left, greaterThanOrEqualTo(0));
              expect(card.top, greaterThanOrEqualTo(0));
              expect(card.right, lessThanOrEqualTo(size.width + 0.01));
              expect(card.bottom, lessThanOrEqualTo(size.height + 0.01));
              expect(card.height, lessThanOrEqualTo(520 + 0.01));
              expect(card.height, lessThanOrEqualTo(size.height - 48 + 0.01));
              expect(card.width, lessThanOrEqualTo(440 + 0.01));

              // Every text is 4.5:1 and every icon 3:1 on what is behind it.
              final issues = contrastIssues(t, within: find.byType(TipsDialog));
              expect(issues, isEmpty, reason: issues.join('\n'));

              // The buttons: at least 48 x 48, on the card, reachable without scrolling.
              final buttons = step == kTipSteps.length - 1
                  ? [startButton]
                  : [skipButton, nextButton];
              for (final b in buttons) {
                final rect = t.getRect(b);
                expect(
                  rect.height,
                  greaterThanOrEqualTo(48 - 0.01),
                  reason: 'height of $b',
                );
                expect(
                  rect.width,
                  greaterThanOrEqualTo(48 - 0.01),
                  reason: 'width of $b',
                );
                expect(
                  card.contains(rect.topLeft) &&
                      card.contains(
                        rect.bottomRight - const Offset(0.01, 0.01),
                      ),
                  isTrue,
                  reason: '$b is inside the card $card: $rect',
                );
                expect(
                  b.hitTestable(),
                  findsOneWidget,
                  reason: '$b can be tapped',
                );
              }
              final dots = t.getRect(key('tips-dots'));
              expect(
                card.contains(dots.topLeft) &&
                    card.contains(dots.bottomRight - const Offset(0.01, 0.01)),
                isTrue,
              );

              // The content scrolls on its own: scrolled to its end, the last line of the text is in view, and the dots and
              // the buttons have not moved.
              final before = [for (final b in buttons) t.getRect(b), dots];
              final viewport = t.getRect(pageScroll.first);
              final extent = scrollExtent(t);
              if (extent > 0) {
                t
                    .state<ScrollableState>(pageScroll.first)
                    .position
                    .jumpTo(extent);
                await t.pump();
              }
              final body = t.getRect(key('tips-body-$step'));
              expect(
                body.bottom,
                lessThanOrEqualTo(viewport.bottom + 0.5),
                reason: 'the end of the text can be reached',
              );
              expect([
                for (final b in buttons) t.getRect(b),
                t.getRect(key('tips-dots')),
              ], before);
            },
          );
        }
      });
    }

    testWidgets('$lookName: at 320 x 640 with a 2x font the content scrolls', (
      t,
    ) async {
      await pumpTipsDialog(
        t,
        look: look,
        screen: const Size(320, 640),
        textScale: 2.0,
      );
      var scrolling = 0;
      for (var i = 0; i < kTipSteps.length; i++) {
        if (scrollExtent(t) > 0) scrolling++;
        if (i < kTipSteps.length - 1) await tapNext(t);
      }
      expect(
        scrolling,
        greaterThanOrEqualTo(5),
        reason: 'the long steps scroll instead of overflowing',
      );
    });

    testWidgets('$lookName: at 412 x 915 at 1x every title is one line', (
      t,
    ) async {
      await pumpTipsDialog(t, look: look);
      for (var i = 0; i < kTipSteps.length; i++) {
        final title = t.getSize(key('tips-step-title-$i'));
        expect(
          title.height,
          lessThan(40),
          reason: 'step ${i + 1}: ${kTipSteps[i].title}',
        );
        if (i < kTipSteps.length - 1) await tapNext(t);
      }
    });

    testWidgets(
      '$lookName: turning the phone while step 3 is shown keeps step 3',
      (t) async {
        await pumpTipsDialog(t, look: look);
        await tapNext(t);
        await tapNext(t);
        expect(currentStep(t), 2);
        t.view.physicalSize = const Size(915, 412);
        await settleTips(t);
        expect(currentStep(t), 2);
        expect(t.takeException(), isNull);
        expect(
          t.getRect(key('tips-dialog')).bottom,
          lessThanOrEqualTo(412 + 0.01),
        );
        expect(nextButton.hitTestable(), findsOneWidget);
      },
    );

    testWidgets('$lookName: the card is in the look\'s colours', (t) async {
      await pumpTipsDialog(t, look: look);
      final dialog = t.widget<Dialog>(find.byType(Dialog));
      expect(dialog.backgroundColor, look.barFill);
      final title = t.widget<Text>(key('tips-step-title-0'));
      expect(title.style!.color, look.heading);
      final body = t.widget<Text>(key('tips-body-0'));
      expect(body.style!.color, look.text);
    });
  }
}
