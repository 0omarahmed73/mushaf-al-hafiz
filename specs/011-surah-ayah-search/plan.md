# Implementation Plan: Surah and Ayah Search

**Branch**: `011-surah-ayah-search` (work stays on `main`) | **Date**: 2026-11-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/011-surah-ayah-search/spec.md`

## Summary

A search icon in the app bar of the index screen opens one screen with one field and two groups of results: the surah names (from one
letter) and the ayat (from two letters). The 114 names come from the Mushaf's metadata; the 6,236 ayat come from the stored text that is
already bundled (`assets/ayah/text/`, 77,432 words, 1.5 MB), which is **folded in memory at first use** into a comparison copy (research D1,
D2): the four alef forms are one letter, `ة` is `ه`, `ى` is `ي`, tashkeel, Quranic marks and tatweel vanish, the Mushaf's small alef is a soft
character that may stand for a typed `ا` or be skipped, and a hamza on a seat or on the line is matched by a typed hamza letter **mandatorily but
tolerantly** (this narrows the first prototype's optional seat letter: «لؤلؤ» 2,206 ayat to 8, D2). One `RegExp` per query scans 8 chunks of the
folded text; the first 100 matches in Mushaf order are shown, each as the surah's name, the ayah's number, its page and a snippet of its **stored**
words (character for character, in the bundled Quran font, at the reading size) with the matched words emphasised by colour and an underline; the
heading counts all matches. Work is sliced on the UI isolate (about 8 ms at a time, no isolate, no debounce, a generation token drops stale answers,
D5). A surah row returns its first page like the index; an ayah row returns an `AyahTarget` that the reader shows in browse mode on the page where the
ayah begins, highlighted the way the long press highlights until the next touch, turn or opened screen, and brought into view inside the page's own
viewport when the page is taller or wider than the screen (D4). No Mushaf page, line, font or text code changes; no package, no permission, no
table, no asset; every Arabic string is a proposal in one file (D8).

## Technical Context

**Language/Version**: Dart 3.14 / Flutter 3.50 (Android first)

**Primary Dependencies**: `package:material_ui`, `provider` (already used); **nothing new**, not even a dev package

**Storage**: none (no table, no setting, no asset, nothing in the backup; a query is never kept). The comparison copy lives in memory for the run
(about 2.6 MB), made on first use

**Testing**: `flutter test` with new files only (`test/search/`, helpers in `test/support/search_harness.dart`); real-data tests over the bundled
assets of all 114 surahs; a Python reference (`specs/011-surah-ayah-search/prototype/match_rules.py`) that every number of research D2 comes from; the
earlier features' tests unchanged; the phone check on the owner's phone <phone> only with approval

**Target Platform**: Android phone, portrait and landscape, RTL; the owner's phone <phone> (1080 x 2340)

**Project Type**: mobile app

**Performance Goals**: SC-004 (results within 300 ms of the last letter, median 100 ms; the whole-text scan takes about 5-11 ms on the laptop);
SC-005 (ayah text ready within 2 s on first use, no frame over 100 ms, at most 25 MB more, launch time unchanged); the whole-text scan under 1 s in
the unit test

**Constraints**: offline, no tracking, nothing stored; the Quran text, its order, the page and line distribution and `mushaf_page.dart` untouched;
the stored text is the only text ever shown; no new package, no permission, installed size +0 MB (limit 2 MB); earlier tests unchanged; nothing
overflows at 320 dp with a 2x system font; targets >= 48 dp; contrast 4.5:1 text, 3:1 icons in both looks; the tree is shared with other sessions
(explicit `git add`, one commit per task)

**Scale/Scope**: 11 new files in `lib/search/` (about 1,300 lines), 5 edited files (`index_screen.dart`, `reader_screen.dart`, `page_viewport.dart`,
`app.dart`, `main.dart`; the last two by one line each), about 30 new test files (one per task of tasks.md, research D7)

## Constitution Check

*GATE: passed before research and again after the design (constitution 1.3.0).*

| Principle | Check |
|---|---|
| I Quran text integrity | The stored text is read, never written, and is the only text shown (rows, snippets, page); the comparison copy is derived by fixed rules, never shown, shared or used by the pages, the ayah menu, the share text or the PDF (FR-018). `mushaf_page.dart`, `mushaf_page_card.dart`, `AyahRepository`, `ShareTextBuilder` and the page data are not edited; the highlight reuses the long press's and `PageViewport` gets one optional parameter that moves only its own transformation after arrival. The geometry baselines of 003, 004, 006 and 010 and the 604-page layout tests must be equal before and after (T001, T047, T069). The validation of the derived copy is a deviation in **timing**, see Complexity Tracking. **Pass with one recorded interpretation** |
| II Mushaf first | No new first screen and no change to launch; search is a screen reached from the reader (the index) and returning to it, back leaves the reader as it was; opening search reads nothing at launch. **Pass** |
| III Focus | A search inside the Quran text and the surah names only; no tafsir, translation or meanings are searched or shown (FR-020). **Pass** |
| IV Offline, private, free | No network, no analytics; a query is kept only in the open screen's memory and never stored, logged (the traces print a length, never a text, and only in builds made with an explicit option) or backed up; the keyboard is told not to correct or learn (D12). **Pass** |
| V Licensing | No external resource, no font, no package: `licenses.md` and About are unchanged. **Pass** |
| VI Arabic, RTL | Every string is Arabic, in one file, marked as a proposal; the owner confirms each (T070); none is machine-translated; page turning is untouched; the screen is RTL like the index. **Pass (the confirmation is a task)** |
| VII Reliability | Searching writes nothing; choosing a result writes the last viewed page exactly as the index does and moves no wird (FR-015, FR-016, tests); a failed preparation shows a line and a button and affects nothing else. **Pass** |
| VIII App size | +0 bytes of assets (unless the conditional T062 adds the generated index: at most 0.8 MB, about 0.18 MB in the APK), about 1,300 lines of code; 2.6 MB of memory while search has been used. **Pass** |
| IX Quality gates | Test-first (every contract has its test written red first, T001 pins the baselines before any edit); the pure logic (folding, matching, surah ranking, snippet, announcement gate) is separate from the widgets and unit-tested over the real data; `flutter analyze` clean and the whole suite once at the end (T068, T069); the real-device checks with numbers (T061, T071). **Pass** |

Coordination, not deviation: `reader_screen.dart` is also edited by feature 010's windows R1 to R3 and by sessions on 005 to 009; the three tasks of 011 that
touch it are one window marked **[R4]** after 010's (research D11). `app.dart`, `main.dart` and `index_screen.dart` get small additive edits.

## Project Structure

### Documentation (this feature)

```text
specs/011-surah-ayah-search/
├── spec.md
├── plan.md
├── research.md            # decisions D1-D13 with the measurements
├── data-model.md          # no stored data; the in-memory structures and the screen's state
├── quickstart.md          # automated checks and the phone procedure
├── contracts/
│   ├── ui.md              # the screen, its states, rows, semantics, sizes, looks
│   └── dart-interfaces.md # ArabicFold, AyahIndex, SearchService, SearchSession, AyahTarget, PageReveal, ...
├── prototype/
│   └── match_rules.py     # the reference of D2 (Python, not shipped; every number of D2 is printed by it)
├── checklists/
│   └── requirements.md    # spec quality (specify step)
└── tasks.md
```

### Source code (repository root)

```text
lib/
├── search/                        # NEW
│   ├── arabic_fold.dart           # folding of stored words, queries, names; the pattern (D2)
│   ├── ayah_index.dart            # AyahIndex, AyahIndexBuilder, validation (D3)
│   ├── surah_search.dart          # surah names: match and order
│   ├── snippet.dart               # whole-word window around the first match (D6)
│   ├── search_service.dart        # preparing (sliced), searchAyat (sliced), retry (D5)
│   ├── search_session.dart        # the screen's logic: generations, view states, announcement gate
│   ├── ayah_target.dart           # what an ayah row hands back
│   ├── search_strings.dart        # every Arabic string, proposals (D8)
│   ├── search_screen.dart         # field, groups, states
│   ├── search_rows.dart           # surah row, ayah row (snippet, emphasis, semantics)
│   └── search_trace.dart          # SEARCH_TRACE / SEARCH_BENCH (D9)
├── mushaf/
│   ├── index_screen.dart          # EDIT: the search icon (only when a SearchService is provided), forwards the result (T045)
│   ├── reader_screen.dart         # EDIT in one window [R4]: AyahTarget, highlight, clearing, reveal (T041-T043)
│   └── page_viewport.dart         # EDIT: optional PageReveal (T040)
├── app.dart                       # EDIT: ListenableProvider<SearchService?> (T044)
└── main.dart                      # EDIT: passes SearchService(...) (T044)

