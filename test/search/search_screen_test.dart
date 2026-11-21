// Feature 011, T020: the search screen, its field and its surah group, pumped directly over `SearchService.prepared` over the
// real index (spec FR-002, FR-004, FR-008, FR-009, FR-010, User Story 1 scenarios 1-7; research D3, D12; contracts/ui.md
// "The screen", "States", "Rows"). The ayah group is T030's; here the ayah group's lines and the stand-in service states.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/search/search_screen.dart';
import 'package:mushaf/search/search_service.dart';
import 'package:mushaf/search/search_strings.dart';
import 'package:mushaf/search/surah_search.dart';

import '../support/search_harness.dart';

const _field = ValueKey('search-field');
const _clear = ValueKey('search-clear');
const _surahsHeading = ValueKey('search-heading-surahs');
const _ayatHeading = ValueKey('search-heading-ayat');
const _retry = ValueKey('search-retry');

Finder _row(int surah) => find.byKey(ValueKey('surah-row-$surah'));

/// The keys of the surah rows on screen, in the order of the tree.
List<String> _surahRows(WidgetTester t) => [
  for (final w in t.widgetList(
    find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('surah-row-'),
    ),
  ))
    (w.key! as ValueKey<String>).value,
];

TextField _textField(WidgetTester t) => t.widget<TextField>(find.byKey(_field));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MushafMeta meta;
  setUpAll(() async {
    meta = await realMeta();
    await realIndex();
  });

  group('the app bar and the field', () {
    testWidgets('the app bar is «بحث» with a back arrow', (t) async {
      await pumpSearch(t);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(kSearchLabel),
        ),
        findsOneWidget,
      );
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets(
      'the field has the label, the focus and the keyboard when the screen opens',
      (t) async {
        await pumpSearch(t);
        final field = _textField(t);
        expect(field.decoration!.labelText, kSearchFieldLabel);
        expect(field.autofocus, isTrue);
        final focus = FocusManager.instance.primaryFocus;
        expect(focus, isNotNull);
        expect(
          find.descendant(
            of: find.byKey(_field),
            matching: find.byWidgetPredicate(
              (w) => w is EditableText && w.focusNode == focus,
            ),
          ),
          findsOneWidget,
          reason: 'the field has the focus',
        );
        expect(t.testTextInput.isVisible, isTrue, reason: 'the keyboard is up');
      },
    );

    testWidgets(
      'the field is single line and never corrects, suggests, learns, formats or limits (FR-008, D12)',
      (t) async {
        await pumpSearch(t);
        final field = _textField(t);
        expect(field.maxLines, 1);
        expect(field.autocorrect, isFalse);
        expect(field.enableSuggestions, isFalse);
        expect(field.enableIMEPersonalizedLearning, isFalse);
        expect(field.textInputAction, TextInputAction.search);
        expect(field.inputFormatters ?? const [], isEmpty);
        expect(field.maxLength, isNull);
      },
    );

    testWidgets('1,500 characters with tashkeel stay exactly as entered', (
      t,
    ) async {
      await pumpSearch(t);
      const unit = 'ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ';
      final text = (unit * 100).substring(0, 1500);
      expect(text.length, 1500);
      await typeQuery(t, text);
      expect(_textField(t).controller!.text, text);
      expect(t.takeException(), isNull);
    });

    testWidgets(
      'the search key only closes the keyboard: nothing is submitted and the screen stays',
      (t) async {
        final run = await pumpSearch(t);
        await typeQuery(t, 'كهف');
        await t.testTextInput.receiveAction(TextInputAction.search);
        await t.pump();
        expect(run.popped, isFalse);
        expect(find.byType(SearchScreen), findsOneWidget);
        expect(_row(18), findsOneWidget);
      },
    );
  });

  group('the surah group', () {
    testWidgets('nothing typed shows the one line and no heading', (t) async {
      await pumpSearch(t);
      expect(find.text(kSearchHint), findsOneWidget);
      expect(find.byKey(_surahsHeading), findsNothing);
      expect(find.byKey(_ayatHeading), findsNothing);
      expect(find.byKey(_clear), findsNothing);
    });

    testWidgets(
      '«كهف» shows the heading «السور · 1» and the row 18 with its number, name and page',
      (t) async {
        await pumpSearch(t);
        await typeQuery(t, 'كهف');
        expect(
          find.descendant(
            of: find.byKey(_surahsHeading),
            matching: find.text(kSurahHeading(1)),
          ),
          findsOneWidget,
        );
        expect(kSurahHeading(1), 'السور · 1');
        final row = _row(18);
        expect(row, findsOneWidget);
        expect(
          find.descendant(of: row, matching: find.text('18')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: row, matching: find.text('الكهف')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: row, matching: find.text('ص 293')),
          findsOneWidget,
        );
        expect(find.text(kSearchHint), findsNothing);
      },
    );

    testWidgets('«سبا» shows surah 34 with its name as the index writes it', (
      t,
    ) async {
      await pumpSearch(t);
      await typeQuery(t, 'سبا');
      expect(_row(34), findsOneWidget);
      expect(
        find.descendant(of: _row(34), matching: find.text(meta.surah(34).name)),
        findsOneWidget,
      );
    });

    testWidgets('«الحج» shows 22, 15, 49 in that order under «السور · 3»', (
      t,
    ) async {
      await pumpSearch(t);
      await typeQuery(t, 'الحج');
      expect(
        find.descendant(
          of: find.byKey(_surahsHeading),
          matching: find.text('السور · 3'),
        ),
        findsOneWidget,
      );
      final tops = [
        for (final s in [22, 15, 49]) t.getTopLeft(_row(s)).dy,
      ];
      expect(tops[0], lessThan(tops[1]));
      expect(tops[1], lessThan(tops[2]));
      expect(_surahRows(t), hasLength(3));
    });

    testWidgets('«سورة الكهف» shows 18', (t) async {
      await pumpSearch(t);
      await typeQuery(t, 'سورة الكهف');
      expect(_row(18), findsOneWidget);
    });

    testWidgets('a surah row is at least 56 px high and 48 px wide', (t) async {
      await pumpSearch(t);
      await typeQuery(t, 'كهف');
      expect(t.getSize(_row(18)).height, greaterThanOrEqualTo(56));
      expect(t.getSize(_row(18)).width, greaterThanOrEqualTo(48));
    });

    testWidgets(
      '«ق» lists 50 first and the one line that asks for a second letter, with no ayah heading',
      (t) async {
        await pumpSearch(t);
        await typeQuery(t, 'ق');
        expect(_row(50), findsOneWidget);
        expect(_surahRows(t).first, 'surah-row-50');
        // the line stands under the surah group: many names have a «ق», so it is down the list
        await t.scrollUntilVisible(
          find.text(kSearchNeedTwo),
          300,
          scrollable: find.descendant(
            of: find.byKey(const ValueKey('search-results')),
            matching: find.byType(Scrollable),
          ),
        );
        expect(find.text(kSearchNeedTwo), findsOneWidget);
        expect(find.byKey(_ayatHeading), findsNothing);
      },
    );

    testWidgets(
      'one letter that matches no surah still shows the need-two line',
      (t) async {
        await pumpSearch(t);
        final letter = [
          for (var c = 0x627; c <= 0x64A; c++) String.fromCharCode(c),
        ].firstWhere((l) => searchSurahs(meta.surahs, l).isEmpty && l != 'ء');
        await typeQuery(t, letter);
        expect(find.byKey(_surahsHeading), findsNothing);
        expect(find.text(kSearchNeedTwo), findsOneWidget);
      },
    );

    testWidgets('a query with no Arabic letter shows the hint and no error', (
      t,
    ) async {
      await pumpSearch(t);
      for (final typed in ['123', 'abc', '﴿ ﴾', '   ']) {
        await typeQuery(t, typed);
        expect(find.text(kSearchHint), findsOneWidget, reason: typed);
        expect(find.byKey(_surahsHeading), findsNothing, reason: typed);
        expect(find.text(kSearchNeedTwo), findsNothing, reason: typed);
      }
    });
  });

  group('the clear button', () {
    testWidgets(
      'is absent while the field is empty, is 48 x 48 once there is text, and clears it',
      (t) async {
        await pumpSearch(t);
        expect(find.byKey(_clear), findsNothing);
        await typeQuery(t, 'كهف');
        expect(find.byKey(_clear), findsOneWidget);
        expect(t.getSize(find.byKey(_clear)), const Size(48, 48));
        expect(find.byTooltip(kSearchClear), findsOneWidget);
        await t.tap(find.byKey(_clear));
        await t.pump();
        await t.pump();
        expect(_textField(t).controller!.text, isEmpty);
        expect(find.byKey(_clear), findsNothing);
        expect(find.text(kSearchHint), findsOneWidget);
        expect(find.byKey(_surahsHeading), findsNothing);
        expect(_row(18), findsNothing);
      },
    );

    testWidgets('keeps the focus in the field so the keyboard stays up', (
      t,
    ) async {
      await pumpSearch(t);
      await typeQuery(t, 'كهف');
      await t.tap(find.byKey(_clear));
      await t.pump();
      expect(t.testTextInput.isVisible, isTrue);
    });
  });

  group('leaving', () {
    testWidgets(
      'a tap on a surah row pops the int first page; a second tap in the same frame is ignored',
      (t) async {
        final run = await pumpSearch(t);
        await typeQuery(t, 'كهف');
        final tile = t.widget<ListTile>(
          find.descendant(of: _row(18), matching: find.byType(ListTile)),
        );
        tile.onTap!();
        tile.onTap!(); // the framework would ignore a real second touch only from the next frame on
        await settleSearch(t);
        expect(run.popped, isTrue);
        expect(run.result, 293);
        expect(run.result, isA<int>());
        expect(find.byType(SearchScreen), findsNothing);
        expect(find.byKey(const ValueKey('search-home')), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets('the system back pops without a value', (t) async {
      final run = await pumpSearch(t);
      await typeQuery(t, 'كهف');
      await t.binding.handlePopRoute();
      await settleSearch(t);
      expect(run.popped, isTrue);
      expect(run.result, isNull);
      expect(find.byType(SearchScreen), findsNothing);
    });

    testWidgets('the back arrow pops without a value', (t) async {
      final run = await pumpSearch(t);
      await t.tap(find.byType(BackButton));
      await settleSearch(t);
      expect(run.popped, isTrue);
      expect(run.result, isNull);
    });
  });

  group('the first use', () {
    testWidgets(
      'the screen starts the preparation once and listens to nothing while it builds',
      (t) async {
        final service = ScriptedSearchService(phase: IndexPhase.notStarted);
        await pumpSearch(t, service: service);
        expect(service.prepareCalls, 1);
        expect(t.takeException(), isNull);
      },
    );
  });

  group('the ayah group of the lines', () {
    testWidgets(
      'two letters while the service is preparing show the surah rows and the preparing line',
      (t) async {
        final service = ScriptedSearchService(phase: IndexPhase.preparing);
        await pumpSearch(t, service: service);
        await typeQuery(t, 'كهف');
        expect(_row(18), findsOneWidget);
        expect(find.text(kSearchPreparing), findsOneWidget);
        expect(find.byKey(_ayatHeading), findsNothing);
        service.setPhase(IndexPhase.ready);
        await t.pump();
        await t.pump();
        expect(find.text(kSearchPreparing), findsNothing);
      },
    );

    testWidgets(
      'failed shows the failure line and the retry button, 48 high; tapping it runs retry',
      (t) async {
        final service = ScriptedSearchService(phase: IndexPhase.failed);
        await pumpSearch(t, service: service);
        await typeQuery(t, 'كهف');
        expect(find.text(kSearchFailed), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(_retry),
            matching: find.text(kSearchRetry),
          ),
          findsOneWidget,
        );
        expect(t.getSize(find.byKey(_retry)).height, greaterThanOrEqualTo(48));
        expect(_row(18), findsOneWidget, reason: 'the surah rows still work');
        await t.tap(find.byKey(_retry));
        await t.pump();
        expect(service.retryCalls, 1);
      },
    );

    testWidgets(
      'ready with nothing in either group shows the none line and its advice, with no heading',
      (t) async {
        await pumpSearch(t);
        await typeQuery(t, 'ذو القرنين');
        expect(find.text(kSearchNone), findsOneWidget);
        expect(find.text(kSearchNoneAdvice), findsOneWidget);
        expect(find.byKey(_surahsHeading), findsNothing);
        expect(find.byKey(_ayatHeading), findsNothing);
      },
    );

    testWidgets(
      'ready with a surah match and no ayah shows only the surah group',
      (t) async {
        final service = ScriptedSearchService();
        await pumpSearch(t, service: service);
        await typeQuery(t, 'كهف');
        expect(_row(18), findsOneWidget);
        expect(find.text(kSearchNone), findsNothing);
        expect(find.byKey(_ayatHeading), findsNothing);
      },
    );
  });

  group('typing again', () {
    testWidgets('a new query puts the list back at the top', (t) async {
      await pumpSearch(t);
      await typeQuery(t, 'ا');
      final list = find.descendant(
        of: find.byKey(const ValueKey('search-results')),
        matching: find.byType(Scrollable),
      );
      await t.drag(list, const Offset(0, -2000));
      await t.pump();
      final scrollable = t.state<ScrollableState>(list);
      expect(scrollable.position.pixels, greaterThan(0));
      await typeQuery(t, 'ال');
      expect(scrollable.position.pixels, 0);
    });
  });

  group('the screen reader', () {
    testWidgets(
      'each group heading is a header whose label is the semantics label, not the visible text',
      (t) async {
        final handle = t.ensureSemantics();
        await pumpSearch(t);
        await typeQuery(t, 'كهف');
        final node = t.getSemantics(find.byKey(_surahsHeading));
        expect(node.flagsCollection.isHeader, isTrue);
        expect(node.label, kSurahHeadingSemantics(1));
        expect(node.label, isNot(contains('·')));
        handle.dispose();
      },
    );

    testWidgets(
      'a surah row is one button «سورة {name}، صفحة N» that a screen reader can tap',
      (t) async {
        final handle = t.ensureSemantics();
        final run = await pumpSearch(t);
        await typeQuery(t, 'كهف');
        final node = t.getSemantics(_row(18));
        expect(node.label, kSurahRowSemantics('الكهف', 293));
        expect(node.flagsCollection.isButton, isTrue);
        t.semantics.tap(
          find.semantics.byLabel(kSurahRowSemantics('الكهف', 293)),
        );
        await settleSearch(t);
        expect(run.result, 293);
        handle.dispose();
      },
    );

    testWidgets(
      'the results are announced once, 700 ms after the last letter, never per letter',
      (t) async {
        final sent = <String>[];
        t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
          SystemChannels.accessibility,
          (message) async {
            final map = message as Map;
            if (map['type'] == 'announce') {
              sent.add((map['data'] as Map)['message'] as String);
            }
            return null;
          },
        );
        addTearDown(
          () => t.binding.defaultBinaryMessenger
              .setMockDecodedMessageHandler<dynamic>(
                SystemChannels.accessibility,
                null,
              ),
        );
        await pumpSearch(t, service: ScriptedSearchService());
        await typeQuery(t, 'ك');
        await t.pump(const Duration(milliseconds: 200));
        await typeQuery(t, 'كه');
        await t.pump(const Duration(milliseconds: 200));
        await typeQuery(t, 'كهف');
        await t.pump(const Duration(milliseconds: 600));
        expect(sent, isEmpty, reason: 'still inside the quiet time');
        await t.pump(const Duration(milliseconds: 200));
        expect(sent, [kSurahHeadingSemantics(1)]);
        await t.pump(const Duration(seconds: 2));
        expect(sent, hasLength(1));
      },
    );
  });
}
