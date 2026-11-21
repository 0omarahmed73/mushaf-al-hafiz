// The marker of a wird on a card: its colour, lifted on a dark card so every palette colour can be seen, and its
// shape (spec FR-013, SC-005; data-model.md "Wird marker colour"; research D6).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/contrast.dart';
import 'package:mushaf/look/wird_marker.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/wird_palette.dart';

void main() {
  final palette = [for (final c in wirdPalette) Color(c)];

  group('markerColor', () {
    test('Emerald shows the palette colour exactly as chosen', () {
      for (final c in palette) {
        expect(markerColor(AppLook.emerald, c), c);
      }
    });

    test(
      'Night: every one of the 8 palette colours reaches 3:1 on the card',
      () {
        for (final c in palette) {
          final shown = markerColor(AppLook.night, c);
          expect(
            contrastRatio(shown, AppLook.night.cardFill),
            greaterThanOrEqualTo(3.0),
            reason: '#${c.toARGB32().toRadixString(16)}',
          );
        }
      },
    );

    test('Night: colours that already pass are untouched, the three that fail are lightened', () {
      final unchanged = palette
          .where((c) => markerColor(AppLook.night, c) == c)
          .length;
      expect(
        unchanged,
        5,
        reason: 'green, blue, red, orange and teal already pass',
      );
      for (final c in [
        const Color(0xFF6A1B9A),
        const Color(0xFF4E342E),
        const Color(0xFF37474F),
      ]) {
        final shown = markerColor(AppLook.night, c);
        expect(shown, isNot(c));
        expect(
          HSLColor.fromColor(shown).lightness,
          greaterThan(HSLColor.fromColor(c).lightness),
        );
        expect(
          HSLColor.fromColor(shown).hue,
          closeTo(HSLColor.fromColor(c).hue, 2.0),
          reason: 'only the lightness moves',
        );
      }
    });

    test('Night: the eight markers are still eight different colours', () {
      final shown = {
        for (final c in palette) markerColor(AppLook.night, c).toARGB32(),
      };
      expect(shown, hasLength(8));
    });
  });

  group('WirdMarker', () {
    Future<void> pump(WidgetTester t, AppLook look, Color color) =>
        t.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(look: look),
            home: Scaffold(
              body: Center(child: WirdMarker(color: color)),
            ),
          ),
        );

    testWidgets(
      'Emerald: the rotated square of today, 10 px, in the colour chosen',
      (t) async {
        await pump(t, AppLook.emerald, const Color(0xFF6A1B9A));
        expect(
          find.descendant(
            of: find.byType(WirdMarker),
            matching: find.byType(Transform),
          ),
          findsOneWidget,
        );
        final box = t.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(WirdMarker),
            matching: find.byType(DecoratedBox),
          ),
        );
        expect(
          (box.decoration as BoxDecoration).color,
          const Color(0xFF6A1B9A),
        );
        expect(
          t.getSize(
            find
                .descendant(
                  of: find.byType(WirdMarker),
                  matching: find.byType(SizedBox),
                )
                .first,
          ),
          const Size(10, 10),
        );
      },
    );

    testWidgets(
      'Night: a round dot of 8 px in the lifted colour, no rotation',
      (t) async {
        const purple = Color(0xFF6A1B9A);
        await pump(t, AppLook.night, purple);
        expect(
          find.descendant(
            of: find.byType(WirdMarker),
            matching: find.byType(Transform),
          ),
          findsNothing,
        );
        final box = t.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(WirdMarker),
            matching: find.byType(DecoratedBox),
          ),
        );
        final deco = box.decoration as BoxDecoration;
        expect(deco.shape, BoxShape.circle);
        expect(deco.color, markerColor(AppLook.night, purple));
        expect(t.getSize(find.byType(WirdMarker)), const Size(8, 8));
      },
    );
  });
}
