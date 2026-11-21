import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/share_text.dart';

import '../support/test_meta.dart';

void main() {
  final builder = ShareTextBuilder(testMeta());

  group('ayah (contracts/share-formats.md)', () {
    test(
      'is the spec example: two lines, the words in ﴿ ﴾, then the reference',
      () {
        final text = builder.ayah(const AyahRef(1, 2), [
          'ٱلْحَمْدُ',
          'لِلَّهِ',
          'رَبِّ',
          'ٱلْعَٰلَمِينَ',
        ]);
        expect(
          text,
          '﴿ ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ ﴾\n[سورة الفاتحة: 2]',
        );
      },
    );

    test('has exactly two lines, one space inside each bracket pair, no trailing newline', () {
      final text = builder.ayah(const AyahRef(2, 255), ['ٱللَّهُ', 'لَآ']);
      expect(text.split('\n'), hasLength(2));
      expect(text.startsWith('﴿ '), isTrue);
      expect(text.split('\n').first.endsWith(' ﴾'), isTrue);
      expect(text.endsWith('\n'), isFalse);
      expect(text.split('\n').last, '[سورة البقرة: 255]');
    });

    test('writes the numbers with the digits 0-9', () {
      final text = builder.ayah(const AyahRef(2, 255), ['x']);
      expect(RegExp(r'[٠-٩۰-۹]').hasMatch(text), isFalse);
      expect(text, contains('255'));
    });

    test('keeps every word unchanged, signs inside words included', () {
      const words = ['۞ وَإِذۡ', 'قَالَ', 'ٱلنَّجۡمِ۩'];
      final text = builder.ayah(const AyahRef(2, 1), words);
      expect(text.split('\n').first, '﴿ ${words.join(' ')} ﴾');
    });

    test('adds no app name, link or other text', () {
      final text = builder.ayah(const AyahRef(1, 1), ['a', 'b']);
      expect(text, '﴿ a b ﴾\n[سورة الفاتحة: 1]');
      expect(text, isNot(contains('http')));
    });

    test('refuses an ayah without words', () {
      expect(
        () => builder.ayah(const AyahRef(1, 1), const []),
        throwsArgumentError,
      );
    });
  });

  group('tafsir and translation', () {
    test(
      'tafsir: the text, a blank line, the reference, then the source name',
      () {
        expect(
          builder.tafsir(const AyahRef(2, 255), 'شرح الآية'),
          'شرح الآية\n\n[سورة البقرة: 255]\nتفسير السعدي',
        );
      },
    );

    test('translation: the English text, a blank line, the reference, then the source name', () {
      expect(
        builder.translation(
          const AyahRef(1, 2),
          '[All] praise is [due] to Allah',
        ),
        '[All] praise is [due] to Allah\n\n[سورة الفاتحة: 2]\nSaheeh International',
      );
    });

    test('do not contain the Quran words or the ﴿ ﴾ marks', () {
      expect(builder.tafsir(const AyahRef(1, 1), 'x'), isNot(contains('﴿')));
      expect(
        builder.translation(const AyahRef(1, 1), 'x'),
        isNot(contains('﴿')),
      );
    });

    test('keep a multi-line tafsir exactly as it is', () {
      const text = 'سطر أول\nسطر ثان';
      expect(
        builder.tafsir(const AyahRef(1, 1), text),
        startsWith('$text\n\n[سورة الفاتحة: 1]'),
      );
    });
  });
}
