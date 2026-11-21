// Feature 011, T050: every state of the search screen says what it is (spec FR-002, FR-009, FR-014, User Story 5
// scenarios 1-4, 6, 7; contracts/ui.md "States"). The screen runs over a service whose phase and answers the test
// controls (its answers are the real ones, taken from the real index beforehand), or over the prepared real one.
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

/// A name inside it lists surah 55; many ayat hold it (1:1 among them).
const _mercy = 'رحم';

/// Surah 112, ayah 1, whole; no surah has such a name.
const _ikhlas = 'قل هو الله احد';

/// The name of no surah and the words of no ayah as typed here.
const _nowhere = 'ذو القرنين';

/// Surah 18 by its name.
const _cave = 'كهف';

/// The four lines of the ayah group and the «nothing found» pair.
const _lines = [
  kSearchHint,
  kSearchNeedTwo,
  kSearchPreparing,
  kSearchFailed,
  kSearchNone,
  kSearchNoneAdvice,
];

/// Exactly [shown] of the lines are on screen, once each, and none of the others.
void expectLines(WidgetTester t, List<String> shown, {String? reason}) {
  for (final line in _lines) {
    expect(
      find.text(line),
      shown.contains(line) ? findsOneWidget : findsNothing,
      reason: '«$line»${reason == null ? '' : ' ($reason)'}',
    );
  }
}

/// Nothing is red, nothing is an error dialog or a snack bar, nothing was thrown (contracts/ui.md "States").
void expectCalm(WidgetTester t, {String? reason}) {
  expect(t.takeException(), isNull, reason: reason);
  expect(find.byType(Dialog), findsNothing, reason: reason);
  expect(find.byType(AlertDialog), findsNothing, reason: reason);
  expect(find.byType(SnackBar), findsNothing, reason: reason);
  expect(find.byType(MaterialBanner), findsNothing, reason: reason);
  expect(redThings(t), isEmpty, reason: reason);
  expect(find.byType(SearchScreen), findsOneWidget, reason: reason);
}

const _empty = AyahSearchResult(total: 0, hits: []);

