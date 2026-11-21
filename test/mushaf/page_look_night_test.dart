// The Mushaf page in Night Reader (spec FR-007, FR-008, SC-004; contracts/dart-interfaces.md page_look.dart): no card
// and no frame drawn, light ink, a teal title between two hairlines, a quiet page number, teal ayah-end markers and a
// visible highlight, all in the same box as in Emerald & Gold.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/contrast.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_page.dart';
import 'package:mushaf/mushaf/mushaf_page_card.dart';
import 'package:mushaf/mushaf/page_look.dart';
import 'package:mushaf/theme.dart';

import '../support/test_meta.dart';

const Color _teal = Color(0xFF6CC4B5);

MushafWord word(int id, int n, {int ayah = 1}) =>
    MushafWord(id: id, key: '1:$ayah:$n', glyph: 'ب', surah: 1, ayah: ayah);

/// A title line and two ayah lines; the last word of each ayah (ids 3 and 5) is its end marker.
PageData data({Set<int> markers = const {3, 5}}) => PageData(
  page: 3,
  juz: 1,
  hizbQuarter: 1,
  endMarkerIds: markers,
  lines: [
    const MushafLine(
      number: 1,
      type: LineType.surahName,
      centered: false,
      surah: 1,
      words: [],
    ),
    MushafLine(
      number: 2,
      type: LineType.ayah,
      centered: false,
      surah: null,
      words: [word(1, 1), word(2, 2), word(3, 3)],
    ),
    MushafLine(
      number: 3,
      type: LineType.ayah,
      centered: false,
      surah: null,
      words: [word(4, 1, ayah: 2), word(5, 2, ayah: 2)],
    ),
  ],
);

Widget host(Widget card) => Directionality(
  textDirection: TextDirection.rtl,
  child: Center(child: SizedBox(width: 400, height: 600, child: card)),
);

Widget card(PageLook look, {Set<int> highlighted = const {}}) => MushafPageCard(
  data: data(),
  meta: testMeta(),
  fontFamily: 'x',
  look: look,
  highlightedWordIds: highlighted,
);

Iterable<BoxDecoration> boxes(WidgetTester t) => t
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .map((d) => d.decoration)
    .whereType<BoxDecoration>();

Color? inkOf(WidgetTester t, int id) =>
    t.widget<Text>(find.byKey(ValueKey('w$id'))).style?.color;

