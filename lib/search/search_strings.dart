// Every Arabic string of the search feature (feature 011, T002; spec FR-028; research D8).
//
// The owner confirmed every one of them on 2026-11-21 (task T070, Constitution VI): each doc comment says so. A string that
// changes later needs the owner's word again. None is machine-translated; numbers are Western digits, as the page number
// is. This is the only file of the feature that holds Arabic text: a string is never written in a widget. A surah's name
// is never held here (the metadata's spelling is used as the index writes it).

/// Confirmed by the owner, 2026-11-21. Shown as the tooltip and the screen-reader label of the search icon in the index app bar, and as the title of the search screen.
const String kSearchLabel = 'بحث';

/// Confirmed by the owner, 2026-11-21. Shown as the label of the search field (and read by a screen reader as its name).
const String kSearchFieldLabel = 'ابحث عن سورة أو آية';

/// Confirmed by the owner, 2026-11-21. Shown as the tooltip and the screen-reader label of the clear button inside the search field.
const String kSearchClear = 'مسح';

/// Confirmed by the owner, 2026-11-21. Shown as the heading of the surah group, with the number of surahs that match ([n], Western digits).
String kSurahHeading(int n) => 'السور · $n';

/// Confirmed by the owner, 2026-11-21. Shown as the heading of the ayah group, with the true total of ayat that match ([n], Western digits; never the 100 rows listed).
String kAyahHeading(int n) => 'الآيات · $n';

/// Confirmed by the owner, 2026-11-21. Shown to a screen reader only: read instead of the visible surah heading (and announced after a change of results).
String kSurahHeadingSemantics(int n) => 'السور، عدد النتائج $n';

/// Confirmed by the owner, 2026-11-21. Shown to a screen reader only: read instead of the visible ayah heading (and announced after a change of results).
String kAyahHeadingSemantics(int n) => 'الآيات، عدد النتائج $n';

/// Confirmed by the owner, 2026-11-21. Shown as the one line under the field when nothing, or no Arabic letter, is typed.
const String kSearchHint = 'اكتب اسم سورة، أو كلمات من آية';

/// Confirmed by the owner, 2026-11-21. Shown as the one line of the ayah group when exactly one Arabic letter is typed (the surah group already answers).
const String kSearchNeedTwo = 'اكتب حرفين على الأقل للبحث في الآيات';

/// Confirmed by the owner, 2026-11-21. Shown as the one line of the ayah group while the ayah text is being prepared for the first search of the run.
const String kSearchPreparing = 'جارٍ تجهيز البحث في الآيات';

/// Confirmed by the owner, 2026-11-21. Shown as the line when two or more letters match neither a surah nor an ayah; also the text announced to a screen reader then.
const String kSearchNone = 'لا توجد نتائج';

/// Confirmed by the owner, 2026-11-21. Shown under [kSearchNone], as the advice line.
const String kSearchNoneAdvice = 'جرّب كلمة واحدة أو كلمات أقل';

/// Confirmed by the owner, 2026-11-21. Shown as the line of the ayah group when preparing the ayah text failed.
const String kSearchFailed = 'تعذّر تجهيز البحث في الآيات';

/// Confirmed by the owner, 2026-11-21. Shown as the label of the button under [kSearchFailed] that prepares the ayah text again.
const String kSearchRetry = 'إعادة المحاولة';

/// Confirmed by the owner, 2026-11-21. Shown as the line under the last of the 100 ayah rows when more than 100 ayat match.
const String kSearchTooMany = 'النتائج كثيرة، اكتب كلمات أكثر لتضييق البحث';

/// Confirmed by the owner, 2026-11-21. Shown at the end of a surah row and of an ayah row: the page number [page] (the first page of the surah, or the page where the ayah begins).
String kPageShort(int page) => 'ص $page';

/// Confirmed by the owner, 2026-11-21. Shown as the title of an ayah row: the surah's name as the index writes it, then the ayah's number [ayah].
String kAyahRowTitle(String surahName, int ayah) => '$surahName · آية $ayah';

/// Confirmed by the owner, 2026-11-21. Shown to a screen reader only: the label of a surah row (a button), the surah's name and its first page [page].
String kSurahRowSemantics(String surahName, int page) =>
    'سورة $surahName، صفحة $page';

/// Confirmed by the owner, 2026-11-21. Shown to a screen reader only: the label of an ayah row (a button), the surah's name, the ayah's number and the page where it begins; the snippet's words follow it.
String kAyahRowSemantics(String surahName, int ayah, int page) =>
    'سورة $surahName، آية $ayah، صفحة $page';

/// Confirmed by the owner, 2026-11-21. Shown at the start and/or the end of a snippet, outside the stored words, where words of the ayah were left out; not read by a screen reader.
const String kSnippetCut = '…';
