# Tasks: Night Reader Look (Second Theme)

**Input**: `specs/004-night-reader-theme/` (spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md,
checklists/look.md)

**Rules**: test-first (a failing test is written and run red before the code that makes it pass); one commit per
task; `git add` explicit paths only and `dart format` on explicit files only; **new tests go in NEW files**: the
existing tests of features 001 to 003 are never edited and must keep passing with the Emerald look (spec SC-003);
the only allowed edit of test support is the behaviour-preserving optional `look` parameter on the renderer fakes
(T023). Check `git status` and `git log` before every task: the sessions of features 002 and 003 work in this
folder. **`lib/mushaf/reader_screen.dart` is touched only in Phase 7** (T030, T031), and only for colours, the
floating bar and passing the page look. `.specify/feature.json` is NOT changed (speckit scripts run with
`SPECIFY_FEATURE_DIRECTORY=specs/004-night-reader-theme SPECIFY_FEATURE_NO_PERSIST=1`). The Quran text, page data,
fonts, page geometry, About credits and `docs/research/licenses.md` are never touched. Arabic UI strings are
proposals until the owner confirms them (T036). Commit trailer:
`Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.

Key: **FR/SC** are the spec's requirement and success-criterion ids; "data-model.md X" is the cited definition.

## Phase 1: Setup

- [X] T001 Write `docs/design/night-reader.md` next to `docs/design/emerald-gold.md`: the design canvas link (direction B, boards B-Wirds and B-Reader, a source and not a build dependency), the full token table of `data-model.md` (AppLook colours and shapes, PageLook fields) with the two lifted colours and their ratios (dim `#6E7983` to `#85909B`, control border to `#5F6B76`), the three wird palette colours that are lightened in Night, the fonts kept (Cairo, Reem Kufi, Amiri Quran) and what is not copied from the design (IBM Plex Sans Arabic, Amiri, the 88 px bar) (spec FR-005, FR-017; research D7)

---

## Phase 2: Foundational (blocks every story)

**Purpose**: the look model, its stored value, the theme extension and the app wiring. Nothing visible changes in
Emerald.

