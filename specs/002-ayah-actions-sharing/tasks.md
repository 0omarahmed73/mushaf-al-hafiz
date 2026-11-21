---

description: "Task list for feature 002: ayah actions and sharing"
---

# Tasks: Ayah Actions and Sharing

**Input**: Design documents from `/specs/002-ayah-actions-sharing/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md. The four source files are already in
`data-raw/ayah/` (git-ignored), checked against the sizes and sha256 recorded in `docs/research/licenses.md`.

**Tests**: REQUIRED. Constitution Principle IX makes test-first mandatory: a test task (or the test step named first inside a task)
must fail before the code that makes it pass. Every task ends with its own commit once its checks pass (message
`<type>: T0NN <short description>`, e.g. `feat: T016 ayah repository`); no commit mixes two tasks.

**Organization**: Setup and two foundational phases (the data build, then the pure Dart logic), then one phase per user story. The
owner asked for this story order: US1, then US2 and US5 (the three views), then US3 (picture), then US4 (PDF), then polish; so US5
comes before US3 here even though its spec priority is lower.

**Reader file rule**: `lib/mushaf/reader_screen.dart` is touched only by **T023** (long-press wiring, US1) and **T040** (progress strip,
US4). Every other task works in new files.

**Constrained fields**: every task that implements a constrained field of `data-model.md` cites it as `data-model.md Entity.field`.
The canonical rule lives there; tasks add only what narrows it.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no unfinished dependency)
- **[Story]**: US1–US5 from the spec (setup, foundational and polish tasks have none)
- Paths are relative to the repository root `<repo-root>/`

---

## Phase 1: Setup

- [X] T001 Add `assets/ayah/` to `.gitignore` (generated, rebuilt by the tool, same policy as `assets/mushaf/`); run `sha256sum` on the four inputs in `data-raw/ayah/` (`quranpedia-meanings.json.gz`, `tanzil-en.sahih.txt`, `qul-24-tafsir-saadi-ar.json.zip`, `qul-312-hafs-words.json.zip`) and confirm each matches the size and hash written in `docs/research/licenses.md`; commit only `.gitignore`

---

## Phase 2: Foundational A: the validated ayah data (blocks US1–US5)

**Purpose**: `tool/build_ayah_assets.py` and its tests, then the real `assets/ayah/` (contracts/assets.md, research D1–D5). Test tasks come first and fail first. All tests are in `tool/test_build_ayah_assets.py` and use small inline samples shaped like the real files; the Mushaf side is a tiny fake page set.

- [X] T002 Write failing pytest tests in `tool/test_build_ayah_assets.py` for the text source: the QUL 312 reader returns words per ayah and drops the last numeral marker; the build stops when the source's location set or ids differ from the Mushaf pages', when an ayah's last word is not a numeral, or when counts are not 6,236 ayahs and 77,432 words; stored words are byte-identical to the source's `text` (data-model.md AyahWords.words, AyahWords.text)
- [X] T003 Implement the text reader and alignment check in `tool/build_ayah_assets.py` (functions `read_hafs_words`, `check_alignment`, `split_ayahs`) until T002 passes; no other file changes
- [X] T004 Write failing pytest tests for the Tanzil cross-check: letters-only comparison (marks, tatweel removed, alef forms unified), the basmalah that Tanzil prepends to ayah 1 of surahs 2–8 and 10–114 is dropped before comparing, a difference not listed in `tool/ayah_text_known_differences.json` stops the build, a listed one needs a non-empty reason
- [X] T005 Implement the cross-check in `tool/build_ayah_assets.py` and create `tool/ayah_text_known_differences.json` containing exactly `2:72` with the reason (QUL writes the hamza as the letter «ء», Tanzil as a combining mark); run it against the real inputs and confirm that is the only difference
- [X] T006 Write failing pytest tests for the tafsir source: tags removed (`<span …>` keep their text, `<br>` becomes `\n`, `{ }` quote marks kept), identical consecutive texts merged into one `from`–`to` entry, empty `{}` ayahs listed in `without`, the set of `without` ayahs must equal `tool/tafsir_without_own_entry.json` or the build stops, a merged range or an inherited ayah may not cross a surah boundary, an inherited ayah needs an earlier entry in its surah (data-model.md TafsirEntry.from, TafsirEntry.to, TafsirEntry.text)
- [X] T007 Implement the tafsir reader in `tool/build_ayah_assets.py` and create `tool/tafsir_without_own_entry.json` from the real file (59 ayahs: 2:107, 2:109, 2:111, 2:286, 6:105 … 109:4); confirm the real file merges 205 repeated ayahs and passes every rule
- [X] T008 Write failing pytest tests for the translation and gharib sources: Tanzil lines `sura|aya|text` with the `#` footer and blank lines ignored, exactly 6,236 non-empty entries; Quranpedia filtered to books 327 and 208 only, an entry with an empty `text` or `meaning`, an unknown ayah or another book id stops the build, the covered-ayah count is returned (data-model.md TranslationEntry.text, GharibEntry.word, GharibEntry.meaning, GharibEntry.book)
- [X] T009 Implement the translation and gharib readers in `tool/build_ayah_assets.py`; on the real files the gharib coverage must print 3,689 of 6,236 ayahs (1,955 from book 327, 3,167 from book 208, as measured in research D4)
- [X] T010 Write failing pytest tests for the writer: nothing is written when any check fails, output files `assets/ayah/{text,tafsir,translation,gharib}/NNN.json` for NNN 001…114 and `assets/ayah/sources.json` match contracts/assets.md exactly, `sources.json` records every input's name, version or file date and sha256 (data-model.md Source.version, Source.sha256), the size report lists raw and gzip bytes per kind and the total and fails above 40 MB
- [X] T011 Implement `write_assets`, the size report and `main()` (`uv run python tool/build_ayah_assets.py [--out assets]`, validate everything first, then write) until T010 and every earlier test pass; `uv run --with pytest pytest tool/` all green
- [X] T012 Run the tool on the real inputs to produce `assets/ayah/`; add the five asset entries (`assets/ayah/text/`, `assets/ayah/tafsir/`, `assets/ayah/translation/`, `assets/ayah/gharib/`, `assets/ayah/sources.json`) to `pubspec.yaml`; write the real raw and gzip sizes into research.md D5 and the Technical Context line of plan.md (replacing the estimates); commit `pubspec.yaml`, research.md and plan.md (the tool and the pinned JSON files were committed in their own tasks; assets stay ignored)

