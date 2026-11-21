// «أوراد» and the today panel in both looks (spec FR-004, FR-005, FR-006, FR-012, FR-013, FR-014; contracts/ui.md
// «أوراد»). Emerald must stay as before; Night wears the design's shapes and colours.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/contrast.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/look/wird_marker.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/wirds_screen.dart';

import '../support/contrast_walk.dart';
import '../support/look_harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

BoxDecoration cardDecoration(WidgetTester t) =>
    t.widget<DecoratedBox>(key('today-card')).decoration as BoxDecoration;

void main() {
  group('Emerald stays as it was', () {
    testWidgets('today card, wird cards, add buttons and tags are today\'s', (
      t,
    ) async {
      final a = await LookApp.create(t);
      await a.show(t, const WirdsScreen());
      final deco = cardDecoration(t);
      expect(deco.color, AppColors.paper);
      expect((deco.border as Border).top.color, AppColors.goldDark);
      expect((deco.border as Border).top.width, 2);
      expect(deco.borderRadius, BorderRadius.circular(16));
      // The big add button is the filled gold one, the small one a rounded square.
      expect(key('wird-add'), findsOneWidget);
      expect(
        find.descendant(
          of: key('wird-add'),
          matching: find.byType(FilledButton),
        ),
        findsNothing,
      );
      expect(t.widget(key('wird-add')), isA<FilledButton>());
      final top = t.widget<IconButton>(key('wird-add-top'));
      expect(top.style!.shape!.resolve({}), isA<RoundedRectangleBorder>());
      expect(top.style!.side!.resolve({})!.width, 1.5);
      // The markers are rotated squares.
      expect(
        find.descendant(
          of: find.byType(WirdMarker),
          matching: find.byType(Transform),
        ),
        findsWidgets,
      );
    });
  });

  group('Night', () {
    testWidgets(
      'the screen is on the near-black background, today card on charcoal with a hairline and radius 20',
      (t) async {
        final a = await LookApp.create(t, choice: LookChoice.night);
        await a.show(t, const WirdsScreen());
        expect(
          Theme.of(t.element(find.byType(Scaffold))).scaffoldBackgroundColor,
          AppLook.night.background,
        );
        final deco = cardDecoration(t);
        expect(deco.color, AppLook.night.cardFill);
        expect(
          (deco.border as Border).top.color,
          AppLook.night.cardBorderStrong,
        );
        expect((deco.border as Border).top.width, 1);
        expect(deco.borderRadius, BorderRadius.circular(20));
      },
    );

    testWidgets(
      'the add button is a 44 px circle with a control border, the big one an outlined pill',
      (t) async {
        final a = await LookApp.create(t, choice: LookChoice.night);
        await a.show(t, const WirdsScreen());
        final top = t.widget<IconButton>(key('wird-add-top'));
        expect(top.style!.shape!.resolve({}), isA<CircleBorder>());
        expect(
          top.style!.side!.resolve({})!.color,
          AppLook.night.controlBorder,
        );
        expect(t.getSize(key('wird-add-top')).width, greaterThanOrEqualTo(44));
        expect(t.widget(key('wird-add')), isA<OutlinedButton>());
        final outlined = t.widget<OutlinedButton>(key('wird-add'));
        expect(
          outlined.style!.side!.resolve({})!.color,
          AppLook.night.controlBorder,
        );
        expect(outlined.style!.shape!.resolve({}), isA<StadiumBorder>());
        expect(t.getSize(key('wird-add')).height, greaterThanOrEqualTo(52));
      },
    );

    testWidgets(
      'wirds have dot markers, the active one is outlined in teal and tagged «النشط»',
      (t) async {
        final a = await LookApp.create(t, choice: LookChoice.night);
        await a.show(t, const WirdsScreen());
        expect(find.byType(WirdMarker), findsWidgets);
        expect(
          find.descendant(
            of: find.byType(WirdMarker),
            matching: find.byType(Transform),
          ),
          findsNothing,
          reason: 'no rotated squares in Night',
        );
        expect(find.text('النشط'), findsOneWidget);
        final activeCard = find
            .ancestor(of: find.text('النشط'), matching: find.byType(Material))
            .first;
        final shape =
            t.widget<Material>(activeCard).shape as RoundedRectangleBorder;
        expect(shape.side.color, AppLook.night.cardBorderActive);
        expect(shape.side.width, 1);
        expect(shape.borderRadius, BorderRadius.circular(20));
        // The tag is an outlined pill in the accent colour, not a filled block.
        final tag = t.widget<DecoratedBox>(
          find
              .ancestor(
                of: find.text('النشط'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final deco = tag.decoration as BoxDecoration;
        expect(deco.borderRadius, BorderRadius.circular(999));
        expect(deco.color, isNull);
        expect(
          (deco.border as Border).top.color,
          AppLook.night.cardBorderActive,
        );
      },
    );

    testWidgets(
      'the «تم» button is a teal pill and a done row shows a teal tick',
      (t) async {
        final a = await LookApp.create(t, choice: LookChoice.night);
        await a.show(t, const WirdsScreen());
        final done = find.byWidgetPredicate(
          (w) => w is FilledButton && w.key.toString().contains('today-done'),
        );
        expect(done, findsWidgets);
        final button = t.widget<FilledButton>(done.first);
        expect(
          button.style!.backgroundColor!.resolve({}),
          AppLook.night.doneFill,
        );
        expect(
          button.style!.foregroundColor!.resolve({}),
          AppLook.night.onDone,
        );
        expect(button.style!.shape!.resolve({}), isA<RoundedRectangleBorder>());
        await t.tap(done.first);
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
        final tick = find.byWidgetPredicate(
          (w) => w.key.toString().contains('today-tick'),
        );
        expect(tick, findsWidgets);
        final tickIcon = t.widget<Icon>(
          find.descendant(of: tick.first, matching: find.byType(Icon)),
        );
        expect(tickIcon.color, AppLook.night.doneFill);
      },
    );

    testWidgets(
      'no ivory or bright block, every text and icon meets the contrast',
      (t) async {
        final a = await LookApp.create(t, choice: LookChoice.night);
        await a.show(t, const WirdsScreen());
        final bright = <Color>[];
        for (final d in t.widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
          final c = (d.decoration as BoxDecoration?)?.color;
          if (c != null && c.computeLuminance() > 0.5) bright.add(c);
        }
        expect(bright, isEmpty);
        expect(
          contrastIssues(t),
          isEmpty,
          reason: contrastIssues(t).join('\n'),
        );
      },
    );
  });

  for (final choice in LookChoice.values) {
    testWidgets(
      '${choice.name}: nothing overflows on a 320 dp window with a 2x system font',
      (t) async {
        final a = await LookApp.create(t, choice: choice);
        await a.show(
          t,
          const WirdsScreen(),
          screen: const Size(320, 640),
          textScale: 2.0,
        );
        expect(t.takeException(), isNull);
        expect(key('wird-add-top'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'the marker colours of the palette are lifted on a Night card only',
    (t) async {
      final a = await LookApp.create(t, choice: LookChoice.night);
      await a.show(t, const WirdsScreen());
      final dots = find.descendant(
        of: find.byType(WirdMarker),
        matching: find.byType(DecoratedBox),
      );
      expect(dots, findsWidgets);
      for (final d in t.widgetList<DecoratedBox>(dots)) {
        final c = (d.decoration as BoxDecoration).color!;
        expect(
          contrastRatio(c, AppLook.night.cardFill),
          greaterThanOrEqualTo(3.0),
        );
      }
    },
  );
}
