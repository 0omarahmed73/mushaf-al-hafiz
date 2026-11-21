# Tasks: Khatm Dua After the Last Page

**Input**: `specs/005-khatm-dua/` (spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md,
checklists/khatm.md)

**Rules**: test-first (a failing test is written and run red before the code that makes it pass); one commit per
task; `git add` explicit paths only and `dart format` on explicit files only (other sessions edit this tree: never
`git add -A`); **new tests go in NEW files** (`test/khatm/`): the tests of features 001 to 004 are never edited and
must keep passing (spec FR-018, SC-007). Check `git status` and `git log` before every task. `.specify/feature.json`
is NOT changed (speckit scripts run with `SPECIFY_FEATURE_DIRECTORY=specs/005-khatm-dua
SPECIFY_FEATURE_NO_PERSIST=1`). The Quran text, page data, fonts, page geometry and layout code are never touched.
**Two existing files are edited, each once, in one small additive commit, only after `git status` and `git log --
<file>` and after the feature 004 session (`local_9648d7e1-a2ae-45f8-a103-a32be38e313a`) was sent the exact lines by
`SendMessage`: `lib/mushaf/reader_screen.dart` (T007) and `lib/settings/about_screen.dart` (T010).** Arabic UI strings
and the dua's wording are proposals until the owner confirms them (T011): the feature is not done before that.
Commit trailer: `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.

Key: **FR/SC** are the spec's requirement and success-criterion ids; "data-model.md X" is the cited definition.

## Phase 1: Setup

- [X] T001 Add the bundled text `assets/khatm/dua.txt` holding the **proposed, unconfirmed** wording of the spec's
  Assumptions as the shape data-model.md `Dua text (bundled asset).Content` requires (UTF-8, paragraphs separated by one
  blank line, no title or markup, one final newline) and the single pubspec line `- assets/khatm/dua.txt` under
  `flutter: assets:`; run `flutter pub get`. Do not add anything else to the asset: it is the app's only dua
  (data-model.md `Dua text (bundled asset).Only one`; the file stays tiny: data-model.md `Dua text (bundled asset).Size`, a few hundred bytes; spec FR-015, Constitution III)
- [X] T002 Create `lib/khatm/dua_strings.dart` with exactly the constants of contracts/dart-interfaces.md
  (`kDuaTitle`, `kDuaNote`, `kDuaAmen`, `kDuaUnavailable`, `kDuaCreditName`, `kDuaCreditUse`, `kDuaCreditNote`), all
  marked in a doc comment as proposals awaiting the owner (T011); nothing else in the file (spec FR-009, FR-016,
  FR-019)
- [X] T003 [P] Add the section «Feature 005 (khatm dua)» to `docs/research/licenses.md` as research D6 describes: the
  wording is customary text with no fixed source, found on mawdoo3.com «دعاء ختم القرآن» (updated 2024-08-06) and
  albayan.ae (2024-04-08), both read on 2026-11-20, neither gives a book, narrator or grading, neither ties it to the
  Madinah Mushaf, both say there is no fixed text from the Prophet ﷺ; no text of those sites other than the
  supplication is used; the entry is marked «awaiting the owner's confirmation (T011)» (spec FR-016, Constitution V)

---

## Phase 2: Foundational (blocks every story)

**Purpose**: the pure gesture rule and the text loader, both Flutter-free where possible. Nothing visible changes.

- [X] T004 Test-first: `test/khatm/last_page_swipe_test.dart` (red) with every case of contracts/dart-interfaces.md:
  47.9 px slow → false, 48 px slow → true, 16 px at 300 px/s → true, 15.9 px at 5000 px/s → false, 16 px at 299 px/s →
  false, negative and zero overscroll never add, two gestures never add together, `end()` twice answers false the
  second time, `start()` clears the distance, `distance` reports the sum; then `lib/khatm/last_page_swipe.dart` with no
  Flutter import (data-model.md `LastPageSwipe.forward distance` and `LastPageSwipe.constants`: 48, 16, 300; spec FR-001;
  research D1, D2)
- [X] T005 Test-first: `test/khatm/dua_text_test.dart` (red): `DuaText.parse` splits at blank lines and drops the final
  newline only (diacritics, spaces and order kept), `text` joins the paragraphs by one blank line and equals the file's
  text, `load` over the real `assets/khatm/dua.txt` (`rootBundle`) equals the file byte for byte, a missing asset and an
  empty file both throw `DuaUnavailable` (use `test/support/map_bundle.dart`), the real asset is under 4 KB (data-model.md `Dua text (bundled asset).Size`) and has no empty paragraph, and `parse` never returns an empty paragraph even when a file has two blank lines in a row (`text` then joins the remaining paragraphs by one blank line; for the real asset, which has exactly one blank line between paragraphs, it equals the file's text); then `lib/khatm/dua_text.dart`
  (data-model.md `DuaText.paragraphs` and `Dua text (bundled asset).Integrity`; spec FR-015, FR-019, SC-006)

---

## Phase 3: User Story 1 - Swipe at page 604 opens the dua, «آمين» goes to page 1 (Priority: P1) 🎯 MVP

**Goal**: spec User Story 1. **Independent test**: with a reader on page 604 a forward swipe opens the dua and «آمين»
shows page 1 with page 1 saved; on pages 1 to 603 the swipe only turns the page.

- [X] T006 [US1] Test-first: `test/khatm/khatm_dua_screen_test.dart` (red; the screen is pumped alone under
  `MaterialApp(theme: buildAppTheme(look: ...), locale: ar, localizationsDelegates: GlobalMaterialLocalizations.
  delegates)` with `DefaultAssetBundle` over a `MapBundle`): the AppBar title `kDuaTitle`, the label `kDuaNote` above the
  panel (key `khatm-note`), the panel (`khatm-panel`) with one `khatm-text-<n>` per paragraph whose joined text equals the
  asset, «آمين» (`khatm-amen`) is below the panel in the same scrollable and at least 52 px high, the dua's `TextStyle`
  has the theme's interface font and no Quran family (the page fonts are named `QCF…`/`p<n>`; the Amiri Quran family
  is not used either), both looks (Emerald and Night) draw the panel in `cardFill` with `cardBorderStrong` and
  `rowRadius(14)`, tapping «آمين» pops `true`, the back arrow pops with no result, an unreadable asset shows
  `khatm-unavailable` with `kDuaUnavailable` while «آمين» and back still work; then `lib/khatm/khatm_dua_screen.dart` as
  research D3 and contracts/ui.md describe, with colours only from `context.look` and the text from
  `ReadingScope.of(context).arabic` inside `ReadingScope` (spec FR-009, FR-010, FR-011, FR-012, FR-019; contracts/ui.md
  «The screen»)
- [X] T007 [US1] Reader wiring, one commit. **Step 1**: run `git status` and `git log -- lib/mushaf/reader_screen.dart`,
  then `SendMessage` to `local_9648d7e1-a2ae-45f8-a103-a32be38e313a` naming the exact additions: one import of
  `../khatm/khatm_dua_screen.dart` and `../khatm/last_page_swipe.dart`, fields `_lastSwipe` and `_duaOpen`, a
  `NotificationListener<ScrollNotification>` around the `PageView.builder`, the methods `_onPagerScroll` and `_openDua`,
  and one branch at the top of `_onEdgeTurn`; if that session has the file uncommitted, wait for its commit (say so
  to the owner) and do not touch the file meanwhile. **Step 2** (red first): `test/khatm/reader_khatm_test.dart` over
  `test/support/reader_harness.dart` (extend the start page to 604 with a helper in the test file itself): a forward
  drag of 120 px on page 604 opens `khatm-amen`; a fling opens it; a 12 px brush does not; a drag on page 603 turns to
  page 604 and opens nothing; a jump to page 604 from the index (`jumpTo` through `ReaderController` or the index
  screen) opens nothing; two flings in quick succession open one screen (`_duaOpen`, data-model.md `Reader state
  added._duaOpen`); at a 150% reading size (a wide page, pager locked) the edge turn on page 604 opens it; a zoomed
  page 604 (pinch) with a sideways drag does not; «آمين» shows page 1 (the pager is on index 0 and the page number
  shows 1) and the saved position is 1 for a reader following a wird (the wird's page) and for browse mode (the last
  viewed page); after «آمين» at most 3 pages exist in the tree (`find.byType(PageViewport)`), so `jumpToPage(0)` did not build the pages between (research D5); a switch of wird and a notification payload that land on page 604 open nothing; the khatma count, today's portions and the bookmarks are unchanged after «آمين». The harness `pumpSizedReader` follows a wird, so browse mode, the wird switch and the notification need a small pump helper in the test file itself. **Step 3**: the edits
  of contracts/dart-interfaces.md «Reader», nothing else in the file. **Step 4**: the whole of `test/mushaf` and
  `test/khatm` pass (spec FR-001 to FR-006, FR-008, FR-018; SC-001, SC-002, SC-004, SC-007; research D1, D5). *Done: 13 tests in `test/khatm/reader_khatm_test.dart`; the notification payload is not a separate case because `openPayload` ends in `switchWird` (tested) or `jumpTo` (the go-to-page test goes through it), so no arrival route has a gesture of its own.*

**Checkpoint**: the MVP works: swipe at 604, read, «آمين», page 1.

---

## Phase 4: User Story 2 - Leave the dua without finishing it (Priority: P2)

**Goal**: spec User Story 2. **Independent test**: back from the dua leaves page 604 and the saved position.

- [X] T008 [US2] Test-first: `test/khatm/reader_khatm_back_test.dart` (red if anything is wrong; written against the
  reader of T007): the back arrow closes the dua and the reader still shows page 604 with the saved position 604 (wird
  and browse mode); the system back (`WidgetTester.pageBack` or `binding.handlePopRoute`) does the same; a second forward
  swipe opens the dua again; changing the window size (rotation) and sending the app to the background and back
  (`AppLifecycleState.paused` then `resumed`) while the dua is open keep it open (FR-014); opening and going back changes no khatma count, portion, bookmark or setting. If every
  case passes at once, say so in the commit message (the behaviour is the route's own pop: T007 writes nothing on a
  `null` result) and prove each assertion can fail by reverting one line temporarily (spec FR-007, FR-008; SC-002). *Done: all 7 cases passed at once (no fix needed, back is the route's own pop); with `if (amen == true && mounted)` temporarily changed to `if (mounted)` 6 of the 7 failed, then the line was restored. In wird mode the harness never writes the last viewed page, so the test compares it with its value before the dua.*

---

## Phase 5: User Story 3 - Readable and not mistaken for the Quran (Priority: P2)

**Goal**: spec User Story 3. **Independent test**: the dua screen alone, both looks, three reading sizes, 320 dp with a
2x system font. Needs only T006.

- [X] T009 [P] [US3] Test-first: `test/khatm/khatm_dua_look_test.dart`: the text follows the reading size (the paragraph's
  font size is `ReadingScope.of(context).arabic` at 80%, 100% and 150% through `TextSizeSettings`, with the system
  text scale capped as `ReadingScope` does), both looks pass `contrastIssues` from `test/support/contrast_walk.dart` with
  nothing reported, nothing overflows on a 320 dp window with a 2x system font in both looks and «آمين» is reached by
  scrolling (`dragUntilVisible`), every tappable is at least 48 px, the semantics tree has the AppBar title as a
  heading, «آمين» as a button with its label and the back arrow as a button labelled «رجوع», the dua paragraphs are in
  reading order. Any assertion that is red is fixed in `lib/khatm/khatm_dua_screen.dart`; any that passes at once is
  shown red once by a temporary one-line change, reverted before the commit (spec FR-010 to FR-013; SC-005). *Done: 14 tests, all passed at once (the screen of T006 already met them); each group was shown red by a temporary change that was reverted: a fixed 17 px style (reading size), the panel text in the panel's own colour (contrast), a 36 px button with a shrink-wrapped target (48 px), the title wrapped in `ExcludeSemantics` (heading).*

---

## Phase 6: User Story 4 - The wording is the owner's, and its source is told honestly (Priority: P3)

**Goal**: spec User Story 4. **Independent test**: About shows the credit; the shown text equals the confirmed text.

- [X] T010 [P] [US4] Test-first: `test/khatm/khatm_about_test.dart` (red): `AboutScreen` shows one credit row with
  `kDuaCreditName`, `kDuaCreditUse` and `kDuaCreditNote`, and the sentence says there is no fixed text from the Prophet
  ﷺ; then the one-tuple addition to `AboutScreen.credits` in `lib/settings/about_screen.dart` (`(kDuaCreditName,
  kDuaCreditUse, kDuaCreditNote)`). **Before editing**: `git status` and `git log -- lib/settings/about_screen.dart`,
  `SendMessage` to `local_9648d7e1-a2ae-45f8-a103-a32be38e313a` with the exact line (feature 004's T015 colours this file),
  and wait for its commit if it is uncommitted; the existing About tests pass unchanged (spec FR-016; research D6, D7). *Done: the file was clean (last commit 004's T015, 1c42467), the 004 session was told before the edit; the new test was red (2 of 3), then green with the one tuple and one import; `test/settings/about_screen_test.dart` and `about_night_test.dart` pass unchanged.*
- [X] T011 [US4] **Owner confirmation, blocks «done».** Show the owner, in Egyptian Arabic and with the exact text of
  `assets/khatm/dua.txt` and the source line of `kDuaCreditNote`, the four strings of `lib/khatm/dua_strings.dart` and
  the research summary (no fixed text from the Prophet ﷺ; the wording circulates without a named book), and ask with
  `AskUserQuestion`: keep as it is, add lines (and which), or replace (the owner supplies the text); whether the
  diacritics are right; whether the source line and the credit sentence are right; whether the four Arabic strings are
  right. Then update `assets/khatm/dua.txt`, `dua_strings.dart` and the licenses section to exactly what was confirmed
  (remove «awaiting confirmation»), re-run `test/khatm`, and record the confirmation date in the commit message. If the
  owner has not answered, stop here and say the feature is not done (spec FR-016, SC-006, Constitution III, V, VI). *Done 2026-11-21 (answers in chat): the owner replaced the proposal with their own wording (11 paragraphs, ۞ at the end of ten), «سيبه كده» for the diacritics, the credit sentence without the names of the sites, the four strings approved. `assets/khatm/dua.txt` holds exactly their text; `dua_strings.dart`, `licenses.md`, spec FR-009/FR-010/Assumptions, research D6/D8, the contracts and data-model were updated; `dua_text_test.dart` pins the confirmed bytes (size and checksum) so a later change needs the owner again. Left open and told to the owner: where the added paragraphs come from (Constitution III asks for a named source), the spelling details of the pasted text (words joined to «ما» and «يا», a few marks missing, one double space), and how ۞ looks on the phone (T013).*

---

## Phase 7: Polish and cross-cutting

- [X] T012 Run `flutter analyze` (no issues) and the whole `flutter test` once; confirm the layout tests
  (`test/mushaf/page_layout_invariance_test.dart`, the page card tests) pass unchanged and `git diff --stat` for
  `lib/mushaf` shows only the additive reader edit of T007 (spec FR-018, SC-007; Constitution IX). *Done 2026-11-21: `flutter analyze` has no issues for the whole project. The whole suite on the final wording: 847 passed, 10 failed, all ten in feature 004's red-first night tests (`test/mushaf/reader_night_test.dart`, `test/settings/text_size_night_test.dart`) that its session is still implementing; none is a feature 005 test, and the 78 `test/khatm` tests, the About tests and the page layout tests pass. In `lib/mushaf` this feature changed only `reader_screen.dart` (T007, 2cf5510).*
- [ ] T013 Phone check of quickstart.md on the owner's phone <phone>: never unlock it, ask before sending any input;
  install a release build only with the owner's approval. Page 604 by index (must not open), swipe forward (slow drag,
  flick, brush), back, swipe again, «آمين» and restart, both looks, rotation with the dua open, a large font, the
  khatma count of a wird before and after. If the feel is wrong, tune the three constants of `LastPageSwipe` in one
  commit with a test update and record the values in research.md D2. Screenshots in `docs/design/` only if the owner
  wants them (spec SC-003, SC-008; Constitution IX). *Partly done 2026-11-21 (owner approved the install and driving the phone with adb): release build (178.6 MB) installed; in the Night look, page 604 reached through the go-to-page dialog opened nothing (SC-001); a 12 to 20 px brush and a 150 px (53 dp) slow drag opened nothing, while a 300 px drag and a 600 px flick opened the dua 23 times out of 23 in under a second; the dua showed the title, the label, the panel in Night colours and the text in Cairo; the sign ۞ draws as a small rosette from a system font, not an empty box; scrolling reached «آمين» as the last item; the system back and the on-screen arrow returned to page 604; «آمين» showed page 1; 7 seconds with no input left the dua open. The constants stay as they are (a swipe needs about 66 dp of finger travel: 18 dp touch slop plus 48 dp of overscroll, about 1 cm). Not done yet, for the owner or a later pass: Emerald look, rotation with the dua open, a large system font, a wird's khatma count and today's portion before and after, restart (the app restarts on the wird's page). Seen once and not reproduced in 7 repeats of the same sequence: after a system back and a flick the reader showed page 2 instead of the dua; the phone also dropped to its home screen twice while my script had not pressed Home, so the owner may have been touching it. My replay script once sent a back key and one flick to the home screen after the app had left; nothing opened or started.*
- [X] T014 Update `specs/005-khatm-dua/quickstart.md` with what was measured and run `/speckit-converge` (with the
  two environment variables); append whatever it finds as new tasks (spec all). *Done 2026-11-21: quickstart updated; converge found six partial gaps and appended them as Phase 8 (T015 to T020).*

---

## Dependencies and execution order

- Phase 1 first; T003 may run beside T001 and T002 (docs only).
- Phase 2 needs T001 and T002 (the asset and strings); T004 and T005 are different files and may run in either order.
- US1: T006 needs T002, T005; T007 needs T004 and T006. US2: T008 needs T007. US3: T009 needs only T006. US4: T010 needs
  T002; T011 needs T001, T002, T003 and T006 (the owner sees the screen), and blocks calling the feature done.
- Polish after everything; T011 may be answered earlier or later but before T012's «done» claim, and T013 comes after
  T011 because the phone check reads the confirmed wording (quickstart step 6).
- `reader_screen.dart` and `about_screen.dart` are each edited once (T007, T010), each after telling feature 004's session.

### Parallel example

T001 + T002 + T003 (Phase 1); T004 + T005 (Phase 2); after T006: T009 + T010 beside T007.

## Implementation strategy

- **MVP** = Phases 1 to 3: the swipe at page 604, the dua, «آمين» to page 1.
- Then US2 (back), US3 (looks and sizes), US4 (About and the owner's confirmation), then polish and the phone check.
- Every task: failing test first, minimal code, `flutter analyze` on the touched files, the related tests green, one commit.

## Coverage of the spec

| Spec | Tasks |
|---|---|
| FR-001, FR-002, FR-003, FR-004, FR-005 | T004, T007 |
| FR-006, FR-007, FR-008 | T007, T008 |
| FR-009, FR-010, FR-011, FR-012, FR-013 | T006, T009 |
| FR-014 | T007 (the route survives; restart opens on the saved position), T013 |
| FR-015, FR-016 | T001, T003, T005, T010, T011 |
| FR-017 | T001 to T007 (no network or storage is used; checked in review of the diff), T012 |
| FR-018 | T007, T012 |
| FR-019 | T005, T006 |
| SC-001 to SC-004 | T007, T008, T013 |
| SC-005 | T009 |
| SC-006 | T005, T011 |
| SC-007 | T007, T012 |
| SC-008 | T013 |

---

## Phase 8: Convergence

- [ ] T015 HIGH: name the source of paragraphs 3 to 11 of `assets/khatm/dua.txt`: ask the owner with `AskUserQuestion` (Egyptian Arabic) where they copied them from (a site, a book, their own collection); record the answer as the named source in `docs/research/licenses.md` (replace the «Open» sentence); if there is no source, record «supplied by the owner of the app, no other source» and have the owner confirm that this satisfies Constitution III; change nothing else per FR-016, Constitution III and V (partial)
- [ ] T016 HIGH: reproduce or rule out the one unexplained phone observation (after a system back, a quick flick left the reader on page 2 instead of opening the dua): a new `test/khatm/reader_khatm_back_race_test.dart` that sends the system back and then a flick (a) before the pop animation ends (pump 50 ms steps) and (b) straight after it, 20 times, and asserts the reader shows page 604 or the dua, never another page, with the wird position and last viewed page unchanged; if red, fix `_openDua` in `lib/mushaf/reader_screen.dart` (check `git status` and tell the 004 session first); then repeat the phone sequence ten times with the guard of `scratchpad` style (check the app has focus before every input) per FR-002, FR-007 (partial)
- [ ] T017 MEDIUM: ask the owner to confirm that «exactly one supplication» in Constitution III may be the 11-paragraph composition now bundled (it joins several traditional supplications and the verse 2:201 under one title), and if yes record it in the constitution's rationale through `/speckit-constitution` as a PATCH note with the owner's approval; if no, ask which paragraphs to keep and redo T011 per Constitution III (partial)
- [ ] T018 MEDIUM: test the restart after «آمين»: in `test/khatm/reader_khatm_restart_test.dart` re-pump the reader over the same in-memory database after «آمين» for (a) a reader following a wird (opens on page 1), (b) a reader without a wird (page 1), (c) browse mode with an active wird (opens on the wird's page, as on the phone); then decide with the owner whether (c) should move the wird to page 1 too (change `_openDua`) or whether SC-002 should say that a restart follows the wird, and record the decision per SC-002, FR-006 (partial)
- [ ] T019 MEDIUM: state the units of the swipe rule where it is written (spec FR-001 and SC-001, `contracts/ui.md` «The gesture», research D2): the 48 and 16 are logical pixels of overscroll after the 18 dp touch slop, so a drag needs about 66 dp (about 1 cm) of finger travel; on the phone a 53 dp slow drag opened nothing and 107 dp, 213 dp drags opened the dua 23 times out of 23; or change the constants in `lib/khatm/last_page_swipe.dart` with its test and record the new values per FR-001, SC-001 (partial)
- [ ] T020 LOW: extend `untouched` in `test/support/khatm_harness.dart` to the reminders (`reminderInputs`) and the settings (`textSizeRaw`, `appLookRaw`) so the «آمين» and back tests of `test/khatm/reader_khatm_test.dart` and `reader_khatm_back_test.dart` also prove SC-004 for them per FR-008, SC-004 (partial)

**Owner decision, 2026-11-21:** asked what is left (the rest of T013 and T015 to T020), the owner answered «اعتبر كله تمام» (take all of it as fine). Nothing was done for these items and none is marked done above. What this means, so nobody reads it as more:
- Not verified: the phone items of T013 (Emerald look, rotation, large system font, wird counts before and after, restart, the owner's own trial), the page-2 observation of T016, the restart behaviour of T018.
- Still open in the record: the source of paragraphs 3 to 11 (T015; `docs/research/licenses.md` keeps its «Open» sentence), and the reading of Constitution III for the 11-paragraph text (T017). The owner accepted them without naming a source; a change to the constitution, if wanted, goes through `/speckit-constitution`.
- Accepted as is: the units of the swipe rule are still unwritten in the spec (T019), the `untouched` helper still covers only the khatma count, today's portions and the bookmarks (T020).
- `checklists/khatm.md` was never reviewed.
