// Feature 011, T057: what a screen reader gets from the search screen (spec FR-027, User Story 6 scenario 4; research
// D13; contracts/ui.md "Semantics"): the field's name, the clear button, each heading as a header with its count, each
// row as one button with its whole label, the lines as text, the order, and ONE announcement after 700 ms of quiet.
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/search/arabic_fold.dart';
import 'package:mushaf/search/search_screen.dart';
import 'package:mushaf/search/search_service.dart';
import 'package:mushaf/search/search_strings.dart';
import 'package:mushaf/search/surah_search.dart';

import '../support/search_harness.dart';
import '../support/search_quality_harness.dart';

/// The name of surah 114, and a word of more than a hundred ayat.
const _people = 'الناس';

/// Surah 112, ayah 1, whole.
const _ikhlas = 'قل هو الله احد';

/// A word of 2:282 only: the longest ayah, whose snippet leaves words out.
const _debt = 'تداينتم';

/// Found nowhere as typed.
const _nowhere = 'ذو القرنين';

/// Surah 18 by its name.
const _cave = 'كهف';

/// Lets [time] pass a frame at a time, as on a phone (a timer and the frame that follows it are then never far apart).
Future<void> frames(WidgetTester t, Duration time) async {
  const frame = Duration(milliseconds: 16);
  for (var passed = Duration.zero; passed < time; passed += frame) {
    await t.pump(frame);
  }
}

SemanticsData dataOf(WidgetTester t, Finder finder) =>
    t.getSemantics(finder).getSemanticsData();

/// What a screen reader says for the node: its label, or its tooltip when it has no label.
String spoken(SemanticsData data) =>
    data.label.isNotEmpty ? data.label : data.tooltip;

bool canTap(SemanticsData data) => data.hasAction(SemanticsAction.tap);

/// The nodes a screen reader walks through, in its order, as what it says for each (the nodes that say nothing left
/// out).
List<String> traversal(WidgetTester t) => [
  for (final node in t.semantics.simulatedAccessibilityTraversal())
    if (spoken(node.getSemanticsData()).isNotEmpty)
      spoken(node.getSemanticsData()),
];

