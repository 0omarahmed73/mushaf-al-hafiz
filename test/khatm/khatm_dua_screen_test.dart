// The khatm dua screen (spec FR-009, FR-010, FR-011, FR-012, FR-019; contracts/ui.md «The screen»). It is pumped
// alone, opened from a launcher button the way the reader opens it, with a bundle that holds the real dua text.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/khatm/dua_strings.dart';
import 'package:mushaf/khatm/dua_text.dart';
import 'package:mushaf/khatm/khatm_dua_screen.dart';
import 'package:mushaf/mushaf/mushaf_page.dart' show kQuranFont;
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/theme.dart';
import 'package:provider/provider.dart';

import '../support/map_bundle.dart';

Finder key(String k) => find.byKey(ValueKey(k));

/// The dua as the file holds it.
String realFile() => File(DuaText.assetPath).readAsStringSync();

class Opened {
  Object? result = 'not closed';
  bool get closed => result != 'not closed';
}

/// A launcher whose button pushes the screen and records what it pops with.
Future<Opened> pumpDua(
  WidgetTester t, {
  AppLook look = AppLook.emerald,
  AssetBundle? bundle,
  Size screen = const Size(412, 915),
  double textScale = 1.0,
}) async {
  t.view.physicalSize = screen;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final opened = Opened();
  await t.pumpWidget(
    DefaultAssetBundle(
      bundle: bundle ?? MapBundle({DuaText.assetPath: realFile()}),
      child: ListenableProvider<TextSizeSettings?>.value(
        value: null,
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
                  onPressed: () async {
                    opened.result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const KhatmDuaScreen()),
                    );
                    opened.result ??= 'back';
                  },
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
  return opened;
}

BoxDecoration panelDecoration(WidgetTester t) =>
    t.widget<DecoratedBox>(key('khatm-panel')).decoration as BoxDecoration;

TextStyle? textStyleOf(WidgetTester t, Finder f) {
  final rich = t.widget<RichText>(
    find.descendant(of: f, matching: find.byType(RichText)).first,
  );
  return rich.text.style;
}

void main() {
  group('content', () {
    testWidgets('title, label, the dua in one panel, «آمين» below it', (
      t,
    ) async {
      await pumpDua(t);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(kDuaTitle),
        ),
        findsOneWidget,
      );
      expect(find.text(kDuaNote), findsOneWidget);
      expect(find.text(kDuaAmen), findsOneWidget);
      final dua = DuaText.parse(realFile());
      for (var i = 0; i < dua.paragraphs.length; i++) {
        expect(
          t.widget<Text>(key('khatm-text-$i')).data,
          dua.paragraphs[i],
          reason: 'paragraph $i is shown as the file has it',
        );
      }
      expect(key('khatm-text-${dua.paragraphs.length}'), findsNothing);
      expect(
        t.getBottomLeft(key('khatm-note')).dy,
        lessThanOrEqualTo(t.getTopLeft(key('khatm-panel')).dy),
        reason: 'the label is above the dua',
      );
      expect(
        t.getBottomLeft(key('khatm-panel')).dy,
        lessThanOrEqualTo(t.getTopLeft(key('khatm-amen')).dy),
        reason: '«آمين» is under the dua',
      );
      expect(t.getSize(key('khatm-amen')).height, greaterThanOrEqualTo(52));
    });

    testWidgets('«آمين» is the last item of the scrolling content', (t) async {
      await pumpDua(t);
      final amen = t.getBottomLeft(key('khatm-amen')).dy;
      final scroll = find.descendant(
        of: key('khatm-scroll'),
        matching: find.byType(RichText),
      );
      expect(scroll, findsWidgets);
      for (final element in scroll.evaluate()) {
        final box = element.renderObject! as RenderBox;
        final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
        expect(bottom, lessThanOrEqualTo(amen + 0.5));
      }
      expect(
        find.ancestor(of: key('khatm-amen'), matching: key('khatm-scroll')),
        findsOneWidget,
        reason: 'it is inside the same scrollable as the text',
      );
    });

    testWidgets('the dua is in the interface font, never the Quran font', (
      t,
    ) async {
      await pumpDua(t);
      final style = textStyleOf(t, key('khatm-text-0'))!;
      expect(style.fontFamily, kUiFont);
      expect(style.fontFamily, isNot(kQuranFont));
      expect(style.fontFamily, isNot(startsWith('QCF')));
      final note = textStyleOf(t, key('khatm-note'))!;
      expect(note.fontFamily, kUiFont);
    });
  });

  for (final look in [AppLook.emerald, AppLook.night]) {
    final name = look == AppLook.emerald ? 'Emerald' : 'Night';
    testWidgets('$name: the panel is in the card colours of the look', (
      t,
    ) async {
      await pumpDua(t, look: look);
      final d = panelDecoration(t);
      expect(d.color, look.cardFill);
      expect((d.border! as Border).top.color, look.cardBorderStrong);
      expect(d.borderRadius, BorderRadius.circular(look.rowRadius(14)));
      expect(textStyleOf(t, key('khatm-text-0'))!.color, look.cardInk);
      expect(textStyleOf(t, key('khatm-note'))!.color, look.textSecondary);
    });
  }

  group('closing', () {
    testWidgets('«آمين» closes the screen and answers true', (t) async {
      final opened = await pumpDua(t);
      await t.ensureVisible(key('khatm-amen'));
      await t.pump();
      await t.tap(key('khatm-amen'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(opened.result, true);
      expect(key('khatm-amen'), findsNothing);
    });

    testWidgets('the back arrow closes the screen with no answer', (t) async {
      final opened = await pumpDua(t);
      await t.tap(find.byType(BackButton));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(opened.result, 'back');
      expect(key('khatm-amen'), findsNothing);
    });
  });

  group('an unreadable text (FR-019)', () {
    testWidgets(
      'shows the message instead of the dua and «آمين» and back still work',
      (t) async {
        final opened = await pumpDua(t, bundle: MapBundle({}));
        expect(find.text(kDuaTitle), findsOneWidget);
        expect(find.text(kDuaNote), findsOneWidget);
        expect(find.text(kDuaUnavailable), findsOneWidget);
        expect(key('khatm-unavailable'), findsOneWidget);
        expect(key('khatm-panel'), findsNothing);
        await t.tap(key('khatm-amen'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
        expect(opened.result, true);
      },
    );

    testWidgets('back works too', (t) async {
      final opened = await pumpDua(t, bundle: MapBundle({}));
      await t.tap(find.byType(BackButton));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(opened.result, 'back');
    });

    testWidgets('an empty file is the same as a missing one', (t) async {
      await pumpDua(t, bundle: MapBundle({DuaText.assetPath: '\n'}));
      expect(key('khatm-unavailable'), findsOneWidget);
    });
  });
}
