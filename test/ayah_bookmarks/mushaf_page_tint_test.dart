// The tint on the Mushaf page (feature 013, spec FR-016, FR-023, SC-010; contracts/dart-interfaces.md; research D6): the
// words of a bookmarked ayah get the same per-word DecoratedBox as the highlight, in the tint colour; the highlight wins
// over it; nothing about the layout moves, to the pixel. Real page data and the real page font.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_page.dart';
import 'package:mushaf/mushaf/mushaf_page_card.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/page_font_loader.dart';
import 'package:mushaf/mushaf/page_look.dart';

const small = Size(320, 640);
const large = Size(412, 915);
const tint = Color(0x290F766E);
const highlight = Color(0x55FFC107);

late MushafRepository repo;
late PageFontLoader fonts;
late MushafMeta meta;

Future<(PageData, String)> load(WidgetTester t, int page) async {
  late PageData data;
  late String family;
  await t.runAsync(() async {
    data = await repo.loadPage(page);
    family = await fonts.ensure(page);
  });
  return (data, family);
}

Future<void> pumpIn(WidgetTester t, Size size, Widget child) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: SizedBox.expand(child: child),
      ),
    ),
  );
}

/// The decorations between the word's Text and the page: what paints behind the word.
List<BoxDecoration> decorationsOf(WidgetTester t, int id) => t
    .widgetList<DecoratedBox>(
      find.ancestor(
        of: find.byKey(ValueKey('w$id')),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((d) => d.decoration)
    .whereType<BoxDecoration>()
    .toList();

/// The decoration right around the word, or null when the word has none of its own.
BoxDecoration? ownDecoration(WidgetTester t, int id) {
  final ancestors = find.ancestor(
    of: find.byKey(ValueKey('w$id')),
    matching: find.byType(DecoratedBox),
  );
  if (t.widgetList(ancestors).isEmpty) return null;
  final parent = ancestors.first;
  final box = t.widget<DecoratedBox>(parent);
  final wordOnly = find.descendant(of: parent, matching: find.byType(Text));
  if (t.widgetList(wordOnly).length != 1) {
    return null; // the nearest box holds the whole page: not the word's
  }
  return box.decoration as BoxDecoration;
}

/// Every element of the tree as its widget type and key, in order: equal lists mean the same tree.
List<String> treeOf(WidgetTester t) {
  final out = <String>[];
  void visit(Element e) {
    out.add('${e.widget.runtimeType}${e.widget.key ?? ''}');
    e.visitChildren(visit);
  }

  t.binding.rootElement!.visitChildren(visit);
  return out;
}

Set<int> wordsOf(PageData p, AyahRef ref) => wordIdsOfAyah(p, ref);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    repo = MushafRepository(rootBundle);
    fonts = PageFontLoader();
    meta = await repo.loadMeta();
  });

  testWidgets(
    'exactly the tinted words get a DecoratedBox in the tint colour, radius 4',
    (t) async {
      final (data, family) = await load(t, 3);
      final ayah = wordsOf(data, const AyahRef(2, 6));
      expect(ayah, isNotEmpty);
      await pumpIn(
        t,
        large,
        MushafPage(
          data: data,
          meta: meta,
          fontFamily: family,
          tintedWordIds: ayah,
          tintColor: tint,
        ),
      );
      expect(t.takeException(), isNull);
      for (final w in data.lines.expand((l) => l.words)) {
        final own = ownDecoration(t, w.id);
        if (ayah.contains(w.id)) {
          expect(own, isNotNull, reason: 'word ${w.id} is tinted');
          expect(own!.color, tint, reason: 'word ${w.id}');
          expect(
            own.borderRadius,
            BorderRadius.circular(4),
            reason: 'word ${w.id}',
          );
          expect(
            decorationsOf(t, w.id).where((d) => d.color == tint),
            hasLength(1),
            reason: 'one tint, word ${w.id}',
          );
        } else {
          expect(own, isNull, reason: 'word ${w.id} is not tinted');
        }
      }
    },
  );

  testWidgets('a word in both sets shows the highlight and not the tint', (
    t,
  ) async {
    final (data, family) = await load(t, 3);
    final a = wordsOf(data, const AyahRef(2, 6));
    final b = wordsOf(data, const AyahRef(2, 7));
    final both = a.first;
    await pumpIn(
      t,
      large,
      MushafPage(
        data: data,
        meta: meta,
        fontFamily: family,
        highlightedWordIds: {...b, both},
        highlightColor: highlight,
        tintedWordIds: a,
        tintColor: tint,
      ),
    );
    final bothColors = decorationsOf(t, both).map((d) => d.color).toList();
    expect(bothColors, contains(highlight));
    expect(
      bothColors,
      isNot(contains(tint)),
      reason: 'the highlight replaces the tint, no blend',
    );
    expect(ownDecoration(t, both)!.color, highlight);
    for (final id in b) {
      expect(
        ownDecoration(t, id)!.color,
        highlight,
        reason: 'highlighted word $id',
      );
    }
    for (final id in a.difference({both})) {
      expect(ownDecoration(t, id)!.color, tint, reason: 'tinted word $id');
    }
  });

  testWidgets('no tint set: the widget tree is the one of today', (t) async {
    final (data, family) = await load(t, 3);
    await pumpIn(
      t,
      large,
      MushafPage(
        data: data,
        meta: meta,
        fontFamily: family,
        highlightedWordIds: {80},
      ),
    );
    final today = treeOf(t);
    await pumpIn(t, small, const SizedBox());
    await pumpIn(
      t,
      large,
      MushafPage(
        data: data,
        meta: meta,
        fontFamily: family,
        highlightedWordIds: {80},
        tintColor: tint,
      ),
    );
    expect(treeOf(t), today, reason: 'a colour alone changes nothing');
    await pumpIn(t, small, const SizedBox());
    await pumpIn(
      t,
      large,
      MushafPage(
        data: data,
        meta: meta,
        fontFamily: family,
        highlightedWordIds: {80},
        tintedWordIds: const {},
        tintColor: tint,
      ),
    );
    expect(treeOf(t), today, reason: 'an empty set changes nothing');
  });

  for (final size in [small, large]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    for (final page in [1, 3, 48, 604]) {
      testWidgets(
        'page $page at $label: every word and line rectangle is the same with and without the tint',
        (t) async {
          final (data, family) = await load(t, page);
          final words = data.lines.expand((l) => l.words).toList();
          Map<String, Rect> rects() => {
            for (final l in data.lines)
              'line-${l.number}': t.getRect(
                find.byKey(ValueKey('line-${l.number}')),
              ),
            for (final w in words)
              'w${w.id}': t.getRect(find.byKey(ValueKey('w${w.id}'))),
            'page-number': t.getRect(find.byKey(const ValueKey('page-number'))),
          };
          await pumpIn(
            t,
            size,
            MushafPage(data: data, meta: meta, fontFamily: family),
          );
          final bare = rects();
          // Every other word tinted, and every word of the page: the most boxes and the longest runs.
          for (final ids in [
            {for (var i = 0; i < words.length; i += 2) words[i].id},
            {for (final w in words) w.id},
          ]) {
            await pumpIn(
              t,
              size,
              MushafPage(
                data: data,
                meta: meta,
                fontFamily: family,
                tintedWordIds: ids,
                tintColor: tint,
              ),
            );
            expect(t.takeException(), isNull);
            final tinted = rects();
            expect(tinted.keys, bare.keys);
            for (final k in bare.keys) {
              expect(tinted[k], bare[k], reason: '$k moved (0 px allowed)');
            }
          }
        },
      );
    }
  }

  testWidgets('the words keep their keys and stay one Text each', (t) async {
    final (data, family) = await load(t, 48);
    final ids = {for (final w in data.lines.expand((l) => l.words)) w.id};
    await pumpIn(
      t,
      large,
      MushafPage(
        data: data,
        meta: meta,
        fontFamily: family,
        tintedWordIds: ids,
        tintColor: tint,
      ),
    );
    for (final id in ids) {
      final f = find.byKey(ValueKey('w$id'));
      expect(f, findsOneWidget, reason: 'w$id');
      expect(t.widget(f), isA<Text>(), reason: 'w$id');
    }
  });

  for (final look in [PageLook.emerald, PageLook.night]) {
    testWidgets(
      'the card passes the tint through in ${look == PageLook.night ? 'Night Reader' : 'Emerald & Gold'}',
      (t) async {
        final (data, family) = await load(t, 3);
        final ayah = wordsOf(data, const AyahRef(2, 6));
        await pumpIn(
          t,
          large,
          MushafPageCard(
            data: data,
            meta: meta,
            fontFamily: family,
            look: look,
            tintedWordIds: ayah,
          ),
        );
        final page = t.widget<MushafPage>(find.byType(MushafPage));
        expect(page.tintedWordIds, ayah);
        expect(page.tintColor, look.bookmarkTint);
        for (final id in ayah) {
          expect(
            ownDecoration(t, id)!.color,
            look.bookmarkTint,
            reason: 'word $id',
          );
        }
      },
    );
  }

  testWidgets('a card with no tint set builds the page with an empty set', (
    t,
  ) async {
    final (data, family) = await load(t, 3);
    await pumpIn(
      t,
      large,
      MushafPageCard(data: data, meta: meta, fontFamily: family),
    );
    expect(
      t.widget<MushafPage>(find.byType(MushafPage)).tintedWordIds,
      isEmpty,
    );
  });
}
