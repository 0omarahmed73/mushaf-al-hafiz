import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/models.dart';

MushafWord word(int id, int surah, int ayah, int n) => MushafWord(
  id: id,
  key: '$surah:$ayah:$n',
  glyph: 'g$id',
  surah: surah,
  ayah: ayah,
);

PageData page(List<List<MushafWord>> lines) => PageData(
  page: 1,
  juz: 1,
  hizbQuarter: 1,
  lines: [
    for (var i = 0; i < lines.length; i++)
      MushafLine(
        number: i + 1,
        type: LineType.ayah,
        centered: false,
        surah: null,
        words: lines[i],
      ),
  ],
);

void main() {
  group('AyahRef', () {
    test('has value equality, a key and a readable string', () {
      expect(const AyahRef(2, 255), const AyahRef(2, 255));
      expect(const AyahRef(2, 255) == const AyahRef(2, 256), isFalse);
      expect(const AyahRef(2, 255).hashCode, const AyahRef(2, 255).hashCode);
      expect(const AyahRef(2, 255).key, '2:255');
      expect({const AyahRef(1, 1): 'a'}[const AyahRef(1, 1)], 'a');
    });

    test('validated() accepts real ayahs and rejects the impossible ones', () {
      final meta = MushafMeta(
        surahs: const [
          SurahInfo(number: 1, name: 'الفاتحة', ayahs: 7, startPage: 1),
          SurahInfo(number: 2, name: 'البقرة', ayahs: 286, startPage: 2),
        ],
        pageJuz: const [],
        pageHizbQuarter: const [],
        pageSurahs: const [],
        ayahPage: const {},
      );
      expect(AyahRef.validated(meta, 2, 286), const AyahRef(2, 286));
      for (final bad in [(0, 1), (3, 1), (1, 0), (1, 8), (2, 287)]) {
        expect(
          () => AyahRef.validated(meta, bad.$1, bad.$2),
          throwsRangeError,
          reason: '$bad',
        );
      }
    });
  });

  group('ayahOfWord', () {
    test('is the surah and ayah of the word', () {
      expect(ayahOfWord(word(7, 18, 9, 3)), const AyahRef(18, 9));
    });
  });

  group('wordIdsOfAyah', () {
    test('returns every word of the ayah on the page, end marker included', () {
      final p = page([
        [word(1, 1, 1, 1), word(2, 1, 1, 2), word(3, 1, 1, 3)], // 1:1 + marker
        [word(4, 1, 2, 1), word(5, 1, 2, 2), word(6, 1, 2, 3)],
      ]);
      expect(wordIdsOfAyah(p, const AyahRef(1, 1)), {1, 2, 3});
      expect(wordIdsOfAyah(p, const AyahRef(1, 2)), {4, 5, 6});
    });

    test(
      'collects the words of one ayah that are spread over several lines',
      () {
        final p = page([
          [word(1, 2, 5, 1), word(2, 2, 5, 2)],
          [word(3, 2, 5, 3), word(4, 2, 5, 4)],
          [word(5, 2, 6, 1)],
        ]);
        expect(wordIdsOfAyah(p, const AyahRef(2, 5)), {1, 2, 3, 4});
      },
    );

    test('is empty when the ayah is not on the page', () {
      final p = page([
        [word(1, 1, 1, 1)],
      ]);
      expect(wordIdsOfAyah(p, const AyahRef(1, 2)), isEmpty);
      expect(wordIdsOfAyah(p, const AyahRef(2, 1)), isEmpty);
    });

    test('an ayah that continues on the next page gives only its part on this page', () {
      final first = page([
        [word(10, 3, 1, 1), word(11, 3, 1, 2)],
      ]);
      final second = page([
        [word(12, 3, 1, 3), word(13, 3, 1, 4)],
      ]);
      expect(wordIdsOfAyah(first, const AyahRef(3, 1)), {10, 11});
      expect(wordIdsOfAyah(second, const AyahRef(3, 1)), {12, 13});
    });

    test('ignores title and basmallah lines (they have no words)', () {
      final p = PageData(
        page: 2,
        juz: 1,
        hizbQuarter: 1,
        lines: [
          const MushafLine(
            number: 1,
            type: LineType.surahName,
            centered: true,
            surah: 2,
            words: [],
          ),
          const MushafLine(
            number: 2,
            type: LineType.basmallah,
            centered: true,
            surah: null,
            words: [],
          ),
          MushafLine(
            number: 3,
            type: LineType.ayah,
            centered: true,
            surah: null,
            words: [word(1, 2, 1, 1)],
          ),
        ],
      );
      expect(wordIdsOfAyah(p, const AyahRef(2, 1)), {1});
    });
  });
}
