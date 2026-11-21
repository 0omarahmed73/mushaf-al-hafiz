// Feature 011, T005: the ayah search over the real index, scanning every chunk with AyahIndex.scanChunk (spec FR-005,
// FR-006, FR-007, SC-002; research D2, D3). Every row of the table of User Story 3 and the matched-word flags.
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/search/arabic_fold.dart';
import 'package:mushaf/search/ayah_index.dart';

import '../support/search_harness.dart';

/// The ayat of the whole text that contain [typed], as the service scans them: chunk by chunk, ascending.
List<int> scanAll(AyahIndex index, String typed) {
  final pattern = ArabicFold.pattern(ArabicFold.query(typed));
  return [
    for (var c = 0; c < index.chunks.length; c++)
      ...index.scanChunk(c, pattern),
  ];
}

Set<String> keysOf(AyahIndex index, List<int> hits) => {
  for (final i in hits) index.refOf(i).key,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AyahIndex index;
  setUpAll(() async {
    index = await realIndex();
  });

  Set<String> find(String typed) => keysOf(index, scanAll(index, typed));

  /// The rows of the table of User Story 3: the typed forms, the ayat that must be found, and whether the result must be
  /// exactly those ayat. 15 rows with 30 forms, then the four «exactly» rows: 34 typed forms.
  final table = <(List<String>, List<String>, bool)>[
    (['احمد', 'أحمد'], ['61:6'], false),
    (['ابراهيم', 'إبراهيم', 'ابراهيـم'], ['14:35', '2:124'], false),
    (['الرحمن', 'الرحمٰن'], ['1:1', '55:1'], false),
    (['مؤمن', 'مومن'], ['4:92'], false),
    (['رحمة', 'رحمه'], ['2:157'], false),
    (['موسى', 'موسي'], ['2:51'], false),
    (['الكتاب'], ['2:2'], false),
    (['الصلاة', 'الصلاه'], ['2:3'], false),
    (['الزكاة'], ['2:43'], false),
    (['السماوات', 'السموات'], ['2:33'], false),
    (['شيئا', 'شيأ'], ['2:48'], false),
    (['يستهزئون', 'يستهزؤون', 'يستهزءون'], ['6:5'], false),
    (['النبيين'], ['2:61'], false),
    (['اسماعيل', 'إسماعيل'], ['2:125'], false),
    (
      ['يا ايها الذين امنوا', 'يأيها الذين آمنوا', 'ياأيها الذين امنوا'],
      ['2:104', '2:153'],
      false,
    ),
    (['بسم الله الرحمن الرحيم'], ['1:1', '27:30'], true),
    (['ذلك الكتاب لا ريب فيه'], ['2:2'], true),
    (['قل هو الله احد'], ['112:1'], true),
    (['الله لا اله الا هو الحي القيوم'], ['2:255', '3:2'], true),
  ];

  test('the table has 34 typed forms', () {
    expect(table.fold<int>(0, (n, row) => n + row.$1.length), 34);
  });

  for (final (forms, must, exactly) in table) {
    for (final typed in forms) {
      test('${exactly ? 'exactly ' : ''}$typed finds ${must.join(', ')}', () {
        final found = find(typed);
        expect(
          found.containsAll(must),
          isTrue,
          reason:
              '$typed found ${found.length} ayat, missing ${must.where((m) => !found.contains(m))}',
        );
        if (exactly) expect(found, must.toSet());
        if (typed == 'احمد' || typed == 'أحمد') {
          expect(found.contains('1:2'), isFalse, reason: 'الحمد is not أحمد');
        }
      });
    }
  }

  test('ذو القرنين finds nothing and ذي القرنين finds 18:83', () {
    expect(find('ذو القرنين'), isEmpty);
    expect(find('ذي القرنين'), {'18:83'});
  });

  test('the longest ayah, 2:282, pasted exactly as it is printed finds exactly 2:282', () {
    final i = index.indexOf(const AyahRef(2, 282));
    final pasted = index.storedWords(i).join(' ');
    expect(pasted.length, greaterThan(1000));
    expect(find(pasted), {'2:282'});
    expect(find('﴿ $pasted ﴾'), {'2:282'});
  });

  test('every scan is ascending, once per ayah, inside its chunk, and the sum over the chunks is the total', () {
    for (final typed in ['ال', 'الله', 'رحم', 'يا ايها', 'ذلك']) {
      final pattern = ArabicFold.pattern(ArabicFold.query(typed));
      var total = 0;
      for (var c = 0; c < index.chunks.length; c++) {
        final hits = index.scanChunk(c, pattern);
        for (var h = 0; h < hits.length; h++) {
          expect(
            hits[h],
            inInclusiveRange(c * 800, c * 800 + 799),
            reason: '$typed chunk $c',
          );
          if (h > 0) {
            expect(
              hits[h],
              greaterThan(hits[h - 1]),
              reason: '$typed chunk $c',
            );
          }
        }
        total += hits.length;
      }
      expect(total, scanAll(index, typed).length, reason: typed);
      // the brute force over the folded ayat agrees with the chunk scan
      final brute = [
        for (var i = 0; i < index.ayahCount; i++)
          if (pattern.hasMatch(index.foldedAyah(i))) i,
      ];
      expect(scanAll(index, typed), brute, reason: typed);
    }
  });

  test('a word that occurs several times in one ayah is one hit (73:20 has «الله» seven times)', () {
    final hits = scanAll(index, 'الله');
    final i = index.indexOf(const AyahRef(73, 20));
    expect(hits.where((h) => h == i), hasLength(1));
    final pattern = ArabicFold.pattern(ArabicFold.query('الله'));
    expect(
      pattern.allMatches(index.foldedAyah(i)).length,
      greaterThanOrEqualTo(3),
    );
    expect(hits.toSet(), hasLength(hits.length));
  });

  test('two spellings of the same query give the same ayat (User Story 3 scenario 5)', () {
    final groups = [
      [
        'يا ايها الذين امنوا',
        'يأيها الذين آمنوا',
        'ياأيها الذين امنوا',
        'يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ',
      ],
      ['ابراهيم', 'إبراهيم', 'ابراهيـم', 'إِبۡرَٰهِيمَ'],
      ['الرحمن', 'الرحمٰن', 'ٱلرَّحۡمَٰنِ', 'الــرحمن'],
      ['مؤمن', 'مومن', 'مُؤۡمِنٖ'],
      ['رحمة', 'رحمه', 'رَحۡمَةٞ'],
    ];
    for (final forms in groups) {
      final first = scanAll(index, forms.first);
      expect(first, isNotEmpty, reason: forms.first);
      for (final typed in forms.skip(1)) {
        expect(
          scanAll(index, typed),
          first,
          reason: '$typed vs ${forms.first}',
        );
      }
    }
  });

  test('the refrain of Ar-Rahman finds 31 ayat, each its own hit with its own number, none merged', () {
    final hits = scanAll(index, 'فباي الاء ربكما تكذبان');
    expect(hits, hasLength(31));
    final refs = [for (final i in hits) index.refOf(i)];
    expect(refs.every((r) => r.surah == 55), isTrue);
    expect(refs.map((r) => r.ayah).toSet(), hasLength(31));
    expect(refs.first, const AyahRef(55, 13));
    expect(refs.last, const AyahRef(55, 77));
    expect(
      find('فَبِأَيِّ ءَالَآءِ رَبِّكُمَا تُكَذِّبَانِ'),
      keysOf(index, hits),
    );
  });

  test('a match never crosses an ayah: the end of 1:1 and the start of 1:2 are not one phrase', () {
    expect(find('الرحيم الحمد'), isEmpty);
    expect(find('الرحيمالحمد'), isEmpty);
  });

  group('matchedWords', () {
    List<bool> flags(AyahRef ref, String typed) => index.matchedWords(
      index.indexOf(ref),
      ArabicFold.pattern(ArabicFold.query(typed)),
    );

    test('all four words of 112:1 for «قل هو الله احد»', () {
      expect(flags(const AyahRef(112, 1), 'قل هو الله احد'), [
        true,
        true,
        true,
        true,
      ]);
    });

    test('«رحم» marks «ٱلرَّحۡمَٰنِ» and not «ٱلرَّحِيمِ» (the letters of رحيم are ر ح ي م); the phrase marks both', () {
      final words = index.storedWords(index.indexOf(const AyahRef(1, 3)));
      expect(words.map(ArabicFold.word), ['الرحم\u0670ن', 'الرحيم']);
      expect(flags(const AyahRef(1, 3), 'رحم'), [true, false]);
      expect(flags(const AyahRef(1, 1), 'رحم'), [false, false, true, false]);
      expect(flags(const AyahRef(1, 3), 'الرحمن الرحيم'), [true, true]);
      expect(flags(const AyahRef(1, 3), 'رحيم'), [false, true]);
    });

    test(
      'the one word «يَٰٓأَيُّهَا» of 2:104 for «يا ايها», nothing else',
      () {
        final words = index.storedWords(index.indexOf(const AyahRef(2, 104)));
        expect(ArabicFold.word(words.first), 'ي\u0670ايها');
        final f = flags(const AyahRef(2, 104), 'يا ايها');
        expect(f, hasLength(words.length));
        expect(f.first, isTrue);
        expect(f.skip(1).any((b) => b), isFalse);
      },
    );

    test('a phrase marks the words it spans and no others', () {
      expect(flags(const AyahRef(1, 1), 'الله الرحمن'), [
        false,
        true,
        true,
        false,
      ]);
      expect(flags(const AyahRef(1, 1), 'بسم'), [true, false, false, false]);
    });

    test('an ayah the pattern does not match has no flag', () {
      expect(flags(const AyahRef(1, 2), 'قل هو'), [false, false, false, false]);
    });

    test('a word that occurs three times in an ayah is marked each time', () {
      final f = flags(const AyahRef(73, 20), 'الله');
      expect(f.where((b) => b).length, greaterThanOrEqualTo(3));
    });

    test('flags agree with the scan: a hit has a flag, a non-hit has none, for the whole text', () {
      for (final typed in ['ال', 'رحم', 'يا ايها', 'الله', 'مؤمن']) {
        final pattern = ArabicFold.pattern(ArabicFold.query(typed));
        final hits = scanAll(index, typed).toSet();
        for (var i = 0; i < index.ayahCount; i++) {
          final f = index.matchedWords(i, pattern);
          expect(f, hasLength(index.storedWords(i).length));
          expect(
            f.any((b) => b),
            hits.contains(i),
            reason: '$typed ${index.refOf(i).key}',
          );
        }
      }
    });
  });
}
