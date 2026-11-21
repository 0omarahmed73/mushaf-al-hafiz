// Feature 011, T007: the surah search over the 114 real names of assets/mushaf/meta.json (spec FR-004, FR-009, SC-001;
// research D2 "Surah names").
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/search/arabic_fold.dart';
import 'package:mushaf/search/surah_search.dart';

import '../support/search_harness.dart';

List<int> numbers(List<SurahInfo> rows) => [for (final s in rows) s.number];

/// The five careless ways of User Story 1 (match_rules.py five_ways): as shown; every hamza bare; ة as ه and ى as ي; with
/// «سورة » in front; without the leading «ال».
List<String> fiveWays(String name) {
  final bare = name
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ٱ', 'ا')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll('ء', '');
  final soft = name.replaceAll('ة', 'ه').replaceAll('ى', 'ي');
  final withoutAl = name.startsWith('ال') && name.length > 2
      ? name.substring(2)
      : name;
  return [name, bare, soft, 'سورة $name', withoutAl];
}

String stripAl(String key) =>
    key.startsWith('ال') && key.length > 2 ? key.substring(2) : key;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MushafMeta meta;
  late List<SurahInfo> surahs;
  setUpAll(() async {
    meta = await realMeta();
    surahs = meta.surahs;
  });

  List<SurahInfo> search(String typed) => searchSurahs(surahs, typed);

  test('SC-001: 570 queries (114 names in five careless ways) list the right surah, and the name that equals the query is the first row', () {
    var queries = 0;
    final failures = <String>[];
    for (final s in surahs) {
      for (final typed in fiveWays(s.name)) {
        queries++;
        final rows = search(typed);
        if (rows.isEmpty || rows.first.number != s.number) {
          failures.add(
            '${s.number} ${s.name} "$typed" -> ${numbers(rows).take(3)}',
          );
        }
        expect(rows.length, lessThanOrEqualTo(114));
      }
    }
    expect(queries, 570);
    expect(failures, isEmpty);
  });

  test('كهف and الكهف and سورة الكهف list 18', () {
    for (final typed in [
      'كهف',
      'الكهف',
      'سورة الكهف',
      'الْكَهْفِ',
      'ٱلۡكَهۡفِ',
    ]) {
      expect(numbers(search(typed)), [18], reason: typed);
    }
    expect(search('كهف').single.name, 'الكهف');
  });

  test(
    'سبأ, سبا, سبإ list 34 and the row keeps the name as the index writes it',
    () {
      for (final typed in ['سبأ', 'سبا', 'سبإ']) {
        final rows = search(typed);
        expect(numbers(rows), [34], reason: typed);
        expect(rows.single.name, meta.surah(34).name);
      }
    },
  );

  test(
    'الإنسان and الانسان list 76; النبأ and النبإ list 78; ابراهيم lists 14',
    () {
      expect(numbers(search('الإنسان')), [76]);
      expect(numbers(search('الانسان')), [76]);
      expect(numbers(search('النبأ')), [78]);
      expect(numbers(search('النبإ')), [78]);
      expect(numbers(search('ابراهيم')), [14]);
      expect(numbers(search('إبراهيم')), [14]);
      expect(numbers(search('المؤمنون')), [23]);
      expect(numbers(search('المومنون')), [23]);
    },
  );

  test('الحج lists 22, 15, 49 in that order', () {
    expect(numbers(search('الحج')), [22, 15, 49]);
  });

  test('ق lists 50 first and ص lists 38 first (one letter is enough)', () {
    expect(search('ق').first.number, 50);
    expect(search('ص').first.number, 38);
    expect(search('ق').length, greaterThan(1));
    expect(numbers(search('ص')).sublist(0, 2), [
      38,
      37,
    ]); // the equal name before a lower number that only starts with it
  });

  test('the order is the name that equals, then names that start with it, then names that contain it, then surah number', () {
    // قريش starts with «قر» (rank 1), البقرة contains it once the leading ال is dropped (rank 2) although its number is lower
    expect(numbers(search('قر')), [106, 2]);
    // both contain «حم»: surah order
    expect(numbers(search('حم')), [47, 55]);
    // from the whole list, every query's rows are never out of rank order
    for (final s in surahs) {
      for (final typed in fiveWays(s.name)) {
        var q = ArabicFold.query(typed)
            .replaceAll(ArabicFold.seatWaw, 'و')
            .replaceAll(ArabicFold.seatYeh, 'ي');
        if (q.startsWith('سوره ')) q = q.substring(5);
        final forms = {q.replaceAll(' ', ''), stripAl(q.replaceAll(' ', ''))};
        int rank(SurahInfo r) {
          final key = ArabicFold.surahKey(r.name);
          var best = 3;
          for (final f in forms) {
            for (final n in {key, stripAl(key)}) {
              final v = n == f
                  ? 0
                  : (n.startsWith(f) ? 1 : (n.contains(f) ? 2 : 3));
              if (v < best) best = v;
            }
          }
          return best;
        }

        final rows = search(typed);
        for (var i = 0; i < rows.length; i++) {
          expect(
            rank(rows[i]),
            lessThan(3),
            reason: '"$typed" ${rows[i].name}',
          );
          if (i > 0) {
            final a = rank(rows[i - 1]), b = rank(rows[i]);
            expect(
              a <= b,
              isTrue,
              reason: '"$typed" ${rows[i - 1].name} before ${rows[i].name}',
            );
            if (a == b) {
              expect(
                rows[i - 1].number,
                lessThan(rows[i].number),
                reason: '"$typed" ties are in surah order',
              );
            }
          }
        }
      }
    }
  });

  test('a query with no Arabic letter lists nothing', () {
    for (final typed in [
      '',
      ' ',
      '   ',
      '123',
      '١٢٣',
      'abc',
      '2:255',
      '﴿ ﴾',
      'َُّ',
      'ـــ',
      ',.;',
    ]) {
      expect(search(typed), isEmpty, reason: '"$typed"');
    }
  });

  test('a leading «سورة» alone is not dropped; before something it is', () {
    expect(search('سورة'), isEmpty);
    expect(search('سورة '), isEmpty);
    expect(search('سورة ').length, 0);
    expect(numbers(search('سورة الكهف')), [18]);
    expect(numbers(search('سورة كهف')), [18]);
    expect(search('سورة ال'), search('ال'));
    expect(search('سورة ال'), isNotEmpty);
  });

  test('a typed hamza, dagger or tashkeel in the query changes nothing', () {
    expect(numbers(search('الرحمٰن')), [55]);
    expect(numbers(search('الرَّحْمَٰنِ')), [55]);
    expect(numbers(search('سبء')), numbers(search('سب')));
    expect(numbers(search('سب')), [34]);
  });

  test(
    'آل عمران is found with the space typed or not, with or without «آل»',
    () {
      expect(numbers(search('آل عمران')), [3]);
      expect(numbers(search('ال عمران')), [3]);
      expect(numbers(search('عمران')), [3]);
      expect(numbers(search('آلعمران')), [3]);
    },
  );

  test('never more than 114 rows, and a very common query lists them in surah order without repeats', () {
    for (final typed in ['ا', 'ال', 'ل', 'ن', 'م', 'ا ل']) {
      final rows = search(typed);
      expect(rows.length, lessThanOrEqualTo(114), reason: typed);
      expect(numbers(rows).toSet().length, rows.length, reason: typed);
    }
    expect(search('ا').length, greaterThan(50));
  });

  test('no two names are equal after dropping the leading «ال»', () {
    final keys = [for (final s in surahs) stripAl(ArabicFold.surahKey(s.name))];
    expect(keys.toSet().length, 114);
    expect(surahs.length, 114);
  });

  test('a query that matches no name lists nothing', () {
    expect(search('ظظ'), isEmpty);
    expect(search('المؤمنين'), isEmpty);
    expect(search('كهفف'), isEmpty);
  });

  test('searching does not change the list it is given', () {
    final before = numbers(surahs);
    search('ال');
    expect(numbers(surahs), before);
  });
}
