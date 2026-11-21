# Research: Surah and Ayah Search (feature 011)

Written on 2026-11-21 after reading `lib/mushaf/index_screen.dart`, `reader_screen.dart` (working tree with other sessions'
uncommitted edits; line numbers drift, so none are quoted), `reader_controller.dart`, `page_viewport.dart`, `page_scale.dart`,
`mushaf_page.dart` (read only), `mushaf_page_card.dart`, `mushaf_repository.dart`, `models.dart`, `lib/ayah/*`
(`ayah_ref.dart`, `ayah_repository.dart`, `ui/reading_text.dart`), `lib/app.dart`, `lib/main.dart`, `lib/theme.dart`,
`lib/settings/text_size*.dart`, the tests that touch the index screen (`test/mushaf/reader_screen_test.dart`,
`test/look/theme_only_screens_night_test.dart`, `test/onboarding/tips_reader_truth_test.dart`,
`test/bookmarks/reader_bookmark_geometry_test.dart`) and the test helpers in `test/support/`. The real bundled data was
measured with a Python reference (`specs/011-surah-ayah-search/prototype/match_rules.py`, kept in the repository, re-run
for every number below) and with a throw-away Dart benchmark compiled with `dart compile exe` (the same AOT runtime family
as a Flutter release build) written in the session's scratch folder, not in the repository. Nothing was run on a phone.

**How to read the numbers.** Counts (ayat found, words, characters, bytes) are exact and do not depend on the machine.
Milliseconds are from the development laptop (Dart 3.14 AOT, other agents were running tests, so a figure moves by about
30% between runs); they compare things measured in the same run and are **not** predictions for the phone. Where a phone
number decides something, the plan says so and a **[PHONE]** task measures it (D9).

## D1. Where the text that is searched comes from: normalise the 114 files at first use (no generated index file)

**Decision**: when search is opened for the first time in a run, the app reads the 114 files `assets/ayah/text/NNN.json`
(the stored text, already bundled for the ayah menu and sharing), decodes each, folds every word with the rules of D2 and keeps
in memory (a) the folded text of the 6,236 ayat in 8 chunks, (b) the stored words of each ayah for the snippets (D3). It runs on
the UI isolate in slices of at most about 8 ms (D5), never at launch and never while the reader is used (FR-022). **No file is
generated and no asset is added.** If the phone shows the first use takes more than 2 s (SC-005), the conditional task
**T062** builds the generated index of the alternative below instead; nothing else in the plan changes.

**Evidence** (real data, laptop):

| Quantity | Measured |
|---|---|
| Stored text, 114 files | 1,503,411 bytes on disk (6,236 ayat, 77,432 words); 305,300 bytes deflated |
| Folded text (rule D2, ayat joined by a line break) | 413,092 characters = **748,753 bytes** UTF-8, **184,706 bytes** deflated (`gzip -9`), 0 stored words fold to nothing |
| Cost of a generated index file | +0.75 MB raw, about +0.18 MB inside the APK, against the 2 MB cap (FR-021): 9% of the cap; **size is not the problem** |
| First use at run time, normalise at first use (AOT) | read 114 files **16 ms**; `jsonDecode` 114 files **12-15 ms**; fold all words **27-30 ms** with a code-unit table (49-69 ms with a `Map` and `runes`); build in all about **55-100 ms** |
| First use with a generated index (AOT) | read and decode the folded file **7.6 ms**, but the stored words are still needed for the snippets (below) |
| Memory kept after preparing | folded text 413k UTF-16 chars = 0.83 MB; stored words of 6,236 ayat about 1.7 MB; tables 0.05 MB: **about 2.6 MB**, against the 25 MB of FR-022. The benchmark process went from 10 MB to 43 MB resident while it decoded all files in one go (garbage, not held); the sliced build of D5 decodes one surah at a time |

**Rationale**:

1. *Principle I.* Generated Quran data must be validated and a failed validation must stop the build. A generated index is a
   second copy of the Quran text on disk; it needs a Python tool, a committed artefact and a build gate, and it adds a place
   where the Quran's letters can drift. An index made in memory from the stored text by the **same Dart code that folds the
   query** has no such copy, and its validation (114 surahs, 6,236 ayat, the same ayat per surah as the Mushaf's data, one
   entry per ayah, every stored word present once and in order, no word folding to nothing) runs in `flutter test` over the
   real assets (FR-019 allows "a test that the build runs") **and** at every preparation at run time (a failed check puts the
   ayah group in the «تعذّر تجهيز البحث» state instead of showing wrong results). See Complexity Tracking in plan.md.
2. *Drift.* With a generated file there are two implementations of the folding rules (the Python tool and the Dart query
   folding); one differing character makes the search miss silently. One implementation cannot drift.
3. *The saving is small.* A generated file removes only the folding (27-30 ms of AOT time, about 0.15 s on a phone) because the
   stored words are still needed: the snippet of a row must be the stored words character for character (FR-012), and 100 rows
   can come from 100 different surahs, which `AyahRepository`'s cache of 3 surahs would decode again on every scroll.