- [X] T002 [P] Test-first: `test/look/look_choice_test.dart`, then `lib/look/look_choice.dart`: `enum LookChoice { emerald, night }` with `parse(String?)` (null, empty, unknown, wrong case, `"purple"` all give `emerald`; never throws) and `name` as the stored value (data-model.md `Look setting.value`; spec FR-016). The `look` and `pageLook` getters are added in T004 and T019
- [X] T003 [P] Test-first: `test/look/contrast_test.dart` (known values: black on white 21.0, equal colours 1.0, the Night pairs of research D7 to two decimals, `liftToContrast` keeps a colour that already passes, raises HSL lightness in 1% steps otherwise and keeps the hue, never exceeds white), then `lib/look/contrast.dart` with `contrastRatio` and `liftToContrast`; also the test helper `test/support/contrast_walk.dart` (pumps nothing itself: given a finder root it walks the painted `Text` and `Icon` colours and the colour of the nearest painted background behind each, and reports every pair below 4.5:1, or 3:1 for text of 24 px and more and for icons) with its own `test/look/contrast_walk_test.dart`; every Night screen test below uses it, so the hand-written `requiredPairs` list cannot hide a pair a screen really uses (contracts/dart-interfaces.md `contrast.dart`; spec FR-012, SC-005)
- [X] T004 Test-first: `test/look/emerald_identity_test.dart` (every `AppLook.emerald` token equals its `AppColors` constant or the literal of data-model.md AppLook; `buildAppTheme()` has today's colour scheme, app bar, tab bar, list tile, divider, input and button themes; `context.look` is Emerald under a plain `MaterialApp`) and `test/look/app_look_test.dart` (`AppLook.night` equals data-model.md AppLook; **every pair of `AppLook.night.requiredPairs` meets its minimum, 4.5 for text and 3.0 for large text, icons and control borders; the exempt hairline pairs are exactly the names in `decorative`**; `copyWith` and `lerp` (`t < .5` gives this, else the other); `buildAppTheme(look: night)` builds a scheme from the Night tokens and a `Theme` carries the extension), then `AppLook`, `AppLook.emerald`, `AppLook.night`, `LookContext.look`, `buildAppTheme({AppLook look = AppLook.emerald})` and the `LookChoice.look` getter in `lib/theme.dart` / `lib/look/` (data-model.md `AppLook.textDim` and `AppLook.controlBorder` (the two lifted values, canonical ratios in research D7) and every other `AppLook` colour and shape token of its two tables; spec FR-002, FR-004, FR-005, FR-012, SC-003, SC-005). The list `requiredPairs` is the table "Required pairs" of data-model.md
- [X] T005 Test-first: `test/look/look_settings_test.dart` (in-memory drift as in the wird repository tests: default Emerald when nothing is stored; `set(night)` saves and notifies once, the same value notifies nothing; `reload()` picks up a changed row and notifies only on a change; a bad stored value reads as Emerald and leaves the row alone), then `WirdRepository.appLookRaw` / `setAppLook` (key `appLook`) in `lib/wirds/wird_repository.dart` and `lib/look/look_settings.dart` (`AppLookSettings`: `choice`, `look`, `pageLook`, `load`, `reload`, `set`) (data-model.md `Look setting.value` (`emerald` or `night`, anything else reads as `emerald`); spec FR-003, FR-016). `AppLookSettings.pageLook` returns `choice.pageLook`, which does not exist before T019, so it is added in T019 and not here
- [X] T006 Test-first: `test/look/look_provider_test.dart` (a new `test/support/look_harness.dart` holds the helper; `MushafApp(appLook: night)` has the Night scaffold colour in the **first pumped frame**; `AppLookSettings.set` changes the theme of the open app without a restart and keeps the current route; a null look is Emerald; `themeAnimationDuration` is zero; the status bar and navigation bar icons stay light in both looks because both are dark, a test documents it), then `lib/app.dart` (`appLook` parameter, `ListenableProvider<AppLookSettings?>.value`, `ListenableBuilder` around `MaterialApp` with `buildAppTheme(look: ...)` and `themeAnimationDuration: Duration.zero`) and `lib/main.dart` (create and `load()` it before `runApp`, after the text size) (contracts/dart-interfaces.md `lib/app.dart`; spec FR-003, FR-015, SC-006)

**Checkpoint**: the look can be stored, read, observed and applied to the theme; every screen still reads `AppColors`
and Emerald is unchanged.

---

## Phase 3: User Story 1 - Choose Night Reader and see the whole app change (P1) MVP

**Goal**: a «المظهر» row in Settings; Night wears every screen except the reader's own chrome and page (Phase 7 and
Phase 4); the choice is kept.

**Independent Test**: choose «القارئ الليلي» in Settings: Settings, «أوراد», the wird form, the bookmarks sheet, the
ayah menu and its views, the PDF strip, About, the index and the go-to-page popup are all in the Night look with no
ivory block; restart: kept; choose «زمردي وذهبي»: as before.

