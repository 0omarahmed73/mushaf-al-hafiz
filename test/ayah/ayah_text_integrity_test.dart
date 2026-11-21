// Runs over the real generated assets (run `uv run python tool/build_ayah_assets.py` first).
// Spec FR-008, FR-013, SC-002, SC-003: the shared text of every ayah is exactly the Mushaf's words for
// it, and every ayah has a translation and a tafsir.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/ayah/share_text.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MushafMeta meta;
  late AyahRepository repo;
  // "s:a" -> the word numbers the Mushaf draws for that ayah (the last one is the end marker)
  final mushafWords = <String, List<int>>{};
  final refs = <AyahRef>[];

  setUpAll(() async {
    final mushaf = MushafRepository(rootBundle);
    meta = await mushaf.loadMeta();
    for (var p = 1; p <= MushafMeta.pageCount; p++) {
      final page = await mushaf.loadPage(p);
      for (final line in page.lines) {
        for (final w in line.words) {
          mushafWords
              .putIfAbsent('${w.surah}:${w.ayah}', () => [])
              .add(int.parse(w.key.split(':')[2]));
        }
      }
    }
    for (final s in meta.surahs) {
      for (var a = 1; a <= s.ayahs; a++) {
        refs.add(AyahRef(s.number, a));
      }
    }
    repo = AyahRepository(rootBundle);
  });

  const timeout = Timeout(Duration(minutes: 4));

  test('the Mushaf has 6,236 ayahs', () {
    expect(refs, hasLength(6236));
    expect(mushafWords, hasLength(6236));
  });

  test('the words of every ayah are the Mushaf words 1..n-1 (marker excluded) and the shared text is exactly the two lines', () async {
    final builder = ShareTextBuilder(meta);
    var total = 0;
    for (final ref in refs) {
      final numbers = mushafWords[ref.key]!..sort();
      final words = await repo.words(ref);
      expect(
        numbers,
        List.generate(numbers.length, (i) => i + 1),
        reason: '${ref.key} positions',
      );
      expect(
        words.length,
        numbers.length - 1,
        reason: '${ref.key}: words vs Mushaf words without the marker',
      );
      expect(
        words.every((w) => w.isNotEmpty && w == w.trim()),
        isTrue,
        reason: '${ref.key}: padded or empty word',
      );
      total += words.length;
      final text = builder.ayah(ref, words);
      final lines = text.split('\n');
      expect(lines, hasLength(2), reason: ref.key);
      expect(lines[0], '﴿ ${words.join(' ')} ﴾', reason: ref.key);
      expect(
        lines[1],
        '[سورة ${meta.surah(ref.surah).name}: ${ref.ayah}]',
        reason: ref.key,
      );
      expect(
        RegExp('[٠-٩]').hasMatch(lines[1]),
        isFalse,
        reason: '${ref.key}: reference uses 0-9',
      );
    }
    expect(total, 77432);
  }, timeout: timeout);

  test('every ayah has a tafsir; exactly 59 use the nearest earlier entry (FR-009a)', () async {
    var inherited = 0;
    for (final ref in refs) {
      final r = await repo.tafsir(ref);
      expect(r.entry.text.trim(), isNotEmpty, reason: ref.key);
      expect(r.entry.from, lessThanOrEqualTo(ref.ayah), reason: ref.key);
      if (r.inherited) {
        inherited++;
        expect(r.entry.to, lessThan(ref.ayah), reason: ref.key);
      } else {
        expect(r.entry.contains(ref.ayah), isTrue, reason: ref.key);
      }
    }
    expect(inherited, 59);
  }, timeout: timeout);

  test('every ayah has a non-empty English translation', () async {
    for (final ref in refs) {
      expect((await repo.translation(ref)).trim(), isNotEmpty, reason: ref.key);
    }
  }, timeout: timeout);

  test('3,689 ayahs have difficult words, all from the two classical books, each with a source', () async {
    final sources = await repo.sources();
    expect(
      sources.map((s) => s.id),
      unorderedEquals(['qul-312', 'qul-24', 'tanzil-en-sahih', '327', '208']),
    );
    var covered = 0;
    for (final ref in refs) {
      final entries = await repo.gharib(ref);
      if (entries.isNotEmpty) covered++;
      for (final e in entries) {
        expect(e.word.trim(), isNotEmpty, reason: ref.key);
        expect(e.meaning.trim(), isNotEmpty, reason: ref.key);
        expect(
          repo.sourceOfBook(sources, e.book),
          isNotNull,
          reason: '${ref.key} book ${e.book}',
        );
      }
    }
    expect(covered, 3689);
  }, timeout: timeout);
}
