# Tasks: First-Run Tips

**Input**: `specs/008-first-run-tips/` (spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md,
checklists/tips.md)

**Rules**: test-first (a failing test is written and run red before the code that makes it pass; the two truth and
reopen tasks say where a test is expected to pass at once and why); one commit per task; `git add` explicit paths only and
`dart format` on explicit files only (other sessions edit this tree: never `git add -A`, `git stash`, `git reset`,
`git checkout`, `git restore`, `git clean`); **new tests go in NEW files** (`test/onboarding/`, `test/support/tips_harness.dart`):
no existing test is edited. `.specify/feature.json` is NOT changed (speckit scripts run with
`SPECIFY_FEATURE_DIRECTORY=specs/008-first-run-tips SPECIFY_FEATURE_NO_PERSIST=1`); no git branch. Files this feature may
edit: `specs/008-first-run-tips/**`, `lib/onboarding/**`, `test/onboarding/**`, `test/support/tips_harness.dart`, and
`lib/backup/backup_service.dart` only in T009 (after `git status` and `git log -- lib/backup/backup_service.dart`).
`lib/main.dart`, `lib/app.dart`, `lib/mushaf/**`, `lib/settings/**`, `lib/reminders/**`, `lib/wirds/**` are read only; the
wiring is the coordinator's (quickstart section 3). Never start a second copy of a running test command; never run the
whole suite; run `timeout 600 flutter test test/onboarding --reporter expanded > <scratchpad>/tips_tests.txt 2>&1` (or one
file) and read the file. The known harmless issue (the reader's bottom bar overflows at 320 dp) is not this feature's: the
reader is pumped at 412 x 915 only. All Arabic is a proposal until T020. Commit trailer:
`Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.

Key: **FR/SC** are the spec's requirement and success-criterion ids; "data-model.md X" is the cited definition
(`data-model.md` `The flag: tipsSeen`, `TipStep.title`, `TipStep.body`, `Dialog state.index`).

## Phase 1: Setup

- [X] T001 [P] Write the failing `test/onboarding/tips_strings_test.dart` that pins every constant of
  contracts/dart-interfaces.md `tips_strings.dart` to the exact text of contracts/ui.md (`kTipsDialogLabel`, `kTipsNext`,
  `kTipsSkip`, `kTipsStart`, `kTipsStepOf(2, 6)`, the six titles, the six bodies; a change must fail the test, so it needs the
  owner again), then create `lib/onboarding/tips_strings.dart` with a doc comment saying they are proposals awaiting T020 and
  why (Constitution VI); make it green (spec FR-014; contracts/ui.md)
- [X] T002 Write the failing `test/onboarding/tip_steps_test.dart`: `kTipSteps` has exactly 6 steps in the order of the
  spec, all `TipPicture` values different and all used, titles and bodies equal to the strings, every `TipStep.title` not
  empty and without digits, every `TipStep.body` has at most two full stops and no character of the Quran's own marks
  (U+06D6 to U+06ED) or Quran-ornament brackets (`﴿ ﴾`), no title or body is repeated; then create
  `lib/onboarding/tip_steps.dart` (pure Dart, no widget import) and make it green (spec FR-003, SC-003; data-model.md
  `TipStep.picture`, `TipStep.title`, `TipStep.body`; Constitution I)

---

## Phase 2: Foundational (blocks every story)

- [X] T003 Write the failing `test/onboarding/tips_store_test.dart` on an in-memory `AppDatabase` (one per test, closed in
  `tearDown`): `TipsStore.isSeen` is true only for exactly `'true'` (null, `''`, `'false'`, `'True'`, `'1'` all false);
  `seen()` is false on an empty database; `markSeen()` makes `seen()` true and the raw setting `tipsSeen` is `'true'`;
  calling it twice changes nothing; it writes no other setting; `kTipsSeenKey` is the literal `'tipsSeen'`;
  `TipsStore.maybeOf` returns null without a `Provider<WirdRepository>` and a store with one (a bare widget test);
  then create `lib/onboarding/tips_store.dart` and make it green (spec FR-006, FR-007; data-model.md
  `The flag: tipsSeen`; research D2, D3)

---

## Phase 3: User Story 1 (P1) — see the tips once, leave whenever I want

**Independent test**: an empty database shows the popup after the first frame; «التالي» five times and «ابدأ» close it; a
second launch on the same data shows nothing; skip and back do the same.

- [X] T004 [P] [US1] Write the failing `test/onboarding/tip_picture_test.dart` for `TipPictureView` alone (a bare
  `MaterialApp` with `buildAppTheme`): each of the six `TipPicture` values builds without error at 240 x 112 and at 100 x 60
  (it scales down, no overflow); contains no `Text`, no `RichText` and no `Image`; is excluded from the semantics;
  `active: true` on `longPress` runs a ticker (`binding.transientCallbackCount > 0`) and the other five never do; a
  picture with `active: false` runs none; then create `lib/onboarding/tip_picture.dart` (shapes and icons on the design
  box, the one ring pulse of research D10) and make it green (spec FR-003, FR-013; research D10; contracts/dart-interfaces.md
  `TipPictureView`)
- [X] T005 [US1] Create `test/support/tips_harness.dart` (a new file: `pumpTips` that pumps the app's `MushafApp` with
  `home` = a launcher button that calls `showDialog` for `TipsDialog`, in a given `AppLook`, `Size`, `textScale` and
  `disableAnimations`; `settleTips`; helpers `key`, `nextButton`, `skipButton`, `startButton`, `currentStep`) and write the failing
  `test/onboarding/tips_dialog_test.dart` (the first group): step 1 of 6 is shown with its title and the first dot current;
  «التالي» goes to 2 and the dots follow; a drag from left to right moves forward and a drag from right to left moves back
  (the paper direction), on 5 of 5 steps; a swipe beyond step 1 and beyond step 6 does nothing; on step 6 the buttons are only
  «ابدأ» (no «تخطي», no «التالي») and it sits at the left end; two quick taps on «التالي» move one step; «التالي» and
  «ابدأ» pop the route with `TipsOutcome.finished` only from «ابدأ»; «تخطي» and the system back pop with
  `TipsOutcome.skipped`; a touch on the dimmed area outside does nothing; the dialog is laid out right-to-left even in an app
  without the Arabic locale (spec FR-004, FR-005, FR-002, SC-002; contracts/ui.md The card; research D7)
- [X] T006 [US1] Implement `lib/onboarding/tips_dialog.dart` (`TipsOutcome`, `TipsDialog`: `Dialog` on `look.barFill`,
  `PageView` with a scrolling page per step, the dots, the `Wrap` of buttons, `PopScope(canPop: false)` for back, the
  `animating` guard, forced `Directionality(rtl)`, `min(available, 520)` height, keys of contracts/dart-interfaces.md); make
  T005 green; the tests of T004 stay green (spec FR-004, FR-005, FR-011; research D7, D8, D9; data-model.md
  `Dialog state.index`, `Dialog state.animating`)
- [X] T007 [US1] Write the failing `test/onboarding/tips_gate_test.dart` (the harness pumps `MushafApp(home: TipsGate(child:
  a placeholder reader))` over an in-memory database with the real repository): on an empty database the popup opens after
  the first frame, not before; with `tipsSeen = 'true'` it never opens; finish (five «التالي» and «ابدأ»), skip on step 1 and
  back on step 3 each store the flag and the popup is gone; a **rebuilt app** on the same repository (unmount, pump a new
  `MushafApp`) shows nothing; a **real restart** (a temporary file database written and closed, then opened again as a new
  `AppDatabase` and a new repository) shows nothing, while a database that was never finished shows the popup again;
  closing the route without a result (`Navigator.pop` with no value from the test, `popUntil`) stores nothing and the
  popup opens again on the next start; an outside touch stores nothing; `enabled: false` shows nothing and turning it on
  opens it once; a repository that throws on read shows no popup and no error; a repository that throws on write still
  closes the popup; a value other than `'true'` shows the popup; no drift stream is used (the test writes the database
  with `runAsync` while the gate is mounted and does not hang) (spec FR-001, FR-002, FR-006, FR-007, SC-001; data-model.md
  `The flag: tipsSeen`; research D2, D3, D4, D12, D14)
- [X] T008 [US1] Implement `lib/onboarding/tips_gate.dart`: `TipsGate` (a post-frame callback that reads once,
  `enabled`, `didUpdateWidget`, mounted checks, errors swallowed with `debugPrint`), `showTips` (shows the dialog with
  `barrierDismissible: false`, writes the flag when the result is not null, swallows a write error); make T007 green
  (spec FR-001, FR-006, FR-007; research D1, D2, D4, D12)
- [X] T009 [US1] Write the failing `test/onboarding/tips_backup_test.dart` (in-memory databases): `exportJson` of a phone
  with the flag has `settings.tipsSeen == 'true'`; importing that file into an empty phone gives `seen() == true`; an old
  file without `tipsSeen` imports without error; importing an old file on a phone that has seen the tips keeps `seen()
  == true`, importing it on a phone that has not leaves it false; the file's `'true'` wins over a phone that has not
  seen; an import that fails halfway (the `debugHook` throws at `'bookmarks'`) leaves the phone's flag, wirds and
  bookmarks exactly as before; the other settings are still replaced (a setting not in the file is gone, as before);
  `kKeptOnImport` equals `{kTipsSeenKey}`. Run it red, then check `git status` and
  `git log -- lib/backup/backup_service.dart` and add the additive edit of research D5 (`kKeptOnImport`, read before the
  delete, written back after the inserts when the file has no value, all in the existing transaction); make it green and run
  `flutter test test/backup` once (the existing backup tests unchanged and green) (spec FR-008, SC-005; data-model.md
  `The flag: tipsSeen` in the backup; research D5)

---

## Phase 4: User Story 2 (P1) — every tip is true

**Independent test**: for each step, do what it says on the real reader and see the thing it names.

- [X] T010 [US2] Write `test/onboarding/tips_reader_truth_test.dart` (a new harness function in
  `test/support/tips_harness.dart` pumps `MushafApp(home: TipsGate(child: ReaderScreen()))` over a real page, the real
  `AyahRepository(rootBundle)`, a `FakeShareService`, 412 x 915, with the flag already `'true'` so the popup does not cover
  the reader, the way `pumpSizedReader` does): 1 a long press on a word of 2:255 opens the ayah menu whose rows are the keys
  `ayah-share`, `ayah-tafsir`, `ayah-translation`, `ayah-meanings`, `ayah-page-picture`, `ayah-surah-pdf` (the
  last two need the renderer and the PDF job: pump them with the same fakes the ayah tests use) and the menu's tafsir view
  is titled «تفسير السعدي»; 2 a tap on `open-index` opens the index with the tabs «السور» «الأجزاء» «صفحة», a tap on
  `page-number` opens «الانتقال إلى صفحة», a drag from left to right shows the next page; 3 a tap on the page hides `top-bar` and `bottom-bar`, a second shows
  them, and `page-pan` or the viewer scales up to 3x by a two-finger pinch (the same technique as `page_viewport_test`);
  4 `wird-pill` shows «الورد اليومي» and opens the wirds list with «ورد جديد», `today-chip` opens the card with a «تم»
  button; 5 `bookmark-button` is in the top bar and a tap makes the page appear in the «علامات» sheet from the bottom
  bar; 6 `open-settings` has the tooltip «القائمة» and opens Settings holding «حجم الخط» and «المظهر» with «زمردي وذهبي» and
  «القارئ الليلي»; every name the strings of contracts/ui.md use («علامات», «أوراد», «ملخص اليوم», «تم») is found on the
  real reader; one more case starts with the flag **absent**: the popup opens over the reader that is still loading its page,
  «تخطي» closes it, and the reader then shows its page and obeys a tap on the page (bars hide) (spec Edge Cases); this task has nothing to implement: **it is expected to pass on the first run** (it documents the reader as it
  is); to see it red, mutate one name in a scratch copy of the strings and watch the pin fail, not the reader (spec FR-003,
  SC-003; research D6, D13; Constitution VI)
- [X] T011 [US2] If T010 found a sentence that is not true (a name that differs, a control that moved), fix the sentence in
  `lib/onboarding/tips_strings.dart` and its pin in `tips_strings_test.dart` and contracts/ui.md in one commit; otherwise add
  to research.md D6 the date and the commit id of T010 as the last verification (spec FR-003; research D6)

---

## Phase 5: User Story 3 (P2) — open the tips again later

**Independent test**: with the tips already seen, `showTips` opens the popup at step 1; finishing leaves it seen.

- [X] T012 [US3] Write the failing `test/onboarding/tips_show_again_test.dart` (harness: a screen with a button that
  calls `showTips(context)`): with the flag `'true'` a tap opens the popup at step 1 and the future completes only when it
  closes; finishing keeps `tipsSeen` `'true'`; with the flag absent, skipping stores it; a second `showTips` while one is
  open does nothing (one `TipsDialog` in the tree, and after it closes a third call opens another); an app without a
  `Provider<WirdRepository>` still shows the tips and closes them with nothing stored and no error; `showTips` never throws
  when the repository does; a `TipsGate` re-created while a popup is open (the app rebuilt) does not open a second one (spec
  FR-009; research D11; contracts/dart-interfaces.md `showTips`)
- [X] T013 [US3] Make T012 green in `lib/onboarding/tips_gate.dart` (the per-navigator `Expando<bool>` mark set before the push
  and cleared in a `finally`, `TipsStore.maybeOf` for the missing provider); T007 stays green (spec FR-009; research D11)

---

## Phase 6: User Story 4 (P2) — both looks, every size, for everyone

**Independent test**: both looks at 412 x 915 and at 320 x 640 with a 2x font, on every step: no overflow, contrast, targets,
semantics, reduced motion.

- [X] T014 [US4] Write the failing `test/onboarding/tips_look_size_test.dart`: for each look (`AppLook.emerald`,
  `AppLook.night`, through `buildAppTheme(look:)`), each screen (412 x 915 at scale 1.0, 320 x 640 at `TextScaler.linear(2.0)`),
  each of the 6 steps (reached with «التالي»; 24 combinations counted in the test): `tester.takeException()` is null; the
  card is inside the screen; `contrastIssues(t, within: find.byType(TipsDialog))` is empty (text 4.5, icons 3.0); «تخطي» and
  «التالي» / «ابدأ» are at least 48 px high and 48 px wide and inside the card; the dots are visible and the buttons are
  visible without scrolling; at 320 x 640 with the 2x font the page's scroll view has `maxScrollExtent > 0` on the long
  steps and scrolling it never moves the dots or the buttons; the card's height is at most 520 and at most the screen minus
  its inset; the card is drawn in the look's tokens (the look cannot change while it is open); each title is one line at 412 x 915 with scale 1.0 (data-model.md
  `TipStep.title`); a landscape screen (640 x 360, scale 1.0 and 2.0) has no overflow and keeps the buttons in view; turning the
  screen from portrait to landscape while step 3 is shown keeps step 3 (spec FR-010, FR-011, SC-004, Edge Cases; research D8, D9)
- [X] T015 [US4] Fix whatever T014 finds, only in `lib/onboarding/tips_dialog.dart` and `tip_picture.dart` (if a colour fails,
  change the token used and record it in research D9); make T014 green and the earlier tests stay green (spec FR-010,
  FR-011)
- [X] T016 [US4] Add to `test/onboarding/tips_dialog_test.dart` a second, failing group on semantics (a `SemanticsHandle`
  disposed in the test body): the dialog has the label «نصائح لاستخدام التطبيق»; each step announces «الخطوة N من 6» as one
  live-region node and the dots add no other node; each title is a header; the pictures add no node; «تخطي», «التالي» and
  «ابدأ» are buttons with those names; after «التالي» the announcement changes (spec FR-012; contracts/ui.md Semantics)
- [X] T017 [US4] Make T016 green in `lib/onboarding/tips_dialog.dart` (`Dialog.semanticLabel`, `Semantics(header: true)`,
  the live step label with `excludeSemantics`, `ExcludeSemantics` around each picture and the dots) (spec FR-012)
- [X] T018 [US4] Write the failing `test/onboarding/tips_motion_test.dart`: with `MediaQuery.disableAnimations` true: on step 1
  no ticker runs (`transientCallbackCount == 0` after the dialog has opened and settled), «التالي» shows step 2 in one pump
  with no slide (the second page is fully there after a single `pump()`), the dots change size at once; with it false: the
  ring runs on step 1 only and stops on step 2, and «التالي» slides (the second page is not fully there after one pump and is
  after the duration); two taps during the slide never skip a step (spec FR-013, SC-006; research D7, D10)
- [X] T019 [US4] Make T018 green in `lib/onboarding/tip_picture.dart` and `tips_dialog.dart` (`MediaQuery.disableAnimationsOf`,
  `jumpToPage` versus `animateToPage`, `AnimatedContainer` duration zero, the pulse controller started and stopped from
  `active` and the media setting) (spec FR-013; data-model.md `Dialog state.reduceMotion`)

---

## Phase 7: Owner confirmation and the phone (open: need the owner)

- [ ] T020 Show the owner, in Egyptian Arabic, every string of `lib/onboarding/tips_strings.dart` (the four UI strings, the
  step counter, the six titles and the six bodies, listed in the report and in contracts/ui.md) and ask to keep or change
  each, and the four open questions of the report (an update sees the tips once?; is a Settings row wanted?; is the
  khatm dua left out?; is step 5 right about the bookmark icon?); apply the answer to `tips_strings.dart`, its pin test,
  the spec Assumptions, contracts/ui.md and quickstart; the feature is not done until answered (spec FR-014, Constitution VI)
- [ ] T021 Phone check of quickstart section 2: **ask the owner first** for any install or input; the gate must be wired by
  the coordinator (section 3) and the splash (009) present; do steps 1 to 8 with the owner, record what the owner saw (the
  slide feel, the first launch after the splash, the second launch without tips) in research.md as D15; the last step
  (confirming every sentence) is T020 (spec SC-007; Constitution IX)

---

## Phase 8: Polish and convergence

- [X] T022 `flutter analyze` on `lib/onboarding`, `lib/backup/backup_service.dart`, `test/onboarding`,
  `test/support/tips_harness.dart` is clean; `dart format` on those files only; `flutter test test/onboarding` and
  `flutter test test/backup` pass; record the counts at the end of this file (spec SC-001 to SC-006; Constitution IX)
- [X] T023 Run `/speckit-analyze` and `/speckit-converge` for this feature (with
  `SPECIFY_FEATURE_DIRECTORY=specs/008-first-run-tips SPECIFY_FEATURE_NO_PERSIST=1`), append what they find as new tasks,
  repeat until they converge; update quickstart.md and the checklist notes with what changed
- [X] T024 Confirm in `git log` that only the files of the rules above were touched by this feature's commits (no
  `lib/main.dart`, `lib/app.dart`, `lib/mushaf/**`, `lib/settings/**`, `lib/wirds/**`, no existing test, `.specify/feature.json`
  unchanged), record the commit ids at the end of this file, and hand the wiring lines of quickstart section 3 to the
  coordinator

---

## Dependencies and order

```text
T001 → T002                                  (steps use the strings)
T003                                         (independent of T001 and T002: the store needs only the repository)
T004 [P]  T005 → T006                        (the dialog needs the pictures T004 and the steps T002)
T003 + T006 → T007 → T008                    (the gate needs the store and the dialog)
T003 → T009                                  (backup test uses the store's key; edit of backup_service after git status)
T008 → T010 → T011                           (the truth test pumps the gate over the reader)
T008 → T012 → T013
T006 → T014 → T015 → T016 → T017 → T018 → T019
all → T022 → T023 → T024;  T020, T021 need the owner and block "done"
```

## Coverage of the spec

| Spec | Tasks |
|---|---|
| FR-001, FR-002, FR-006, FR-007, SC-001 | T003, T007, T008 |
| FR-003, SC-003 | T001, T002, T004, T010, T011 |
| FR-004, FR-005, SC-002 | T005, T006 |
| FR-008, SC-005 | T009 |
| FR-009 | T012, T013 |
| FR-010, FR-011, SC-004 | T014, T015 |
| FR-012 | T016, T017 |
| FR-013, SC-006 | T004, T018, T019 |
| FR-014 | T001, T020 |
| FR-015, FR-016 | T024 and the rules above |
| SC-007 | T021 |

---

## Results (T022, 2026-11-21)

- `flutter test test/onboarding`: 205 tests, all pass (strings 8, steps 16, store 9, pictures 26, dialog 22, gate 22, show again 6,
  backup 13, reader truth 16, look and size 82, motion 10 - the dialog file counts its semantics group).
- `flutter test test/backup` (after the one additive edit of `lib/backup/backup_service.dart`): 28 tests, all pass, unchanged.
- `flutter analyze lib/onboarding lib/backup/backup_service.dart test/onboarding test/support/tips_harness.dart`: no issues;
  `dart format --set-exit-if-changed` on the same files: nothing to change.

---

## Phase 9: Convergence

- [X] T025 LOW: make two lines of the design documents say what the code does: `contracts/ui.md` "The card" says "inset 16 px" while the card keeps 16 px at the sides and 24 px above and below (`insetPadding` in `lib/onboarding/tips_dialog.dart`, the tests use the 48 px), and `research.md` D9 says the sentence is `look.textSecondary` while the body text is `look.text` (the dots are `look.accent` and `look.textSecondary`); no code change per plan: research D9, contracts/ui.md The card (partial)

---

## Commits (T024, 2026-11-21)

Docs: cd740a1 spec, 3741007 plan and design documents, f39852e checklist, 86be25b tasks, a600e16 analyze fixes.
Code and tests: 190ad39 T001, 502d33b T002, 8fa4697 T003, 587a06a T004, 6d4b15c T005+T006, df7a3b7 T007+T008, 3252a40 T009
(the one edit outside the feature's folders: `lib/backup/backup_service.dart`), a7ea839 T010, 5a8c6d1 + 13a2699 T011,
85057d2 T012+T013, 8c586e9 T014+T015, bce8289 T016+T017, b9f334e T018+T019, 9b6d262 T022, 9764063 T023+T025.
Files touched by these commits: `specs/008-first-run-tips/**`, `lib/onboarding/**`, `test/onboarding/**`,
`test/support/tips_harness.dart`, `lib/backup/backup_service.dart`. Not touched: `lib/main.dart`, `lib/app.dart`,
`lib/mushaf/**`, `lib/settings/**`, `lib/wirds/**`, `lib/reminders/**`, any existing test, `.specify/feature.json`.
Open: T020 and T021 (the owner). The wiring lines are in contracts/ui.md "Wiring" and the report.
