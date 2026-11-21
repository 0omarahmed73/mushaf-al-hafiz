import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_page.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/page_font_loader.dart';

const small = Size(360, 640);
const large = Size(412, 915);

late MushafRepository repo;
late PageFontLoader fonts;
late MushafMeta meta;

/// Loads the real page data and font, then pumps [MushafPage] in an LTR ambient direction
/// (the reader wraps its PageView in LTR, so the page must set its own RTL direction).
Future<PageData> pumpPage(
  WidgetTester t, {
  required int page,
  required Size size,
  Set<int> hidden = const {},
  Set<int> highlighted = const {},
  void Function(MushafWord)? onTap,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  late PageData data;
  late String family;
  await t.runAsync(() async {
    data = await repo.loadPage(page);
    family = await fonts.ensure(page);
  });
  await t.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: SizedBox.expand(
        child: MushafPage(
          data: data,
          meta: meta,
          fontFamily: family,
          hiddenWordIds: hidden,
          highlightedWordIds: highlighted,
          onWordTap: onTap,
        ),
      ),
    ),
  ));
  return data;
}

Rect lineRect(WidgetTester t, int n) => t.getRect(find.byKey(ValueKey('line-$n')));

Rect wordsRect(WidgetTester t, Iterable<int> ids) =>
    ids.map((id) => t.getRect(find.byKey(ValueKey('w$id')))).reduce((a, b) => a.expandToInclude(b));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    repo = MushafRepository(rootBundle);
    fonts = PageFontLoader();
    meta = (await repo.loadMeta());
  });

  for (final size in [small, large]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('page 3 (15 lines) shows its first and last word with no overflow at $label', (t) async {
      await pumpPage(t, page: 3, size: size);
      expect(t.takeException(), isNull);
      expect(find.byKey(const ValueKey('w78')), findsOneWidget);
      expect(find.byKey(const ValueKey('w215')), findsOneWidget);
      for (var n = 1; n <= 15; n++) {
        expect(find.byKey(ValueKey('line-$n')), findsOneWidget, reason: 'line $n');
      }
    });

    testWidgets('pages 1 and 2 keep the 15-line line height, centred, not stretched at $label', (t) async {
      await pumpPage(t, page: 3, size: size);
      final fullHeight = lineRect(t, 1).height;
      final contentTop = lineRect(t, 1).top;
      final contentBottom = lineRect(t, 15).bottom;

      await pumpPage(t, page: 1, size: size);
      expect(t.takeException(), isNull);
      for (var n = 1; n <= 8; n++) {
        expect(lineRect(t, n).height, closeTo(fullHeight, 0.5), reason: 'page 1 line $n');
      }
      // the 8-line block sits in the vertical middle of the 15-line content area
      final topGap = lineRect(t, 1).top - contentTop;
      final bottomGap = contentBottom - lineRect(t, 8).bottom;
      expect(topGap, closeTo(bottomGap, 1.0));
      expect(topGap, greaterThan(fullHeight)); // clearly not stretched to the top

      // line 2 (words 1..5) is centred horizontally, not justified edge to edge
      final words = wordsRect(t, [1, 2, 3, 4, 5]);
      expect(words.center.dx, closeTo(size.width / 2, 1.5));
      expect(words.width, lessThan(size.width * 0.9));

      await pumpPage(t, page: 2, size: size);
      expect(t.takeException(), isNull);
      expect(lineRect(t, 3).height, closeTo(fullHeight, 0.5));
    });

    testWidgets('justified lines reach both edges of the text block at $label', (t) async {
      await pumpPage(t, page: 3, size: size);
      final block = lineRect(t, 1);
      for (final n in [1, 5, 9, 14]) {
        final line = lineRect(t, n);
        final words = wordsRect(t, _wordIdsOfLine(await _page(t, 3), n));
        expect(words.left, closeTo(line.left, 1.5), reason: 'line $n left edge');
        expect(words.right, closeTo(line.right, 1.5), reason: 'line $n right edge');
        expect(line.width, closeTo(block.width, 0.5));
      }
    });

    testWidgets('page 2 shows the surah title in Reem Kufi and the basmallah in AmiriQuran at $label', (t) async {
      await pumpPage(t, page: 2, size: size);
      expect(find.text('سورة البقرة'), findsOneWidget);
      final basmallah = find.text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ');
      expect(basmallah, findsOneWidget);
      expect(t.widget<Text>(basmallah).style?.fontFamily, 'AmiriQuran');
      expect(t.widget<Text>(find.text('سورة البقرة')).style?.fontFamily, 'ReemKufi');
    });

    testWidgets('the page number is centred at the bottom at $label', (t) async {
      await pumpPage(t, page: 3, size: size);
      final number = find.byKey(const ValueKey('page-number'));
      expect(t.widget<Text>(number).data, '3');
      final rect = t.getRect(number);
      expect(rect.center.dx, closeTo(size.width / 2, 1.5));
      expect(rect.top, greaterThan(lineRect(t, 15).bottom - 1));
      expect(rect.bottom, lessThanOrEqualTo(size.height + 0.5));
    });

    testWidgets('a hidden word keeps its space but is invisible at $label', (t) async {
      await pumpPage(t, page: 3, size: size);
      final before = t.getRect(find.byKey(const ValueKey('w80')));
      await pumpPage(t, page: 3, size: size, hidden: {80});
      final after = t.getRect(find.byKey(const ValueKey('w80')));
      expect(after, before);
      final opacity = t.widget<Opacity>(find
          .ancestor(of: find.byKey(const ValueKey('w80')), matching: find.byType(Opacity))
          .first);
      expect(opacity.opacity, 0);
      final other = find.ancestor(of: find.byKey(const ValueKey('w81')), matching: find.byType(Opacity));
      expect(other, findsNothing);
    });
  }

  testWidgets('a highlighted word has a background colour and a tap reports the word', (t) async {
    MushafWord? tapped;
    final data = await pumpPage(t, page: 3, size: small, highlighted: {80}, onTap: (w) => tapped = w);
    final expected = data.lines.expand((l) => l.words).firstWhere((w) => w.id == 81);
    final box = t.widget<DecoratedBox>(find
        .ancestor(of: find.byKey(const ValueKey('w80')), matching: find.byType(DecoratedBox))
        .first);
    expect((box.decoration as BoxDecoration).color, isNotNull);
    await t.tap(find.byKey(const ValueKey('w81')));
    expect(tapped?.id, 81);
    expect(tapped?.key, expected.key);
  });

  for (final size in [small, large]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('all 604 pages render with every word and no overflow at $label', (t) async {
      for (var p = 1; p <= 604; p++) {
        final data = await pumpPage(t, page: p, size: size);
        expect(t.takeException(), isNull, reason: 'page $p');
        for (final line in data.lines) {
          for (final w in line.words) {
            expect(find.byKey(ValueKey('w${w.id}')), findsOneWidget, reason: 'page $p word ${w.id}');
          }
        }
      }
    }, timeout: const Timeout(Duration(minutes: 20)));
  }
}

Future<PageData> _page(WidgetTester t, int page) async {
  late PageData data;
  await t.runAsync(() async => data = await repo.loadPage(page));
  return data;
}

Iterable<int> _wordIdsOfLine(PageData data, int n) => data.lines[n - 1].words.map((w) => w.id);
