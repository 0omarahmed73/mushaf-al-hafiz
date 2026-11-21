import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_page.dart';
import 'package:mushaf/mushaf/mushaf_page_card.dart';
import 'package:mushaf/mushaf/page_look.dart';
import 'package:mushaf/theme.dart';

import '../support/test_meta.dart';

MushafWord word(int id, int n) =>
    MushafWord(id: id, key: '1:1:$n', glyph: 'ب', surah: 1, ayah: 1);

PageData data() => PageData(
  page: 3,
  juz: 1,
  hizbQuarter: 1,
  lines: [
    MushafLine(
      number: 1,
      type: LineType.ayah,
      centered: false,
      surah: null,
      words: [word(1, 1), word(2, 2), word(3, 3)],
    ),
  ],
);

Widget host(Widget card) => Directionality(
  textDirection: TextDirection.rtl,
  child: Center(child: SizedBox(width: 400, height: 600, child: card)),
);

Iterable<BoxDecoration> boxes(WidgetTester t) => t
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .map((d) => d.decoration)
    .whereType<BoxDecoration>();

/// A look unlike the app's (white paper, black ink and lines, no ring and no banner fill): the card must draw
/// whatever look it is given, with the same geometry.
const PageLook _plainLook = PageLook(
  paper: Color(0xFFFFFFFF),
  ink: Color(0xFF000000),
  frame: Color(0xFF000000),
  frameWidth: 1,
  bannerText: Color(0xFF000000),
  background: Color(0xFFFFFFFF),
);

void main() {
  group('PageLook', () {
    test('screen is the app look: ring, ivory paper, gold frame, green banner with gold text', () {
      const l = PageLook.screen;
      expect(l.ring, AppColors.ring);
      expect(l.paper, AppColors.paper);
      expect(l.frame, AppColors.goldDark);
      expect(l.frameWidth, 2);
      expect(l.ink, AppColors.ink);
      expect(l.bannerFill, AppColors.green);
      expect(l.bannerText, AppColors.gold);
    });
  });

  group('MushafPageCard', () {
    testWidgets(
      'screen look draws the ring, the ivory paper and the gold frame like the reader page',
      (t) async {
        await t.pumpWidget(
          host(MushafPageCard(data: data(), meta: testMeta(), fontFamily: 'x')),
        );
        final decorations = boxes(t).toList();
        expect(
          decorations.any((d) => d.border?.top.color == AppColors.ring),
          isTrue,
          reason: 'ring',
        );
        final paper = decorations.firstWhere((d) => d.color == AppColors.paper);
        expect(paper.border?.top.color, AppColors.goldDark);
        expect(paper.border?.top.width, 2);
        final page = t.widget<MushafPage>(find.byType(MushafPage));
        expect(
          (
            page.textColor,
            page.frameColor,
            page.bannerColor,
            page.bannerTextColor,
          ),
          (AppColors.ink, AppColors.goldDark, AppColors.green, AppColors.gold),
        );
      },
    );

    testWidgets(
      'a plain look (no ring, white paper, black lines) is honoured everywhere',
      (t) async {
        await t.pumpWidget(
          host(
            MushafPageCard(
              data: data(),
              meta: testMeta(),
              fontFamily: 'x',
              look: _plainLook,
            ),
          ),
        );
        final decorations = boxes(t).toList();
        expect(
          decorations.any((d) => d.border?.top.color == AppColors.ring),
          isFalse,
        );
        final paper = decorations.firstWhere(
          (d) => d.color == const Color(0xFFFFFFFF),
        );
        expect(paper.border?.top.color, const Color(0xFF000000));
        expect(decorations.any((d) => d.color == AppColors.paper), isFalse);
        expect(
          decorations.any((d) => d.border?.top.color == AppColors.goldDark),
          isFalse,
        );
        final page = t.widget<MushafPage>(find.byType(MushafPage));
        expect(page.textColor, const Color(0xFF000000));
        expect(page.bannerColor, isNull);
        expect(page.bannerTextColor, const Color(0xFF000000));
      },
    );

    testWidgets('has the same geometry in every look', (t) async {
      await t.pumpWidget(
        host(MushafPageCard(data: data(), meta: testMeta(), fontFamily: 'x')),
      );
      final screen = t.getRect(find.byType(MushafPage));
      await t.pumpWidget(
        host(
          MushafPageCard(
            data: data(),
            meta: testMeta(),
            fontFamily: 'x',
            look: _plainLook,
          ),
        ),
      );
      expect(t.getRect(find.byType(MushafPage)), screen);
    });

    testWidgets(
      'highlights the given words and reports a long press on a word',
      (t) async {
        MushafWord? pressed;
        await t.pumpWidget(
          host(
            MushafPageCard(
              data: data(),
              meta: testMeta(),
              fontFamily: 'x',
              highlightedWordIds: const {2},
              onWordLongPress: (w) => pressed = w,
            ),
          ),
        );
        final highlighted = boxes(t)
            .where((d) => d.color == const Color(0x55FFC107));
        expect(highlighted, hasLength(1));
        await t.longPress(find.byKey(const ValueKey('w3')));
        expect(pressed?.id, 3);
      },
    );

    testWidgets('draws the page number in Cairo', (t) async {
      await t.pumpWidget(
        host(MushafPageCard(data: data(), meta: testMeta(), fontFamily: 'x')),
      );
      expect(
        t
            .widget<Text>(find.byKey(const ValueKey('page-number')))
            .style
            ?.fontFamily,
        kUiFont,
      );
    });

    testWidgets(
      'the loading card shows the page number inside the same ring and paper, never the text',
      (t) async {
        await t.pumpWidget(host(const MushafPageCard.loading(page: 7)));
        expect(find.byKey(const ValueKey('page-number')), findsOneWidget);
        expect(find.text('7'), findsOneWidget);
        expect(find.byType(MushafPage), findsNothing);
        expect(boxes(t).any((d) => d.color == AppColors.paper), isTrue);
      },
    );
  });
}
