// The bundled city list (feature 014, FR-004a, FR-004b, research D4): search tolerant of hamza and taa marbuta spelling
// like the surah search of feature 011, the nearest city, and every zone known.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/prayer/cities.dart';
import 'package:mushaf/prayer/prayer_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CityIndex index;
  late int loadMs;

  setUpAll(() async {
    final w = Stopwatch()..start();
    index = await CityIndex.load(rootBundle);
    loadMs = w.elapsedMilliseconds;
  });

  test('loads in under 300 ms with about 1,300 cities', () {
    expect(loadMs, lessThan(300));
    expect(index.cities.length, inInclusiveRange(1200, 2500));
  });

  test('spelling-tolerant Arabic search and English search', () {
    expect(index.search('الاسكندريه').first.en, 'Alexandria');
    expect(index.search('اسكندرية').first.en, 'Alexandria');
    expect(index.search('القاهره').first.en, 'Cairo');
    expect(index.search('قاهرة').first.en, 'Cairo');
    expect(index.search('cairo').first.en, 'Cairo');
    expect(index.search('CAI').first.en, 'Cairo');
    expect(index.search('مكه').first.en, 'Makkah');
    expect(index.search('اسوان').first.en, 'Aswan');
    expect(index.search('zzzz'), isEmpty);
  });

  test(
    'a name that starts with the query comes before one that only contains it',
    () {
      final r = index.search('المنصور');
      expect(r.first.ar, 'المنصورة');
    },
  );

  test('an empty query gives the largest cities first, limited', () {
    final r = index.search('');
    expect(r.length, 50);
    expect(r.take(10).map((c) => c.en), contains('Cairo'));
  });

  test('nearest', () {
    expect(index.nearest(30.04, 31.24).en, 'Cairo');
    expect(index.nearest(21.42, 39.83).en, 'Makkah');
    expect(index.nearest(31.2, 29.92).en, 'Alexandria');
  });

  test('every zone exists in the time-zone database', () {
    for (final c in index.cities) {
      expect(zoneKnown(c.tz), isTrue, reason: '${c.en} ${c.tz}');
    }
  });

  test('a keystroke search takes under 50 ms', () {
    final w = Stopwatch()..start();
    for (final q in ['ا', 'ال', 'الق', 'القا', 'القاه']) {
      index.search(q);
    }
    expect(w.elapsedMilliseconds / 5, lessThan(50));
  });
}