- [X] T007 [US1] Test-first: `test/settings/look_tile_test.dart` (two options with colour samples, the chosen one has a check, a 2 px outline and `selected` semantics, labels «زمردي وذهبي» and «القارئ الليلي», each at least 56 px high and 48 px wide, stacked at less than 320 dp or with a 2x system font and never overflowing, a tap calls `AppLookSettings.set`) and `test/settings/settings_look_test.dart` (the row is first in Settings under «المظهر» and the note is shown; choosing Night changes the open Settings screen and a screen behind it at once; the choice survives a new `MushafApp` on the same database; the existing settings tests and the small-phone no-overflow test pass unchanged), then `lib/settings/look_tile.dart` and its insertion in `lib/settings/settings_screen.dart` (a `_SectionLabel('المظهر')` and `const LookTile()` as the first children; the `TextSizeTile` line is not touched) (contracts/ui.md Settings row; spec FR-001, FR-003, FR-018, SC-001)
- [X] T008 [P] [US1] Test-first: `test/look/wird_marker_test.dart` (all 8 palette colours at 3:1 or more on `#161B22` in Night, unchanged in Emerald, hue kept and the eight still pairwise different, the stored `Wirds.color` untouched), then `lib/look/wird_marker.dart`: `markerColor(AppLook look, Color palette)` and `WirdMarker` (diamond of 10 px in Emerald, dot of 8 px in Night) (data-model.md Wird marker colour: `markerColor` result against `AppLook.cardFill` at 3.0, hue kept; spec FR-013, SC-005; research D6). `WirdDiamond` in `today_panel.dart` stays as it is for About
- [X] T009 [US1] Test-first: `test/wirds/wirds_night_test.dart` (red; like every Night screen test below it also walks the screen with `contrast_walk.dart`, and pumps it at 320 dp wide with a 2x system text scale to check that nothing overflows, in both looks, spec FR-012, FR-014) then migrate `lib/wirds/wirds_screen.dart` and `lib/wirds/today_panel.dart` from `AppColors` to `context.look`: round 44 px add button with `controlBorder` in Night (rounded square as today in Emerald), «ملخص اليوم» card, `WirdMarker` dots, «تم» pill in `doneFill` and the «✓ تم» mark, wird cards with the active one outlined `cardBorderActive` and tagged «النشط», pill tags, the outlined «ورد جديد» pill with `controlBorder`; the existing wirds and today-panel tests pass unchanged (spec FR-004, FR-005, FR-006, FR-012, FR-013; contracts/ui.md «أوراد»)
- [X] T010 [P] [US1] Test-first: `test/wirds/wird_form_night_test.dart` (contrast walk and the 320 dp / 2x text scale no-overflow check in both looks) then migrate `lib/wirds/wird_form_screen.dart` (outlined fields with `controlBorder`, pill choices, `primaryFill` «حفظ» pill, palette swatches through `markerColor`, the selected check with a second cue); existing wird form tests unchanged (spec FR-004, FR-012, FR-013)
- [X] T011 [P] [US1] Test-first: `test/wirds/bookmarks_night_test.dart` (contrast walk and the 320 dp / 2x no-overflow check in both looks) then migrate `lib/wirds/bookmarks_sheet.dart` (sheet on `background`, `cardFill` rows, `accent` icons, the delete background keeps a readable icon); existing bookmark tests unchanged (spec FR-004, FR-012)
- [X] T012 [US1] Test-first: `test/ayah/ayah_night_test.dart` (the menu, the three views and their reading panels have no ivory block in Night, pass the contrast walk, and do not overflow at 320 dp with a 2x text scale, in both looks) then migrate `lib/ayah/ui/ayah_sheet.dart`, `sheet_detail.dart`, `tafsir_view.dart`, `translation_view.dart`, `meanings_view.dart` (rows `cardFill` with `cardBorder` and radius 20, `StatusLine`, the sheet background and handle, the meanings divider). **`lib/ayah/ui/reading_text.dart` belongs to feature 003**: edit its quiet text colours here only if `git status` shows it clean and say so in the commit, otherwise leave it for T032; existing ayah tests unchanged (spec FR-004, FR-012; contracts/ui.md ayah menu)
- [X] T013 [P] [US1] Test-first: `test/ayah/pdf_strip_night_test.dart` (contrast walk and the 320 dp / 2x no-overflow check in both looks) then migrate `lib/ayah/ui/pdf_progress_strip.dart` (`cardFill` pill, `accent` progress, `controlBorder` buttons, the three states); existing strip tests unchanged (spec FR-004, FR-012)
- [X] T014 [US1] Test-first: `test/settings/settings_night_test.dart` (contrast walk and the 320 dp / 2x no-overflow check in both looks) then migrate the colours of `lib/settings/settings_screen.dart` (labels, subtitles, the time text, the backup section and status cards, switch and button colours through the scheme); do NOT touch `TextSizeTile`; existing settings tests unchanged (spec FR-004, FR-012)
- [X] T015 [P] [US1] Test-first: `test/settings/about_night_test.dart` (contrast walk and the 320 dp / 2x no-overflow check in both looks) then migrate `lib/settings/about_screen.dart` (37 colour uses: cards `cardFill`, emblem and links `accent`, rings `ring`, text roles); the credits, links and text are identical and the existing about test passes unchanged (spec FR-004, FR-006, FR-017)
- [X] T016 [US1] Test-first: `test/look/theme_only_screens_night_test.dart` (also the contrast walk and the 320 dp / 2x no-overflow check in both looks): the index (surahs and parts), the go-to-page dialog, a snack bar, a text field in each state, a switch, a slider, a dialog, a bottom sheet and a tab bar, pumped under `buildAppTheme(look: night)`, contain no ivory or bright fill (walk the painted decorations) and meet `requiredPairs`; fix `lib/theme.dart` (dialog, sheet, snack bar, switch, slider, checkbox, chip themes) and, only if a screen paints its own bright colour, `lib/mushaf/index_screen.dart` / `go_to_page_dialog.dart` (spec FR-004, FR-012, SC-002)
- [ ] T017 [US1] (deferred to T035: one install and one approval for every look check; not done yet) On the phone check US1 (quickstart, on-phone steps 1 and 6, except the reader chrome and page until Phase 7, and except the feature 003 text-size tile and the reading-panel note colours until T032 unless T012 or an early T032 already did them): install, choose Night, open every screen of FR-004, screenshot each (`adb exec-out screencap`), switch back to Emerald; ask before sending any input to the phone (never unlock it); record in `research.md` D12; commit

