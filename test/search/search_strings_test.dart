// Every Arabic string of the search feature, pinned (feature 011, T002; spec FR-028; research D8; Constitution VI).
// The owner confirmed every one on 2026-11-21 (T070), they live in the one file lib/search/search_strings.dart, each with a
// doc comment that says it is confirmed and where it is shown, and they are written with Western digits.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/search/search_strings.dart';

/// Arabic-Indic (U+0660-0669) and extended Arabic-Indic (U+06F0-06F9) digits.
final RegExp _easternDigit = RegExp('[٠-٩۰-۹]');
final RegExp _latinLetter = RegExp('[A-Za-z]');

/// Every string value the file can produce, with the arguments of the tests.
Map<String, String> _all() => {
  'kSearchLabel': kSearchLabel,
  'kSearchFieldLabel': kSearchFieldLabel,
  'kSearchClear': kSearchClear,
  'kSurahHeading(0)': kSurahHeading(0),
  'kSurahHeading(114)': kSurahHeading(114),
  'kAyahHeading(0)': kAyahHeading(0),
  'kAyahHeading(5182)': kAyahHeading(5182),
  'kSurahHeadingSemantics(114)': kSurahHeadingSemantics(114),
  'kAyahHeadingSemantics(5182)': kAyahHeadingSemantics(5182),
  'kSearchHint': kSearchHint,
  'kSearchNeedTwo': kSearchNeedTwo,
  'kSearchPreparing': kSearchPreparing,
  'kSearchNone': kSearchNone,
  'kSearchNoneAdvice': kSearchNoneAdvice,
  'kSearchFailed': kSearchFailed,
  'kSearchRetry': kSearchRetry,
  'kSearchTooMany': kSearchTooMany,
  'kPageShort(293)': kPageShort(293),
  'kAyahRowTitle': kAyahRowTitle('الإخلاص', 1),
  'kSurahRowSemantics': kSurahRowSemantics('الكهف', 293),
  'kAyahRowSemantics': kAyahRowSemantics('البقرة', 255, 42),
  'kSnippetCut': kSnippetCut,
};

