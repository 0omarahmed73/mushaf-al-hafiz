# Tasks: Smooth Motion

**Input**: `specs/010-smooth-motion/` (spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md,
checklists/motion.md, phone/)

**Rules**: test-first (a failing test is written and run red before the code that makes it pass; one commit per task holds
the test and its code, so the suite is never red on `main`); `git add` explicit paths only and `dart format` on explicit files
only (other sessions edit this tree: never `git add -A`); **new tests go in NEW files** (`test/motion/`, helpers in
`test/support/motion_*.dart`): the tests of features 001 to 009 are never edited and must keep passing (spec FR-016, SC-006).
Run the owner's existing reader tests after every task that touches the reader: `flutter test test/mushaf test/bookmarks
test/khatm test/wirds test/look`. Check `git status` and `git log -- <file>` before every task. `.specify/feature.json` is NOT
changed (speckit scripts run with `SPECIFY_FEATURE_DIRECTORY=specs/010-smooth-motion SPECIFY_FEATURE_NO_PERSIST=1`). The Quran
text, page data, fonts, the page card and `mushaf_page.dart` are never touched in Stages A and B. Known harmless issue: at 320 dp
the reader's bottom bar overflows (feature 006 T020); ignore errors whose widget chain contains `_BottomBar`. Lesson: widget
tests that write the database with `tester.runAsync` while a drift `watch*` stream is listened in the fake-async zone can hang;
write through the app or before the pump (see `test/support/motion_harness.dart`, which also gives a database that answers
after a delay). Commit trailer: `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.

**Owner's answers of 2026-11-21 (recorded in spec.md Clarifications)**: the lag is felt at the start of the swipe; the look switch
and jumps fade softly (T035, T032); the 320 dp bottom bar is not this feature's; **no phone measurement is approved yet** (T003, T016,
T050, T073 wait); delayed position saving (T060, T061) stays off the table until a phone measurement asks for it, so Stage A keeps
writing the position through `onPageShown` and **T007 is not needed now** (it only serves T060). **Deferred to the coordinator
because other sessions edit `lib/main.dart` and `lib/app.dart`: the one line of T002 in `lib/main.dart` and all of T035 (the look
cross-fade host in `lib/app.dart`).** `lib/motion/frame_trace.dart` and its test are done without the `main.dart` line.

**Phone tasks** are marked **[PHONE]**: only with the owner in that session; never unlock the phone, ask before input and
before installing, change no phone setting (research D9). The script refuses to run without `--approved-by-owner`.

**`reader_screen.dart` windows** (the file is also edited by features 005, 006, 007 and the 008/009 sessions; do each window in
one sitting, in order, each task its own commit, `git status` clean for the file before the first edit of a window):
**[R1]** Stage A, T010-T013 (stop rebuilds, neighbours ready); **[R2]** the motion, T021, T022, T032, T034, T040;
**[R3]** only if Stage C is built, T060. Every other task adds new files or touches a file nobody else is editing and can be
done at any time.

Key: **FR/SC** are the spec's ids; "research D#/H#" the decisions and hypotheses; "data-model.md X" the cited definition.

## Phase 1: Setup

- [X] T001 Measurements before any fix, print-only with generous bounds: `test/motion/page_data_cost_test.dart`,
  `page_font_cost_test.dart`, `page_build_cost_test.dart`, `reader_rebuild_count_test.dart`,
  `reduce_motion_probe_test.dart`, helpers `test/support/motion_probe.dart` and `motion_harness.dart` (commit `7db3f64`), and
  the spike `test/motion/pager_prewarm_spike_test.dart` (commit `2d7eacf`); numbers in research.md D1 and D8
- [X] T002 [P] Test-first: `test/motion/frame_trace_test.dart` (red): `FrameTrace.formatFrame(FrameTiming)` prints
  `build=<ms> raster=<ms> total=<ms>` with two decimals from a hand-made `FrameTiming`, `FrameTrace.warmLine(next: true,
  prev: false)` is `PAGEWARM next=true prev=false`, `FrameTrace.enabled` is false in tests, `install()` registers nothing when
  disabled; then `lib/motion/frame_trace.dart` and one line `FrameTrace.install();` before `runApp` in `lib/main.dart` (check
  `git status` for that file: feature 009 may be editing it; the line is additive). The `FRAMETRACE refresh=<hz>` line is printed
  once from the first view's display refresh rate. Free in normal builds: a `const bool.fromEnvironment('FRAME_TRACE')` guards
  everything (data-model.md "Frame trace line"; spec FR-018; research D9)
