# Feature Specification: Smooth Motion

**Feature Branch**: `010-smooth-motion` (work stays on `main`, as for features 001 to 009)

**Created**: 2026-11-21

**Status**: Draft (research and plan written with measurements taken on the development machine; the phone
measurements of research D9 wait for the owner's approval)

**Input**: Owner request (Egyptian Arabic, translated): "I want the splash to have a nice animation, and the movement
inside the app should also have animation and smoothness, because I noticed a lag (تعليق) while moving between
pages." The splash animation is feature 009 and is not covered here. This feature covers (a) finding and removing the
cause of the lag when the reader swipes between Mushaf pages and (b) soft, modest motion for the rest of the reader,
all of it honouring the phone's «remove animations» setting. Constitution 1.2.0.

## Clarifications

### Session 2026-11-21, owner's answers (in chat, after the research)

- Q: Where is the lag felt? → A: **At the start of the swipe.** This matches hypotheses H2 (the incoming page is built when the
  finger first moves) and H1 (the whole reader is rebuilt in the middle of the slide) of research.md D1; Stage A fixes those.
- Q: Does the look switch fade? → A: **Yes**, softly, about 220 ms; it may be dropped only if it proves fragile (T035).
- Q: Does a jump to a page (index, go-to-page, bookmark, another wird) fade in? → A: **Yes**, lightly, about 180 ms.
- Q: The bottom bar overflows at 320 dp (feature 006 T020). → A: **Not this feature's**; the owner wants it fixed as its own later
  feature.
- Q: May the phone be measured now? → A: **No**; no measurement, build or install is approved yet. The test-time numbers of
  research D8 are the only «before» numbers until the owner says so.
- Q: Delay the saving of the reading position (T060, T061)? → A: **Not now**; only if a later phone measurement asks for it. Stage
  A keeps writing the position exactly when it is written today.

### Session 2026-11-21 (proposed, the owner confirms; nothing here waited for an answer)

- Q: What does «lag while moving between pages» mean in numbers? → A: The reader sees a hitch when a page slides in or
  out: a frame that takes longer than the screen's frame time. The target is measured on the owner's phone over 50
  swipes: at least 95% of the frames within the frame time of the screen's refresh rate, none over 100 ms, and the
  incoming page showing its text from the first moment it is visible (SC-001, SC-002). The cause is not known until the
  phone is measured; research.md ranks the likely causes from the code and from measurements made on the development
  machine, and the plan fixes the strongest ones first and re-measures before touching the rest.
- Q: Is there a switch in Settings to turn the motion off? → A: No. The phone's own «remove animations» setting is the
  only switch (Android's accessibility choice, read by the app through the system). With it on, everything this feature
  adds happens in one frame. (Default recorded, not asked.)
- Q: How much motion is «modest»? → A: A fade and a slide of at most 24 dp, 160 to 220 ms, easing out when something
  appears and easing in when it leaves; no bounce, no spring, no scale below 96%, nothing that loops. Motion never moves
  the Mushaf page or changes its size (Constitution I). (Default recorded, not asked.)
- Q: What happens when the reader jumps to a page (index, go-to-page, bookmark, notification, a wird chosen in the
  wirds list)? → A: The new page fades in over 180 ms (from 35% opacity to full); the pager never slides through the pages
  in between (that would build hundreds of pages). (Proposed.)
- Q: Does the look switch (Emerald & Gold ↔ Night Reader) fade? → A: Yes, as a 220 ms cross-fade from the old look to
  the new one, started when the choice is tapped; the theme itself still changes at once (feature 004 FR-015 stays
  true: the colours are never interpolated, because the two looks differ in shapes as well). With «remove animations» on
  it is instant, as today. (Proposed; the owner may choose to keep it instant.)
- Q: Do sheets, dialogs and screens get their own motion? → A: They keep the framework's own transitions, which already
  move and which the system setting already shortens to one frame (measured, research D7); this feature only adds the
  motion that is missing or abrupt today (bars, today panel, jumps, the bookmark icon, the wird name, the look).
  (Proposed.)
- Q: May saving the reading position wait while the reader is turning pages? → A: Only if the phone numbers show the two
  writes per page turn still matter after the other fixes (plan Stage C). If it happens, the position is written at the
  latest 0.4 s after the last page turn, and at once when the app leaves the front, when another screen opens, and when
  the reader closes; it is never lost (Constitution VII). (Proposed, conditional.)
- Q: Who measures on the phone, and when? → A: Nobody until the owner says so in that session; the phone is never
  unlocked by the tool, input is sent only with approval, and a measurement build is installed only with approval
  (research D9, quickstart.md). (Standing rule of the earlier features.)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Turning a page never stutters (Priority: P1)

The reader holds the phone and turns pages with the thumb, one at a time while reading and fast when looking for a
place. The page follows the finger, the next page is already drawn with its text when it slides in from the left, and
nothing hitches at the start of the swipe, in the middle, or just after the page comes to rest. Opening a bar, a panel
or a message while pages are turning does not make the turn hitch either.

**Why this priority**: This is the owner's complaint and the app's one job. A Mushaf reader that stutters on its main
gesture feels broken however good everything else is.

**Independent Test**: On the owner's phone, 50 swipes at three paces (slow, normal, fast) in browse mode and in wird
mode: the frame numbers of SC-001. Without the phone, counters in widget tests: a page turn builds the incoming page
once and rebuilds no page that is already drawn; the incoming page is already built before the finger touches the
screen.

**Acceptance Scenarios**:

1. **Given** the reader has rested on a page for a second, **When** the reader swipes to the next page, **Then** the
   next page is already built with its text, so no empty page slides in and nothing is built or laid out in the first
   frames of the swipe.
2. **Given** a page is sliding, **When** the pager passes the middle of the slide and reports the new page, **Then** the
   pages already drawn are not rebuilt, and no frame of the slide rebuilds the whole screen.
3. **Given** the reader follows a wird, **When** a page turn is saved to the database and the database answers, **Then**
   the answer rebuilds the bars at most, never a Mushaf page.
4. **Given** the reader flips pages quickly (a swipe every 250 ms), **When** each swipe ends, **Then** the text of the
   page that arrived is on the screen and the next neighbour is prepared without a visible hitch.
5. **Given** the reader turns the page with a swipe from the edge of a page wider than the screen (feature 003), **When**
   the page turns, **Then** the turn takes 300 ms as today and shows the new page with its text from the first frame.

---

### User Story 2 - Bars and the today panel move softly (Priority: P2)

A tap on the page hides the top and bottom bars and a second tap brings them back. Today they cut in and out, which
feels abrupt next to the soft page. The bars should fade and slide a little (up for the top bar, down for the bottom
bar) in about 200 ms, and the page between them must not move or change size. The «ملخص اليوم» card, which opens over
the reader from the chip in the top bar, should fade and slide down a little instead of jumping in, and fade away when
it is closed.

**Why this priority**: It is the visible half of the request («movement inside the app should also have animation») and
it is cheap once the page no longer rebuilds on every setState, but it is not the complaint about lag.

**Independent Test**: Widget tests: after a tap the bars are present and partly transparent in the middle of the
animation and gone after 250 ms; the page rectangles (line boxes, word boxes) are identical in every frame of the
animation; the card is present during its fade-out and absent after 250 ms; taps outside the card close it at once.

**Acceptance Scenarios**:

1. **Given** the bars are shown, **When** the reader taps the page, **Then** within 200 ms both bars fade out while
   sliding away from the page, and the page area keeps its size and place in every frame.
2. **Given** the bars are hidden, **When** the reader taps the page, **Then** they fade in and slide to their place in
   200 ms; a bar that is leaving does not catch taps (a tap meant for the page reaches the page), and a bar that is arriving
   can be tapped as soon as it is visible.
3. **Given** the today chip is tapped, **When** the card opens, **Then** it fades in while sliding down 12 dp in 220 ms,
   and it fades out in 160 ms when it is closed by the chip, by the close button or by a tap outside it.
4. **Given** the card is closing, **When** the reader taps where the page is, **Then** the tap reaches the page (the
   barrier is gone at once), and the leaving card does not catch it.
5. **Given** the phone is rotated or the app returns from the background, **When** the reader looks at the bars, **Then**
   they are in the state they were in, with no animation replayed.

---

### User Story 3 - Jumps, the bookmark icon, the wird name and the look change softly (Priority: P2)

Going to another page by the index, by the page number, by a bookmark, by a notification or by choosing another wird
puts the reader on a distant page at once; today the page changes with no transition at all. The new page should fade
in quickly (180 ms). The bookmark icon changes between outline and filled with a short fade and grow, the wird name in the
top bar changes with a short fade when another wird is chosen, and the look switch in Settings fades from the old look
to the new one. Sheets, dialogs and screens keep the framework's transitions.

**Why this priority**: It completes the owner's wish for a reader that feels soft, but each part is small and none is
needed for the app to work.

**Independent Test**: Widget tests: after a jump the new page is at about 35% opacity in the first frame and fully opaque
180 ms later; the saved position and the page shown are right on the first frame; the icon is the new one in the first frame and its size and colour reach the end state 160 ms later; with «remove animations» on, each of these ends in one frame.

**Acceptance Scenarios**:

1. **Given** the reader is on page 50, **When** they choose page 300 in go-to-page, **Then** page 300 fades in over
   180 ms, the top line shows the new surah at once, and no page between 50 and 300 is built.
2. **Given** the reader taps the bookmark icon, **When** the database confirms, **Then** the new icon (outline or filled)
   is shown at once, grows and takes its colour in 160 ms, only one icon is ever on screen, and the message appears with the
   framework's snack-bar motion.
3. **Given** the reader opens «أوراد» and chooses another wird, **When** the list closes, **Then** that wird's page fades in
   and the wird name in the top bar changes with a short fade.
4. **Given** the reader taps the other look in Settings, **When** the choice is saved, **Then** the screen cross-fades
   from the old look to the new one in 220 ms (instantly with «remove animations» on), and the choice is saved and
   applied as before.

---

### User Story 4 - «Remove animations» is honoured everywhere (Priority: P1)

Some readers turn off animations on their phone for comfort or because they cause discomfort. When the phone's «remove
animations» setting is on, nothing this feature adds moves: bars, the today panel, jumps, the icon, the wird name and
the look switch all happen in one frame, and the edge turn of a wide page jumps instead of sliding. The swipe that the
finger drives still follows the finger, because that is the reader's own movement, and a page that the finger releases
still settles on its page.

**Why this priority**: It is an accessibility rule of the whole feature; a motion feature that ignores the setting is
worse than none.

**Independent Test**: Widget tests with the setting on (`accessibilityFeaturesTestValue`): every motion of the feature
completes in the first frame after it starts, and the edge turn does not animate; with it off the motion lasts the
durations in contracts/ui.md.

**Acceptance Scenarios**:

1. **Given** «remove animations» is on, **When** the reader taps the page, **Then** the bars are gone or back in the next
   frame, with no fade.
2. **Given** it is on, **When** the reader jumps to another page, **Then** the new page is shown in the next frame with no
   fade.
3. **Given** the setting changes while the app is open, **When** the next motion starts, **Then** it follows the new value.

---

### User Story 5 - The page, the text and the gestures are exactly as they were (Priority: P1)

None of this may change what the Mushaf shows or how it behaves. The Quran text, the 15-line distribution, every line
box and word box, the direction of a page turn (the next page comes in from the left), the edge turn of a wide page,
pinch zoom, the long press on a word, the page number tap, the swipe past page 604 and the saved position all work
exactly as before.

**Why this priority**: Constitution I and VI; the previous features' tests are the proof.

**Independent Test**: The earlier features' tests pass unchanged, the geometry baselines recorded by features 003, 004
and 006 are equal before and after, and a new test compares the line boxes and word boxes of sampled pages in every
frame of a bars animation.

**Acceptance Scenarios**:

1. **Given** the feature is built, **When** the geometry tests of features 001 to 006 run, **Then** they pass unchanged.
2. **Given** any motion of this feature is running, **When** the page's line and word rectangles are read, **Then** they
   equal the rectangles read when nothing moves.

---

### Edge Cases

- The pager is locked because the page is wider than the screen or zoomed in (features 003, 005): the bars and the
  jump fade still work; the edge turn keeps its 300 ms slide, or jumps with «remove animations» on.
- The reader taps the page twice quickly: the bars end in the state of the second tap, the animation reverses from where
  it is, with no jump of the page.
- The reader swipes while the bars are fading: the swipe is handled by the pager as usual and the fade goes on.
- The today panel is open and the reader turns pages: the panel is modal today (a tap outside closes it), so it closes
  first; the rule stays.
- A jump arrives while a jump fade is running (two notifications in a row): the second starts from the current
  opacity; the final page is the last one asked for.
- A jump to the page already shown (go-to-page with the same number): no fade, nothing changes.
- The app is started by a notification that jumps to a page: the first frame already shows that page; no fade plays at
  start (nothing to fade from).
- The reader uses landscape (the bars are shown there by default since 2026-11-21; they used to start hidden): the bars animate the same way when a tap shows or hides them.
- The look is changed while the reader is open under Settings: the cross-fade plays over Settings; coming back shows the
  reader already in the new look.
- Slow or old phones: a motion that cannot keep its frames may drop frames but never delays what it shows; the final state
  is always reached.
- The measurement build (FRAME_TRACE, PAGE_TURN_TRACE) is a build option; the normal build contains no logging of frames.

## Requirements *(mandatory)*

### Functional Requirements

**The page swipe**

- **FR-001**: Turning a page by a swipe MUST be drawn without a hitch (SC-001). The cause of today's lag MUST be found by
  measurement on the owner's phone before any fix beyond Stage A of the plan is kept (research D9, plan Stages).
- **FR-002**: The pages next to the shown one (next and previous) MUST be ready before the reader touches the screen: data
  and font loaded, widgets built and laid out, once the reader has stayed on the page for one second, so the first frames of
  a swipe build and lay out nothing for the incoming page. A page that is not ready MUST still show its page number only
  (feature 001 FR-008a), never text in another font.
- **FR-003**: A Mushaf page that is already drawn MUST NOT be rebuilt because something else changed: the other page arrived,
  the pager reported a new page, the bars or the today panel animated, a message appeared, the database answered, or a
  setting that does not affect the page changed. A page is rebuilt only when its own inputs change (its data, the chosen
  look, the reading size, the highlighted ayah, the font, the screen size).
- **FR-004**: The reader screen MUST NOT rebuild all its widgets on every change of the reader's state. The bars, the
  today panel, the pager and the page each follow only what they show.
- **FR-005**: Loading page data and page fonts of the pages near the shown page MUST run in the background, MUST NOT start in
  the middle of a slide, and MUST NOT delay the page the reader asked for. Pages far away (a jump) load on demand.
- **FR-006**: The direction and the rules of turning pages MUST NOT change: the next page comes in from the left, the edge
  turn of a wide page, pinch zoom, the swipe past page 604 (feature 005) and the long press on a word (feature 002).
- **FR-007**: The reading position MUST be saved as today (the active wird's position when following a wird, the last
  viewed page in both modes). If saving is ever delayed (plan Stage C) it MUST be written within 0.4 s of the last page turn
  and at once when the app leaves the front, when another screen opens, when the reader closes and when a page is jumped
  to; an app that is killed after a pause of one second MUST have lost nothing (Constitution VII).

**Soft motion**

- **FR-008**: The top and bottom bars MUST fade and slide when shown or hidden (durations and curves in contracts/ui.md),
  inside slots of fixed height (84 dp and 68 dp), so the page area never changes size or position. A hidden bar MUST NOT
  be tappable, focusable or read by a screen reader, and a bar that is leaving MUST NOT catch taps.
- **FR-009**: The «ملخص اليوم» card MUST fade and slide when opened or closed. The barrier behind it MUST appear and
  disappear with the card's open state, not with its animation, so a tap during the fade-out reaches what is under it.
- **FR-010**: A jump to another page (index, go-to-page, bookmark, notification, wird chosen, backup restored) MUST show
  the new page with a soft 180 ms fade-in, without building the pages in between, and MUST NOT delay the
  saved position or the top line.
- **FR-011**: The bookmark icon's two states, and the wird name in the top bar, MUST change with the short fade of
  contracts/ui.md. The icon's size (48 x 48), tooltip and screen-reader label stay as feature 006 set them.
- **FR-012**: A look change MUST cross-fade from the old look to the new in 220 ms (contracts/ui.md) without interpolating
  the theme (feature 004 FR-015 stays) and without delaying the saved choice or the new theme.
- **FR-013**: Sheets, dialogs, screens and snack bars MUST keep the framework's own transitions; the app MUST NOT replace
  them.
- **FR-014**: When the phone's «remove animations» setting is on, every motion this feature adds MUST finish in one frame
  and the edge turn MUST jump instead of sliding. The setting is read when each motion starts, so a change
  while the app is open applies to the next motion. No other switch is added.
- **FR-015**: All motion MUST be implicit (an animated widget or a single short controller owned by the widget that moves);
  no new package, no loop, no motion that runs while nothing is changing. Every motion MUST end in the exact state it would
  have had without motion.

**What does not change**

- **FR-016**: The Quran text, the 604 pages, the 15 lines per page, every line and word rectangle, the page fonts, the page
  card and the way a page is drawn MUST NOT change (Constitution I). The earlier features' tests, including the geometry
  baselines of features 003, 004 and 006, MUST pass unchanged.
- **FR-017**: Arabic strings, RTL, contrast, 48 dp targets and the two looks MUST remain as the earlier features set them.
  This feature adds no visible text. (Constitution VI)
- **FR-018**: The feature MUST work fully offline, send nothing off the device and track nothing (Constitution IV). Frame
  and page-turn traces exist only in builds made with an explicit option, print to the log only, and are free (a
  compile-time constant) in normal builds.
- **FR-019**: The measurements MUST be repeatable: the test-time micro-benchmarks and rebuild counters in `test/motion/`,
  the phone script and the summariser in `specs/010-smooth-motion/phone/`, and the acceptance numbers of the success
  criteria are the way a fix is shown to work (research D8, D9).

### Key Entities

- **Page turn**: one swipe, fling or edge turn from a page to a neighbour, from the finger down to the moment the new
  page has settled and its neighbours are prepared. Its cost is what SC-001 measures.
- **Prepared neighbour**: the next or the previous page with its data loaded, its font registered and its widgets built and
  laid out, waiting offscreen. At most two exist besides the shown page.
- **Motion**: one of the soft transitions of contracts/ui.md (bars, today card, jump fade, icon swap, wird name swap,
  look cross-fade) with its duration, curve and reduced form.
- **Reduce-motion setting**: the phone's «remove animations» state as the system reports it to the app; read, never stored.
- **Reading position**: already in the app (feature 001); unchanged by this feature, except possibly the moment it is
  written (FR-007).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On the owner's phone, over 50 page swipes at each of three paces (slow, normal, fast), in browse mode and in
  wird mode: at least 95% of the frames are drawn within the frame time of the screen's refresh rate (16.7 ms at 60 Hz,
  8.3 ms at 120 Hz, taken from the phone), no frame takes longer than 100 ms, and the 99th percentile is at most twice the
  frame time. The same numbers before the fix are recorded for comparison (research D9).
- **SC-002**: In at least 98% of 50 swipes read at a normal pace (the reader rested at least one second on each page) the
  incoming page shows its text from the first frame in which it is visible; and in 100% of swipes at any pace its text is
  painted within 300 ms of the swipe starting (the existing page-turn trace, features 001 SC-007, 003 SC-006).
- **SC-003**: A page turn builds the Mushaf page widget of the incoming page once and rebuilds no other page: in the widget
  tests, `MushafPage` is built at most once per page turn in browse mode and in wird mode and zero times for a bars toggle,
  a today-panel toggle, a message or a database answer (counted by the tests, research D1, D8).
- **SC-004**: Showing or hiding the bars and the today card never costs a frame over 33 ms on the phone, and in the widget
  tests the line and word rectangles of the page are identical in every frame of the animation (0 px difference).
- **SC-005**: With «remove animations» on, every motion of this feature is complete in the first frame after it starts, and
  with it off each lasts the duration in contracts/ui.md within ± 2 frames (widget tests).
- **SC-006**: All tests of features 001 to 009 pass unchanged and `flutter analyze` reports no issues; the geometry baselines
  of features 003, 004 and 006 and the 604-page layout checks are equal before and after.
- **SC-007**: A position is never lost: with saving delayed (if Stage C is built), a swipe followed by sending the app to the
  background, opening another screen or closing the reader is saved before the next screen is shown (test), and a
  force-stop one second after the last swipe finds the last page.
- **SC-008**: The owner, turning pages on the phone, says the lag is gone and that the bars, the today card and the jumps feel
  soft but not slow (a yes or no on the phone, Constitution IX).

## Assumptions

- The lag is real and comes from the code the research reads (whole-screen rebuilds mid-swipe, building the incoming page
  during the slide, work triggered by the saved position), not from the phone; the plan nevertheless fixes in stages and
  re-measures, because the earlier phone traces only measured the time until the text was painted (26 to 52 ms in browse
  mode), never the frames of a swipe or the wird-mode path (research D9).
- The owner's phone (<phone>, 1080 x 2340) may run at 60, 90 or 120 Hz or adaptively; the frame budget is read
  from the phone, never assumed. Nothing in the phone's settings is changed to measure.
- The framework already shortens its own animations to one frame under «remove animations» (measured: routes, sheets,
  dialogs, snack bars and implicit animations take 1 frame, while the edge turn's programmatic slide still takes its
  full duration, research D7), so only the edge turn needs its own check.
- The pager's slide after the finger lifts is the framework's spring and stays: it is the paper-like feel the owner already
  knows. It is tuned only if the phone numbers show it feels heavy (plan Stage C).
- The pager can prepare both neighbours while it rests without them being visible or counted as the shown page (measured,
  research D2), so the earlier tests that look for one page number keep passing.
- No new package is needed, not even a development one; the phone measurement uses the app's own frame trace and `adb`.
- The measurement build prints frame timings to the local log only; installing it on the phone is the owner's call (research D9).
