// Feature 011, T052: the measurement lines of the search (spec SC-004, SC-005; research D9; Constitution IV). Built with
// --dart-define=SEARCH_TRACE=true the service prints one `SEARCH prepare` line when the text of the ayat is ready (the screen
// adds the `SEARCH query` line of each query, T050); built with --dart-define=SEARCH_BENCH=true the screen runs the 20 queries
// of SC-004 and prints a `SEARCHBENCH` line for each. In normal builds (and in every test) nothing is printed, and no line
// ever holds the text of a query: only its length, the number of ayat found and milliseconds.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/search/arabic_fold.dart';
import 'package:mushaf/search/ayah_index.dart';
import 'package:mushaf/search/search_service.dart';
import 'package:mushaf/search/search_trace.dart';

import '../support/map_bundle.dart';
import '../support/search_harness.dart';

Future<void> immediate() => Future<void>.value();

/// Every line the trace can print is plain ASCII: a word, `key=<number>` pairs.
final RegExp _ascii = RegExp(r'^[\x20-\x7E]+$');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MushafMeta meta;
  late AyahIndex index;
  late Map<String, String> files;
  setUpAll(() async {
    meta = await realMeta();
    index = await realIndex();
    files = realTextFiles();
  });

  /// How many ayat of the real index [query] finds (the production scan).
  int found(String query) {
    final pattern = ArabicFold.pattern(ArabicFold.query(query));
    var total = 0;
    for (var chunk = 0; chunk < index.chunks.length; chunk++) {
      total += index.scanChunk(chunk, pattern).length;
    }
    return total;
  }

  group('the lines', () {
    test('prepareLine, queryLine and benchLine are exactly the lines of the contract', () {
      expect(
        SearchTrace.prepareLine(1200, 140),
        'SEARCH prepare ms=1200 slices=140',
      );
      expect(
        SearchTrace.queryLine(6, 48, 5),
        'SEARCH query len=6 ayat=48 ms=5',
      );
      expect(
        SearchTrace.benchLine(3, 1746, 7),
        'SEARCHBENCH q=3 ayat=1746 ms=7',
      );
    });

    test('they are plain ASCII with numbers only, whatever the numbers', () {
      for (final n in [0, 1, 99, 1500, 6236]) {
        expect(
          SearchTrace.prepareLine(n, n),
          matches(RegExp(r'^SEARCH prepare ms=\d+ slices=\d+$')),
        );
        expect(
          SearchTrace.queryLine(n, n, n),
          matches(RegExp(r'^SEARCH query len=\d+ ayat=\d+ ms=\d+$')),
        );
        expect(
          SearchTrace.benchLine(n, n, n),
          matches(RegExp(r'^SEARCHBENCH q=\d+ ayat=\d+ ms=\d+$')),
        );
        for (final line in [
          SearchTrace.prepareLine(n, n),
          SearchTrace.queryLine(n, n, n),
          SearchTrace.benchLine(n, n, n),
        ]) {
          expect(line, matches(_ascii));
        }
      }
    });

    test('enabled and bench are false in tests: only the build options turn them on', () {
      expect(SearchTrace.enabled, isFalse);
      expect(SearchTrace.bench, isFalse);
      final source = File('lib/search/search_trace.dart').readAsStringSync();
      expect(
        source,
        contains(
          "static const bool enabled = bool.fromEnvironment('SEARCH_TRACE');",
        ),
      );
      expect(
        source,
        contains(
          "static const bool bench = bool.fromEnvironment('SEARCH_BENCH');",
        ),
      );
    });

    test(
      'nothing is printed when both are off: emit prints nothing, in tests',
      () {
        final printed = <String?>[];
        final old = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) =>
            printed.add(message);
        addTearDown(() => debugPrint = old);
        SearchTrace.emit(SearchTrace.prepareLine(1, 1));
        SearchTrace.emit(SearchTrace.queryLine(1, 1, 1));
        SearchTrace.emit(SearchTrace.benchLine(1, 1, 1));
        expect(printed, isEmpty);
      },
    );

    test('the file prints in one place, behind the flags, and imports only Flutter', () {
      final source = File('lib/search/search_trace.dart').readAsStringSync();
      expect('debugPrint('.allMatches(source), hasLength(1));
      expect(RegExp(r'[^g]print\(').hasMatch(source), isFalse);
      final guard = source.indexOf('if (!enabled && !bench) return;');
      expect(guard, isNonNegative);
      expect(source.indexOf('debugPrint('), greaterThan(guard));
      final imports = [
        for (final l in source.split('\n'))
          if (l.startsWith('import ')) l,
      ];
      expect(imports, ["import 'package:flutter/foundation.dart';"]);
    });
  });

  group('benchQueries (SC-004)', () {
    const queries = SearchTrace.benchQueries;

    test('are 20, all different: ten one-word, five phrases, «ال», 2:282 pasted whole, three that match nothing', () {
      expect(queries, hasLength(20));
      expect(queries.toSet(), hasLength(20));
      for (final q in queries.sublist(0, 10)) {
        final folded = ArabicFold.query(q);
        expect(folded, isNotEmpty, reason: q);
        expect(folded, isNot(contains(' ')), reason: 'one word: $q');
        expect(ArabicFold.letters(folded), greaterThanOrEqualTo(2), reason: q);
      }
      for (final q in queries.sublist(10, 15)) {
        expect(
          ArabicFold.query(q).split(' ').length,
          greaterThanOrEqualTo(2),
          reason: 'a phrase: $q',
        );
      }
      expect(queries[15], 'ال');
    });

    test('the pasted ayah is the stored text of 2:282, every word unchanged (Constitution I)', () {
      final stored = index.storedWords(index.indexOf(const AyahRef(2, 282)));
      expect(stored, hasLength(128));
      expect(queries[16], stored.join(' '));
      expect(queries[16].length, 1188);
      expect(found(queries[16]), 1);
    });

    test('the first seventeen find ayat and the last three find nothing (over the real text)', () {
      for (var i = 0; i < 17; i++) {
        expect(found(queries[i]), greaterThan(0), reason: 'q=$i ${queries[i]}');
      }
      for (var i = 17; i < 20; i++) {
        expect(found(queries[i]), 0, reason: 'q=$i ${queries[i]}');
      }
      expect(found(queries[15]), 5182);
    });

    test('the one-word queries include a typed ؤ, whose rule is the costly one (research D2)', () {
      final folded = [
        for (final q in queries.sublist(0, 10)) ArabicFold.query(q),
      ];
      expect(
        folded.any(
          (f) =>
              f.contains(ArabicFold.seatWaw) || f.contains(ArabicFold.seatYeh),
        ),
        isTrue,
      );
    });
  });

  group('the service prints the prepare line', () {
    ({
      SearchService service,
      MapBundle bundle,
      List<String> lines,
      List<int> yields,
    })
    make({
      Map<String, String>? override,
      Duration slice = const Duration(milliseconds: 8),
      bool withSink = true,
    }) {
      final bundle = MapBundle({...files, ...?override});
      final lines = <String>[];
      final yields = <int>[];
      final service = SearchService(
        bundle: bundle,
        meta: () async => meta,
        yieldTurn: () {
          yields.add(1);
          return immediate();
        },
        slice: slice,
        trace: withSink ? lines.add : null,
      );
      addTearDown(service.dispose);
      return (service: service, bundle: bundle, lines: lines, yields: yields);
    }

    final prepareRegExp = RegExp(r'^SEARCH prepare ms=(\d+) slices=(\d+)$');

    test('creating the service and waiting print nothing; the text is read and the line printed once, when it is ready', () async {
      final m = make();
      expect(m.lines, isEmpty);
      final done = m.service.prepare();
      expect(m.lines, isEmpty, reason: 'not before it is ready');
      await done;
      expect(m.service.phase, IndexPhase.ready);
      expect(m.lines, hasLength(1));
      final match = prepareRegExp.firstMatch(m.lines.single);
      expect(match, isNotNull, reason: m.lines.single);
      expect(int.parse(match!.group(1)!), greaterThanOrEqualTo(0));
      expect(
        int.parse(match.group(2)!),
        m.yields.length + 1,
        reason: 'slices = the yields + the last one',
      );
    });

    test('with slice zero every ayah is a slice; with a large slice the work is one', () async {
      final zero = make(slice: Duration.zero);
      await zero.service.prepare();
      final z = prepareRegExp.firstMatch(zero.lines.single)!;
      expect(int.parse(z.group(2)!), greaterThanOrEqualTo(6237));
      final large = make(slice: const Duration(minutes: 5));
      await large.service.prepare();
      expect(
        large.lines.single,
        matches(RegExp(r'^SEARCH prepare ms=\d+ slices=1$')),
      );
    });

    test('a second prepare, a retry when ready and twenty searches print nothing more, and no line holds a query', () async {
      final m = make();
      await m.service.prepare();
      await m.service.prepare();
      await m.service.retry();
      for (final q in SearchTrace.benchQueries) {
        await m.service.searchAyat(ArabicFold.query(q), isCurrent: () => true);
      }
      expect(m.lines, hasLength(1));
      for (final line in m.lines) {
        expect(line, matches(_ascii));
        for (final q in SearchTrace.benchQueries) {
          expect(line, isNot(contains(q)));
        }
      }
    });

    test('a preparation that fails prints nothing; the retry that works prints the one line', () async {
      final m = make(override: {realTextPath(5): 'not json'});
      await m.service.prepare();
      expect(m.service.phase, IndexPhase.failed);
      expect(m.lines, isEmpty);
      m.bundle.files[realTextPath(5)] = files[realTextPath(5)]!;
      await m.service.retry();
      expect(m.service.phase, IndexPhase.ready);
      expect(m.lines, hasLength(1));
      expect(m.lines.single, matches(prepareRegExp));
    });

    test('without a sink (every normal build and every test) nothing reaches the log', () async {
      final printed = <String?>[];
      final old = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => printed.add(message);
      addTearDown(() => debugPrint = old);
      final m = make(withSink: false);
      await m.service.prepare();
      await m.service.searchAyat('الله', isCurrent: () => true);
      expect(m.service.phase, IndexPhase.ready);
      expect(printed, isEmpty);
    });

    test('a service made ready over an index prints nothing', () async {
      final printed = <String?>[];
      final old = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => printed.add(message);
      addTearDown(() => debugPrint = old);
      final service = SearchService.prepared(index, meta, yieldTurn: immediate);
      addTearDown(service.dispose);
      await service.prepare();
      await service.searchAyat('الله', isCurrent: () => true);
      expect(printed, isEmpty);
    });

    test('the source: the call is guarded by the flag, and the service itself never prints', () {
      final source = File('lib/search/search_service.dart').readAsStringSync();
      expect(source, contains("import 'search_trace.dart';"));
      expect(source, contains('SearchTrace.enabled ? SearchTrace.emit : null'));
      expect(source, contains('SearchTrace.prepareLine('));
      expect(source, isNot(contains('debugPrint(')));
      expect(RegExp(r'[^g]print\(').hasMatch(source), isFalse);
    });
  });
}
