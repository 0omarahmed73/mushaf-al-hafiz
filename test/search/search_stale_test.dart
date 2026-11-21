// Feature 011, T051: a late answer never wins (spec FR-022, FR-023, User Story 5 scenarios 3 and 5; research D5). The
// screen runs over a service whose answers wait until the test hands them out, in the fake time of the widget test; the
// last test runs over the real service and a bundle whose files wait behind a gate.
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/search/arabic_fold.dart';
import 'package:mushaf/search/ayah_index.dart';
import 'package:mushaf/search/search_screen.dart';
import 'package:mushaf/search/search_service.dart';
import 'package:mushaf/search/search_strings.dart';
import 'package:mushaf/search/surah_search.dart';

import '../support/search_harness.dart';
import '../support/search_quality_harness.dart';

/// Lets a handed-out answer reach the screen (the first pump only runs the microtasks: no frame is scheduled before the
/// answer arrives) and draws exactly ONE frame.
Future<void> oneFrameAfterTheAnswer(WidgetTester t) async {
  await t.pump();
  expect(
    t.binding.hasScheduledFrame,
    isTrue,
    reason: 'the answer asks for a frame at once (no timer, no debounce)',
  );
  await t.pump();
}

/// What is typed, a letter at a time.
const _typed = ['ر', 'رح', 'رحم', 'رحمن'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MushafMeta meta;
  late AyahIndex index;

  /// A made-up answer to each typed text, with rows no other answer has: text k answers with the ayat 1..3 of surah
  /// 20 + k.
  late Map<String, AyahSearchResult> answerOf;

  setUpAll(() async {
    meta = await realMeta();
    index = await realIndex();
    answerOf = {
      for (var k = 0; k < _typed.length; k++)
        _typed[k]: AyahSearchResult(
          total: 3,
          hits: [
            for (var a = 1; a <= 3; a++) hitOf(index, meta, AyahRef(20 + k, a)),
          ],
        ),
    };
  });

  List<String> rowsOf(String typed) => [
    for (final hit in answerOf[typed]!.hits) hit.ref.key,
  ];

  /// The surah rows on screen are those of [typed], whatever the ayah answers do.
  void expectSurahsOf(WidgetTester t, String typed) {
    final wanted = searchSurahs(meta.surahs, typed).map((s) => s.number);
    expect(wanted, isNotEmpty);
    expect(surahRowsBuilt(t), isNotEmpty);
    expect(surahRowsBuilt(t), everyElement(isIn(wanted)));
    expect(surahRowsBuilt(t).first, wanted.first);
  }

  testWidgets(
    'typed quickly, answered in the order 3, 1, 4, 2: the list shows the answer to the last text, and never a row of an older answer',
    (t) async {
      final service = GatedSearchService();
      await pumpSearch(t, service: service);

      for (final text in _typed) {
        await typeQuery(t, text);
        expect(fieldText(t), text);
        expect(
          ayahRowsBuilt(t),
          isEmpty,
          reason: 'nothing answered yet ($text)',
        );
        expectSurahsOf(t, text);
      }
      // one letter is never asked about; the three others were, in the order typed
      expect(service.asked, [
        for (final text in _typed.skip(1)) ArabicFold.query(text),
      ]);
      expect(service.waits(_typed[0]), isFalse);

      // the third arrives first: it is not the text in the field
      service.answer(_typed[2], answerOf[_typed[2]]!);
      await t.pump();
      await t.pump();
      expect(
        ayahRowsBuilt(t),
        isEmpty,
        reason: 'the answer to «${_typed[2]}» is stale',
      );
      expect(ayatHeading, findsNothing);
      await t.pump(const Duration(milliseconds: 50));
      expect(ayahRowsBuilt(t), isEmpty);

      // the first: one letter, there is no question to answer
      service.answer(_typed[0], answerOf[_typed[0]]!);
      await t.pump();
      await t.pump();
      expect(ayahRowsBuilt(t), isEmpty);

      // the fourth, the text in the field: on screen within one frame
      service.answer(_typed[3], answerOf[_typed[3]]!);
      await oneFrameAfterTheAnswer(t);
      expect(
        ayahRowsBuilt(t),
        rowsOf(_typed[3]),
        reason: 'one frame after the answer',
      );
      expect(ayatHeading, findsOneWidget);
      expect(
        find.descendant(of: ayatHeading, matching: find.text(kAyahHeading(3))),
        findsOneWidget,
      );

      // the second arrives last and changes nothing
      service.answer(_typed[1], answerOf[_typed[1]]!);
      await t.pump();
      await t.pump();
      expect(ayahRowsBuilt(t), rowsOf(_typed[3]));
      await t.pump(const Duration(seconds: 2));
      expect(ayahRowsBuilt(t), rowsOf(_typed[3]));
      expectSurahsOf(t, _typed[3]);
      expect(fieldText(t), _typed[3]);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'an older answer that arrives while a newer one is on screen does not replace it, and deleting back asks again',
    (t) async {
      final service = GatedSearchService();
      await pumpSearch(t, service: service);
      await typeQuery(t, _typed[1]);
      await typeQuery(t, _typed[2]);
      service.answer(_typed[2], answerOf[_typed[2]]!);
      await oneFrameAfterTheAnswer(t);
      expect(ayahRowsBuilt(t), rowsOf(_typed[2]));
      service.answer(_typed[1], answerOf[_typed[1]]!);
      await t.pump();
      await t.pump();
      expect(ayahRowsBuilt(t), rowsOf(_typed[2]));

      // back to the shorter text: a new question, and the rows of the longer text may stay only until it is answered
      await typeQuery(t, _typed[1]);
      expect(service.waits(_typed[1]), isTrue);
      expect(
        ayahRowsBuilt(t),
        everyElement(isIn(rowsOf(_typed[2]))),
        reason:
            'the earlier answer may stay on screen meanwhile; nothing else may',
      );
      service.answer(_typed[1], answerOf[_typed[1]]!);
      await oneFrameAfterTheAnswer(t);
      expect(ayahRowsBuilt(t), rowsOf(_typed[1]));
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'clearing the field while an answer is awaited: the answer is dropped and the hint stays',
    (t) async {
      final service = GatedSearchService();
      await pumpSearch(t, service: service);
      await typeQuery(t, _typed[3]);
      await typeQuery(t, '');
      service.answer(_typed[3], answerOf[_typed[3]]!);
      await t.pump();
      await t.pump();
      expect(ayahRowsBuilt(t), isEmpty);
      expect(ayatHeading, findsNothing);
      expect(find.text(kSearchHint), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'an answer that arrives after the screen was closed changes nothing and throws nothing',
    (t) async {
      final service = GatedSearchService();
      final run = await pumpSearch(t, service: service);
      await typeQuery(t, _typed[3]);
      expect(service.waits(_typed[3]), isTrue);
      final listenersWhileOpen = service.listeners;
      expect(
        listenersWhileOpen,
        greaterThan(0),
        reason: 'the open screen listens to the service',
      );

      await closeSearch(t);
      expect(run.popped, isTrue);
      expect(run.result, isNull);
      expect(find.byType(SearchScreen), findsNothing);
      expect(
        service.listeners,
        lessThan(listenersWhileOpen),
        reason: 'a closed screen listens to nothing (what is left is the provider above the app)',
      );
      expect(service.listeners, lessThanOrEqualTo(1));

      service.answer(_typed[3], answerOf[_typed[3]]!);
      await t.pump();
      await t.pump(const Duration(seconds: 2));
      expect(t.takeException(), isNull);
      expect(find.byType(SearchScreen), findsNothing);
      expect(skey('search-home'), findsOneWidget);
      expect(ayahRowsBuilt(t), isEmpty);

      // the next search starts clean: the late answer is not shown there either
      await reopenSearch(t, run);
      expect(fieldText(t), isEmpty);
      expect(ayahRowsBuilt(t), isEmpty);
      expect(find.text(kSearchHint), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'opening search while the preparing of an earlier, closed search still runs does not start it again',
    (t) async {
      const query = 'قل هو الله احد';
      final bundle = GatedTextBundle(realTextFiles());
      final service = SearchService(
        bundle: bundle,
        meta: () async => meta,
        yieldTurn: () async {},
        slice: const Duration(days: 1),
        trace: (_) {},
      );
      addTearDown(service.dispose);
      var readyCount = 0;
      service.addListener(() {
        if (service.phase == IndexPhase.ready) readyCount++;
      });

      final run = await pumpSearch(t, service: service);
      expect(
        t.takeException(),
        isNull,
        reason: 'opening the first search of the run (the service tells its listeners at once that it prepares)',
      );
      expect(
        service.phase,
        IndexPhase.preparing,
        reason: 'the first search starts the preparation',
      );
      expect(bundle.loads, {realTextPath(1): 1});
      await typeQuery(t, query);
      expect(find.text(kSearchPreparing), findsOneWidget);

      await closeSearch(t);
      expect(
        service.phase,
        IndexPhase.preparing,
        reason: 'closing does not stop it',
      );

      await reopenSearch(t, run);
      await typeQuery(t, query);
      expect(service.phase, IndexPhase.preparing);
      expect(bundle.loads, {
        realTextPath(1): 1,
      }, reason: 'the running preparation is shared, not started again');
      expect(find.text(kSearchPreparing), findsOneWidget);
      expect(ayahRowsBuilt(t), isEmpty);
      await t.pump(const Duration(seconds: 5));
      expect(
        find.text(kSearchPreparing),
        findsOneWidget,
        reason: 'until the preparation ends',
      );

      bundle.open();
      await t.pump();
      await t.pump();
      expect(service.phase, IndexPhase.ready);
      expect(readyCount, 1);
      expect(bundle.loads, hasLength(MushafMeta.surahCount));
      expect(
        bundle.loads.values,
        everyElement(1),
        reason: 'every file read once in the run',
      );
      expect(find.text(kSearchPreparing), findsNothing);
      expect(
        ayahRow(112, 1),
        findsOneWidget,
        reason: 'the rows appear by themselves for the text in the field',
      );
      expect(fieldText(t), query);

      // a third search in the same run reads nothing more
      await closeSearch(t);
      await reopenSearch(t, run);
      await typeQuery(t, query);
      expect(ayahRow(112, 1), findsOneWidget);
      expect(bundle.loads.values, everyElement(1));
      expect(t.takeException(), isNull);
    },
  );
}