4. *Time.* Even at 5 times the laptop's time plus 114 asset reads (a platform-channel call each) the estimate is under 1.2 s
   against the 2 s of SC-005. It is an estimate: **T061** measures it and decides T062.
5. *No launch-time work (FR-022).* The service object is created at launch (no I/O in its constructor); the first read happens in
   `SearchScreen.initState`. Opening the index does not start it.

**Alternatives considered**:

- *A generated `assets/ayah/search/index.txt` with a Python tool, a build gate and a Dart comparison test.* Rejected for
  rationale 1-3. It stays as the conditional fallback T062 (the Dart test that recomputes the file from the stored text with
  the Dart folding and compares byte for byte makes the drift of rationale 2 visible).
- *Reading each surah file when a result needs it (no stored words in memory).* Rejected: up to 100 distinct surahs on one
  screen, a 3-surah cache, and a decode of 15-160 KB per row on every scroll.
- *Decoding in `compute`/`Isolate.run` (as `AyahRepository` does for texts above 25 KB).* See D5: not needed for 0.1 s of
  work that can be sliced, and it would make every widget test use `runAsync`.
- *`assets/ayah/text` re-read by `AyahRepository`.* Its cache holds 3 surahs and it is not made for 6,236 ayat; the search
  keeps its own structure and leaves `AyahRepository` unchanged (Constitution I: the existing text paths are not touched).

## D2. The matching rule (normalisation, the optional seat letter, the pattern)

**Decision**: the reference is `specs/011-surah-ayah-search/prototype/match_rules.py`; the Dart code in `lib/search/arabic_fold.dart`
ports it one to one and every number below is a test (T003-T006).

**The stored side** (`ArabicFold.word`), one stored word at a time; the words of an ayah are folded one by one and joined by
one space, so word *k* of the folded ayah is word *k* of the stored ayah:

| Stored character | Becomes | Why |
|---|---|---|
| `ا` and `أ إ آ ٱ` (U+0627, 0623, 0625, 0622, 0671) | `ا` | the four alef forms are one letter (FR-006) |
| `ؤ` (0624) | `و` | a hamza on a waw seat is a waw in what people type («مومن») |
| `ئ` (0626) | `ي` | same, for the yeh seat |
| `ى` (0649), `ی` (06CC) | `ي` | FR-006; the Persian yeh and kaf are folded for pasted text |
| `ة` (0629) | `ه` | FR-006 |
| `ک` (06A9) | `ك` | pasted text |
| `ء` (0621) and the hamza signs `ٔ ٕ` (0654, 0655, 495 and 14 times, on a tatweel) | **`ء` kept, a SOFT character** | a hamza with no seat letter: it may be skipped or matched (below) |
| `ٰ` (0670 dagger alef, 9,726 times) | **`ٰ` kept, a SOFT character** | the Mushaf's small alef: it may stand for a typed `ا` or be skipped |
| `ۧ` (06E7 small high yeh, 38 times) | `ي` | a real yeh written small (إبراهيم, النبيين) |
| `ۨ` (06E8 small high noon, once, 21:88) | `ن` | a real noon written small |
| every other letter (`ب ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ف ق ك ل م ن ه و ي`) | itself | |
| tashkeel (064B-0653, 0656-065F), the small letters of the pronouns `ۥ ۦ` (06E5, 06E6), the Quranic marks (06D6-06E4, 06E9-06ED), `۞ ۩`, tatweel, the spaces inside a word («۞ إِنَّ», «إِلۡ يَاسِينَ»: 209 words) | nothing | FR-006 |

**The query side** (`ArabicFold.query`): the same folding, except that (a) a typed `ؤ` and a typed `ئ` become two private
markers `SEATW` and `SEATY` (never mixed with `و`/`ي`), (b) a typed dagger, a typed `ء`, a mark, tatweel and an invisible
control (U+200B-200F, FEFF) vanish, (c) whitespace and any other sign (digits, Latin letters, `﴿ ﴾ ۝`, punctuation) is a word break,
(d) breaks are collapsed and trimmed. **Letters of the query** = the characters that are not a break. Fewer than two letters:
the ayah group is not searched (FR-009); no letter at all: nothing typed.

**The pattern** (`ArabicFold.pattern`), built from the folded query; *SOFT* is `[ٰء]`:

| Query unit | Pattern |
|---|---|
| a letter that is not `ا`, `SEATW`, `SEATY` | the letter, then `SOFT*` |
| `ا` | `(?:ا\|وٰ\|ٰ)` then `SOFT*`: an alef, the `و` of «الصلوٰة», or the small alef itself |
| `SEATW` (typed `ؤ`) | `[وء]` then `SOFT*` |
| `SEATY` (typed `ئ`) | `[يء]` then `SOFT*` |
| a break | `[ٰء ]*` (a space, none, or soft characters around it: «يا ايها» finds the one word «يَٰٓأَيُّهَا», «الذين امنوا» finds «ٱلَّذِينَ ءَامَنُواْ») |

