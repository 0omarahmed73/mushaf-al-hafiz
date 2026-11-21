// Feature 011, T003: the folding of the stored words, the typed query and the surah names (research D2). Small literals
// only; the real-data sweeps are T004-T006. The soft small alef and the soft seatless hamza are written with their
// escapes, every other letter is the Arabic character itself.
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/search/arabic_fold.dart';

const String dagger = 'ٰ';
const String hamza = 'ء';

String u(int codeUnit) => String.fromCharCode(codeUnit);

void main() {
  group('ArabicFold.word: the stored side (research D2 table)', () {
    test('the soft characters are the dagger alef and the seatless hamza', () {
      expect(ArabicFold.dagger, dagger);
      expect(ArabicFold.hamza, hamza);
      expect(ArabicFold.seatWaw, '\u0001');
      expect(ArabicFold.seatYeh, '\u0002');
    });

    test('the four alef forms and the plain alef are one letter', () {
      for (final c in ['ا', 'أ', 'إ', 'آ', 'ٱ']) {
        expect(ArabicFold.word('ب$cب'), 'باب', reason: c);
      }
    });

    test('a hamza on a waw or yeh seat is that letter', () {
      expect(ArabicFold.word('ؤ'), 'و');
      expect(ArabicFold.word('ئ'), 'ي');
    });

    test('alef maqsura and the Persian yeh are yeh; teh marbuta is heh; the Persian kaf is kaf', () {
      expect(ArabicFold.word('ى'), 'ي');
      expect(ArabicFold.word('ی'), 'ي');
      expect(ArabicFold.word('ة'), 'ه');
      expect(ArabicFold.word('ک'), 'ك');
    });

    test(
      'the seatless hamza, its two signs (U+0654, U+0655) are one soft hamza',
      () {
        expect(ArabicFold.word('ء'), hamza);
        expect(ArabicFold.word('ب${u(0x654)}'), 'ب$hamza');
        expect(ArabicFold.word('ب${u(0x655)}'), 'ب$hamza');
        expect(ArabicFold.word('شَيۡـٔٗا'), 'شي$hamzaا');
      },
    );

    test('the dagger alef is kept as the soft small alef', () {
      expect(ArabicFold.word('ب${u(0x670)}'), 'ب$dagger');
    });

    test('the small high yeh (U+06E7) is a yeh and the small high noon (U+06E8) is a noon', () {
      expect(ArabicFold.word('ب${u(0x6E7)}'), 'بي');
      expect(ArabicFold.word('ب${u(0x6E8)}'), 'بن');
    });

    test('every other letter is itself', () {
      const letters = 'ابتثجحخدذرزسشصضطظعغفقكلمنهوي';
      for (final c in letters.split('')) {
        expect(ArabicFold.word(c), c, reason: c);
      }
    });

    test('tashkeel U+064B-0653 and U+0656-065F vanish', () {
      for (var cu = 0x64B; cu <= 0x65F; cu++) {
        if (cu == 0x654 || cu == 0x655) continue;
        expect(
          ArabicFold.word('ب${u(cu)}ب'),
          'بب',
          reason: cu.toRadixString(16),
        );
      }
    });

    test('the small letters of the pronouns (U+06E5, U+06E6) vanish', () {
      expect(ArabicFold.word('ب${u(0x6E5)}'), 'ب');
      expect(ArabicFold.word('ب${u(0x6E6)}'), 'ب');
    });

    test('the Quranic marks U+06D6-06E4 and U+06E9-06ED vanish', () {
      for (var cu = 0x6D6; cu <= 0x6E4; cu++) {
        expect(
          ArabicFold.word('ب${u(cu)}ب'),
          'بب',
          reason: cu.toRadixString(16),
        );
      }
      for (var cu = 0x6E9; cu <= 0x6ED; cu++) {
        expect(
          ArabicFold.word('ب${u(cu)}ب'),
          'بب',
          reason: cu.toRadixString(16),
        );
      }
    });

    test('the sign signs, tatweel and the spaces inside a word vanish', () {
      expect(ArabicFold.word('۞'), '');
      expect(ArabicFold.word('۩'), '');
      expect(ArabicFold.word('بـب'), 'بب');
      expect(ArabicFold.word('ب ب'), 'بب');
    });

    test('digits, Latin letters and code units above U+06FF vanish from a stored word', () {
      expect(ArabicFold.word('ب1ب'), 'بب');
      expect(ArabicFold.word('بaب'), 'بب');
      expect(ArabicFold.word('ب${u(0x7FF)}ب'), 'بب');
      expect(ArabicFold.word('ب${u(0xFDFA)}ب'), 'بب');
    });

    test('a stored word that is only marks folds to the empty string', () {
      expect(ArabicFold.word('${u(0x64E)}${u(0x6E1)}'), '');
      expect(ArabicFold.word(''), '');
    });

    test('the ten word examples of the contract', () {
      expect(ArabicFold.word('ٱلرَّحۡمَٰنِ'), 'الرحم$daggerن');
      expect(ArabicFold.word('مُؤۡمِنٖ'), 'مومن');
      expect(ArabicFold.word('يَسۡتَهۡزِءُونَ'), 'يستهز$hamzaون');
      expect(ArabicFold.word('شَيۡـٔٗا'), 'شي$hamzaا');
      expect(ArabicFold.word('إِبۡرَٰهِـۧمَ'), 'ابر$daggerهيم');
      expect(ArabicFold.word('ٱلصَّلَوٰةَ'), 'الصلو$daggerه');
      expect(ArabicFold.word('ءَامَنُواْ'), '$hamzaامنوا');
      expect(ArabicFold.word('يَٰٓأَيُّهَا'), 'ي$daggerايها');
      expect(ArabicFold.word('۞ إِنَّ'), 'ان');
      expect(ArabicFold.word('إِلۡ يَاسِينَ'), 'الياسين');
    });
  });

  group('ArabicFold.ayah', () {
    test('joins the folds of the words by one space, word k stays word k', () {
      final words = ['قُلۡ', 'هُوَ', 'ٱللَّهُ', 'أَحَدٌ'];
      final folded = ArabicFold.ayah(words);
      expect(folded, 'قل هو الله احد');
      expect(folded.split(' ').length, words.length);
      for (var k = 0; k < words.length; k++) {
        expect(folded.split(' ')[k], ArabicFold.word(words[k]));
      }
    });

    test('a single word is just its fold; no words is the empty string', () {
      expect(ArabicFold.ayah(['ٱلرَّحۡمَٰنِ']), 'الرحم$daggerن');
      expect(ArabicFold.ayah(const []), '');
    });
  });

  group('ArabicFold.query: the typed side', () {
    test('nothing typed: empty, only spaces, only tashkeel, only tatweel', () {
      expect(ArabicFold.query(''), '');
      expect(ArabicFold.query('     '), '');
      expect(
        ArabicFold.query('${u(0x64E)}${u(0x650)}${u(0x651)}${u(0x652)}'),
        '',
      );
      expect(ArabicFold.query('ـــــ'), '');
    });

    test('digits only and Latin letters only are nothing', () {
      expect(ArabicFold.query('123'), '');
      expect(ArabicFold.query('٢٥٥'), '');
      expect(ArabicFold.query('abc'), '');
      expect(ArabicFold.query('2:255'), '');
    });

    test(
      'the pasted ornate brackets, a digit and the end sign are breaks or gone',
      () {
        expect(ArabicFold.query('﴿ قل ٢ هو ﴾'), 'قل هو');
        expect(
          ArabicFold.query('﴿قُلۡ هُوَ ٱللَّهُ أَحَدٌ ۝١﴾'),
          'قل هو الله احد',
        );
      },
    );

    test('tashkeel and tatweel inside a word vanish without a break', () {
      expect(ArabicFold.query('أَحۡمَد'), 'احمد');
      expect(ArabicFold.query('ابراهيـم'), 'ابراهيم');
      expect(ArabicFold.query('الرحمٰن'), 'الرحمن');
    });

    test('a typed dagger and a typed hamza vanish', () {
      expect(ArabicFold.query('الرحم$daggerن'), 'الرحمن');
      expect(ArabicFold.query('شي$hamza'), 'شي');
      expect(ArabicFold.query('ءامنوا'), 'امنوا');
      expect(ArabicFold.query('شَيۡـٔٗا'), 'شيا');
    });

    test('a hamza sign U+0654 / U+0655 vanishes like a typed hamza', () {
      expect(ArabicFold.query('ب${u(0x654)}ب'), 'بب');
      expect(ArabicFold.query('ب${u(0x655)}ب'), 'بب');
    });

    test('the alef forms, teh marbuta, alef maqsura and the small high letters fold', () {
      expect(ArabicFold.query('أإآٱا'), 'ااااا');
      expect(ArabicFold.query('رحمة'), 'رحمه');
      expect(ArabicFold.query('موسى'), 'موسي');
      expect(ArabicFold.query('ب${u(0x6E7)}'), 'بي');
      expect(ArabicFold.query('ب${u(0x6E8)}'), 'بن');
      expect(ArabicFold.query('ک'), 'ك');
    });

    test('a typed ؤ and a typed ئ become the two private markers', () {
      expect(ArabicFold.query('ؤ'), ArabicFold.seatWaw);
      expect(ArabicFold.query('ئ'), ArabicFold.seatYeh);
      expect(
        ArabicFold.query('لؤلؤ'),
        'ل${ArabicFold.seatWaw}ل${ArabicFold.seatWaw}',
      );
      expect(ArabicFold.query('يستهزئون'), 'يستهز${ArabicFold.seatYeh}ون');
      expect(ArabicFold.query('مومن'), 'مومن');
    });

    test(
      'the invisible controls U+200B-200F and U+FEFF vanish without a break',
      () {
        for (final cu in [0x200B, 0x200C, 0x200D, 0x200E, 0x200F, 0xFEFF]) {
          expect(
            ArabicFold.query('ق${u(cu)}ل'),
            'قل',
            reason: cu.toRadixString(16),
          );
        }
      },
    );

    test('any other sign is a word break; breaks collapse and are trimmed', () {
      expect(ArabicFold.query('قل.هو'), 'قل هو');
      expect(ArabicFold.query('قل،هو'), 'قل هو');
      expect(ArabicFold.query('قل \t\n  هو'), 'قل هو');
      expect(ArabicFold.query('  قل هو  '), 'قل هو');
      expect(ArabicFold.query('«قل» - (هو)'), 'قل هو');
      expect(ArabicFold.query('قل1هو'), 'قل هو');
      expect(ArabicFold.query('قل،،، ،هو'), 'قل هو');
      expect(ArabicFold.query('...قل'), 'قل');
    });

    test('a vanishing character does not reopen or close a break', () {
      expect(ArabicFold.query('قل ـ هو'), 'قل هو');
      expect(ArabicFold.query('قل ${u(0x64E)} هو'), 'قل هو');
    });

    test('a 1,500-character input is accepted and folded', () {
      final typed = ('قُلۡ هُوَ ٱللَّهُ أَحَدٌ ' * 100).substring(0, 1500);
      expect(typed.length, 1500);
      final q = ArabicFold.query(typed);
      expect(q.startsWith('قل هو الله احد قل هو'), isTrue);
      expect(ArabicFold.letters(q), greaterThan(600));
      // The pattern of such a query is built without error.
      expect(() => ArabicFold.pattern(q), returnsNormally);
    });
  });

  group('ArabicFold.letters', () {
    test(
      'counts the characters that are not a space, the markers included',
      () {
        expect(ArabicFold.letters(''), 0);
        expect(ArabicFold.letters(' '), 0);
        expect(ArabicFold.letters('قل'), 2);
        expect(ArabicFold.letters('قل هو'), 4);
        expect(ArabicFold.letters('ل${ArabicFold.seatWaw}'), 2);
      },
    );
  });

  group('ArabicFold.pattern (research D2, "The pattern")', () {
    RegExp p(String typed) => ArabicFold.pattern(ArabicFold.query(typed));

    test('لؤلؤ matches لولوا and not لله', () {
      expect(p('لؤلؤ').hasMatch('لولوا'), isTrue);
      expect(p('لؤلؤ').hasMatch('لله'), isFalse);
      expect(p('لؤلؤ').hasMatch('ل$hamzaل$hamza'), isTrue);
    });

    test('a typed ئ needs a yeh or a seatless hamza in the text', () {
      expect(p('يستهزئون').hasMatch('يستهز$hamzaون'), isTrue);
      expect(p('يستهزئون').hasMatch('يستهزيون'), isTrue);
      expect(p('يستهزئون').hasMatch('يستهزون'), isFalse);
      // typed without any hamza the word still matches
      expect(p('يستهزون').hasMatch('يستهز$hamzaون'), isTrue);
      expect(p('يستهزءون').hasMatch('يستهز$hamzaون'), isTrue);
    });

    test('يا ايها matches the one folded word ي + dagger + ايها', () {
      expect(p('يا ايها').hasMatch('ي$daggerايها'), isTrue);
      expect(p('يأيها').hasMatch('ي$daggerايها'), isTrue);
      expect(p('ياأيها').hasMatch('ي$daggerايها'), isTrue);
      expect(p('يا ايها').hasMatch('يا ايها'), isTrue);
    });

    test('الذين امنوا matches الذين + a space + hamza + امنوا', () {
      expect(p('الذين امنوا').hasMatch('الذين $hamzaامنوا'), isTrue);
      expect(p('الذين آمنوا').hasMatch('الذين $hamzaامنوا'), isTrue);
    });

    test('احمد does not match الحمد', () {
      expect(p('احمد').hasMatch('الحمد'), isFalse);
      expect(p('أحمد').hasMatch('الحمد'), isFalse);
      expect(p('احمد').hasMatch('احمد'), isTrue);
    });

    test(
      'a typed alef finds the small alef, the waw of الصلوٰة, or a plain alef',
      () {
        expect(p('الرحمن').hasMatch('الرحم$daggerن'), isTrue);
        expect(p('الرحمٰن').hasMatch('الرحم$daggerن'), isTrue);
        expect(p('الكتاب').hasMatch('الكت$daggerب'), isTrue);
        expect(p('الصلاة').hasMatch('الصلو$daggerه'), isTrue);
        expect(p('الصلاه').hasMatch('الصلو$daggerه'), isTrue);
        expect(p('الصلاة').hasMatch('الصلاه'), isTrue);
        expect(p('ابراهيم').hasMatch('ابر$daggerهيم'), isTrue);
      },
    );

    test(
      'a typed word without the small alef still finds the word that has one',
      () {
        expect(p('رحمن').hasMatch('الرحم$daggerن'), isTrue);
        expect(p('مومن').hasMatch('مومن'), isTrue);
        expect(p('مؤمن').hasMatch('مومن'), isTrue);
      },
    );

    test('a space in the query matches a space in the text or none', () {
      expect(p('قل هو').hasMatch('قل هو'), isTrue);
      expect(p('قل هو').hasMatch('قلهو'), isTrue);
      expect(p('قلهو').hasMatch('قل هو'), isFalse);
    });

    test('a match never crosses a line break (the ayah separator)', () {
      expect(p('قل هو').hasMatch('قل\nهو'), isFalse);
      expect(p('لق').hasMatch('ل\nق'), isFalse);
    });

    test('a letterless query is an ArgumentError', () {
      expect(() => ArabicFold.pattern(''), throwsArgumentError);
      expect(() => ArabicFold.pattern(' '), throwsArgumentError);
      expect(() => ArabicFold.pattern('   '), throwsArgumentError);
    });

    test(
      'a match inside a longer word is a match (a part of a word is found)',
      () {
        expect(p('رحم').hasMatch('الرحم$daggerن'), isTrue);
        expect(p('رحم').hasMatch('رحمه'), isTrue);
        expect(p('رحم').hasMatch('يرحم'), isTrue);
      },
    );
  });

  group('ArabicFold.surahKey (the surah names)', () {
    test('hamza spellings of the names fold together', () {
      expect(ArabicFold.surahKey('سبإ'), 'سبا');
      expect(ArabicFold.surahKey('سبأ'), 'سبا');
      expect(ArabicFold.surahKey('سبا'), 'سبا');
      expect(ArabicFold.surahKey('الإنفطار'), 'الانفطار');
      expect(ArabicFold.surahKey('المؤمنون'), 'المومنون');
      expect(ArabicFold.surahKey('النبإ'), 'النبا');
    });

    test('teh marbuta, alef maqsura and the small alef fold; the soft characters are removed', () {
      expect(ArabicFold.surahKey('الفاتحة'), 'الفاتحه');
      expect(ArabicFold.surahKey('الضحى'), 'الضحي');
      expect(ArabicFold.surahKey('الرحمٰن'), 'الرحمن');
      expect(ArabicFold.surahKey('ءامنوا'), 'امنوا');
      expect(ArabicFold.surahKey('شي$hamza'), 'شي');
    });

    test('tashkeel vanishes, and the space of a two-word name too', () {
      expect(ArabicFold.surahKey('آل عمران'), 'العمران');
      expect(ArabicFold.surahKey('ٱلۡكَهۡفِ'), 'الكهف');
    });
  });
}