void main() {
  group('the constants', () {
    test('the icon, the title, the field and the clear button', () {
      expect(kSearchLabel, 'بحث');
      expect(kSearchFieldLabel, 'ابحث عن سورة أو آية');
      expect(kSearchClear, 'مسح');
    });

    test('the lines the screen shows instead of rows', () {
      expect(kSearchHint, 'اكتب اسم سورة، أو كلمات من آية');
      expect(kSearchNeedTwo, 'اكتب حرفين على الأقل للبحث في الآيات');
      expect(kSearchPreparing, 'جارٍ تجهيز البحث في الآيات');
      expect(kSearchNone, 'لا توجد نتائج');
      expect(kSearchNoneAdvice, 'جرّب كلمة واحدة أو كلمات أقل');
      expect(kSearchFailed, 'تعذّر تجهيز البحث في الآيات');
      expect(kSearchRetry, 'إعادة المحاولة');
      expect(kSearchTooMany, 'النتائج كثيرة، اكتب كلمات أكثر لتضييق البحث');
    });

    test(
      'the mark for the words left out of a snippet is one ellipsis character',
      () {
        expect(kSnippetCut, '…');
        expect(kSnippetCut.runes.single, 0x2026);
      },
    );
  });

  group('the functions', () {
    test('the headings carry the count with Western digits', () {
      expect(kSurahHeading(114), 'السور · 114');
      expect(kAyahHeading(5182), 'الآيات · 5182');
      expect(kSurahHeading(0), 'السور · 0');
      expect(kAyahHeading(100), 'الآيات · 100');
      // A middle dot (U+00B7) between the words and the number, and no thousands separator.
      expect(kAyahHeading(5182).contains('·'), isTrue);
      expect(kAyahHeading(5182).contains(','), isFalse);
      expect(kAyahHeading(5182).contains('٬'), isFalse);
    });

    test('the two headings for a screen reader', () {
      expect(kSurahHeadingSemantics(114), 'السور، عدد النتائج 114');
      expect(kAyahHeadingSemantics(5182), 'الآيات، عدد النتائج 5182');
      expect(kSurahHeadingSemantics(1), 'السور، عدد النتائج 1');
    });

    test('the page of a row is «ص N»', () {
      expect(kPageShort(293), 'ص 293');
      expect(kPageShort(1), 'ص 1');
      expect(kPageShort(604), 'ص 604');
    });

    test('the title of an ayah row and the labels of the two rows for a screen reader', () {
      expect(kAyahRowTitle('الإخلاص', 1), 'الإخلاص · آية 1');
      expect(kAyahRowTitle('البقرة', 255), 'البقرة · آية 255');
      expect(kSurahRowSemantics('الكهف', 293), 'سورة الكهف، صفحة 293');
      expect(
        kAyahRowSemantics('البقرة', 255, 42),
        'سورة البقرة، آية 255، صفحة 42',
      );
    });

    test(
      'the name of the surah goes in as the caller gives it, never altered',
      () {
        expect(kAyahRowTitle('سبإ', 3), 'سبإ · آية 3');
        expect(kSurahRowSemantics('الإنفطار', 587), 'سورة الإنفطار، صفحة 587');
      },
    );
  });

  group('every string', () {
    test('has no Latin letter and no Arabic-Indic digit, and is not empty', () {
      for (final e in _all().entries) {
        expect(e.value, isNotEmpty, reason: e.key);
        expect(
          e.value.contains(_latinLetter),
          isFalse,
          reason: '${e.key}: ${e.value}',
        );
        expect(
          e.value.contains(_easternDigit),
          isFalse,
          reason: '${e.key}: ${e.value}',
        );
      }
    });

    test('has Arabic text (the numbers are the only Western digits)', () {
      for (final e in _all().entries) {
        expect(
          e.value.contains(RegExp('[؀-ۿ…]')),
          isTrue,
          reason: '${e.key}: ${e.value}',
        );
      }
    });
  });

  group('the file', () {
    final source = File('lib/search/search_strings.dart').readAsStringSync();
    final lines = source.split('\n');

    /// The top-level declarations (`const String kX = ...` and `String kX(...) => ...`).
    final declaration = RegExp(r'^(?:const String|String) (k\w+)\b');
    final declared = <String, int>{
      for (var i = 0; i < lines.length; i++)
        if (declaration.firstMatch(lines[i]) case final m?) m.group(1)!: i,
    };

    /// The `///` lines that sit directly above line [index].
    String docAbove(int index) {
      final doc = <String>[];
      for (
        var i = index - 1;
        i >= 0 && lines[i].trimLeft().startsWith('///');
        i--
      ) {
        doc.insert(0, lines[i].trimLeft().substring(3).trim());
      }
      return doc.join(' ');
    }

    test('declares exactly the strings of the contract (no other Arabic text of the feature)', () {
      expect(declared.keys.toSet(), {
        'kSearchLabel',
        'kSearchFieldLabel',
        'kSearchClear',
        'kSurahHeading',
        'kAyahHeading',
        'kSurahHeadingSemantics',
        'kAyahHeadingSemantics',
        'kSearchHint',
        'kSearchNeedTwo',
        'kSearchPreparing',
        'kSearchNone',
        'kSearchNoneAdvice',
        'kSearchFailed',
        'kSearchRetry',
        'kSearchTooMany',
        'kPageShort',
        'kAyahRowTitle',
        'kSurahRowSemantics',
        'kAyahRowSemantics',
        'kSnippetCut',
      });
      // Nothing else is declared at the top level (no helper that could hide a string).
      final topLevel = lines.where(
        (l) =>
            RegExp(r'^[A-Za-z@]').hasMatch(l) &&
            !l.startsWith('import ') &&
            !l.startsWith('library'),
      );
      expect(topLevel.length, declared.length, reason: topLevel.join('\n'));
    });

    test('says in its header that the owner confirmed every string (T070)', () {
      final firstDeclaration = declared.values.reduce((a, b) => a < b ? a : b);
      // The header: the comment block before the first declaration, without the doc comment of that declaration.
      var end = firstDeclaration;
      while (end > 0 && lines[end - 1].trimLeft().startsWith('///')) {
        end--;
      }
      final header = lines.sublist(0, end).join('\n');
      expect(header.toLowerCase(), contains('confirmed'));
      expect(header.toLowerCase(), isNot(contains('proposal')));
      expect(header, contains('T070'));
      expect(header.toLowerCase(), contains('owner'));
    });

    test('has a /// doc comment on every declaration that says the owner confirmed it and where it is shown', () {
      for (final e in declared.entries) {
        final doc = docAbove(e.value);
        expect(doc, isNotEmpty, reason: '${e.key} has no /// doc comment');
        expect(
          doc.toLowerCase(),
          contains('confirmed by the owner'),
          reason: '${e.key}: $doc',
        );
        expect(
          doc.toLowerCase(),
          contains('shown'),
          reason: '${e.key} does not say where it is shown: $doc',
        );
      }
    });

    test('is plain Dart: no import, and no colour, widget or other code', () {
      expect(source, isNot(contains('import ')));
      expect(source, isNot(contains('Color(')));
    });
  });
}
