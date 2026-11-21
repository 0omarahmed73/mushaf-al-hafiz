// Feature 011, T035: the careless spellings of User Story 3 typed into the field of the search screen, over the real index (spec
// FR-006, FR-007, SC-002, User Story 3 scenarios 1-5). A sweep: a failure here is a defect of the folding, the scan or the screen.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/search/arabic_fold.dart';
import 'package:mushaf/search/ayah_index.dart';
import 'package:mushaf/search/search_strings.dart';

import '../support/search_harness.dart';

const _ayatHeading = ValueKey('search-heading-ayat');

Finder get _scrollable => find.descendant(
  of: find.byKey(const ValueKey('search-results')),
  matching: find.byType(Scrollable),
);

List<String> _built(WidgetTester t, String prefix) => [
  for (final w in t.widgetList(
    find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith(prefix),
    ),
  ))
    (w.key! as ValueKey<String>).value.substring(prefix.length),
];

/// Every row of the list whose key starts with [prefix], met while scrolling it from its top to its end, in order.
Future<List<String>> _all(WidgetTester t, String prefix) async {
  final seen = <String>[];
  final position = t.state<ScrollableState>(_scrollable).position;
  position.jumpTo(0);
  await t.pump();
  while (true) {
    for (final key in _built(t, prefix)) {
      if (!seen.contains(key)) seen.add(key);
    }
    if (position.pixels >= position.maxScrollExtent) break;
    position.jumpTo(
      (position.pixels + 400).clamp(0, position.maxScrollExtent).toDouble(),
    );
    await t.pump();
  }
  return seen;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AyahIndex index;
  setUpAll(() async {
    await realMeta();
    index = await realIndex();
  });

  /// Every ayah that [typed] finds, in Mushaf order, by a scan of the whole text (not through the screen).
  List<String> scan(String typed) {
    final pattern = ArabicFold.pattern(ArabicFold.query(typed));
    return [
      for (var chunk = 0; chunk < index.chunks.length; chunk++)
        for (final i in index.scanChunk(chunk, pattern)) index.refOf(i).key,
    ];
  }

  /// Types [typed] and checks the ayah group against the scan: the heading has the true total and the rows are the first 100.
  Future<List<String>> typeAndCheck(WidgetTester t, String typed) async {
    await typeQuery(t, typed);
    final all = scan(typed);
    final rows = await _all(t, 'ayah-row-');
    expect(rows, all.take(100).toList(), reason: typed);
    if (all.isNotEmpty) {
      await t.scrollUntilVisible(
        find.byKey(_ayatHeading),
        -400,
        scrollable: _scrollable,
      );
      expect(
        find.descendant(
          of: find.byKey(_ayatHeading),
          matching: find.text(kAyahHeading(all.length)),
        ),
        findsOneWidget,
        reason: typed,
      );
    }
    return rows;
  }

  // The 15 rows of the table of User Story 3 that name an ayah: the typed forms and the ayat that must be found.
  final table = <(List<String>, List<String>)>[
    (['احمد', 'أحمد'], ['61:6']),
    (['ابراهيم', 'إبراهيم', 'ابراهيـم'], ['14:35', '2:124']),
    (['الرحمن', 'الرحمٰن'], ['1:1', '55:1']),
    (['مؤمن', 'مومن'], ['4:92']),
    (['رحمة', 'رحمه'], ['2:157']),
    (['موسى', 'موسي'], ['2:51']),
    (['الكتاب'], ['2:2']),
    (['الصلاة', 'الصلاه'], ['2:3']),
    (['الزكاة'], ['2:43']),
    (['السماوات', 'السموات'], ['2:33']),
    (['شيئا', 'شيأ'], ['2:48']),
    (['يستهزئون', 'يستهزؤون', 'يستهزءون'], ['6:5']),
    (['النبيين'], ['2:61']),
    (['اسماعيل', 'إسماعيل'], ['2:125']),
    (
      ['يا ايها الذين امنوا', 'يأيها الذين آمنوا', 'ياأيها الذين امنوا'],
      ['2:104', '2:153'],
    ),
  ];

  for (final (forms, must) in table) {
    testWidgets(
      '${forms.join(' · ')} typed in the field lists ${must.join(', ')}',
      (t) async {
        await pumpSearch(t);
        for (final typed in forms) {
          final rows = await typeAndCheck(t, typed);
          final all = scan(typed);
          expect(all, containsAll(must), reason: typed);
          // 100 rows are listed: an ayah named is a row when it is among the first 100 in Mushaf order
          for (final key in must) {
            if (all.indexOf(key) < 100) {
              expect(rows, contains(key), reason: '$typed lists $key');
            } else {
              expect(find.text(kSearchTooMany), findsOneWidget, reason: typed);
            }
          }
        }
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets('«احمد» does not list 1:2', (t) async {
    await pumpSearch(t);
    final rows = await typeAndCheck(t, 'احمد');
    expect(rows, isNot(contains('1:2')));
  });

  final exactly = <(String, List<String>)>[
    ('بسم الله الرحمن الرحيم', ['1:1', '27:30']),
    ('ذلك الكتاب لا ريب فيه', ['2:2']),
    ('قل هو الله احد', ['112:1']),
    ('الله لا اله الا هو الحي القيوم', ['2:255', '3:2']),
  ];

  for (final (typed, ayat) in exactly) {
    testWidgets(
      '«$typed» lists exactly ${ayat.join(', ')} under «الآيات · ${ayat.length}»',
      (t) async {
        await pumpSearch(t);
        final rows = await typeAndCheck(t, typed);
        expect(rows, ayat);
        expect(find.text('الآيات · ${ayat.length}'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'the same query with and without tashkeel, tatweel or hamzas gives the same surah rows and ayah rows',
    (t) async {
      await pumpSearch(t);
      const pairs = [
        ('مريم', 'مَرْيَم'),
        ('يوسف', 'يُوسُفُ'),
        ('ابراهيم', 'إِبْرَاهِيم'),
        ('ابراهيم', 'ابراهيـــم'),
        ('الكهف', 'الكـهف'),
        ('رحمة', 'رَحْمَة'),
        ('الانسان', 'الإنسان'),
        ('قل هو الله احد', 'قُلْ هُوَ اللَّهُ أَحَدٌ'),
      ];
      for (final (plain, other) in pairs) {
        await typeQuery(t, plain);
        final surahs = await _all(t, 'surah-row-');
        final ayat = await _all(t, 'ayah-row-');
        await typeQuery(t, other);
        expect(await _all(t, 'surah-row-'), surahs, reason: '$plain / $other');
        expect(await _all(t, 'ayah-row-'), ayat, reason: '$plain / $other');
        expect(surahs.length + ayat.length, greaterThan(0), reason: plain);
      }
    },
  );

  testWidgets('«ٱلرَّحۡمَٰنِ» typed exactly as printed lists 1:1', (t) async {
    await pumpSearch(t);
    final word = index.storedWords(index.indexOf(const AyahRef(1, 1)))[2];
    // the stored word itself (the file's own order of marks)
    final rows = await typeAndCheck(t, word);
    expect(rows, contains('1:1'));
    expect(rows, contains('55:1'));
  });

  testWidgets(
    'an ayah pasted with the ornate brackets and the end sign lists its ayah',
    (t) async {
      await pumpSearch(t);
      for (final (ref, number) in [
        (const AyahRef(112, 1), '١'),
        (const AyahRef(2, 255), '٢٥٥'),
        (const AyahRef(18, 10), '١٠'),
      ]) {
        final words = index.storedWords(index.indexOf(ref)).join(' ');
        final rows = await typeAndCheck(t, '﴿ $words ۝$number ﴾');
        expect(rows, contains(ref.key), reason: ref.key);
        expect(rows, typeAndCheckSame(scan(words)), reason: ref.key);
      }
    },
  );
}

/// The rows of a pasted ayah are the rows of its words alone (the brackets, the end sign and its number change nothing).
Matcher typeAndCheckSame(List<String> all) => equals(all.take(100).toList());
