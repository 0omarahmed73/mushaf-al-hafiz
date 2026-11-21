import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MushafRepository repo;

  setUp(() => repo = MushafRepository(rootBundle));

  test('meta: al-Kahf starts on page 293, Ayat al-Kursi is on 42, page 604 is juz 30', () async {
    final meta = await repo.loadMeta();
    expect(meta.surahs.length, 114);
    expect(meta.surah(18).startPage, 293);
    expect(meta.surah(18).name, 'الكهف');
    expect(meta.pageOfAyah(2, 255), 42);
    expect(meta.juzOf(604), 30);
    expect(meta.juzOf(1), 1);
  });

  test('meta: surahs on a page and hizb quarter', () async {
    final meta = await repo.loadMeta();
    expect(meta.surahsOn(1), [1]);
    expect(meta.surahsOn(76), [3, 4]); // an-Nisa title sits at the bottom of page 76
    expect(meta.hizbQuarterOf(1), 1);
    expect(meta.surah(4).startPage, 77);
  });

  test('page 1 has 8 lines, first is the Fatiha title, then word 1:1:1', () async {
    final p = await repo.loadPage(1);
    expect(p.page, 1);
    expect(p.lines.length, 8);
    expect(p.lines.first.type, LineType.surahName);
    expect(p.lines.first.surah, 1);
    expect(p.lines.first.words, isEmpty);
    final first = p.lines[1].words.first;
    expect(first.key, '1:1:1');
    expect(first.id, 1);
    expect(first.surah, 1);
    expect(first.ayah, 1);
    expect(first.glyph, isNotEmpty);
  });

  test('page 2 has a basmallah line and page 3 has 15 ayah lines', () async {
    final p2 = await repo.loadPage(2);
    expect(p2.lines[1].type, LineType.basmallah);
    final p3 = await repo.loadPage(3);
    expect(p3.lines.length, 15);
    expect(p3.lines.every((l) => l.type == LineType.ayah), isTrue);
    expect(p3.lines.first.words.first.id, 78);
    expect(p3.lines.last.words.last.id, 215);
  });

  test('every page loads and all 83,668 words appear once and in order', () async {
    var next = 1;
    for (var n = 1; n <= 604; n++) {
      final p = await repo.loadPage(n);
      for (final line in p.lines) {
        for (final w in line.words) {
          expect(w.id, next, reason: 'page $n');
          next++;
        }
      }
    }
    expect(next - 1, 83668);
  });

  test('page outside 1..604 throws RangeError', () {
    expect(() => repo.loadPage(0), throwsRangeError);
    expect(() => repo.loadPage(605), throwsRangeError);
  });

  test('the last pages are cached (same instance)', () async {
    final a = await repo.loadPage(10);
    final b = await repo.loadPage(10);
    expect(identical(a, b), isTrue);
  });
}
