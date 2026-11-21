// The «حجم الخط» row of Settings in both looks (feature 004, T032; spec FR-004, FR-012; contracts/ui.md): the title,
// the slider, the preview panel, the note and the reset button read the look; Emerald & Gold keeps the colours it
// had before this feature, and feature 003's sizes and behaviour do not change.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/settings/text_size_tile.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:provider/provider.dart';

import '../support/contrast_walk.dart';

Finder key(String k) => find.byKey(ValueKey(k));

Color? colorOf(WidgetTester t, Finder f) => t.widget<Text>(f).style?.color;

void main() {
  late AppDatabase db;
  late TextSizeSettings size;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    size = TextSizeSettings(WirdRepository(db));
  });
  tearDown(() async {
    size.dispose();
    await db.close();
  });

  Future<void> pump(WidgetTester t, AppLook look) => t.pumpWidget(
    ListenableProvider<TextSizeSettings?>.value(
      value: size,
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: buildAppTheme(look: look),
        home: Scaffold(body: ListView(children: const [TextSizeTile()])),
      ),
    ),
  );

  for (final look in [AppLook.emerald, AppLook.night]) {
    final name = identical(look, AppLook.night) ? 'Night' : 'Emerald';

    group('the size row in $name', () {
      testWidgets('title, value, mark, note and reset use the look', (t) async {
        await pump(t, look);
        expect(colorOf(t, key('text-size-title')), look.text);
        expect(colorOf(t, key('text-size-value')), look.accent);
        expect(colorOf(t, key('text-size-default-mark')), look.textSecondary);
        expect(colorOf(t, find.text(TextSizeTile.kNote)), look.textSecondary);
        final reset = t.widget<TextButton>(key('text-size-reset'));
        expect(reset.style!.foregroundColor!.resolve({}), look.accent);
      });

      testWidgets('the slider reads the look', (t) async {
        await pump(t, look);
        final theme = SliderTheme.of(t.element(key('text-size-slider')));
        expect(theme.activeTrackColor, look.accent);
        expect(theme.inactiveTrackColor, look.line);
        expect(theme.thumbColor, look.accent);
        expect(theme.activeTickMarkColor, look.background);
        expect(theme.inactiveTickMarkColor, look.ring);
      });

      testWidgets('the preview panel is a card of the look with its own ink', (
        t,
      ) async {
        await pump(t, look);
        final panel = t.widget<DecoratedBox>(
          find
              .ancestor(
                of: key('text-size-preview'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final decoration = panel.decoration as BoxDecoration;
        expect(decoration.color, look.cardFill);
        expect((decoration.border as Border).top.color, look.cardBorderStrong);
        expect(
          decoration.borderRadius,
          BorderRadius.circular(look.rowRadius(14)),
        );
        expect(colorOf(t, key('text-size-preview')), look.cardMuted);
        final ink = DefaultTextStyle.of(t.element(key('text-size-preview-ar')))
            .style
            .color;
        expect(ink, look.cardInk);
      });

      testWidgets('every text and icon of the row passes the contrast walk', (
        t,
      ) async {
        await pump(t, look);
        // At the default size «الحجم الافتراضي» is disabled, and disabled content needs no contrast (FR-012).
        await t.runAsync(() => size.set(120));
        await t.pumpAndSettle();
        expect(contrastIssues(t, within: find.byType(TextSizeTile)), isEmpty);
      });
    });
  }

  testWidgets(
    'feature 003 is unchanged: the same stops, sizes and reset in Night',
    (t) async {
      await pump(t, AppLook.night);
      expect(t.widget<Text>(key('text-size-value')).data, '100%');
      expect(t.widget<Text>(key('text-size-preview-ar')).style!.fontSize, 17);
      await t.runAsync(() => size.set(150));
      await t.pump();
      expect(t.widget<Text>(key('text-size-value')).data, '150%');
      expect(t.widget<Text>(key('text-size-preview-ar')).style!.fontSize, 25.5);
      expect(t.widget<Slider>(key('text-size-slider')).divisions, 7);
    },
  );
}
