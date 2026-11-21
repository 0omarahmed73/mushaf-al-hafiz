# Research: Khatm Dua After the Last Page (feature 005)

All decisions below were made while planning, on 2026-11-20, after reading `lib/mushaf/reader_screen.dart`,
`reader_controller.dart`, `page_viewport.dart`, `page_scale.dart`, `lib/ayah/ui/sheet_detail.dart`,
`reading_text.dart`, `lib/settings/about_screen.dart`, `docs/research/licenses.md` and `pubspec.yaml`, and after a
throw-away spike (D1). Nothing here needs the owner's answer except the wording (D8), which is a task.

## D1. How the forward swipe at the last page is detected

**Spike** (throw-away widget test, deleted afterwards): a `PageView.builder(reverse: true, physics:
PageScrollPhysics())` of three pages inside `Directionality(ltr)`, started on the last page, with a
`NotificationListener<ScrollNotification>` above it. A finger moving left to right (+dx) is the forward direction
(the next page comes in from the left, Constitution VI).

| Gesture on the last page | Notifications | Cumulative `overscroll` | `ScrollEndNotification.dragDetails.velocity.dx` |
|---|---|---|---|
| slow drag, 12 moves of 10 px, then still | Start, 12 × `OverscrollNotification` (+10 each), End | +120 | 0 |
| fling (200 px at 1500 px/s) | Start, 50 × `OverscrollNotification` (+4 each), End | +200 | +1500 |
| tiny drag, 2 moves of 10 px | Start, 2 × `OverscrollNotification`, End | +20 | 0 |
| drag the other way (toward the previous page) | normal `ScrollUpdateNotification`s, springs back | 0 | n/a |

What this shows: with this physics the pager is **clamped** at the last page (`pixels` stays at
`maxScrollExtent`), forward movement arrives as positive `OverscrollNotification.overscroll` while the finger is
down (there is no ballistic phase at the boundary), and the release speed is on the end notification.

