# Dart Interfaces: Surah and Ayah Search (feature 011)

Signatures the tasks build and the tests pin. Names may change in the code if the test and this file change together. Behaviour of the folding and the
pattern is defined by research D2 and by `prototype/match_rules.py`; every example below is a test.

## `lib/search/arabic_fold.dart` (pure Dart, no Flutter import)

```dart
abstract final class ArabicFold {
  /// The small alef and the seatless hamza: the two SOFT characters of a folded stored word.
  static const String dagger = '\u0670';
  static const String hamza = '\u0621';

  /// A typed ؤ and a typed ئ inside a folded query (never mixed with و / ي).
  static const String seatWaw = '\u0001';
  static const String seatYeh = '\u0002';

  /// One STORED word folded (research D2, "The stored side"): letters folded, tashkeel/marks/tatweel/signs/spaces gone,
  /// `ء` (and the hamza signs) and `ٰ` kept as soft characters. Never empty for a stored word of the bundled text.
  static String word(String stored);

  /// The words of one stored ayah folded and joined by one space (word k of the result is word k of [words]).
  static String ayah(List<String> words);

  /// The typed text folded for matching: letters, single spaces, [seatWaw], [seatYeh]; every other character is a word
  /// break or vanishes; trimmed. `query('أَحۡمَد')` is `'احمد'`, `query('﴿ قل ٢ هو ﴾')` is `'قل هو'`.
  static String query(String typed);

  /// The number of letters of a folded query (its characters that are not a space).
  static int letters(String foldedQuery);

  /// The `RegExp` that finds [foldedQuery] in a folded text (research D2, "The pattern"). Throws [ArgumentError] when
  /// [foldedQuery] has no letter.
  static RegExp pattern(String foldedQuery);

  /// A surah name folded for the surah search: like [word] but `ء` and `ٰ` removed and ؤ/ئ as و/ي.
  static String surahKey(String name);
}
```

Examples pinned by `arabic_fold_test.dart` (`\u0670` is the soft small alef, `\u0621` the soft seatless hamza):
`word('ٱلرَّحۡمَٰنِ') == 'الرحم\u0670ن'`; `word('مُؤۡمِنٖ') == 'مومن'`; `word('يَسۡتَهۡزِءُونَ') == 'يستهز\u0621ون'`; `word('شَيۡـٔٗا') == 'شي\u0621ا'`;
`word('إِبۡرَٰهِـۧمَ') == 'ابر\u0670هيم'`; `word('ٱلصَّلَوٰةَ') == 'الصلو\u0670ه'`; `word('ءَامَنُواْ') == '\u0621امنوا'`; `word('يَٰٓأَيُّهَا') == 'ي\u0670ايها'`;
`word('۞ إِنَّ') == 'ان'`; `word('إِلۡ يَاسِينَ') == 'الياسين'`; `query('أَحۡمَد') == 'احمد'`; `query('﴿ قل ٢ هو ﴾') == 'قل هو'`;
`pattern(query('لؤلؤ'))` matches `'لولوا'` and does **not** match `'لله'`; `pattern(query('يا ايها'))` matches `'ي\u0670ايها'`.

## `lib/search/surah_search.dart`

```dart
/// The surahs that match [typed], in row order: the name that equals the query first, then names that start with it, then
/// names that contain it, ties in surah order (FR-004). A leading «سورة» of the query and a leading «ال» on either side are
/// ignored. Empty when [typed] has no Arabic letter. Never more than 114 rows; one typed letter is enough.
List<SurahInfo> searchSurahs(List<SurahInfo> surahs, String typed);
```

## `lib/search/ayah_index.dart`

