# Tasks: Surah and Ayah Search

**Input**: `specs/011-surah-ayah-search/` (spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md, prototype/match_rules.py,
checklists/requirements.md)

**Rules**: test-first (a failing test is written and run red before the code that makes it pass; one commit per task holds the test and its
code, so the suite is never red on `main`); `git add` explicit paths only and `dart format` on explicit files only (other sessions edit this
tree: never `git add -A`); **new tests go in NEW files** (`test/search/`, helpers in `test/support/search_harness.dart`): the tests of
features 001 to 010 are never edited and must keep passing (spec FR-030). After every task that edits `index_screen.dart`,
`reader_screen.dart`, `page_viewport.dart`, `app.dart` or `main.dart` run the earlier suites:
`flutter test test/mushaf test/look test/bookmarks test/onboarding test/motion test/ayah test/settings`. Check `git status` and
`git log -- <file>` before every task. `.specify/feature.json` is NOT changed (speckit scripts run with
`SPECIFY_FEATURE_DIRECTORY=specs/011-surah-ayah-search SPECIFY_FEATURE_NO_PERSIST=1`). The Quran text, page data, fonts, the page card and
`mushaf_page.dart` are never touched; `AyahRepository` and `ShareTextBuilder` are not edited. **No new package, permission, asset or table.**
Known harmless issue from feature 010: at 320 dp the reader's bottom bar overflows (feature 006 T020); ignore errors whose widget chain
contains `_BottomBar`. Lesson from feature 010: widget tests that write the database with `tester.runAsync` while a drift `watch*` stream is
listened in the fake-async zone can hang; write through the app or before the pump. Real asset loading in widget tests runs outside the
fake clock (`settle` / `settleReader` of `test/support/`). **Do not write a unicode escape in a Dart test string where the character is
what the test is about**: write the Arabic character itself (the escapes of research D2 are for the soft small alef and the seatless
hamza only). Commit trailer: `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.

**The reference**: `python3 -I specs/011-surah-ayah-search/prototype/match_rules.py` (from the repository root) prints every number the Dart
tests must agree with (research D2): the 34 forms, the 12,472 self-matches, the 570 names, the narrowing table, and the fold fingerprint
`0xd2ba2ab9` (the Dart folding of the 6,236 ayat hashed with the same FNV-1a 32 gives the same number; verified with a scratch Dart port).

**Phone tasks** are marked **[PHONE]**: only with the owner in that session; never unlock the phone, ask before input and before installing,
change no phone setting (research D9). **Owner task** **[OWNER]**: Constitution VI, the feature is not done before it.

**`reader_screen.dart` window [R4]**: the file is also edited by the feature 010 windows R1, R2, R3 and by other sessions. **All the tasks of
this feature come after feature 010's: do not open [R4] before every 010 task that touches the file is committed and `git status` is clean for
it.** The three [R4] tasks **T041, T042, T043** are one sitting, in this order, each its own commit. No other task of this feature edits the
file. `index_screen.dart` (T045), `page_viewport.dart` (T040), `app.dart` and `main.dart` (T044) are small additive edits, each after
`git status` and `git log -- <file>`.

Key: **FR/SC** are the spec's ids; "research D#" the decisions; "data-model.md X" and "contracts/ui.md X" the cited definitions.

## Phase 1: Setup

- [x] T001 Record the baselines on the **unchanged** code, before any edit of `lib/`: `test/search/search_baseline_test.dart` pumps (a) `IndexScreen`
  through `LookApp` (`test/support/look_harness.dart`) at 412 x 915 and at 320 x 640 with `textScale: 2.0`, in `LookChoice.emerald` and
  `LookChoice.night`, and measures the rectangles of the title «الفهرس», the three tab texts, the first three rows of `surah-list` and, after
  tapping the tab «صفحة», `page-field`; (b) the reader through `pumpSizedReader` (`test/support/reader_harness.dart`) at 412 x 915 on pages 42 and
  293: `top-bar`, the `PageView`, and every line and word through `pageRects` of `test/support/motion_geometry.dart`. Print the rectangles; the numbers
  become literals in the test with a tolerance of 0.01. Run it green on the unchanged code and commit it **before** T020. It must still pass after
  T045 and T047 except for the one thing the spec allows to move: the index title may lose width (assert its start edge and its top unchanged and
  its width at most 48 px smaller) (spec FR-030, SC-008; research D7; Constitution I)
- [x] T002 [P] Test-first: `test/search/search_strings_test.dart` (red) pins every string and function of contracts/dart-interfaces.md
  `search_strings.dart` (`kSearchLabel` «بحث», `kSearchFieldLabel`, `kSearchClear`, `kSurahHeading(114)` is «السور · 114» and `kAyahHeading(5182)`
  «الآيات · 5182» with Western digits, the two heading semantics labels, `kSearchHint`, `kSearchNeedTwo`, `kSearchPreparing`, `kSearchNone`,
  `kSearchNoneAdvice`, `kSearchFailed`, `kSearchRetry`, `kSearchTooMany`, `kPageShort(293)` «ص 293», `kAyahRowTitle('الإخلاص', 1)` «الإخلاص · آية 1»,
  `kSurahRowSemantics('الكهف', 293)` «سورة الكهف، صفحة 293», `kAyahRowSemantics('البقرة', 255, 42)` «سورة البقرة، آية 255، صفحة 42», `kSnippetCut`
  «…»); reads the source file and asserts it has the header that says the strings are proposals awaiting T070 and that every declaration has a `///`
  doc comment that says where it is shown; no Latin letter and no Arabic-Indic digit in any string; then `lib/search/search_strings.dart` exactly as
  the contract. These strings are the only Arabic text of the feature (spec FR-028; research D8; Constitution VI)

---

## Phase 2: Foundational (pure logic and the service; blocks the stories; nothing visible changes)