The whole folded text is searched as **chunks of ayat joined by a line break** (D3); no pattern contains `.` or `\s`, so a match
never crosses an ayah.

**The narrowing of the optional seat letter.** The first prototype let a typed `ؤ`/`ئ` be *optional* (`و?`, `ي?`) and deleted every
`ء` from the text. A typed `لؤلؤ` became «ل·ل», which is in `لِلَّهِ` and in 2,206 ayat. The rule above makes the typed seat
letter **mandatory but tolerant**: it must find a seat letter or a seatless hamza (what the Mushaf always writes where it
writes a hamza: `أ إ ؤ ئ ء` or a hamza sign), and the seatless hamza is kept in the text (as a soft `ء`) so it can be
matched. Typed without any hamza the word still matches (every `ء` is skippable). Measured on the real text (the prototype
prints this table; `--full` prints the last two rows):

| Typed | First prototype (seat letter optional) | This rule |
|---|---:|---:|
| لؤلؤ | **2,206** | **8** |
| رؤيا | 264 | 7 |
| سؤال | 43 | 1 |
| جزؤا | 45 | 6 |
| مئة | 568 | 10 |
| مؤمن | 241 | 200 |
| سئل | 534 | 82 |
| شيئا | 123 | 76 |
| شئ (a careless «شيء») | 1,605 | 456 |
| يستهزئون / يستهزؤون / يستهزءون | 14 | 14 |
| الملائكة, جزاء, ءامنوا, امنوا | 53, 45, 266, 266 | 53, 45, 266, 266 |
| 15,122 distinct stored words typed carelessly: total ayat found | 326,070 | 308,124 (**5.5% fewer**, none finds more, **none finds nothing**) |

**Checks the Python reference passes today** (each becomes a Dart test): the 34 typed forms of the spec's table and the four
«exactly» rows (0 failures); the 12,472 self-match queries of SC-003, both forms (0 of 6,236 pasted and 0 of 6,236 careless fail);
the 570 surah-name queries of SC-001 (0 failures); «احمد» does not find 1:2; «ذو القرنين» finds nothing and «ذي القرنين» finds 18:83.

**Surah names** (`ArabicFold.surahKey` and `searchSurahs`): the name is folded like a stored word but with `ء` and `ٰ` removed and `ؤ`/`ئ`
as `و`/`ي`; the query is folded the same way (a typed `ؤ` is `و`, `ئ` is `ي`); a leading word «سوره» (folded «سورة») of the query is dropped when
something follows; the leading `ال` is dropped from the query and from the name when something remains. A name matches when the
query occurs in the name; rows are ordered equal, then starts with, then contains, then surah number. No two names are equal
after dropping `ال` (checked), so «the name that equals what was typed is the first row» always names one surah.

**Known limits** (not requirements of the spec; listed for the owner): (1) «النبيئين» (the old spelling with a hamza the
Hafs Mushaf does not write) finds nothing, as «النبيين» is the Mushaf's word; (2) «مئة» (a standard spelling) does not find
«مِاْئَةَ» because the Mushaf writes a silent alef (an `ا` with sukun, 3,722 times in all, mostly the alef after the plural
waw); making that alef soft would turn «مئة» from 10 noisy ayat into 17 including the real ones, a one-line change in the folding
if the owner wants it; (3) digits, Latin letters, presentation forms (`ﷲ`, `ﻻ`) and alternative surah names are not understood
(spec Assumptions).

**Rationale**: it passes every row and every count the spec asks for, it is the narrowest rule that does (a typed letter always
has to find a letter), and it is implemented as one `RegExp` per query over a few large strings, which the benchmark shows is
fast enough (D5). **Alternatives considered**:

- *The first prototype's optional seat letter*: 2,206 ayat for «لؤلؤ» (above).
- *Keeping the stored `ؤ`/`ئ` apart from `و`/`ي` so that a typed `ئ` can never match a real yeh* (the prototype variant `C2`):
  305,854 instead of 308,124 ayat in all (0.7% fewer), «مئة» 2 instead of 10 and **«شئ» 23 instead of 456**: the careless
  «شئ» for «شيء» (452 ayat) would stop finding anything. Rejected: one rare noise case is cheaper than losing a common careless form.
- *Two folded texts (with and without the small alef) and `indexOf`*: a phrase mixes both kinds in one match («ذلك الكتاب»: «ذَٰلِكَ»
  with a small alef the typed word does not have, «ٱلۡكِتَٰبُ» with one it does), so neither text alone finds it.
- *The consonant skeleton (drop every `ا و ي ء`)*: «احمد» would find «الحمد», which FR-007 forbids.
- *Unicode NFKC for pasted presentation forms*: Dart has no built-in normaliser and no package may be added (FR-021).

## D3. The data structures and where the code lives

**Decision**: a new folder `lib/search/` holds everything (nothing in `lib/mushaf/mushaf_page.dart`, which Constitution I protects, and
no change to `AyahRepository`, `ShareTextBuilder` or any text path):

