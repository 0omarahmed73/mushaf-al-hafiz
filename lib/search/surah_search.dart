/// The surah group of the search (feature 011, research D2 "Surah names"; spec FR-004, FR-009). Pure Dart over the 114
/// names of the Mushaf's data: nothing is read, nothing is kept.
library;

import '../mushaf/models.dart';
import 'arabic_fold.dart';

/// The surahs that match [typed], in row order: the name that equals the query first, then names that start with it, then
/// names that contain it, ties in surah order (FR-004). A leading «سورة» of the query (when something follows it) and a
/// leading «ال» on either side are ignored. Empty when [typed] has no Arabic letter. Never more than the 114 surahs of
/// [surahs]; one typed letter is enough.
List<SurahInfo> searchSurahs(List<SurahInfo> surahs, String typed) {
  var q = ArabicFold.query(typed)
      .replaceAll(ArabicFold.seatWaw, 'و')
      .replaceAll(ArabicFold.seatYeh, 'ي');
  // «سورة» folded is «سوره»: dropped when something follows it, kept (and so matching no name) when it is alone
  if (q.startsWith(_surahWord)) q = q.substring(_surahWord.length);
  if (q.isEmpty) return const [];
  final withAl = q.replaceAll(' ', '');
  final queries = {withAl, _withoutAl(withAl)};

  final rows = <(int rank, SurahInfo surah)>[];
  for (final surah in surahs) {
    final key = ArabicFold.surahKey(surah.name);
    final names = {key, _withoutAl(key)};
    var best = _noMatch;
    for (final query in queries) {
      for (final name in names) {
        final rank = name == query
            ? 0
            : name.startsWith(query)
            ? 1
            : name.contains(query)
            ? 2
            : _noMatch;
        if (rank < best) best = rank;
      }
    }
    if (best != _noMatch) rows.add((best, surah));
  }
  rows.sort((a, b) {
    final byRank = a.$1.compareTo(b.$1);
    return byRank != 0 ? byRank : a.$2.number.compareTo(b.$2.number);
  });
  return [for (final row in rows) row.$2];
}

/// «سورة» as the folding writes it (ة is ه), followed by the space that separates it from the name.
const String _surahWord = 'سوره ';

const int _noMatch = 3;

/// [folded] without its leading «ال» when something remains.
String _withoutAl(String folded) =>
    folded.startsWith('ال') && folded.length > 2 ? folded.substring(2) : folded;
