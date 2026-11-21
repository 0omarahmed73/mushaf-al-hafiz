# Research: Smooth Motion (feature 010)

Written on 2026-11-21 after reading `lib/mushaf/reader_screen.dart` (working tree with other sessions' uncommitted edits;
line numbers below are of that tree and drift), `reader_controller.dart`, `page_font_loader.dart`,
`mushaf_repository.dart`, `mushaf_page_card.dart`, `mushaf_page.dart`, `page_viewport.dart`, `page_scale.dart`,
`bookmark_button.dart`, `lib/app.dart`, `lib/theme.dart`, `lib/wirds/wird_repository.dart` (the position writes and the two
`watch*` streams), `lib/reminders/reminder_scheduler.dart`, `drift_flutter` 0.3.1 (the database runs in a background
isolate), Flutter 3.50's `page_view.dart` and `framework.dart`, and the phone notes of features 001, 003 and 004
(`quickstart.md` section 5 of 001; `research.md` D7 of 003; D12 of 004). Nothing was run on a phone. The measurements
below were made on the development machine by the tests in `test/motion/` (run them again with
`flutter test test/motion --reporter expanded`; every line starts with `MOTION`).

**How to read the numbers.** `flutter test` runs the Dart VM in JIT mode with assertions on, so absolute milliseconds are
several times what a release build needs on a phone; other agents were also running tests on the machine, so a figure
moves by ±30% between runs. Counts (rebuilds, elements, reads) do not depend on the machine and are the strong evidence;
milliseconds are only good for comparing two things measured in the same run. No millisecond below is a prediction for the
phone. The ranges are the lowest and highest of three runs.

## D1. What is slow: ranked hypotheses

What the earlier phone traces do and do not say: `PAGETURN` (feature 001 SC-007) is the time from the incoming page being
created until its text is painted, and the phone numbers on record are **26 to 52 ms** (003 D7: edge swipes at 150%, a
swipe at 80%, a jump, all in browse mode, driven by `adb input`). So the data and the font are in time, but (1) 26 to 52 ms
is already two to six missed frames at 60 to 120 Hz if it is one long frame inside the slide, (2) nobody measured the
frames of a swipe, and (3) every trace was taken in browse mode, so the path that moves a wird (two writes, two database
streams) has never been measured. «Under 300 ms» was a good gate for "the text appears", not for "the slide is smooth".

