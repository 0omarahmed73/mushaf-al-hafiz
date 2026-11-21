import '../mushaf/models.dart';

/// Names of the files the app shares (contracts/share-formats.md): Arabic, digits 0-9.
class FileNames {
  const FileNames._();

  // Characters Android file systems and share targets do not accept, and control characters.
  static final RegExp _forbidden = RegExp(r'[/\\:*?"<>|\x00-\x1F]');

  /// «مصحف - صفحة 293.png»
  static String page(int page) {
    if (page < 1 || page > MushafMeta.pageCount) {
      throw RangeError.range(page, 1, MushafMeta.pageCount, 'page');
    }
    return 'مصحف - صفحة $page.png';
  }

  /// «سورة البقرة.pdf» for the surah named [name] (as in `SurahInfo.name`, without «سورة»).
  static String surah(String name) => 'سورة ${_clean(name)}.pdf';

  static String _clean(String name) =>
      name.replaceAll(_forbidden, ' ').replaceAll(RegExp(r' {2,}'), ' ').trim();
}
