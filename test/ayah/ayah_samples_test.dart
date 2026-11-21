// The by-hand sample of spec SC-002 made automatic, over the real generated assets: the ayahs the owner
// checks (1:1, 2:255, 114:6), an entry that covers two ayahs, and ayahs the tafsir has no text of its own for.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/ayah/share_text.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';

/// The letters of [s] without vowel marks and with alef wasla as alef, so the checks do not depend on how the
/// order of combining marks is typed in this file; the exact words are proved against the Mushaf by the
/// integrity test.
String bare(String s) => s
    .replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
    .replaceAll('ٱ', 'ا');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AyahRepository repo;
  late ShareTextBuilder texts;

  setUpAll(() async {
    repo = AyahRepository(rootBundle);
    texts = ShareTextBuilder(await MushafRepository(rootBundle).loadMeta());
  });

  test(
    '1:1 has the exact shared text, its tafsir and its translation',
    () async {
      const ref = AyahRef(1, 1);
      final shared = texts.ayah(ref, await repo.words(ref));
      expect(bare(shared), '﴿ بسم الله الرحمن الرحيم ﴾\n[سورة الفاتحة: 1]');
      expect(shared.split('\n'), hasLength(2));
      final tafsir = await repo.tafsir(ref);
      expect((tafsir.entry.covers, tafsir.inherited), ('1', false));
      expect(bare(tafsir.entry.text), startsWith('{ بسم الله } أي: أبتدئ'));
      expect(
        await repo.translation(ref),
        'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
      );
    },
  );

  test(
    '2:255 (Ayat al-Kursi) has its own tafsir entry and its translation',
    () async {
      const ref = AyahRef(2, 255);
      final words = await repo.words(ref);
      expect(words.take(4).map(bare), ['الله', 'لا', 'إله', 'إلا']);
      expect(words, hasLength(50));
      expect(texts.ayah(ref, words), endsWith('\n[سورة البقرة: 255]'));
      final tafsir = await repo.tafsir(ref);
      expect((tafsir.entry.covers, tafsir.inherited), ('255', false));
      expect(
        tafsir.entry.text,
        startsWith('هذه الآية الكريمة أعظم آيات القرآن'),
      );
      expect(
        await repo.translation(ref),
        startsWith('Allah - there is no deity except Him, the Ever-Living'),
      );
    },
  );

  test('114:6, the last ayah, has its tafsir and its translation', () async {
    const ref = AyahRef(114, 6);
    expect(
      bare(texts.ayah(ref, await repo.words(ref))),
      '﴿ من الجنة والناس ﴾\n[سورة الناس: 6]',
    );
    final tafsir = await repo.tafsir(ref);
    expect((tafsir.entry.covers, tafsir.inherited), ('6', false));
    expect(tafsir.entry.text, startsWith('وهذه السورة مشتملة على الاستعاذة'));
    expect(await repo.translation(ref), 'From among the jinn and mankind."');
  });

  test(
    '2:23 and 2:24 share one tafsir entry that says it covers 23–24',
    () async {
      final a = await repo.tafsir(const AyahRef(2, 23));
      final b = await repo.tafsir(const AyahRef(2, 24));
      expect((a.entry.covers, b.entry.covers), ('23–24', '23–24'));
      expect(
        identical(a.entry.text, b.entry.text) || a.entry.text == b.entry.text,
        isTrue,
      );
      expect((a.inherited, b.inherited), (false, false));
    },
  );

  test('2:107, 2:286 and 109:4 have no commentary of their own and use the nearest earlier entry', () async {
    for (final ref in const [
      AyahRef(2, 107),
      AyahRef(2, 286),
      AyahRef(109, 4),
    ]) {
      final r = await repo.tafsir(ref);
      expect(r.inherited, isTrue, reason: ref.key);
      expect(r.entry.to, lessThan(ref.ayah), reason: ref.key);
      expect(r.entry.text.trim(), isNotEmpty, reason: ref.key);
      expect((await repo.translation(ref)).trim(), isNotEmpty, reason: ref.key);
    }
  });

  test('2:255 has difficult words from the two classical books, each with a meaning', () async {
    final entries = await repo.gharib(const AyahRef(2, 255));
    expect(entries, isNotEmpty);
    expect(entries.map((e) => e.book).toSet().difference({327, 208}), isEmpty);
    expect(
      entries.every(
        (e) => e.word.trim().isNotEmpty && e.meaning.trim().isNotEmpty,
      ),
      isTrue,
    );
  });
}
