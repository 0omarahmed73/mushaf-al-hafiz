# Research: Text Size (Font Size)

All decisions follow the owner's choices of 2026-11-20 (spec Clarifications). Numbers about the current code were
read from `lib/mushaf/mushaf_page.dart`, `lib/mushaf/reader_screen.dart` and the ayah views.

## D1. Where the size lives

**Decision**: `TextSizeSettings` (a `ChangeNotifier`, `lib/settings/text_size_settings.dart`) holds the chosen
percent. `main()` loads it before `runApp`, `MushafApp` provides it with `ListenableProvider<TextSizeSettings?>`
(`Provider` refuses Listenable values, as found in feature 002). It reads and writes through two methods of
`WirdRepository` using the key `textSizePercent`. The pure parsing lives in `lib/settings/text_size.dart`:
`TextSize.steps = [80, 90, ..., 150]`, `TextSize.defaultPercent = 100`, `TextSize.parse(String?)` returns an int
step: null or not a number → 100; outside 80..150 → 100 (FR-014); inside the range but not a step → the nearest step.
`factor = percent / 100`.

**Rationale**: the app keeps every setting in the key/value table, so the backup already exports it (the export
copies all rows; the import accepts any string value, see D6). A notifier lets Settings, the reader and the ayah
sheet react at once without a restart (FR-016).

**Alternatives**: storing as a double (invites 1.0000001 and float parsing issues); a drift column (schema
migration for one number); `shared_preferences` (a second store that the backup would not see).

## D2. Scaling the Mushaf page

**Decision**: do not change `MushafPage` or `MushafPageCard`. The reader lays the card out in a box of
`base x factor`, where `base` is today's box: the viewport in portrait, and in landscape
`min(width, 600) x 1.75 * thatWidth` (the numbers now in `_PageItem`). `MushafPage` already derives its font from
the box it gets (`fontSize = min(width / 16.2, lineHeight / 1.8)`), so the page grows or shrinks as a whole.
`lib/mushaf/page_scale.dart` computes the box and how it fits the viewport:

