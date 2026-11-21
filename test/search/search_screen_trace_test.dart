// Feature 011, the screen's side of T052 (research D9; spec SC-004, SC-005): the `SEARCH query` line of each query and, in a
// bench build, the 20 `SEARCHBENCH` lines, through the screen's `trace` and `bench` parameters (the build flags are false in
// tests). No line holds the text of a query.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/search/search_screen.dart';
import 'package:mushaf/search/search_service.dart';
import 'package:mushaf/search/search_trace.dart';

import '../support/search_harness.dart';

/// Closes the search that [pumpSearch] opened and opens [screen] over the same app.
Future<void> _open(WidgetTester t, SearchRun run, SearchScreen screen) async {
  await t.binding.handlePopRoute();
  await settleSearch(t);
  unawaited(
    run.navigator.currentState!.push<Object>(
      MaterialPageRoute<Object>(builder: (_) => screen),
    ),
  );
  await settleSearch(t);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await realMeta();
    await realIndex();
  });

  testWidgets(
    'a normal build has no trace and no bench: the field is empty and nothing was asked',
    (t) async {
      expect(SearchTrace.enabled, isFalse);
      expect(SearchTrace.bench, isFalse);
      const screen = SearchScreen();
      expect(screen.trace, isNull);
      expect(screen.bench, isNull);
      final service = ScriptedSearchService();
      final asked = <String>[];
      service.answerOf = (q) {
        asked.add(q);
        return const AyahSearchResult(total: 0, hits: []);
      };
      await pumpSearch(t, service: service);
      expect(asked, isEmpty);
    },
  );

  testWidgets(
    'each query of two letters or more prints one SEARCH query line: its length, the total, milliseconds',
    (t) async {
      final lines = <String>[];
      final run = await pumpSearch(t);
      await _open(t, run, SearchScreen(trace: lines.add, bench: false));
      await typeQuery(t, 'ق');
      expect(lines, isEmpty, reason: 'one letter asks nothing of the ayat');
      await typeQuery(t, 'قل هو الله احد');
      expect(lines, hasLength(1));
      expect(
        RegExp(r'^SEARCH query len=14 ayat=1 ms=\d+$').hasMatch(lines.single),
        isTrue,
        reason: lines.single,
      );
      await typeQuery(t, 'ال');
      expect(lines, hasLength(2));
      expect(lines.last, startsWith('SEARCH query len=2 ayat=5182 ms='));
      await typeQuery(t, 'ذو القرنين');
      expect(lines.last, startsWith('SEARCH query len=10 ayat=0 ms='));
      for (final line in lines) {
        expect(
          RegExp(r'^[ -~]+$').hasMatch(line),
          isTrue,
          reason: 'ASCII only: $line',
        );
      }
    },
  );

  testWidgets('the line is printed after the frame that shows the results', (
    t,
  ) async {
    final lines = <String>[];
    final run = await pumpSearch(t);
    await _open(t, run, SearchScreen(trace: lines.add, bench: false));
    await t.enterText(
      find.byKey(const ValueKey('search-field')),
      'قل هو الله احد',
    );
    expect(lines, isEmpty);
    await t.pump();
    await t.pump();
    expect(find.byKey(const ValueKey('ayah-row-112:1')), findsOneWidget);
    expect(lines, hasLength(1));
  });

  testWidgets(
    'a bench build runs the 20 queries through the session when the screen opens and leaves the field empty',
    (t) async {
      final lines = <String>[];
      final run = await pumpSearch(t);
      await _open(t, run, SearchScreen(trace: lines.add, bench: true));
      for (var i = 0; i < 30; i++) {
        await t.pump(const Duration(milliseconds: 10));
      }
      final bench = [
        for (final l in lines)
          if (l.startsWith('SEARCHBENCH')) l,
      ];
      expect(bench, hasLength(20));
      for (var i = 0; i < 20; i++) {
        expect(bench[i], startsWith('SEARCHBENCH q=${i + 1} ayat='));
        expect(RegExp(r'^[ -~]+$').hasMatch(bench[i]), isTrue);
      }
      expect(bench[15], startsWith('SEARCHBENCH q=16 ayat=5182 ms='));
      expect(bench[16], startsWith('SEARCHBENCH q=17 ayat=1 ms='));
      for (final i in [17, 18, 19]) {
        expect(bench[i], contains(' ayat=0 '));
      }
      expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('search-field')))
            .controller!
            .text,
        isEmpty,
      );
      expect(find.byKey(const ValueKey('search-heading-ayat')), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
}
