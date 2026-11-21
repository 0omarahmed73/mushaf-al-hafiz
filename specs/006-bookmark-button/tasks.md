# Tasks: Bookmark Button in the Reader

**Input**: `specs/006-bookmark-button/` (spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md,
checklists/bookmark.md)

**Rules**: test-first (a failing test is written and run red before the code that makes it pass); one commit per
task; `git add` explicit paths only and `dart format` on explicit files only (other sessions edit this tree: never
`git add -A`); **new tests go in NEW files** (`test/bookmarks/`): the tests of features 001 to 005 are never edited and
must keep passing (spec FR-015, SC-007). Check `git status` and `git log` before every task. `.specify/feature.json`
is NOT changed (speckit scripts run with `SPECIFY_FEATURE_DIRECTORY=specs/006-bookmark-button
SPECIFY_FEATURE_NO_PERSIST=1`). The Quran text, page data, fonts, page geometry and layout code are never touched.
Existing files edited, each additive and small: `lib/wirds/wird_repository.dart` (T005), `lib/mushaf/reader_controller.dart`
(T006), `lib/mushaf/reader_screen.dart` (T010, T012 and, if T013 finds something, T014, each after `git status` and
`git log -- lib/mushaf/reader_screen.dart`). Arabic UI strings are proposals until the owner confirms them (T015): the
feature is not done before that.
Commit trailer: `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.

Key: **FR/SC** are the spec's requirement and success-criterion ids; "data-model.md X" is the cited definition.

## Phase 1: Setup

- [X] T001 [P] Create `lib/mushaf/bookmark_strings.dart` with exactly the seven constants of
  contracts/dart-interfaces.md (`kBookmarkAdd`, `kBookmarkRemove`, `kBookmarkStateOn`, `kBookmarkStateOff`,
  `kBookmarkAdded`, `kBookmarkRemoved`, `kBookmarkUndo`), marked in a doc comment as proposals awaiting the owner
  (T018); first a small failing test `test/bookmarks/bookmark_strings_test.dart` that pins the seven strings for pages
  1 and 604, and name them as proposals awaiting T015 (spec FR-011, FR-007; Constitution VI)
- [X] T002 Record the geometry baseline on the **unchanged** code: `test/bookmarks/reader_bookmark_geometry_test.dart`
  pumps the reader through `test/support/reader_harness.dart` at 412 x 915 and 320 x 640 in both looks
  (`AppLook.emerald`, `AppLook.night`; use the harness's way of choosing the look), in wird mode and in browse mode
  (`pumpBrowseReader` of `test/support/khatm_harness.dart`), measures the rectangles of `top-bar`, the pager page,
  `page-number`, `wird-pill` and the «اليوم» chip, prints them, and the numbers become literals in the test with a
  tolerance of 0.01. Run it green on the unchanged code and commit the numbers **before any edit of `lib/`**; the
  test must still pass after T010 except for the rectangles the spec allows to move (the pill, the chip and
  «اجعلها موضعي» may lose width to the 48 px reserve: assert their **left/top** unchanged and their right edge
  at most 48 px smaller) (spec FR-003, SC-007; research D9)

---

## Phase 2: Foundational (blocks every story)

- [X] T003 Write the failing repository tests `test/bookmarks/bookmark_toggle_repository_test.dart` on an in-memory
  `AppDatabase` (one DB per test; pump 1 s before `db.close` where widgets are involved): `toggleBookmark` adds one
  bookmark with no note when the scope has none; removes all of the scope's rows when it has some; never reads or
  deletes a bookmark of another wird or a general one when `wirdId` is set, and never a wird's when `wirdId` is null;
  two rows of the scope on one page are both removed; `ArgumentError` for page 0 and 605
  (data-model.md `BookmarkToggle.addedId`, `BookmarkToggle.removed`: exactly one is set); `undoBookmarkToggle` after an
  add deletes that id; after a removal restores the rows with the same `id`, `createdAt` and `note`; a row whose wird
  was deleted meanwhile comes back with `wirdId` null; an undo run twice changes nothing the second time (spec FR-004,
  FR-006, FR-009, SC-001, SC-009; contracts/dart-interfaces.md)
- [X] T004 [P] Write the failing controller tests `test/bookmarks/bookmark_controller_test.dart` (a real
  `ReaderController` over an in-memory repository, no widgets): `pageBookmarked` is false before `init()` finishes
  and true for a page with a bookmark of the scope; follows `onPageShown`, `jumpTo`, `switchWird` and
  `makeThisMyPosition` (the scope changes); a bookmark of another wird or a general one does not make it true while
  following a wird, and a wird's bookmark does not make it true while browsing; follows an add, a delete and a restore
  done straight on the repository (the sheet's path); `toggleBookmark` returns null and writes nothing while the
  previous call is being written, and a later call toggles back; changing the state does not call the controller's
  `notifyListeners` (count the notifications) (data-model.md `Controller state.pageBookmarked`,
  `Controller state._toggleBusy`; spec FR-005, FR-009, SC-002)
- [X] T005 Implement `BookmarkToggle`, `WirdRepository.toggleBookmark` and `WirdRepository.undoBookmarkToggle` in
  `lib/wirds/wird_repository.dart` as contracts/dart-interfaces.md and research D3 say (one transaction each;
  `InsertMode.insertOrIgnore` for the restore; ids and times kept); make T003 green; `flutter analyze` on the file;
  `test/wirds` unchanged and green (spec FR-004, FR-006, SC-009, FR-014)
- [X] T006 Check `git status` / `git log -- lib/mushaf/reader_controller.dart`, then implement in
  `lib/mushaf/reader_controller.dart`: the single `watchBookmarks()` subscription in `init()` (cancelled in
  `dispose()`), the `ValueNotifier<bool>` behind `pageBookmarked` recomputed from the list and in `_notify()` by
  `scopeWirdId`, `toggleBookmark()` with the `_toggleBusy` guard and `undoBookmarkToggle()`
  (data-model.md `Scope`, `Controller state.pageBookmarked`, `Controller state._toggleBusy`); make T004 green; the
  existing controller tests unchanged and green (spec FR-005, FR-009, SC-002; research D2)

---

## Phase 3: User Story 1 and 2 (P1) — one tap adds, the icon shows the state

**Independent test**: open the reader on a page without a bookmark, tap the icon, the list gains one entry and the
icon is filled; turn the page, the icon follows.

- [X] T007 [P] [US1] Write the failing widget test `test/bookmarks/bookmark_button_test.dart` for
  `lib/mushaf/bookmark_button.dart` alone (a `ValueNotifier<bool>` and a callback): outlined icon when false, filled
  when true and it changes without rebuilding the parent; key `bookmark-button`; target at least 48 x 48; tooltip and
  semantics label «إضافة علامة للصفحة N» / «إزالة العلامة من الصفحة N», value «ليس عليها علامة» / «عليها علامة»,
  `isSemantics(isButton: true, hasTapAction: true, ...)` (dispose the `SemanticsHandle` in the test body); a tap calls
  the callback once (spec FR-005, FR-010, FR-011, SC-005; contracts/ui.md States)
- [X] T008 [US1] Implement `lib/mushaf/bookmark_button.dart` (`IconButton` with `isSelected`, `Icons.bookmark_border` /
  `Icons.bookmark`, `look.textSecondary` / `look.accent`, `ValueListenableBuilder` around the icon only, `Tooltip` and
  `Semantics` as research D5 says); make T007 green (spec FR-005, FR-010, FR-011, FR-012)
- [X] T009 [US1] Write the failing reader tests `test/bookmarks/reader_bookmark_button_test.dart` (reader harness, new
  file): the button is found once, its rectangle is at the far left end of the top bar (left edge within 12 px of the
  screen's left edge) and its top is below the bottom of `juz-hizb` (directly under the juz text) in wird mode and
  in browse mode, where `«اجعلها موضعي»` is also visible and the two rectangles do not intersect; a tap on a
  page with no bookmark adds exactly one bookmark with no note owned by the wird (wird mode) or general (browse mode,
  no wird), the icon is filled, and the khatma count, today's portions and done marks, bookmarks of other pages, the
  wird's position, `lastViewedPage`, reminders (`reminderInputs`) and the settings (`textSizeRaw`, `appLookRaw`) are
  unchanged and the page did not turn; swiping to another page and back updates the icon; adding and deleting
  through the «علامات» sheet updates the icon; a bookmark of another wird on the page leaves it outlined; the bottom
  bar and the khatm dua swipe on page 604 still work (spec FR-001, FR-002, FR-004, FR-005, FR-008, FR-015, SC-001,
  SC-002, SC-006; contracts/ui.md Place)
- [X] T010 [US1] Re-run T002's geometry test and T009 red/green status, then check `git status` and
  `git log -- lib/mushaf/reader_screen.dart` and edit `lib/mushaf/reader_screen.dart` once (small, additive, one
  commit): wrap `_TopBar`'s content in a `Stack`, add the `PositionedDirectional(end: 10, bottom: 0)`
  `BookmarkButton` fed by `_controller.pageBookmarked` and `_controller.toggleBookmark`, put `Padding(end: 48)`
  around the second row (research D1); the khatm lines (`_onPagerScroll`, `_openDua`, `_lastSwipe`) and everything
  else stay as they are; make T009 and T002 green and the earlier mushaf, wirds, ayah, khatm and settings tests
  pass unchanged (spec FR-001, FR-002, FR-003, FR-004, SC-007)

---

## Phase 4: User Story 3 (P2) — a tap on a filled icon removes, with «تراجع»

**Independent test**: on a bookmarked page tap the icon: the bookmark is gone, the message appears; «تراجع» brings it
back exactly.

- [X] T011 [US3] Write the failing reader tests `test/bookmarks/reader_bookmark_undo_test.dart` (reader harness, new
  file): the first tap shows a SnackBar with «تمت إضافة علامة للصفحة N» and the action «تراجع»; a tap on a filled icon
  removes the scope's bookmarks, empties the icon and shows «تمت إزالة العلامة من الصفحة N» with «تراجع»; «تراجع»
  after an add removes it, after a removal restores it with its note, id and time, in the list's order; a bookmark of
  another wird on the same page survives a removal; two bookmarks of the scope on one page both go and both come
  back; a new tap replaces the message; «تراجع» does nothing once the message is gone; the message sits above the
  bottom bar (its bottom edge at most the top of the bar) and with the bars hidden at 8 px from the bottom; two quick
  taps leave at most one bookmark on the page (spec FR-006, FR-007, FR-009, SC-009; contracts/ui.md The tap, The
  message)
- [X] T012 [US3] Implement in `lib/mushaf/reader_screen.dart` the `_toggleBookmark()` handler of research D4 (the same
  small commit rules: `git status`, `git log`, explicit paths): `hideCurrentSnackBar`, floating `SnackBar` with the
  margin from the bottom bar, `SnackBarAction(label: kBookmarkUndo)` capturing that tap's `BookmarkToggle`; if the
  write throws, no message and the icon stays as it was; make T011 green (spec FR-006, FR-007)

---

## Phase 5: User Story 4 (P2) — fits both looks and every size

**Independent test**: the reader in both looks at 80, 100, 150 percent, 320 dp with a 2x system font, wird and browse
mode: no overflow, everything reachable, contrast and targets right.

- [X] T013 [US4] Write the failing tests `test/bookmarks/reader_bookmark_look_test.dart`: for each look (Emerald &
  Gold, Night Reader), each reading size (80, 100, 150) and the screens 412 x 915 and 320 x 640 with
  `TextScaler.linear(2.0)` (12 combinations of SC-003 times the two modes, counted in the test) there is no exception
  (`tester.takeException()`), the button, `«اجعلها موضعي»` (browse mode), the pill and the chip are all inside the screen;
  the button is at least 48 x 48; `contrastIssues(t)` of `test/support/contrast_walk.dart` is empty with the icon filled
  and with it outlined; the tooltip appears on a long press; switching the look while the reader is shown recolours
  the icon (spec FR-010, FR-012, FR-013, SC-003, SC-004, SC-005; contracts/ui.md States)
- [X] T014 [US4] Fix whatever T013 finds, only in `lib/mushaf/bookmark_button.dart` and the one place in
  `lib/mushaf/reader_screen.dart` T010 edited (if the filled colour fails 4.5:1, use `look.heading` and record it in
  research D6); make T013 green and T002 still green (spec FR-012, FR-013)

---

## Phase 6: Owner confirmation

- [X] T015 Show the owner, in Egyptian Arabic with `AskUserQuestion`, the exact seven strings of
  `lib/mushaf/bookmark_strings.dart` (the tooltip pair, the two states, the two messages, «تراجع») and ask to keep or
  change each; apply the answer to `bookmark_strings.dart`, its test, the spec Assumptions, contracts/ and the
  quickstart; the feature is not done until answered (spec FR-011, Constitution VI; research D8)
  **Owner confirmed all seven strings on 2026-11-21 (answered «موافق على كلها»), unchanged.**

---

## Phase 7: Polish and convergence

- [ ] T016 `flutter analyze` clean on the whole project; run `flutter test` (whole suite; the failures that belong to
  another feature's unfinished work are named, not hidden); the earlier layout, mushaf, wirds, ayah, khatm, settings
  and backup tests unchanged and green (spec FR-015, SC-007)
- [ ] T017 Phone check of quickstart.md on <phone>: **ask the owner first** for any install or input; build the
  release APK with `flutter build apk --release`, install only with the owner's approval, then do steps 1 to 7 of
  quickstart.md with read-only `adb` checks and screenshots, and let the owner do the last step; record the numbers
  and what the owner saw in research D10 (spec SC-008; Constitution IX)
- [ ] T018 Update `quickstart.md` with what T017 changed; run `/speckit-converge` for feature 006 (with
  `SPECIFY_FEATURE_DIRECTORY=specs/006-bookmark-button SPECIFY_FEATURE_NO_PERSIST=1`), append what it finds as new
  tasks, repeat until it converges
- [ ] T019 Confirm in the commit log that `lib/mushaf/reader_screen.dart` was edited in at most two commits for this
  feature (T010, T012), that no file of another feature's tests changed, and record the commit ids at the end of this
  file

---

- [ ] T020 MEDIUM, found by T002 (not caused by this feature): at 320 dp wide the **bottom bar** (`_BottomBar` in
  `lib/mushaf/reader_screen.dart`, from feature 001) already overflows by 45 px in Emerald & Gold and 77 px in Night
  Reader (its five items need 365 px; Night's pill leaves 288), so a phone that narrow clips its items; every
  320 dp test of this feature therefore ignores errors whose widget chain contains `_BottomBar` and fails on any
  other. Decide with the owner whether to fix it here or as its own change (a fix must keep the 412 dp bar exactly
  as it is and keep the 48 px targets) (Constitution Development Workflow, spec SC-003 for the top bar only).
  Found again by T013: with a 2x system font at 320 dp the bottom bar's items (`_BarItem` Column, 21 px) and the page's
  own text lines (`mushaf_page.dart`, about 230 px) overflow too; the 2x test of this feature therefore checks only the
  errors raised inside `_TopBar` (`BookmarkReader.topBarErrors`), and that is what the top bar and the icon are held to
  **Owner decision 2026-11-21: fix the bottom bar at 320 dp as its own later feature (not in 006); T020 stays open as a pointer to it.**

---

## Dependencies and order

```text
T001 [P]  T002 (baseline, done before any lib edit)
   └────────────┐
T003 → T005     T004 → T006        (T004 may be written while T003 runs; T006 needs T005)
        └──── T005 + T006 ────┐
T007 [P] → T008               │
                T009 ──→ T010 ┘  (T010 needs T006, T008, T009; T002 stays green)
                    T011 → T012  (needs T010)
                    T013 → T014  (needs T010; T012 may run before or after)
                          T015   (needs T001; blocks "done")
                          T016 → T017 → T018 → T019
```

## Coverage of the spec

| Spec | Tasks |
|---|---|
| FR-001, FR-002, FR-003 | T002, T009, T010 |
| FR-004, FR-005 | T003, T004, T005, T006, T009 |
| FR-006, FR-007 | T003, T011, T012 |
| FR-008, FR-009 | T004, T006, T009, T011 |
| FR-010, FR-011, FR-012, FR-013 | T001, T007, T008, T013, T014, T015 |
| FR-014 | T005 (no schema change), T016 |
| FR-015 | T009, T010, T016 |
| SC-001, SC-002, SC-006 | T003, T004, T009 |
| SC-003, SC-004, SC-005 | T007, T013, T014 |
| SC-007 | T002, T010, T016 |
| SC-008 | T017 |
| SC-009 | T003, T011 |
