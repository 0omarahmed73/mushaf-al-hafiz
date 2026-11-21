// The khatm dua is readable at every reading size and in both looks (spec FR-010 to FR-013; SC-005; User Story 3).
// The screen is pumped alone, with the real dua text and a real TextSizeSettings (in-memory database).
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ui/reading_text.dart';
import 'package:mushaf/khatm/dua_strings.dart';
import 'package:mushaf/khatm/dua_text.dart';
import 'package:mushaf/khatm/khatm_dua_screen.dart';
import 'package:mushaf/settings/text_size.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:provider/provider.dart';

import '../support/contrast_walk.dart';
import '../support/map_bundle.dart';

Finder key(String k) => find.byKey(ValueKey(k));

const looks = <(String, AppLook)>[
  ('Emerald & Gold', AppLook.emerald),
  ('Night Reader', AppLook.night),
];

/// The screen, pushed from a launcher the way the reader pushes it, at reading size [percent] and system text scale
/// [textScale].
Future<void> pumpDuaSized(
  WidgetTester t, {
  required AppLook look,
  int percent = 100,
  Size screen = const Size(412, 915),
  double textScale = 1.0,
}) async {
  t.view.physicalSize = screen;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  final size = TextSizeSettings(WirdRepository(db));
  addTearDown(() async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    size.dispose();
    await t.runAsync(db.close);
  });
  await t.runAsync(() => size.set(percent));
  await t.pumpWidget(
    DefaultAssetBundle(
      bundle: MapBundle({
        DuaText.assetPath: File(DuaText.assetPath).readAsStringSync(),
      }),
      child: ListenableProvider<TextSizeSettings?>.value(
        value: size,
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: buildAppTheme(look: look),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  key: const ValueKey('open'),
                  onPressed: () => Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const KhatmDuaScreen()),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await t.tap(key('open'));
  await t.pump();
  await t.pump(const Duration(milliseconds: 500));
}

double paragraphSize(WidgetTester t, int i) {
  final rich = t.widget<RichText>(
    find
        .descendant(of: key('khatm-text-$i'), matching: find.byType(RichText))
        .first,
  );
  return rich.text.style!.fontSize!;
}

void main() {
  group('the text follows the reading size', () {
    // 17 px is the Arabic reading style at 100% (feature 003); the dua uses it as it is.
    for (final (percent, expected) in [(80, 13.6), (100, 17.0), (150, 25.5)]) {
      testWidgets('at $percent% every paragraph is $expected px', (t) async {
        await pumpDuaSized(t, look: AppLook.emerald, percent: percent);
        expect(paragraphSize(t, 0), closeTo(expected, 0.01));
        expect(paragraphSize(t, 1), closeTo(expected, 0.01));
        expect(
          paragraphSize(t, 0),
          ReadingStyles(TextSize.factor(percent)).arabic.fontSize,
          reason: 'the same size the reading screens use',
        );
      });
    }
  });

  for (final (name, look) in looks) {
    group(name, () {
      for (final percent in [80, 100, 150]) {
        testWidgets('contrast: every text and icon is readable at $percent%', (
          t,
        ) async {
          await pumpDuaSized(t, look: look, percent: percent);
          expect(contrastIssues(t), isEmpty);
        });
      }

      testWidgets('320 dp wide with a 2x system font and the largest reading '
          'size: nothing overflows and «آمين» is reached by scrolling', (
        t,
      ) async {
        await pumpDuaSized(
          t,
          look: look,
          percent: 150,
          screen: const Size(320, 640),
          textScale: 2.0,
        );
        expect(t.takeException(), isNull);
        expect(
          t.getRect(key('khatm-amen')).bottom,
          greaterThan(640),
          reason: 'the text is longer than the screen: «آمين» is below it',
        );
        await t.ensureVisible(key('khatm-amen'));
        await t.pump();
        expect(t.takeException(), isNull);
        expect(t.getRect(key('khatm-amen')).bottom, lessThanOrEqualTo(640));
        expect(key('khatm-amen'), findsOneWidget);
        final amen = t.getRect(key('khatm-amen'));
        expect(amen.right, lessThanOrEqualTo(320));
        expect(amen.left, greaterThanOrEqualTo(0));
        expect(contrastIssues(t), isEmpty);
      });

      testWidgets('every target is at least 48 px', (t) async {
        await pumpDuaSized(t, look: look);
        final amen = t.getSize(key('khatm-amen'));
        expect(amen.height, greaterThanOrEqualTo(48));
        expect(amen.width, greaterThanOrEqualTo(48));
        final back = t.getSize(find.byType(BackButton));
        expect(back.height, greaterThanOrEqualTo(48));
        expect(back.width, greaterThanOrEqualTo(48));
      });
    });
  }

  group('accessibility', () {
    testWidgets(
      'the title is a heading, «آمين» and the back arrow are labelled '
      'buttons, and the text reads top to bottom',
      (t) async {
        final handle = t.ensureSemantics();
        await pumpDuaSized(t, look: AppLook.emerald);
        expect(
          t.getSemantics(find.text(kDuaTitle)),
          isSemantics(isHeader: true, label: kDuaTitle),
        );
        expect(
          t.getSemantics(key('khatm-amen')),
          isSemantics(isButton: true, hasTapAction: true, label: kDuaAmen),
        );
        expect(
          t.getSemantics(find.byType(BackButton)),
          isSemantics(isButton: true, hasTapAction: true, label: 'رجوع'),
        );
        final order = [
          t.getRect(find.text(kDuaTitle)).top,
          t.getRect(key('khatm-note')).top,
          t.getRect(key('khatm-text-0')).top,
          t.getRect(key('khatm-text-1')).top,
          t.getRect(key('khatm-amen')).top,
        ];
        expect(
          order,
          [...order]..sort(),
          reason: 'title, label, paragraphs, «آمين»',
        );
        handle.dispose();
      },
    );
  });
}