void main() {
  group('PageLook.night', () {
    const n = PageLook.night;

    test('the values of data-model.md', () {
      expect(n.background, const Color(0xFF0D1014));
      expect(n.paper, n.background, reason: 'no card: the paper is the page');
      expect(n.ring, isNull);
      expect(n.frame.a, 0, reason: 'nothing is drawn');
      expect(n.frameWidth, 2, reason: 'the same box as Emerald');
      expect(n.ink, const Color(0xFFECE7DC));
      expect(n.bannerFill, isNull);
      expect(n.bannerText, _teal);
      expect(n.bannerStyle, PageBannerStyle.rules);
      expect(n.bannerRule, const Color(0xFF2B343D));
      expect(n.numberColor, const Color(0xFF85909B));
      expect(n.highlight, const Color(0x4D6CC4B5));
      expect(n.endMarker, _teal);
    });

    test('Emerald is today\'s page: framed banner, ink page number, yellow highlight, no marker colour', () {
      const e = PageLook.screen;
      expect(e.bannerStyle, PageBannerStyle.framed);
      expect(e.numberColor, isNull);
      expect(e.highlight, const Color(0x55FFC107));
      expect(e.endMarker, isNull);
      expect(PageLook.emerald, same(PageLook.screen));
    });

    test('each look chooses its page look', () {
      expect(LookChoice.emerald.pageLook, same(PageLook.screen));
      expect(LookChoice.night.pageLook, same(PageLook.night));
    });

    test('the ink is readable on the page, and the highlight is visible and keeps the ink readable', () {
      expect(contrastRatio(n.ink, n.background), greaterThanOrEqualTo(4.5));
      expect(
        contrastRatio(n.numberColor!, n.background),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(n.endMarker!, n.background),
        greaterThanOrEqualTo(3.0),
      );
      expect(
        contrastRatio(n.bannerText, n.background),
        greaterThanOrEqualTo(3.0),
      );
      final wash = Color.alphaBlend(n.highlight, n.background);
      expect(
        contrastRatio(wash, n.background),
        greaterThanOrEqualTo(1.5),
        reason: 'the wash shows against the page',
      );
      expect(
        contrastRatio(n.ink, wash),
        greaterThanOrEqualTo(4.5),
        reason: 'the ink stays readable on the wash',
      );
    });
  });

  group('MushafPageCard in Night', () {
    testWidgets('draws no ring, no paper block and no visible frame', (
      t,
    ) async {
      await t.pumpWidget(host(card(PageLook.night)));
      for (final d in boxes(t)) {
        expect(
          d.border?.top.color == AppColors.ring,
          isFalse,
          reason: 'no ring',
        );
        expect(d.color == AppColors.paper, isFalse, reason: 'no ivory paper');
      }
      final paper = boxes(t).firstWhere(
        (d) => d.color == PageLook.night.paper,
        orElse: () => throw TestFailure('the paper box is missing'),
      );
      expect(
        paper.color,
        PageLook.night.background,
        reason: 'the page is the dark background',
      );
      expect(paper.border!.top.color.a, 0, reason: 'frame fully transparent');
      expect(paper.border!.top.width, 2, reason: 'the box keeps its width');
      expect(
        boxes(t).where((d) => d.border?.top.color == AppColors.goldDark),
        isEmpty,
        reason: 'no gold frame',
      );
    });

    testWidgets('has exactly the box and the lines Emerald has', (t) async {
      await t.pumpWidget(host(card(PageLook.screen)));
      final pageE = t.getRect(find.byType(MushafPage));
      final lineE = [
        for (final k in [1, 2, 3]) t.getRect(find.byKey(ValueKey('line-$k'))),
      ];
      final wordE = [
        for (final id in [1, 2, 3, 4, 5])
          t.getRect(find.byKey(ValueKey('w$id'))),
      ];
      await t.pumpWidget(host(card(PageLook.night)));
      expect(t.getRect(find.byType(MushafPage)), pageE);
      expect([
        for (final k in [1, 2, 3]) t.getRect(find.byKey(ValueKey('line-$k'))),
      ], lineE);
      expect([
        for (final id in [1, 2, 3, 4, 5])
          t.getRect(find.byKey(ValueKey('w$id'))),
      ], wordE);
    });

    testWidgets(
      'the surah banner is the title between two 1 px hairlines: no box, no fill, no stars',
      (t) async {
        await t.pumpWidget(host(card(PageLook.night)));
        final line = find.byKey(const ValueKey('line-1'));
        expect(
          find.descendant(of: line, matching: find.byType(StarOrnament)),
          findsNothing,
        );
        final title = t.widget<Text>(
          find.descendant(of: line, matching: find.textContaining('سورة')),
        );
        expect(title.style!.color, _teal);
        final rules = [
          for (final d in t.widgetList<DecoratedBox>(
            find.descendant(of: line, matching: find.byType(DecoratedBox)),
          ))
            d.decoration as BoxDecoration,
        ].where((d) => d.color == PageLook.night.bannerRule).toList();
        expect(rules.length, 2, reason: 'one hairline each side of the title');
        for (final r in rules) {
          expect(r.border, isNull);
        }
        for (final r in t.widgetList<SizedBox>(
          find.descendant(of: line, matching: find.byType(SizedBox)),
        )) {
          if (r.height == 1) expect(r.width, isNull);
        }
        final boxed =
            [
              for (final d in t.widgetList<DecoratedBox>(
                find.descendant(of: line, matching: find.byType(DecoratedBox)),
              ))
                d.decoration as BoxDecoration,
            ].where(
              (d) => d.border != null || d.color == PageLook.night.bannerFill,
            );
        expect(boxed, isEmpty, reason: 'no outlined or filled banner box');
      },
    );

    testWidgets('Emerald keeps its green banner with its two stars', (t) async {
      await t.pumpWidget(host(card(PageLook.screen)));
      final line = find.byKey(const ValueKey('line-1'));
      expect(
        find.descendant(of: line, matching: find.byType(StarOrnament)),
        findsNWidgets(2),
      );
    });

    testWidgets('the page number is quiet, the ink of the page otherwise', (
      t,
    ) async {
      await t.pumpWidget(host(card(PageLook.night)));
      expect(
        t.widget<Text>(find.byKey(const ValueKey('page-number'))).style!.color,
        PageLook.night.numberColor,
      );
      await t.pumpWidget(host(card(PageLook.screen)));
      expect(
        t.widget<Text>(find.byKey(const ValueKey('page-number'))).style!.color,
        PageLook.screen.ink,
      );
    });

    testWidgets('ayah-end markers are teal, every other word is the ink', (
      t,
    ) async {
      await t.pumpWidget(host(card(PageLook.night)));
      expect(inkOf(t, 3), _teal);
      expect(inkOf(t, 5), _teal);
      for (final id in [1, 2, 4]) {
        expect(inkOf(t, id), PageLook.night.ink, reason: 'word $id');
      }
      // Emerald draws every word in the ink, markers included.
      await t.pumpWidget(host(card(PageLook.screen)));
      for (final id in [1, 2, 3, 4, 5]) {
        expect(inkOf(t, id), PageLook.screen.ink, reason: 'word $id');
      }
    });

    testWidgets('the long-pressed ayah gets the look\'s wash', (t) async {
      await t.pumpWidget(host(card(PageLook.night, highlighted: {1, 2})));
      final washes = boxes(t)
          .where((d) => d.color == PageLook.night.highlight)
          .toList();
      expect(washes.length, 2);
      await t.pumpWidget(host(card(PageLook.screen, highlighted: {1})));
      expect(
        boxes(t).where((d) => d.color == const Color(0x55FFC107)).length,
        1,
      );
    });

    testWidgets(
      'the loading card has the same box in both looks and the quiet number',
      (t) async {
        await t.pumpWidget(
          host(const MushafPageCard.loading(page: 3, look: PageLook.screen)),
        );
        final e = t.getRect(find.byKey(const ValueKey('page-number')));
        await t.pumpWidget(
          host(const MushafPageCard.loading(page: 3, look: PageLook.night)),
        );
        expect(t.getRect(find.byKey(const ValueKey('page-number'))), e);
        expect(
          t
              .widget<Text>(find.byKey(const ValueKey('page-number')))
              .style!
              .color,
          PageLook.night.numberColor,
        );
      },
    );
  });
}