```dart
class SearchIndexError implements Exception {
  const SearchIndexError(this.message);
  final String message;
}

class AyahIndex {
  AyahIndex({required this.chunks, required this.ayahStart, required this.surahFirst, required this.stored});
  static const int ayahsPerChunk = 800;

  final List<String> chunks;      // 8
  final Int32List ayahStart;      // 6,237
  final Int32List surahFirst;     // 115: surahFirst[s - 1] is the first ayah of surah s (1..114), surahFirst[114] == 6,236
  final List<String> stored;      // 6,236, words joined by '\n'

  int get ayahCount;              // 6,236
  int get estimatedBytes;         // about 2.6 MB

  AyahRef refOf(int index);       // from surahFirst
  int indexOf(AyahRef ref);

  /// The stored words of ayah [index], unchanged.
  List<String> storedWords(int index);

  /// The folded text of ayah [index] (no trailing line break).
  String foldedAyah(int index);

  /// The ayat of chunk [chunk] whose folded text contains [pattern], once each, in ascending order.
  List<int> scanChunk(int chunk, RegExp pattern);

  /// The words of ayah [index] that [pattern] matches (a flag per stored word) and whether any matches at all.
  List<bool> matchedWords(int index, RegExp pattern);
}

/// Adds the surah files one by one (so the caller can yield between them) and builds the index.
class AyahIndexBuilder {
  /// The finer steps the service uses to yield between two ayat: [openSurah] decodes and checks a file and returns its ayat,
  /// [addAyah] folds and adds the next one (throws on a word that folds to nothing), [closeSurah] checks all were added.
  /// [addSurah] is the three together.
  List<List<String>> openSurah(int surah, String json);
  void addAyah(List<String> words);
  void closeSurah();

  /// Decodes [json] (the text of `assets/ayah/text/NNN.json`) and adds its ayat. Throws [SearchIndexError] on a surah
  /// out of order, a malformed file or a word that folds to nothing.
  void addSurah(int surah, String json);

  /// Validates against [meta] (114 surahs, 6,236 ayat, the per-surah counts) and returns the index; throws
  /// [SearchIndexError] otherwise.
  AyahIndex build(MushafMeta meta);
}
```

## `lib/search/search_service.dart`

```dart
enum IndexPhase { notStarted, preparing, ready, failed }

class AyahHit {
  const AyahHit({required this.ref, required this.page, required this.words, required this.matched});
  final AyahRef ref;
  final int page;                 // where the ayah begins (MushafMeta.pageOfAyah)
  final List<String> words;       // the stored words, unchanged
  final List<bool> matched;       // one flag per word
}

class AyahSearchResult {
  const AyahSearchResult({required this.total, required this.hits});
  final int total;                // all ayat that match
  final List<AyahHit> hits;       // the first [maxRows] in Mushaf order
  static const int maxRows = 100;
  bool get tooMany => total > hits.length;
}

/// One per run. Creating it reads nothing (FR-022).
class SearchService extends ChangeNotifier {
  SearchService({
    required AssetBundle bundle,
    required Future<MushafMeta> Function() meta,
    Future<void> Function()? yieldTurn,        // default Future<void>.delayed(Duration.zero); tests pass an immediate one
    Duration slice = const Duration(milliseconds: 8),
    void Function(String line)? trace,         // gets the `SEARCH prepare` line; default: SearchTrace.emit when SearchTrace.enabled, else none (a test passes its own)
  });

  /// A service that is already `ready` over [index] (tests of the screen); it has no bundle, so `prepare`/`retry` do nothing.
  /// [yieldTurn] as above (a widget test passes an immediate one so a scan needs no pump).
  SearchService.prepared(AyahIndex index, MushafMeta meta, {Future<void> Function()? yieldTurn});

  IndexPhase get phase;
  Object? get failure;

  /// Starts preparing once; does nothing while `preparing` or `ready`; starts again after `failed`.
  Future<void> prepare();
  Future<void> retry();

  /// Scans the folded text for [foldedQuery] (at least two letters), a slice at a time. Returns null when [isCurrent]
  /// became false (a newer query exists) or the service is not ready. Never throws for a query.
  Future<AyahSearchResult?> searchAyat(String foldedQuery, {required bool Function() isCurrent});
}
```

## `lib/search/search_session.dart`