| # | Hypothesis | Evidence in the code | What it costs (measured here) | Confidence | Confirm on the phone with |
|---|---|---|---|---|---|
| H1 | **The whole reader is rebuilt in the middle of the slide, and again when the database answers.** `onPageChanged` fires when the pager passes half way, with the finger still down; it calls `_controller.onPageShown`, which calls `notifyListeners`; the `ListenableBuilder` wraps the whole `Scaffold`, so the two visible pages are rebuilt, and `PageView.builder` hands out new, non-const widgets, so every `Text` and `GestureDetector` of both pages is built again though nothing changed. In wird mode `setPage` makes `watchWirds` (`_onWirdsChanged` → another notify) and `watchTodayEntries` (`setState` of the screen) fire a few frames later. | `reader_screen.dart:365-367` (`ListenableBuilder` around the whole `Scaffold`), `:346-350` (`_onPageChanged`), `:400-426` (the `PageView.builder` and its `itemBuilder`), `:127-129` (`_watchToday` `setState`), `:571-600` (`_PageItem` builds a new `MushafPageCard` every time); `reader_controller.dart:77-84` (`onPageShown`: `_notify()`, then `setPage`, then `setLastViewedPage`), `:189-212`, `:214-218`; `wird_repository.dart:291-295`, `:386-391`; `mushaf_page_card.dart:44-92` and `mushaf_page.dart:97-126` (no `const`, no caching). | **Per page turn: 3 `MushafPage` builds in browse mode (1 is needed) and 5 in wird mode, 377-436 and 633-722 `Text` rebuilds (the page itself has 123-153 words).** The extra builds are in two different frames in wird mode (frame 2 mid-slide, frame 4 when the database answered). A page rebuilt with nothing changed costs a third of building it from nothing (median 10-12 ms against 37-39 ms in the test VM) and the frame that does it is among the slowest of the swipe (66-134 ms in the test VM, next to the frame that builds the incoming page, 66-142 ms). **A bar tap rebuilds the page too: 1 `MushafPage` and 500-658 element rebuilds per tap** (M4b). If the page keeps its widget instance, a rebuild costs 0.4-0.6 ms and 0 builds (M3). | **High** (counts are exact; the cost on the phone is not known) | Frame trace: `build` time of the frames in the second half of a slide, with and without the fix; DevTools "Track widget rebuilds" in a profile build (`flutter run --profile`); the build counter from the tests, printed by a debug build |
| H2 | **The incoming page is built and laid out during the slide.** `PageView` builds a neighbour only when the finger moves (cache extent 0), so on the first frames of the swipe `_PageItem` is created, shows the page-number-only card, loads the data, then in a later frame builds about 900 elements and lays out about 130 paragraphs in a font family nobody has used yet (first use shapes and caches the glyphs). That frame is inside the slide. | `reader_screen.dart:400-426` (`PageView.builder` with default `allowImplicitScrolling: false`); `:539-567` (`_PageItemState._load`: data, then font, then the `FutureBuilder` swaps the card); `mushaf_page_card.dart:44-92`, `mushaf_page.dart:154-210` (one `Text` and one `GestureDetector` per word). Spike S1a. | **A page is about 640 elements on average (96 `Text`, 94 `GestureDetector`, 96 `RenderParagraph`), 900 for a full one.** First build with a new font family: median 51-68 ms, worst 214-286 ms (the densest page); the same page built again with the font already used: 37-39 ms. The first build is the slowest frame of the swipe in every run (frame 1: 66-142 ms in the test VM). The phone's own `PAGETURN` of 26-52 ms is that frame plus the waiting. | **High** | `PAGETURN` + frame trace: the longest frame of each swipe is at the start of the slide; `PAGEWARM` trace (D2) shows the neighbour is not ready |
| H3 | **Work caused by saving the position lands in the slide.** Each turn writes `setPage` and `setLastViewedPage`; the writes run in the database isolate, but their answers wake `watchWirds`, `watchTodayEntries` (several queries and a transaction per wird, `today()`), the reminder scheduler (400 ms later, `reminderInputs`: one query per wird plus two) and two rebuilds of the reader (H1). | `reader_controller.dart:77-84`; `wird_repository.dart:291-295`, `:316-340`, `:366-391`, `:427-433`, `:561-564`; `reminder_scheduler.dart:48-53`; `drift_flutter` 0.3.1 `native.dart:131` (background isolate, so the SQL itself is off the UI isolate). | The rebuilds are counted in H1. The queries are not on the UI isolate, only their answers are; not measurable here (the test database runs in the test isolate). | **Medium** | Frame trace in wird mode against browse mode (same swipes): if the wird-mode run has more frames over budget after H1 is fixed, H3 is real (plan Stage C) |
| H4 | **Font loading starts mid-slide and keeps growing.** `_fonts.prefetch(page)` runs in `_onPageChanged` (mid-slide) for page ± 2, each font is a 66-388 KB TTF (median 285 KB) read through the asset channel and registered on the UI isolate, and nothing is ever unloaded (all 604 would be 152 MB). | `reader_screen.dart:346-348`, `page_font_loader.dart:19-45`; fonts in `assets/fonts/qpc-v2/`. | In the test VM a cold font costs 4.5-5.5 ms to read and 0.5 ms to register; 5 fonts after a jump take 9-13 ms in total. Small. The retained memory (about 285 KB per page read) is not measured. | **Low** for lag, **medium** for memory on a weak phone | `dumpsys meminfo app.hafiz.mushaf` before and after 200 pages; the frame trace around the moment `prefetch` runs |
| H5 | **Page data is read twice per page and parsed on the UI isolate.** `loadPage` reads the page file and `_endMarkers` reads and decodes the next page's whole file to learn its first word; the next page's own load reads it again. Nothing prefetches page data, so the first read of a neighbour is in the slide. | `mushaf_repository.dart:26-47`, `:58-93`. | 2.00 asset reads per page (1 needed); `jsonDecode` 0.2 ms and `PageData.fromJson` 0.05 ms per page (3.4 MB of JSON in all, 138.5 words per page); `loadPage` cold 2.4 ms, warm 0.1 ms. Pages are under 8 KB, so the framework decodes them on the UI isolate without an isolate hop. | **Low** (about 2 to 3 ms); worth doing only because the neighbour must be ready (D2) | `PAGEWARM` trace; not worth a frame-level confirmation |
| H6 | **A page is a heavy widget tree.** One `Text` and one `GestureDetector` per word (about 94 of each per page) and a `LayoutBuilder` + `InteractiveViewer` + `FutureBuilder` around it; this multiplies H1 and H2. | `mushaf_page.dart:183-210`, `page_viewport.dart:156-189`. | 637 elements per page on average (about 900 for a full page). | **Medium** as a multiplier, **low** on its own | Rebuild counts are already the proof; a thinner page only if the phone still misses SC-001 after Stage A (D12) |
| H7 | **First draw of a page in a new font family is slow on the raster thread** (glyph cache or atlas for a new typeface). | Nothing in the code; it follows from loading a new font family per page. | Not measurable here (tests do not rasterize). | **Unknown** | Frame trace `raster` column: a raster spike on the first frames of the incoming page, `dumpsys gfxinfo` GPU columns, Impeller on or off (`adb logcat | grep -i impeller`) |
| H8 | **The slide itself feels heavy**: `PageScrollPhysics` uses Flutter's standard spring (0.5 kg, stiffness 100, damping ratio 1.1), which takes about half a second to come to rest after the finger lifts. | `reader_screen.dart:404-406` (default physics). | n/a | **Low**; a feeling, not a stutter | Owner's answer to question 2 of quickstart; only tuned if frames are clean and the feel is still «ثقيل» (D10) |