| File | What |
|---|---|
| `arabic_fold.dart` | D2: `ArabicFold.word/ayah/query/pattern/surahKey`, pure, no Flutter import |
| `ayah_index.dart` | `AyahIndex` (the structure below) and `AyahIndexBuilder` (adds surah files, validates, builds) |
| `surah_search.dart` | `searchSurahs(surahs, typed)` pure |
| `snippet.dart` | `SnippetWords`, `snippetOf(...)` pure (D6) |
| `search_service.dart` | `SearchService`: the preparing state machine and `searchAyat` (D5) |
| `search_session.dart` | `SearchSession`: the screen's logic, the query, the view, stale answers, the announcement gate |
| `ayah_target.dart` | `AyahTarget(ref, page)`: what an ayah row hands back |
| `search_strings.dart` | every Arabic string, proposals (D8) |
| `search_screen.dart`, `search_rows.dart` | the screen and its rows |
| `search_trace.dart` | `SEARCH_TRACE` / `SEARCH_BENCH` build options (D9) |

**`AyahIndex`** (all in memory, built once per run, immutable):

| Field | Meaning | Size |
|---|---|---|
| `chunks: List<String>` | 8 strings; chunk *c* holds the folded text of ayat `800c .. 800c+799` in Mushaf order, each ayah followed by `\n` | 413k chars in all |
| `ayahStart: Int32List` (6,237) | offset of ayah *i* inside its chunk (the last entry closes the last chunk) | 25 KB |
| `surahFirst: Int32List` (115) | index of the first ayah of each surah (from the per-surah counts), so `i ↔ (surah, ayah)` | 0.5 KB |
| `stored: List<String>` (6,236) | the stored words of ayah *i* **joined by `\n`** (a stored word can contain a space, a line break cannot occur in one) | about 1.7 MB |

There is **no word table**. The *word map* back to the stored words is derived on demand for the at most 100 rows on screen:
split `stored[i]` on `\n` to get the stored words, fold each (`ArabicFold.word`), their offsets in the joined folded ayah are a
running sum (word + 1 for the space), the matches are `pattern.allMatches(foldedAyah)` and a word is *matched* when a match
overlaps its span. The folded ayah of a row is `chunks[c].substring(start, end - 1)`; the test checks it equals the words'
folds joined by one space for all 6,236 ayat (that equality is the 1:1 guarantee). The snippet is built from the **stored**
words only (FR-012).

**Rationale**: eight chunks make a scan sliceable (D5) without a second copy of the text; one `allMatches` per chunk is the fastest
way to scan (a call per ayah would cost 6,236 engine entries, a match per chunk stays inside the engine); a derived word map keeps
memory at 2.6 MB and removes a table that would have to be kept in step with the text. **Alternatives considered**: one 413k-char
string (no sliceable scan); a per-ayah `List<String>` of folded text and `hasMatch` each (6,236 calls, about 3 times slower in the
Python reference and no better in memory); a stored word-offset table (310 KB, one more structure to validate).

## D4. How a result reaches the reader, the highlight, and the ayah in view

**What exists today.** `ReaderController.jumpTo(int page)` is the only way in (index, go-to-page, bookmarks, notification
`page:N` all end in it): browse mode, no wird moves, `setLastViewedPage`. `IndexScreen` pops an `int` and `_openIndex` calls
`jumpTo` even when the page is the one shown; the go-to-page dialog does nothing in that case (`_askPage`). The long press already
has the highlight: `_highlightPage` + `_highlight` (the word ids of an ayah on a page, from `wordIdsOfAyah`) travel through the
kept pager instance to `_PageItem` and the card; `MushafPage` wraps those words in a `DecoratedBox` with `look.highlight`
(no geometry change). Every word is a `Text` with `ValueKey('w<id>')`. `PageViewport` owns each page's transformation
(`fits`, `scrollsVertically` inside a `SingleChildScrollView`, `pansBothWays` through an `InteractiveViewer`'s
`TransformationController`).

**Decision**:

1. *Carrying the ayah.* The search screen pops an `int` for a surah row (the index's own value: the reader treats it exactly as
   today) and an `AyahTarget(ref, page)` for an ayah row. `IndexScreen` pushes the search screen, and when it returns a value it pops
   itself with that value (so «search closes and the index it was opened from» and the reader sees one result). `_openIndex`
   becomes `push<Object>`; `int` → `jumpTo` (unchanged), `AyahTarget` → `_showFoundAyah`. `ReaderController` and its tests are not changed:
   `jumpTo(int)` is reused.
2. *`_showFoundAyah(target)`* (window **[R4]** of `reader_screen.dart`): if `target.page != _controller.page` call
   `_controller.jumpTo(target.page)` (browse mode, nothing else moves; FR-015); if it is the same page do not touch the mode
   (FR-016, the go-to-page rule). Then load the page's data (`MushafRepository.loadPage`, cached), take
   `ids = wordIdsOfAyah(data, ref)` (the part of the ayah on this page; an ayah that continues is highlighted on its first page only),
   set `_highlightPage = page`, `_highlight = ids` (a new `Set`), `_found = (ref, page)` and `_reveal = PageReveal(ids, ++token)`. The
   existing kept-pager check (`identical(_pagerHighlight, _highlight)`) rebuilds the pager once; nothing else rebuilds.
