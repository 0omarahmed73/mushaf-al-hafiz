// One large-ayah screen (feature 015, research D1, D2, D9; contracts/ui.md; SC-002, SC-005).
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/large_ayah/large_ayah_screen.dart';
import 'package:mushaf/large_ayah/large_ayah_strings.dart';
import 'package:mushaf/large_ayah/page_screens.dart';
import 'package:mushaf/large_ayah/screen_layout.dart';
import 'package:mushaf/large_ayah/word_measurer.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_page.dart';
import 'package:mushaf/mushaf/mushaf_page_card.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/page_font_loader.dart';
import 'package:mushaf/mushaf/page_look.dart';

import '../support/contrast_walk.dart';

late MushafRepository mushaf;
late PageFontLoader fonts;
late WordMeasurer measurer;
late MushafMeta meta;

Future<void> _ui(WidgetTester t) async {
  await t.runAsync(() async {
    for (final (family, asset) in [
      (kTitleFont, 'assets/fonts/reemkufi/ReemKufi.ttf'),
      (kQuranFont, 'assets/fonts/amiri/AmiriQuran.ttf'),
    ]) {
      final l = FontLoader(family)..addFont(rootBundle.load(asset));
      await l.load();
    }
  });
}

Future<List<LargeScreen>> _screens(WidgetTester t, int page, LargeGeometry g, {int count = 1}) async => (await t
    .runAsync(() => PageScreens(mushaf: mushaf, measurer: measurer, geometry: g, count: count).screensOf(page)))!;

Future<void> _pump(WidgetTester t, Size size, Widget child, {double textScale = 1}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
}

