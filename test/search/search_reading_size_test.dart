// Feature 011, T056: the snippet's Quran words follow the reading size of feature 003 and nothing else on the search
// screen does (spec FR-012, FR-026; contracts/ui.md "Rows", "Looks, sizes, targets"; research D6).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ui/reading_text.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_page.dart' show kQuranFont;
import 'package:mushaf/search/search_strings.dart';

import '../support/search_harness.dart';
import '../support/search_quality_harness.dart';

/// Surah 112, ayah 1, whole; no surah has such a name.
const _ikhlas = 'قل هو الله احد';

/// Surah 18 by its name, and ayat that hold the word.
const _cave = 'الكهف';

/// The snippet of 112:1 as drawn now.
RichText snippet(WidgetTester t) =>
    t.widget<RichText>(snippetIn(ayahRow(112, 1)));

/// The one text of [finder] (a `Text` draws one `RichText`).
RichText richOf(WidgetTester t, Finder finder) => t.widget<RichText>(
  find.descendant(of: finder, matching: find.byType(RichText), matchRoot: true),
);

/// The runs of the snippet that are words of the Mushaf (not the cut mark).
List<StyledRun> words(RichText rich) => [
  for (final run in runsOf(rich))
    if (run.text.trim() != kSnippetCut) run,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MushafMeta meta;

  /// The stored words of 112:1.
  late List<String> stored;
  setUpAll(() async {
    meta = await realMeta();
    final index = await realIndex();
    stored = index.storedWords(index.surahFirst[111]);
  });

  String title() => kAyahRowTitle(meta.surah(112).name, 1);
  String page() => kPageShort(meta.pageOfAyah(112, 1));

  /// The sizes of everything that is not Quran text: they never change with the reading size.
  void expectTheRestUnscaled(WidgetTester t, double systemFont) {
    final row = ayahRow(112, 1);
    final titleText = richOf(
      t,
      find.descendant(of: row, matching: find.text(title())),
    );
    final titleStyle = runsOf(titleText).single.style;
    expect(titleStyle.fontSize, 16);
    expect(titleStyle.fontWeight, FontWeight.w600);
    expect(titleStyle.fontFamily, isNot(kQuranFont));
    expect(drawnSize(titleText, titleStyle), 16 * systemFont);

    final pageText = richOf(
      t,
      find.descendant(of: row, matching: find.text(page())),
    );
    final pageStyle = runsOf(pageText).single.style;
    expect(pageStyle.fontSize, 14);
    expect(pageStyle.fontFamily, isNot(kQuranFont));
    expect(drawnSize(pageText, pageStyle), 14 * systemFont);

    final headingText = richOf(
      t,
      find.descendant(of: ayatHeading, matching: find.byType(RichText)),
    );
    final headingStyle = runsOf(headingText).single.style;
    expect(headingStyle.fontSize, 18);
    expect(headingStyle.fontFamily, isNot(kQuranFont));
    expect(drawnSize(headingText, headingStyle), 18 * systemFont);
  }

  for (final percent in const [80, 100, 150]) {
    final factor = percent / 100;
    testWidgets(
      '$percent %: the snippet is drawn at ${20 * factor} in the Quran font, the rest keeps its size',
      (t) async {
        await pumpSearch(t, readingPercent: percent);
        await typeQuery(t, _ikhlas);
        final rich = snippet(t);
        final runs = words(rich);
        expect(runs, isNotEmpty);
        for (final run in runs) {
          expect(run.style.fontFamily, kQuranFont, reason: run.text);
          expect(run.style.fontSize, 20 * factor, reason: run.text);
          expect(run.style.height, 2.0, reason: run.text);
          expect(drawnSize(rich, run.style), 20 * factor, reason: run.text);
        }
        expectTheRestUnscaled(t, 1.0);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets('the lines keep their size at every reading size', (t) async {
    final run = await pumpSearch(t, readingPercent: 150);
    for (final percent in const [150, 80, 100]) {
      await run.setSize(t, percent);
      await typeQuery(t, '');
      final hint = richOf(t, find.text(kSearchHint));
      expect(runsOf(hint).single.style.fontSize, 15, reason: '$percent %');
      expect(hint.textScaler.scale(15), 15, reason: '$percent %');
      await typeQuery(t, 'ذو القرنين');
      for (final line in [kSearchNone, kSearchNoneAdvice]) {
        final text = richOf(t, find.text(line));
        expect(runsOf(text).single.style.fontSize, 15, reason: '$percent %');
        expect(runsOf(text).single.style.fontFamily, isNot(kQuranFont));
      }
    }
  });

  testWidgets('a surah row and its heading do not follow the reading size', (
    t,
  ) async {
    final run = await pumpSearch(t, readingPercent: 80);
    await typeQuery(t, _cave);
    Map<String, double?> sizes() => {
      for (final text in t.widgetList<RichText>(
        find.descendant(of: surahRow(18), matching: find.byType(RichText)),
      ))
        text.text.toPlainText(): text.textScaler.scale(
          runsOf(text).single.style.fontSize ?? 14,
        ),
    };
    final before = sizes();
    final headingBefore = t.getSize(surahsHeading);
    final rowBefore = t.getSize(surahRow(18));
    expect(before, hasLength(3), reason: 'the number, the name, the page');
    await run.setSize(t, 150);
    expect(sizes(), before);
    expect(t.getSize(surahsHeading), headingBefore);
    expect(t.getSize(surahRow(18)), rowBefore);
  });

  group('with the system font', () {
    testWidgets(
      '2x and 150 %: the snippet is at 3x of its base (60), the title at 2x of its own (32)',
      (t) async {
        final errors = collectErrors();
        await pumpSearch(
          t,
          readingPercent: 150,
          textScale: 2.0,
          screen: const Size(412, 915),
        );
        await typeQuery(t, _ikhlas);
        final rich = snippet(t);
        for (final run in words(rich)) {
          expect(run.style.fontSize, 30);
          expect(drawnSize(rich, run.style), 60);
        }
        expectTheRestUnscaled(t, 2.0);
        expect(errors, isEmpty, reason: describeErrors(errors));
      },
    );

    testWidgets(
      '3x and 150 %: the snippet is capped at 3x of its base (60, not 90), the title is not capped (48)',
      (t) async {
        // a 3x system font is beyond what the layout promises (2x); only the sizes are looked at here
        collectErrors();
        await pumpSearch(
          t,
          readingPercent: 150,
          textScale: 3.0,
          screen: const Size(412, 915),
        );
        await typeQuery(t, _ikhlas);
        await t.scrollUntilVisible(
          ayahRow(112, 1),
          100,
          scrollable: searchList,
        );
        final rich = snippet(t);
        for (final run in words(rich)) {
          expect(run.style.fontSize, 30);
          expect(drawnSize(rich, run.style), 20 * kMaxReadingScale);
        }
        expectTheRestUnscaled(t, 3.0);
      },
    );

    testWidgets(
      '3x and 80 %: the cap is on size times system font (20 x 0.8 x 3 = 48 is under it)',
      (t) async {
        collectErrors();
        await pumpSearch(
          t,
          readingPercent: 80,
          textScale: 3.0,
          screen: const Size(412, 915),
        );
        await typeQuery(t, _ikhlas);
        await t.scrollUntilVisible(
          ayahRow(112, 1),
          100,
          scrollable: searchList,
        );
        final rich = snippet(t);
        for (final run in words(rich)) {
          expect(drawnSize(rich, run.style), 48);
        }
      },
    );
  });

  testWidgets(
    'changing the reading size while search is open redraws the snippet, and only the snippet grows',
    (t) async {
      final run = await pumpSearch(t, readingPercent: 100);
      await typeQuery(t, _ikhlas);
      expect(words(snippet(t)).first.style.fontSize, 20);
      final heightAt100 = t.getSize(snippetIn(ayahRow(112, 1))).height;
      final titleAt100 = t.getSize(
        find.descendant(of: ayahRow(112, 1), matching: find.text(title())),
      );

      await run.setSize(t, 150);
      expect(fieldText(t), _ikhlas, reason: 'nothing was typed again');
      expect(words(snippet(t)).first.style.fontSize, 30);
      expect(
        t.getSize(snippetIn(ayahRow(112, 1))).height,
        greaterThan(heightAt100),
      );
      expect(
        t.getSize(
          find.descendant(of: ayahRow(112, 1), matching: find.text(title())),
        ),
        titleAt100,
      );
      expectTheRestUnscaled(t, 1.0);

      await run.setSize(t, 80);
      expect(words(snippet(t)).first.style.fontSize, 16);
      expect(
        t.getSize(snippetIn(ayahRow(112, 1))).height,
        lessThan(heightAt100),
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'the snippet is the stored words at every size, three lines at most',
    (t) async {
      final run = await pumpSearch(t);
      await typeQuery(t, _ikhlas);
      for (final percent in const [80, 100, 150]) {
        await run.setSize(t, percent);
        final rich = snippet(t);
        final shown = rich.text
            .toPlainText()
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty && w != kSnippetCut)
            .join(' ');
        expect(shown, isNotEmpty);
        expect(
          ' ${stored.join(' ')} ',
          contains(' $shown '),
          reason:
              '$percent %: whole stored words in a row, character for character',
        );
        expect(rich.maxLines, anyOf(isNull, lessThanOrEqualTo(3)));
        final painter = TextPainter(
          text: rich.text,
          textDirection: TextDirection.rtl,
          textScaler: rich.textScaler,
        )..layout(maxWidth: t.getSize(snippetIn(ayahRow(112, 1))).width);
        expect(
          painter.computeLineMetrics().length,
          lessThanOrEqualTo(3),
          reason: '$percent %',
        );
        painter.dispose();
      }
    },
  );

  test('the family is the bundled AmiriQuran: pubspec.yaml declares it and no font was added for search', () {
    expect(kQuranFont, 'AmiriQuran');
    final families = RegExp(r'^\s*- family:\s*(\S+)\s*$', multiLine: true)
        .allMatches(File('pubspec.yaml').readAsStringSync())
        .map((m) => m.group(1))
        .toList();
    expect(families, ['AmiriQuran', 'ReemKufi', 'Cairo']);
    final fonts = Directory('assets/fonts')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.ttf') || f.path.endsWith('.otf'))
        .map((f) => f.path.split('/').last)
        .toSet();
    expect(fonts, contains('AmiriQuran.ttf'));
    // no source file of the search names another family
    for (final file in Directory('lib/search').listSync().whereType<File>()) {
      final source = file.readAsStringSync();
      for (final match in RegExp(
        r'fontFamily:\s*([^,\n]+)',
      ).allMatches(source)) {
        expect(match.group(1)!.trim(), 'kQuranFont', reason: file.path);
      }
    }
  });
}
