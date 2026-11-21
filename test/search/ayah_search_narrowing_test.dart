// Feature 011, T006: the narrowing of the optional seat letter (research D2): the exact counts the Python reference prints,
// and that none of the 15,122 distinct stored words typed carelessly finds nothing (total 308,124 ayat).
@Timeout(Duration(minutes: 8))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/search/arabic_fold.dart';
import 'package:mushaf/search/ayah_index.dart';

import '../support/search_harness.dart';

int countAyat(AyahIndex index, String typed) {
  final pattern = ArabicFold.pattern(ArabicFold.query(typed));
  var total = 0;
  for (var c = 0; c < index.chunks.length; c++) {
    total += index.scanChunk(c, pattern).length;
  }
  return total;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AyahIndex index;
  setUpAll(() async {
    index = await realIndex();
  });

  // The table of research D2 "The narrowing of the optional seat letter", column "This rule" (match_rules.py section 3).
  const counts = <String, int>{
    'لؤلؤ': 8,
    'رؤيا': 7,
    'سؤال': 1,
    'جزؤا': 6,
    'مئة': 10,
    'مؤمن': 200,
    'سئل': 82,
    'شيئا': 76,
    'شئ': 456,
    'يستهزئون': 14,
    'يستهزؤون': 14,
    'يستهزءون': 14,
    'الملائكة': 53,
    'جزاء': 45,
    'ءامنوا': 266,
    'امنوا': 266,
    'النبيين': 13,
  };
  for (final entry in counts.entries) {
    test('${entry.key} finds exactly ${entry.value} ayat', () {
      expect(countAyat(index, entry.key), entry.value);
    });
  }

  test('the old spelling النبيئين (a hamza the Mushaf does not write) finds nothing (a known limit, research D2)', () {
    expect(countAyat(index, 'النبيئين'), 0);
  });

  test('15,122 distinct stored words typed carelessly: none finds nothing, 308,124 ayat in all', () {
    final typed = <String>{};
    for (var i = 0; i < index.ayahCount; i++) {
      for (final w in index.storedWords(i)) {
        final t = carelessForm(w);
        if (ArabicFold.letters(ArabicFold.query(t)) >= 2) typed.add(t);
      }
    }
    expect(typed.length, 15122);
    var total = 0;
    final nothing = <String>[];
    final watch = Stopwatch()..start();
    var slowest = 0;
    for (final t in typed) {
      final one = Stopwatch()..start();
      final n = countAyat(index, t);
      if (one.elapsedMilliseconds > slowest) slowest = one.elapsedMilliseconds;
      if (n == 0) nothing.add(t);
      total += n;
    }
    // ignore: avoid_print
    print(
      '15,122 words: ${watch.elapsedMilliseconds} ms in all, slowest scan $slowest ms, $total ayat',
    );
    expect(nothing.take(10), isEmpty);
    expect(total, 308124);
  });
}