Ranking for the plan: **H1 and H2 together are most of the lag** (every swipe pays H2 at its start and H1 in its middle, wird
mode pays H1 again), **H3** follows in wird mode, **H5** is a small part of making H2 go away, **H4** and **H7** need the
phone, **H6** and **H8** are last resorts. This is a reading of the code and of counts; the plan therefore builds Stage A
(H1, H2, H5), measures on the phone, and builds Stage C (H3, H4, H6, H7, H8) only for what the numbers still show.

## D2. Make the neighbours ready at rest (fixes H2, part of H5)

**Decision**: `PageView.builder(allowImplicitScrolling: true, scrollCacheExtent: ScrollCacheExtent.pixels(1))`. At rest the
pager builds the shown page and both neighbours; the page after a neighbour is built only at the very end of a slide.

**Spike S1** (`test/motion/pager_prewarm_spike_test.dart`, kept as a regression test of the framework's behaviour), a
`PageView.builder(reverse: true)` of 604 items inside `Directionality(ltr)`, started on index 50:

| | Without (today) | With `allowImplicitScrolling` + 1 px cache |
|---|---|---|
| Built at rest | {50} | {49, 50, 51} |
| Built after the first 40 px of a swipe | {50, 51}: the neighbour is built in the slide | {} (nothing new) |
| Built after 390 of 400 px | n/a | {} |
| Built after the slide settled | n/a | {52}: the next neighbour appears at the very end |
| `find.byKey(...)` for a neighbour | found while sliding | **`findsNothing` at rest: neighbours outside the screen are offstage for finders**, so the tests that expect one page number keep passing |

A cache of one viewport (the default of `allowImplicitScrolling: true`) would build the page after the neighbour at the
first pixel of the next swipe, which only moves the hitch; 1 px does not. The cost left is one page build at the end of each
slide (D3 removes its sibling rebuilds), in a frame where nothing else moves. `allowImplicitScrolling` also keeps the
neighbours in the semantics tree, which helps a screen-reader user who swipes to the next page.

**Also**: `_PageItemState` takes the page synchronously when it can (data in the repository cache and font loaded: no
`FutureBuilder` round trip, no page-number-only first frame); `MushafRepository` gets `peek(page)` for that and a
`prefetch(page)`; the loading card stays for a page that is not ready (jump).

**Alternatives rejected**: `cacheExtent` of a viewport (above); a hand-made offstage `Stack` of three pages (re-implements
the pager); pre-rendering to an image (the page is text, a picture would not be the Mushaf page and would break the long
press); a bigger window (memory, and the build of N+2 lands at the start of the next swipe).

## D3. Stop rebuilding what did not change (fixes H1)

**Decision**, in this order, each a task with a failing test first:

1. `_PageItemState` keeps the `MushafPageCard` it built and builds a new one only when one of its inputs changes (data,
   font family, look, reading size, highlighted ids, meta, or the callbacks compared with `==`); `PageViewport` gets the same
   instance, so Flutter skips the subtree (M3: 0 builds, 0.4-0.6 ms per ignored rebuild). This alone removes the three
   causes of H1 (mid-slide notify, database answers, bar taps) because it does not matter who rebuilds the screen.
2. The screen stops rebuilding itself as a whole: the bars, the today card and the pager each get a narrow listener
   (`ListenableBuilder` on the controller only where the page number or wird name is shown; the pager reads
   `_locks`/`_highlight` through small notifiers), so a notification rebuilds a bar, not the `Scaffold`. The controller keeps
   its single `ChangeNotifier`; `pageBookmarked` already shows the pattern (feature 006).
3. `ReaderController` gets `pageSeen(page)` (notify only) and `savePosition()` (the writes), and `onPageShown(page)` stays and
   does both, so feature 005 and the controller tests are unchanged. **Stage A keeps calling `onPageShown` from
   `_onPageChanged`** (the position is written exactly when it is today); the split exists so that Stage C (D5) can call
   `pageSeen` and leave the write to the saver.

**Test-first guards**: `test/motion/reader_rebuild_budget_test.dart` asserts what M4 prints: per turn at most 1 `MushafPage`
build in browse mode and in wird mode, 0 for a bar tap, a panel toggle, a bookmark tap and a database answer, and at most 1
whole-screen rebuild. It is written red against today's code and made green by D3.

**Alternatives rejected**: `const` pages (the data differs per page); `RepaintBoundary` around the bars (paint is not the
problem, build is); moving the page into a `StatefulBuilder` (the same as item 1, less clear); `AutomaticKeepAlive`
(keeps state, does not stop rebuilds).

## D4. Load in the background, never in the slide (fixes H4, H5)

**Decision**: `MushafRepository.prefetch(page)` loads and parses a page that nobody asked for (data and end markers, one
read: the memo of first words from the page that was just read), and `PageFontLoader.prefetch` keeps ± 2 but runs from a
`ScrollEndNotification` / after the slide settles (`_onPagerScroll` already sees it), nearest page first, in the direction the
reader is turning. A jump loads the shown page first and its neighbours after the first frame. The end-marker read of the next
page is replaced by the memo (page N's first word is known once page N was prefetched), which removes the second read per page
(M1b: 2.00 reads per page, 1 needed). No isolates: pages are under 8 KB (0.25 ms to parse), so `compute` would cost more than
the work.

**Not done**: unloading fonts (the engine has no unload for `FontLoader` families; the plan records the memory as a watch item,
D9 measures it).

## D5. Saving the position (H3), conditional

**Decision (Stage C, only if the wird-mode run still misses SC-001 after Stage A)**: `PositionSaver` (pure, in
`lib/mushaf/position_saver.dart`) holds the last page and a 400 ms timer; `flush()` writes at once. The reader calls `flush()`
when the app is paused/inactive/detached, before any route is pushed from the reader, on `dispose`, and when a jump happens.
`ReaderController.onPageShown` stays as it is for callers that want an immediate write (feature 005's «آمين»). With the saver,
a burst of ten page turns writes twice instead of twenty times and the two streams answer once.

**Why conditional**: after D3 the answers of the database rebuild only the top bar (the wird name and the today chip), which is
cheap; the saver adds a rule about when the position is on disk, which touches Constitution VII, so it is added only for a
measured reason. If it is added, existing tests that read `currentPage` after `settle` (about 1 s of test time) still pass with
a 400 ms delay; the ones that read it earlier must be checked (tasks T060).

## D6. The motion itself

Tokens and widgets are in contracts/ui.md. Decisions behind them:

- **Bars**: `AnimatedSwitcher` (so the old bar leaves the tree when its fade ends, which the existing test «tapping the page
  toggles the top and bottom bars» needs: it pumps 300 ms and then expects `findsNothing`) with a fade + slide
  `transitionBuilder`, inside the existing fixed 84 dp and 68 dp `SizedBox` slots, so nothing around the page moves. The
  outgoing bar is wrapped in `IgnorePointer` while it leaves. Durations 200 in / 160 out, `easeOutCubic` / `easeInCubic`.
- **Today card**: the card and its modal barrier are separate: the barrier follows `_panelOpen` immediately; the card is an
  `AnimatedSwitcher` child with the same fade + 12 dp slide, 220 in / 160 out.
- **Jump arrival**: a small `JumpFade` widget around the pager area owns one `AnimationController` (the only place besides
  the look host where a controller is used; created with `Duration.zero` under «remove animations»); `_syncPager` calls
  `jumpToPage` and then `play()`, which fades the pager area from 0.35 to 1.0 over 180 ms with `easeOut`. It is a fade-in of
  the new page, not a true cross-fade: a true cross-fade needs the old page's picture (`RepaintBoundary.toImage`, one
  full-screen capture) and is not worth it for a 180 ms arrival; if the owner wants it, it reuses the look host's snapshot
  (T035). The opacity layer lasts only while the fade runs.
- **Icon and wird name**: `FadeInOnChange` (a small stateful widget with one controller): the child is replaced at once and
  fades in (the icon also grows from 0.8), 160 ms, `easeOut`. It is **not** an `AnimatedSwitcher`: that keeps the old child in
  the tree for the whole fade, and the feature 006 tests expect exactly one bookmark icon right after a tap
  (`find.byIcon(...)` `findsNothing` for the other state, `test/bookmarks/bookmark_button_test.dart`). The icon's semantics node
  of feature 006 sits outside it and is unchanged.
- **Look switch**: a snapshot cross-fade owned by `MushafApp`, because `AppLook.lerp` is deliberately a hard switch at 0.5
  (`theme.dart:365-369`, feature 004) and `themeAnimationDuration` would flip the shapes in the middle. `LookTile` asks
  `AppLookSettings` for the switch; a `RepaintBoundary` above the app's `home` gives the old image, the theme changes at once
  under it, and the image fades out in 220 ms. Instant with «remove animations» on and in tests that do not ask for it.
- **Edge turn**: stays `animateToPage(300 ms, easeOutCubic)` and becomes `jumpToPage` under «remove animations» (D7).

All motion is implicit or owned by the widget that moves; no new package; no `Ticker` outside those widgets.

## D7. «Remove animations» (measured)

`test/motion/reduce_motion_probe_test.dart` sets the accessibility feature and counts the frames each motion needs.

| Motion | Animations on | «Remove animations» on |
|---|---|---|
| Route push / pop (`PageRouteBuilder` default) | 19 / 19 frames | 1 / 1 |
| Modal bottom sheet open / close | 16 / 13 | 1 / 1 |
| Dialog open / close | 10 / 10 | 1 / 1 |
| Snack bar in / out | 16 / 16 | 1 / 1 |
| `AnimatedOpacity` 200 ms (any implicit animation, any `AnimationController` with the default behaviour) | 13 | 1 |
| **`PageController.animateToPage` 300 ms** | 20 | **20 (unchanged)** |

So the framework already honours the setting for everything the app builds from implicit animations, routes, sheets, dialogs
and snack bars (its controllers shorten themselves to 5% of their duration); the only motion that ignores it is the scroll
activity of `animateToPage`, which is the reader's edge turn. Decision: `Motion.of(context)` returns the durations of
contracts/ui.md, or `Duration.zero` where `MediaQuery.disableAnimationsOf(context)` is true; custom controllers are given
`Duration.zero` explicitly (never rely on the 5%); `_onEdgeTurn` uses `jumpToPage` when it is true. The pager's own drag and
its spring after the finger lifts stay (they are the reader's own movement). A widget test per motion flips
`accessibilityFeaturesTestValue` (T004, T020, T030, T031, T041).

## D8. Measurements that exist before any fix (test-time)

All in `test/motion/`, print-only with generous bounds; support in `test/support/motion_probe.dart` and `motion_harness.dart`.

| Test | Measures | Numbers (three runs) |
|---|---|---|
| `page_data_cost_test.dart` M1 | JSON parse of all 604 pages; `loadPage` cold and warm; asset reads per page | decode 0.20 ms mean (p95 0.4), `fromJson` 0.05 ms; `loadPage` cold 2.4 ms mean, warm 0.1 ms; **2.00 reads per page**; 83,668 words, 138.5 per page, 3.4 MB |
| `page_font_cost_test.dart` M2 | font sizes; `ensure` cold; `FontLoader.load` alone; 5 fonts after a jump | 66-388 KB, median 285 KB, 152 MB in all; `ensure` 4.5-5.5 ms mean; register alone 0.5 ms; 5 fonts 9-13 ms |
| `page_build_cost_test.dart` M3 | elements per page; first build; build again; rebuild with nothing changed; relayout; what-if with the same widget instance | 637 elements, 96 `Text`, 94 `GestureDetector`, 96 paragraphs (mean of 6 pages incl. the two short ones); first build median 51-68 ms (max 214-286); build again 37-39; **rebuild with nothing changed 10-12 ms (0.26-0.31 of a build)**; relayout 10-11; **same instance: 0.4-0.6 ms and 0 builds** |
| `reader_rebuild_count_test.dart` M4a | rebuilds per swipe by frame, browse and wird mode, database answering after 8 ms of test time (`DelayedDatabase`) | browse: 1 whole-screen rebuild, 3 `MushafPage` builds (frames 1 and 2), 377-436 `Text`; wird: 2 whole-screen rebuilds in two frames, 5 builds (frames 1, 2, 4), 633-722 `Text`; slowest frames (test VM) 66-142 ms at frames 1 and 2, 48-71 ms at frame 4 |
| same, M4b | bar taps | per tap: 1 `MushafPage`, 147-156 `Text`, 500-658 element rebuilds |
| `reduce_motion_probe_test.dart` M5 | D7 table | above |
| `pager_prewarm_spike_test.dart` S1 | D2 table | above |

Without the delay the in-memory database answers inside the same frame and the rebuilds of one turn fold into one (browse:
1 whole-screen rebuild, wird: 1 with `ReaderScreen` set-state); on the phone the answers arrive a few frames later, as the
delayed run shows. The tests are the **before** numbers: when a fix lands, its task tightens the bound in the same file (for
example `lessThan(30)` whole-screen rebuilds becomes `lessThanOrEqualTo(1)` per turn).

**After Stage A** (T010 to T013, printed by the same tests, 2026-11-21; `Scaffold` rebuilds are the whole-screen measure now
that the outer `ListenableBuilder` is gone, T011):

| Test | After |
|---|---|
| `reader_rebuild_count_test.dart` M4a, browse mode, per turn (three turns) | **0** `Scaffold`/`PageView` rebuilds, **1** `MushafPage` build (before: 3), in frame 43 of 44 (the end of the slide, the new neighbour), 0 in the finger-down, dragging and past-the-middle frames (`reader_neighbours_ready_test.dart`); 127-157 `Text` rebuilds (before: 377-436); `_BottomBar` 0 |
| same, wird mode, per turn | 1 `Scaffold` rebuild in 1 frame (the database answer after the turn, before: 2), **1** `MushafPage` build (before: 5), at the end of the slide; 134-164 `Text`; `PageView` 0, `_BottomBar` 0 |
| same, M4b, per bar tap | 0 `MushafPage`, 0 `PageView`; 29 element rebuilds for a hide tap and 190 for a show tap (before: 500-658 and 1 page build) |
| at rest | 3 `MushafPage` built (the shown page and both neighbours, with their text, no page-number-only card), 1 page number found by finders, the neighbours not in the semantics tree |

Frame times in the test VM are not the phone's: the longest frame of a turn moved from the first frames of the slide (66-142 ms
before) to the last frame (52-106 ms, one page build with nothing else moving); the phone's `FRAMETRACE` decides (T016).

## D9. Measuring on the phone (never now; with the owner's approval in that session)

**Standing rules** (features 003 to 006): the phone is the owner's <phone>; never unlock it; ask before sending any input
or installing anything; nothing in the phone's settings is changed to measure; browse mode keeps the wird still (jump from the
index first); for a wird-mode run use `--and-back` so the position ends where it started, or have the owner export a backup
first.

**What to read, and why not only `gfxinfo`.** Flutter draws into its own surface, so `dumpsys gfxinfo app.hafiz.mushaf
framestats` may hold few or no frames for it (it counts frames of the Android view hierarchy). The owner's brief asked for it
and it is in the script as a cross-check, but the primary number is the app's own `FrameTiming` through a **FRAME_TRACE** build
option (T002): `FRAMETRACE build=<ms> raster=<ms> total=<ms>` per frame plus `FRAMETRACE refresh=<hz>`, free in normal builds
like `PAGE_TURN_TRACE` and `AYAH_MENU_TRACE`. `PAGE_TURN_TRACE` gains one line at the start of each swipe, `PAGEWARM
next=<bool> prev=<bool>`, telling whether the neighbours were ready (SC-002).

**Procedure** (`specs/010-smooth-motion/phone/measure.sh`, which refuses to run without `--approved-by-owner`):

1. Owner approves, unlocks the phone, opens the reader on a Mushaf page in the mode to measure.
2. `flutter build apk --release --dart-define=FRAME_TRACE=true --dart-define=PAGE_TURN_TRACE=true` (release, the same as the
   earlier phone checks; a profile build with `flutter run --profile` is the alternative when the timeline is needed, and shows
   widget rebuilds in DevTools). Install with `adb -s <phone> install -r` (data kept), **only with approval**.
3. Record the device: model, Android, `wm size`, and the refresh rate in use (`dumpsys display | grep -i refreshRate`; adaptive displays may change it, so the frame trace's own `refresh=` line and the median vsync interval are what count). The
   budget is `1000 / refresh` ms.
4. `measure.sh --approved-by-owner --label before --pace slow|normal|fast --swipes 50` three times (slow: 1.2 s of rest between
   swipes; normal 0.6 s; fast 0.25 s), each in browse mode, then again in wird mode with `--and-back`. Swipes are `adb shell
   input swipe x1 y x2 y 110` from 15% to 85% of the width (left to right brings the next page).
5. `summarise.py` prints count, mean, p50, p90, p95, p99, max, the share within the budget and the count over 100 ms for the
   total, build and raster times, and PASS or FAIL against SC-001; `PAGETURN` min, median, max; `PAGEWARM` ready share.
6. Memory (H4): `adb shell dumpsys meminfo app.hafiz.mushaf` before and after 200 swipes.
7. Repeat the whole set after each stage with `--label after-A` etc. and compare the files in `phone/results/`.

**Acceptance numbers** (proposal, the owner may change them): over 50 swipes per pace and mode, at least 95% of frames within the
frame budget of the phone's refresh rate, none over 100 ms, p99 at most twice the budget, `PAGETURN` at most 300 ms every time
and `PAGEWARM ready=true` in at least 98% of the normal-pace swipes; the bar and card animations never cost a frame over 33 ms.
If the phone runs adaptively and the budget comes out at 60 Hz or lower while swiping, the stricter budget of the display's
maximum rate is reported too, not used for the verdict.

**What a failed number points at**: long `build` at the start of the slide → H2 (the neighbour was not ready, see `PAGEWARM`);
long `build` in the middle or end → H1/H3; long `raster` on the first frames of a new page → H7; long frames only in wird mode →
H3; frames fine but the owner still says «ثقيل» → H8.

## D10. The slide's feel

Not changed in Stage A. If the frames are clean and the feel is still heavy, the option is a `PageScrollPhysics` subclass with
a stiffer spring (stiffness 160, damping ratio 1.1, about 350 ms to rest), applied to the reader's pager only; edge turn stays
300 ms. It is the owner's feel to judge, so it waits for question 2.

## D11. Look switch, details

Feature 004 chose an instant switch (`themeAnimationDuration: Duration.zero`, `AppLook.lerp` flips at 0.5) because the two
looks differ in shape (pill bar, round add button, dot markers), so interpolating the theme shows neither look. The snapshot
cross-fade of D6 leaves that rule true (the theme never interpolates) and adds only an overlay for 220 ms. It is the most
invasive motion (it wraps `MaterialApp`'s child and touches `look_tile.dart`/`look_settings.dart`), so it is the last task
before the phone check and can be dropped without affecting anything else (the owner's question 3).

## D12. A thinner page, only if the phone still misses SC-001

If Stage A and C leave frames over budget and `build` is the column that is long, the next step is to cut the page's element
count: one long-press recognizer per page instead of one `GestureDetector` per word (the word is found from the long-press
position by its key's render box, so every `ValueKey('w<id>')` stays and the tests that long-press a word keep working), and
no per-word `Semantics`. It touches `mushaf_page.dart`, which Constitution I protects, so it needs the geometry baselines of
004 and 006 (equal line and word boxes, 604 pages) green before and after, and is a separate decision.

## D13. Coordination and risks

- `lib/mushaf/reader_screen.dart` is edited by features 005, 006, 007 and others; most tasks that touch it are marked in
  tasks.md ("**reader_screen.dart**") so the coordinator can schedule them after those. Tasks that add new files only (the
  `Motion` tokens, `FrameTrace`, `JumpFade`, `PositionSaver`, the `MushafRepository`/`PageFontLoader`/`ReaderController`
  additions) can be done any time.
- Existing tests that look at what a page turn or a bar tap leaves behind must stay green unchanged: the ones that find one
  page number (S1b shows neighbours are offstage), the one that taps the page and expects the bars gone after 300 ms (D6
  uses `AnimatedSwitcher`, gone after 200 ms), the ones that read `currentPage` after `settle` (D5, only if Stage C), and the
  geometry baselines of 003, 004 and 006.
- **Correction found while building (T021, T012):** two claims above were wrong. (1) A tap on the page followed by one
  `pump(300)` does NOT find the bars gone with an animated switcher: the fade starts in the build frame, so after a single
  300 ms pump the bars are still in the tree. The reader therefore also starts a short timer (`barOut` + 20 ms) that makes the
  two slots start again empty after the fade, so the earlier reader tests stay green unedited; on a device the fade has ended
  by then and nothing visible changes. (2) Three pages alive at rest do change one earlier test:
  `test/mushaf/reset_text_size_test.dart` read the size of "the" `MushafPageCard` under Settings with `skipOffstage: false`
  and now finds the shown page and its two neighbours. Its line was changed to check that every card there is at 100%
  (the same point), the only edit of an earlier feature's test in this feature; spec FR-016 allows it only for this
  consequence of FR-002 (neighbours built at rest).
- Risk: three pages alive at rest means three times the memory of page widgets and, until D3 is in, three times the work of
  every whole-screen rebuild. D3 item 1 must therefore land before or with D2.
- Risk: `allowImplicitScrolling` changes semantics (neighbour pages are reachable by a screen reader's scroll action); this is
  intended and checked on the phone with TalkBack (quickstart).
- The test numbers are before-numbers of the code at the commit of this research; they are not a promise about the phone.