```dart
sealed class AyahGroup { const AyahGroup(); }
class AyahHint extends AyahGroup { const AyahHint(); }          // nothing typed
class AyahNeedsTwo extends AyahGroup { const AyahNeedsTwo(); }  // one letter
class AyahPreparing extends AyahGroup { const AyahPreparing(); }
class AyahFailed extends AyahGroup { const AyahFailed(this.error); final Object error; }
/// Two or more letters, ready, the scan has not answered yet and there is no earlier answer to keep on screen (a few ms): the screen draws nothing for the ayah group.
/// While an earlier answer exists it stays on screen until the new one replaces it (no flicker, the scroll offset is kept).
class AyahSearching extends AyahGroup { const AyahSearching(); }
class AyahResults extends AyahGroup { const AyahResults(this.result); final AyahSearchResult result; }

class SearchView {
  const SearchView({required this.surahs, required this.ayah, required this.letters});
  final List<SurahInfo> surahs;
  final AyahGroup ayah;
  final int letters;
  bool get nothingTyped => letters == 0;
  /// Two or more letters, ready, and neither group has a row: the «لا توجد نتائج» state.
  bool get none;
}

/// The screen's logic. Owned by the screen's State; disposed with it.
class SearchSession extends ChangeNotifier {
  SearchSession({
    required SearchService service,
    required List<SurahInfo> surahs,
    required void Function(String text) onAnnounce,   // the screen: SemanticsService.sendAnnouncement
    Duration quiet = const Duration(milliseconds: 700),
  });
  SearchView get view;

  /// The text of the field exactly as typed (never altered or trimmed).
  String get typed;

  /// The field changed: fold, answer the surah group now, start the ayah scan, drop any older scan. A change of the
  /// service's phase to `ready` runs the current query again.
  void setQuery(String typed);

  /// «إعادة المحاولة»: `service.retry()`, then the current query (the service's own notifications already refresh the view; a refresh is added only when the phase changed without one).
  Future<void> retry();

  // After every change of [view] the session `touch`es its [AnnouncementGate] with the two headings' semantics labels (or
  // `kSearchNone`); the gate calls [onAnnounce] once, [quiet] after the last change, and never twice with the same text.
}

/// What the session touches the gate with: the labels of the groups that have rows joined by «. » (`kSurahHeadingSemantics(n)`, `kAyahHeadingSemantics(total)`), or `kSearchNone`,
/// or '' (nothing typed, the need-two line, preparing, failed, a scan under way with no group yet).
String announcementOf(SearchView view);

/// Calls its callback once, [quiet] after the last [touch], with the latest text; nothing if the text equals the last sent.
/// An empty text is never sent and makes the gate forget the last sent text (the same words are announced again later).
class AnnouncementGate {
  AnnouncementGate({required this.quiet, required this.send});
  final Duration quiet;
  final void Function(String text) send;
  void touch(String text);
  void dispose();
}
```

## `lib/search/ayah_target.dart`

```dart
/// What an ayah row hands back to the index and the reader.
class AyahTarget {
  const AyahTarget(this.ref, this.page);
  final AyahRef ref;
  final int page;
}
```

## `lib/search/snippet.dart`

```dart
class SnippetWords {
  const SnippetWords({required this.from, required this.to, required this.cutBefore, required this.cutAfter});
  final int from;           // first word shown (inclusive)
  final int to;             // last word shown (inclusive)
  final bool cutBefore;     // words were left out before [from]: draw «…» first
  final bool cutAfter;      // words were left out after [to]: draw «…» last
}

/// The run of whole, consecutive words around the first matched word: grows right then left while [fits] (a three-line
/// layout in the row's width) says so; the whole ayah when it fits. [fits] must be monotone in the run's length. A word is
/// never cut. Pure: the widget supplies [fits] from a `TextPainter`, the tests from a character budget.
SnippetWords snippetOf(List<bool> matched, {required bool Function(int from, int to) fits});
```

## `lib/search/search_strings.dart` (proposals; see research D8; the doc comment of each says so)

```dart
const String kSearchLabel = 'بحث';                              // icon, tooltip, screen title
const String kSearchFieldLabel = 'ابحث عن سورة أو آية';
const String kSearchClear = 'مسح';
String kSurahHeading(int n) => 'السور · $n';
String kAyahHeading(int n) => 'الآيات · $n';
String kSurahHeadingSemantics(int n) => 'السور، عدد النتائج $n';
String kAyahHeadingSemantics(int n) => 'الآيات، عدد النتائج $n';
const String kSearchHint = 'اكتب اسم سورة، أو كلمات من آية';
const String kSearchNeedTwo = 'اكتب حرفين على الأقل للبحث في الآيات';
const String kSearchPreparing = 'جارٍ تجهيز البحث في الآيات';
const String kSearchNone = 'لا توجد نتائج';
const String kSearchNoneAdvice = 'جرّب كلمة واحدة أو كلمات أقل';
const String kSearchFailed = 'تعذّر تجهيز البحث في الآيات';
const String kSearchRetry = 'إعادة المحاولة';
const String kSearchTooMany = 'النتائج كثيرة، اكتب كلمات أكثر لتضييق البحث';
String kPageShort(int page) => 'ص $page';
String kAyahRowTitle(String surahName, int ayah) => '$surahName · آية $ayah';
String kSurahRowSemantics(String surahName, int page) => 'سورة $surahName، صفحة $page';
String kAyahRowSemantics(String surahName, int ayah, int page) => 'سورة $surahName، آية $ayah، صفحة $page';
const String kSnippetCut = '…';
```