3. *Cleared on the next touch, turn or opened screen.* A `Listener(behavior: translucent, onPointerDown: ...)` around the body of the
   reader clears `_found` (sets `_highlight` empty, `_highlightPage` null, `_reveal` null) on **any** pointer-down (the page, a bar, the card:
   all are touches «on the reader»); `_onPageChanged(index)` clears it when the new page is not `_highlightPage`; the long-press menu
   replaces it with its own highlight and clears it as it does today when it closes; a notification tap or a go-to-page jump changes
   the page and so clears it. Opening the index, bookmarks, wirds or settings starts with a pointer-down on a bar, so it clears first.
   The `Listener` is not a gesture detector: it cannot take a tap from the page or the bars.
4. *In view.* `PageViewport` gets one optional parameter `reveal: PageReveal?` (`wordIds`, `token`). A new token makes it look for the
   words' render boxes under itself (a walk of its own element subtree for the `ValueKey('w<id>')` of the ids, once per token, retried for
   up to 60 frames because the page is built after its data and font load), then: **fits**: nothing; **scrollsVertically**: `Scrollable.ensureVisible`
   on the first word with `alignment 0.3`, no animation; **pansBothWays**: set its `TransformationController` to a translation that puts the
   union of the words inside the viewport with a 24 dp margin (the first word at the right edge when the union is wider than the screen, because
   reading starts at the right), clamped to `[viewport - content, 0]` like every other transformation of the widget. A page that is zoomed in is first
   put back to scale 1 (it is an arrival). **A rule of the owner's reading:** the *first line* of the ayah is always in view; the whole
   highlighted part is in view when it fits the viewport (it cannot when 2:282 is read at 150%: it is longer than the screen), so FR-013's
   «found ayah in view» is read as «its beginning, and all of it when the screen can hold it».
5. *What is not touched*: `mushaf_page.dart`, `mushaf_page_card.dart`, the page geometry, the pager's physics, `ReaderController`.