- [x] T003 [P] Test-first: `test/search/arabic_fold_test.dart` (red), over small literals (the real-data sweeps are T004-T006): `ArabicFold.word`
  for every row of the table of research D2 "The stored side" (the four alef forms to `ا`; `ؤ` to `و`; `ئ` to `ي`; `ى` and `ی` to `ي`; `ة` to `ه`; `ک` to
  `ك`; U+0654 and U+0655 and `ء` to the soft hamza; U+0670 kept; U+06E7 to `ي`; U+06E8 to `ن`; tashkeel U+064B-0653 and U+0656-065F, U+06E5 and U+06E6,
  the marks U+06D6-06E4 and U+06E9-06ED, `۞ ۩`, tatweel and the spaces inside a word gone) and the ten word examples of contracts/dart-interfaces.md
  (`word('ٱلرَّحۡمَٰنِ')`, `'مُؤۡمِنٖ'`, `'يَسۡتَهۡزِءُونَ'`, `'شَيۡـٔٗا'`, `'إِبۡرَٰهِـۧمَ'`, `'ٱلصَّلَوٰةَ'`, `'ءَامَنُواْ'`, `'يَٰٓأَيُّهَا'`,
  `'۞ إِنَّ'`, `'إِلۡ يَاسِينَ'`); `ayah(words)` joins the folds by one space; `query`: empty, only spaces, only tashkeel, only tatweel, digits only, Latin only,
  `﴿ قل ٢ هو ﴾` is `قل هو`, a typed dagger and a typed `ء` vanish, `ؤ` and `ئ` become the two private markers, U+200B-200F and U+FEFF vanish, any other
  sign is a word break and breaks collapse and are trimmed, a 1,500-character input is accepted; `letters`; `pattern` matches the examples of
  research D2 (`لؤلؤ` matches `لولوا` and not `لله`; `يا ايها` matches the one folded word `ي`+dagger+`ايها`; `الذين امنوا` matches `الذين `+hamza+`امنوا`;
  `احمد` does not match `الحمد`) and throws `ArgumentError` for a letterless query; `surahKey` (`سبإ` to `سبا`, `الإنفطار` to `الانفطار`, `المؤمنون` to
  `المومنون`, `النبإ` to `النبا`); then `lib/search/arabic_fold.dart` as a port of `prototype/match_rules.py` (a `Uint16List` table for the code units
  below U+0700 so the fold of the whole text takes about 30 ms, research D1) (spec FR-006, FR-007, FR-008, FR-009; research D2)
- [x] T004 Test-first: `test/support/search_harness.dart` (a cached `Future<AyahIndex> realIndex()` and `Future<MushafMeta> realMeta()` over `rootBundle`, so the
  index is built once per test run) and `test/search/ayah_index_real_data_test.dart` (red) over **all 114 real files**: 6,236 ayat; 77,432 words; per-surah
  ayah counts equal `meta.surahs[s-1].ayahs`; **no stored word folds to the empty string**; for every ayah `foldedAyah(i)` equals its stored words folded and
  joined by one space; `storedWords(i)` are the stored words unchanged; chunks are 8 (7 of 800 ayat and one of 636), each ayah followed by one line break, the
  concatenated chunks have the fold fingerprint **0xd2ba2ab9** (FNV-1a 32 over the UTF-16 code units, as the Python reference prints it); `ayahStart` strictly
  increasing inside a chunk; `refOf` and `indexOf` agree for all 6,236; `meta.pageOfAyah(surah, ayah)` equals the page of the ayah's first word for all 6,236
  (load the 604 pages through `MushafRepository` as `test/ayah/ayah_text_integrity_test.dart` does; 2:282 is on page 48); `estimatedBytes` is under 6 MB;
  `AyahIndexBuilder` rejects with `SearchIndexError`: a surah added out of order, malformed JSON, a word that folds to nothing, and `build` with 113
  surahs, with one ayah fewer in a surah, or with a count different from `meta`; then `lib/search/ayah_index.dart` (`AyahIndex`, `AyahIndexBuilder`,
  `SearchIndexError`) as data-model.md "AyahIndex" and "Validation" say (spec FR-018, FR-019, SC-009; research D1, D3)
- [x] T005 Test-first: `test/search/ayah_search_table_test.dart` (red) over the real index, scanning every chunk with `scanChunk` (ascending, once per ayah,
  the sum over chunks is the total): all **34 typed forms** of the table of User Story 3 find the ayat named (`احمد`/`أحمد` find 61:6 and not 1:2; `ابراهيم`/
  `إبراهيم`/`ابراهيـم` find 14:35 and 2:124; the others as the table), the four «exactly» rows find exactly `{1:1, 27:30}`, `{2:2}`, `{112:1}` and
  `{2:255, 3:2}`; `ذو القرنين` finds nothing and `ذي القرنين` finds 18:83; 2:282 pasted exactly as printed finds exactly 2:282; a word that occurs three times in one
  ayah is one hit; two spellings of the same query give the same ayat (User Story 3 scenario 5); the refrain `فباي الاء ربكما تكذبان` finds **31** ayat, each its own hit with its own number and none merged (spec Edge Cases); `matchedWords` marks all four words of 112:1 for `قل هو الله احد`,
  the word «ٱلرَّحۡمَٰنِ» of 1:3 for `رحم` (not «ٱلرَّحِيمِ», whose letters are ر ح ي م) and both words of 1:3 for `الرحمن الرحيم`, and the one word «يَٰٓأَيُّهَا» of 2:104 for `يا ايها`; then `scanChunk` and `matchedWords` in
  `lib/search/ayah_index.dart` (a match never crosses an ayah: the pattern has no `.` and no `\s`) (spec FR-005, FR-006, FR-007, SC-002; research D2, D3)
- [x] T006 Real-data sweeps, test-only (they should pass at once; a failure is a defect in T003-T005): `test/search/ayah_search_self_match_test.dart`
  (**SC-003**: for all 6,236 ayat, the ayah pasted exactly as the Mushaf prints it and the careless form (tashkeel U+064B-0653, 0656-065F, the Quranic
  marks U+06D6-06E4 and 06E9-06ED and tatweel removed, `ٱ أ إ آ` as `ا`, `ة` as `ه`, `ى` as `ي`, the small letters left) each match their own ayah: 12,472 of 12,472;
  and for 300 ayat spread over the 114 surahs a full scan returns that ayah among its hits), `test/search/ayah_search_narrowing_test.dart` (the table of research
  D2 as exact counts: `لؤلؤ` 8, `رؤيا` 7, `سؤال` 1, `جزؤا` 6, `مئة` 10, `مؤمن` 200, `سئل` 82, `شيئا` 76, `شئ` 456, `يستهزئون` 14, `الملائكة` 53, `جزاء` 45, `ءامنوا` 266, `امنوا`
  266; `النبيين` 13; and over the 15,122 distinct stored words typed carelessly (hamza letters as the Mushaf has them) **none finds nothing** and the total
  number of ayat found is 308,124; give it `Timeout(Duration(minutes: 8))`) and `test/search/ayah_search_speed_test.dart` (**SC-004's automated bound**: 20 queries,
  ten one-word, five phrases, `ال`, 2:282 pasted, three that match nothing, each finishes in under 1 s on the machine, the typical one in about 10 ms; `ال` returns 5,182
  ayat; the 1,500-character query of 2:282 repeated is accepted) (spec FR-023, SC-002, SC-003, SC-004; research D2, D5)
