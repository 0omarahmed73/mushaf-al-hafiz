// The words a page tints for its bookmarked ayat (feature 013, spec FR-016, FR-025, SC-014; research D6): the ids come from
// the page's own words, never from a stored page, so an ayah that crosses two pages is tinted on both, each its own part.
// Real page data, read from the project's assets through MushafRepository (the end markers are derived there).
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/ayah_tint.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';

import '../support/motion_probe.dart';

void main() {
  late MushafRepository repo;
  late MushafMeta meta;

  setUpAll(() async {
    repo = MushafRepository(FileBundle());
    meta = await repo.loadMeta();
  });

  Future<PageData> page(int n) => repo.loadPage(n);

  /// Every word of [p] whose ayah is [ref], read straight from the lines.
  Set<int> wordsOf(PageData p, AyahRef ref) => {
    for (final l in p.lines)
      for (final w in l.words)
        if (w.surah == ref.surah && w.ayah == ref.ayah) w.id,
  };

  test(
    'an ayah of one page gives exactly its words, the end marker included',
    () async {
      const ref = AyahRef(2, 255);
      final p = await page(meta.pageOfAyah(2, 255));
      final ids = ayahTintIds(p, {ref});
      final expected = wordsOf(p, ref);
      expect(expected, isNotEmpty);
      expect(ids, expected);
      final marker = p.endMarkerIds.intersection(expected);
      expect(marker, hasLength(1), reason: 'the ayah ends on this page');
      expect(ids.containsAll(marker), isTrue);
    },
  );

  // In this edition no ayah crosses a page (checked over the 604 pages when feature 013 was built): 2:282, the longest
  // ayah, fills page 48 alone and page 49 opens with 2:283. The function still reads the page's own words.
  test(
    '2:282 is wholly on page 48, with its end marker, and nowhere else',
    () async {
      const ref = AyahRef(2, 282);
      final p48 = await page(48);
      final on48 = ayahTintIds(p48, {ref});
      expect(on48, isNotEmpty);
      expect(on48, wordsOf(p48, ref));
      expect(
        on48.intersection(p48.endMarkerIds),
        hasLength(1),
        reason: 'its end marker is on page 48',
      );
      for (final n in [47, 49, 50]) {
        expect(ayahTintIds(await page(n), {ref}), isEmpty, reason: 'page $n');
      }
    },
  );

  test('an empty set gives empty', () async {
    expect(ayahTintIds(await page(48), const {}), isEmpty);
    expect(ayahTintIds(await page(1), <AyahRef>{}), isEmpty);
  });

  test('two ayat give the union, each word by word', () async {
    final p = await page(1);
    const a = AyahRef(1, 2), b = AyahRef(1, 3);
    final ids = ayahTintIds(p, {a, b});
    expect(wordsOf(p, a), isNotEmpty);
    expect(wordsOf(p, b), isNotEmpty);
    expect(ids, {...wordsOf(p, a), ...wordsOf(p, b)});
    expect(
      ids.intersection(wordsOf(p, const AyahRef(1, 4))),
      isEmpty,
      reason: 'the next ayah is not tinted',
    );
  });

  test('an ayah not on the page gives empty, among others that are', () async {
    final p = await page(48);
    expect(ayahTintIds(p, {const AyahRef(2, 1)}), isEmpty);
    expect(ayahTintIds(p, {const AyahRef(114, 6)}), isEmpty);
    expect(
      ayahTintIds(p, {const AyahRef(2, 1), const AyahRef(2, 282)}),
      wordsOf(p, const AyahRef(2, 282)),
    );
  });

  test('a surah-start ayah whose title is on the previous page is found by its words', () async {
    // Surah 4: its title and basmallah close page 76, its first ayah opens page 77.
    const ref = AyahRef(4, 1);
    expect(meta.pageOfAyah(4, 1), 77);
    final p76 = await page(76);
    final p77 = await page(77);
    expect(
      p76.lines.any((l) => l.surah == 4),
      isTrue,
      reason: 'the title of surah 4 is on page 76',
    );
    expect(
      ayahTintIds(p76, {ref}),
      isEmpty,
      reason: 'a title or basmallah line is never tinted',
    );
    final on77 = ayahTintIds(p77, {ref});
    expect(on77, isNotEmpty);
    expect(on77, wordsOf(p77, ref));
    final first = p77.lines.expand((l) => l.words).first;
    expect(on77, contains(first.id));
  });
}