**Rationale**: it reuses the long-press highlight (the owner's decision: «the way the long-press highlight is drawn»), adds one `Listener`
(no rebuild, no layout), and puts the only new knowledge (where a word is) in the widget that already owns the transformation.
**Alternatives considered**: a new `ReaderController.jumpToAyah` (more state in a file the feature-010 windows also edit, for nothing the
screen cannot hold); passing the ayah through a side channel such as a `ValueNotifier` on `ReaderController` (hidden coupling);
`IndexScreen` popping a sealed class for every row (changes the index's existing contract and every test that reads it);
`GestureDetector` for the clearing (it would take the tap away from the page's bar toggle); computing the word's rectangle from the line
index (the line's words are laid out `spaceBetween` with real glyph widths, so only the render box knows); a `GlobalKey` per word (94 per page,
the page card is protected); `showOnScreen` for the pan case (`InteractiveViewer` moves its child with a `Transform`, it does not scroll).

## D5. Concurrency: no isolate, no debounce, a generation token

**Decision**: everything runs on the UI isolate in slices; a newer query cancels an older one at its next slice; nothing waits on a timer.

- *Preparing* (D1): per surah file, `loadString(path, cache: false)` (so the bundle does not keep a second copy of the raw text), decode,
  fold; after every ayah check a `Stopwatch` and yield with `Future<void>.delayed(Duration.zero)` when 8 ms have passed. The slowest whole surah
  (surah 2, 286 ayat) took 3.6-11 ms to fold on the laptop even with the slow folding, so a slice by the clock is about 8 ms plus one ayah there; on a phone at
  5 times the laptop's time a slice is still far under the 100 ms of FR-022 (a few frames at worst, none lost to a single long task). The yield function is
  a constructor argument so tests run at once.
- *Scanning* (D3): one `allMatches` per chunk, a yield between chunks, the first 100 ayat kept and the rest only counted (the heading shows the
  true total, FR-014). Measured (laptop, AOT, median / worst of 20): «الرحمن» 4.9 / 5.1 ms (48 ayat), **«ال» 11.2 / 11.5 ms (5,182 ayat)**,
  «الله» 5.6 / 7.3 (1,746), «يا ايها الذين امنوا» 6.5 / 7.0 (89), «ذو القرنين» 3.8 / 4.9 (0), the longest ayah pasted (2:282, 1,188
  characters) 2.4 / 2.6 ms, and the whole text 6,236 times with every ayah pasted in 25.4 s with a worst single scan of 10.9 ms. In the JIT test VM the
  figures are the same within 30%. A chunk is one eighth of that: about 1.5 ms here.
- *Stale answers (FR-023)*: `SearchSession` increments a `generation` on every change of the field; `searchAyat(q, isCurrent: () => gen == current)`
  stops at the next slice when it is false and returns null; the session also discards any answer whose generation is not current. When the
  index becomes ready the session runs the query that is in the field now.
- *No debounce.* A debounce timer adds its delay to every answer and SC-004 asks for a median of 100 ms; the slicing already makes a fast typist
  cheap (an abandoned scan costs one chunk). The one timer in the feature is the **announcement gate** (D13), which delays only what a screen reader says.
- *The surah group* is answered in the same frame (114 names, microseconds).

**Alternatives considered**: a long-lived worker isolate holding the index (a message per query; the stored words needed by the rows
copied back or fetched per row; every widget test needs `runAsync`; a lifecycle to manage) for a scan of 1.5 ms a slice; `compute` for the
build (as `AyahRepository` does for large texts): a copy of 1.5 MB in and 3 MB out, the same 100 ms of work, and widget tests that need real time.
**The phone decides**: **T061** reads the `SEARCH` trace and the frame trace; if a slice costs more than 16 ms or a frame goes over
100 ms, slices get smaller; an isolate is considered only if even a slice of one ayah is too slow, which the laptop numbers make improbable.

**Memory bound**: about 2.6 MB retained (D1) against the 25 MB of FR-022, plus the transient decode of one surah at a time (the biggest file,
surah 2, is 160 KB of JSON). A test bounds `AyahIndex.estimatedBytes`; **T061** reads `dumpsys meminfo` before and after.

## D6. The snippet, the emphasis and the type

**Decision**: a row's snippet is `snippetOf(storedWords, matched, fits)`: start with the first matched word, widen to the right and to the
left alternately by whole words while `fits(from, to)` says the run is at most **three lines**, stop when the next word does not fit, and mark
`cutBefore` / `cutAfter` where the window does not reach the ayah's ends («…» is drawn there, outside the stored words). `fits` is a
`TextPainter` layout with `maxLines: 3` in the row's width, the Quran font and the reading size; the fit is monotone in the window's length,
so a binary search (at most 7 layouts for 128 words) finds it, cached per (ayah, width, scale) in the row. A word wider than three lines does not
exist (the longest word is under 25 characters). If the whole ayah fits there is no «…». The words are drawn as one `Text.rich`: each stored word,
unchanged, then a space; a matched word has the emphasis style.

*Type*: `AmiriQuran` (the family `kQuranFont` already bundled for the basmala line, no new font), base size 20 times the reading factor of feature 003,
line height 2.0, through `ReadingScope` so size times system font is capped at 3x like the other reading texts; the rest of the screen follows the
system font only (FR-026). *Emphasis* (a proposal: colour and the look's accent): `look.accent` **and** `TextDecoration.underline` (2 px); the
contrast walk and a style test check both. **Bold** is not used by default because the Quran font has one weight, so the platform would
smear the marks of a synthetic bold; if the owner prefers bold, only `search_rows.dart` changes.

**Alternatives considered**: a character budget instead of a layout (it is wrong at 80% and at 150% and with a 2x system font); `maxLines: 3` with
`TextOverflow.ellipsis` (cuts inside a word and loses the match, which FR-012 forbids); highlighting with a background paint (a colour only; the
non-colour cue of FR-011 is the underline).

## D7. Tests (Principle IX): what is pinned, in what order

Test-first for every contract; new tests go in `test/search/` (helpers in `test/support/search_harness.dart`); the tests of features 001 to 010
are never edited (FR-030: if a test is found that counts the index's app-bar buttons it is the one allowed edit; none was found: the three
that open the index only look for the title, the tabs and `surah-list`).

| Test file | Pins |
|---|---|
| `search_baseline_test.dart` | recorded **before any edit of `lib/`**: the rectangles of the index screen (title, tabs, `surah-list` rows 1-3, `page-field`) in both looks at 412 x 915 and 320 x 640 with a 2x font, and of the reader (`top-bar`, pager, lines and words of pages 42 and 293); must pass unchanged at the end (FR-030, SC-008) |
| `arabic_fold_test.dart` | the folding table of D2 character by character; query cleaning (digits, Latin, ornate brackets, invisible controls); `pattern` for the examples of D2 |
| `ayah_index_real_data_test.dart` | over all 114 files: 6,236 ayat, 77,432 words, per-surah counts equal to `meta.surahs`, no word folds to nothing, `folded ayah == words folded joined by one space` for every ayah, `meta.pageOfAyah` equals the page of the ayah's first word for all 6,236 (the page of FR-011), `estimatedBytes` bound |
| `ayah_search_table_test.dart` | all 34 typed forms of User Story 3 and the four «exactly» rows; «احمد» does not find 1:2; 2:282 pasted; «ذو القرنين» none |
| `ayah_search_self_match_test.dart` | SC-003: 12,472 queries (pasted, careless) each return their ayah |
| `ayah_search_narrowing_test.dart` | the table of D2: «لؤلؤ» at most 10, «رؤيا» at most 10, ... and that no query of the 15,122-word list finds nothing |
| `ayah_search_speed_test.dart` | SC-004's bound: 20 queries each under 1 s on the machine (they take about 10 ms), and the one-row cap: «ال» returns 100 rows and a total of 5,182 |
| `surah_search_test.dart` | SC-001: 570 queries; order equal, starts, contains; «سورة»; «ق», «ص» from one letter; «سبا / سبأ / سبإ» |
| `snippet_test.dart` | for all 6,236 ayat the snippet is a run of consecutive stored words, character for character, containing the first match, with `cutBefore/cutAfter` right; the longest ayah |
| `search_service_test.dart` | no read before `prepare`; once only; opened twice while preparing; failure then retry; a validation failure fails; slices yield; a stale scan returns null |
| `search_session_test.dart` | every state of contracts/ui.md; stale answers dropped with a delayed fake service; the field text is never changed |
| `search_screen_test.dart`, `search_states_look_size_test.dart` | the screen, the rows, the clear button, the states, **36 combinations** of SC-008, 4.5:1 and 3:1, 48 px, 320 dp with a 2x font, 80/100/150% |
| `search_semantics_test.dart` | labels, headings, the announcement once per settled change |
| `search_index_entry_test.dart` | the icon in the index app bar, nothing else of the index changed; the forwarding of the result |
| `reader_search_open_test.dart`, `reader_search_highlight_test.dart`, `reader_search_in_view_test.dart` | reader integration (D4): browse mode, wird unchanged, same page, highlight until touch/turn/open, in view at 80/100/150% and in landscape |
| `page_viewport_reveal_test.dart` | the new parameter alone |
| `search_ayah_group_test.dart`, `search_spelling_ui_test.dart`, `search_states_test.dart`, `search_stale_test.dart`, `search_trace_test.dart`, `search_state_kept_test.dart`, `search_reading_size_test.dart`, `reader_search_leave_test.dart`, `reader_search_geometry_test.dart` | the rest of the tasks' tests, one file per task of tasks.md (the table lists the main contracts, not every file) |
| `search_privacy_test.dart` | nothing written: the database before and after; `lib/search` imports no database, file, backup or network code and prints nothing outside `SEARCH_TRACE` |
| `search_wiring_test.dart` | `main.dart` and `app.dart` provide the service; creating it reads nothing (FR-022) |

The existing tests that open the index or the reader run again after every task that edits `index_screen.dart`, `reader_screen.dart`,
`page_viewport.dart`, `app.dart` or `main.dart`: `flutter test test/mushaf test/look test/bookmarks test/onboarding test/motion test/ayah test/settings`.

## D8. Strings are proposals until the owner confirms them (Constitution VI)

All Arabic strings of the feature are in `lib/search/search_strings.dart`, each with a doc comment saying it is a proposal and where it is shown,
exactly the list of the spec's Assumptions plus these that the design needs and the spec does not list (so they are proposals too): the row title
`«{name} · آية N»` and «ص N» (listed), the row's semantics labels (listed), and **no new visible text**. The announcement of a settled change reuses the
two headings' semantics labels or «لا توجد نتائج». One task writes the file (T002), one task at the end (T070) asks the owner to confirm every
string and the feature is not done before it. Numbers are Western digits, as the page number is.

## D9. The phone: measurement build, checks, and the fallback

Nothing here is run without the owner in that session; never unlock the phone, ask before sending input and before installing, change no
phone setting (as feature 010 D9).

- `--dart-define=SEARCH_TRACE=true` prints `SEARCH prepare ms=<t> slices=<n>` once and `SEARCH query len=<n> ayat=<total> ms=<t>` for each query (from the
  change of the field to the frame after the results were built); memory is read with `dumpsys meminfo`, not printed by the app.
  `--dart-define=SEARCH_BENCH=true` additionally runs the 20 queries of SC-004 through `SearchSession` when the search screen opens and prints
  `SEARCHBENCH q=<n> ayat=<total> ms=<t>`, because `adb input text` cannot type Arabic. Both are compile-time guarded, print to the log only,
  write no file and send nothing; in normal builds they cost nothing (as `FRAME_TRACE`).
- **T061** (first use, SC-004, SC-005, FR-022): build with the traces and the frame trace of feature 010, open search on the phone, read `SEARCH prepare`,
  the 20 `SEARCHBENCH` lines, the frame trace during the preparation, and `dumpsys meminfo app.hafiz.mushaf` before search and after the first result; launch
  time to the first Mushaf page 5 times against the build before the feature. **Decision rule**: prepare under 2 s and no frame over 100 ms: nothing more
  (T062 is dropped); prepare over 2 s: T062 (the generated index of D1); a slice over 16 ms or a frame over 100 ms: smaller slices; a query over 300 ms: look
  at which rule costs (D2) before touching the architecture.
- **T071** (the rest): airplane mode, a screen reader on, rotation, the owner types five surahs and five ayat of their choosing (SC-011), the look and size
  checks of FR-024 to FR-026 on the real screen, the page in view at 150%, back from search, the wird untouched.

### Phone results (2026-11-21, the owner's own first use of the build with `--dart-define=SEARCH_TRACE=true`)

Read from `adb logcat -d -s flutter:I` after the owner searched on the phone (read only; the lines carry numbers only, never a query):

| Line | Value | Bound | Verdict |
|---|---|---|---|
| `SEARCH prepare` (first use, folding the 114 files) | 179 ms, 1 slice | under 2,000 ms (SC-005) | met, T062 (generated index file) is NOT needed |
| `SEARCH query len=2 ayat=3608` | 28 ms | under 300 ms (SC-004) | met |
| `SEARCH query len=3 ayat=378` | 41 ms | under 300 ms | met |
| `SEARCH query len=4 ayat=29` | 39 ms | under 300 ms | met |
| `SEARCH query len=2 ayat=5182` (the worst case, «ال») | 19 ms | under 300 ms | met |
| `SEARCH query len=3 ayat=260` | 24 ms | under 300 ms | met |

Not measured (the owner was not asked to run them, and the build carried only `SEARCH_TRACE`): the 20 `SEARCHBENCH` lines, the frame trace around the preparation, five launches against the build before the feature, and a controlled memory difference (a `dumpsys meminfo` taken once after the owner's use shows 189 MB total PSS for the whole app, with no baseline to subtract). The release APK is 179,325,300 bytes with the trace flag against 179,095,844 before the feature: 0.22 MB more (FR-021 allows 2 MB). `pubspec.yaml`, `pubspec.lock`, `assets/` and `android/` are unchanged by the feature's commits, and no file outside the list of T060 was touched.

## D10. Wiring and the null convention

`MushafApp` gets `final SearchService? searchService` and, when it is not null, `ListenableProvider<SearchService?>.value(value: searchService)` (a plain `Provider` is refused in debug for a `ChangeNotifier`; the other optional notifiers of the app, `PdfJob?`, `TextSizeSettings?` and `AppLookSettings?`, are provided the same way; with none nothing is provided and `context.read<SearchService?>()` is null, so a service provided above the app by a test is not hidden by a null), as it does for `AyahRepository?`;
`main.dart` passes `SearchService(bundle: rootBundle, meta: mushafRepository.loadMeta)` (a constructor that reads nothing). **A null service means the index shows no
search icon**, so every existing test (they pass no service) sees the index exactly as it is today and the tests of this feature provide one. This is
the project's own convention for optional services (the ayah menu, the PDF strip, the page renderer). `app.dart` and `main.dart` are edited by other
sessions: the two one-line edits are their own task (T044), done after `git status` is clean for both files, with a wiring test in the style of
`frame_trace_wiring_test.dart`.

## D11. Coordination and risks

| Risk | Handling |
|---|---|
| `reader_screen.dart` is edited by the feature 010 windows R1-R3 (still open in the working tree) | all of 011's edits to it are one window **[R4]** (T041, T042, T043), after 010's tasks are committed and `git status` is clean for the file; the tasks of 011 come after 010 in the order of work |
| `app.dart`, `main.dart` are edited by other sessions | one small task each, checked first (D10) |
| `page_viewport.dart` is under the geometry baselines of features 003 and 004 | the new parameter is optional and acts only when given; the baseline tests must be equal before and after (T001, T047) |
| `PageViewport`'s retry of up to 60 frames keeps the frame loop running | it schedules a frame only while a reveal is pending, and gives up silently |
| `Listener` above the pager | adds no layout and no rebuild; `reader_rebuild_budget_test.dart` and `reader_narrow_listeners_test.dart` must stay green (they count builds) |
| A pasted 1,500-character query is a 22,000-character pattern | measured: the longest ayah (1,188 characters) 2.4 ms |
| The index shows a new icon in its app bar | the baseline test (T001) pins the rest of the screen; the title keeps its place or only loses width |
| `compute`/isolates are not used, so a future feature that needs them is not blocked | n/a |

**Not in this feature** (spec Assumptions): the tafsir, the translation, the word meanings, history, voice input, relevance ranking, a phrase across two ayat, a tip
about search, correcting how the index spells some surah names, alternative names, numbers («2:255»).

## D12. Privacy: searching never writes

`lib/search/` has no import of `wirds/`, `backup/`, `dart:io`, `path_provider`, a database or a network library; the query lives in a
`TextEditingController` and a `SearchSession`, both owned by the screen's `State` and gone when it closes; nothing is logged except under
`SEARCH_TRACE`, and then only the length of the query, never its text. The field uses `autocorrect: false`, `enableSuggestions: false` and
`enableIMEPersonalizedLearning: false` so the keyboard neither alters what was typed (FR-008) nor learns it. Choosing a result writes only the
last viewed page, exactly as the index does (FR-015).

## D13. Accessibility

Rows are one `Semantics(button: true, label: ...)` each with their children excluded, so a reader hears «سورة البقرة، آية 255، صفحة 42» followed by
the snippet's words (without «…»); a group's heading is `Semantics(header: true, label: 'السور، عدد النتائج N')`. **The announcement**: an
`AnnouncementGate` waits 700 ms after the last change of the results, then calls `SemanticsService.sendAnnouncement` once with the two
headings' labels (or «لا توجد نتائج»), and sends nothing if the text is the one it announced last; it is cancelled when the screen closes. The
traversal order is: field, clear button, the surah heading, its rows, the ayah heading, its rows, the line asking for more words.
