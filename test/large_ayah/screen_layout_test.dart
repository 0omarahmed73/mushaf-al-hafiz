// The pure screen layout of the large-ayah view (feature 015, research D1 and D3, contracts/dart-interfaces.md).
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/large_ayah/screen_layout.dart';
import 'package:mushaf/mushaf/models.dart';

int _nextId = 1;

/// One ayah of [surah] with [n] words, each [w] wide, and the opening lines before it.
LayoutAyah ayah(int surah, int number, int n, {double w = 10, List<OpeningLine> opening = const []}) {
  final words = [
    for (var i = 1; i <= n; i++)
      MushafWord(id: _nextId++, key: '$surah:$number:$i', glyph: 'g', surah: surah, ayah: number),
  ];
  return LayoutAyah(ref: AyahRef(surah, number), words: words, widths: List.filled(n, w), opening: opening);
}

List<LargeScreen> lay(List<LayoutAyah> ayat, {double width = 35, int lines = 4, int count = 1, int page = 7}) =>
    layoutPage(page: page, ayat: ayat, lineWidth: width, wordGap: 2.5, linesPerScreen: lines, count: count);

void main() {
  setUp(() => _nextId = 1);

  test('wraps greedily: three 10-wide words with a 2.5 gap fit 35, the fourth goes to the next line', () {
    final s = lay([ayah(2, 5, 7)]);
    expect(s, hasLength(1));
    expect([for (final l in s.single.lines) l.length], [3, 3, 1]);
    expect(s.single.ayat, [const AyahRef(2, 5)]);
    expect(s.single.part, isNull);
    expect(s.single.page, 7);
  });

  test('the words stay in order and each appears once', () {
    final a = ayah(2, 5, 7);
    final s = lay([a]);
    expect([for (final l in s.single.lines) ...l], a.words);
  });

  test('count 1: one ayah a screen', () {
    final s = lay([ayah(2, 5, 3), ayah(2, 6, 3), ayah(2, 7, 3)]);
    expect(
      [for (final x in s) x.ayat],
      [
        [const AyahRef(2, 5)],
        [const AyahRef(2, 6)],
        [const AyahRef(2, 7)],
      ],
    );
  });

  test('count 2 and 3: up to count whole ayat while their lines fit, each ayah from a new line', () {
    final ayat = [ayah(2, 5, 3), ayah(2, 6, 3), ayah(2, 7, 3), ayah(2, 8, 3)];
    expect([for (final x in lay(ayat, count: 2)) x.ayat.length], [2, 2]);
    final three = lay(ayat, count: 3);
    expect([for (final x in three) x.ayat.length], [3, 1]);
    expect([for (final l in three.first.lines) l.length], [3, 3, 3]);
  });

  test('an ayah that does not fit with the previous ones starts the next screen; at least one ayah a screen', () {
    // 2 lines + 3 lines > 4: the second ayah goes to its own screen.
    final s = lay([ayah(2, 5, 6), ayah(2, 6, 9), ayah(2, 7, 3)], count: 3);
    // 2:6 (3 lines) and 2:7 (1 line) fit together in the second screen.
    expect(
      [for (final x in s) x.ayat],
      [
        [const AyahRef(2, 5)],
        [const AyahRef(2, 6), const AyahRef(2, 7)],
      ],
    );
  });

  test('an ayah longer than a screen is split between words into parts, numbered, sharing no screen', () {
    final long = ayah(2, 282, 30); // 10 lines of 3
    final s = lay([ayah(2, 281, 3), long, ayah(2, 283, 3)], count: 3);
    expect(s.first.ayat, [const AyahRef(2, 281)]);
    final parts = s.sublist(1, 4);
    expect([for (final p in parts) p.part], [(number: 1, of: 3), (number: 2, of: 3), (number: 3, of: 3)]);
    expect([for (final p in parts) p.lines.length], [4, 4, 2]);
    expect([
      for (final p in parts)
        for (final l in p.lines) ...l,
    ], long.words);
    for (final p in parts) {
      expect(p.ayat, [const AyahRef(2, 282)]);
    }
    expect(s.last.ayat, [const AyahRef(2, 283)]);
    expect(s.last.part, isNull);
  });

  test('the opening lines of a surah belong to the screen of the next ayah and count as lines', () {
    final opening = [const OpeningLine(OpeningKind.surahTitle, surah: 3), const OpeningLine(OpeningKind.basmala)];
    final s = lay([ayah(2, 286, 3), ayah(3, 1, 3, opening: opening), ayah(3, 2, 3)], count: 3);
    // 2:286 (1 line) + opening (2) + 3:1 (1) = 4 lines; 3:2 does not fit.
    expect(
      [for (final x in s) x.ayat],
      [
        [const AyahRef(2, 286), const AyahRef(3, 1)],
        [const AyahRef(3, 2)],
      ],
    );
    expect(s.first.items.map((i) => i.runtimeType.toString()), ['AyahItem', 'OpeningItem', 'OpeningItem', 'AyahItem']);
    expect(s.first.opening, opening);
  });

  test('At-Tawbah: the title alone opens it', () {
    final s = lay([
      ayah(9, 1, 3, opening: [const OpeningLine(OpeningKind.surahTitle, surah: 9)]),
    ]);
    expect(s.single.opening, [const OpeningLine(OpeningKind.surahTitle, surah: 9)]);
    expect(s.single.lines, hasLength(1));
  });

  test('a split ayah with an opening keeps the opening on its first part', () {
    final s = lay([
      ayah(2, 1, 12, opening: [const OpeningLine(OpeningKind.surahTitle, surah: 2)]),
    ]);
    // 4 lines of 3 + 1 opening line > 4: part 1 holds the title and 3 lines, part 2 one line.
    expect([for (final x in s) x.part], [(number: 1, of: 2), (number: 2, of: 2)]);
    expect(s.first.opening, hasLength(1));
    expect(s.last.opening, isEmpty);
    expect([for (final x in s) x.lines.length], [3, 1]);
  });

  test('a surah title on the last line of a page stays at the end of the page\'s last screen', () {
    const title = OpeningLine(OpeningKind.surahTitle, surah: 4);
    final last = ayah(3, 200, 3);
    final withTail = LayoutAyah(ref: last.ref, words: last.words, widths: last.widths, trailing: const [title]);
    final s = lay([ayah(3, 199, 3), withTail], count: 3);
    expect(s, hasLength(1));
    expect(s.single.items.last, isA<OpeningItem>());
    // When the last screen has no room, the last ayah moves to a screen with the title.
    final full = lay([ayah(3, 199, 9), withTail], count: 3);
    expect(
      [for (final x in full) x.ayat],
      [
        [const AyahRef(3, 199)],
        [const AyahRef(3, 200)],
      ],
    );
    expect(full.last.opening, [title]);
  });

  test('a word wider than the line gets a line of its own', () {
    final a = ayah(2, 5, 1, w: 80);
    final b = LayoutAyah(
      ref: a.ref,
      words: [...a.words, ...ayah(2, 5, 2).words],
      widths: [80, 10, 10],
      opening: const [],
    );
    final s = lay([b]);
    expect([for (final l in s.single.lines) l.length], [1, 2]);
  });

  test('every screen is of the given page', () {
    for (final x in lay([ayah(2, 5, 30), ayah(2, 6, 3)], page: 48)) {
      expect(x.page, 48);
    }
  });

  test('an empty page has no screen', () {
    expect(lay(const []), isEmpty);
  });

  test('bad arguments are refused', () {
    final a = [ayah(2, 5, 3)];
    expect(() => lay(a, count: 0), throwsArgumentError);
    expect(() => lay(a, count: 4), throwsArgumentError);
    expect(() => lay(a, lines: 2), throwsArgumentError);
    expect(() => lay(a, width: 0), throwsArgumentError);
  });

  test('pageAyat reads a page: the ayat in order with their words and the opening lines before each', () {
    final page = PageData.fromJson({
      'page': 50,
      'juz': 3,
      'hizbQuarter': 20,
      'lines': [
        {
          'n': 1,
          'type': 'ayah',
          'centered': false,
          'words': [
            {'id': 1, 'k': '2:286:1', 'g': 'a'},
            {'id': 2, 'k': '2:286:2', 'g': 'b'},
          ],
        },
        {'n': 2, 'type': 'surah_name', 'centered': true, 'surah': 3, 'words': []},
        {'n': 3, 'type': 'basmallah', 'centered': true, 'words': []},
        {
          'n': 4,
          'type': 'ayah',
          'centered': false,
          'words': [
            {'id': 3, 'k': '3:1:1', 'g': 'c'},
            {'id': 4, 'k': '3:2:1', 'g': 'd'},
            {'id': 5, 'k': '3:2:2', 'g': 'e'},
          ],
        },
        {
          'n': 5,
          'type': 'ayah',
          'centered': false,
          'words': [
            {'id': 6, 'k': '3:2:3', 'g': 'f'},
          ],
        },
      ],
    });
    final ayat = pageAyat(page);
    expect([for (final a in ayat) a.ref], [const AyahRef(2, 286), const AyahRef(3, 1), const AyahRef(3, 2)]);
    expect(
      [for (final a in ayat) a.words.map((w) => w.id).toList()],
      [
        [1, 2],
        [3],
        [4, 5, 6],
      ],
    );
    expect(ayat[0].opening, isEmpty);
    expect(ayat[1].opening, [
      const OpeningLine(OpeningKind.surahTitle, surah: 3),
      const OpeningLine(OpeningKind.basmala),
    ]);
    expect(ayat[2].opening, isEmpty);
  });
}
