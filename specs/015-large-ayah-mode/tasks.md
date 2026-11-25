# Tasks: Large Ayah Mode

**Input**: design documents in `specs/015-large-ayah-mode/` (spec.md, plan.md, research.md, data-model.md, contracts/,
quickstart.md); constitution 2.2.0

**Rules for every task**: test-first (Principle IX): a task that writes a test makes it fail for the right reason before the
next task makes it pass. One commit per task, with explicit paths only (`git commit -m ... -- <paths>`), never `git add -A`,
no branch. `lib/mushaf/mushaf_page.dart` is NOT edited by any task. Existing tests are not edited. Before each commit:
`flutter analyze` reports no issue and the touched tests pass. Speckit scripts run with
`SPECIFY_FEATURE_DIRECTORY=specs/015-large-ayah-mode SPECIFY_FEATURE_NO_PERSIST=1`; `.specify/feature.json` stays on 003.

**Format**: `- [ ] T### [P?] [Story?] description with file path`. [P] = can run in parallel (different files, no open
dependency).

## Phase 1: Setup

- [x] T001 [P] Write the failing `test/large_ayah/large_ayah_strings_test.dart` that pins every proposed string of
  `specs/015-large-ayah-mode/contracts/ui.md` exactly: «الآيات الكبيرة», «آية أو آيتان أو ثلاث في الصفحة، بخط كبير»,
  «عدد الآيات في الصفحة», «آية واحدة», «آيتان», «ثلاث آيات», «حجم الخط», «كبير», «أكبر», «أكبر جدًا», «تتبع ←», «المصحف»,
  «الرجوع إلى المصحف», and the header builder: `header(surahName: 'البقرة', first: 255, last: 255, page: 42)` gives
  «البقرة ٢٥٥ · صفحة ٤٢», a range gives «البقرة ٥–٦ · صفحة ٣», a part gives «البقرة ٢٨٢ (١ من ٣) · صفحة ٤٨».
- [x] T002 Create `lib/large_ayah/large_ayah_strings.dart` with exactly those strings and the header builder (Arabic-Indic
  digits in the header), with a doc comment saying they are proposals until the owner confirms them (Principle VI); T001
  passes.

## Phase 2: Foundational (blocks every story)

### Settings (research D8, data-model.md)

- [x] T003 [P] Write the failing `test/large_ayah/large_ayah_settings_test.dart` on an in-memory database: the four keys
  and their rules verbatim from data-model.md — `largeAyah` `'true'`/`'false'`, off when absent; `largeAyahCount` `'1'`,
  `'2'`, `'3'`, 1 when absent or unusable; `largeAyahSize` `'1'`, `'2'`, `'3'`, 1 when absent or unusable (factors 2.0,
  2.5, 3.0); `largeAyahAt` `"surah:ayah"` of a real ayah, ignored when unusable (e.g. `'2:287'`, `'x'`, `'115:1'`).
  Parsing never throws; each setter writes at once; listeners hear only real changes; `reload()` picks up a value written
  behind its back.
- [x] T004 Add readers and writers for the four keys to `lib/wirds/wird_repository.dart` (in the pattern of `ayahTintRaw` /
  `setAyahTint`) and create `lib/large_ayah/large_ayah_settings.dart` (`LargeAyahSettings`, contracts/dart-interfaces.md);
  T003 passes.
- [x] T005 [P] Write `test/large_ayah/backup_keys_test.dart`: export a backup with the four keys set, wipe, import, and the
  four values are back; a backup without them restores with the defaults. Expected to pass at once (the backup carries every
  key, research "Measured"); if it fails, stop and report, the backup is not changed by this feature.

### Pure layout (research D1, D3)

- [x] T006 [P] Write the failing `test/large_ayah/screen_layout_test.dart` for `layoutPage` with plain widths: greedy
  wrapping right to left with `wordGap`; each ayah starts a new line; count 1, 2, 3; a screen takes up to `count` whole
  ayat while their lines fit and at least one; an ayah longer than `linesPerScreen` gets screens of its own, cut only
  between words, with `part` (1..of) on each; surah-opening lines (title, basmala, in page order) belong to the screen of
  the next ayah and count as lines (At-Tawbah: title only); a word wider than the line gets its own line; no screen holds
  two pages; `ArgumentError` for count outside 1..3, `linesPerScreen` < 3 (a title, a basmala and a line of words must fit), `lineWidth` <= 0.
- [x] T007 Create `lib/large_ayah/screen_layout.dart` (`LayoutAyah`, `OpeningLine`, `LargeScreen`, `layoutPage`, contracts/
  dart-interfaces.md), no Flutter widget import; T006 passes.