- [ ] T003 **[PHONE]** The «before» run: build with `flutter build apk --release --dart-define=FRAME_TRACE=true
  --dart-define=PAGE_TURN_TRACE=true` from the code at the end of T002 (nothing of Stage A in it), install only with the
  owner's approval, and run `phone/measure.sh --approved-by-owner --label before --pace slow|normal|fast` in browse mode and
  with `--and-back` in wird mode (quickstart "On the phone"); save `phone/results/` summaries and copy the six summary lines
  into research.md D9 under "Phone results, before". If the owner declines, write that in D9 and use the test numbers of D8
  as the only «before» (spec SC-001, research D9)

---

## Phase 2: Foundational (blocks the stories; nothing visible changes)

- [X] T004 [P] Test-first: `test/motion/motion_tokens_test.dart` (red): every duration, curve and distance equals the table of
  contracts/ui.md "Tokens" (data-model.md "Motion tokens"), `Motion.of(context, d)` is `d` normally and `Duration.zero` when
  `accessibilityFeaturesTestValue` has `disableAnimations: true`, `Motion.reduced` follows a change of the setting between two
  reads, no token is above 300 ms; then `lib/motion/motion.dart` per contracts/dart-interfaces.md (spec FR-014, FR-015)
- [X] T005 [P] Test-first: `test/motion/mushaf_repository_prefetch_test.dart` (red) with a counting bundle
  (`test/support/motion_probe.dart` `FileBundle`): `peek(p)` is null before a load and the page after it, `prefetch(p)` ignores a
  missing page, prefetching pages 100 to 119 in order reads **each asset once** (today 2 reads per page, research D1 H5), and
  `endMarkerIds` of every page are the same as the old path gives for all 604 pages (prefetch in ascending order and in
  descending order, each compared with a page loaded alone, and 6,236 markers in all as `test/mushaf/end_markers_test.dart`
  expects); then `lib/mushaf/mushaf_repository.dart` (the first word of the next page
  comes from the prefetch of that page; the old one-read fallback stays for a page asked on its own). `test/mushaf/
  mushaf_repository_test.dart` and `end_markers_test.dart` stay green unchanged (research D4)
