// Feature 011, T030: the ayah group of the search screen over the real index (spec FR-005, FR-011, FR-012, FR-014, FR-020, User
// Story 2 scenarios 1-8; research D3, D6; contracts/ui.md "States", "Rows").
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/search/ayah_index.dart';
import 'package:mushaf/search/ayah_target.dart';
import 'package:mushaf/search/search_strings.dart';

import '../support/search_harness.dart';

const _ayatHeading = ValueKey('search-heading-ayat');
const _surahsHeading = ValueKey('search-heading-surahs');
const _moreLine = ValueKey('search-more-line');

Finder _row(int s, int a) => find.byKey(ValueKey('ayah-row-$s:$a'));
Finder _snippet(int s, int a) => find.byKey(ValueKey('ayah-snippet-$s:$a'));

Finder get _scrollable => find.descendant(
  of: find.byKey(const ValueKey('search-results')),
  matching: find.byType(Scrollable),
);

/// The keys of the ayah rows built now, in the order of the tree.
List<String> _ayahRows(WidgetTester t) => [
  for (final w in t.widgetList(
    find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('ayah-row-'),
    ),
  ))
    (w.key! as ValueKey<String>).value.substring('ayah-row-'.length),
];

/// Scrolls the whole list and returns every ayah row key met, in order.
Future<List<String>> _allAyahRows(WidgetTester t) async {
  final seen = <String>[];
  final position = t.state<ScrollableState>(_scrollable).position;
  while (true) {
    for (final key in _ayahRows(t)) {
      if (!seen.contains(key)) seen.add(key);
    }
    if (position.pixels >= position.maxScrollExtent) break;
    position.jumpTo(
      (position.pixels + 400).clamp(0, position.maxScrollExtent).toDouble(),
    );
    await t.pump();
  }
  return seen;
}

RichText _rich(WidgetTester t, int s, int a) => t.widget<RichText>(
  find.descendant(of: _snippet(s, a), matching: find.byType(RichText)),
);