- [x] T008 [P] Write `test/large_ayah/whole_mushaf_test.dart` (SC-001): read the 604 files of `assets/mushaf/pages` and
  `assets/mushaf/meta.json`; for count 1, 2, 3 and `linesPerScreen` 6 and 12, with widths of 1 unit per word and a second
  run with widths from the glyph's character count, check that the screens of every page hold every word of its ayat
  exactly once, in order, never two pages, each split ayah's parts consecutive and numbered 1..of, and the 6,236 ayat
  appear once each in Mushaf order; and a third run with real glyph widths (the QCF fonts loaded) for pages 1, 2, 48, 50,
  187, 300, 582 and 604 at size steps 1 and 3. Fails until T007 exists; passes with T007 or the layout is fixed.

### Navigation and measuring (research D4, D5)

- [x] T009 [P] Write the failing `test/large_ayah/screen_navigator_test.dart` with a fake `ScreenSource`: `next` within a
  page, from a page's last screen to the next page's first, null after page 604's last; `previous` symmetric, null before
  page 1's first; `screenOfAyah` gives the first part of a split ayah; `firstOf(page)`; each page's screens are asked for at
  most once per navigator.
- [x] T010 Create `lib/large_ayah/screen_navigator.dart` (`ScreenRef`, `ScreenSource`, `ScreenNavigator`); T009 passes.
- [x] T011 [P] Write the failing `test/large_ayah/word_measurer_test.dart` with the real QCF fonts of pages 1, 48 and 604
  loaded (as `test/render/page_renderer_test.dart` loads them): widths are positive, scale linearly with the font size
  (within 1 px), are cached per (page, size) for the last 8 pages, and a page whose font is not loaded waits for
  `PageFontLoader.ensure`.
- [x] T012 Create `lib/large_ayah/word_measurer.dart` (`WordMeasurer`, `TextPainter` in the page font) and the
  `ScreenSource` that joins `MushafRepository.loadPage`, `WordMeasurer` and `layoutPage` for a given size, count and screen
  box in `lib/large_ayah/page_screens.dart`; T011 passes.

**Checkpoint**: the settings, the layout, the navigator and the measurer are done and tested; no UI yet.

## Phase 3: User Story 1 — read one ayah (or a few) at a large size (P1) MVP

**Goal**: the reader turns the mode on and reads screen by screen in the Madinah glyphs at the large size.
**Independent test**: page 50 → mode on → the first screen is the opening of Al Imran and 3:1; swipes go forward and back in
order; mode off → page 50.

- [x] T013 [P] [US1] Write the failing `test/large_ayah/large_ayah_screen_test.dart`: `LargeAyahScreen` draws each word as
  its glyph in `qpc_p<page>` keyed `ValueKey('lw<id>')`, the header of T002, the opening title (Reem Kufi) and basmala as
  the Mushaf page draws them, «تتبع ←» on a part that goes on; at 360 dp and size step 1 the glyph font size is at least
  twice the Mushaf page's at 100 % (SC-002); a system text scale of 2.0 does not change it; page 48's screens at 320 dp
  portrait and in landscape overflow nothing and contain no scrollable (SC-005); Emerald & Gold and Night colours from
  `PageLook`, contrast at least 4.5:1 for the header and «تتبع» through `test/support/contrast_walk.dart`.
- [x] T014 [US1] Create `lib/large_ayah/large_ayah_screen.dart` (font size `factor × (shortest side − 32) / 16.2`, line
  height 1.8 em, right-aligned lines, `MediaQuery.withNoTextScaling`, research D1, D2, D9); T013 passes.
- [x] T015 [P] [US1] Write the failing `test/large_ayah/large_ayah_pager_test.dart`: the anchored pager (research D5) starts
  at its anchor; a left-to-right swipe shows the next screen coming in from the left; it crosses pages; it stops at 1:1's
  screen; past page 604's last screen it calls `onPastEnd` once (as `LastPageSwipe`); `onScreenShown` fires once per
  settled screen; re-anchoring keeps the given first ayah on screen; a tap calls `onTap`.
- [x] T016 [US1] Create `lib/large_ayah/large_ayah_pager.dart` (virtual-index `PageView`, `reverse: true` in an LTR box,
  bounded start physics, neighbour pages laid out ahead); T015 passes.
- [x] T017 [P] [US1] Write the failing `test/large_ayah/reader_mode_test.dart` (first group) through
  `test/support/reader_harness.dart`: with `largeAyah` off the reader shows the Mushaf as before; turning it on (Settings
  tile, T020) on page 50 shows the screen of 3:1 with Al Imran's opening; the top-bar button «المصحف» turns it off and the
  Mushaf shows the page of the screen; with `largeAyah` on at start the app opens in the mode; a first install opens on the
  Mushaf; the Mushaf page item is built no differently when the mode is off (compare with the existing reader tests).
