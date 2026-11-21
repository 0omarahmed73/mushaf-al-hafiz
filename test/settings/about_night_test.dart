// «عن التطبيق» in both looks (spec FR-004, FR-006, FR-012, FR-014, FR-017; contracts/ui.md about). The credits, links and
// texts are the existing test's business and do not change; only colours and shapes do.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/look/wird_marker.dart';
import 'package:mushaf/settings/about_screen.dart';
import 'package:mushaf/theme.dart';

import '../support/contrast_walk.dart';
import '../support/look_harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

/// A window tall enough to build every row of the lazy list.
const tall = Size(412, 3600);

Future<void> open(
  WidgetTester t,
  LookChoice choice, {
  Size screen = tall,
  double textScale = 1.0,
}) async {
  final a = await LookApp.create(t, choice: choice);
  await a.show(
    t,
    const AboutScreen(),
    defaults: false,
    screen: screen,
    textScale: textScale,
  );
}

BoxDecoration decoration(WidgetTester t, String k) =>
    t.widget<DecoratedBox>(key(k)).decoration as BoxDecoration;

Color? colorOf(WidgetTester t, String text) =>
    t.widget<Text>(find.text(text)).style?.color;

void main() {
  group('Emerald stays as it was', () {
    testWidgets(
      'ivory dedication in a ring, dark developer card, gold accents',
      (t) async {
        await open(t, LookChoice.emerald);
        final outer = decoration(t, 'dedication');
        expect((outer.border as Border).top.color, AppColors.ring);
        expect(outer.borderRadius, BorderRadius.circular(19));
        final inner =
            t
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: key('dedication'),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        expect(inner.color, AppColors.paper);
        expect((inner.border as Border).top.color, AppColors.goldDark);
        expect((inner.border as Border).top.width, 2);
        expect(inner.borderRadius, BorderRadius.circular(16));
        final developer = t.widget<Material>(key('developer'));
        expect(developer.color, AppColors.greenDeep);
        expect(
          (developer.shape as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(18),
        );
        expect(colorOf(t, AboutScreen.appName), AppColors.gold);
        expect(colorOf(t, AboutScreen.developerName), AppColors.ivory);
        expect(colorOf(t, AboutScreen.developerRole), AppColors.gold);
        expect(colorOf(t, AboutScreen.dedicationDua), const Color(0xFF2C4A3F));
        final notModified = decoration(t, 'text-not-modified');
        expect(notModified.borderRadius, BorderRadius.circular(14));
        expect((notModified.border as Border).top.color, AppColors.goldDark);
        // The credits keep their rotated squares in gold-dark.
        final markers = t.widgetList<WirdMarker>(find.byType(WirdMarker));
        expect(markers, isNotEmpty);
        expect(markers.every((m) => m.color == AppColors.goldDark), isTrue);
        expect(
          find.descendant(
            of: find.byType(WirdMarker),
            matching: find.byType(Transform),
          ),
          findsWidgets,
        );
      },
    );
  });

  group('Night', () {
    testWidgets(
      'a charcoal dedication, charcoal developer card with its hairline, teal accents',
      (t) async {
        await open(t, LookChoice.night);
        final outer = decoration(t, 'dedication');
        expect((outer.border as Border).top.color, AppLook.night.ring);
        expect(outer.borderRadius, BorderRadius.circular(23));
        final inner =
            t
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: key('dedication'),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        expect(inner.color, AppLook.night.cardFill);
        expect(
          (inner.border as Border).top.color,
          AppLook.night.cardBorderStrong,
        );
        expect((inner.border as Border).top.width, 1);
        expect(inner.borderRadius, BorderRadius.circular(20));
        final developer = t.widget<Material>(key('developer'));
        expect(developer.color, AppLook.night.barFill);
        expect(
          (developer.shape as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(20),
        );
        expect(colorOf(t, AboutScreen.appName), AppLook.night.heading);
        expect(colorOf(t, AboutScreen.developerName), AppLook.night.text);
        expect(colorOf(t, AboutScreen.developerRole), AppLook.night.accent);
        expect(colorOf(t, AboutScreen.dedicationDua), AppLook.night.cardMuted);
        expect(colorOf(t, AboutScreen.dedicationFor), AppLook.night.doneFill);
        final notModified = decoration(t, 'text-not-modified');
        expect(notModified.borderRadius, BorderRadius.circular(20));
        expect(
          (notModified.border as Border).top.color,
          AppLook.night.controlBorder,
        );
        // The credits' markers are dots now.
        expect(
          find.descendant(
            of: find.byType(WirdMarker),
            matching: find.byType(Transform),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('no ivory or bright block anywhere', (t) async {
      await open(t, LookChoice.night);
      final bright = [
        for (final d in t.widgetList<DecoratedBox>(find.byType(DecoratedBox)))
          if ((d.decoration as BoxDecoration).color case final c?
              when c.computeLuminance() > 0.5)
            c,
        for (final c in [
          for (final m in t.widgetList<Material>(find.byType(Material)))
            m.color,
        ])
          if (c != null && c.computeLuminance() > 0.5) c,
      ];
      expect(bright, isEmpty);
    });

    testWidgets('every text and icon of the whole screen meets the contrast', (
      t,
    ) async {
      await open(t, LookChoice.night);
      final issues = contrastIssues(t);
      expect(issues, isEmpty, reason: issues.join('\n'));
    });
  });

  for (final look in LookChoice.values) {
    testWidgets(
      '${look.name}: nothing overflows on 320 dp with a 2x font, down to the last line',
      (t) async {
        await open(t, look, screen: const Size(320, 640), textScale: 2.0);
        expect(t.takeException(), isNull);
        await t.dragUntilVisible(
          find.textContaining('تطبيق مجاني غير تجاري'),
          find.byType(ListView),
          const Offset(0, -200),
        );
        expect(t.takeException(), isNull);
      },
    );
  }
}
