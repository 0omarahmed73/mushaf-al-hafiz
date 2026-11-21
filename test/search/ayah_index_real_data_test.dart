// Feature 011, T004: the AyahIndex built from all 114 real surah files (spec FR-018, FR-019, SC-009; research D1, D3).
@Timeout(Duration(minutes: 4))
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/search/arabic_fold.dart';
import 'package:mushaf/search/ayah_index.dart';

import '../support/search_harness.dart';

/// The fold fingerprint printed by specs/011-surah-ayah-search/prototype/match_rules.py: FNV-1a 32 over the UTF-16 code
/// units of every folded ayah followed by a line break.
const int kFoldFingerprint = 0xd2ba2ab9;

int fingerprintOf(Iterable<String> texts) {
  var h = 0x811C9DC5;
  for (final text in texts) {
    for (final unit in text.codeUnits) {
      h = ((h ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
  }
  return h;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MushafMeta meta;
  late AyahIndex index;
  final files = <int, String>{};
  // the stored words of every ayah, read from the files by the test itself
  final stored = <List<String>>[];

  setUpAll(() async {
    meta = await realMeta();
    for (var s = 1; s <= MushafMeta.surahCount; s++) {
      final text = await rootBundle.loadString(realTextPath(s), cache: false);
      files[s] = text;
      final d = jsonDecode(text) as Map<String, dynamic>;
      for (final a in d['ayahs'] as List<dynamic>) {
        stored.add((a as List<dynamic>).cast<String>());
      }
    }
    index = await realIndex();
  });

  test(
    '6,236 ayat and 77,432 words, the per-surah counts equal the Mushaf meta',
    () {
      expect(index.ayahCount, 6236);
      expect(stored, hasLength(6236));
      var words = 0;
      for (var i = 0; i < index.ayahCount; i++) {
        words += index.storedWords(i).length;
      }
      expect(words, 77432);
      for (var s = 1; s <= MushafMeta.surahCount; s++) {
        expect(
          index.surahFirst[s] - index.surahFirst[s - 1],
          meta.surah(s).ayahs,
          reason: 'surah $s',
        );
      }
      expect(index.surahFirst[0], 0);
      expect(index.surahFirst[MushafMeta.surahCount], 6236);
      expect(index.surahFirst, hasLength(115));
    },
  );

  test('the stored words are the files\' words, unchanged', () {
    for (var i = 0; i < index.ayahCount; i++) {
      expect(index.storedWords(i), stored[i], reason: 'ayah index $i');
    }
  });

  test('no stored word folds to the empty string', () {
    var empty = 0;
    for (final words in stored) {
      for (final w in words) {
        if (ArabicFold.word(w).isEmpty) empty++;
      }
    }
    expect(empty, 0);
  });

  test('the folded ayah is its stored words folded and joined by one space, for all 6,236', () {
    for (var i = 0; i < index.ayahCount; i++) {
      expect(
        index.foldedAyah(i),
        ArabicFold.ayah(stored[i]),
        reason: 'ayah index $i',
      );
    }
  });

  test('8 chunks (7 of 800 ayat and one of 636), each ayah followed by one line break', () {
    expect(index.chunks, hasLength(8));
    var total = 0;
    for (var c = 0; c < 8; c++) {
      final chunk = index.chunks[c];
      final breaks = '\n'.allMatches(chunk).length;
      expect(breaks, c < 7 ? 800 : 636, reason: 'chunk $c');
      expect(chunk.endsWith('\n'), isTrue, reason: 'chunk $c');
      expect(chunk.contains('\n\n'), isFalse, reason: 'chunk $c');
      total += chunk.length;
    }
    expect(total, 413093);
    expect(index.chunks[7].length, index.ayahStart[6236]);
  });

  test('the concatenated chunks have the fold fingerprint 0xd2ba2ab9 of the Python reference', () {
    final fingerprint = fingerprintOf(index.chunks);
    // ignore: avoid_print
    print('fold fingerprint 0x${fingerprint.toRadixString(16)}');
    expect(fingerprint, kFoldFingerprint);
  });

  test('ayahStart is strictly increasing inside a chunk and starts every chunk at 0', () {
    expect(index.ayahStart, hasLength(6237));
    for (var c = 0; c < 8; c++) {
      final first = c * AyahIndex.ayahsPerChunk;
      final last =
          (first + AyahIndex.ayahsPerChunk < 6236
              ? first + AyahIndex.ayahsPerChunk
              : 6236) -
          1;
      expect(index.ayahStart[first], 0, reason: 'chunk $c');
      for (var i = first; i < last; i++) {
        expect(
          index.ayahStart[i + 1],
          greaterThan(index.ayahStart[i]),
          reason: 'ayah index $i',
        );
      }
      expect(
        index.chunks[c].length,
        greaterThan(index.ayahStart[last]),
        reason: 'chunk $c',
      );
    }
  });

  test('refOf and indexOf agree for all 6,236 ayat', () {
    var i = 0;
    for (final s in meta.surahs) {
      for (var a = 1; a <= s.ayahs; a++) {
        final ref = index.refOf(i);
        expect(ref, AyahRef(s.number, a), reason: 'index $i');
        expect(index.indexOf(ref), i, reason: ref.key);
        i++;
      }
    }
    expect(i, 6236);
    expect(index.refOf(0), const AyahRef(1, 1));
    expect(index.refOf(6235), const AyahRef(114, 6));
    expect(index.indexOf(const AyahRef(2, 255)), 7 + 254);
    expect(() => index.refOf(-1), throwsRangeError);
    expect(() => index.refOf(6236), throwsRangeError);
    expect(() => index.indexOf(const AyahRef(1, 8)), throwsRangeError);
    expect(() => index.indexOf(const AyahRef(114, 7)), throwsRangeError);
  });

  test('meta.pageOfAyah is the page of the ayah\'s first word, for all 6,236 (2:282 is on page 48)', () async {
    final mushaf = MushafRepository(rootBundle);
    final firstWordPage = <String, int>{};
    for (var p = 1; p <= MushafMeta.pageCount; p++) {
      final page = await mushaf.loadPage(p);
      for (final line in page.lines) {
        for (final w in line.words) {
          if (w.key.endsWith(':1')) {
            firstWordPage['${w.surah}:${w.ayah}'] = p;
          }
        }
      }
    }
    expect(firstWordPage, hasLength(6236));
    for (var i = 0; i < index.ayahCount; i++) {
      final ref = index.refOf(i);
      expect(
        meta.pageOfAyah(ref.surah, ref.ayah),
        firstWordPage[ref.key],
        reason: ref.key,
      );
    }
    expect(meta.pageOfAyah(2, 282), 48);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('the index is small: estimatedBytes is under 6 MB', () {
    expect(index.estimatedBytes, lessThan(6 * 1024 * 1024));
    expect(index.estimatedBytes, greaterThan(1024 * 1024));
  });

  group('AyahIndexBuilder rejects with SearchIndexError', () {
    final isIndexError = throwsA(isA<SearchIndexError>());

    AyahIndexBuilder addAll({
      int upTo = 114,
      Map<int, String> replace = const {},
    }) {
      final b = AyahIndexBuilder();
      for (var s = 1; s <= upTo; s++) {
        b.addSurah(s, replace[s] ?? files[s]!);
      }
      return b;
    }

    String edited(int surah, void Function(List<dynamic> ayahs) change) {
      final d = jsonDecode(files[surah]!) as Map<String, dynamic>;
      change(d['ayahs'] as List<dynamic>);
      return jsonEncode(d);
    }

    test('a surah added out of order', () {
      final b = AyahIndexBuilder();
      expect(() => b.addSurah(2, files[2]!), isIndexError);
      final c = AyahIndexBuilder()..addSurah(1, files[1]!);
      expect(() => c.addSurah(3, files[3]!), isIndexError);
      expect(() => c.addSurah(1, files[1]!), isIndexError);
    });

    test('malformed JSON, a wrong shape, a wrong surah number, no ayat', () {
      for (final bad in [
        'not json',
        '',
        '[]',
        '{}',
        '{"surah":1}',
        '{"surah":1,"ayahs":"x"}',
        '{"surah":1,"ayahs":[1,2]}',
        '{"surah":1,"ayahs":[[1,2]]}',
        '{"surah":2,"ayahs":[["قُلۡ"]]}',
        '{"surah":1,"ayahs":[]}',
        '{"surah":1,"ayahs":[[]]}',
        '{"surah":1,"ayahs":[["قُلۡ\\nهُوَ"]]}',
      ]) {
        expect(
          () => AyahIndexBuilder().addSurah(1, bad),
          isIndexError,
          reason: bad,
        );
      }
    });

    test('a word that folds to nothing', () {
      expect(
        () => AyahIndexBuilder().addSurah(
          1,
          '{"surah":1,"ayahs":[["قُلۡ","ۡ"]]}',
        ),
        isIndexError,
      );
      expect(
        () => AyahIndexBuilder().addSurah(1, '{"surah":1,"ayahs":[["abc"]]}'),
        isIndexError,
      );
      expect(
        () => AyahIndexBuilder().addSurah(1, '{"surah":1,"ayahs":[[""]]}'),
        isIndexError,
      );
      expect(
        () => addAll(
          replace: {57: edited(57, (a) => (a[3] as List<dynamic>)[0] = '۞')},
        ),
        isIndexError,
      );
    });

    test('build with 113 surahs', () {
      final b = addAll(upTo: 113);
      expect(() => b.build(meta), isIndexError);
      expect(() => AyahIndexBuilder().build(meta), isIndexError);
    });

    test('build with one ayah fewer in a surah', () {
      final b = addAll(replace: {2: edited(2, (a) => a.removeLast())});
      expect(() => b.build(meta), isIndexError);
    });

    test('build with a count different from meta (one ayah more)', () {
      final b = addAll(
        replace: {
          3: edited(3, (a) => a.add(['قُلۡ'])),
        },
      );
      expect(() => b.build(meta), isIndexError);
    });
  });
}