| Fit | When | Behaviour |
|---|---|---|
| `fits` | scaled box not larger than the viewport on both axes | centred, no scrolling (all sizes below 100% in portrait; the default in portrait) |
| `scrollsVertically` | wider-than-viewport is false, taller is true | vertical scroll, horizontal swipe turns the page (today's landscape page at 100%) |
| `pansBothWays` | scaled box wider than the viewport | pan up, down and sideways; swipe from the side edge turns the page (D3) |

The card's own paddings (12/4/3/10/6 px) and the 6 px page paddings are absolute, so a scaled page is not a pure
uniform magnification, but the text area always gets the new width and the font is derived from it, so the widest
line (16.15 em) still fits at every size. Line distribution cannot change: each line is a `Row` of its own words
from the page JSON with `spaceBetween` and no wrapping.

**Proof of SC-003** (test-first): (a) a data test over all 604 `pNNN.json`: for every step, the font size derived
from the scaled box times the measured widest line (16.15 em) does not exceed the text width, so no line overflows
(a pure check on `kMaxLineEm`; the 16.15 comes from the 604 fonts measured in feature 001); (b) a widget test with
the real fonts on pages 1, 2, 3, 293, 604 and the pages that hold the widest lines, at 80% and 150%: the lines
`line-1..line-15` hold the same word keys in the same order as at 100% and no layout exception is raised.

**Result (2026-11-20, dev machine)**: `flutter test test/mushaf/page_layout_invariance_test.dart --dart-define=FULL_LAYOUT_CHECK=true`
checked all 604 pages at all 8 sizes with the real fonts (4,832 layouts, 3 min 44 s): every line holds the same
words in the same order, no layout overflow, no word outside its line box. The default run checks pages 1-4,
600-604 and every sixth page at all 8 sizes (about 35 s).

**Alternatives**: `Transform.scale` of the 100% page (blurry or re-rasterised text at large scales, touch targets
and hit-testing differ, scroll extents need manual maths); scaling only the font size inside the old box (breaks
the justified lines: wider than the box); scaling `kMaxLineEm` (changes the default).

## D3. Pan, pinch zoom and the edge turn

**Decision**: option (a). `PageViewport` (new widget, `lib/mushaf/page_viewport.dart`) wraps the card per page:

- `fits` and `scrollsVertically`: exactly the structure that exists today (an `InteractiveViewer` around the page,
  and the vertical `SingleChildScrollView` for tall pages); the pager stays unlocked, horizontal swipes turn the
  page.
- `pansBothWays`: an `InteractiveViewer(constrained: false, boundaryMargin: EdgeInsets.zero)` whose child is the
  scaled box (at least the viewport on both axes). Pan is always on; the pager is locked (as it already is when
  zoomed). The view starts at the top and right side (reading starts at the right). When a one-finger drag ends,
  the pure function `edgeTurn` decides: if the gesture **started** with the page against a side edge, the finger
  then moved outward by at least 56 px (or flung faster than 700 px/s) and the move was more horizontal than
  vertical, the reader calls `nextPage` or `previousPage` (animated). Left edge + finger left→right = next page;
  right edge + finger right→left = previous page, as in the paper Mushaf (Constitution VI). A drag that merely
  runs into an edge stops there and never turns the page (spec edge case).
- Pinch zoom keeps its 1x–3x limit, now relative to the scaled page. While zoomed above 1.01 the pager stays
  locked and the edge turn is off, as today.
- Each page item owns its own `TransformationController` (today there is one shared controller reset on every page
  change). `PageView.builder` destroys pages that scroll out, so a page opened later starts fresh at its start
  position, and the incoming page during a turn animation shows its own start position instead of the outgoing
  page's offset. The reader keeps only "is the current page locked" (a small map keyed by page, filled by the
  viewports' callbacks) to set the pager's physics.

**Rationale**: it reuses the widget and the lock rule the reader already has, adds one pure function that is easy
to test, and does not fight the gesture arena: horizontal drags are either the pager's (unlocked) or ours
(locked), never both. Finger-following page drag at the edge is given up in exchange for a discrete, animated
turn, which is simple and predictable.

**Alternatives**: (b) nested horizontal and vertical `Scrollable`s with the overscroll forwarded to the
`PageController` (the framework does not chain drags to an outer scrollable; forwarding `OverscrollNotification`
by hand is fragile and differs per physics); (c) one continuous strip of pages with snapping (any rest position
between two pages is possible, the reading position and the wird bookkeeping become ambiguous, and it breaks the
paper-Mushaf paging feel).

**Tests**: unit tests for `pageBox` and `edgeTurn` (every table row, both directions, short drags, vertical-ish
drags, fast fling); widget tests in the reader harness: at 150% the page is bigger than the viewport, a drag moves
it and stops at the edges, a drag from the left edge to the right turns to the next page, a drag from the middle
does not, a long press still opens the menu, a tap toggles the bars, pinch zoom is limited to 1x..3x of the size,
landscape. **On the phone**: the pan feel, the edge turn without accidental turns, no jump of the incoming page,
a long press while panned (spec SC-009).

## D4. The three ayah texts and the preview

**Decision**: `lib/ayah/ui/reading_text.dart` holds `ReadingStyles` (the current styles of the panel texts:
tafsir paragraphs 17/1.8, translation 17/1.6, meanings word 18 bold and meaning 16/1.7, their source line 12) and
`ReadingScope`, which wraps the panel body of `SheetDetail`. `ReadingStyles` multiplies each `fontSize` by the
factor from `TextSizeSettings` (1.0 when the provider has none). The panel header (title, source, note) and the
sheet rows keep their size (FR-006). The system text scale still applies through `MediaQuery`; `ReadingScope`
clamps it so that `system x factor` never exceeds 3.0 (so a phone already at 2x with 150% is shown at 3x, not 3x
more). The Settings preview draws one Arabic paragraph and one English sentence with the same `ReadingStyles`
inside the same `ReadingScope`, so what is previewed is what the ayah menu shows. Sample sentences are plain
example text, never Quran text.

**Alternatives**: applying a `TextScaler` only (would also scale the section headers); a separate style set for
the preview (would drift from the real views).

## D5. Settings row

**Decision**: a card «حجم الخط» in `SettingsScreen` between the reminders and the backup sections: the title, the
current value as `NN%`, a `Slider(min: 80, max: 150, divisions: 7)` (RTL, so the larger sizes are to the left as
in every Arabic Material slider), `onChanged` updates the preview and saves at once (`TextSizeSettings.set`),
the preview panel, the note «يُطبَّق على التفسير والترجمة ومعاني الكلمات وعلى صفحة المصحف», and the button
«الحجم الافتراضي» (48 px high, disabled at 100%). The slider track has a mark at 100%. The whole card sits in the
existing scrolling list so the small-phone no-overflow test still passes. The slider thumb and the button meet
the 48 px target rule.

**Phone results (release build with `PAGE_TURN_TRACE`, owner's phone <phone>, 2026-11-20; driven with `adb input`
in browse mode, so the wird position stayed on page 2)**:
- The row sits between the reminders and the backup sections; the slider has its 8 stops, the thumb at 100% is at
  2/7 of the track from the right (RTL), the larger sizes are to the left, the «100%» mark is under it.
- Dragging the thumb to 150% and to 80%: the number and the preview (Arabic and English) change at once; at 100%
  «الحجم الافتراضي» is greyed, at any other size it is gold.
- Ayah menu on 3:5 at 150%: tafsir, translation and meanings texts are bigger, their headers («تفسير السعدي», «الترجمة»,
  «معاني الكلمات», the source lines) keep their size; the tafsir scrolls to its last line with room under it. At 80% the
  tafsir (3:13) shows more text and the header is unchanged.
- Not yet checked on the phone: translation and meanings at 80%, the longest tafsir (2:282 area), the size kept after
  closing the app, and the next row of quickstart section 2 that needs hands (see D7).

## D6. Backup

**Decision**: no change to the file format or its version. `exportJson` copies every settings row, so
`textSizePercent` travels automatically; `import` replaces all settings and accepts any string value (the parser
only checks that values are strings). A backup from before this feature has no key: after the import the value
is absent and `TextSizeSettings.reload()` gives 100%. A bad value (`"abc"`, `"999"`, `"-5"`) gives 100% through
`TextSize.parse` without failing the import. The reader already reloads after a restore (`_openSettings` pops
`true`); it also calls `TextSizeSettings.reload()` there.

## D7. Performance and memory

**Decision**: nothing to build; verify. The widget tree per page is the same, only larger; page fonts are
per page and already loaded before the page paints. At 150% the page is 2.25x the pixels. The page-turn trace
(`PAGE_TURN_TRACE`, feature 001 quickstart section 5) is read on the phone at 80%, 100% and 150% and recorded in
this file next to the 001 numbers (task in tasks.md). If the turn is slower than 300 ms at 150%, the fallback is
to cap the largest step.

**Phone results (same build and session)**: page-turn trace `PAGETURN page=N ms=T` (time from the page being created
until its text is painted; budget 300 ms, spec SC-006):

| Size | Turn | ms |
|---|---|---|
| 150% | edge swipe 50 → 51 | 48 |
| 150% | edge swipe 51 → 50 | 44 |
| 150% | jump to 604 | 26 |
| 80% | swipe 50 → 51 | 52 |
| 100% (after a reset) | 604 → 603 | 35 |

All turns are far under 300 ms, so the largest step stays 150% (the fallback of capping it is not needed).

Behaviour at 150% on the phone (portrait): pages 2, 50, 51 and 604 are 1.5 times bigger, show the same lines as at
100%, start at the top and the right side; a sideways drag in the middle moves the page and does not turn it; running
into the left edge turns nothing; a swipe left to right that starts at the left edge brings the next page (51), shown
at its top right with no jump; a swipe right to left that starts at the right edge brings the previous page (50);
on page 604 a swipe past the left edge does nothing and nothing breaks; a long press on a word opens the ayah menu
(3:5) and a tap hides the bars. At 80% the page is a smaller, centred card with all 15 lines and the page number,
and a plain swipe turns it.

Still to check by hand on the phone (they cannot be driven with `adb input` without changing system settings or a
two-finger gesture): pinch at 150% (1x to 3x, pager locked, back on pinch out), rotate at 80%, 100% and 150%, the
size kept after closing the app, the picture and the Al-Fatiha PDF shared at 150% (the render test already proves the
bytes equal 100%), export, change the size and import, airplane mode.

## D8. What must not change

- `MushafPageCard`, `MushafPage`, `PageLook`, `OffscreenPageRenderer`, the picture and the PDF never read
  `TextSizeSettings`; a test renders a picture and a print page with the setting at 150% in the tree and compares
  the bytes with 100% (SC-007).
- At 100% the reader is pixel-identical: the existing reader, landscape, ayah-sheet and settings tests pass
  unchanged (SC-008); no existing test file is edited except to add new ones.
- The About credits and `licenses.md` are not touched (FR-015).

**Deviations found by the convergence check (2026-11-20)**: the harness options for the setting live in
`test/support/ayah_harness.dart` (an optional `textSize`) and the new `test/support/reader_harness.dart`, not in a
`text_size_harness.dart` (T003); the offscreen renderer's API is `pdfPage` and `renderRgba`, which
`test/render/page_renderer_size_test.dart` compares at 80%, 100% and 150% (T015 says `printPage`); and
`flutter analyze` is clean for the whole project (the one note T020 mentioned was fixed by feature 004).

## D9. Arabic strings (confirmed by the owner on 2026-11-20)

See `contracts/ui.md`. They are not machine-translated English; the sample sentences are original short texts. The
owner approved all of them as written (title, value, note, «معاينة», «الحجم الافتراضي» and the two samples).
