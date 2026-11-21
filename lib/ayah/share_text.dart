import '../mushaf/models.dart';
import 'ayah_ref.dart';

/// Builds the texts the app hands to the share sheet (contracts/share-formats.md). Digits are always
/// 0-9. The Quran words are never changed, trimmed or normalised.
class ShareTextBuilder {
  const ShareTextBuilder(this.meta);

  final MushafMeta meta;

  static const String tafsirSource = 'تفسير السعدي';
  static const String translationSource = 'Saheeh International';

  /// `﴿ <words joined by single spaces> ﴾` then `[سورة <name>: <number>]`, nothing else.
  String ayah(AyahRef ref, List<String> words) {
    if (words.isEmpty) {
      throw ArgumentError.value(
        words,
        'words',
        'an ayah has at least one word',
      );
    }
    return '﴿ ${words.join(' ')} ﴾\n${_reference(ref)}';
  }

  /// A tafsir entry, a blank line, the reference and the source's name. The Quran text is not included.
  String tafsir(AyahRef ref, String text) =>
      '$text\n\n${_reference(ref)}\n$tafsirSource';

  /// The English translation, a blank line, the reference and the source's name.
  String translation(AyahRef ref, String text) =>
      '$text\n\n${_reference(ref)}\n$translationSource';

  String _reference(AyahRef ref) =>
      '[سورة ${meta.surah(ref.surah).name}: ${ref.ayah}]';
}