**Checkpoint**: US1 works alone: the app has two looks; the reader's chrome and the page keep their Emerald colours
until Phase 7 and Phase 4.

---

## Phase 4: User Story 2 - The Mushaf page in Night (P2)

**Goal**: with Night chosen the page has no card and no frame, light ink, a teal title between hairlines and teal
ayah-end markers; it is the same page.

**Independent Test**: pages 1, 2, 3, 50, 293, 604 and a page with a surah banner in the middle in both looks: same
lines, words and line boxes; no paper and no frame painted in Night; the highlight is visible; 6,236 end markers.

- [X] T018 [US2] Write failing tests (red, committed): `test/mushaf/page_look_night_test.dart` (`MushafPageCard` with `PageLook.night`: no paper colour and no visible frame or ring painted, the same outer box size as with Emerald, banner in `rules` style, page number and end markers in their colours, the long-press highlight is at least 1.5:1 against the page and the ink on it at least 4.5:1), `test/mushaf/page_layout_both_looks_test.dart` (default: pages 1, 2, 3, 50, 293, 604 and the widest-line pages; with `FULL_LAYOUT_CHECK` all 604: the `line-N` boxes, the word boxes and the word order are equal in both looks; real fonts as in feature 003's invariance test, which is not edited) and `test/mushaf/end_markers_test.dart` (over all 604 page JSON files: exactly 6,236 markers, one per ayah, each the last word of its ayah, none else; `loadPage` of a page whose next page is missing returns without an exception; the time of `loadPage` with the derivation stays within the existing repository tests' budget) (spec FR-007, FR-008, FR-009, SC-004; research D3)
- [X] T019 [US2] Implement `PageLook.night` and the per-look fields (`bannerStyle`, `numberColor`, `highlight`, `endMarker`; `PageLook.emerald = screen`) in `lib/mushaf/page_look.dart` and complete `LookChoice.pageLook` / `AppLookSettings.pageLook`; check `git status` of `page_look.dart` first (feature 002 file). `PageLook.screen` and the `PageLook(...)` literal of `mushaf_page_card_test.dart` keep compiling (data-model.md `PageLook.bannerStyle`, `PageLook.numberColor`, `PageLook.highlight`, `PageLook.endMarker` and the Night column of its table; contracts/dart-interfaces.md `page_look.dart`)
- [X] T020 [US2] Make `lib/mushaf/mushaf_page.dart` and `mushaf_page_card.dart` paint the look: banner `rules` style (title between two 1 px hairlines in the same line box, no fill and no box), `numberColor`, `endMarkerIds` coloured `endMarker`, highlight from the look; **paddings, border width and every size stay**; with the defaults the output is exactly today's; T018's card and layout tests go green and `mushaf_page_card_test.dart`, `mushaf_page_test.dart` and feature 003's invariance test pass unchanged (spec FR-007, FR-008, SC-004)
- [X] T021 [US2] `PageData.endMarkerIds` in `lib/mushaf/models.dart`, derived in `MushafRepository.loadPage` in `lib/mushaf/mushaf_repository.dart` (a word is a marker when the next word in Mushaf order, for the last word of a page the first word of the next page, belongs to another ayah). The lookup of the next page is best effort and must not change what `loadPage` does today: it reuses a page already loaded or loading, never makes a page turn wait for a second page, and when the next page is not available (page 604, a bundle with fewer pages as in the existing tests, a load error) the last word of the page is a marker only on page 604 and otherwise not, with no exception; no asset changed; T018's end-marker test goes green and the existing repository tests pass unchanged (data-model.md `PageData.endMarkerIds`; spec FR-007, FR-017)