/// The leaf spans of a snippet, in order.
List<TextSpan> _leaves(InlineSpan root) {
  final out = <TextSpan>[];
  root.visitChildren((span) {
    if (span is TextSpan && span.text != null && span.text!.isNotEmpty) {
      out.add(span);
    }
    return true;
  });
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AyahIndex index;
  setUpAll(() async {
    await realMeta();
    index = await realIndex();
  });

  List<String> stored(int s, int a) =>
      index.storedWords(index.indexOf(AyahRef(s, a)));

  testWidgets(
    '«قل هو الله احد» shows «الآيات · 1» and the one row of 112:1 with its title, page and stored words',
    (t) async {
      await pumpSearch(t);
      await typeQuery(t, 'قل هو الله احد');
      expect(
        find.descendant(
          of: find.byKey(_ayatHeading),
          matching: find.text('الآيات · 1'),
        ),
        findsOneWidget,
      );
      expect(_ayahRows(t), ['112:1']);
      final row = _row(112, 1);
      expect(
        find.descendant(of: row, matching: find.text('الإخلاص · آية 1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('ص 604')),
        findsOneWidget,
      );
      final rich = _rich(t, 112, 1);
      // character for character the stored words (the file's own order of marks), a space between two
      expect(rich.text.toPlainText(), stored(112, 1).join(' '));
      expect(t.getSize(row).height, greaterThanOrEqualTo(56));
    },
  );

  testWidgets(
    'the four matched words are in the accent colour and underlined, the Quran font at 20, height 2',
    (t) async {
      final run = await pumpSearch(t);
      await typeQuery(t, 'قل هو الله احد');
      final look = run.look.look;
      final rich = _rich(t, 112, 1);
      final words = [
        for (final leaf in _leaves(rich.text))
          if (leaf.text!.trim().isNotEmpty) leaf,
      ];
      expect(words.map((w) => w.text), stored(112, 1));
      final base = rich.text.style!;
      expect(base.fontFamily, 'AmiriQuran');
      expect(base.fontSize, 20);
      expect(base.height, 2.0);
      expect(base.color, look.text);
      for (final word in words) {
        final style = base.merge(word.style);
        expect(style.color, look.accent);
        expect(style.decoration, TextDecoration.underline);
        expect(style.fontFamily, 'AmiriQuran');
      }
    },
  );

  testWidgets('a word that did not match has the normal style', (t) async {
    final run = await pumpSearch(t);
    await typeQuery(t, 'قل هو الله احد');
    await typeQuery(t, 'الصمد');
    expect(_ayahRows(t), ['112:2']);
    final rich = _rich(t, 112, 2);
    final base = rich.text.style!;
    final words = [
      for (final leaf in _leaves(rich.text))
        if (leaf.text!.trim().isNotEmpty) leaf,
    ];
    expect(words.map((w) => w.text), stored(112, 2));
    final styles = [for (final w in words) base.merge(w.style)];
    expect(styles[0].color, run.look.look.text);
    expect(styles[0].decoration, isNot(TextDecoration.underline));
    expect(styles[1].color, run.look.look.accent);
    expect(styles[1].decoration, TextDecoration.underline);
  });

  testWidgets(
    'the emphasis uses the accent of the look in use (Night Reader)',
    (t) async {
      final run = await pumpSearch(t, look: LookChoice.night);
      await typeQuery(t, 'قل هو الله احد');
      final look = run.look.look;
      expect(look.accent, isNot(LookChoice.emerald.look.accent));
      final rich = _rich(t, 112, 1);
      final word = _leaves(rich.text).first;
      expect(rich.text.style!.merge(word.style).color, look.accent);
      expect(rich.text.style!.color, look.text);
    },
  );

  testWidgets(
    'the snippet grows with the reading size and the title does not',
    (t) async {
      final run = await pumpSearch(t);
      await typeQuery(t, 'قل هو الله احد');
      final title = find.descendant(
        of: _row(112, 1),
        matching: find.text('الإخلاص · آية 1'),
      );
      final titleHeight = t.getSize(title).height;
      expect(_rich(t, 112, 1).text.style!.fontSize, 20);
      await run.setSize(t, 150);
      await t.pump();
      expect(_rich(t, 112, 1).text.style!.fontSize, 30);
      expect(t.getSize(title).height, titleHeight);
      await run.setSize(t, 80);
      await t.pump();
      expect(_rich(t, 112, 1).text.style!.fontSize, 16);
    },
  );

  testWidgets('«بسم الله الرحمن الرحيم» shows 1:1 then 27:30', (t) async {
    await pumpSearch(t);
    await typeQuery(t, 'بسم الله الرحمن الرحيم');
    expect(_ayahRows(t), ['1:1', '27:30']);
    expect(find.text('الآيات · 2'), findsOneWidget);
    expect(
      find.descendant(of: _row(1, 1), matching: find.text('الفاتحة · آية 1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _row(1, 1), matching: find.text('ص 1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _row(27, 30), matching: find.text('النمل · آية 30')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _row(27, 30), matching: find.text('ص 379')),
      findsOneWidget,
    );
    expect(
      t.getTopLeft(_row(1, 1)).dy,
      lessThan(t.getTopLeft(_row(27, 30)).dy),
    );
  });

  testWidgets('a word that is three times in one ayah is one row', (t) async {
    await pumpSearch(t);
    // «لا» and «هو» are several times in 2:255
    await typeQuery(t, 'لا اله الا هو الحي القيوم');
    final rows = _ayahRows(t);
    expect(rows, ['2:255', '3:2']);
    expect(rows.toSet().length, rows.length);
  });

  testWidgets('«رحم» includes ayat with «الرحمن», «رحمة» and «يرحم»', (
    t,
  ) async {
    await pumpSearch(t);
    await typeQuery(t, 'رحم');
    final rows = await _allAyahRows(t);
    expect(rows, contains('1:1')); // ٱلرَّحۡمَٰنِ
    expect(rows, contains('2:157')); // وَرَحۡمَةٞ
    expect(rows, contains('3:132')); // تُرۡحَمُونَ
    expect(rows.toSet().length, rows.length);
  });

  testWidgets(
    '«ال» shows «الآيات · 5182», 100 rows in Mushaf order and the more-line under the last',
    (t) async {
      await pumpSearch(t);
      await typeQuery(t, 'ال');
      // the surah group stands first (every name with «ال»): the ayah heading is down the list
      await t.scrollUntilVisible(
        find.byKey(_ayatHeading),
        400,
        scrollable: _scrollable,
      );
      expect(
        find.descendant(
          of: find.byKey(_ayatHeading),
          matching: find.text('الآيات · 5182'),
        ),
        findsOneWidget,
      );
      expect(kAyahHeading(5182), 'الآيات · 5182');
      final rows = await _allAyahRows(t);
      expect(rows, hasLength(100));
      final order = [for (final r in rows) index.indexOf(_ref(r))];
      expect(order, [...order]..sort());
      expect(rows.first, '1:1');
      await t.scrollUntilVisible(
        find.byKey(_moreLine),
        400,
        scrollable: _scrollable,
      );
      expect(
        find.descendant(
          of: find.byKey(_moreLine),
          matching: find.text(kSearchTooMany),
        ),
        findsOneWidget,
      );
      final last = find.byKey(ValueKey('ayah-row-${rows.last}'));
      expect(last, findsOneWidget, reason: 'the last row is reachable');
      expect(
        t.getTopLeft(find.byKey(_moreLine)).dy,
        greaterThanOrEqualTo(t.getBottomLeft(last).dy),
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('a query with 100 hits or fewer has no more-line', (t) async {
    await pumpSearch(t);
    await typeQuery(t, 'بسم الله الرحمن الرحيم');
    expect(find.byKey(_moreLine), findsNothing);
    expect(find.text(kSearchTooMany), findsNothing);
  });

  for (final percent in [80, 100, 150]) {
    testWidgets(
      '2:282 shows whole consecutive stored words with «…», at most three lines, at $percent%',
      (t) async {
        await pumpSearch(t, readingPercent: percent);
        await typeQuery(t, 'تداينتم');
        expect(_ayahRows(t), ['2:282']);
        final rich = _rich(t, 2, 282);
        final words = stored(2, 282);
        final plain = rich.text.toPlainText();
        expect(plain, endsWith(' $kSnippetCut'));
        final cutBefore = plain.startsWith('$kSnippetCut ');
        final shown = plain
            .substring(cutBefore ? 2 : 0, plain.length - 2)
            .split(' ');
        expect(shown.length, greaterThanOrEqualTo(2));
        final from = words.indexOf(shown.first);
        expect(from, cutBefore ? greaterThan(0) : 0);
        expect(
          shown,
          words.sublist(from, from + shown.length),
          reason: 'a run of whole consecutive stored words',
        );
        expect(shown, contains('تَدَايَنتُم'));
        // three lines at most, measured as the row draws it
        final box = t.renderObject<RenderBox>(
          find.descendant(
            of: _snippet(2, 282),
            matching: find.byType(RichText),
          ),
        );
        final painter = TextPainter(
          text: rich.text,
          textDirection: TextDirection.rtl,
          textScaler: rich.textScaler,
        )..layout(maxWidth: box.size.width);
        expect(painter.computeLineMetrics().length, lessThanOrEqualTo(3));
        expect(
          painter.computeLineMetrics().length,
          3,
          reason: 'the room is used',
        );
        painter.dispose();
        expect(rich.maxLines, anyOf(isNull, 3));
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'a tap on the row of 112:1 pops AyahTarget(112:1, 604); a second tap in the same frame is ignored',
    (t) async {
      final run = await pumpSearch(t);
      await typeQuery(t, 'قل هو الله احد');
      final ink = t.widget<InkWell>(
        find.descendant(of: _row(112, 1), matching: find.byType(InkWell)),
      );
      ink.onTap!();
      ink.onTap!();
      await settleSearch(t);
      expect(run.popped, isTrue);
      final target = run.result! as AyahTarget;
      expect(target.ref, const AyahRef(112, 1));
      expect(target.page, 604);
      expect(find.byKey(const ValueKey('search-home')), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('the row of 2:282 pops page 48, where the ayah begins', (
    t,
  ) async {
    final run = await pumpSearch(t);
    await typeQuery(t, 'تداينتم');
    expect(
      find.descendant(of: _row(2, 282), matching: find.text('ص 48')),
      findsOneWidget,
    );
    await t.tap(_row(2, 282));
    await settleSearch(t);
    final target = run.result! as AyahTarget;
    expect(target.ref, const AyahRef(2, 282));
    expect(target.page, 48);
  });

  testWidgets(
    '«ذو القرنين» shows no ayah heading and, with no surah match, the none state',
    (t) async {
      await pumpSearch(t);
      await typeQuery(t, 'ذو القرنين');
      expect(find.byKey(_ayatHeading), findsNothing);
      expect(find.byKey(_surahsHeading), findsNothing);
      expect(find.text(kSearchNone), findsOneWidget);
      expect(_ayahRows(t), isEmpty);
    },
  );

  testWidgets('the ayah group stands under the surah group', (t) async {
    await pumpSearch(t);
    await typeQuery(t, 'الاخلاص');
    expect(find.byKey(const ValueKey('surah-row-112')), findsOneWidget);
    await typeQuery(t, 'مريم');
    expect(find.byKey(const ValueKey('surah-row-19')), findsOneWidget);
    expect(find.byKey(_ayatHeading), findsOneWidget);
    expect(
      t.getTopLeft(find.byKey(const ValueKey('surah-row-19'))).dy,
      lessThan(t.getTopLeft(find.byKey(_ayatHeading)).dy),
    );
  });

  testWidgets(
    'the ayah heading is a header «الآيات، عدد النتائج N» and a row is one button with its place and words',
    (t) async {
      final handle = t.ensureSemantics();
      await pumpSearch(t);
      await typeQuery(t, 'تداينتم');
      final heading = t.getSemantics(find.byKey(_ayatHeading));
      expect(heading.flagsCollection.isHeader, isTrue);
      expect(heading.label, kAyahHeadingSemantics(1));
      final node = t.getSemantics(_row(2, 282));
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.label, startsWith(kAyahRowSemantics('البقرة', 282, 48)));
      expect(node.label, contains('تَدَايَنتُم'));
      expect(node.label, isNot(contains(kSnippetCut)));
      handle.dispose();
    },
  );
}

AyahRef _ref(String key) {
  final parts = key.split(':');
  return AyahRef(int.parse(parts[0]), int.parse(parts[1]));
}
