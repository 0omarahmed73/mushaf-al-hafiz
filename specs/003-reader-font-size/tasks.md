# Tasks: Text Size (Font Size)

**Input**: `specs/003-reader-font-size/` (spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md)

**Rules**: test-first (a failing test is written and committed before the code that makes it pass); one commit per
task; run `dart format` only on explicit file paths; existing tests of features 001 and 002 are never edited (new
tests go in new files) and must keep passing (spec SC-008); `lib/mushaf/reader_screen.dart` is touched only in
T014 and T017; the page card, page data, fonts, renderer, picture and PDF are never touched (research D8).
Commit trailer: `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.

## Phase 1: Foundational (the setting, blocks every story)

- [X] T001 Test-first: `test/settings/text_size_test.dart`, then `lib/settings/text_size.dart` (`TextSize.steps` 80..150 by 10, `defaultPercent` 100, `factor`, `parse`: null/empty/not a number → 100, outside 80..150 → 100, inside the range → nearest step with ties to the lower step, never throws) (data-model.md TextSize; spec FR-014)
- [X] T002 Test-first: `test/settings/text_size_settings_test.dart` (in-memory drift as in the wird repository tests), then `WirdRepository.textSizeRaw` / `setTextSizePercent` in `lib/wirds/wird_repository.dart` (key `textSizePercent`) and `lib/settings/text_size_settings.dart` (`load`, `set` snaps and saves and notifies only on change, `reset`, `reload`; default when nothing is stored or the value is bad) (data-model.md Stored setting and TextSizeSettings; spec FR-003, FR-013, FR-014)
- [X] T003 Provide the setting: add `textSize` to `MushafApp` in `lib/app.dart` as `ListenableProvider<TextSizeSettings?>.value`, create and `load()` it in `lib/main.dart` before `runApp`, add it to the test harnesses in `test/support/` (a new `text_size_harness.dart`, no edit of existing support files) and a small test `test/settings/text_size_provider_test.dart` (a widget under `MushafApp(textSize: …)` reads the same instance; a null provider reads as 100%) (contracts/dart-interfaces.md)

**Checkpoint**: the percent can be stored, read and observed; nothing visible changes yet.

## Phase 2: User Story 1 - Bigger or smaller tafsir, translation and meanings, one Settings slider (P1)

**Goal**: «حجم الخط» in Settings with a live preview; the three ayah texts follow it; it is kept between launches.

**Independent Test**: move the slider to 150% and 80%: preview and the three ayah views change, header and rows do not; restart: kept; at 100% everything is as before.

- [X] T004 [P] [US1] Test-first: `test/ayah/reading_text_test.dart`, then `lib/ayah/ui/reading_text.dart`: `ReadingStyles(factor)` returns today's sizes times the factor (arabic 17/1.8, english 17/1.6, meaning word 18 bold, meaning text 16/1.7, small 12), `ReadingScope` reads `TextSizeSettings` (1.0 when null) and clamps the system text scale so that `system x factor` is at most 3.0 (research D4; spec FR-006)
- [X] T005 [US1] Test-first: `test/ayah/reading_size_test.dart` (tafsir, translation and meanings at 80% and 150% in the ayah-sheet harness: panel texts scale, the header title and source lines and the menu rows do not, the longest sample entry still scrolls to its last line, a phone text scale of 2x with 150% is capped), then use `ReadingScope.of` in `lib/ayah/ui/sheet_detail.dart` (`Paragraphs` and the panel), `tafsir_view.dart`, `translation_view.dart`, `meanings_view.dart`; the existing ayah view tests pass unchanged (spec FR-005, FR-006, SC-004)
- [X] T006 [P] [US1] Test-first: `test/settings/text_size_tile_test.dart`: title «حجم الخط» and value «100%», a `Slider` with 8 stops (min 80, max 150, 7 divisions) and the 100% mark, moving it changes the preview font sizes at once and saves through `TextSizeSettings`, «معاينة» with an Arabic and an English sample (LTR) using `ReadingStyles`, the note, «الحجم الافتراضي» disabled at 100% and returning to 100% when pressed, semantics label «حجم الخط، 120%», targets at least 48 px (contracts/ui.md; spec FR-001, FR-002, FR-004, FR-017)
- [X] T007 [US1] Implement `lib/settings/text_size_tile.dart` until T006 passes and add it to `lib/settings/settings_screen.dart` between the reminders and the backup sections; add `test/settings/settings_text_size_test.dart` (the row is on the screen; the existing settings tests and the small-phone no-overflow test pass unchanged)
- [ ] T008 [US1] On the phone check US1 (quickstart section 2, first four rows): slider feels live, the three ayah views at 150% and 80%, longest tafsir scrolls to its end, size kept after closing the app; record in `research.md` D5 notes; commit

**Checkpoint**: US1 works alone; the Mushaf page is still unchanged.

## Phase 3: User Story 2 - Bigger or smaller Mushaf page, same layout (P2)

**Goal**: the page follows the size; a bigger page moves sideways and a swipe from the side edge turns the page.

**Independent Test**: at 150% open pages 1, 2, 293, 604: same lines and words, drag in all directions, an edge swipe turns the page, a middle drag does not.

- [X] T009 [P] [US2] Test-first: `test/mushaf/page_scale_test.dart`, then `lib/mushaf/page_scale.dart` (`kLandscapePageWidth`, `kPageAspect`, `PageBox` base/scaled/content/fit/startOffset, `PageTurn`, `edgeTurn`): every fit row of research D2 in portrait and landscape, start offset at the top right, `edgeTurn` next/previous/none for both edges, short drag, vertical-ish drag, fast fling, a page not wider than the viewport (research D2, D3; contracts/dart-interfaces.md)
- [X] T010 [P] [US2] Test-first (characterisation, must pass on the current page code): `test/mushaf/page_layout_invariance_test.dart`: (a) all 604 page JSON files at all 8 steps: the font size derived from the scaled box times the 16.15 em widest line fits the text width, and words per line and line count equal the data; (b) real fonts on pages 1, 2, 3, 293, 604 and the widest-line pages at 80% and 150%: `line-1..` hold the same word keys in the same order as at 100% and no layout exception (spec FR-009, SC-003)
- [X] T011 [US2] Write failing tests `test/mushaf/page_viewport_test.dart`: `fits` centres a smaller page with even margins and no scrolling; `scrollsVertically` keeps today's `landscape-scroll` structure and an unlocked pager; `pansBothWays` (key `page-pan`) starts at the top right, a drag moves it in both axes and stops at the edges, a drag from the middle that ends past an edge does not call `onEdgeTurn`, a drag that starts at the left edge and moves right at least 56 px calls `onEdgeTurn(next)`, from the right edge moving left calls `previous`, a vertical-ish drag at an edge does nothing; pinch zoom 1x..3x of the scaled page and no edge turn while zoomed; `onLockChanged` is true for `pansBothWays` and while zoomed, false otherwise; a long press on a word and a tap still reach their handlers (research D3)
- [X] T012 [US2] Implement `lib/mushaf/page_viewport.dart` (per-page `TransformationController`, the three fits, the edge turn on interaction end through `edgeTurn`, lock callbacks) until T011 passes
- [X] T013 [US2] Write failing reader tests `test/mushaf/reader_size_test.dart` (reader harness, `TextSizeSettings` at 150%): the page is bigger than the viewport in portrait and in landscape; a sideways drag does not turn the page; an edge swipe left→right turns to the next page, right→left to the previous, and the wird position is saved as for a normal swipe; the page that comes in starts at the top right and the outgoing page does not jump during the turn; tap toggles the bars; long press opens the menu with the highlight; the page number and the surah name still open their popups; pinch is limited to 1x..3x; at 80% the page is smaller and centred and a swipe turns it as before; changing the setting while the reader is shown applies without a restart
- [X] T014 [US2] Wire the reader (**first touch of `lib/mushaf/reader_screen.dart` in this feature**): `_PageItem` builds `PageViewport` with the factor from `TextSizeSettings`, the shared `_zoom` controller and `_zoomed` are replaced by per-page controllers and a small map of locks keyed by page, the pager physics are locked from that map, `onEdgeTurn` animates `nextPage` / `previousPage` with the same duration as a swipe, the landscape constants move to `page_scale.dart`; T013 and every existing reader, landscape and ayah-sheet test pass unchanged
- [X] T015 [P] [US2] Test-first (independence): `test/render/page_renderer_size_test.dart`: with `TextSizeSettings` at 150% in the widget tree, `OffscreenPageRenderer.picture(293)` and `printPage(293)` return the same bytes as at 100%, and the PDF job pages are unchanged (spec FR-011, SC-007); no production code expected, fix only if it fails
- [ ] T016 [US2] On the phone check US2 (quickstart section 2): pages 1, 2, 293, 604 at 150% and 80% in portrait and landscape; pan feel and no accidental turns; edge swipes both ways; incoming page starts at the top right with no jump; long press while panned; pinch; page-turn trace at 80%, 100%, 150% under 300 ms; record numbers in `research.md` D7 and decide there whether the largest step stays 150% (spec SC-006, SC-009); commit

**Checkpoint**: the Mushaf page follows the setting without changing its layout.

## Phase 4: User Story 3 - Back to the default, and the size in a backup (P3)

**Goal**: one press returns to today's look; the size is part of the backup.

**Independent Test**: choose a size, press «الحجم الافتراضي»: texts and page are as before. Export, change, import: the exported size returns.

- [X] T017 [US3] Test-first: `test/backup/backup_text_size_test.dart` (export holds `textSizePercent`; import restores it and `TextSizeSettings.reload()` shows it; a backup without the key gives 100%; bad values `"abc"`, `"999"`, `"-5"` give 100% and the import still succeeds; nothing else in the backup changes) and `test/mushaf/reader_text_size_reload_test.dart`; then make the reader reload the setting after a restore (**second and last touch of `lib/mushaf/reader_screen.dart`**: in `_openSettings`, next to `_controller.reload()`, call `TextSizeSettings.reload()`) (spec FR-013, FR-014; research D6)
- [X] T018 [US3] Test-first acceptance: `test/mushaf/reset_text_size_test.dart` (harness with the tile, the reader and the ayah sheet at 150%; press «الحجم الافتراضي»: the preview, the open ayah texts and the page are at 100% at once, a restart value is 100%) (spec FR-004, FR-005)

**Checkpoint**: all three stories work together.

## Phase 5: Polish and cross-cutting

- [X] T019 [P] Ask the owner to confirm the proposed Arabic strings of `contracts/ui.md` (row title, value, note, reset, preview label, the two samples); apply any change in `text_size_tile.dart` and its tests; confirm that `docs/research/licenses.md` and `lib/settings/about_screen.dart` are unchanged (spec FR-015, FR-017; Constitution VI)
- [X] T020 Run `flutter analyze` (no issues) and the whole `flutter test` suite and `uv run --with pytest pytest tool/`; fix anything red in separate commits (spec SC-008) — 2026-11-20: 542 Flutter tests and 59 pytest pass; analyze clean for this feature (the one remaining info is in feature 004's `test/support/contrast_walk.dart`)
- [ ] T021 Real-device checklist: every row of `quickstart.md` section 2 on the owner's phone, including airplane mode, restart, export/import and the picture and PDF at 150%; record the results in `research.md` and mark the checklist; commit (Constitution IX)
- [ ] T022 Update `quickstart.md` with what the phone checks changed, then run `/speckit-converge` for feature 003 and repeat implement and converge until it converges

## Dependencies and order

- Phase 1 (T001–T003) first, in order. US1 (T004–T008) needs T003. US2 (T009–T016) needs T003 for the factor; T009, T010 and T015 may run beside US1 tasks (other files). US3 (T017, T018) needs T003 and T014 (it uses the reader).
- Within a story: tests, then code, then the phone check. T012 needs T009 and T011; T014 needs T012 and T013.
- The reader file is touched only by T014 and T017; `settings_screen.dart` only by T007; `wird_repository.dart` only by T002.
- Parallel examples: T004 with T006 with T009 with T010 (four different new files); T015 beside T012.

## Implementation strategy

1. MVP: Phase 1 + US1 (T001–T008): the setting, the slider and the readable ayah texts, with no risk to the Mushaf page.
2. Then US2, the risky part, behind the same setting, with its own phone check (T016) before anything else depends on it.
3. Then US3 and polish. If T016 shows the sideways pan and edge turn are not good enough, stop and take the fallback in plan.md Complexity Tracking to the owner (option B of FR-008).

## Phase 6: Convergence

- [X] T023 Sync the feature documents with what was built and decided: `spec.md` Status (Draft → Implemented) and the "proposed" wording of FR-017, the Arabic-strings heading and the last Assumption (owner confirmed 2026-11-20); `plan.md` Constitution Check row VI; `contracts/dart-interfaces.md` `ReadingStyles` members (`note` and `source`, not `small`); `tasks.md` is not rewritten, so record the T003 harness location (`ayah_harness.dart` option and `reader_harness.dart`), the T015 API names (`pdfPage`, `renderRgba`) and the now-clean analyze in `research.md` D8 instead per FR-017, Constitution VI, plan: Constitution Check (partial)
- [X] T024 End-to-end test `test/mushaf/text_size_end_to_end_test.dart`: the whole app with a loaded `TextSizeSettings`, the slider moved by a finger in Settings, then the reader's page and the tafsir, translation and meanings of an ayah at 150% and 80%, and a restart that reads the saved size back; checked to fail when the page wiring is removed, so the setting is proved applied through the real chain, not only per widget per FR-003, FR-006, FR-007, FR-016, SC-005 (owner report "the new font size not applied")
