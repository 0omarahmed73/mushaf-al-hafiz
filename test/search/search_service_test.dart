// Feature 011, T009: SearchService, the time-sliced preparation off launch, the generation-aware scan and the 100-row cap
// (spec FR-014, FR-018, FR-019, FR-022, FR-023; research D1, D5). A counting MapBundle over the 114 real files.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/search/arabic_fold.dart';
import 'package:mushaf/search/ayah_index.dart';
import 'package:mushaf/search/search_service.dart';

import '../support/map_bundle.dart';
import '../support/search_harness.dart';

Future<void> immediate() => Future<void>.value();

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

  /// A service over a counting bundle of the real files (or [override]n ones), with an immediate yield.
  ({
    SearchService service,
    MapBundle bundle,
    List<int> metaCalls,
    List<int> yields,
  })
  make({
    Map<String, String>? override,
    Duration slice = const Duration(milliseconds: 8),
  }) {
    final bundle = MapBundle({...files, ...?override});
    final metaCalls = <int>[];
    final yields = <int>[];
    final service = SearchService(
      bundle: bundle,
      meta: () async {
        metaCalls.add(1);
        return meta;
      },
      yieldTurn: () {
        yields.add(1);
        return immediate();
      },
      slice: slice,
    );
    addTearDown(service.dispose);
    return (
      service: service,
      bundle: bundle,
      metaCalls: metaCalls,
      yields: yields,
    );
  }

  String path(int surah) => realTextPath(surah);

  group('nothing is read before the first prepare (FR-022)', () {
    test('creating a SearchService reads nothing', () {
      final m = make();
      expect(m.bundle.loads, isEmpty);
      expect(m.metaCalls, isEmpty);
      expect(m.yields, isEmpty);
      expect(m.service.phase, IndexPhase.notStarted);
      expect(m.service.failure, isNull);
    });

    test(
      'a search before prepare returns null and still reads nothing',
      () async {
        final m = make();
        expect(
          await m.service.searchAyat('الله', isCurrent: () => true),
          isNull,
        );
        expect(m.bundle.loads, isEmpty);
      },
    );
  });

  group('prepare', () {
    test('reads the 114 files once, each file once, and ends ready', () async {
      final m = make();
      final watch = Stopwatch()..start();
      await m.service.prepare();
      // ignore: avoid_print
      print(
        'prepare (immediate yields, 8 ms slices): ${watch.elapsedMilliseconds} ms, ${m.yields.length} yields',
      );
      expect(m.service.phase, IndexPhase.ready);
      expect(m.service.failure, isNull);
      expect(m.bundle.loads, hasLength(114));
      expect(m.bundle.loads.toSet(), {for (var s = 1; s <= 114; s++) path(s)});
      expect(m.metaCalls, hasLength(1));
    });

    test('a second prepare while preparing shares the work; one after ready reads nothing more', () async {
      final m = make();
      final first = m.service.prepare();
      expect(m.service.phase, IndexPhase.preparing);
      final second = m.service.prepare();
      expect(m.service.phase, IndexPhase.preparing);
      await Future.wait([first, second]);
      expect(m.service.phase, IndexPhase.ready);
      expect(m.bundle.loads, hasLength(114));
      await m.service.prepare();
      await m.service.retry();
      expect(m.bundle.loads, hasLength(114));
      expect(m.metaCalls, hasLength(1));
      expect(m.service.phase, IndexPhase.ready);
    });

    test('the index it prepares is the production one: same folded text as the real index', () async {
      final m = make();
      await m.service.prepare();
      final result = await m.service.searchAyat(
        'قل هو الله احد',
        isCurrent: () => true,
      );
      expect(result!.total, 1);
      expect(result.hits.single.ref, const AyahRef(112, 1));
      expect(index.ayahCount, 6236);
    });

    test('with slice zero it yields after every ayah (at least 6,236 yields); with a large slice it yields rarely', () async {
      final zero = make(slice: Duration.zero);
      await zero.service.prepare();
      expect(zero.service.phase, IndexPhase.ready);
      expect(zero.yields.length, greaterThanOrEqualTo(6236));

      final large = make(slice: const Duration(minutes: 5));
      await large.service.prepare();
      expect(large.service.phase, IndexPhase.ready);
      expect(large.yields.length, lessThanOrEqualTo(114));
      expect(large.yields.length, lessThan(zero.yields.length ~/ 10));
    });

    test('the default yield is a real turn of the event loop (Future.delayed), not a microtask', () async {
      final bundle = MapBundle(files);
      final service = SearchService(
        bundle: bundle,
        meta: () async => meta,
        slice: Duration.zero,
      );
      addTearDown(service.dispose);
      var ticks = 0;
      final ticker = Future.doWhile(() async {
        await Future<void>.delayed(Duration.zero);
        ticks++;
        return service.phase == IndexPhase.preparing;
      });
      await service.prepare();
      await ticker;
      expect(service.phase, IndexPhase.ready);
      expect(ticks, greaterThan(100)); // other timers ran in between the slices
    });
  });

  group(
    'failure and retry (the failed phase never serves a partial index)',
    () {
      test('a bundle that lacks file 057 ends failed; searchAyat returns null; retry after the file is there ends ready', () async {
        final missing = {...files}..remove(path(57));
        final bundle = MapBundle(missing);
        final service = SearchService(
          bundle: bundle,
          meta: () async => meta,
          yieldTurn: immediate,
        );
        addTearDown(service.dispose);
        await service.prepare();
        expect(service.phase, IndexPhase.failed);
        expect(service.failure, isNotNull);
        expect(await service.searchAyat('الله', isCurrent: () => true), isNull);
        expect(bundle.loads.last, path(57));

        // the file is there again
        bundle.files[path(57)] = files[path(57)]!;
        final before = bundle.loads.length;
        await service.retry();
        expect(service.phase, IndexPhase.ready);
        expect(service.failure, isNull);
        expect(bundle.loads.length - before, 114);
        final result = await service.searchAyat(
          'قل هو الله احد',
          isCurrent: () => true,
        );
        expect(result!.total, 1);
      });

      test('prepare after failed starts again, like retry', () async {
        final missing = {...files}..remove(path(1));
        final bundle = MapBundle(missing);
        final service = SearchService(
          bundle: bundle,
          meta: () async => meta,
          yieldTurn: immediate,
        );
        addTearDown(service.dispose);
        await service.prepare();
        expect(service.phase, IndexPhase.failed);
        bundle.files[path(1)] = files[path(1)]!;
        await service.prepare();
        expect(service.phase, IndexPhase.ready);
      });

      test('a file with one ayah fewer ends failed with a SearchIndexError, and the next try with the right file is ready', () async {
        final d = jsonDecode(files[path(2)]!) as Map<String, dynamic>;
        (d['ayahs'] as List<dynamic>).removeLast();
        final m = make(override: {path(2): jsonEncode(d)});
        await m.service.prepare();
        expect(m.service.phase, IndexPhase.failed);
        expect(m.service.failure, isA<SearchIndexError>());
        expect(
          await m.service.searchAyat('الله', isCurrent: () => true),
          isNull,
        );
        m.bundle.files[path(2)] = files[path(2)]!;
        await m.service.retry();
        expect(m.service.phase, IndexPhase.ready);
      });

      test('a malformed file, a surah file of another surah and a word that folds to nothing end failed', () async {
        for (final bad in [
          'not json',
          files[path(3)]!,
          '{"surah":5,"ayahs":[["۞"]]}',
        ]) {
          final m = make(override: {path(5): bad});
          await m.service.prepare();
          expect(
            m.service.phase,
            IndexPhase.failed,
            reason: bad.length > 40 ? 'file of surah 3' : bad,
          );
          expect(m.service.failure, isA<SearchIndexError>());
        }
      });

      test('a meta that cannot be read ends failed', () async {
        final service = SearchService(
          bundle: MapBundle(files),
          meta: () async => throw StateError('no meta'),
          yieldTurn: immediate,
        );
        addTearDown(service.dispose);
        await service.prepare();
        expect(service.phase, IndexPhase.failed);
        expect(service.failure, isA<StateError>());
      });
    },
  );

  group('listeners', () {
    test('notify on every phase change: preparing, ready', () async {
      final m = make();
      final phases = <IndexPhase>[];
      m.service.addListener(() => phases.add(m.service.phase));
      await m.service.prepare();
      await m.service.prepare();
      expect(phases, [IndexPhase.preparing, IndexPhase.ready]);
    });

    test(
      'notify on failure and on the retry: preparing, failed, preparing, ready',
      () async {
        final missing = {...files}..remove(path(10));
        final bundle = MapBundle(missing);
        final service = SearchService(
          bundle: bundle,
          meta: () async => meta,
          yieldTurn: immediate,
        );
        addTearDown(service.dispose);
        final phases = <IndexPhase>[];
        service.addListener(() => phases.add(service.phase));
        await service.prepare();
        bundle.files[path(10)] = files[path(10)]!;
        await service.retry();
        expect(phases, [
          IndexPhase.preparing,
          IndexPhase.failed,
          IndexPhase.preparing,
          IndexPhase.ready,
        ]);
      },
    );

    test('a service disposed while preparing ends quietly', () async {
      final m = make(slice: Duration.zero);
      final done = m.service.prepare();
      m.service.dispose();
      await done;
    });
  });

  group('searchAyat', () {
    late SearchService service;
    setUpAll(() async {
      service = SearchService.prepared(index, meta);
    });

    List<int> brute(String typed) {
      final pattern = ArabicFold.pattern(ArabicFold.query(typed));
      return [
        for (var i = 0; i < index.ayahCount; i++)
          if (pattern.hasMatch(index.foldedAyah(i))) i,
      ];
    }

    Future<AyahSearchResult?> ask(String typed, {bool Function()? isCurrent}) =>
        service.searchAyat(
          ArabicFold.query(typed),
          isCurrent: isCurrent ?? () => true,
        );

    test('«ال» returns the total 5,182 and the first 100 hits in Mushaf order, each with its page, stored words and flags', () async {
      final result = (await ask('ال'))!;
      expect(AyahSearchResult.maxRows, 100);
      expect(result.total, 5182);
      expect(result.hits, hasLength(100));
      expect(result.tooMany, isTrue);
      final expected = brute('ال').take(100).toList();
      expect([for (final h in result.hits) index.indexOf(h.ref)], expected);
      for (final h in result.hits) {
        final i = index.indexOf(h.ref);
        expect(
          h.page,
          meta.pageOfAyah(h.ref.surah, h.ref.ayah),
          reason: h.ref.key,
        );
        expect(h.words, index.storedWords(i), reason: h.ref.key);
        expect(h.matched, hasLength(h.words.length), reason: h.ref.key);
        expect(h.matched.any((b) => b), isTrue, reason: h.ref.key);
      }
      expect(
        result.hits.first.ref,
        const AyahRef(1, 1),
      ); // «ٱللَّهِ» of the basmala
    });

    test(
      '100 hits or fewer: no more-line (tooMany false), every hit kept',
      () async {
        final few = (await ask('الرحمن'))!;
        expect(few.total, 48);
        expect(few.hits, hasLength(48));
        expect(few.tooMany, isFalse);
        final one = (await ask('قل هو الله احد'))!;
        expect(one.total, 1);
        expect(one.hits.single.ref, const AyahRef(112, 1));
        expect(one.hits.single.page, 604);
        expect(one.hits.single.matched, [true, true, true, true]);
        expect(one.tooMany, isFalse);
        final none = (await ask('ذو القرنين'))!;
        expect(none.total, 0);
        expect(none.hits, isEmpty);
      },
    );

    test('exactly the boundary: a query with more than 100 ayat keeps 100 and counts the rest', () async {
      final result = (await ask('الله'))!;
      expect(result.total, brute('الله').length);
      expect(result.total, greaterThan(100));
      expect(result.hits, hasLength(100));
      expect(
        result.hits.map((h) => index.indexOf(h.ref)),
        brute('الله').take(100),
      );
    });

    test('2:282 is on page 48, the page where it begins', () async {
      final pasted = index
          .storedWords(index.indexOf(const AyahRef(2, 282)))
          .join(' ');
      final result = (await ask(pasted))!;
      expect(result.total, 1);
      expect(result.hits.single.ref, const AyahRef(2, 282));
      expect(result.hits.single.page, 48);
      expect(result.hits.single.words.length, 128);
    });

    test('a query with fewer than two letters is not scanned and returns an empty result', () async {
      for (final typed in ['', ' ', 'ق', '1', 'ا']) {
        final result = (await ask(typed))!;
        expect(result.total, 0, reason: '"$typed"');
        expect(result.hits, isEmpty);
        expect(result.tooMany, isFalse);
      }
    });

    test(
      'a stale scan: isCurrent false from the start returns null at once',
      () async {
        var yields = 0;
        final counting = SearchService.prepared(
          index,
          meta,
          yieldTurn: () {
            yields++;
            return immediate();
          },
        );
        addTearDown(counting.dispose);
        expect(
          await counting.searchAyat(
            ArabicFold.query('ال'),
            isCurrent: () => false,
          ),
          isNull,
        );
        expect(yields, 0);
      },
    );

    test('a scan whose isCurrent turns false after the first chunk returns null after at most one more chunk', () async {
      var yields = 0;
      final counting = SearchService.prepared(
        index,
        meta,
        yieldTurn: () {
          yields++;
          return immediate();
        },
      );
      addTearDown(counting.dispose);
      final result = await counting.searchAyat(
        ArabicFold.query('ال'),
        isCurrent: () => yields < 1,
      );
      expect(result, isNull);
      expect(
        yields,
        lessThanOrEqualTo(2),
      ); // a yield between chunks: the first one, at most one more
    });

    test('an answer that is still current at the end is complete (yields between the 8 chunks)', () async {
      var yields = 0;
      final counting = SearchService.prepared(
        index,
        meta,
        yieldTurn: () {
          yields++;
          return immediate();
        },
      );
      addTearDown(counting.dispose);
      final result = await counting.searchAyat(
        ArabicFold.query('ال'),
        isCurrent: () => true,
      );
      expect(result!.total, 5182);
      expect(yields, 7);
    });

    test('two searches at once do not disturb each other', () async {
      final a = ask('الله');
      final b = ask('الرحمن');
      expect((await a)!.total, brute('الله').length);
      expect((await b)!.total, 48);
    });
  });

  group('SearchService.prepared', () {
    test(
      'is ready at once, reads nothing, and prepare and retry do nothing',
      () async {
        final service = SearchService.prepared(index, meta);
        addTearDown(service.dispose);
        expect(service.phase, IndexPhase.ready);
        expect(service.failure, isNull);
        var notified = 0;
        service.addListener(() => notified++);
        await service.prepare();
        await service.retry();
        expect(notified, 0);
        expect(service.phase, IndexPhase.ready);
        expect(
          (await service.searchAyat(
            ArabicFold.query('قل هو'),
            isCurrent: () => true,
          ))!.total,
          greaterThan(0),
        );
      },
    );
  });
}