**Checkpoint**: `assets/ayah/` exists, every build check passed, total size known (SC-009).

---

## Phase 3: Foundational B: pure Dart logic (blocks US1–US5)

**Purpose**: everything in `lib/ayah/` that has no widget (contracts/dart-interfaces.md). Each task writes its failing test first inside the same commit sequence (red, then green).

- [X] T013 [P] Test-first: `lib/ayah/ayah_ref.dart` and `test/ayah/ayah_ref_test.dart`: `AyahRef(surah, ayah)` with value equality and `key`, `ayahOfWord(MushafWord)`, `wordIdsOfAyah(PageData, AyahRef)` (every word including the marker, empty when the ayah is not on the page, only the part on that page when an ayah continues across pages; use a synthetic two-page ayah since no real one exists) (data-model.md AyahRef.surah, AyahRef.ayah)
- [X] T014 [P] Test-first: `lib/ayah/share_text.dart` and `test/ayah/share_text_test.dart`: `ShareTextBuilder.ayah/tafsir/translation` produce exactly the formats of contracts/share-formats.md (two lines, one space inside ﴿ ﴾, digits 0–9, no trailing newline, the example for 1:2, `۞` and `۩` kept, nothing added)
- [X] T015 [P] Test-first: `lib/ayah/file_names.dart` and `test/ayah/file_names_test.dart`: `FileNames.page(293)` is «مصحف - صفحة 293.png», `FileNames.surah('البقرة')` is «سورة البقرة.pdf», forbidden characters become a space and repeated spaces collapse; `SurahPages.of(meta, surah)` in `lib/ayah/surah_pages.dart` gives first and last page (Al-Fatiha 1..1, Al-Baqarah 2..49 = 48 pages, Al-Ikhlas 604..604) (data-model.md SurahPdf.firstPage, SurahPdf.lastPage, SurahPdf.pageCount, SurahPdf.fileName)
- [X] T016 Test-first: `lib/ayah/models.dart`, `lib/ayah/ayah_repository.dart` and `test/ayah/ayah_repository_test.dart` with a fake `AssetBundle`: `words`, `tafsir` (returns `TafsirResult(entry, inherited)`; an ayah in `without` resolves to the nearest earlier entry with `inherited` true), `translation`, `gharib` (empty list when none), `sources`; keeps the last 3 surahs per kind, decodes files over about 50 KB with `compute`, throws `StateError` naming the asset when a file is missing or malformed (data-model.md TafsirEntry.from, TafsirEntry.to, TafsirResult.inherited, TranslationEntry.text, GharibEntry.book)
- [X] T017 Write `test/ayah/ayah_text_integrity_test.dart` over the real assets: for all 6,236 ayahs the repository's words have the same count and positions `1..n-1` as the Mushaf page assets (read all 604 `assets/mushaf/pages/pNNN.json`), the shared string equals `﴿ words ﴾` plus the reference line and nothing else, all 114 tafsir files resolve every ayah (59 inherited, no failure) and all translation files give 6,236 non-empty texts (spec FR-008, FR-013, SC-002, SC-003)
- [X] T018 [P] Test-first: `lib/ayah/share_service.dart`, `lib/ayah/failures.dart`, `test/support/fake_share.dart` and `test/ayah/share_service_test.dart`: `ShareService` interface (`shareText`, `shareFile`), `ShareOutcome` (shared, dismissed), `ShareFailure` with the three kinds and their Arabic messages from contracts/ui.md, `TempShareFiles.create/clean` (folder `<temp>/share/`, `clean` empties it), `PlatformShareService` over `SharePlus.instance.share` mapping a dismissed result to `dismissed` and a platform error to `ShareFailure(couldNotShare)`, and `FakeShareService` recording what it was given (data-model.md ShareFailure.kind)

