// The wird form in both looks (spec FR-004, FR-005, FR-012, FR-013, FR-014; contracts/ui.md «ورد جديد»).
// Emerald keeps today's gold choices and swatches; Night wears the teal ones and shows each swatch in the colour the
// wird's marker will have, so what the owner picks is what the list shows.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/contrast.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/look/wird_marker.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/wird_form_screen.dart';
import 'package:mushaf/wirds/wird_palette.dart';

import '../support/contrast_walk.dart';
import '../support/look_harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

/// The Material a `_Choice` draws its pill on.
Material choiceMaterial(WidgetTester t, String k) => t.widget<Material>(
  find.descendant(of: key(k), matching: find.byType(Material)).first,
);

BoxDecoration swatch(WidgetTester t, int i) {
  final boxes = find.descendant(
    of: key('color-$i'),
    matching: find.byType(DecoratedBox),
  );
  return t.widget<DecoratedBox>(boxes.first).decoration as BoxDecoration;
}

void main() {
  group('Emerald stays as it was', () {
    testWidgets('gold choice pills, gold date button and stored swatches', (
      t,
    ) async {
      final a = await LookApp.create(t);
      await a.show(t, const WirdFormScreen(), defaults: false);
      final chosen = choiceMaterial(t, 'type-reading');
      expect(chosen.color, AppColors.gold);
      expect(
        (chosen.shape as StadiumBorder).side.color,
        AppColors.gold,
        reason: 'the chosen type',
      );
      final other = choiceMaterial(t, 'type-qiyam');
      expect(other.color, Colors.transparent);
      expect((other.shape as StadiumBorder).side.color, AppColors.goldDark);
      for (var i = 0; i < wirdPalette.length; i++) {
        expect(
          swatch(t, i).color,
          Color(wirdPalette[i]),
          reason: 'swatch $i is the stored colour',
        );
      }
      // The selected swatch has a gold ring and a white tick.
      final ring = swatch(t, 0).border as Border;
      expect(ring.top.color, AppColors.gold);
      expect(ring.top.width, 3);
      final tick = t.widget<Icon>(
        find.descendant(of: key('color-0'), matching: find.byType(Icon)),
      );
      expect(tick.color, Colors.white);
    });

    testWidgets('every palette colour keeps a white tick', (t) async {
      for (final c in wirdPalette) {
        expect(
          contrastRatio(Colors.white, Color(c)),
          greaterThanOrEqualTo(3.0),
          reason: '0x${c.toRadixString(16)}',
        );
      }
    });
  });

  group('Night', () {
    testWidgets('the chosen pills are teal, the others have a control border', (
      t,
    ) async {
      final a = await LookApp.create(t, choice: LookChoice.night);
      await a.show(t, const WirdFormScreen(), defaults: false);
      final chosen = choiceMaterial(t, 'type-reading');
      expect(chosen.color, AppLook.night.primaryFill);
      expect(
        (chosen.shape as StadiumBorder).side.color,
        AppLook.night.primaryFill,
      );
      final other = choiceMaterial(t, 'type-qiyam');
      expect(other.color, Colors.transparent);
      expect(
        (other.shape as StadiumBorder).side.color,
        AppLook.night.controlBorder,
      );
    });

    testWidgets(
      'every swatch shows the colour the marker will have, 3:1 on the page',
      (t) async {
        final a = await LookApp.create(t, choice: LookChoice.night);
        await a.show(t, const WirdFormScreen(), defaults: false);
        for (var i = 0; i < wirdPalette.length; i++) {
          final shown = swatch(t, i).color!;
          expect(
            shown,
            markerColor(AppLook.night, Color(wirdPalette[i])),
            reason: 'swatch $i',
          );
          expect(
            contrastRatio(shown, AppLook.night.background),
            greaterThanOrEqualTo(3.0),
            reason: 'swatch $i on the page',
          );
        }
        // The choice itself is still stored as the palette colour.
        final ring = swatch(t, 0).border as Border;
        expect(ring.top.color, AppLook.night.accent);
        expect(ring.top.width, 3);
      },
    );

    testWidgets(
      'the date button, the time and the labels are in Night colours',
      (t) async {
        final a = await LookApp.create(t, choice: LookChoice.night);
        await a.show(t, const WirdFormScreen(), defaults: false);
        await t.tap(key('amount-date'));
        await t.pump();
        final date = t.widget<OutlinedButton>(key('wird-target-date'));
        expect(date.style!.foregroundColor!.resolve({}), AppLook.night.accent);
        expect(
          date.style!.side!.resolve({})!.color,
          AppLook.night.controlBorder,
        );
        final labelColors = <Color?>{
          for (final w in t.widgetList<Text>(find.text('النوع')))
            w.style?.color,
        };
        expect(labelColors, {AppLook.night.textSecondary});
      },
    );

    testWidgets('every text and icon of the form meets the contrast', (
      t,
    ) async {
      final a = await LookApp.create(t, choice: LookChoice.night);
      await a.show(t, const WirdFormScreen(), defaults: false);
      await t.tap(key('amount-date'));
      await t.pump();
      final issues = contrastIssues(t);
      expect(issues, isEmpty, reason: issues.join('\n'));
    });
  });

  for (final choice in LookChoice.values) {
    testWidgets(
      '${choice.name}: nothing overflows on a 320 dp window with a 2x system font',
      (t) async {
        final a = await LookApp.create(t, choice: choice);
        await a.show(
          t,
          const WirdFormScreen(),
          defaults: false,
          screen: const Size(320, 640),
          textScale: 2.0,
        );
        expect(t.takeException(), isNull);
        // The list is lazy: scroll to the save button at the end, which lays out every row on the way.
        await t.dragUntilVisible(
          key('wird-save'),
          find.byType(ListView),
          const Offset(0, -200),
        );
        expect(key('wird-save'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
}
