// Feature 011, T006 (SC-004's automated bound): 20 queries, each finishes in under 1 s on the machine, «ال» returns 5,182
// ayat, and the 1,500-character query of 2:282 repeated is accepted (spec FR-008, FR-023; research D5).
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/search/arabic_fold.dart';
import 'package:mushaf/search/ayah_index.dart';

import '../support/search_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AyahIndex index;
  setUpAll(() async {
    index = await realIndex();
  });

  /// One whole query the way the service answers it: fold, pattern, one scan per chunk. Returns (ayat found, milliseconds).
  (int, int) run(String typed) {
    final watch = Stopwatch()..start();
    final pattern = ArabicFold.pattern(ArabicFold.query(typed));
    var total = 0;
    for (var c = 0; c < index.chunks.length; c++) {
      total += index.scanChunk(c, pattern).length;
    }
    return (total, watch.elapsedMilliseconds);
  }

  test('SC-004: 20 queries, each under 1 s; «ال» returns 5,182 ayat', () {
    final longest = index
        .storedWords(index.indexOf(const AyahRef(2, 282)))
        .join(' ');
    final queries = <String>[
      // ten one-word
      'الرحمن',
      'الله',
      'موسى',
      'الصلاة',
      'رحمة',
      'ابراهيم',
      'السماوات',
      'مؤمن',
      'يستهزئون',
      'كتاب',
      // five phrases
      'بسم الله الرحمن الرحيم',
      'يا ايها الذين امنوا',
      'قل هو الله احد',
      'الله لا اله الا هو الحي القيوم',
      'ذلك الكتاب لا ريب فيه',
      // «ال», the longest ayah pasted
      'ال', longest,
      // three that match nothing
      'ذو القرنين', 'ظظظظظ', 'قل هو الله احد ثلاثة',
    ];
    expect(queries, hasLength(20));
    run('الله'); // the first scan of a run warms the engine; SC-004 is about the typical query
    final times = <int>[];
    for (final typed in queries) {
      final (total, ms) = run(typed);
      times.add(ms);
      expect(ms, lessThan(1000), reason: '$typed took $ms ms');
      if (typed == 'ال') {
        expect(total, 5182);
        // ignore: avoid_print
        print('«ال»: $total ayat in $ms ms');
      }
      if (typed == longest) expect(total, 1);
      if (typed == 'قل هو الله احد') expect(total, 1);
    }
    times.sort();
    // ignore: avoid_print
    print('20 queries: median ${times[10]} ms, slowest ${times.last} ms');
    final nothing = [for (final t in queries.sublist(17)) run(t).$1];
    expect(nothing, [0, 0, 0]);
  });

  test('the one-row cap needs no scan limit: «ال» is scanned whole and counts 5,182', () {
    expect(run('ال').$1, 5182);
  });

  test('a 1,500-character query of 2:282 repeated is accepted and answered in under 1 s', () {
    final longest = index
        .storedWords(index.indexOf(const AyahRef(2, 282)))
        .join(' ');
    var typed = longest;
    while (typed.length < 1500) {
      typed = '$typed $longest';
    }
    expect(typed.length, greaterThanOrEqualTo(1500));
    final (total, ms) = run(typed);
    expect(ms, lessThan(1000), reason: '$ms ms');
    expect(total, 0); // two copies of one ayah are not in any ayah
    // exactly 1,500 characters typed (cut inside the second copy): still accepted, still nothing, no exception
    final cut = typed.substring(0, 1500);
    expect(cut.length, 1500);
    expect(() => ArabicFold.pattern(ArabicFold.query(cut)), returnsNormally);
    expect(run(cut).$1, 0);
  });
}