- [x] T018 [US1] Wire the mode into `lib/mushaf/reader_screen.dart`: while `LargeAyahSettings.on`, show `LargeAyahPager` in
  the pager's place under the same bars and today panel; the «المصحف» button in the top bar (48 px at least); `onPastEnd`
  opens the khatm screen as the last page does; `lib/mushaf/mushaf_page.dart` untouched. Provide `LargeAyahSettings` in
  `lib/main.dart` next to `TextSizeSettings` and reload it after a restored backup. T017 passes except its Settings-tile
  scenario, which T020 makes pass.
- [x] T019 [P] [US1] Write the failing `test/large_ayah/settings_tile_test.dart`: the tile «الآيات الكبيرة» is the first
  entry of Settings, its switch writes `largeAyah` and returns to the reader in the mode; the count and size choices show
  only while it is on; nothing overflows at 320 dp with a 2x system font; targets at least 48 px.
- [x] T020 [US1] Add the tile to `lib/settings/settings_screen.dart` (a new widget in `lib/large_ayah/large_ayah_tile.dart`);
  T019 and the remaining part of T017 pass.

**Checkpoint**: US1 works alone (count 1, size step 1).

## Phase 4: User Story 2 — choose how many ayat a screen holds (P1)

**Goal**: 1, 2 or 3 ayat per screen, and the size step, chosen and kept.
**Independent test**: change the count while on 2:5 and the screen regroups starting at 2:5; restart keeps it.

- [x] T021 [P] [US2] Add the failing group "count and size" to a new `test/large_ayah/regroup_test.dart`: choosing «آيتان»
  on 2:5 shows 2:5 and 2:6; «آية واحدة» shows 2:5 alone; «ثلاث آيات» shows 2:5 to 2:7 if they fit, fewer otherwise (FR-009);
  a size step change and a rotation re-anchor at the same first ayah (a split ayah at its first part); the choices survive
  a restart; the one-line preview of 1:1 in the size choice follows the step.
- [x] T022 [US2] Implement the count and size choices in `lib/large_ayah/large_ayah_tile.dart` and the re-anchoring on
  count, size and screen-box change in `lib/large_ayah/large_ayah_pager.dart`; T021 passes.

## Phase 5: User Story 3 — everything else works in the mode (P2)

**Goal**: wirds, position, bookmarks, the ayah sheet, search and jumps, both looks.
**Independent test**: inside the active wird read into the next page and the wird moved; long-press opens the same sheet.

- [x] T023 [P] [US3] Write the failing `test/large_ayah/mode_position_test.dart`: each settled screen calls
  `ReaderController.onPageShown(screen.page)`, so inside the active wird reading from page 10 into 11 sets the wird to 11,
  and in browse mode nothing moves; `largeAyahAt` holds the first ayah of the screen; on restart the mode opens at
  `largeAyahAt`'s screen when that ayah is on the controller's page, else at the page's first screen (research D6); a jump
  (index, «اذهب إلى صفحة», a bookmark, a reminder payload) opens the target page's first screen; a search `AyahTarget` opens
  the screen holding that ayah with it highlighted; a wird switch and a restored backup re-anchor.
- [x] T024 [US3] Implement the position, anchor and jump wiring in `lib/mushaf/reader_screen.dart` and
  `lib/large_ayah/large_ayah_pager.dart`; T023 passes.
  (Done in T018, c824ed8: the wiring went in with the reader change; T023's tests passed on it at once, so this task
  added no code.)
- [x] T025 [P] [US3] Write the failing `test/large_ayah/mode_actions_test.dart` (through
  `test/support/ayah_bookmark_harness.dart` and `tint_harness.dart`): a long press on any word, including a word of a
  non-first part of 2:282, highlights the whole ayah's words on screen and opens `showAyahSheet` for that ayah and its page
  with the same rows as in the Mushaf; the highlight goes when the sheet closes; an ayah bookmark tints its words (and not
  with the tint switch off); the page bookmark icon and «علامات» act on the screen's page; the Night look applies.
