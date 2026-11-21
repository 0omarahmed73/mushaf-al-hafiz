import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/file_names.dart';
import 'package:mushaf/ayah/surah_pages.dart';
import 'package:mushaf/mushaf/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('FileNames', () {
    test('page: «مصحف - صفحة 293.png» with digits 0-9', () {
      expect(FileNames.page(293), 'مصحف - صفحة 293.png');
      expect(FileNames.page(1), 'مصحف - صفحة 1.png');
      expect(FileNames.page(604), 'مصحف - صفحة 604.png');
    });

    test('surah: «سورة البقرة.pdf»', () {
      expect(FileNames.surah('البقرة'), 'سورة البقرة.pdf');
      expect(FileNames.surah('آل عمران'), 'سورة آل عمران.pdf');
    });

    test(
      'forbidden characters become a space and repeated spaces collapse',
      () {
        expect(
          FileNames.surah('a/b\\c:d*e?f"g<h>i|j'),
          'سورة a b c d e f g h i j.pdf',
        );
        expect(FileNames.surah('x  //  y'), 'سورة x y.pdf');
        expect(FileNames.surah('a\u0000b\nc'), 'سورة a b c.pdf');
      },
    );

    test('rejects pages outside 1..604', () {
      expect(() => FileNames.page(0), throwsRangeError);
      expect(() => FileNames.page(605), throwsRangeError);
    });
  });

  group('SurahPages', () {
    late MushafMeta meta;

    setUpAll(() async {
      final text = await rootBundle.loadString('assets/mushaf/meta.json');
      meta = MushafMeta.fromJson(jsonDecode(text) as Map<String, dynamic>);
    });

    test('Al-Fatiha is page 1 only', () {
      final p = SurahPages.of(meta, 1);
      expect((p.first, p.last, p.count), (1, 1, 1));
    });

    test('Al-Baqarah is pages 2 to 49, 48 pages', () {
      final p = SurahPages.of(meta, 2);
      expect((p.first, p.last, p.count), (2, 49, 48));
    });

    test('Al-Ikhlas is page 604 and shares it with its neighbours', () {
      final p = SurahPages.of(meta, 112);
      expect((p.first, p.last, p.count), (604, 604, 1));
    });

    test('An-Nas is page 604', () {
      expect(SurahPages.of(meta, 114).first, 604);
    });

    test('the pages of all surahs cover the Mushaf in order and each surah has at least one page', () {
      var previousLast = 0;
      for (var s = 1; s <= 114; s++) {
        final p = SurahPages.of(meta, s);
        expect(p.count, greaterThanOrEqualTo(1), reason: 'surah $s');
        expect(p.first, lessThanOrEqualTo(p.last), reason: 'surah $s');
        expect(p.first, greaterThanOrEqualTo(previousLast), reason: 'surah $s');
        previousLast = p.last;
      }
      expect(previousLast, 604);
    });

    test('rejects a surah outside 1..114', () {
      expect(() => SurahPages.of(meta, 0), throwsRangeError);
      expect(() => SurahPages.of(meta, 115), throwsRangeError);
    });
  });
}
