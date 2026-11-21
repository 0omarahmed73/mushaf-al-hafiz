# Tasks: App Icon and Animated Splash Screen

**Input**: `specs/009-app-icon-splash/` (spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md,
checklists/splash.md)

**Rules**: test-first (a failing test is written and run red before the code that makes it pass); one commit per task;
`git add` explicit paths only and `dart format` on explicit files only (other sessions edit this tree: never `git add -A`,
`git add .`, `git stash`, `git reset`, `git checkout`, `git restore`, `git clean`); commit with `git commit -m "..." --
<paths>`; retry if `index.lock` exists. **New tests go in NEW files** under `test/splash/`; no existing test is edited
(spec FR-019). `.specify/feature.json` is NOT changed (speckit scripts run with `SPECIFY_FEATURE_DIRECTORY=specs/009-app-icon-splash
SPECIFY_FEATURE_NO_PERSIST=1`); no branch is created. Files this feature may edit: `specs/009-app-icon-splash/**`,
`android/app/src/main/res/**`, `lib/splash/**`, `lib/main.dart` (one hunk, T019), `tool/**` (new files), `test/splash/**`.
**Never touched**: `lib/mushaf/**`, `lib/settings/**`, `lib/reminders/**`, `lib/wirds/**`, `lib/app.dart`,
`android/app/build.gradle.kts` (another session owns it), `docs/**`, the constitution, `pubspec.yaml` (no asset, package
or font is added), any existing test. Run only the relevant tests with a timeout and the output to a file, e.g.
`timeout 600 flutter test test/splash --reporter expanded > $SCRATCH/splash_tests.txt 2>&1`; never the whole suite.
Do not build an APK, do not touch the phone or adb, do not install or download anything. Commit trailer:
`Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.

The tagline of the splash is an Arabic string written by the assistant: a **proposal** until the owner confirms it (T001,
T028). The feature is not done before the real-device check of the quickstart (done by the coordinator on the phone, after T028).

Key: **FR/SC** are the spec's requirement and success-criterion ids; "data-model.md X" is the cited definition. The plan
lists one resource test file; it is split in two by story (`android_icon_resources_test.dart`, `android_launch_resources_test.dart`).

## Phase 1: Setup

- [X] T001 Test-first: `test/splash/splash_strings_test.dart` (red): `kSplashName` equals `'مصحف الحافظ'`, equals `MushafApp.title`
  (import `package:mushaf/app.dart`) and the `android:label` of `android/app/src/main/AndroidManifest.xml`; `kSplashTagline`
  equals `'المصحف كاملاً بلا إنترنت وبلا إعلانات'`; `SplashColors` holds the design's colours exactly (#0D1014, #17313A, #ECE7DC,
  #9AA4AD, #232A33, #6CC4B5, #E3B05A, …); then `lib/splash/splash_strings.dart` (the tagline's doc comment says «proposal until
  the owner confirms», Constitution VI) and `lib/splash/splash_palette.dart` (contracts/dart-interfaces.md `splash_strings.dart`
  and `splash_palette.dart`; spec FR-008, FR-017)

---

## Phase 2: Foundational (blocks every story)

**Purpose**: the pure rules and the drawing as data, none of which import a widget. Nothing visible changes.

- [X] T002 Test-first: `test/splash/splash_plan_test.dart` (red) with every case of contracts/dart-interfaces.md `splash_plan.dart`
  (not ready never leaves, at any time and with a tap; ready at 899 ms stays and at 900 ms leaves; ready and skipped leaves at
  0 ms; reduced motion leaves at 300 ms and not at 299 ms; skipped but not ready never leaves; the four constants equal
  data-model.md `SplashPlan.fullDuration`, `SplashPlan.minimum`, `SplashPlan.reducedStay`, `SplashPlan.fade`); then
  `lib/splash/splash_plan.dart` with no Flutter import (spec FR-010, FR-011; research D2)
- [X] T003 [P] Test-first: `test/splash/splash_timeline_test.dart` (red) with the rules of contracts/dart-interfaces.md
  `splash_timeline.dart` (first frame is flat; ranges for 0..2000 ms in 1 ms steps; monotone opacities, scale, backdrop, stars and
  progress; `twinkle` is 0 outside 400..800 ms and peaks once; from 900 ms every field except `progress` equals the final frame;
  from 1400 ms the whole frame equals `finalFrame`; negative durations clamp); then `lib/splash/splash_timeline.dart` with no
  Flutter import, the beats of research D3 (data-model.md `SplashFrame.backdrop`, `SplashFrame.stars`, `SplashFrame.tileOpacity`, `SplashFrame.tileScale`,
  `SplashFrame.twinkle`, `SplashFrame.nameOpacity`, `SplashFrame.lineOpacity`, `SplashFrame.nameRise`, `SplashFrame.lineRise`, `SplashFrame.progress`; spec FR-009)
- [X] T004 [P] Test-first: `test/splash/icon_geometry_test.dart` (red): `parsePath` bounds for a rectangle and a curve, `FormatException`
  for `A`, a lower-case command and a missing number; the star diamond is the square turned 45° about (54, 25); every colour and
  stroke width equals data-model.md `Icon geometry` (the `Icon2.dc.html` values) and the two placements equal data-model.md
  `Icon geometry.legacy placement` and `Icon geometry.adaptive placement`; `farthestFromCentre(adaptive) <= 33` and
  `farthestFromCentre(legacy) > 33` (the measured values are 32.33 and 34.23, research D5); then `lib/splash/icon_geometry.dart`
  (`AppIconGeometry`, `IconPlacement`, the path parser for absolute `M L C Z`; spec FR-001, FR-002, FR-004)
- [X] T005 [P] Test-first: `test/splash/support/xml_check_test.dart` (red): the checker accepts a vector, a layer-list and a style
  file, accepts comments and `<?xml ?>`, and rejects an unclosed tag, a mismatched tag, an unquoted attribute and two roots; then
  `test/splash/support/xml_check.dart` (a tiny tokenizer, no package: `package:xml` is only a transitive dependency) returning
  the list of elements with their attributes so later tests can read `android:drawable` and `android:pathData`
  (contracts/android-resources.md invariant 1)

---

## Phase 3: User Story 1 - The app has its own icon (Priority: P1) 🎯 MVP

**Goal**: spec User Story 1. **Independent test**: `android_icon_resources_test.dart` finds the adaptive icon with its three
layers, five PNGs of the right size and palette, and vectors equal to what the tool writes; on the phone the launcher shows
the icon (quickstart step 1 and 2).

- [X] T006 [US1] Test-first: `test/splash/app_icon_painter_test.dart` (red): paint `AppIconPainter` at 192 px into an image
  (`tester.runAsync`, `PictureRecorder`) and read pixels: the top-left area is dark (the #1A212A end of the gradient), the
  bottom is darker, the star's centre area is teal, the left page area is ivory #ECE7DC and the right page #D6D0C1, a pixel
  on the gold line is gold #E3B05A, the star hole is #0D1014; with `twinkle: 1` the star area is larger than with 0;
  `withBackground: false` leaves the corners transparent; then `lib/splash/app_icon_painter.dart` (contracts/dart-interfaces.md
  `app_icon_painter.dart`; spec FR-001, FR-004)
- [X] T007 [US1] Test-first: `test/splash/android_icon_resources_test.dart` (red) for contracts/android-resources.md invariants 1, 2,
  3, 4 and 6 for the icon files: `mipmap-anydpi-v26/ic_launcher.xml` is an `adaptive-icon` naming `ic_launcher_background`,
  `ic_launcher_foreground` and `ic_launcher_monochrome`, all three exist under `drawable/`; each of the five
  `mipmap-*/ic_launcher.png` has the PNG signature, the size 48/72/96/144/192, a transparent corner pixel and ivory, teal and
  gold in the right regions (so the Flutter default fails); the three vector files equal `AppIconResources.background()`,
  `foreground()` and `monochrome()` (imported by relative path from `tool/app_icon_resources.dart`); the foreground's group has
  the adaptive placement and every `pathData` of the foreground equals a constant of `AppIconGeometry`; the monochrome
  has one colour and the even-odd star (spec FR-002, FR-003, FR-004, SC-007)
- [X] T008 [US1] `tool/app_icon_resources.dart` (`AppIconResources.background/foreground/monochrome`, strings computed from
  `AppIconGeometry`, research D5) and `tool/make_app_icons.dart` (a `testWidgets` file; this task writes the three vectors),
  run `flutter test tool/make_app_icons.dart`; add the hand-written `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`;
  commit the tool, the three `drawable/ic_launcher_*.xml` and the adaptive XML. The PNG checks of T007 stay red until T009
  (contracts/android-resources.md; data-model.md `Icon geometry.adaptive placement`)
- [X] T009 [US1] Extend `tool/make_app_icons.dart` to draw `AppIconPainter` as a rounded square (corner radius 25%, transparent
  corners, the legacy placement) at 48, 72, 96, 144 and 192 px and write the five `mipmap-*/ic_launcher.png`; run it; commit the
  tool and the five PNGs; `android_icon_resources_test.dart` is green. View one PNG to check by eye that it is the design
  (spec FR-003; research D6)

**Checkpoint**: the icon exists in every form; the phone check is in the quickstart.

---

## Phase 4: User Story 2 - Dark start, then the splash plays and hands over to the Mushaf (Priority: P1)

**Goal**: spec User Story 2. **Independent test**: `android_launch_resources_test.dart` finds the dark launch screen in the day
and night sets; `splash_screen_test.dart` and `splash_gate_test.dart` show the splash appear with its content, play, end, and
leave the child (the app) behind it intact; `splash_wiring_test.dart` finds the production wiring and no splash in `app.dart`.

- [X] T010 [US2] Test-first: `test/splash/android_launch_resources_test.dart` (red) for contracts/android-resources.md invariants 1, 2,
  5, 7: `values/colors.xml` defines `splash_background` #0D1014; `drawable/launch_background.xml` and
  `drawable-v21/launch_background.xml` are a `layer-list` with the colour item and the foreground item (gravity center, 140 dp), and
  contain neither `white` nor `colorBackground`; `values` and `values-night` styles define `LaunchTheme` (parent
  `Theme.Black.NoTitleBar`, `windowBackground` = `@drawable/launch_background`) and `NormalTheme` (`windowBackground` =
  `@color/splash_background`); `values-v31` and `values-night-v31` carry `windowSplashScreenBackground`,
  `windowSplashScreenAnimatedIcon` = `@drawable/ic_launcher_foreground` and `windowSplashScreenAnimationDuration`, and are
  identical to each other; every reference resolves (spec FR-005, FR-006, SC-007)
- [X] T011 [US2] The launch resources: `values/colors.xml`, both `launch_background.xml`, `values/styles.xml`,
  `values-night/styles.xml`, `values-v31/styles.xml`, `values-night-v31/styles.xml` as in contracts/android-resources.md; run the
  `aapt2 compile` + `aapt2 link` check of the quickstart on the whole `res/` (scratch manifest, output only in the scratch
  folder) and fix what it reports; `android_launch_resources_test.dart` green (spec FR-005, FR-006; research D7)
- [X] T012 [US2] Test-first: `test/splash/splash_painters_test.dart` (red): at 390 × 844 the pixel at the glow centre (195, 253) is
  lighter than the corner (0, 0); the corner equals #0D1014; with `backdrop: 0` the whole picture is flat #0D1014; with `stars: 1`
  the dot at (60, 90) is lit and with `stars: 0` it is not; at a 195 × 422 size the same dot appears at (30, 45) (proportional
  placement, contracts/dart-interfaces.md `splash_painters.dart`); `ProgressLinePainter` at progress 0.45 fills 54 of the 120 px track
  in #6CC4B5 over #232A33; then `lib/splash/splash_painters.dart` (spec FR-008)
- [X] T013 [US2] Test-first: `test/splash/splash_screen_test.dart` and `test/splash/splash_gate_test.dart` (red), basic behaviour: the
  first frame shows no name and no tile (flat background); with `ready: false`, at 1000 ms the name «مصحف الحافظ» and the tagline are found
  and fully visible; at 1400 ms the final frame; with `SplashGate(child: ...)` the child is built from the first frame and keeps its
  `State` after the splash is gone; the gate provides `Directionality` rtl and a `MediaQuery` when none is above it; with `ready: true` the splash
  is gone from the tree at the latest 1400 ms + 220 ms (spec FR-007, FR-008, FR-009; research D1, D4)
- [X] T014 [US2] `lib/splash/splash_screen.dart` and `lib/splash/splash_gate.dart` (first version: one `AnimationController` of
  `SplashPlan.fullDuration` as the clock, the pure `SplashTimeline.at` painted through `AppIconPainter`,
  `SplashBackgroundPainter`, `ProgressLinePainter` and two `Text`s (ReemKufi 700 at 44 px #ECE7DC; Cairo at 15 px #9AA4AD), the
  220 ms fade, the tile inside a `RepaintBoundary` with the teal glow shadow; it leaves when the clock ends; `ready`, tap, reduced
  motion and `onFinished` are added by T018, T020, T024; `SplashScreen` takes `ready` and `onGone` from the start (contracts/dart-interfaces.md
  `splash_screen.dart`), `ready` unused until T018, and the gate removes the overlay in `onGone`); `splash_screen_test.dart` and `splash_gate_test.dart` green
  (spec FR-007–FR-009, FR-015)
- [X] T015 [US2] Test-first: `test/splash/app_when_ready_test.dart` (red): a dark box (#0D1014) before the future completes; the
  app widget after; an error is rethrown from `build` (the test catches it through `tester.takeException`); then
  `lib/splash/app_when_ready.dart` (contracts/dart-interfaces.md `app_when_ready.dart`; spec FR-007, Edge Cases)
- [X] T016 [US2] Test-first: `test/splash/splash_wiring_test.dart` (red): `lib/main.dart` imports `splash/splash_gate.dart`, calls
  `runApp(SplashGate(` with `ready:` and `AppWhenReady(`, defines `_bootApp`, and no `runApp` call appears before it; `lib/app.dart`
  contains no `splash`; no file under `test/` other than `test/splash/` mentions `SplashGate` (spec FR-016, FR-019); every `import` in `lib/splash/` is `dart:*`, `package:flutter/*` or a
  relative file of `lib/splash/` (no theme, provider, settings, database, network: spec FR-015) and `pubspec.yaml` lists none of `flutter_svg`,
  `flutter_native_splash`, `flutter_launcher_icons`; then edit
  `lib/main.dart` in one hunk (after `git status` and `git log -- lib/main.dart`; the old body of `main()` becomes
  `Future<MushafApp> _bootApp()` ending in `return MushafApp(...)`, `main()` calls `WidgetsFlutterBinding.ensureInitialized()`,
  `_bootApp()` and `runApp(SplashGate(ready: app, child: AppWhenReady(app)))`; research D1) and run
  `flutter analyze lib/main.dart lib/splash`

**Checkpoint**: a cold start shows the dark native screen, the splash plays and leaves; `ready` and the tap come next.

---

## Phase 5: User Story 3 - Light, never longer than needed, a tap skips it (Priority: P2)

**Goal**: spec User Story 3. **Independent test**: `splash_timing_test.dart` with fake time.

- [X] T017 [US3] Test-first: `test/splash/splash_timing_test.dart` (red) with the scenarios of spec User Story 3 and contracts/dart-interfaces.md
  `splash_screen.dart`: ready from the start: still shown at 899 ms, leaving at 900 ms, gone at 900 + 220 ms; not ready: shown at
  5 s; becoming ready at 2.5 s: gone by 2.5 s + 220 ms and not before; a tap at 300 ms with ready: gone by 300 + 220 ms; a tap
  while not ready: stays, then gone within 220 ms of ready; two taps and a tap while fading: no exception; the gate takes a
  `ready` future: null means ready, a completed future means ready, a failed future also means ready (spec FR-010, SC-002, SC-003)
- [X] T018 [US3] Implement `ready` (a `bool` on `SplashScreen`, a `Future<void>?` on `SplashGate`, errors count as ready) and the tap
  (opaque `GestureDetector`, sets `skipped`) with `SplashPlan.mayLeave` evaluated after every tick and every change; the clock
  stops at its end but leaving is still decided on every change; `splash_timing_test.dart` green (data-model.md
  `State of the overlay.phase`, `State of the overlay.skipped`, `State of the overlay.ready`; research D2)

---

## Phase 6: User Story 4 - Reduce motion (Priority: P2)

**Goal**: spec User Story 4. **Independent test**: `splash_reduce_motion_test.dart`.

- [X] T019 [US4] Test-first: `test/splash/splash_reduce_motion_test.dart` (red), flag set through
  `tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: true)`: the first frame already
  shows the name, tagline, tile and a full thin line; ready from the start: still shown at 299 ms, gone at 300 ms from the first frame with no fade (ready later: gone at that moment)
  (no frame in between with a partial opacity); not ready stays; a tap with ready leaves at once; turning the flag on mid-way
  drops to the static drawing at the next frame without restarting the timeline; `SplashTimeline.at` is never asked for a
  frame (a spy through the painter's inputs: the tile scale stays 1) (spec FR-011)
- [X] T020 [US4] Implement reduced motion: read `MediaQuery.disableAnimationsOf`, paint `SplashTimeline.finalFrame`, clock of
  `SplashPlan.reducedStay`, no fade, follow a change of the flag in `didChangeDependencies`; green (research D2, D3)

---

## Phase 7: User Story 5 - Readable and safe on every phone and setting (Priority: P2)

**Goal**: spec User Story 5. **Independent test**: `splash_layout_test.dart`.

- [X] T021 [US5] Test-first: `test/splash/splash_layout_test.dart` (red where it is not yet true): a 320 × 640 window with a text scale of
  2.0 at the start, at 900 ms and at the end: no exception, no overflow (`tester.takeException` is null); the same at 3.0 and at a
  landscape 640 × 320; the contrast of `SplashColors.name` and of `SplashColors.tagline` against both `SplashColors.background`
  and `SplashColors.backdropGlow` is at least 4.5 (`contrastRatio` from `lib/look/contrast.dart`); one semantics node
  carries the name and the tagline and the child behind has none while the splash shows (`ExcludeSemantics`); a tap on a
  button in the child does not reach it while the splash shows and does after it is gone; after a size change mid-splash (320 × 640 to 640 × 320) the clock is not restarted (the
  frame at 900 ms is still the 900 ms frame); the Reem Kufi and Cairo family
  names equal `kHeadingFont` and `kUiFont` of `lib/theme.dart` (spec FR-012, FR-014, SC-005)
- [X] T022 [US5] Make it pass: `FittedBox(scaleDown)` around the name and around the column, the semantics label `kSplashName` +
  tagline with `ExcludeSemantics` over the drawing, `IgnorePointer` and `ExcludeSemantics` on the child while the splash shows;
  green; `flutter analyze lib/splash` (research D4)

---

## Phase 8: User Story 6 - Something can run when the splash finishes (Priority: P3)

**Goal**: spec User Story 6. **Independent test**: `splash_gate_test.dart` (a new group in a new file `splash_finished_test.dart`).

- [X] T023 [US6] Test-first: `test/splash/splash_finished_test.dart` (red): `onFinished` is called once for a normal end, a tap, reduced motion
  and a failed `ready`; never while the splash is still in the tree (the callback checks `find.byType(SplashScreen)` is empty);
  never twice for two taps; not called by a rebuild of the gate with the same arguments; absent callback: nothing happens
  (spec FR-013, SC-004)
- [X] T024 [US6] Implement `onFinished` in `SplashGate` (post-frame callback after the overlay is removed, guarded by a `finished` flag);
  green (data-model.md `State of the overlay.finished`)

---

## Phase 9: Polish and cross-cutting

- [X] T025 Run `dart format` on every file this feature added or edited (explicit paths), `flutter analyze lib/splash lib/main.dart
  tool test/splash` (no issue), the full `flutter test test/splash` and `flutter test test/app_test.dart test/look` to
  see the existing tests still pass; commit only formatting changes if any (spec FR-019, Constitution IX)
- [X] T026 Run the `aapt2` resource check of the quickstart once more on the final `res/`, and `git diff --stat` to confirm that only
  the allowed paths changed in this feature's commits and `.specify/feature.json` is unchanged (rule list above)
- [X] T027 `/speckit-analyze` then `/speckit-converge`: record findings and any appended tasks here; tick every task that is
  done (spec, plan and tasks agree)
- [X] T028 Write the hand-over in the final report: the new Arabic string, the open questions in Egyptian Arabic (spec Open
  questions), the `onFinished` contract for feature 008, the list of what only the phone can prove (quickstart steps 1 to 9)

**Not done by this session (the coordinator, Constitution IX)**: build a release APK, install it on the owner's phone and go
through the quickstart's phone steps; confirm the tagline with the owner (Open question 2) and the Principle II reading (Open
question 1).

---

## Dependencies and order

- T001 → everything that imports the strings or palette. T002 to T005 are independent of each other (T003, T004, T005 `[P]`).
- US1 needs T004, T005 (geometry, XML checker): T006 → T007 → T008 → T009.
- US2 needs T001 to T004 and T008 (the launch resources refer to the foreground vector): T010 → T011; T012; T013 → T014 (needs T003, T006, T012); T015; T016 (needs T014, T015).
- US3 needs T014 and T002: T017 → T018. US4 needs T018: T019 → T020. US5 needs T014: T021 → T022. US6 needs T018: T023 → T024.
- T025 to T028 last. The phone check is outside this list.

## Implementation strategy

MVP is US1 + US2 (the owner sees the icon and the splash). US3 to US6 make the splash well behaved; they could ship after the
MVP but all are in this feature. Each task ends green and committed before the next starts; the red run of each test-first
task is the evidence kept in the commit message of its implementation task (the failing test names).

---

## Analysis (`/speckit-analyze`, 2026-11-21, before implementation)

Coverage: 19 of 19 functional requirements and 8 of 8 success criteria have a task or a named phone check (FR-015 and FR-016 gained
test assertions in T016; FR-018 is by construction and review; SC-001, SC-006 and the first-frame part of SC-008 are phone-only,
quickstart steps 1 to 9). No task is unmapped. Constrained fields of data-model.md are cited in T002, T003, T004, T008, T018 and
T024 (field names added in this pass where they were generic).

| ID | Category | Severity | Finding | Resolution |
|----|----------|----------|---------|------------|
| C1 | Constitution | CRITICAL under the strict reading | Principle II says the app opens directly on a Mushaf page with no home screen, splash menu or list before it; a branded splash is not a menu, but «directly» can be read to forbid any screen. The owner chose the splash | Cannot be edited here (the constitution is out of scope). Reading recorded in spec Clarifications and plan; spec Open question 1 now carries the proposed PATCH text for the owner. Proceeding on the owner's explicit choice |
| I1 | Inconsistency | HIGH | Reduced motion: «0.3 s once ready» (spec FR-011, US4, SC-002) against `elapsed >= 300 ms` from the first frame with `ready` (data model, tasks T019) | Spec reworded to «at least 0.3 s from the first frame and until ready» |
| I2 | Inconsistency | MEDIUM | T013's content checks at 1000 ms would clash with T018 (ready app starts leaving at 900 ms) | T013 uses `ready: false` for content checks; the end check is an upper bound |
| I3 | Inconsistency | MEDIUM | Plan listed one resource test file and five other test names; tasks name sixteen files | Plan and quickstart lists updated to the task file names |
| I4 | Ordering | MEDIUM | T010 refers to the foreground drawable made in T008 but the dependency line did not say so | Dependencies updated |
| U1 | Underspecification | MEDIUM | `SplashScreen.ready/onGone` signatures needed in T013 (compile) before T018 | T014 says they exist from the start, `ready` unused until T018 |
| U2 | Underspecification | LOW | FR-015 (no package, no setting read) and the rotation edge case had no test | T016 and T021 gained assertions |
| Q1 | Quickstart | LOW | Quickstart said to run `flutter test` (whole suite); this session must not | Reworded: the coordinator runs the whole suite once |

Metrics: 19 FR, 8 SC, 28 tasks, coverage 100%, ambiguity 1 (the word «gently» of FR-009 is made measurable by research D3), duplication 0,
critical 1 (C1, needs the owner, not a task).

## Phase 10: Convergence

Found by `/speckit-converge` on 2026-11-21 after T001 to T026 (19 functional requirements, 8 success criteria, 6 user stories, the plan's
decisions D1 to D10 and the constitution checked against the code): 3 gaps, none against a constitution MUST. Not code gaps and not
tasks: the reviewer-owned checklist `checklists/splash.md` is still unchecked, Principle II is an owner question (spec Open question
1), and the real-device check of the quickstart is the coordinator's.

- [X] T029 [US5] The gate always builds its own `MediaQuery` from the view: under `runApp` nothing above `SplashGate` provides one (the test
  binding does, so the branch `MediaQuery.maybeOf(context) == null` of `lib/splash/splash_gate.dart` never ran in any test, and it is
  the production path); test-first in a new `test/splash/splash_media_query_test.dart` (red): a gate placed under a `MediaQuery` of size
  1 × 1 still gives its splash the real view size and the platform's text scale and reduce-motion flag; then drop the condition in
  `lib/splash/splash_gate.dart` so every run takes the same path per plan research D2 (partial: spec FR-011, FR-014)
- [X] T030 Reconcile the first frame: spec FR-009 says «the first frame MUST not show a bare screen» but the first frame is the flat
  night colour on purpose (it is the colour of the native launch screen, so nothing jumps; `SplashTimeline.at(0)`, tested in
  `splash_timeline_test.dart`, research D3, checklist CHK022). Reword that sentence of `spec.md` FR-009 to «the first frame is the night
  colour of the native launch screen, never white and never empty-looking», and add to `quickstart.md` step 4 what to look at: before
  Android 12 the native icon disappears for the first frames and fades back in (decide on the phone if it is acceptable; one constant
  `SplashTimeline` tile start is the cure) (contradicts: spec FR-009, as written)
- [X] T031 Bring the plan's file list up to date: `specs/009-app-icon-splash/plan.md` Source Code tree lacks `test/splash/support/pixels.dart`
  and `test/splash/support/splash_harness.dart` (and now `test/splash/splash_media_query_test.dart`), which the tests share (partial:
  plan structure)