- [x] T026 [US3] Pass the reader's `_openAyahMenu`, highlight set and `ayahMarks` to the mode in
  `lib/mushaf/reader_screen.dart` and map them to word ids in `lib/large_ayah/large_ayah_screen.dart`; T025 passes.
  (Done in T018, c824ed8: as T024; T025's tests passed on it at once.)

## Phase 6: Polish and cross-cutting

- [x] T027 [P] Write `test/large_ayah/mode_performance_test.dart` (a guard, not a promise to the owner): laying out a page's
  screens takes under 30 ms in the test environment for pages 1, 48, 300 and 604, and a swipe builds the incoming
  `LargeAyahScreen` at most once (as feature 010's rebuild counts in `test/support/motion_harness.dart`), and turning the
  mode on shows the first screen within 300 ms of the page font being loaded.
- [x] T028 Run `flutter analyze` and the whole `flutter test`; fix only this feature's code until both are clean; record the
  numbers in `specs/015-large-ayah-mode/quickstart.md` under a "Run" note.
- [x] T029 Show the owner every string of `lib/large_ayah/large_ayah_strings.dart` in short Egyptian Arabic and record his
  answer in `specs/015-large-ayah-mode/spec.md` Clarifications; change the strings and T001's test only as he says
  (Principle VI).
- [x] T030 After the owner's «سطّب», build the release APK, install it over the current build, and walk
  `specs/015-large-ayah-mode/quickstart.md` steps 1 to 10 with him on the phone; record each step's result, including
  SC-006, in `specs/015-large-ayah-mode/quickstart.md` (Principle IX). Never push without his «ارفع».
  - Install 2026-11-26: the phone (<phone>) had the Google Play build (versionCode 1, Google's key), so this APK could
    not go over it. The owner chose «أشيل نسخة بلاي وأسطّب نسختي», named the backup of 2026-11-25 20:22 (3 wirds, 1
    bookmark; the file DOC-20261125-WA0072..json, copied to ~/mushaf-backups/) as his backup, and answered «امسح وسطّب».
    Uninstalled, then the release APK (179 915 520 bytes, versionCode 2, the owner's upload key) installed: Success,
    00:58:03. Play updates do not reach this build until the same steps are done the other way round.
    The owner imported that backup in the app and answered «رجعت» (his data is back).
    The walk of quickstart steps 1 to 10: every step «أيوه», sizes «التلاتة كويسين» (quickstart.md "Phone walk").
- [x] T031 Converge: `/speckit-converge` against spec, plan and constitution 2.2.0; write what the code now does into
  `specs/015-large-ayah-mode/spec.md` (Status and a Convergence note).

## Dependencies

- Phase 1 → Phase 2 → US1 → US2 → US3 → Polish. US2 and US3 both need US1's pager and reader wiring (T016, T018); they
  touch different code and can be done in either order after US1, but both edit `large_ayah_pager.dart` (T022, T024), so not
  at the same time.
- Inside Phase 2: T003 → T004; T006 → T007 → T008 (passes); T009 → T010; T011 → T012 (needs T007 and T010 for the
  `ScreenSource`). T005 needs T004.
- T029 can happen any time after T002; T030 needs T028 and T029.

## Parallel examples

- After T002: T003, T006, T009, T011 (four test files, no shared file).
- In US1: T013 and T015 together; T017 and T019 together once T014 and T016 are done.
- In US3: T023 and T025 together.

## Implementation strategy

MVP = Phases 1 to 3 (US1 with one ayah per screen at the first size): it already answers the owner's request for one ayah
per screen. Then US2 (the choice of 1, 2 or 3 and the size), then US3 (wirds, sheet, bookmarks, search), then polish, the
owner's string check and the phone walk.

## Phase 7: Convergence

- [x] T032 Add to `test/large_ayah/mode_position_test.dart` a wird switch (a second wird on another page, chosen from «أوراد») and a restored backup (Settings import) while the view is on, each opening the first screen of the new position's page, per US3 / T023 (partial)
  - Done for the wird switch. The restored-backup case is not tested: a widget test that imports a backup while the
    reader's database streams are open hung in the test clock (twice, over 400 s each); the re-anchor after a restore is
    in `_openSettings` (reader_screen.dart) and checked by reading only.
- [x] T033 Add to `test/large_ayah/reader_mode_test.dart` the forward swipe past the last screen of page 604 opening the khatm supplication screen from the view, per Edge Cases (khatm) (partial)
- [x] T034 Record in `specs/015-large-ayah-mode/spec.md` the two rules built at implementation: a surah title on a page's last line stays at the end of that page's last screen (FR-008), and a box too short for 3 lines at the chosen size gets the size that holds 3 (FR-010), per FR-008 / FR-010 (unrequested)
- [x] T035 Write the Status and a "Convergence 2026-11-26" note in `specs/015-large-ayah-mode/spec.md` (what is built, the owner's answers, what is not done), per T031 (partial)