/// The words of the snippet of [row] as shown, without the cut mark.
List<String> shownWords(WidgetTester t, Finder row) => t
    .widget<RichText>(snippetIn(row))
    .text
    .toPlainText()
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty && w != kSnippetCut)
    .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MushafMeta meta;
  late Map<String, AyahSearchResult> answers;
  late AyahSearchResult people;

  /// A letter that is in no surah's name.
  late String loneLetter;

  setUpAll(() async {
    meta = await realMeta();
    answers = await realAnswers([_people, _ikhlas, _debt, _nowhere]);
    people = answers.values.first;
    loneLetter = [for (var c = 0x628; c <= 0x64A; c++) String.fromCharCode(c)]
        .firstWhere(
          (l) =>
              ArabicFold.letters(ArabicFold.query(l)) == 1 &&
              searchSurahs(meta.surahs, l).isEmpty,
        );
  });

  test(
    'the queries of this file are what their names say (the real index)',
    () {
      expect(searchSurahs(meta.surahs, _people).map((s) => s.number), [114]);
      expect(people.total, greaterThan(AyahSearchResult.maxRows));
      expect(answers.values.elementAt(2).hits.map((h) => h.ref.key), ['2:282']);
      expect(answers.values.elementAt(3).total, 0);
    },
  );

  group('the field and its button', () {
    testWidgets('the field is a text field named by its label', (t) async {
      final handle = t.ensureSemantics();
      await pumpSearch(t);
      final fields = [
        for (final node in t.semantics.simulatedAccessibilityTraversal())
          if (node.getSemanticsData().flagsCollection.isTextField)
            node.getSemanticsData(),
      ];
      expect(fields, hasLength(1));
      expect(fields.single.label, kSearchFieldLabel);
      await typeQuery(t, _cave);
      final typed = [
        for (final node in t.semantics.simulatedAccessibilityTraversal())
          if (node.getSemanticsData().flagsCollection.isTextField)
            node.getSemanticsData(),
      ].single;
      expect(
        typed.label,
        kSearchFieldLabel,
        reason: 'the name stays once text is typed',
      );
      expect(typed.value, _cave);
      handle.dispose();
    });

    testWidgets('the clear button is a button that says «مسح»', (t) async {
      final handle = t.ensureSemantics();
      await pumpSearch(t);
      await typeQuery(t, _cave);
      final clear = dataOf(t, searchClear);
      expect(spoken(clear), kSearchClear);
      expect(clear.flagsCollection.isButton, isTrue);
      expect(canTap(clear), isTrue);
      handle.dispose();
    });
  });

  group('the headings', () {
    testWidgets(
      'each is a header that says the group and its count, not the visible text',
      (t) async {
        final handle = t.ensureSemantics();
        await pumpSearch(t);
        await typeQuery(t, _people);
        final surahs = dataOf(t, surahsHeading);
        expect(surahs.flagsCollection.isHeader, isTrue);
        expect(surahs.label, kSurahHeadingSemantics(1));
        final ayat = dataOf(t, ayatHeading);
        expect(ayat.flagsCollection.isHeader, isTrue);
        expect(ayat.label, kAyahHeadingSemantics(people.total));
        expect(
          people.total,
          isNot(AyahSearchResult.maxRows),
          reason: 'the true total',
        );
        // the visible «السور · N» is not read at all
        final said = traversal(t);
        expect(said, isNot(contains(kSurahHeading(1))));
        expect(said, isNot(contains(kAyahHeading(people.total))));
        expect(said.where((s) => s.contains('·')), isEmpty);
        expect(canTap(surahs), isFalse);
        expect(canTap(ayat), isFalse);
        handle.dispose();
      },
    );
  });

  group('the rows', () {
    testWidgets('a surah row is one button: «سورة {name}، صفحة N»', (t) async {
      final handle = t.ensureSemantics();
      await pumpSearch(t);
      await typeQuery(t, _cave);
      final node = t.getSemantics(surahRow(18));
      final row = node.getSemanticsData();
      expect(row.label, kSurahRowSemantics(meta.surah(18).name, 293));
      expect(row.flagsCollection.isButton, isTrue);
      expect(canTap(row), isTrue);
      expect(
        node.childrenCount,
        0,
        reason:
            'one node: the number, the name and the page are not read apart',
      );
      final said = traversal(t);
      expect(
        said.where((s) => s == row.label),
        hasLength(1),
        reason: 'the row is read once',
      );
      expect(
        said,
        isNot(contains(meta.surah(18).name)),
        reason: 'the name is not read apart',
      );
      expect(
        said,
        isNot(contains(kPageShort(293))),
        reason: 'the page is not read apart',
      );
      handle.dispose();
    });

    testWidgets(
      'an ayah row is one button: «سورة {name}، آية N، صفحة N» then the snippet words',
      (t) async {
        final handle = t.ensureSemantics();
        await pumpSearch(t);
        await typeQuery(t, _ikhlas);
        final node = t.getSemantics(ayahRow(112, 1));
        final row = node.getSemanticsData();
        final place = kAyahRowSemantics(
          meta.surah(112).name,
          1,
          meta.pageOfAyah(112, 1),
        );
        expect(row.label, startsWith(place));
        final rest = row.label.substring(place.length);
        final words = shownWords(t, ayahRow(112, 1));
        expect(words, hasLength(4));
        expect(
          rest.split(RegExp(r'\s+')).where((w) => w.isNotEmpty),
          words,
          reason: 'the words of the snippet follow, as stored',
        );
        expect(row.flagsCollection.isButton, isTrue);
        expect(canTap(row), isTrue);
        expect(node.childrenCount, 0, reason: 'one node for the whole row');
        expect(traversal(t).where((s) => s.contains(words.first)), [
          row.label,
        ], reason: 'the snippet is read once, inside the row');
        handle.dispose();
      },
    );

    testWidgets('a snippet that leaves words out is read without «…»', (
      t,
    ) async {
      final handle = t.ensureSemantics();
      await pumpSearch(t);
      await typeQuery(t, _debt);
      final shown = t
          .widget<RichText>(snippetIn(ayahRow(2, 282)))
          .text
          .toPlainText();
      expect(shown, contains(kSnippetCut), reason: 'the eye sees the cut mark');
      final row = dataOf(t, ayahRow(2, 282));
      final place = kAyahRowSemantics(meta.surah(2).name, 282, 48);
      expect(row.label, startsWith(place));
      expect(row.label, isNot(contains(kSnippetCut)));
      expect(row.label, isNot(contains('...')));
      expect(
        row.label
            .substring(place.length)
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty),
        shownWords(t, ayahRow(2, 282)),
      );
      expect(traversal(t).where((s) => s.contains(kSnippetCut)), isEmpty);
      handle.dispose();
    });
  });

  group('the lines and the button', () {
    testWidgets('the lines are plain text: not a button, not a header', (
      t,
    ) async {
      final handle = t.ensureSemantics();
      // a line is read as text, alone or together with the line under it
      void expectPlain(String line) {
        final data = dataOf(t, find.text(line));
        expect(data.label.split('\n'), contains(line), reason: line);
        expect(data.flagsCollection.isButton, isFalse, reason: line);
        expect(data.flagsCollection.isHeader, isFalse, reason: line);
        expect(data.flagsCollection.isTextField, isFalse, reason: line);
        expect(canTap(data), isFalse, reason: line);
        expect(
          traversal(t).expand((s) => s.split('\n')).where((s) => s == line),
          hasLength(1),
          reason: '«$line» is read once',
        );
      }

      final service = ScriptedSearchService(phase: IndexPhase.preparing);
      await pumpSearch(t, service: service);
      expectPlain(kSearchHint);
      await typeQuery(t, loneLetter);
      expectPlain(kSearchNeedTwo);
      await typeQuery(t, _nowhere);
      expectPlain(kSearchPreparing);
      service.setPhase(IndexPhase.failed);
      await t.pump();
      await t.pump();
      expectPlain(kSearchFailed);
      service.setPhase(IndexPhase.ready);
      await t.pump();
      await t.pump();
      expectPlain(kSearchNone);
      expectPlain(kSearchNoneAdvice);
      handle.dispose();
    });

    testWidgets('«إعادة المحاولة» is a button', (t) async {
      final handle = t.ensureSemantics();
      await pumpSearch(
        t,
        service: ScriptedSearchService(phase: IndexPhase.failed),
      );
      await typeQuery(t, _nowhere);
      final retry = dataOf(t, searchRetry);
      expect(retry.label, kSearchRetry);
      expect(retry.flagsCollection.isButton, isTrue);
      expect(canTap(retry), isTrue);
      final said = traversal(t);
      expect(
        said.indexOf(kSearchFailed),
        lessThan(said.indexOf(kSearchRetry)),
        reason: 'the line is read before its button',
      );
      handle.dispose();
    });

    testWidgets('the more-line is plain text', (t) async {
      final handle = t.ensureSemantics();
      await pumpSearch(t);
      await typeQuery(t, _people);
      await t.scrollUntilVisible(
        searchMoreLine,
        600,
        scrollable: searchList,
        maxScrolls: 400,
      );
      final more = dataOf(t, searchMoreLine);
      expect(more.label, kSearchTooMany);
      expect(more.flagsCollection.isButton, isFalse);
      expect(canTap(more), isFalse);
      handle.dispose();
    });
  });

  testWidgets(
    'the order: field, clear, surah heading, its rows, ayah heading, its rows, the more-line',
    (t) async {
      final handle = t.ensureSemantics();
      await pumpSearch(t);
      await typeQuery(t, _people);
      String rowLabel(AyahHit hit) => kAyahRowSemantics(
        meta.surah(hit.ref.surah).name,
        hit.ref.ayah,
        hit.page,
      );

      final top = traversal(t);
      int at(String what) {
        final i = top.indexWhere(
          (s) => s == what || s.startsWith('$what\n') || s.startsWith('$what '),
        );
        expect(i, isNonNegative, reason: '«$what» is read; read: $top');
        return i;
      }

      final order = [
        at(kSearchFieldLabel),
        at(kSearchClear),
        at(kSurahHeadingSemantics(1)),
        at(kSurahRowSemantics(meta.surah(114).name, meta.surah(114).startPage)),
        at(kAyahHeadingSemantics(people.total)),
        at(rowLabel(people.hits[0])),
        at(rowLabel(people.hits[1])),
      ];
      expect(order, orderedEquals([...order]..sort()), reason: '$top');
      expect(order.toSet(), hasLength(order.length));

      // the end of the list: the last rows, then the line that asks for more words, and nothing after it
      await t.scrollUntilVisible(
        searchMoreLine,
        600,
        scrollable: searchList,
        maxScrolls: 400,
      );
      await t.pump();
      final end = traversal(t);
      final last = end.indexWhere(
        (s) => s.startsWith(rowLabel(people.hits[99])),
      );
      final beforeLast = end.indexWhere(
        (s) => s.startsWith(rowLabel(people.hits[98])),
      );
      final more = end.indexOf(kSearchTooMany);
      expect(last, isNonNegative, reason: '$end');
      expect(more, isNonNegative, reason: '$end');
      expect(beforeLast, lessThan(last));
      expect(last, lessThan(more));
      expect(
        more,
        end.length - 1,
        reason: 'nothing is read after the more-line',
      );
      expect(
        end.indexOf(kSearchFieldLabel),
        lessThan(beforeLast),
        reason: 'the field stays first',
      );
      handle.dispose();
    },
  );

  group('the announcement', () {
    testWidgets(
      'typing letter by letter sends ONE, 700 ms after the last letter: the two headings\' labels',
      (t) async {
        final sent = recordAnnouncements(t);
        await pumpSearch(t);
        for (var n = 1; n <= _people.length; n++) {
          await typeQuery(t, _people.substring(0, n));
          await t.pump(const Duration(milliseconds: 150));
          expect(
            sent,
            isEmpty,
            reason: 'never per letter (${_people.substring(0, n)})',
          );
        }
        await t.pump(const Duration(milliseconds: 500));
        expect(
          sent,
          isEmpty,
          reason: '650 ms after the last letter: still quiet time',
        );
        await t.pump(const Duration(milliseconds: 100));
        expect(sent, [
          '${kSurahHeadingSemantics(1)}. ${kAyahHeadingSemantics(people.total)}',
        ]);
        await t.pump(const Duration(seconds: 5));
        expect(sent, hasLength(1), reason: 'once');
      },
    );

    testWidgets(
      'only one group: its label alone; nothing found: «لا توجد نتائج»',
      (t) async {
        final sent = recordAnnouncements(t);
        await pumpSearch(t);
        await typeQuery(t, _ikhlas);
        await t.pump(const Duration(milliseconds: 800));
        expect(sent, [
          kAyahHeadingSemantics(answers.values.elementAt(1).total),
        ]);
        await typeQuery(t, _nowhere);
        await t.pump(const Duration(milliseconds: 650));
        expect(sent, hasLength(1));
        await t.pump(const Duration(milliseconds: 100));
        expect(sent.last, kSearchNone);
        expect(sent, hasLength(2));
      },
    );

    testWidgets(
      'none when nothing changed, none for the lines, none per frame',
      (t) async {
        final sent = recordAnnouncements(t);
        final run = await pumpSearch(t);
        await t.pump(const Duration(seconds: 2));
        expect(
          sent,
          isEmpty,
          reason: 'opening says nothing (the hint is on screen to be read)',
        );
        await typeQuery(t, loneLetter);
        await t.pump(const Duration(seconds: 2));
        expect(sent, isEmpty, reason: 'the need-two line is not announced');

        await typeQuery(t, _ikhlas);
        await t.pump(const Duration(seconds: 1));
        expect(sent, hasLength(1));
        // the same results again: a space more, a rotation, a new reading size
        await typeQuery(t, '$_ikhlas ');
        await t.pump(const Duration(seconds: 1));
        await typeQuery(t, ' $_ikhlas  ');
        await t.pump(const Duration(seconds: 1));
        t.view.physicalSize = const Size(915, 412);
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        await run.setSize(t, 150);
        await t.pump(const Duration(seconds: 1));
        expect(sent, hasLength(1), reason: 'nothing changed in the results');
      },
    );

    testWidgets('none after the screen is closed (closed at once)', (t) async {
      final sent = recordAnnouncements(t);
      final run = await pumpSearch(t);
      await typeQuery(t, _ikhlas);
      await t.binding.handlePopRoute();
      await frames(t, const Duration(seconds: 3));
      expect(run.popped, isTrue);
      expect(find.byType(SearchScreen), findsNothing);
      expect(
        sent,
        isEmpty,
        reason: 'the pending announcement left with the screen',
      );
      expect(t.takeException(), isNull);
    });

    testWidgets(
      'none after the screen is closed (the quiet time ends while the route is on its way out)',
      (t) async {
        final sent = recordAnnouncements(t);
        final run = await pumpSearch(t);
        await typeQuery(t, _ikhlas);
        await frames(t, const Duration(milliseconds: 600));
        expect(sent, isEmpty);
        // back: search is closed for the reader now; the route takes a few hundred ms to leave the screen and the quiet
        // time ends 100 ms from here
        await t.binding.handlePopRoute();
        await t.pump();
        expect(
          run.navigator.currentState!.canPop(),
          isFalse,
          reason: 'the search route is popped',
        );
        await frames(t, const Duration(seconds: 3));
        expect(run.popped, isTrue);
        expect(
          sent,
          isEmpty,
          reason: 'the results of a screen that was left are not announced',
        );
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'the rows that appear when the preparation ends are announced once too',
      (t) async {
        final sent = recordAnnouncements(t);
        final service = ScriptedSearchService(
          phase: IndexPhase.preparing,
          answerOf: (folded) =>
              answers[folded] ?? const AyahSearchResult(total: 0, hits: []),
        );
        await pumpSearch(t, service: service);
        await typeQuery(t, _ikhlas);
        await t.pump(const Duration(seconds: 2));
        expect(sent, isEmpty, reason: 'the preparing line is not announced');
        service.setPhase(IndexPhase.ready);
        await t.pump();
        await t.pump(const Duration(milliseconds: 650));
        expect(sent, isEmpty);
        await t.pump(const Duration(milliseconds: 100));
        expect(sent, [
          kAyahHeadingSemantics(answers.values.elementAt(1).total),
        ]);
      },
    );
  });
}