- [X] T006 [P] Test-first: `test/motion/page_font_prefetch_test.dart` (red) with a counting bundle: `prefetch(50)` asks 51 and
  52 before 49 and 48, `prefetch(50, direction: -1)` asks 49 and 48 first, a loaded or loading page is not asked again, pages
  outside 1..604 are skipped, a failed load is retried by a later `ensure`; then `lib/mushaf/page_font_loader.dart` (default
  `direction` keeps today's callers unchanged) (research D4)
- [ ] T007 Test-first: `test/motion/reader_controller_page_seen_test.dart` (red): `pageSeen(p)` changes `page`, notifies once and
  writes nothing (the wird's `currentPage` and `lastViewedPage` are as before), `savePosition()` writes `setPage` (following a
  wird) and `setLastViewedPage`, `onPageShown(p)` is `pageSeen` + `savePosition` with the same results as today, a page outside
  1..604 throws `ArgumentError` as before; then `lib/mushaf/reader_controller.dart`. `test/mushaf/reader_controller_test.dart`
  stays green unchanged (research D3 item 3; Constitution VII)

---

## Phase 3: User Story 1 - Turning a page never stutters (Priority: P1) - Stage A

**Goal**: no page that is drawn is rebuilt for a reason that is not its own, and the incoming page is ready before the finger
moves.

**Independent test**: `test/motion/reader_rebuild_budget_test.dart` and `reader_neighbours_ready_test.dart` (the numbers of
D8 as bounds), then the phone numbers of SC-001 and SC-002.

**Window R1 (reader_screen.dart): T010 to T013 in one sitting, in this order** (the cache first: three pages alive without it
would triple the cost of every whole-screen rebuild, research D13).

- [X] T010 [US1] **[R1]** Test-first: `test/motion/reader_rebuild_budget_test.dart` (red against today's code, which builds 3 and
  5 pages per turn): with `pumpMotionReader` (browse mode and wird mode, database delayed 8 ms), a turn builds `MushafPage` at
  most **1** time, a bar tap, a today-panel toggle and a database answer build it **0** times (SC-003); then in
  `lib/mushaf/reader_screen.dart` `_PageItemState` keeps its `MushafPageCard` and makes a new one only when data, font family,
  look, reading size, highlighted ids, meta or the callbacks (compared with `==`) change (research D3 item 1; spec FR-003).
  The earlier reader tests stay green
- [X] T011 [US1] **[R1]** Test-first: `test/motion/reader_narrow_listeners_test.dart` (red): a page turn, a database answer and a
  bar tap rebuild the `PageView` and the `Scaffold` 0 times, rebuild `_BottomBar` 0 times, rebuild `_TopBar` only when what it
  shows changed (page, wird name, today list, panel state, bookmark state); then `reader_screen.dart` loses the `ListenableBuilder`
  around the `Scaffold`: the top bar, the card layer and the pager listen to what they show (per-page lock and highlight through
  small `ValueNotifier`s); `ReaderController` keeps its one `ChangeNotifier`. Existing tests for the lock, the highlight and the
  position rules stay green (research D3 item 2; spec FR-004)
- [X] T012 [US1] **[R1]** Test-first: `test/motion/reader_neighbours_ready_test.dart` (red): after the reader settles, the next
  and the previous page are built (`find.byType(MushafPage, skipOffstage: false)` finds 3) while `find.byKey(page-number)` still
  finds exactly one widget, no `MushafPageLoading` card exists for a neighbour whose data and font are ready, the first frames of
  a swipe (finger down, dragging, past the middle) build 0 `MushafPage`, and the whole turn builds at most 1 (the next
  neighbour, at the end of the slide); then `reader_screen.dart`: `PageView.builder(allowImplicitScrolling: true,
  scrollCacheExtent: ScrollCacheExtent.pixels(1))`, `_PageItemState` takes the page synchronously when `MushafRepository.peek`
  has it and `PageFontLoader.isLoaded` says so (no `FutureBuilder` round trip), the loading card only for a page that is not
  ready. `pager_prewarm_spike_test.dart` keeps passing (spec FR-002; research D2, S1)
- [X] T013 [US1] **[R1]** Test-first: `test/motion/reader_loading_after_slide_test.dart` (red) with a counting bundle given to
  `MushafRepository`: no page data is requested between the first moving frame of a swipe and the end of the slide, and the
  neighbours of the new page are requested after it (nearest first, in the direction of the swipe); then `reader_screen.dart`:
  `_onPageChanged` keeps calling `_controller.onPageShown(page)` (the position is written exactly when it is today; Stage A does
  not change Constitution VII's behaviour) and starts no prefetch, the prefetch of data and fonts runs from the pager's
  `ScrollEndNotification` (already seen by `_onPagerScroll`) and after a jump from the first frame, and under
  `PAGE_TURN_TRACE` a swipe start prints `FrameTrace.warmLine(...)` for the two neighbours. The font half is checked on the phone
  by the frame trace (the reader cannot be given another `PageFontLoader` in a test) (spec FR-005; research D4, D9)
- [X] T014 [US1] Tighten the before-numbers into after-bounds in my own files `test/motion/reader_rebuild_count_test.dart`
  (the `_watch` list gets `Scaffold` and `PageView`: rebuilds of both per turn become 0; `MushafPage` builds per turn at most 1; the
  `ListenableBuilder` count is no longer a whole-screen measure after T011 and its bound `lessThan(30)` is replaced) and
  `page_build_cost_test.dart` where a number changed; copy the printed counts into research.md D8 under "After Stage A"
  (SC-003; research D8)
- [ ] T015 [US1] Run the earlier suites unchanged and the analyzer: `flutter analyze`, `flutter test test/mushaf test/bookmarks
  test/khatm test/wirds test/look test/ayah test/render test/settings`; fix only the new code if anything fails; record the
  counts in the commit message (spec FR-016, SC-006)
- [ ] T016 **[PHONE]** Gate A: build with the traces, install with approval, the same six runs with `--label after-A`; compare with
  T003 (`summary.txt` side by side: share within the budget, p99, max, `PAGETURN`, `PAGEWARM`); write the table into research.md D9
  "Phone results, after Stage A" and say which of SC-001, SC-002 are met; if they are met go to the motion phases and skip
  Stage C, otherwise use "What a failed number points at" to choose among T060-T063 (spec SC-001, SC-002)

---

## Phase 4: User Story 2 - Bars and the today panel move softly (Priority: P2)

**Goal**: the bars and the card fade and slide a little; the page never moves.

**Independent test**: `reader_bars_motion_test.dart`, `today_card_motion_test.dart` and the geometry test.

- [X] T020 [P] [US2] Test-first: `test/motion/fade_slide_switcher_test.dart` (red): a child that appears is transparent in the first
  frame and opaque after `durationIn` (±2 frames), a child that is replaced by null stays for `durationOut` ignoring pointers and
  excluded from semantics and is then gone from the tree, a reversal in the middle starts from the current opacity, `slide: 0`
  only fades, reduced motion shows or removes the child in the next frame; then `lib/motion/fade_slide_switcher.dart` per
  contracts/dart-interfaces.md (spec FR-008, FR-014, FR-015)
- [X] T021 [US2] **[R2]** Test-first: `test/motion/reader_bars_motion_test.dart` (red) and `test/motion/
  reader_geometry_during_motion_test.dart` (the geometry file is created here and extended in T022 and T032): a tap on the page
  hides both bars with a fade in 160 ms (present and partly transparent at 80 ms, gone at 250 ms), a second tap brings them back
  in 200 ms, a leaving bar ignores taps, a tap during the fade reverses it, the `PageView`'s rectangle and the line and word
  rectangles of pages 1, 2, 50, 293 and 604 are identical (0 px) in every frame, a **rotation or a lifecycle change switches the
  bars at once** (no animation: `durationIn/Out` are zero unless the change came from `_toggleBars`), the PDF strip above the
  bottom bar moves with an `AnimatedPositioned` of the bar's duration; then `reader_screen.dart`: the two slots keep their 84 and
  68 dp `SizedBox`es and their content goes through `FadeSlideSwitcher` (`slide: -24` for the top bar and `+24` for the bottom).
  The existing tests that tap the page and pump 300 ms stay green (spec FR-008; contracts/ui.md; research D6)
- [X] T022 [US2] **[R2]** Test-first: `test/motion/today_card_motion_test.dart` (red): the chip opens the card with a fade and a 12 dp
  slide in 220 ms, close (chip, «×», a tap outside) fades it in 160 ms, the modal barrier exists exactly while the panel is open
  (a tap during the fade-out reaches the page and does not hit the leaving card), the saved `todayPanelExpanded` is written as
  today, the geometry test of T021 is extended with the card open; then `reader_screen.dart`: the card through `FadeSlideSwitcher`
  with `slide: -12` and the barrier outside it. `test/wirds/wirds_ui_test.dart` stays green (spec FR-009)

---

## Phase 5: User Story 3 - Jumps, the bookmark icon, the wird name and the look change softly (Priority: P2)

**Goal**: the remaining abrupt changes get a short, calm motion.

**Independent test**: `jump_fade_test.dart`, `reader_jump_fade_test.dart`, `bookmark_icon_motion_test.dart`,
`reader_wird_name_motion_test.dart`, `look_fade_test.dart`.

- [X] T030 [P] [US3] Test-first: `test/motion/fade_in_on_change_test.dart` (red): the first build shows the child opaque (no fade at
  start), a changed `value` shows the new child at once at opacity 0 and (with `fromScale: 0.8`) scale 0.8, and reaches 1.0 after
  `duration` (±2 frames), the old child is never in the tree (one child at any time), a rebuild with the same value does not
  restart it, reduced motion gives the end state in the next frame; then `lib/motion/fade_in_on_change.dart` (research D6)
- [X] T031 [P] [US3] Test-first: `test/motion/jump_fade_test.dart` (red): `controller.play()` makes the child 0.35 opaque in the first
  frame and 1.0 after 180 ms (`easeOut`), a second `play()` in the middle starts from the current opacity, nothing runs without a
  `play()` (no animation at start), reduced motion jumps to 1.0 in the next frame, disposing in the middle is clean; then
  `lib/motion/jump_fade.dart` (spec FR-010)
- [X] T032 [US3] **[R2]** Test-first: `test/motion/reader_jump_fade_test.dart` (red): a go-to-page confirm (page 50 to 300) shows
  page 300 in the first frame at about 0.35 opacity and opaque after 180 ms, the top line shows the new surah and the saved
  position is page 300 on the first frame, at most 3 `MushafPage` are built (no page between), a jump to the page already shown
  plays nothing, the first frame of a start from a notification plays nothing, a wird chosen in «أوراد» fades its page in; the
  geometry test is extended; then `reader_screen.dart`: `JumpFade` around the pager area and `_syncPager` calls `play()` after the
  `jumpToPage` it makes (spec FR-010)
- [X] T033 [P] [US3] Test-first: `test/motion/bookmark_icon_motion_test.dart` (red): after a tap the icon of the other state is the
  only icon in the tree (the feature 006 expectation), it is 0.8 scaled and transparent in the first frame and at full size and
  colour 160 ms later, the 48 x 48 target and the one `bookmark-button` semantics node are unchanged, reduced motion gives the end
  state in one frame; then `lib/mushaf/bookmark_button.dart` wraps the `Icon` in `FadeInOnChange(value: on, fromScale: 0.8)` (the
  `Semantics` stays outside). `test/bookmarks/` stays green unchanged (spec FR-011)
- [X] T034 [US3] **[R2]** Test-first: `test/motion/reader_wird_name_motion_test.dart` (red): choosing another wird changes the pill's
  name to the new one at once at opacity 0 and 1.0 after 160 ms, exactly one name text in the pill at any time; then
  `reader_screen.dart`: the pill's `Text` inside `FadeInOnChange(value: wirdName)` (spec FR-011)
- [X] T035 [US3] Test-first: `test/motion/look_fade_test.dart` (red): `LookFade.around(context, change)` captures the screen, runs
  `change`, shows the picture over the new look and fades it out in 220 ms; the saved choice and the new theme are in place on the
  first frame (`test/look/look_provider_test.dart` stays green: `themeAnimationDuration` stays zero, the first frame of a start is
  already the saved look, `AppLook.lerp` is untouched); with «remove animations» on or without a `LookFadeHost` it is the
  instant switch of today; a look change with Settings open fades over Settings; then `lib/motion/look_fade.dart`, the host in
  `lib/app.dart` around `home` (check `git status` first: features 008/009 may edit it) and `look_tile.dart` calling
  `LookFade.around` (research D6, D11; spec FR-012). Last motion task: it can be dropped alone if the owner prefers the instant
  switch (quickstart question 3)

---

## Phase 6: User Story 4 - «Remove animations» is honoured everywhere (Priority: P1)

**Goal**: with the setting on, nothing this feature adds moves, including the edge turn the framework does not shorten.

**Independent test**: `reader_edge_turn_reduced_test.dart`, `reduce_motion_reader_test.dart`.

- [X] T040 [US4] **[R2]** Test-first: `test/motion/reader_edge_turn_reduced_test.dart` (red): with the text at 150% (`pumpSizedReader`) a
  swipe from the left edge turns the page in 300 ms with animations on and shows the new page in the next frame with
  `disableAnimations: true`, and in both cases the incoming page's `MushafPage` is already built before the turn starts (spec
  User Story 1 scenario 5); then `reader_screen.dart` `_onEdgeTurn`: `pages.jumpToPage(target)` when `Motion.reduced(context)`,
  else the same `animateToPage(target, duration: Motion.edgeTurn, curve: Motion.enter)` (today's 300 ms `easeOutCubic`)
  (spec FR-014; research D7)
- [X] T041 [US4] Test-first: `test/motion/reduce_motion_reader_test.dart`: with the setting on, the bars, the card, a jump, the
  bookmark icon, the wird name and a look change each reach their end state in the first frame after they start (SC-005); with it
  off each lasts its contracts/ui.md duration within 2 frames; flipping the setting between two motions changes the next one;
  rotation and a lifecycle resume replay nothing, and pushing a route, opening a sheet and showing a snack bar still use the
  framework's transitions (the theme's page transitions are not replaced, FR-013). A sweep over what T021 to T040 built: it should pass at once; a failure is a
  defect in the task it names (spec FR-014, SC-005)

---

## Phase 7: Stage B - the phone gate

- [ ] T050 **[PHONE]** The «after» run with every motion in: `--label after-motion`, the three paces in both modes, the memory
  readings before and after 200 swipes, the manual list of quickstart step 7 with «remove animations» on and off and TalkBack on;
  table in research.md D9 "Phone results, after the motion"; decide which of T060-T063 are still needed (a number that misses
  SC-001, SC-002 or SC-004 names its hypothesis in D9) (spec SC-001 to SC-005, SC-008)

---

## Phase 8: Stage C - only what the phone still shows (CONDITIONAL; each task starts with the number that justifies it)

- [ ] T060 [CONDITIONAL on H3: wird mode misses SC-001 and browse mode meets it] Test-first: `test/motion/position_saver_test.dart`
  (red): `markDirty()` then 399 ms writes nothing, 400 ms writes once with the last page, ten dirty marks in a burst write once,
  `flush()` writes at once and only when dirty, `dispose()` cancels the timer; `test/motion/reader_position_flush_test.dart`
  (red): the saved position is on disk before the wirds list opens, on lifecycle paused/inactive/detached, on dispose, on a jump
  and on «آمين» of the khatm dua, and `currentPage` after a swipe plus 500 ms is the last page; then `lib/mushaf/position_saver.dart`
  and **[R3]** `reader_screen.dart`: `_onPageChanged` marks dirty, flushes at the points of contracts/dart-interfaces.md. Re-run
  every earlier test that reads `currentPage` after a swipe (`test/mushaf`, `test/khatm`) (spec FR-007, SC-007; research D5;
  Constitution VII; checklist CHK016-CHK018)
- [ ] T061 [CONDITIONAL on H8: frames are clean and the owner still says «ثقيل»] Test-first: `test/motion/pager_physics_test.dart`:
  the reader's physics settles a 200 px release in at most 400 ms and still lands on a page, never between two; then a
  `PageScrollPhysics` subclass with a stiffer spring in `lib/motion/page_physics.dart` and the one-line use in `reader_screen.dart`
  **[R3]** (research D10)
- [ ] T062 [CONDITIONAL on H4: memory grows by more than 60 MB over 200 swipes or `prefetch` shows in the frame trace] Test-first:
  `test/motion/page_font_budget_test.dart`: `PageFontLoader` asks for no more than the pages of the window around the shown one
  and not again for a page it has; then limit the prefetch window to ±1 while flipping fast (>= 4 turns per second) in
  `lib/mushaf/page_font_loader.dart` (research H4)
- [ ] T063 [CONDITIONAL on H6/H7: `build` or `raster` is still the long column after Stage A] Decision first, in research.md D12 with
  the owner: one long-press recognizer per page instead of 94 `GestureDetector`s; needs the geometry baselines of 003, 004 and 006
  and the 604-page layout checks green before and after, and `test/mushaf/*` that long-press `ValueKey('w<id>')` unchanged
  (Constitution I)

---

## Phase 9: Polish

- [ ] T070 Run `flutter analyze` (no issues) and the **whole** suite once: `flutter test`; record the counts in the commit message
  (Constitution IX)
- [ ] T071 Confirm the geometry baselines are equal: `test/mushaf/page_layout_invariance_test.dart`, `page_layout_both_looks_test.dart`,
  `test/bookmarks/reader_bookmark_geometry_test.dart`, the 003 size tests, the contrast walk `test/look/contrast_walk_test.dart` and the
  48 dp targets (spec FR-017), plus `reader_geometry_during_motion_test.dart` (spec FR-016,
  SC-004, SC-006)
- [ ] T072 Tick the tasks, copy the final before/after numbers into research.md D8 and D9, and re-run the requirements checklist
  `checklists/motion.md` with the reviewer (it is theirs to mark)
- [ ] T073 **[PHONE]** Final check with the owner (quickstart step 8): the lag is gone and the motion feels soft but not slow (yes or
  no, SC-008); the feature is done only after this and T070 (Constitution IX)

---

## Dependencies and order

- T002 and T004-T007 are independent new-file tasks (T007 and T005 edit existing library files that no one else is editing: check
  `git status`). T003 needs T002 and the owner.
- Window R1 (T010-T013) needs T005, T006, T007. T014-T015 follow T013. T016 needs T015 and the owner.
- T020, T030, T031, T033 are independent of the reader and can be done any time after T004. Window R2 (T021, T022, T032, T034,
  T040) needs T010-T013 done and T004, T020, T030, T031; T041 needs all of Phases 4 to 6. T035 needs T004 only.
- T050 needs everything of Phases 4-6. Stage C tasks need T016 or T050 to justify them. T070-T073 are last.

## Parallel opportunities

T002, T004, T005, T006 (four people, four files); T020, T030, T031, T033 (four new widgets); T035 against the reader windows.

## Implementation strategy

MVP is Stage A (T002 to T016): it fixes the owner's complaint (the lag) and nothing else. Then the motion phases in priority order
(US4's tasks ride with the motion they cover), then the phone gate T050, and Stage C only for the numbers that still fail. Every
task is one commit that holds its own test; the suite is green after each.

## Summary

| | Count |
|---|---|
| Tasks | 34 (1 done) |
| Touching `lib/mushaf/reader_screen.dart` | R1: T010, T011, T012, T013; R2: T021, T022, T032, T034, T040; R3 (conditional): T060, T061 |
| Phone tasks (owner present) | T003, T016, T050, T073 |
| Conditional (Stage C) | T060-T063 |