Future<void> settleAnswer(WidgetTester t) async {
  await t.pump();
  await t.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MushafMeta meta;
  late Map<String, AyahSearchResult> answers;

  /// A letter that is in no surah's name.
  late String loneLetter;

  setUpAll(() async {
    meta = await realMeta();
    answers = await realAnswers([_mercy, _ikhlas, _nowhere, _cave]);
    loneLetter = [for (var c = 0x628; c <= 0x64A; c++) String.fromCharCode(c)]
        .firstWhere(
          (l) =>
              ArabicFold.letters(ArabicFold.query(l)) == 1 &&
              searchSurahs(meta.surahs, l).isEmpty,
        );
  });

  AyahSearchResult answerTo(String typed) => answers[ArabicFold.query(typed)]!;

  /// A service in [phase] that answers with the real answers once it is ready.
  ScriptedSearchService scripted(IndexPhase phase) => ScriptedSearchService(
    phase: phase,
    answerOf: (folded) => answers[folded] ?? _empty,
  );

  test(
    'the queries of this file are what their names say (the real index)',
    () {
      expect(
        searchSurahs(meta.surahs, _mercy).map((s) => s.number),
        contains(55),
      );
      expect(answerTo(_mercy).hits.first.ref.key, '1:1');
      expect(answerTo(_mercy).total, greaterThan(100));
      expect(searchSurahs(meta.surahs, _ikhlas), isEmpty);
      expect(answerTo(_ikhlas).hits.map((h) => h.ref.key), contains('112:1'));
      expect(
        answerTo(_ikhlas).hits.map((h) => h.ref.key),
        isNot(contains('1:1')),
      );
      expect(searchSurahs(meta.surahs, _nowhere), isEmpty);
      expect(answerTo(_nowhere).total, 0);
      expect(searchSurahs(meta.surahs, _cave).map((s) => s.number), [18]);
    },
  );

  group('two or more letters before the text is ready', () {
    for (final phase in [IndexPhase.notStarted, IndexPhase.preparing]) {
      testWidgets(
        '${phase.name}: the surah rows at once and the one line «preparing», no ayah heading',
        (t) async {
          await pumpSearch(t, service: scripted(phase));
          await typeQuery(t, _mercy);
          expect(surahsHeading, findsOneWidget);
          expect(surahRow(55), findsOneWidget);
          expectLines(t, [kSearchPreparing]);
          expect(ayatHeading, findsNothing);
          expect(ayahRowsBuilt(t), isEmpty);
          expect(searchRetry, findsNothing);
          expect(searchMoreLine, findsNothing);
          // the line stands under the surah group
          expect(
            t.getTopLeft(find.text(kSearchPreparing)).dy,
            greaterThan(t.getBottomLeft(surahRow(55)).dy - 0.01),
          );
          expectCalm(t);
        },
      );
    }

    testWidgets(
      'with no surah of that name the preparing line stands alone (nothing is «not found» yet)',
      (t) async {
        await pumpSearch(t, service: scripted(IndexPhase.preparing));
        await typeQuery(t, _nowhere);
        expect(surahsHeading, findsNothing);
        expect(surahRowsBuilt(t), isEmpty);
        expectLines(t, [kSearchPreparing]);
        expect(ayatHeading, findsNothing);
        expectCalm(t);
      },
    );

    testWidgets('a surah row works while the ayah text is being prepared', (
      t,
    ) async {
      final run = await pumpSearch(t, service: scripted(IndexPhase.preparing));
      await typeQuery(t, _cave);
      await t.tap(surahRow(18));
      await settleSearch(t);
      expect(run.popped, isTrue);
      expect(run.result, meta.surah(18).startPage);
    });

    testWidgets(
      'the ayah rows appear by themselves when it becomes ready, for the text in the field NOW',
      (t) async {
        final service = scripted(IndexPhase.preparing);
        await pumpSearch(t, service: service);
        await typeQuery(t, _mercy);
        expectLines(t, [kSearchPreparing]);
        // the text changes while the preparation still runs
        await typeQuery(t, _ikhlas);
        expectLines(t, [kSearchPreparing]);
        expect(ayahRowsBuilt(t), isEmpty);

        service.setPhase(IndexPhase.ready);
        await settleAnswer(t);

        expect(fieldText(t), _ikhlas);
        expectLines(t, []);
        expect(ayatHeading, findsOneWidget);
        expect(
          find.descendant(
            of: ayatHeading,
            matching: find.text(kAyahHeading(answerTo(_ikhlas).total)),
          ),
          findsOneWidget,
        );
        expect(ayahRow(112, 1), findsOneWidget);
        expect(
          ayahRowsBuilt(t),
          everyElement(isIn(answerTo(_ikhlas).hits.map((h) => h.ref.key))),
          reason: 'no row of the text that was in the field before',
        );
        expect(ayahRow(1, 1), findsNothing);
        expect(surahsHeading, findsNothing);
        expectCalm(t);
      },
    );

    testWidgets(
      'becoming ready with a text that is found nowhere shows «nothing found», not the preparing line',
      (t) async {
        final service = scripted(IndexPhase.preparing);
        await pumpSearch(t, service: service);
        await typeQuery(t, _nowhere);
        service.setPhase(IndexPhase.ready);
        await settleAnswer(t);
        expectLines(t, [kSearchNone, kSearchNoneAdvice]);
        expectCalm(t);
      },
    );
  });

  group('the preparation failed', () {
    testWidgets(
      'the failure line and under it the button «retry», 48 px high; no ayah heading',
      (t) async {
        await pumpSearch(t, service: scripted(IndexPhase.failed));
        await typeQuery(t, _cave);
        expectLines(t, [kSearchFailed]);
        expect(searchRetry, findsOneWidget);
        expect(
          find.descendant(of: searchRetry, matching: find.text(kSearchRetry)),
          findsOneWidget,
        );
        final button = t.getRect(searchRetry);
        expect(button.height, greaterThanOrEqualTo(48));
        expect(button.width, greaterThanOrEqualTo(48));
        expect(
          button.top,
          greaterThanOrEqualTo(
            t.getRect(find.text(kSearchFailed)).bottom - 0.01,
          ),
          reason: 'the button is under the line',
        );
        expect(ayatHeading, findsNothing);
        expect(ayahRowsBuilt(t), isEmpty);
        expectCalm(t);
      },
    );

    testWidgets('the surah rows still work', (t) async {
      final run = await pumpSearch(t, service: scripted(IndexPhase.failed));
      await typeQuery(t, _cave);
      expect(surahsHeading, findsOneWidget);
      expect(surahRowsBuilt(t), [18]);
      await t.tap(surahRow(18));
      await settleSearch(t);
      expect(run.popped, isTrue);
      expect(run.result, 293);
    });

    testWidgets(
      'with no surah of that name the failure line and the button stand alone',
      (t) async {
        await pumpSearch(t, service: scripted(IndexPhase.failed));
        await typeQuery(t, _nowhere);
        expectLines(t, [kSearchFailed]);
        expect(searchRetry, findsOneWidget);
        expect(surahsHeading, findsNothing);
        expectCalm(t);
      },
    );

    testWidgets(
      'tapping the button runs retry: the preparing line, then the rows when it succeeds',
      (t) async {
        final service = scripted(IndexPhase.failed);
        service.onRetry = () => service.setPhase(IndexPhase.preparing);
        await pumpSearch(t, service: service);
        await typeQuery(t, _ikhlas);
        expect(service.retryCalls, 0);

        await t.tap(searchRetry);
        await settleAnswer(t);
        expect(service.retryCalls, 1);
        expectLines(t, [kSearchPreparing]);
        expect(searchRetry, findsNothing);
        expectCalm(t);

        service.setPhase(IndexPhase.ready);
        await settleAnswer(t);
        expectLines(t, []);
        expect(searchRetry, findsNothing);
        expect(ayatHeading, findsOneWidget);
        expect(ayahRow(112, 1), findsOneWidget);
        expect(fieldText(t), _ikhlas);
        expectCalm(t);
      },
    );

    testWidgets(
      'a second failure shows the line and the button again, and a third try can succeed',
      (t) async {
        final service = scripted(IndexPhase.failed);
        service.onRetry = () => service.setPhase(IndexPhase.preparing);
        await pumpSearch(t, service: service);
        await typeQuery(t, _ikhlas);

        await t.tap(searchRetry);
        await settleAnswer(t);
        expectLines(t, [kSearchPreparing]);
        service.setPhase(IndexPhase.failed, failure: StateError('again'));
        await settleAnswer(t);
        expectLines(t, [kSearchFailed]);
        expect(searchRetry, findsOneWidget);
        expect(ayahRowsBuilt(t), isEmpty);
        expectCalm(t);

        await t.tap(searchRetry);
        await settleAnswer(t);
        expect(service.retryCalls, 2);
        service.setPhase(IndexPhase.ready);
        await settleAnswer(t);
        expectLines(t, []);
        expect(ayahRow(112, 1), findsOneWidget);
        expectCalm(t);
      },
    );

    testWidgets(
      'a retry that fails at once (no preparing in between) keeps the line and the button',
      (t) async {
        final service = scripted(IndexPhase.failed);
        service.onRetry = () =>
            service.setPhase(IndexPhase.failed, failure: StateError('still'));
        await pumpSearch(t, service: service);
        await typeQuery(t, _ikhlas);
        await t.tap(searchRetry);
        await settleAnswer(t);
        expect(service.retryCalls, 1);
        expectLines(t, [kSearchFailed]);
        expect(searchRetry, findsOneWidget);
        expectCalm(t);
      },
    );

    testWidgets(
      'the failure is said only for two letters or more: nothing typed and one letter keep their own line',
      (t) async {
        await pumpSearch(t, service: scripted(IndexPhase.failed));
        expectLines(t, [kSearchHint]);
        expect(searchRetry, findsNothing);
        await typeQuery(t, loneLetter);
        expectLines(t, [kSearchNeedTwo]);
        expect(searchRetry, findsNothing);
        await typeQuery(t, _cave);
        expectLines(t, [kSearchFailed]);
        await typeQuery(t, '');
        expectLines(t, [kSearchHint]);
        expect(searchRetry, findsNothing);
        expectCalm(t);
      },
    );
  });

  group('ready', () {
    testWidgets(
      'nothing in either group: «nothing found» and under it the advice, and no heading',
      (t) async {
        await pumpSearch(t);
        await typeQuery(t, _nowhere);
        expectLines(t, [kSearchNone, kSearchNoneAdvice]);
        expect(
          t.getTopLeft(find.text(kSearchNoneAdvice)).dy,
          greaterThanOrEqualTo(
            t.getBottomLeft(find.text(kSearchNone)).dy - 0.01,
          ),
          reason: 'the advice is under the line',
        );
        expect(surahsHeading, findsNothing);
        expect(ayatHeading, findsNothing);
        expect(surahRowsBuilt(t), isEmpty);
        expect(ayahRowsBuilt(t), isEmpty);
        expect(searchRetry, findsNothing);
        expect(searchMoreLine, findsNothing);
        expectCalm(t);
      },
    );

    testWidgets(
      'a surah match and no ayah: only the surah group, and no «nothing found»',
      (t) async {
        final service = ScriptedSearchService(); // ready, every answer empty
        await pumpSearch(t, service: service);
        await typeQuery(t, _cave);
        expect(surahsHeading, findsOneWidget);
        expect(surahRowsBuilt(t), [18]);
        expect(ayatHeading, findsNothing);
        expect(ayahRowsBuilt(t), isEmpty);
        expectLines(t, []);
        expectCalm(t);
      },
    );

    testWidgets('an ayah match and no surah: only the ayah group', (t) async {
      await pumpSearch(t);
      await typeQuery(t, _ikhlas);
      expect(surahsHeading, findsNothing);
      expect(surahRowsBuilt(t), isEmpty);
      expect(ayatHeading, findsOneWidget);
      expect(ayahRow(112, 1), findsOneWidget);
      expectLines(t, []);
      expectCalm(t);
    });

    testWidgets(
      'from «nothing found» to results and back, each state replaces the other',
      (t) async {
        await pumpSearch(t);
        await typeQuery(t, _nowhere);
        expectLines(t, [kSearchNone, kSearchNoneAdvice]);
        await typeQuery(t, _ikhlas);
        expectLines(t, []);
        expect(ayahRow(112, 1), findsOneWidget);
        await typeQuery(t, _nowhere);
        expectLines(t, [kSearchNone, kSearchNoneAdvice]);
        expect(ayahRowsBuilt(t), isEmpty);
        expect(ayatHeading, findsNothing);
        await typeQuery(t, '');
        expectLines(t, [kSearchHint]);
        expectCalm(t);
      },
    );
  });

  group('no Arabic letter is nothing typed', () {
    const typedWithNoLetter = <String, String>{
      'digits': '123',
      'Latin': 'abc',
      'the ayah brackets': '﴿ ﴾',
      'spaces': '     ',
      'only tashkeel': 'ًٌٍَُِّْ',
      'only tatweel': 'ـــــ',
      'Arabic-Indic digits and punctuation': '٢٥٥ ، ؛ ؟',
    };

    for (final phase in [
      IndexPhase.ready,
      IndexPhase.preparing,
      IndexPhase.failed,
    ]) {
      testWidgets('${phase.name}: the hint line alone, and no error', (
        t,
      ) async {
        final service = scripted(phase);
        await pumpSearch(t, service: service);
        expectLines(t, [kSearchHint], reason: 'on opening');
        for (final entry in typedWithNoLetter.entries) {
          expect(
            ArabicFold.letters(ArabicFold.query(entry.value)),
            0,
            reason: entry.key,
          );
          // a real query in between, so every case starts from another state
          await typeQuery(t, _cave);
          await typeQuery(t, entry.value);
          expect(fieldText(t), entry.value, reason: entry.key);
          expectLines(t, [kSearchHint], reason: entry.key);
          expect(surahsHeading, findsNothing, reason: entry.key);
          expect(ayatHeading, findsNothing, reason: entry.key);
          expect(surahRowsBuilt(t), isEmpty, reason: entry.key);
          expect(ayahRowsBuilt(t), isEmpty, reason: entry.key);
          expect(searchRetry, findsNothing, reason: entry.key);
          expectCalm(t, reason: entry.key);
        }
      });
    }
  });

  group('one letter', () {
    for (final phase in [
      IndexPhase.ready,
      IndexPhase.preparing,
      IndexPhase.failed,
    ]) {
      testWidgets(
        '${phase.name}: the need-two line also when no surah matched',
        (t) async {
          await pumpSearch(t, service: scripted(phase));
          await typeQuery(t, loneLetter);
          expectLines(t, [kSearchNeedTwo]);
          expect(surahsHeading, findsNothing);
          expect(ayatHeading, findsNothing);
          expect(ayahRowsBuilt(t), isEmpty);
          expect(searchRetry, findsNothing);
          expectCalm(t);
          // one letter with marks and spaces around it is still one letter
          await typeQuery(
            t,
            '  $loneLetter'
            'َ  ',
          );
          expectLines(t, [kSearchNeedTwo]);
          expectCalm(t);
        },
      );
    }

    testWidgets(
      'the service is never asked about one letter or about nothing',
      (t) async {
        final asked = <String>[];
        final service = ScriptedSearchService(
          answerOf: (folded) {
            asked.add(folded);
            return answers[folded] ?? _empty;
          },
        );
        await pumpSearch(t, service: service);
        await typeQuery(t, loneLetter);
        await typeQuery(t, '123');
        await typeQuery(t, '');
        expect(asked, isEmpty);
        await typeQuery(t, _cave);
        expect(asked, [ArabicFold.query(_cave)]);
      },
    );
  });
}