**Checkpoint**: the page card draws the Night page; the reader still has to pass the look (T031).

---

## Phase 5: User Story 3 - Share a Night page as a picture or a PDF (P3)

**Goal**: the picture and the PDF follow the look in force when the share or the job starts.

**Independent Test**: with Night chosen, share the picture and prepare a PDF of a short surah: both are Night; a look
change after the PDF started does not change it; with Emerald they are as before.

- [X] T022 [US3] Write failing tests (red): `test/render/page_renderer_night_test.dart` (a Night render has the background, ink, teal title and hairline colours within 6 of 255 per channel, like `page_renderer_test.dart` does for Emerald, which is not edited; the picture and the 256-colour PDF image both), `test/pdf/pdf_job_night_test.dart` (the writer sheet colour is the Night background; a `look` passed to `start` reaches every `pdfPage`; changing the app look after `start` does not change the running job; Emerald as before) and `test/ayah/page_picture_look_test.dart` (the picture action passes its look to the renderer) (spec FR-010, FR-011, SC-007; research D4)
- [X] T023 [US3] Add the optional `look` parameter to `PageRenderer.picture` / `pdfPage` (default `PageLook.screen`) in `lib/render/page_renderer.dart`, use it in `OffscreenPageRenderer`, and give the two renderer fakes in `test/support/fake_renderer.dart` (and any `PageRenderer` fake found by `grep -rn "implements PageRenderer" test`) the same optional parameter, behaviour unchanged (record this in Complexity Tracking of `plan.md`); check `git status` of `lib/render`, `test/support` first; every earlier render, pdf and ayah test passes unchanged (contracts/dart-interfaces.md renderer)
- [X] T024 [US3] `PdfJob.start(int surah, {PageLook look = PageLook.screen})` in `lib/pdf/pdf_job.dart`: store `_jobLook`, pass it to every `renderer.pdfPage`, build the default writer with `sheet: _jobLook.background`; a test-supplied `writerFactory` is called as before; T022's PDF tests go green (spec FR-011)
- [X] T025 [US3] `PagePictureAction` takes `look` in `lib/ayah/page_picture_action.dart`; `showAyahSheet` in `lib/ayah/ui/ayah_sheet.dart` passes `context.read<AppLookSettings?>()?.pageLook` to it and to `pdfJob.start`; T022's picture test goes green and the existing picture and PDF row tests pass unchanged (spec FR-010, FR-011)

**Checkpoint**: Night pictures and PDFs; timing and size are re-measured on the phone in T034.

---

## Phase 6: User Story 4 - Keep the look in a backup and fall back safely (P3)

**Goal**: the look travels with the backup; bad or missing values never fail.

**Independent Test**: choose Night, export, switch to Emerald, import: Night again, at once. Import an old backup and a
file with `"purple"`: Emerald, no error.

