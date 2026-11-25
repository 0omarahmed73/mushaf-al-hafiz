import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/large_ayah/large_ayah_strings.dart';

/// Pins the proposed strings of specs/015-large-ayah-mode/contracts/ui.md (proposals until the owner confirms them).
void main() {
  test('the strings are exactly the proposals of contracts/ui.md', () {
    expect(LargeAyahStrings.title, 'الآيات الكبيرة');
    expect(LargeAyahStrings.subtitle, 'آية أو آيتان أو ثلاث في الصفحة، بخط كبير');
    expect(LargeAyahStrings.countTitle, 'عدد الآيات في الصفحة');
    expect(LargeAyahStrings.counts, ['آية واحدة', 'آيتان', 'ثلاث آيات']);
    expect(LargeAyahStrings.sizeTitle, 'حجم الخط');
    expect(LargeAyahStrings.sizes, ['كبير', 'أكبر', 'أكبر جدًا']);
    expect(LargeAyahStrings.continues, 'تتبع ←');
    expect(LargeAyahStrings.backToMushaf, 'المصحف');
    expect(LargeAyahStrings.backToMushafTooltip, 'الرجوع إلى المصحف');
  });

  test('the header names the surah, the ayat and the page in Arabic-Indic digits', () {
    expect(LargeAyahStrings.header(surahName: 'البقرة', first: 255, last: 255, page: 42), 'البقرة ٢٥٥ · صفحة ٤٢');
    expect(LargeAyahStrings.header(surahName: 'البقرة', first: 5, last: 6, page: 3), 'البقرة ٥–٦ · صفحة ٣');
    expect(
      LargeAyahStrings.header(surahName: 'البقرة', first: 282, last: 282, page: 48, part: (number: 1, of: 3)),
      'البقرة ٢٨٢ (١ من ٣) · صفحة ٤٨',
    );
  });
}