## `lib/search/search_trace.dart`

```dart
/// `--dart-define=SEARCH_TRACE=true`: `SEARCH prepare ms=<t> slices=<n>` (printed by the SERVICE, once, when the text is ready; `slices` is the yields plus the last piece of work),
/// `SEARCH query len=<n> ayat=<total> ms=<t>` (printed by the SCREEN, from the change of the field to the frame after the results were built).
/// `--dart-define=SEARCH_BENCH=true`: the 20 queries of SC-004 are run when the search screen opens: `SEARCHBENCH q=<i> ayat=<total> ms=<t>`.
/// Both are `const bool.fromEnvironment`, print to the log only (never a query's text), and are free when off.
abstract final class SearchTrace {
  static const bool enabled = bool.fromEnvironment('SEARCH_TRACE');
  static const bool bench = bool.fromEnvironment('SEARCH_BENCH');
  static String prepareLine(int ms, int slices);
  static String queryLine(int length, int total, int ms);
  static String benchLine(int index, int total, int ms);
  /// The one place that prints (`debugPrint`), behind `if (!enabled && !bench) return;`; callers guard on the flag too, so a line is not even built when off.
  static void emit(String line);
  static const List<String> benchQueries; // the 20 of SC-004: ten one-word, five phrases, «ال», 2:282 pasted (the stored words, checked by a test), three that match nothing
}
```

## `lib/search/search_screen.dart`

```dart
/// The search screen. Pops an `int` (a surah's first page) or an [AyahTarget].
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.trace, this.bench});
  // Reads SearchService, MushafRepository (the surah list) and TextSizeSettings? from the Provider tree.
  // Starts `service.prepare()` after its first frame (the service notifies at once and the provider listens: never while the
  // route builds), and only when the phase is `notStarted`: a preparation that runs is shared, a failed one waits for «إعادة المحاولة».
  final void Function(String line)? trace; // the SEARCH query / SEARCHBENCH lines; null: SearchTrace.emit under the build flags, else nothing
  final bool? bench;                       // run the 20 benchQueries when the screen opens (q=1..20); null: SearchTrace.bench
}
```

Keys for tests: `search-field`, `search-clear`, `surah-row-<n>`, `ayah-row-<surah>:<ayah>`, `search-retry`, `search-more-line`, `search-heading-surahs`,
`search-heading-ayat`; also `search-results` (the list) and `ayah-snippet-<surah>:<ayah>` (the snippet's text inside its row).

## Additions to existing files

```dart
// lib/mushaf/page_viewport.dart
/// Asks a page to bring words into view once per [token] (research D4). Acts only when given.
class PageReveal {
  const PageReveal(this.wordIds, this.token);
  final Set<int> wordIds;
  final int token;
}
// PageViewport gets: final PageReveal? reveal;   (optional, default null: nothing changes)

// lib/mushaf/index_screen.dart: the app bar's actions get the search IconButton (when a SearchService? is provided); a value
// returned by the search screen is popped by the index unchanged.

// lib/app.dart: final SearchService? searchService;  if (searchService != null) ListenableProvider<SearchService?>.value(value: searchService)
// (the Listenable flavour because provider refuses a plain Provider of a ChangeNotifier in debug, as for PdfJob?, TextSizeSettings?, AppLookSettings?;
// only when there is one, so a screen reads null either way and a service provided above the app by a test is not hidden by a null)
// lib/main.dart: searchService: SearchService(bundle: rootBundle, meta: mushafRepository.loadMeta)

// lib/mushaf/reader_screen.dart (window [R4]): _openIndex: push<Object>; int -> jumpTo (unchanged); AyahTarget -> _showFoundAyah;
// a Listener over the body clears the found ayah; PageReveal travels _pagerFor -> _PageItem -> PageViewport.
```