test/
├── search/                        # NEW, one file per contract (research D7)
└── support/search_harness.dart    # NEW: a shared real AyahIndex, a service over it, pump helpers
```

**Structure Decision**: everything about search is one folder with pure logic (folding, index, surah ranking, snippet) apart from the widgets, so
it is unit-tested over the real data without a widget; the reader gets the smallest edits that receive a result, highlight it and bring it into
view (D4); the service is provided like the other optional services (D10).

## Stages

| Stage | What | Gate to the next |
|---|---|---|
| **0 Baseline** | T001 records the rectangles of the index and the reader on the unchanged code | green on the unchanged code, committed before any edit of `lib/` |
| **A The pure core** | T002 strings; T003-T008 folding, index, ayah search, surah search, snippet (all over the real data) | the table, the «exactly» rows, 12,472 self-matches, 570 names, the narrowing numbers: all green |
| **B The service and the session** | T009 service, T010 session | stale answers dropped, failure and retry, nothing read before first use |
| **C The screen (US1, US2, US3)** | T020 field and surah group, T030 ayah group, T035 spelling through the field | the surah and ayah groups green over the real index |
| **D The reader, then the entry point (US4)** | T040 PageViewport reveal; window **[R4]**: T041 result and highlight, T042 clearing, T043 reveal wiring; T044 wiring of the service; T045 the icon in the index (after the reader can receive a result); T046 back and leaving change nothing; T047 geometry unchanged | reader baselines equal; wird untouched; ayah in view at 80/100/150% and in landscape; SC-006 through the real path |
| **E The states and the quality bars (US5, US6)** | T050-T054 states, stale answers, trace, state kept, privacy; T055-T057 looks and sizes, reading size, semantics | 36 combinations; contrast; 48 px; announcements once |
| **F Phone gate** | T060 the measurement build compiles and nothing outside the feature changed; T061 first use, speed, memory; T062 only if first use is over 2 s | the numbers of D9 |
| **G Polish** | T068 analyze, T069 whole suite, T070 strings confirmed, T071 owner's check | Principle IX |

## Complexity Tracking

| Item | Why | Simpler alternative rejected |
|---|---|---|
| **Principle I, «generated Quran data MUST be validated ... before it is used or shipped; a failed validation MUST stop the build»: the comparison copy is generated at run time, so its validation is a test the build runs and a check at every preparation, not a build step** | A generated index file would be a second copy of the Quran text on disk with a second implementation of the folding (drift), a tool and a build gate, to save about 0.15 s of first use (research D1). The run-time copy has no stored text of its own to be wrong; `flutter test` over the 114 real files checks 114 surahs, 6,236 ayat, the per-surah counts, one entry per ayah, 77,432 words present once and in order, none folding to nothing, and the same counts are checked each time the copy is made (a failure shows «تعذّر تجهيز البحث في الآيات», never wrong results). FR-019 itself allows «fail a test that the build runs» | A Python tool, `assets/ayah/search/index.txt` and a build gate: kept as the conditional T062 if the phone says the first use is over 2 s |
| A `Listener` over the reader's body (T042) | «until the next touch» means any touch on the reader (page, bar, card); a `GestureDetector` would take a tap away from the page | Clearing in each of the bars' handlers and the page's tap: five places, and a swipe on the page is not a tap |
| `PageViewport.reveal` (T040) | The page's own transformation and its inner scroll belong to `PageViewport`; only it can bring a word into view without a second source of truth | Moving the pager or the page from the reader: the reader cannot know the transformation |
| Sliced work on the UI isolate (about 8 ms slices) instead of an isolate | Measured: the whole scan is 5-11 ms and the whole preparation under 100 ms on the laptop; an isolate would copy the stored words twice and make every widget test use real time | A worker isolate (research D5); revisited only if the phone shows a slice over 16 ms |
| A Python reference file kept in the repository (`prototype/match_rules.py`) | Every number of the matching rule (the narrowing, the table, the 570 names) is re-run from it, as the Dart tests are written against its output | Numbers pasted in a document that cannot be re-run |

No other deviation from the constitution (1.3.0).
