/// The Arabic strings of the large-ayah view (feature 015, contracts/ui.md). Proposals until the owner confirms them
/// (Principle VI); do not change one without his word.
abstract final class LargeAyahStrings {
  static const String title = 'الآيات الكبيرة';
  static const String subtitle = 'آية أو آيتان أو ثلاث في الصفحة، بخط كبير';
  static const String countTitle = 'عدد الآيات في الصفحة';

  /// For 1, 2 and 3 ayat per screen.
  static const List<String> counts = ['آية واحدة', 'آيتان', 'ثلاث آيات'];
  static const String sizeTitle = 'حجم الخط';

  /// For size steps 1, 2 and 3.
  static const List<String> sizes = ['كبير', 'أكبر', 'أكبر جدًا'];

  /// Under a part of a split ayah that goes on in the next screen.
  static const String continues = 'تتبع ←';
  static const String backToMushaf = 'المصحف';
  static const String backToMushafTooltip = 'الرجوع إلى المصحف';

  /// The header of a screen: «البقرة ٢٥٥ · صفحة ٤٢», «البقرة ٥–٦ · صفحة ٣», «البقرة ٢٨٢ (١ من ٣) · صفحة ٤٨».
  static String header({
    required String surahName,
    required int first,
    required int last,
    required int page,
    ({int number, int of})? part,
  }) {
    final ayat = first == last ? indic(first) : '${indic(first)}–${indic(last)}';
    final ofPart = part == null ? '' : ' (${indic(part.number)} من ${indic(part.of)})';
    return '$surahName $ayat$ofPart · صفحة ${indic(page)}';
  }

  /// [n] in Arabic-Indic digits.
  static String indic(int n) =>
      String.fromCharCodes('$n'.codeUnits.map((c) => c >= 0x30 && c <= 0x39 ? 0x0660 + c - 0x30 : c));
}
