import '../mushaf/models.dart';

/// One ayah of the Mushaf: its surah (1..114) and its number inside it (1..the surah's ayah count).
class AyahRef {
  const AyahRef(this.surah, this.ayah)
    : assert(surah >= 1 && surah <= MushafMeta.surahCount),
      assert(ayah >= 1);

  /// Checks [surah] and [ayah] against the real ayah counts; throws [RangeError] for an ayah that
  /// does not exist.
  factory AyahRef.validated(MushafMeta meta, int surah, int ayah) {
    final ayahs = meta.surah(surah).ayahs; // throws RangeError for a bad surah
    if (ayah < 1 || ayah > ayahs) {
      throw RangeError.range(ayah, 1, ayahs, 'ayah');
    }
    return AyahRef(surah, ayah);
  }

  final int surah;
  final int ayah;

  /// `"surah:ayah"`, the same shape as the Mushaf's word keys without the word number.
  String get key => '$surah:$ayah';

  @override
  bool operator ==(Object other) =>
      other is AyahRef && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);

  @override
  String toString() => 'AyahRef($key)';
}

/// The ayah a pressed word belongs to.
AyahRef ayahOfWord(MushafWord word) => AyahRef(word.surah, word.ayah);

/// Ids of every word of [ref] that is drawn on [page], the end-of-ayah marker included; empty when the
/// ayah is not on the page. For an ayah that continues on another page only its part here is returned.
Set<int> wordIdsOfAyah(PageData page, AyahRef ref) => {
  for (final line in page.lines)
    for (final w in line.words)
      if (w.surah == ref.surah && w.ayah == ref.ayah) w.id,
};