Widget _screen(LargeScreen s, LargeGeometry g, {PageLook look = PageLook.screen}) => SizedBox(
  width: g.width,
  height: g.height,
  child: LargeAyahScreen(screen: s, meta: meta, geometry: g, look: look),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    mushaf = MushafRepository(rootBundle);
    fonts = PageFontLoader();
    measurer = WordMeasurer(fonts);
  });

  Future<void> loadMeta(WidgetTester t) async {
    meta = (await t.runAsync(mushaf.loadMeta))!;
    await _ui(t);
  }

  testWidgets('each word is its glyph in its page font, keyed lw<id>, with the header', (t) async {
    await loadMeta(t);
    final g = LargeGeometry(width: 360, height: 700, factor: 2.0);
    final s = (await _screens(t, 2, g)).first;
    await _pump(t, const Size(360, 700), _screen(s, g));
    for (final w in s.words) {
      final text = t.widget<Text>(find.byKey(ValueKey('lw${w.id}')));
      expect(text.data, w.glyph);
      expect(text.style!.fontFamily, 'qpc_p2');
      expect(text.style!.fontSize, g.fontSize);
    }
    expect(find.text(LargeAyahStrings.header(surahName: 'البقرة', first: 1, last: 1, page: 2)), findsOneWidget);
    expect(find.text('سورة البقرة'), findsOneWidget, reason: 'the opening title of Al-Baqarah');
    expect(find.text(kBasmallah), findsOneWidget);
  });

  testWidgets('SC-002: at 360 dp and step 1 the letters are at least twice the Mushaf page\'s at 100 %', (t) async {
    await loadMeta(t);
    final page = (await t.runAsync(() => mushaf.loadPage(50)))!;
    final family = (await t.runAsync(() => fonts.ensure(50)))!;
    await _pump(t, const Size(360, 640), MushafPageCard(data: page, meta: meta, fontFamily: family));
    final mushafSize = t
        .widget<Text>(find.byKey(ValueKey('w${page.lines.firstWhere((l) => l.words.isNotEmpty).words.first.id}')))
        .style!
        .fontSize!;
    final g = LargeGeometry(width: 360, height: 640, factor: 2.0);
    expect(g.fontSize, greaterThanOrEqualTo(2 * mushafSize));
  });

  testWidgets('a system text scale of 2 changes nothing', (t) async {
    await loadMeta(t);
    final g = LargeGeometry(width: 360, height: 700, factor: 2.0);
    final s = (await _screens(t, 3, g)).first;
    await _pump(t, const Size(360, 700), _screen(s, g), textScale: 2);
    final rich = t.widget<RichText>(
      find.descendant(of: find.byKey(ValueKey('lw${s.words.first.id}')), matching: find.byType(RichText)),
    );
    expect(rich.textScaler, TextScaler.noScaling);
  });

  for (final (label, size) in [('320 dp portrait', const Size(320, 640)), ('landscape', const Size(720, 360))]) {
    testWidgets('SC-005: 2:282 on page 48 at $label: split, «تتبع» on all but the last, no overflow, no scrolling', (
      t,
    ) async {
      await loadMeta(t);
      for (final factor in [2.0, 3.0]) {
        final g = LargeGeometry(width: size.width, height: size.height, factor: factor);
        final screens = await _screens(t, 48, g, count: 3);
        expect(screens.length, greaterThan(1));
        for (var i = 0; i < screens.length; i++) {
          await _pump(t, size, _screen(screens[i], g));
          expect(t.takeException(), isNull, reason: 'no overflow on screen $i at x$factor');
          expect(find.byType(Scrollable), findsNothing);
          expect(find.text(LargeAyahStrings.continues), i < screens.length - 1 ? findsOneWidget : findsNothing);
          for (final w in screens[i].words) {
            final r = t.getRect(find.byKey(ValueKey('lw${w.id}')));
            expect(
              r.left >= -0.5 && r.right <= size.width + 0.5 && r.top >= -0.5 && r.bottom <= size.height + 0.5,
              isTrue,
              reason: 'word ${w.key} on screen at x$factor: $r',
            );
          }
        }
      }
    });
  }

  for (final (name, look) in [('Emerald & Gold', PageLook.screen), ('Night', PageLook.night)]) {
    testWidgets('$name: colours from the look, header and «تتبع» readable', (t) async {
      await loadMeta(t);
      final g = LargeGeometry(width: 360, height: 640, factor: 2.0);
      final s = (await _screens(t, 48, g)).first;
      await _pump(t, const Size(360, 640), _screen(s, g, look: look));
      final word = t.widget<Text>(find.byKey(ValueKey('lw${s.words.first.id}')));
      expect(word.style!.color, look.ink);
      expect(contrastIssues(t, within: find.byType(LargeAyahScreen)), isEmpty);
    });
  }

  testWidgets('the highlight and the tint are drawn behind the given words', (t) async {
    await loadMeta(t);
    final g = LargeGeometry(width: 360, height: 700, factor: 2.0);
    final s = (await _screens(t, 2, g, count: 3)).first;
    final ids = s.words.map((w) => w.id).toList();
    await _pump(
      t,
      const Size(360, 700),
      SizedBox(
        width: 360,
        height: 700,
        child: LargeAyahScreen(
          screen: s,
          meta: meta,
          geometry: g,
          highlightedWordIds: {ids.first},
          tintedWordIds: {ids.last},
        ),
      ),
    );
    BoxDecoration? deco(int id) =>
        (t
                .widgetList<DecoratedBox>(
                  find.ancestor(of: find.byKey(ValueKey('lw$id')), matching: find.byType(DecoratedBox)),
                )
                .first
                .decoration
            as BoxDecoration?);
    expect(deco(ids.first)!.color, PageLook.screen.highlight);
    expect(deco(ids.last)!.color, PageLook.screen.bookmarkTint);
  });

  testWidgets('a long press on a word reports it', (t) async {
    await loadMeta(t);
    final g = LargeGeometry(width: 360, height: 700, factor: 2.0);
    final s = (await _screens(t, 2, g)).first;
    MushafWord? pressed;
    await _pump(
      t,
      const Size(360, 700),
      SizedBox(
        width: 360,
        height: 700,
        child: LargeAyahScreen(screen: s, meta: meta, geometry: g, onWordLongPress: (w) => pressed = w),
      ),
    );
    await t.longPress(find.byKey(ValueKey('lw${s.words.first.id}')));
    expect(pressed, s.words.first);
  });
}