**Decision**: wrap the `PageView` in a `NotificationListener<ScrollNotification>` that
- ignores everything but the pager's own horizontal notifications (`notification.depth == 0`, `metrics.axis ==
  Axis.horizontal`), so the vertical scroll inside a landscape page and the zoom of `InteractiveViewer` never count;
- on `ScrollStartNotification` starts a new gesture; on `OverscrollNotification` with `overscroll > 0` adds it to
  the gesture's forward distance (a negative one is the other end of the Mushaf, page 1, and is ignored);
- on `ScrollEndNotification` asks the pure rule (D2) whether to open the dua, passing the release velocity.

Opening on release, not in the middle of the drag, keeps the finger-down gesture from fighting a route push.

**Why this meets FR-001, FR-002, FR-004**: only the last page can overscroll forward, so pages 1 to 603 can never
trigger it; a zoomed or wide page has its pager locked (`NeverScrollableScrollPhysics`, reader `_locks`), so it
produces no notification at all; a jump to page 604 moves the pager by `jumpToPage`, which is not a drag.

**Second path (wide page).** When the text size makes the page wider than the screen (feature 003, `PageFit.
pansBothWays`) the pager is locked and a swipe that starts at a side edge turns the page through
`PageViewport.onEdgeTurn` → reader `_onEdgeTurn(PageTurn.next)`. On page 604 that call returns early today
(`target >= pageCount`). That early return is the second place the dua opens from: `PageTurn.next` on the last
index. The viewport already refuses the edge turn when the page is zoomed, when a second finger touched, or when
the drag started zoomed, so FR-004 holds there too, and `edgeTurn()` already encodes "a gesture that would have
completed a page turn".

**Alternatives rejected**
- A custom `ScrollPhysics` subclass: it would replace the physics the reader already switches between locked and
  free and would touch more of `reader_screen.dart` for no gain.
- A `GestureDetector`/`Listener` on page 604 only: it competes with the pager and the `InteractiveViewer` in the
  gesture arena and must rebuild the distance and speed rules the pager already has.
- Reading `ScrollUpdateNotification.pixels` beyond the extent: this physics never moves beyond the extent, so
  nothing is reported there.

## D2. The pure rule

`LastPageSwipe` in `lib/khatm/last_page_swipe.dart`, no Flutter imports, unit-tested first.

- `start()` resets the gesture's forward distance.
- `overscroll(double delta)` adds `delta` when it is positive.
- `end({required double velocity})` returns true when the gesture opens the dua and resets the distance:
  `distance >= minDistance (48)` or `distance >= minFlingDistance (16) && velocity >= minFlingVelocity (300)`
  (logical pixels, pixels per second; `velocity` is positive when the finger moved forward).
- The "already open" guard lives in the reader (`_duaOpen`), not in the rule, so the rule stays a function of the
  gesture only.

Why these numbers: the spike shows a slow deliberate drag is at least 100 px and a flick is at least 100 px at over
1,000 px/s, while an accidental brush is a few pixels; 48 px is the app's touch-target size, 16 px is about the touch
slop, 300 px/s is far below a flick (1,500) and far above a resting finger (0). They are constants in one place and
are tuned on the phone in the real-device check (a task), not guessed twice.

## D3. The screen

`KhatmDuaScreen` in `lib/khatm/khatm_dua_screen.dart`, a full-screen `MaterialPageRoute` pushed from the reader
(like `WirdsScreen` and `IndexScreen`, so Constitution II holds: reached only from the Mushaf, returns to it). It
returns `true` for «آمين» and nothing for back.

- `Scaffold` + `AppBar(title: Text('دعاء ختم القرآن'))`: the AppBar's own back arrow (tooltip «رجوع» from the Arabic
  Material localisations) and title are already a button and a heading for a screen reader, and the system back
  gesture pops the route.
- Body: a `Scrollbar` over a `SingleChildScrollView` inside `ReadingScope` (feature 003) with, in order, the label
  «دعاء وليس من نص القرآن» (12 px, `look.textSecondary`, the style of `kHumanWorkNote`), the dua in one panel
  (`look.cardFill`, `look.cardBorderStrong`, `look.rowRadius(14)`, text `look.cardInk`, the style
  `ReadingScope.of(context).arabic`), and «آمين» (a `FilledButton`, key `khatm-amen`, at least 52 px high, full width)
  as the last item (FR-011).
- The dua text uses the theme's interface font (Cairo) because `ReadingStyles` sets no `fontFamily`: the Quran
  font is only ever set by `MushafPage`. A test asserts the dua `TextStyle` has no Quran family.
- Colours come only from `context.look`, so both looks work with no per-look code (Feature 004's Foundation is
  committed). The AppBar and Scaffold follow the theme.
- `ReadingStyles.arabic` is reused as it is (17 px × the owner's size, line height 1.8), so feature 003's file is
  not edited.

**Alternative rejected**: a bottom sheet like the ayah menu. A full route has a real back stack and system back
behaviour, survives rotation without extra code, and the dua is read once, at length, not glanced at.

## D4. The data

- One asset `assets/khatm/dua.txt`: UTF-8, paragraphs separated by one blank line, no title, no markup, a final
  newline. `pubspec.yaml` gets one line `- assets/khatm/dua.txt`.
- `DuaText.parse(String)` splits on blank lines and drops the final newline, nothing else; the paragraphs joined by
  a blank line equal the file's text (byte-for-byte test). `DuaText.load(AssetBundle)` reads the asset and throws
  `DuaUnavailable` on any error.
- The screen reads it with `DefaultAssetBundle.of(context)` in a `FutureBuilder`, so a test replaces the bundle.
  On `DuaUnavailable` it shows `kDuaUnavailable` = «تعذّر تحميل نص الدعاء» (proposal, Constitution VI) instead of
  the panel, with «آمين» and back still working (FR-019).
- The strings live in `lib/khatm/dua_strings.dart` (title, label, «آمين», the unavailable message, the About credit
  sentence) so the owner's confirmation touches one file.
- No database table, no setting, nothing in the backup (the dua has no data of its own, spec edge case).

## D5. What «آمين» and back do in the reader

- «آمين»: `Navigator.pop(context, true)`; the reader then calls `_controller.onPageShown(1)`. That is the ordinary
  page change (spec FR-006): with a wird the wird's position becomes 1 exactly as a swipe to page 1 would, in browse
  mode only the last viewed page does. The controller notifies, `_syncPager` sees that the pager shows index 603 and
  the controller says page 1 and calls `jumpToPage(0)`, which does not build the 602 pages between (a `PageView.builder`
  builds only the visible and cached pages) and fires `onPageChanged(0)`, which calls `onPageShown(1)` again
  (idempotent). No new controller method is added.
- Back: the route pops with no result, the reader does nothing, the pager is still on index 603 and the saved
  position is untouched (FR-007). A new forward gesture opens the dua again.
- Only once: the reader keeps `_duaOpen`, set before the push and cleared after it returns, so a second gesture
  during the push or while the dua is open opens nothing (FR-003).
- Rotation and the app going to the background keep the route (a route is part of the navigator). A restart
  rebuilds the reader from the saved position, which is page 604 or page 1 (FR-014).
- The dua writes nothing: no khatma, portion, bookmark, reminder or setting is touched (FR-008); the only stored
  change is the page change above.

## D6. Licence and About

`docs/research/licenses.md` gets a section «Feature 005 (khatm dua)»: the wording is customary text with no fixed
source; it was found on mawdoo3.com «دعاء ختم القرآن» (updated 2024-08-06) and albayan.ae (2024-04-08), read on
2026-11-20; neither gives a book, a narrator or a grading and neither ties it to the Madinah Mushaf; both say there is
no fixed text from the Prophet ﷺ; it is a short traditional supplication, not a copyrighted work of those sites, and
no text of theirs other than the supplication itself is used. The owner confirms the wording and this entry (D8).
`about_screen.dart` gets one more tuple in `credits` (name, use, note), the proposal being:
(«دعاء ختم القرآن», «الدعاء المتعارف عليه في ختام المصاحف»,
«لا يوجد نص ثابت عن النبي ﷺ؛ الصياغة متداولة، وُجدت على موقعي موضوع والبيان»). A test checks the credit.
**Update 2026-11-21:** the owner chose the shorter sentence without the names of the sites, because their confirmed
wording is longer than the customary opening those sites show (D8).
No other resource is added.

## D7. Coordination with feature 004

`reader_screen.dart` and `about_screen.dart` are also edited by feature 004 (reader colours and bar in its Phase 7,
About colours in its T015). This feature's edits are small and additive: in the reader one import, one
`NotificationListener` around the `PageView`, one handler, `_duaOpen`, one branch in `_onEdgeTurn`; in About one
tuple in `credits`. Rule for the tasks: run `git status` and `git log -- <file>` right before editing each file,
send the 004 session (`local_9648d7e1-a2ae-45f8-a103-a32be38e313a`) the exact lines by `SendMessage`, make the edit
in its own commit, and rebase nothing (one working tree, `main`). New code lives in the new `lib/khatm/` folder so
that most of the feature cannot collide.

## D8. The wording and the owner's confirmation

The proposal is in the spec's Assumptions (the core text opening «اللهم ارحمني بالقرآن …»). The research found no
fixed authentic text from the Prophet ﷺ and no source for this wording beyond its wide circulation. The task before
the feature is done shows the owner the exact text of `assets/khatm/dua.txt` and asks, in Egyptian Arabic: keep it as
it is, or add lines after «يا رب العالمين», or replace it; are the diacritics right; is the source line right. Until
the owner answers, the file holds the proposal and the feature is not called done (Constitution III, VI).

**Outcome, 2026-11-21:** the owner replaced the proposal with their own longer wording (eleven paragraphs), kept the
diacritics as written, shortened the credit sentence and approved the four strings. The text is kept exactly (FR-015),
including a few spelling and diacritic details of the source it was copied from (words joined to «ما» and «يا»,
a missing mark on a few letters, one double space). The sign ۞ is not in the Cairo font, so the phone shows it from
a system font (checked in T013). Where the added paragraphs come from is not named yet (licenses.md, Open).

## D9. Tests (test-first, new files only)

Earlier tests are not edited. New: `test/khatm/last_page_swipe_test.dart` (pure rule), `dua_text_test.dart`,
`khatm_dua_screen_test.dart` (both looks, three sizes, 320 dp with a 2x system font, contrast walk with
`test/support/contrast_walk.dart`, label, font, byte-for-byte text, unavailable fallback, «آمين» last in the scroll),
`reader_khatm_test.dart` (the reader on page 604 through `test/support/reader_harness.dart`: swipe opens; swipe on
603 turns; a jump to 604 does not open; a wide page's edge turn opens; zoomed does not; one screen for two flings;
«آمين» for a wird and for browse mode; back; khatma count, portions and bookmarks unchanged), `khatm_about_test.dart`.

## D10. Real-device check (Constitution IX)

On the owner's phone <phone> (never unlock it, ask before sending any input): the swipe on page 604 in both
looks, «آمين», back, rotation, a large font, a fling, tuning of D2's constants.

## D11. Performance and layout (SC-003, SC-007)

Opening is a route push of a screen with one text: well under a second. No page widget, font loading or layout code
is touched, so the layout tests (`page_layout_invariance_test.dart`, page card tests) stay green unchanged.