- [x] T007 [P] Test-first: `test/search/surah_search_test.dart` (red) over the real names of `assets/mushaf/meta.json`: **SC-001**, the 570 queries (each of the 114
  names in the five careless ways: as shown; every hamza bare (`أ إ آ ٱ` to `ا`, `ؤ` to `و`, `ئ` to `ي`, `ء` removed); `ة` as `ه` and `ى` as `ي`; with «سورة » in front; without the
  leading «ال») return the right surah and the name that equals the query is the **first** row; `كهف` and `الكهف` and `سورة الكهف` list 18; `سبأ`, `سبا`, `سبإ` list 34 and
  `الإنسان`/`الانسان` list 76; `الحج` lists 22, 15, 49 in that order; `ق` lists 50 first and `ص` lists 38 first (one letter is enough); a query with no Arabic letter lists
  nothing; no two names are equal after dropping the leading «ال»; never more than 114 rows; a leading «سورة» alone is not dropped; then `lib/search/surah_search.dart`
  (`searchSurahs`) per research D2 "Surah names" (spec FR-004, FR-009, SC-001)
- [x] T008 [P] Test-first: `test/search/snippet_test.dart` (red): `snippetOf(matched, fits:)` with a character-budget `fits`: the run starts at the first matched word, grows
  right then left by whole words, stops at the first word that does not fit, is the whole ayah (no cut flags) when it fits, `cutBefore`/`cutAfter` are true exactly when words are
  left out on that side, a single word wider than the budget is still returned alone, and the result is monotone (a larger budget never gives a smaller run); with the **real
  index**: for all 6,236 ayat, searching the ayah's own first three words, the snippet contains the first matched word, its words are `storedWords(i).sublist(from, to + 1)`
  character for character (never the folded or the typed form), and for 2:282 (128 words) a 40-character budget gives a run with both cut flags and a 100,000 budget gives the
  whole ayah; then `lib/search/snippet.dart` (`SnippetWords`, `snippetOf`) (spec FR-011, FR-012, SC-009; research D6)
- [x] T009 Test-first: `test/search/search_service_test.dart` (red), with a counting `MapBundle` (`test/support/map_bundle.dart`) over the 114 real files read from
  `assets/ayah/text/` and an immediate `yieldTurn`: **creating a `SearchService` reads nothing** (0 loads, `phase == notStarted`; FR-022); `prepare()` reads the 114 files once and
  ends `ready`; a second `prepare()` while `preparing` and one after `ready` read nothing more (the work is shared, an earlier closed search does not start it again); with
  `slice: Duration.zero` the preparing yields after every ayah (the yield count is at least 6,236) and with a large `slice` it yields rarely (the slices are real); a bundle that lacks file 057
  ends `failed` with `failure` set and `searchAyat` returns null; `retry()` after the file is there ends `ready`; a file with one ayah fewer ends `failed` with a
  `SearchIndexError` (the validation of data-model.md runs at every preparation and never serves a partial index); `searchAyat('ال', ...)` over the real index returns total
  **5,182** and **100** hits in Mushaf order, each hit with its `page` from `meta.pageOfAyah`, its stored words and its matched flags, `tooMany` true; a query with fewer than two
  letters is never passed to it (the session does that, T010) and returns an empty result; `isCurrent` turning false after the first chunk makes it return null after at most one
  more chunk; `SearchService.prepared(index, meta)` is `ready` at once and reads nothing; the service notifies its listeners on every phase change; then `lib/search/search_service.dart`
  (`loadString(path, cache: false)` per surah, decode and fold one ayah at a time with a `Stopwatch` of `slice`, `AyahIndexBuilder`, one `scanChunk` per chunk with a yield between,
  the first `AyahSearchResult.maxRows` = 100 hits kept and the rest only counted) (spec FR-014, FR-018, FR-019, FR-022, FR-023; research D1, D5)
- [x] T010 Test-first: `test/search/search_session_test.dart` (red), no widgets, with a fake service whose `searchAyat` completes on demand and a fake clock: every row of the table of
  contracts/ui.md "States" (letters 0, 1, 2 or more with the service `notStarted`, `preparing`, `failed`, ready with ayat, ready with no ayah and a surah match, ready with nothing in
  either group → `view.none`); the surah group is answered **in the same call** as `setQuery`; **stale answers**: query A then B, B answers first and then A answers late → the view
  shows B and A never replaces it (FR-023), a scan whose `isCurrent` became false returns null and changes nothing; when the service becomes `ready` the session runs the query that
  is in the field **now**; `retry()` runs `service.retry()` and then the current query; `typed` is never altered or trimmed in what the session keeps; the `AnnouncementGate` calls
  `send` once, 700 ms after the last `touch`, with the text of the last touch, sends nothing if that text equals the last one sent, restarts on a new `touch` and is cancelled by
  `dispose`; the announced text is the two headings' semantics labels (or `kSearchNone`); then `lib/search/search_session.dart` (`AyahGroup` and its subclasses, `SearchView`,
  `SearchSession(service:, surahs:, onAnnounce:)`, `AnnouncementGate`) and `lib/search/ayah_target.dart` (spec FR-009, FR-014, FR-023, FR-027; research D5, D13)

---

## Phase 3: User Story 1 - Find a surah by its name, however I spell it (Priority: P1) - the MVP core

**Goal**: the search screen, with the field and the surah group, answers from one letter and hands the first page of the chosen surah back.

**Independent test**: `test/search/search_screen_test.dart` pumping `SearchScreen` directly over `SearchService.prepared(realIndex, meta)`; then SC-001 (done in T007).

