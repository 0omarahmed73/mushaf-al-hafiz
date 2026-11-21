// Feature 011, T006 (SC-003): every one of the 6,236 ayat, pasted exactly as the Mushaf prints it and typed the careless
// way, matches its own ayah: 12,472 of 12,472 queries (spec User Story 3 scenarios 3 and 4; research D2).
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/search/arabic_fold.dart';
import 'package:mushaf/search/ayah_index.dart';

import '../support/search_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AyahIndex index;
  setUpAll(() async {
    index = await realIndex();
  });

  RegExp patternOf(String typed) => ArabicFold.pattern(ArabicFold.query(typed));

  test('SC-003: 12,472 of 12,472 queries (6,236 pasted, 6,236 careless) match their own ayah', () {
    var pasted = 0, careless = 0;
    final failures = <String>[];
    for (var i = 0; i < index.ayahCount; i++) {
      final words = index.storedWords(i).join(' ');
      final folded = index.foldedAyah(i);
      if (patternOf(words).hasMatch(folded)) {
        pasted++;
      } else {
        failures.add('pasted ${index.refOf(i).key}');
      }
      if (patternOf(carelessForm(words)).hasMatch(folded)) {
        careless++;
      } else {
        failures.add('careless ${index.refOf(i).key}');
      }
    }
    expect(failures.take(5), isEmpty);
    expect(pasted, 6236);
    expect(careless, 6236);
    expect(pasted + careless, 12472);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('the ayah with the ornate brackets, the end sign and its number (a pasted ayah) matches too', () {
    for (var i = 0; i < index.ayahCount; i += 7) {
      final words = index.storedWords(i).join(' ');
      final folded = index.foldedAyah(i);
      final number = index.refOf(i).ayah;
      expect(
        patternOf('﴿ $words ﴾').hasMatch(folded),
        isTrue,
        reason: 'brackets ${index.refOf(i).key}',
      );
      expect(
        patternOf('﴿$words ۝$number﴾').hasMatch(folded),
        isTrue,
        reason: 'end sign ${index.refOf(i).key}',
      );
      expect(
        patternOf('$words ۝$number').hasMatch(folded),
        isTrue,
        reason: 'number ${index.refOf(i).key}',
      );
    }
  });

  test('a full scan of the whole text returns the ayah among its hits, for 300 ayat over all 114 surahs', () {
    final picked = <int>{
      // the first ayah of every surah (114) ...
      for (var s = 0; s < 114; s++) index.surahFirst[s],
    };
    // ... and more spread evenly over the whole text, up to 300
    for (var k = 0; picked.length < 300; k++) {
      picked.add(((k * 6236) ~/ 200 + 7) % 6236);
    }
    expect(picked.length, 300);
    expect({for (final i in picked) index.refOf(i).surah}, hasLength(114));
    for (final i in picked) {
      final words = index.storedWords(i).join(' ');
      for (final typed in [words, carelessForm(words)]) {
        final pattern = patternOf(typed);
        final hits = [
          for (var c = 0; c < index.chunks.length; c++)
            ...index.scanChunk(c, pattern),
        ];
        expect(hits, contains(i), reason: index.refOf(i).key);
      }
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