**Checkpoint**: the pure logic and the data are proven for all 6,236 ayahs; no UI exists yet.

---

## Phase 4: User Story 1 - Open an ayah's menu and share the ayah (P1) 🎯 MVP

**Goal**: long press on an ayah highlights it and opens a bottom sheet headed «سورة X · آية N» whose «مشاركة» shares the exact text and reference; tap, swipe and zoom are unchanged.

**Independent Test**: on any page hold a finger on a word: the ayah is highlighted and the sheet opens with the right header; «مشاركة» gives the two exact lines to the (fake) share service; closing clears the highlight; a tap still toggles the bars.

- [X] T019 [US1] Test-first: `lib/mushaf/mushaf_page_card.dart` and `lib/mushaf/page_look.dart` (both new) with `PageLook` (screen and print colours; print = white, black text, thin black frame and banner outline, no ivory or gold fill, per contracts/share-formats.md) and `test/mushaf/mushaf_page_card_test.dart`: `MushafPageCard` holds the ring, ivory paper, gold frame and `MushafPage` now written inline in `_PageItem`, takes `highlightedWordIds` and `onWordLongPress`, draws the page number in Cairo; make the small `mushaf_page.dart` change (page-number font) with its test; all existing `test/mushaf/*` tests still pass; `reader_screen.dart` is not changed here
- [X] T020 [US1] Write failing widget tests `test/ayah/ayah_sheet_test.dart`: the sheet shows the header «سورة البقرة · آية 255» in Reem Kufi and a «مشاركة» row at least 48 px tall with its semantic label; tapping it calls `FakeShareService.shareText` with the exact two lines; a `dismissed` outcome shows nothing; a `ShareFailure` shows its Arabic message in a snackbar and the sheet stays usable; closing the sheet clears a highlight owned by the caller
- [X] T021 [US1] Implement `lib/ayah/ui/ayah_sheet.dart`: `AyahSheet` (modal bottom sheet, the bookmarks sheet's green and ivory look, rows list so later stories add their rows) and the share-ayah action using `AyahRepository.words`, `ShareTextBuilder` and `ShareService`; until T020 passes
- [X] T022 [US1] Write failing reader tests in `test/mushaf/reader_screen_test.dart`: a long press on a word opens the sheet with that ayah's words highlighted; a short tap still toggles the bars and opens nothing; a drag, a fling and a two-finger pinch that start on a word never open it; a long press on the surah banner, on a basmallah line of another surah, on empty space, on the page number and on the top and bottom bars does nothing; Al-Fatiha's first ayah opens its menu; closing the sheet restores the same page and zoom and clears the highlight; a second long press while the sheet is open does nothing (spec FR-001, FR-002, FR-004, FR-006)
- [X] T023 [US1] Wire the reader (**the first of two touches of `lib/mushaf/reader_screen.dart`**): `_PageItem` builds `MushafPageCard`, passes `onWordLongPress` and `highlightedWordIds`; `_ReaderScreenState` keeps `Set<int> _highlight`, calls `HapticFeedback.mediumImpact()`, opens `AyahSheet`, clears the highlight when it closes; built with `--dart-define=AYAH_MENU_TRACE=true` it logs `AYAHMENU ms=<n>` from the long-press callback to the sheet's first painted frame (off, and free, in normal builds, like `PAGE_TURN_TRACE`); provide `AyahRepository`, `ShareService` and `ShareTextBuilder` in `lib/app.dart` and `lib/main.dart` (like `Backup`) and call `TempShareFiles.clean()` at start; T022 and every existing reader test pass
- [X] T024 [US1] Install a release build on the phone (`flutter build apk --release`, `adb install -r`) and check US1 only: long-press feel and the half-second opening (build with `AYAH_MENU_TRACE=true`, read `AYAHMENU ms=` from `adb logcat` over at least 10 holds, all under 500), 50 mixed gestures with no false menu, the shared text in a notes app; write the result under this task and commit it **Result (2026-11-20, Samsung SM-S721B, release build with AYAH_MENU_TRACE):** the menu opened in 15, 28, 32, 25, 26 and 36 ms (limit 500); 30 taps, horizontal and vertical swipes and slow drags opened no menu; 8 holds on the page number, top and bottom bars and the page margin opened none; the Android share sheet showed the ayah text starting with ﴿ and closing it without a target showed no message. Not checked by hand: a two-finger pinch (adb cannot do two touches; the widget tests cover it). The owner then looked at the phone and asked for landscape to be fixed (scrollable portrait-shaped page, commit d7fd2c5), a page-number popup (cd81a57) and confirmed the result.

**Checkpoint**: US1 is the MVP; the app can be used and shared from with only this much.

---

## Phase 5: User Story 2 - Tafsir and translation (P2)

**Goal**: «التفسير» and «الترجمة» views inside the sheet, labelled as human works, each with its own share button.

**Independent Test**: on 2:255 open both views: the Sa'di entry and the English text appear with their labels; a grouped entry shows its covers line; an ayah without its own entry shows the note; each share button sends text plus reference plus source name.

- [X] T025 [US2] Write failing widget tests in `test/ayah/ayah_sheet_test.dart` and new `test/ayah/tafsir_translation_view_test.dart`: the menu gains «التفسير» and «الترجمة» rows; each opens inside the same sheet with a back arrow and system back returning to the menu; the tafsir view is labelled «تفسير السعدي» with the small line «شرح بشري وليس من نص القرآن», shows «يشمل التفسير الآيات 6–7» when `from != to`, shows the proposed note when `inherited`, scrolls when long; the translation view shows the English text left-to-right under its label «Saheeh International»; the Quran words are not repeated; the share buttons call `shareText` with `ShareTextBuilder.tafsir/translation` (spec FR-009, FR-010, FR-010a, FR-012; data-model.md TafsirEntry.text, TranslationEntry.text)
- [X] T026 [US2] Implement `lib/ayah/ui/tafsir_view.dart`, `lib/ayah/ui/translation_view.dart` and the internal menu-to-detail navigation and the two rows in `lib/ayah/ui/ayah_sheet.dart` until T025 passes; strings exactly as in contracts/ui.md; a load error shows «تعذّر تحميل هذا القسم»
- [X] T027 [US2] Add `test/ayah/ayah_samples_test.dart` over the real assets for the by-hand sample of SC-002: 1:1, 2:255 and 114:6 each resolve to the expected reference, a non-empty tafsir (with its covers range) and the known English text; plus one inherited ayah (2:107) and one grouped ayah; commit

---

## Phase 6: User Story 5 - Word meanings (P5, built before US3 and US4 by the owner's order)

**Goal**: «معاني الكلمات» lists each difficult word with its meaning and source, or says there are none.

**Independent Test**: open it on 2:255 (entries from the two classical books, each labelled) and on an ayah with none (the «لا توجد كلمات غريبة في هذه الآية» line).

- [X] T028 [US5] Write failing widget tests `test/ayah/meanings_view_test.dart`: one row per entry with the word in bold and its meaning below, the source label «ابن الهائم · التبيان في تفسير غريب القرآن» or «ابن الجوزي · تذكرة الأريب في تفسير الغريب» from `sources`, set apart from the Quran text, the empty case shows exactly «لا توجد كلمات غريبة في هذه الآية» (spec FR-011, FR-012; data-model.md GharibEntry.word, GharibEntry.meaning, GharibEntry.book)
- [X] T029 [US5] Implement `lib/ayah/ui/meanings_view.dart` and the «معاني الكلمات» row in `lib/ayah/ui/ayah_sheet.dart` until T028 passes; check on the real assets that 2:255 has entries and report in the task which share of ayahs shows the empty line (expected 41%, research D4) **Result:** 2,547 of 6,236 ayahs (40.8%) show «لا توجد كلمات غريبة في هذه الآية» (as predicted in research D4); 3,689 show meanings, 2:255 among them.

---

## Phase 7: User Story 3 - Share the page as a picture (P3)

**Goal**: «مشاركة الصفحة كصورة» offers one PNG of the shown page in the app's look.

**Independent Test**: from page 293 the (fake) share service receives one 2000×3000 PNG named «مصحف - صفحة 293.png» that shows the page without highlight; failures show their Arabic message; a real phone shows it sharp.

- [X] T030 [US3] Write failing tests `test/render/page_renderer_test.dart` (real page data and fonts, loaded as in the planning probe: `tester.runAsync`, `FontLoader` for Reem Kufi, Amiri and the page font): `picture(page)` returns a PNG of exactly 2000×3000 px for pages 1, 2, 293 and 604, and `OffscreenPageRenderer` takes only the page repository, font loader and meta (no wird, bookmark or database object, spec FR-017); the screen look contains ivory and green pixels and no highlight colour; the print look contains only white, gray and black pixels; a missing page font becomes `ShareFailure(couldNotPrepare)` (data-model.md PageRender.page, PageRender.look, PageRender.pixelRatio)
- [X] T031 [US3] Implement `lib/render/page_renderer.dart` (`PageRenderer` interface, `OffscreenPageRenderer`, the canonical logical size 400×600): paint `MushafPageCard` into a `RepaintBoundary` of logical 400×600 at pixel ratio 5 (2000×3000) for the picture and 4 (1600×2400) for the print pages, using `PageFontLoader.ensure`. First prove the detached render tree (own `BuildOwner` and `PipelineOwner`) compiles and works on Flutter 3.50; if it does not, use the short-lived `Overlay` entry placed outside the viewport and record which was used and why in research.md D6; until T030 passes
- [X] T032 [US3] Test-first, then implement the picture action in `lib/ayah/page_picture_action.dart` and the row «مشاركة الصفحة كصورة» in `lib/ayah/ui/ayah_sheet.dart` with `test/ayah/page_picture_action_test.dart` (fake renderer, `FakeShareService`, a temp folder): render, write `<temp>/share/<FileNames.page>`, share with `image/png`; «جارٍ تجهيز الصورة» shows if it takes over 0.5 s; no-space, render and share failures show the three messages; a dismissed share shows nothing; browsing never changes the wird's position
- [ ] T033 [US3] On the phone check US3: ready in under 3 s on pages 1, 2, 293 and 604, looks like the app page, sharp when zoomed twice in the gallery; record the measured times in research.md D6 next to the dev-machine numbers; commit
  - So far (2026-11-20): pages 14 and 16 ready in 0.5–0.8 s, pages 1 and 2 in 351 and 339 ms with the app's exact colours (research D6). Open, owner on the phone: pages 293 and 604, and sharpness when zoomed twice.

---

## Phase 8: User Story 4 - Share a whole surah as a PDF (P4)

**Goal**: «مشاركة السورة PDF» prepares an A4 PDF of the surah's Mushaf pages with progress and cancel while the reader stays usable.

**Independent Test**: with fakes, a surah of 48 pages produces a valid 48-page PDF in order; cancel leaves no file; a second start is refused; on the phone Al-Baqarah is ready in under 60 s and under 40 MB.

- [X] T034 [P] [US4] Test-first: `lib/pdf/a4_layout.dart` and `test/pdf/a4_layout_test.dart`: `A4Layout.place(1600, 2400)` returns a rectangle inside the 28.35 pt margin, centred horizontally, touching the top and bottom margins, keeping the 2:3 proportion, with equal side margins (about 12.65 mm), and an effective resolution of at least 200 pixels per inch (about 220; spec FR-015) (data-model.md SurahPdf.pageCount)
- [X] T035 [P] [US4] Test-first: `lib/render/gray_flate.dart` and `test/render/gray_flate_test.dart`: RGBA bytes become 8-bit gray (the red channel, because the print look is monochrome) and are deflated inside `Isolate.run`; inflating the result gives back exactly `width × height` bytes of the expected values; `GrayPage` carries width, height and `flateBytes`
- [X] T036 [US4] Write failing tests `test/pdf/pdf_writer_test.dart` with a small structure verifier in the test (no PDF package): a document of N tiny `GrayPage`s has the `%PDF-` header, N page objects whose `MediaBox` is `[0 0 595.28 841.89]`, one image XObject per page (`DeviceGray`, 8 bits, `FlateDecode`), a content stream `q W 0 0 H x y cm /Im0 Do Q` placing the image where `A4Layout.place` says, every xref offset pointing at its `N 0 obj`, a trailer with the right `Size` and `Root`, the title «سورة <name>» as UTF-16BE, and no author, producer, date or other metadata, and no text objects, annotations, attachments or scripts (spec FR-017); `abort()` deletes the file
- [X] T037 [US4] Implement `lib/pdf/pdf_writer.dart` (streaming `PdfWriter` over a `RandomAccessFile`: `addPage`, `finish`, `abort`) until T036 passes
- [X] T038 [US4] Write failing tests `test/pdf/pdf_job_test.dart` (fake renderer returning tiny gray pages, temp folder, fake clock): `start(2)` gives 48 pages in order and ends in `ready` with the Arabic file name; progress notifies after every page («صفحة N من 48»); `start` while running returns false; `cancel()` within one step leaves no file and ends `idle`; a no-space `FileSystemException` ends `failed(noSpace)` and removes the file; a render failure ends `failed(couldNotPrepare)`; `shareReady` calls `shareFile` with `application/pdf` and returns to `idle`; a pause while no frames run resumes without losing a page (spec FR-016, FR-018; data-model.md SurahPdf.fileName, PdfJob.state, ShareFailure.kind)
- [X] T039 [US4] Implement `lib/pdf/pdf_job.dart` (`PdfJob` `ChangeNotifier`, `CancelToken`, states from data-model.md PdfJob.state) and `OffscreenPageRenderer.printPage` in `lib/render/page_renderer.dart` (print look, pixel ratio 4 = 1600×2400, `gray_flate`) until T038 passes; extend `test/render/page_renderer_test.dart` for `printPage`
- [X] T040 [US4] Write failing widget tests `test/ayah/pdf_progress_strip_test.dart`, implement `lib/ayah/ui/pdf_progress_strip.dart` (non-modal, 56 px, «جارٍ تجهيز سورة البقرة» · «صفحة 12 من 48» · «إلغاء»; «تم تجهيز الملف» · «مشاركة»; the failure message · «إغلاق») and add the row «مشاركة السورة PDF» (disabled with «يتم تجهيز ملف الآن» while a job runs) to `lib/ayah/ui/ayah_sheet.dart`; then wire the strip above the bottom bar in `lib/mushaf/reader_screen.dart` (**the second and last touch of that file**) and provide `PdfJob` in `lib/app.dart`; add a reader test that page turning still works while a fake job is preparing; all reader tests pass
- [ ] T041 [US4] On the phone check US4: Al-Baqarah in under 60 s and under 40 MB with 48 A4 pages in order, white with black text, centred, readable in a PDF viewer and in print preview; Al-Fatiha (1 page) and Al-Ikhlas (page 604 with neighbours); cancel within 2 s with no file left; a second start refused; screen locked during a job; record the numbers in research.md D7 next to the dev-machine ones and decide the quality gate there (pixel ratio 4 is enough, or raise it to 5, or ask for the vector PDF); commit
  - So far (2026-11-20, colour PDF): Al-Baqarah 10.2 s, 15.1 MB, 48 pages; cancel under 1.5 s and no file left; a second start refused; the strip and the automatic share work. Second run: Al-Baqarah 9.0 s, 15,127,100 bytes; Al-Fatiha 1 page 160 ms, 99 kB. Numbers are in research D7. Open, owner on the phone: Al-Ikhlas, a locked screen during a job, a PDF viewer and print preview.

---

## Phase 9: Polish and cross-cutting

- [X] T042 [P] Test-first: add the four source credits of contracts/ui.md (name, provider, link, version) to `lib/settings/about_screen.dart` with `test/settings/about_screen_test.dart` (each credit line and its link opener); keep the statement «النص القرآني لم يُعدَّل» and the existing credits; the small-phone no-overflow test still passes (spec FR-020, SC-008)
- [X] T043 [P] Finalise `docs/research/licenses.md`: each of the four sources has its file name, version, size and sha256 as built (read from `assets/ayah/sources.json`), «downloaded 2026-11-20», and the owner's approval of the four downloads; the Quranpedia entry states the two books used; the research note about Feature 4 is gone; commit
- [X] T044 Run `flutter analyze` (no issues), the whole `flutter test` suite and `uv run --with pytest pytest tool/`; fix anything red in the task that caused it (separate commits per fix); the 186 earlier Flutter tests still pass
  - Done 2026-11-20: `flutter analyze` is clean on every feature 002 file, the 286 tests of this feature pass, pytest 59 passed. The whole-suite run then showed 9 red tests (all in `test/mushaf/reader_size_test.dart`) and 3 analyzer infos (`page_layout_invariance_test.dart`, `page_viewport_test.dart`): feature 003's own test-first work in progress, not changed by this feature.
  - Re-run 2026-11-21 on the current tree: `flutter analyze` No issues found; `flutter test` all 857 tests passed (the 9 red tests and 3 infos are gone, fixed by the other features' sessions).
- [ ] T045 Real-device checklist, part 1 (quickstart §3 steps 1–3, 8): long-press feel and 50 mixed gestures, share text, the 10-ayah by-hand check (1:1, 2:255, 114:6 and seven more) of reference, tafsir, translation and meanings, the credits in About; write each result under this task
  - So far (2026-11-20): hold to sheet 16–71 ms on the phone; the ayah share text checked in WhatsApp by the owner; the About credits are covered by widget tests. Open, owner on the phone: the 50 mixed gestures and the 10-ayah by-hand check.
- [ ] T046 Real-device checklist, part 2 (quickstart §3 steps 4–7): picture, PDF, airplane mode (nothing changes, no network use), failures (low space message, a dismissed share shows nothing); add the INTERNET permission check of the release manifest (still none); write each result under this task
  - So far (2026-11-20): the release manifest has no INTERNET permission. Open, owner on the phone: airplane mode, the low-space message, a dismissed share shows nothing.
- [ ] T047 Update `specs/002-ayah-actions-sharing/quickstart.md` with anything the phone checks changed; mark T001–T047 `[X]`; run `/speckit-converge` and fix every gap it reports
  - 2026-11-20: quickstart updated (trace build, `adb pull`, SC-010 comparison). `/speckit-converge` found no gap in the code against the spec, plan and tasks; what is left is the phone work already listed in T033, T041, T045, T046 and T053. Tick this task and T001–T046 when those are done.

---

## Dependencies and order

- **Phase 1 → Phase 2 → Phase 3** in order. T002–T012 are sequential (one test file, one tool file). T013, T014, T015 and T018 are independent and may run together; T016 needs the models only (its tests use a fake bundle), T017 needs T012 and T016.
- **US1 (T019–T024)** needs Phases 2–3. T019 (new file) may run while T020–T021 are written. T022 needs T019 and T021. T023 needs T019, T021, T022.
- **US2 (T025–T027)** and **US5 (T028–T029)** need US1's sheet; they touch the same sheet file, so they run one after the other, never together.
- **US3 (T030–T033)** needs T019 and T018; **US4 (T034–T041)** needs T031 (the renderer) and T018. T034 and T035 may run together.
- **Phase 9** needs every story. T042 and T043 may run together.

## Parallel examples

```text
After T012: T013, T014, T015, T018 together (four different new files)
During US4: T034 and T035 together, then T036 → T037 → T038 → T039 → T040
Polish: T042 and T043 together
```

## Implementation strategy

1. **MVP = Phases 1–4 (T001–T024)**: the validated data, the pure logic, and the long-press menu that shares an ayah. Stop and check on the phone (T024) before going on.
2. Add the views (US2, US5), then the picture (US3), then the PDF (US4), each with its own phone check (T033, T041).
3. Polish, the full device checklist and converge (T042–T047).
4. Every task: red test, green code, `flutter analyze`, one commit.

---

## Phase 10: Amendment of 2026-11-20 (owner feedback after the first phone build)

The owner saw the first build on the phone: the PDF was black and white and the page picture's colours were
faded and unlike the app. Decisions: the PDF is in the app's colours (spec FR-015 amended, the print look is
dropped); the picture must match the app's colours (FR-014, SC-010). Budgets stay: Al-Baqarah under 60 s and
under 40 MB, at least 200 ppi, no new package.

- [X] T048 Amend the spec, plan, research D6/D7, contracts, data model and quickstart for the colour PDF and the colour-fidelity criterion SC-010 (docs only; this task is done once the documents agree with each other)
- [X] T049 [US3] Find why the picture looks faded: render the page on the phone (diagnostic build that also writes the PNG to the app's external files folder under `AYAH_MENU_TRACE`) and compare it with a screenshot of the same page; fix the cause in `lib/render/page_renderer.dart` (a `Material` and `DefaultTextStyle` for the overlay, anything that dims) with a test that measures the picture's background, ring, paper, frame, banner and ink colours against `PageLook.screen`
- [X] T050 [US4] Test-first: `lib/render/indexed_flate.dart` and `test/render/indexed_flate_test.dart` replace `gray_flate`: RGBA becomes a 256-colour palette plus 8-bit indices (frequency-weighted median cut over the page's distinct colours, the page's own base colours kept exact), deflated in `Isolate.run`; inflating gives indices that map back to colours within a small error of the original; `IndexedPage` carries width, height, palette and `flateBytes`
- [X] T051 [US4] Update `PdfWriter` and `PdfJob` for colour: image XObject `[/Indexed /DeviceRGB 255 <palette>]`, content stream first fills the sheet with the app's green and then places the image (`q r g b rg 0 0 W H re f Q` + the existing `cm … Do`), still no text, annotations or metadata; `PageRenderer.printPage` becomes `pdfPage` in `PageLook.screen`; remove `PageLook.print` and `gray_flate`; tests for the writer, the job and the renderer are updated first
- [X] T052 [US4] Measure on the dev machine and on the phone: Al-Baqarah time, size (under 40 MB), the PDF in a viewer; if the size is over budget choose a smaller palette or another pixel ratio with the owner; record the numbers in research D7
- [ ] T053 Rebuild, install, and have the owner confirm by eye that the picture and the PDF look like the app (SC-010); commit the final numbers