- [x] T020 [US1] Test-first: `test/search/search_screen_test.dart` (red; the harness `test/support/search_harness.dart` gets `pumpSearch(t, {look, screen, textScale, readingPercent,
  service})` that shows `SearchScreen` as a pushed route over a `MushafApp` with a `SearchService` supplied by its **own `Provider<SearchService?>` placed above `MushafApp`** (the app's own parameter arrives only with T044, so T020-T043 must not need it), records the value the route pops, and settles real loading): the app bar is «بحث»
  with a back arrow; the field (`search-field`, label «ابحث عن سورة أو آية») has the focus when the screen opens and the keyboard is up (`autofocus`; `t.testTextInput.isVisible` is true; FR-002), is single-line with `autocorrect: false`,
  `enableSuggestions: false`, `enableIMEPersonalizedLearning: false`, `textInputAction: search`, **no input formatter and no length limit**: entering a 1,500-character text with tashkeel
  leaves `controller.text` exactly as entered (spec FR-008); nothing typed shows the single line «اكتب اسم سورة، أو كلمات من آية» and no heading; `كهف` shows the heading «السور · 1»
  (`search-heading-surahs`) and the row `surah-row-18` with «18», «الكهف» and «ص 293»; `سبا` shows surah 34 with its name as the index writes it («سبإ»); `الحج` shows 22, 15, 49
  in that order with the heading «السور · 3»; `سورة الكهف` shows 18; `ق` shows `surah-row-50` first and the one line «اكتب حرفين على الأقل للبحث في الآيات» (no ayah heading); the clear
  button `search-clear` («مسح», 48 x 48) is absent while the field is empty, clears it and brings the hint back; a tap on `surah-row-18` pops the **int 293** (the index's own value)
  and a second tap in the same frame is ignored; the system back pops without a value; then `lib/search/search_screen.dart` and `lib/search/search_rows.dart` (the surah row as the
  index's `ListTile`: leading number, title the name as the index writes it, trailing «ص N», at least 56 px) per contracts/ui.md "The screen", "States" and "Rows"; the screen reads
  `SearchService`, `MushafRepository` (the surah list) and creates a `SearchSession`, calls `service.prepare()` once in `initState` (the ayah group of two or more letters is T030's) (spec FR-002,
  FR-004, FR-008, FR-009, FR-010, US1 scenarios 1-7; research D3, D12)

---

## Phase 4: User Story 2 - Find an ayah from a few of its words and open it on its page (Priority: P1)

**Goal**: the ayah group lists the ayat that contain the words, one row each, with the stored words emphasised, and hands an `AyahTarget` back.

**Independent test**: `test/search/search_ayah_group_test.dart`, with the real index.

- [x] T030 [US2] Test-first: `test/search/search_ayah_group_test.dart` (red): `قل هو الله احد` shows the heading «الآيات · 1» and exactly one row `ayah-row-112:1` with the title
  «الإخلاص · آية 1», «ص 604» and the snippet «قُلۡ هُوَ ٱللَّهُ أَحَدٌ» **character for character** (compare the `Text.rich` plain text with the stored words) whose four words have the
  emphasis style (colour `look.accent` **and** `TextDecoration.underline`, different from the normal style in more than colour); `بسم الله الرحمن الرحيم` shows two rows in Mushaf
  order, «الفاتحة · آية 1 · ص 1» then «النمل · آية 30 · ص 379»; a word three times in one ayah is one row; `رحم` includes ayat with «الرحمن», «رحمة» and «يرحم»; `ال` shows the heading
  «الآيات · 5182» (the true total, never 100), **100** rows and under them the line `search-more-line` «النتائج كثيرة، اكتب كلمات أكثر لتضييق البحث», and the last row is reachable
  by scrolling (`scrollUntilVisible`); a query with 100 hits or fewer has no more-line; 2:282 shows a snippet that is a run of **whole consecutive stored words** with «…» where words were
  left out (never inside a word) and at most **three lines** (`TextPainter` of the row's width and style reports no overflow beyond 3 lines); a tap on `ayah-row-112:1` pops
  `AyahTarget(AyahRef(112, 1), 604)` and the row of 2:282 pops page **48** (the page where the ayah begins, not 49); `ذو القرنين` shows no ayah heading and, with no surah match, the
  state of T050; then `search_rows.dart` (the ayah row: title, page, snippet from `snippetOf` with a `TextPainter` `fits` at most three lines cached per (ayah, width, scale), the
  `Text.rich` of stored words, `AmiriQuran`, 20 x the reading factor, height 2.0, inside `ReadingScope`) and the ayah group in `search_screen.dart` (the first 100 rows built lazily with
  `ListView.builder`, the heading with the true total, the more-line) (spec FR-005, FR-011, FR-012, FR-014, FR-020, US2 scenarios 1-8; research D3, D6)

---

## Phase 5: User Story 3 - Careless spelling still finds it (Priority: P1)

**Goal**: the field, not only the unit, finds the Mushaf's words however they are typed.

**Independent test**: `test/search/search_spelling_ui_test.dart`.

- [x] T035 [US3] Sweep through the screen (test-only; it should pass at once, a failure is a defect in T003-T030): `test/search/search_spelling_ui_test.dart` types into `search-field` a
  form of each of the 15 rows of the table of User Story 3 that has an ayah and checks that the ayah rows named are shown (use `ayah-row-<s>:<a>`; 100 rows are listed, so choose the
  forms whose total is at most 100, or assert on the first rows by Mushaf order), the four «exactly» phrases show exactly their ayat (heading counts 2, 1, 1, 2), the same query typed
  with and without tashkeel and with and without tatweel gives the same surah rows and the same ayah rows (scenario 5), `ٱلرَّحۡمَٰنِ` typed exactly as printed finds 1:1, and a pasted
  ayah with the ornate brackets and the end sign «﴿ ... ۝١ ﴾» finds its ayah (spec FR-006, FR-007, SC-002, US3 scenarios 1-5)

---

## Phase 6: User Story 4 - Searching never moves my wird or my place until I choose a result (Priority: P2) - the reader, then the entry point

**Goal**: a chosen ayah appears on its page, highlighted and in view, in browse mode, and nothing else of the reader moves; only then is the screen reachable.

**Independent test**: `test/search/reader_search_open_test.dart`, `reader_search_highlight_test.dart`, `reader_search_in_view_test.dart`, `page_viewport_reveal_test.dart`, then the whole path in
`search_index_entry_test.dart`.

**The order matters**: the reader learns to receive an `AyahTarget` (T041-T043) **before** the index gets the search icon (T045), so no ayah row can be reached while the reader would not
understand its result. The window [R4] tests of T041-T043 drive the reader by popping the index route with an `AyahTarget` themselves (`Navigator.pop(value)` on the route the reader pushed).

- [x] T040 [US4] Test-first: `test/search/page_viewport_reveal_test.dart` (red) with `PageViewport` around a keyed test page (words as `Text` with `ValueKey('w<id>')` in lines,
  the proportions of the real page) at 412 x 915 and in landscape 915 x 412 and the factors 0.8, 1.0, 1.5: **no `reveal` changes nothing** (the existing `test/mushaf/page_viewport_test.dart`
  stays green unchanged and the rectangles are equal); with a `PageReveal(wordIds, token)` the words' union is **inside the viewport** in `fits` (nothing moves), in `scrollsVertically`
  (the first word at about 30% from the top, the scroll position changed, no animation) and in `pansBothWays` (the union inside the viewport with a 24 dp margin, the first word at the right
  edge when the union is wider than the screen, the translation clamped to `[viewport - content, 0]`); a longer ayah than the screen at 150% has its **first line** in view; a new token acts
  again, the same token does not; a page zoomed in is first put back to scale 1; the words may appear a few frames after the page (the retry of up to 60 frames) and a reveal whose words never
  appear gives up silently without error; reduced motion makes no difference (nothing animates); then `lib/mushaf/page_viewport.dart`: `PageReveal` (contracts/dart-interfaces.md) and the optional
  `reveal` parameter, the walk of the page's elements for the `ValueKey('w<id>')` of the ids, `Scrollable.ensureVisible` for the vertical case and a clamped `TransformationController` value for
  the pan case, a frame scheduled only while a reveal is pending (spec FR-013, US6 scenario 5; research D4, D11)
- [x] T041 [US4] **[R4]** Test-first: `test/search/reader_search_open_test.dart` (red; the reader through `pumpSizedReader`, `pumpBrowseReader` of `test/support/khatm_harness.dart` and
  `pumpBookmarkReader`, whichever gives wird mode and browse mode; the route of the index is popped by the test with an `AyahTarget`): popping with `AyahTarget(AyahRef(2, 255), 42)` from page
  50 in **wird mode** shows page 42 in browse mode (`اجعلها موضعي` appears), the wird's `currentPage` is still 50 and its khatma count, today's portions, bookmarks and reminders are unchanged, the
  saved last viewed page is 42, and the ayah's words on the page are highlighted (`highlightedWordIds` of the card equals `wordIdsOfAyah(data, ref)`); popping with a target on the page **already
  shown** while following a wird leaves the reader in wird mode (no browse mode, no banner) and only the highlight appears (spec FR-016); with no wird the page is shown in browse mode (US4
  scenario 4); popping with the int 293 behaves exactly as today (jump, no highlight); a target for 2:282 highlights only its part on page 48; the page is shown once for one pop;
  `tapping «اجعلها موضعي»` after a result makes the shown page the wird's position and a swipe in browse mode moves no wird (US4 scenario 5); then `reader_screen.dart`: `_openIndex` becomes
  `push<Object>`, an `int` goes to `jumpTo` as today, an `AyahTarget` goes to a new `_showFoundAyah` (jump only when the page differs, then `loadPage`, `wordIdsOfAyah`, a new `Set`
  in `_highlight`, `_highlightPage`, and the found-ayah state of data-model.md "Found ayah"); the kept pager instance is rebuilt once for the highlight, and `ReaderController` is not edited
  (spec FR-013, FR-015, FR-016, SC-007; research D4)
- [x] T042 [US4] **[R4]** Test-first: `test/search/reader_search_highlight_test.dart` (red): the found ayah stays highlighted while nothing touches the reader (pump 5 s); it is cleared by **a tap on
  the page** (which also does what that tap does today: the bars toggle), a pointer-down on a bar, on the today card and on the page number, a swipe to another page, a jump to another page
  (go-to-page, a bookmark, a notification tap), a long press on another ayah (the menu's own highlight replaces it, and it is gone when the menu closes as today), and by opening the index,
  bookmarks, wirds and settings; a swipe that returns to the same page does not clear before the turn completes elsewhere; rotation and a lifecycle change do not clear it; the
  `Listener` takes no tap from the page or the bars (the existing tap and bar tests are unchanged); `reader_rebuild_budget_test.dart` and `reader_narrow_listeners_test.dart` of feature 010 stay
  green (the `Listener` adds no rebuild); then `reader_screen.dart`: a `Listener(behavior: HitTestBehavior.translucent, onPointerDown: ...)` around the body clears the found ayah, `_onPageChanged`
  clears it when the new page is not the highlighted page, `_openAyahMenu` replaces it (spec FR-013; research D4)
- [x] T043 [US4] **[R4]** Test-first: `test/search/reader_search_in_view_test.dart` (red) through the reader at 80, 100 and 150% (`pumpSizedReader(percent:)`) in portrait 412 x 915 and landscape
  915 x 412: after a target for 2:255 (page 42), 18:10 (page 294: page 293 is where al-Kahf begins) and 2:282 (page 48) is received, the **first highlighted word's rectangle is inside the pager's rectangle** and, when the
  highlighted part is shorter than the viewport, **all** of it is; the page's line and word rectangles are unchanged by the highlight itself (`pageRects` with and without the found ayah);
  at 150% in landscape the vertical scroll and the horizontal pan both reach the word; a result on the page already shown while the page is scrolled down brings the ayah into view again; the
  loading card of a page that is not ready yet does not break it (the reveal waits for the words); then `reader_screen.dart`: `_reveal` (`PageReveal(ids, ++token)`) is passed through `_pagerFor`
  (part of its cache key) and `_PageItem` to `PageViewport(reveal: ...)` only for the highlighted page and only while the found ayah is set (spec FR-013, US6 scenario 5, SC-008)
- [x] T044 [US1] Test-first: `test/search/search_wiring_test.dart` (red), in the style of `test/motion/frame_trace_wiring_test.dart`: `MushafApp(searchService: s)` provides `context.read<SearchService?>()`;
  with none it provides null; `lib/main.dart` passes `searchService: SearchService(bundle: rootBundle, meta: mushafRepository.loadMeta)` (a source check, as the splash wiring test does) and constructing it
  reads nothing (FR-022, T009); then `lib/app.dart` (`final SearchService? searchService`, `if (searchService != null) ListenableProvider<SearchService?>.value(value: searchService)`: provider refuses a plain `Provider` of a `ChangeNotifier` in debug, and with none nothing is provided so a service provided above the app by a test is not hidden by a null; a harness that provides its own above `MushafApp` must use `ListenableProvider` too) and `lib/main.dart` (the one argument). Check
  `git status` and `git log -- lib/app.dart lib/main.dart` first; both edits are additive; run the earlier suites (spec FR-001, FR-022; research D10)
- [x] T045 [US1] Test-first: `test/search/search_index_entry_test.dart` (red): with a `SearchService` the index's app bar has the `IconButton` `open-search` (`Icons.search`, tooltip and semantics label «بحث»,
  at least 48 x 48) and **without** a service (every earlier test) it is absent and the index is as it was; tapping it pushes `SearchScreen`; **end to end through the real reader** (a `pumpSearchReader` in `test/support/search_harness.dart`, a copy of `pumpSizedReader` that passes `searchService:` to `MushafApp`): reader, tap the surah
  name, tap the icon, type `كهف`, tap the row: page 293 in browse mode (the three taps of SC-006 plus the typing); type `قل هو الله احد`, tap the row: page 604 with the ayah highlighted and in view; the
  index and the search are both gone (the reader is the top route); back from search returns to the index and back again to the reader exactly as it was; the three tabs, the title, `surah-list`
  and `page-field` still work; the rectangles of T001 hold (the title may lose width); the existing tests that open the index (`test/mushaf/reader_screen_test.dart`, `test/look/
  theme_only_screens_night_test.dart`, `test/onboarding/tips_reader_truth_test.dart`, `test/bookmarks/reader_bookmark_geometry_test.dart`, `test/mushaf/reader_night_test.dart`) run unchanged and green; then
  `lib/mushaf/index_screen.dart`: `actions` with the icon when `context.read<SearchService?>() != null`, which pushes `SearchScreen` and, when it returns a value, pops the index with that value unchanged.
  Check `git status` and `git log -- lib/mushaf/index_screen.dart` first (spec FR-001, FR-003, FR-010, FR-030, SC-006; research D4, D10)
- [x] T046 [US4] Sweep (test-only; it should pass at once): `test/search/reader_search_leave_test.dart` with a wird at page 50: open search from the index and close it with back (twice: with a query typed and
  without) and 6 of 6 are unchanged: the page, the zoom, whether the bars are shown, the wird's position, the saved last viewed page, the settings table; typing, scrolling the results and leaving changes
  **no** table (compare every row of the database before and after); a result chosen on page 300 shows it in browse mode with the wird still on 50 and the last viewed page 300 (US4 scenarios 1-2, SC-007)
- [x] T047 [US4] Geometry after the feature, test-only: re-run `test/search/search_baseline_test.dart` (T001) and add `test/search/reader_search_geometry_test.dart`: the pager's, lines' and words' rectangles of the
  reader on pages 42 and 293 at 412 x 915 are **equal to the T001 numbers** with the feature present, with a found ayah highlighted and after it is cleared, in both looks; `test/mushaf/
  page_layout_invariance_test.dart`, `page_layout_both_looks_test.dart` and `test/bookmarks/reader_bookmark_geometry_test.dart` pass unchanged (spec FR-018, FR-030, SC-008; Constitution I)

---

## Phase 7: User Story 5 - Quick while I type, and clear when there is nothing to show (Priority: P2)

**Goal**: every state says what it is, a late answer never wins, and a failed preparation never breaks anything else.

**Independent test**: `test/search/search_states_test.dart`, `search_stale_test.dart`.

- [x] T050 [US5] Test-first: `test/search/search_states_test.dart` (red; the screen over a fake `SearchService` whose phase and answers the test controls): two or more letters with the service
  `preparing` show the surah rows (if any) **and** the one line «جارٍ تجهيز البحث في الآيات» (no ayah heading); the ayah rows appear by themselves when it becomes `ready`, for the text in the field **now**;
  `failed` shows the line «تعذّر تجهيز البحث في الآيات» and the button `search-retry` «إعادة المحاولة» (48 px high), the surah rows still work, tapping it runs `retry` and the rows appear
  when it succeeds, and a second failure shows the line again; ready with nothing in either group shows «لا توجد نتائج» and under it «جرّب كلمة واحدة أو كلمات أقل» and **no heading**; ready with a surah
  match and no ayah shows only the surah group (no «لا توجد نتائج»); a query with **no Arabic letter** (`123`, `abc`, `﴿ ﴾`, spaces, only tashkeel, only tatweel) shows the hint line and no error;
  one letter shows the need-two line also when no surah matched; nothing in these states is red, an error dialog or a snack bar; then the states in `search_screen.dart` (spec FR-002, FR-009, FR-014, User Story 5
  scenarios 1-4, 6, 7; contracts/ui.md "States")
- [x] T051 [US5] Test-first: `test/search/search_stale_test.dart` (red; the screen over a fake service with delayed answers, fake time): typing quickly `ر`, `رح`, `رحم`, `رحمن` with answers arriving
  in the order 3, 1, 4, 2 leaves the list showing the answer to `رحمن` and no row of an older answer, ever; an answer that arrives after the screen was closed changes nothing and throws nothing; opening
  search while the preparing of an earlier closed search is running does not start it again (the service's `prepare` count stays 1) and the screen shows «جارٍ تجهيز البحث في الآيات» until it ends; the
  results are on screen within one frame of the answer; then fix `search_screen.dart` or `search_session.dart` only where the test finds a defect of T010/T020/T030 (spec FR-022, FR-023, User Story 5
  scenarios 3 and 5; research D5)
- [x] T052 [US5] Test-first: `test/search/search_trace_test.dart` (red): `SearchTrace.prepareLine(1200, 140)` is `SEARCH prepare ms=1200 slices=140`, `queryLine(6, 48, 5)` is `SEARCH query len=6
  ayat=48 ms=5`, `benchLine(3, 1746, 7)` is `SEARCHBENCH q=3 ayat=1746 ms=7`; `SearchTrace.enabled` and `bench` are false in tests; `benchQueries` has **20** entries: ten one-word, five phrases, `ال`,
  2:282 pasted whole, three that match nothing (SC-004); nothing is printed when disabled; no line contains the text of a query (only its length); then `lib/search/search_trace.dart` and the two guarded
  calls in `search_service.dart` and `search_screen.dart` (from the field change to the frame after the results were built; with `bench`, the 20 queries run through `SearchSession` when the screen opens)
  (spec SC-004, SC-005; research D9; Constitution IV). **Done in two parts:** `search_trace.dart` (with `SearchTrace.emit`, the one place that prints, and the 2:282 query kept word for word as stored, checked by the test) and the
  service's `SEARCH prepare` line (`SearchService(trace:)`, default `SearchTrace.emit` only when `SearchTrace.enabled`) are committed with this task's test; **the screen's two guarded calls are made in `search_screen.dart` by the screen's own
  window** (`if (SearchTrace.enabled) SearchTrace.emit(SearchTrace.queryLine(length, total, ms))` for each query, and under `SearchTrace.bench` the 20 `benchQueries` through `SearchSession` with `SearchTrace.benchLine`), before T060
- [x] T053 [US5] Test-first: `test/search/search_state_kept_test.dart` (red): with a query typed and results scrolled, rotating the phone (portrait to landscape and back, `t.view.physicalSize`) keeps the
  query, the same rows and the **scroll offset**; a lifecycle trip (`paused`, `resumed` through `handleAppLifecycleStateChanged`) keeps them; closing and opening search again starts **empty** (no memory
  of the last query: spec Clarifications, FR-017); then fix `search_screen.dart` only if the test finds a defect (the state is in the screen's `State`, the list has a `ScrollController` it owns) (spec FR-017,
  FR-029)
- [x] T054 [US5] Sweep (test-only): `test/search/search_privacy_test.dart`: reads every file of `lib/search/` and asserts it imports no `wirds/`, `backup/`, `reminders/`, `dart:io`, `package:drift`,
  `path_provider`, `shared_preferences`, `http` or any package other than `flutter`, `material_ui` and `provider`, and imports nothing of the tafsir, translation or word-meaning code (`ayah/ayah_repository.dart`, `ayah/ui/tafsir_view.dart`, `translation_view.dart`, `meanings_view.dart`; only `ayah/ayah_ref.dart` and `ayah/ui/reading_text.dart` are allowed from `lib/ayah/`; FR-020), and has no `File(`, `Directory(`, `HttpClient`, `Socket` or a `print` / `debugPrint` outside a
  `SearchTrace.enabled` guard; that the pubspec, the lock file, the manifest and the assets are not changed by this feature is checked by `git diff --stat` in T060; typing 20 queries and choosing a surah result and an ayah result changes only the saved last viewed page (database rows compared) (spec FR-017, FR-021, SC-010; research D12)

---

## Phase 8: User Story 6 - Comfortable in both looks, at every size, for everyone (Priority: P2)

**Goal**: the quality bars of features 003, 004 and 006 to 008 hold on the new screen.

**Independent test**: `search_states_look_size_test.dart`, `search_reading_size_test.dart`, `search_semantics_test.dart`.

- [x] T055 [P] [US6] Test-first: `test/search/search_states_look_size_test.dart` (red): the **36 combinations** of SC-008 (both looks, reading sizes 80, 100, 150, screens 412 x 915 and 320 x 640 with `textScale: 2.0`, the
  states results (`قل هو الله احد`), `لا توجد نتائج` (`ذو القرنين`) and `جارٍ تجهيز البحث` (a service that stays `preparing`)): no overflow exception, `contrastIssues(t)` empty (text 4.5:1 including the emphasised
  words on `look.background`, the headings, the lines, «…»; icons 3:1), every target (`open-search` is T045's, here `search-clear`, a result row, `search-retry`) at least 48 x 48, the field fully visible with
  the keyboard inset simulated (`t.view.viewInsets`) and the list scrolling, no colour literal in `lib/search/` (a source check: no `Color(0x` and no `Colors.`), emerald and night each with no bright fill under night
  (`brightFills` as `test/look/theme_only_screens_night_test.dart` does); then fix `search_screen.dart` and `search_rows.dart` where a combination fails (spec FR-024, FR-025, SC-008)
- [x] T056 [US6] Test-first: `test/search/search_reading_size_test.dart` (red): at 80, 100 and 150% the snippet's Quran words are drawn at 20 x the factor in `AmiriQuran` (`TextStyle.fontSize` 16, 20, 30) and the
  row title, the headings and the lines keep the system font only; a system font of 2x with 150% is capped at 3x in the snippet (`ReadingScope`) and is not capped in the title; changing the reading size
  while search is open (`setSize`) redraws the snippet; the family is the bundled `AmiriQuran` (no new font in `pubspec.yaml`) (spec FR-012, FR-026)
- [x] T057 [US6] Test-first: `test/search/search_semantics_test.dart` (red): the field has the label «ابحث عن سورة أو آية», the clear button «مسح», each group heading is a header with «السور، عدد النتائج N» /
  «الآيات، عدد النتائج N» (the visible «السور · N» excluded), a surah row is one button labelled «سورة {name}، صفحة N», an ayah row one button «سورة {name}، آية N، صفحة N» followed by the snippet's words **without «…»**,
  the lines are plain text and «إعادة المحاولة» a button; the order is field, clear, surah heading, its rows, ayah heading, its rows, the more-line; the **announcement**: typing letter by letter sends **one**
  `SemanticsService.sendAnnouncement` after 700 ms of quiet (record it with a `SemanticsService` handler), with the two heading labels or «لا توجد نتائج», and none when nothing changed or after the screen is
  closed; then pass `onAnnounce` (a call of `SemanticsService.sendAnnouncement`) from `search_screen.dart` to the `SearchSession`, whose `AnnouncementGate` it feeds, and add the `Semantics` to `search_rows.dart` (spec FR-027, US6 scenario 4; research D13)

---

## Phase 9: Phone, polish and the owner

- [X] T060 The measurement build compiles and nothing outside the feature changed: `flutter build apk --release --dart-define=SEARCH_TRACE=true --dart-define=SEARCH_BENCH=true
  --dart-define=FRAME_TRACE=true` succeeds (no install); `git diff --stat` of the feature's commits shows **no change** to `pubspec.yaml`, `pubspec.lock`, `assets/`, `android/` and no file outside
  `lib/search/`, `lib/mushaf/index_screen.dart`, `lib/mushaf/reader_screen.dart`, `lib/mushaf/page_viewport.dart`, `lib/app.dart`, `lib/main.dart`, `test/search/`, `test/support/search_harness.dart` and
  `specs/011-surah-ayah-search/`; note the release APK size next to the previous release build in research.md D9 (spec FR-021, SC-010; plan Technical Context)
  **Done 2026-11-21**: the build with `--dart-define=SEARCH_TRACE=true` (the owner's install; no SEARCH_BENCH or FRAME_TRACE) compiled; no change to `pubspec.yaml`, `pubspec.lock`, `assets/`, `android/` and no file outside the list; APK 179,325,300 bytes against 179,095,844 before (+0.22 MB), recorded in research.md D9.
- [X] T061 **[PHONE]** First use, speed and memory (SC-004, SC-005, FR-022): install the build of T060 only with the owner's approval, then follow quickstart.md "On the phone" steps 1-4: `SEARCH prepare ms`
  (**target under 2,000**), the 20 `SEARCHBENCH` lines (**each under 300 ms, the median under 100**), the frame trace around the preparation (**none over 100 ms**), `dumpsys meminfo app.hafiz.mushaf` before
  and after (**at most 25 MB more**), 5 launches to the first Mushaf page against 5 of the build before the feature (not longer), and a few page turns after search was used. Write the table into research.md
  D9 "Phone results" and apply D9's decision rule: prepare over 2 s means T062; a slice over 16 ms or a frame over 100 ms means smaller slices; a query over 300 ms means look at which rule costs first. If
  the owner declines, write that in D9 and leave the laptop numbers as the only ones (spec SC-004, SC-005; research D5, D9)
  **Partly done 2026-11-21, the owner's own use**: prepare 179 ms (under 2 s), every query 19 to 41 ms (under 300 ms); the bench lines, the frame trace, the launch comparison and a controlled memory difference were not measured. Table in research.md D9 "Phone results".
- [X] T062 **[CONDITIONAL on T061: the first use is over 2 s]** The generated index of research D1 as the fallback: `tool/build_search_index.py` (Python, in the style of `tool/build_ayah_assets.py`) writes
  `assets/ayah/search/index.txt` with the **same** folding as `prototype/match_rules.py`; test-first `test/search/search_index_file_test.dart` recomputes the file from the stored text with the **Dart** folding and
  compares byte for byte (the drift guard of D1 rationale 2) and checks the file's size (at most 0.8 MB), the validation of data-model.md and that a damaged file fails the validation instead of serving; `AyahIndexBuilder`
  reads the file instead of folding (the stored words are still loaded for the snippets); the build gate of Constitution I stops the build on a failed validation; add the asset to `pubspec.yaml` (a one-line edit, with the
  owner told: Constitution VIII); re-run T061. Dropped if T061 meets 2 s (spec SC-005, FR-019, FR-021; research D1)
  **Not needed**: the first use took 179 ms on the phone (research.md D9).
- [X] T068 Run `flutter analyze` (no issues) and `dart format --set-exit-if-changed` on the feature's files only; check by hand that `git diff` of the feature touches no file outside the list of T060 (Constitution IX)
  **Done 2026-11-21**: `flutter analyze` no issues; `dart format` clean on the feature's files; the feature touches no file outside the list of T060.
- [X] T069 Run the **whole** suite once: `flutter test`; record the counts in the commit message; the baselines of T001 and the geometry tests of T047 and of features 003, 004, 006 and 010 equal; the three tests
  that open the index (`reader_screen_test`, `theme_only_screens_night_test`, `tips_reader_truth_test`) green (spec FR-030, SC-009; Constitution IX)
  **Done 2026-11-21**: the whole suite, 2,067 tests passed, 0 failed (before the second release build); the baselines of T001 and the geometry tests equal.
- [X] T070 **[OWNER]** Ask the owner to confirm every Arabic string of `lib/search/search_strings.dart` one by one (quickstart question 1), change the ones he rejects (each change re-runs T002 and T055-T057) and
  remove the word «proposal» from the header of the file only for the confirmed ones; record the confirmation in the commit message. **The feature is not done before this** (spec FR-028; Constitution VI)
  **Done 2026-11-21**: the owner read the strings on the screen of the build on their phone and answered «موافق على كله»; every doc comment of `lib/search/search_strings.dart` now says confirmed by the owner and `search_strings_test.dart` pins that.
- [ ] T071 **[PHONE]** The owner's check with the owner present (quickstart "On the phone" step 5): five surahs and five ayat of his choosing typed the quick way with the phone in airplane mode (SC-011), rotation with a
  query typed, a result on another page, on the same page, in wird mode and in browse mode, 150% and landscape with the ayah in view, both looks, TalkBack; ask the remaining questions of quickstart.md (emphasis, «مئة»,
  the same-page rule); **the feature is done only after this and T070** (Constitution IX; spec SC-006, SC-007, SC-010, SC-011)
  *2026-11-21: the owner tried the search on the phone and said it works («تمام وشغّال»). The airplane-mode run, TalkBack and the quickstart questions (emphasis, «مئة», the same-page rule) were not asked in detail: this task stays open until the owner does or waives them.*
- [ ] T072 Tick the tasks, copy the final phone numbers into research.md D9, re-run the requirements checklist `checklists/requirements.md` with the reviewer (it is theirs to mark), and write the hand-over in the last
  commit message: the numbers of T061, the answers of T070 and T071, anything left

---

## Dependencies and order

- **After feature 010**: every task of this feature comes after feature 010's tasks that touch the same files (`reader_screen.dart` above all). T001-T039 touch no file that 010 edits and can start while 010 is open;
  **[R4] (T041-T043) waits for 010's R1-R3 to be committed**.
- T001 first (before any edit of `lib/`). T002, T003 are independent new-file tasks. T004 needs T003. T005 needs T004. T006 needs T005. T007 needs T003. T008 needs T005 (matched flags). T009 needs T004 and T005.
  T010 needs T007 and T009.
- T020 needs T002, T007, T010. T030 needs T008, T020. T035 needs T030. T040 needs nothing of the screen (it needs only the `PageViewport` file free).
- T041 needs 010's windows (not T040); T042 needs T041; T043 needs T040 and T041. T044 needs T009. **T045 needs T020, T030, T041, T042, T043 and T044.** T046 and T047 need T045.
- T050 needs T030 and T010; T051 needs T050; T052 needs T009 and T020; T053 and T054 need T030. T055 needs T030 and T050; T056 needs T030; T057 needs T030 and T010.
- T060 needs T045, T052 and everything of the code. T061 needs T060 and the owner. T062 only if T061 says so. T068, T069 need all code tasks. T070 needs T055-T057 (the strings are final). T071 needs T061 and T070. T072 is last.

## Parallel opportunities

T002 and T003 (two files); T007 and T008 after T005 (two files); T040 (a different file) against T020-T035; T055, T056, T057 (three test files over the finished screen).

## Implementation strategy

**MVP is Phases 1-6** (T001-T047): the search screen finds a surah or an ayah, and the reader shows it on its page, highlighted and in view, with nothing else of the reader moved. Phase 7 makes the states and the speed
honest, Phase 8 proves the quality bars, Phase 9 measures on the phone and asks the owner. Every task is one commit that holds its own test; the suite is green after each. The pure core (T003-T008) is finished
and measured against the Python reference before any widget exists, so the part that is hard to get right is settled on real data first.

## Summary

| | Count |
|---|---|
| Tasks | 37 (T001-T010, T020, T030, T035, T040-T047, T050-T057, T060-T062, T068-T072) |
| Per story | Setup 2, Foundational 8, US1 3 (T020, T044, T045), US2 1, US3 1, US4 6 (T040-T043, T046, T047), US5 5, US6 3, Phase 9 8 |
| Touching `lib/mushaf/reader_screen.dart` (window **[R4]**) | **T041, T042, T043** (3) |
| Other edits of existing files | T040 `page_viewport.dart`, T044 `app.dart` + `main.dart`, T045 `index_screen.dart` |
| Phone tasks (owner present) | T061, T071 (and T062's re-run if it is built) |
| Owner task | T070 |
| Conditional | T062 |
