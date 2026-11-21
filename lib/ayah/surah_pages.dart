import '../mushaf/models.dart';

/// The Mushaf pages that hold a surah: from the page of its first ayah to the page of its last ayah.
/// The first and last pages can also hold ayahs of the neighbouring surahs, as in the printed Mushaf.
class SurahPages {
  const SurahPages(this.first, this.last);

  /// Throws [RangeError] for a surah outside 1..114.
  factory SurahPages.of(MushafMeta meta, int surah) {
    final info = meta.surah(surah);
    return SurahPages(
      meta.pageOfAyah(surah, 1),
      meta.pageOfAyah(surah, info.ayahs),
    );
  }

  final int first;
  final int last;

  int get count => last - first + 1;

  @override
  bool operator ==(Object other) =>
      other is SurahPages && other.first == first && other.last == last;

  @override
  int get hashCode => Object.hash(first, last);

  @override
  String toString() => 'SurahPages($first..$last)';
}