- [X] T026 [US4] Write failing tests (red): `test/backup/backup_look_test.dart` (export holds `appLook`; a backup without it keeps Emerald and changes nothing else; `"purple"` gives Emerald and the import succeeds; importing `night` switches the open Settings screen at once; an import that fails part way leaves the look as it was) (spec FR-016, SC-006; research D10)
- [X] T027 [US4] After a successful import call `AppLookSettings.reload()` in the success path of `lib/settings/settings_screen.dart` (one line; `BackupService` needs no change because it exports every settings row); T026 goes green and the existing backup tests pass unchanged (spec FR-016)

**Checkpoint**: all of US1, US2 (card), US3 and US4 are done except the reader's own colours and look hand-over.

---

## Phase 7: Coordination gate and the reader (after feature 003)

**Gate (T028)**: this phase starts when feature 003 no longer edits the files below: its tasks that touch `lib/mushaf/reader_screen.dart` (T014 and T017, both committed on 2026-11-20) and any task that may still edit `lib/settings/text_size_tile.dart` or `lib/ayah/ui/reading_text.dart` (its T019, the owner's string confirmation) are committed, and `git status` shows `lib/mushaf/reader_screen.dart`, `page_scale.dart`, `page_viewport.dart`, `text_size_tile.dart` and `reading_text.dart` clean. Feature 003's phone checks and converge (T016, T020 to T022) do not edit these files and are NOT waited for. If the 003 session is still editing one of them, stop and tell the owner; do not edit these files.

- [X] T028 Gate check: run `git log --oneline -20` and `git status --short`, confirm the condition above (ask the 003 session through `SendMessage` whether it still plans an edit of `text_size_tile.dart` or `reading_text.dart`), and record the commit hashes in `research.md` D11; commit the note only. T032 may be done earlier, right after T014, when the same two files are clean and the 003 session confirms it has no pending edit of them
- [X] T029 [US1] Write failing tests (red) `test/mushaf/reader_night_test.dart` (reader harness with `AppLookSettings` at Night): the top line, the active-wird pill, the page number and the bars use the Night tokens; the bottom bar floats as a 56 px pill inside the **unchanged 68 px slot** with the same five items and actions («استماع» and «اختبار» disabled with «قريباً»); the page box and `PageBox` base are identical in both looks (same `Rect`s for the page card at 100%); the Mushaf page is the Night page; a long press shows the highlight and opens the menu; a tap toggles the bars; a swipe turns the page; pinch zoom works; the look changes while the reader is shown, without a restart and on the same page (spec FR-006, FR-009, FR-015, SC-008; research D5)
- [X] T030 [US1] **First touch of `lib/mushaf/reader_screen.dart` in this feature**: colours only: the `Scaffold` background (line 161), the shadow (424), the top bar (606-677), the bar-slot floating pill and the `_BarItem`s (734-797), the browse banner and today-panel colours, all through `context.look`; the 68 px and 84 px slots and every handler stay; every existing reader, landscape, size and ayah-sheet test passes unchanged (spec FR-004, FR-006)
- [X] T031 [US2] **Second and last touch of `lib/mushaf/reader_screen.dart`**: `_PageItem` passes `context.read<AppLookSettings?>()`'s `pageLook` (Emerald when absent) to `MushafPageCard`; T029 goes green (spec FR-007, FR-009)
- [X] T032 [P] [US1] Test-first: `test/settings/text_size_night_test.dart` and `test/ayah/reading_text_night_test.dart` (the preview panel and the quiet text colours of the reading styles read the look; their pairs meet `requiredPairs`), then migrate `lib/settings/text_size_tile.dart` and `lib/ayah/ui/reading_text.dart` colours (skip what T012 already did); feature 003's tests for both pass unchanged (spec FR-004, FR-012)

**Checkpoint**: every screen, the page, the picture and the PDF follow the look.

---

## Phase 8: Polish and cross-cutting

- [X] T033 Run `flutter analyze` (no issues), the whole `flutter test` suite, `FULL_LAYOUT_CHECK=1 flutter test test/mushaf/page_layout_both_looks_test.dart` (all 604 pages, both looks) and `uv run --with pytest pytest tool/`; confirm with `git diff --stat` against the commit before T001 that `pubspec.yaml` (assets and fonts), `docs/research/licenses.md`, `lib/settings/about_screen.dart` credits, `assets/` and the page JSON are unchanged apart from the colour migration (spec FR-017); fix anything red in separate commits (spec SC-003, SC-004, SC-005)
- [ ] T034 On the owner's phone re-measure the Night picture and the Al-Baqarah PDF (build with `--dart-define=AYAH_MENU_TRACE=true`): picture offered under 3 s, 48-page PDF under 60 s, size within feature 002's limit, colours faithful when opened in the share target; record the numbers in `research.md` D4 and D12 (spec SC-007) **Not done (2026-11-21): the owner declined phone input; only a reader screenshot in Night was checked, see research.md D12.**
- [ ] T035 Real-device checklist (quickstart on-phone steps 1 to 6) in both looks: every screen of FR-004 with screenshots, cold start in Night without a flash, switching with Settings open, the page in Night (highlight, tap, swipe, pinch, page-turn under 300 ms), rotation, the largest system font on a small window; record results in `research.md` D12 and mark the checklist; commit (Constitution IX; spec SC-001, SC-002, SC-006, SC-008) **Not done (2026-11-21): the owner declined phone input; only a reader screenshot in Night was checked, see research.md D12.**
- [ ] T036 Ask the owner to confirm the four proposed Arabic strings of `contracts/ui.md` («المظهر», «زمردي وذهبي», «القارئ الليلي», the note) and the two lifted colours of `docs/design/night-reader.md`; apply any change in `look_tile.dart` and its tests (spec FR-018; Constitution VI)
- [ ] T037 Update `quickstart.md` with what the phone checks changed, then run `/speckit-converge` for feature 004 (with `SPECIFY_FEATURE_DIRECTORY=specs/004-night-reader-theme SPECIFY_FEATURE_NO_PERSIST=1`) and repeat implement and converge until it converges

---

## Dependencies and order

- Phase 1 (T001) is independent. Phase 2: T002 and T003 may run in parallel; T004 needs T003 (contrast) and T002; T005 needs T002; T006 needs T004 and T005.
- **US1 (T007 to T017)** needs Phase 2. T008 may run beside T007; T010, T011, T013 and T015 are in different files and may run in parallel after T004; T009 needs T008; T016 after the screen migrations.
- **US2 (T018 to T021)**, **US3 (T022 to T025)** and **US4 (T026, T027)** need only Phase 2 (and T019 for `pageLook`), not the screen migrations of US1; US3 needs T019 (the page look) and US4 needs T007 (the Settings screen). T027 edits `settings_screen.dart` after T014.
- **Phase 7** needs the 003 gate (T028) and, for the look hand-over, T019 to T021; T030 and T031 are the only edits of `reader_screen.dart` and follow T029 and each other.
- **Phase 8** needs everything; T034 needs T025 and T031; T035 needs T017, T031 and T032.

## Parallel examples

- Phase 2: `T002` (look choice) and `T003` (contrast) together.
- After `T004`: `T008` (wird marker), `T010` (wird form), `T011` (bookmarks), `T013` (PDF strip), `T015` (About) in separate files.
- After Phase 2: US2 (T018 to T021), US3 (T022 to T025) and US4 (T026, T027) can be taken by different people as they touch different files.

## Implementation strategy

- **MVP**: Phase 2 and US1 (T001 to T017): the owner can already switch the look and see every screen but the reader in Night.
- **Then** US2 (the page card) and Phase 7 (the reader hands the look to the page and wears the Night chrome), which together give the Night reading experience; US3 and US4 are small and independent.
- Until T030 and T031 land, a Night build shows the reader's bars and page in Emerald colours; do not hand a build to the owner for a Night check before then unless the owner asks for the mixed state.
- Each phase ends with a checkpoint where the whole suite is green and Emerald is unchanged.
