import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ayah_repository.dart';

import '../support/map_bundle.dart';

String json(Object o) => jsonEncode(o);

Map<String, String> sample() => {
  'assets/ayah/text/001.json': json({
    'surah': 1,
    'ayahs': [
      ['ب', 'س'],
      ['ا', 'ل', 'ح'],
    ],
  }),
  'assets/ayah/tafsir/001.json': json({
    'surah': 1,
    'entries': [
      {'from': 1, 'to': 1, 'text': 'T1'},
      {'from': 2, 'to': 2, 'text': 'T2'},
    ],
    'without': <int>[],
  }),
  'assets/ayah/tafsir/002.json': json({
    'surah': 2,
    'entries': [
      {'from': 1, 'to': 2, 'text': 'A'},
      {'from': 4, 'to': 4, 'text': 'B'},
    ],
    'without': [3, 5],
  }),
  'assets/ayah/translation/001.json': json({
    'surah': 1,
    'ayahs': ['One', 'Two'],
  }),
  'assets/ayah/gharib/001.json': json({
    'surah': 1,
    'ayahs': {
      '2': [
        {'w': 'كلمة', 'm': 'معنى', 'b': 327},
        {'w': 'أخرى', 'm': 'معنى آخر', 'b': 208},
      ],
    },
  }),
  'assets/ayah/sources.json': json({
    'sources': [
      {
        'id': 327,
        'kind': 'gharib',
        'title': 'التبيان في تفسير غريب القرآن',
        'author': 'ابن الهائم',
        'provider': 'Quranpedia',
        'link': 'https://quranpedia.net/dumps',
        'file': 'f.gz',
        'version': '2026-11-14',
        'sha256': 'abc',
      },
      {
        'id': 'qul-24',
        'kind': 'tafsir',
        'title': 'تفسير السعدي',
        'provider': 'QUL (Tarteel)',
        'link': 'https://qul.tarteel.ai/resources/tafsir/24',
        'file': 'f.zip',
        'version': '2025-05-26',
        'sha256': 'def',
      },
    ],
  }),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MapBundle bundle;
  late AyahRepository repo;

  setUp(() {
    bundle = MapBundle(sample());
    repo = AyahRepository(bundle);
  });

  group('words', () {
    test('returns the words of the ayah unchanged', () async {
      expect(await repo.words(const AyahRef(1, 1)), ['ب', 'س']);
      expect(await repo.words(const AyahRef(1, 2)), ['ا', 'ل', 'ح']);
    });

    test('an ayah the file does not have is a RangeError', () async {
      await expectLater(repo.words(const AyahRef(1, 3)), throwsRangeError);
    });
  });

  group('tafsir', () {
    test('an ayah inside an entry gets that entry, not inherited', () async {
      final r = await repo.tafsir(const AyahRef(2, 2));
      expect(
        (r.entry.from, r.entry.to, r.entry.text, r.inherited),
        (1, 2, 'A', false),
      );
      expect(r.entry.covers, '1–2');
    });

    test('a single-ayah entry covers only itself', () async {
      final r = await repo.tafsir(const AyahRef(1, 2));
      expect(
        (r.entry.text, r.entry.from == r.entry.to, r.inherited),
        ('T2', true, false),
      );
    });

    test('an ayah in `without` gets the nearest earlier entry and inherited is true', () async {
      final three = await repo.tafsir(const AyahRef(2, 3));
      expect((three.entry.text, three.inherited), ('A', true));
      final five = await repo.tafsir(const AyahRef(2, 5));
      expect((five.entry.text, five.inherited), ('B', true));
    });

    test('an ayah that is neither covered nor listed is a StateError (a build bug)', () async {
      await expectLater(repo.tafsir(const AyahRef(1, 9)), throwsStateError);
    });
  });

  test('translation returns the ayah text', () async {
    expect(await repo.translation(const AyahRef(1, 2)), 'Two');
  });

  group('gharib', () {
    test('lists the entries of the ayah in order with their book', () async {
      final list = await repo.gharib(const AyahRef(1, 2));
      expect(list.map((e) => (e.word, e.meaning, e.book)), [
        ('كلمة', 'معنى', 327),
        ('أخرى', 'معنى آخر', 208),
      ]);
    });

    test('is an empty list for an ayah with no difficult words', () async {
      expect(await repo.gharib(const AyahRef(1, 1)), isEmpty);
    });
  });

  test('sources are read once with their labels', () async {
    final s = await repo.sources();
    expect(s.map((e) => e.id), ['327', 'qul-24']);
    expect(s.first.author, 'ابن الهائم');
    expect(s.first.version, '2026-11-14');
    expect(s.last.author, isNull);
    expect(repo.sourceOfBook(s, 327)?.title, 'التبيان في تفسير غريب القرآن');
    expect(repo.sourceOfBook(s, 1), isNull);
    await repo.sources();
    expect(bundle.loads.where((k) => k.endsWith('sources.json')), hasLength(1));
  });

  group('loading', () {
    test('a surah file is loaded once and then served from memory', () async {
      await repo.words(const AyahRef(1, 1));
      await repo.words(const AyahRef(1, 2));
      expect(bundle.loads.where((k) => k.contains('/text/')), hasLength(1));
    });

    test('two requests at the same time share one load', () async {
      await Future.wait([
        repo.translation(const AyahRef(1, 1)),
        repo.translation(const AyahRef(1, 2)),
      ]);
      expect(
        bundle.loads.where((k) => k.contains('/translation/')),
        hasLength(1),
      );
    });

    test('keeps only the last three surahs of a kind', () async {
      final files = <String, String>{
        for (var s = 1; s <= 5; s++)
          'assets/ayah/translation/${s.toString().padLeft(3, '0')}.json': json({
            'surah': s,
            'ayahs': ['x'],
          }),
      };
      final b = MapBundle(files);
      final r = AyahRepository(b);
      for (final s in [1, 2, 3, 4]) {
        await r.translation(AyahRef(s, 1));
      }
      b.loads.clear();
      for (final s in [4, 3, 2]) {
        await r.translation(AyahRef(s, 1));
      }
      expect(b.loads, isEmpty, reason: 'surahs 2, 3 and 4 are still in memory');
      await r.translation(const AyahRef(1, 1));
      expect(b.loads, [
        'assets/ayah/translation/001.json',
      ], reason: 'surah 1 was evicted');
    });

    test(
      'a big file is decoded off the main isolate and gives the same result',
      () async {
        final big = List.generate(
          4000,
          (i) =>
              'Verse number $i of a long surah, with some text to fill space.',
        );
        final r = AyahRepository(
          MapBundle({
            'assets/ayah/translation/002.json': json({
              'surah': 2,
              'ayahs': big,
            }),
          }),
        );
        expect(await r.translation(const AyahRef(2, 4000)), big.last);
      },
    );

    test('a missing file is a StateError that names the asset', () async {
      await expectLater(
        repo.translation(const AyahRef(2, 1)),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('assets/ayah/translation/002.json'),
          ),
        ),
      );
    });

    test('a malformed file is a StateError that names the asset', () async {
      final r = AyahRepository(
        MapBundle({'assets/ayah/text/001.json': '{not json'}),
      );
      await expectLater(
        r.words(const AyahRef(1, 1)),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('assets/ayah/text/001.json'),
          ),
        ),
      );
    });

    test('a failed load can be retried', () async {
      final b = MapBundle({});
      final r = AyahRepository(b);
      await expectLater(r.translation(const AyahRef(1, 1)), throwsStateError);
      b.files['assets/ayah/translation/001.json'] = json({
        'surah': 1,
        'ayahs': ['ok'],
      });
      expect(await r.translation(const AyahRef(1, 1)), 'ok');
    });
  });
}
