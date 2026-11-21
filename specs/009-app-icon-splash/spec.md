# Feature Specification: App Icon and Animated Splash Screen

**Feature Branch**: `009-app-icon-splash` (work stays on `main`, as for features 001 to 008)

**Created**: 2026-11-21

**Status**: Draft

**Input**: User description: the owner chose icon number 2 «المصحف المفتوح» (an open Mushaf in ivory with a gold line
under it and a small teal eight-point star above it, on a dark night background) and liked splash number 2
(«القارئ الليلي»). The splash is shown on every launch and must have a light, pleasant animation. The design files
are `Icon2.dc.html` and `Splash2.dc.html` (feature 006 design canvas). The first-run tips slider is feature 008; it
is shown after the splash on the first launch only.

## Clarifications

### Session 2026-11-21 (proposed; the owner confirms)

The owner was not asked: every answer is a default recorded here, and the questions that need the owner are
collected under Open questions at the end.

- Q: Which icon and which splash? → A: Icon 2 «المصحف المفتوح» and splash 2 «القارئ الليلي», chosen by the owner.
- Q: How often does the splash show? → A: On every launch of the app (a cold start of the process), right after
  the native launch screen. Not when the app comes back from the background, and not on a rotation.
- Q: Does the splash follow the app look (Emerald & Gold or Night Reader)? → A: No. It is always the night look,
  as in the design: the native launch screen is dark in day and night too, and a splash that changed look would
  flash.
- Q: How long is it? → A: The full choreography is 1.4 s. It never keeps the reader waiting for the sake of the
  animation: it leaves as soon as 0.9 s have passed **and** the app has finished its first loading, so on a
  phone that loads in under 0.9 s it shows 0.9 s plus a 0.22 s fade, and on a slow start it stays until loading
  ends.
- Q: When does the 0.9 s start, and what if the app goes to the background meanwhile? → A: It counts from the
  splash's first frame and is measured in drawn frames, so a hidden app does not use it up. (Default recorded.)
- Q: What do the tiny stars and rings do on screens that are not 390 × 844? → A: They keep their place in proportion
  to the screen's width and height; they are decoration. (Default recorded.)
- Q: What does a tap do? → A: It skips the animation and the 0.9 s minimum; the splash still waits for the first
  loading to finish, because leaving earlier would show an unfinished screen.
- Q: What if the phone has «إزالة الرسوم المتحركة» (reduce motion) on? → A: The splash is drawn complete and
  still (no scale, fade, twinkle or filling line), is shown for at least 0.3 s from its first frame and until the app is
  ready, and is cut away with no fade.
- Q: What is the line under the name? → A: «المصحف كاملاً بلا إنترنت وبلا إعلانات», the line of the design. It is
  an Arabic UI string written by the assistant, so it is a **proposal** the owner confirms (Constitution VI); it
  lives in one constants file.
- Q: What is the app name? → A: «مصحف الحافظ», unchanged (the manifest label and `MushafApp.title` already say so).
- Q: Does the splash break Principle II («the app MUST open directly on a Mushaf page; no home screen, splash
  menu or list before it»)? → A: Proposed reading: no. A branded splash offers no menu, list or choice, needs no
  tap, lasts about a second, and always hands over to the Mushaf page; the Mushaf is already loaded behind it.
  This reading is listed for the owner (Open question 1) because the principle says «splash menu» and the owner
  has chosen a splash.
- Q: Android 12 and later draw their own launch splash from the app icon. → A: It is styled (dark background, the
  icon without its background); the in-app splash then follows. Two splashes in a row is how Android 12 and later
  work for every Flutter app; the in-app one is the owner's design.
- Q: Will the icon replace the Flutter default everywhere? → A: Yes: the adaptive icon (Android 8 and later,
  with the themed monochrome layer of Android 13) and the old-style square icon in the five densities (Android
  7).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The app has its own icon (Priority: P1)

On the phone's home screen and in the app list the owner sees the open Mushaf with the gold line and the small teal
star on the dark night background instead of the blue Flutter bird. It looks right in the round, squircle and
rounded-square shapes the phone's launcher uses, nothing is cut off at the edge, and with themed icons on (Android
13) it becomes a one-colour silhouette in the owner's wallpaper colours that is still recognisable.

**Why this priority**: It is the first thing the owner and the people they share the app with see, every day, and
the default icon says «unfinished».

**Independent Test**: The resource files exist and are well-formed, the adaptive icon names background, foreground
and monochrome layers that exist, the drawn content of the foreground lies inside the 66 dp safe circle of the
108 dp canvas, and the five old-style PNGs have the sizes 48, 72, 96, 144 and 192 px. On the phone: look at the icon
in the launcher, long-press, and switch themed icons on.

**Acceptance Scenarios**:

1. **Given** the app is installed on Android 8 or later, **When** the owner looks at the launcher, **Then** the
   icon shows the star, the open Mushaf and the gold line on the dark background, in whatever shape the launcher
   masks it, with nothing cut off.
2. **Given** themed icons are on (Android 13 or later), **When** the owner looks at the launcher, **Then** the icon
   is a single-colour silhouette of the same drawing.
3. **Given** the app is installed on Android 7, **When** the owner looks at the launcher, **Then** the same drawing
   shows as a rounded square.

---

### User Story 2 - The app starts dark, with no white flash, and the splash plays (Priority: P1)

The owner taps the icon. At once the screen is dark (never white, whether the phone is in day or night mode), then
the splash appears: the icon tile eases in with a gentle scale, the star twinkles once, the name «مصحف الحافظ» and
the line under it fade up, and a thin line at the bottom fills. Then the splash fades away and the Mushaf is
already there, on the page where the owner stopped.

**Why this priority**: It is the whole request; the launch is the moment every session starts.

**Independent Test**: A widget test with fake time shows the splash appear, the child behind it, and the splash end;
the launch resources are checked for the dark background in both the day and the night sets. On the phone: cold
start the app in day mode and in night mode and look for any white.

**Acceptance Scenarios**:

1. **Given** the phone is in day mode, **When** the owner starts the app, **Then** no white or light frame is shown
   before or between the native launch screen and the splash.
2. **Given** the app has just started, **When** the splash is shown, **Then** it shows the icon tile, the name, the
   line and the thin line, in the night look, and nothing else (no text button, no menu).
3. **Given** the splash has run its minimum time and the app is ready, **When** it ends, **Then** the Mushaf page is
   already on screen behind it and no second loading indicator appears.
4. **Given** the owner keeps the app in the background and comes back, **When** it returns to the front, **Then**
   no splash shows.

---

### User Story 3 - Light, never longer than needed, and a tap skips it (Priority: P2)

The splash is a greeting, not a delay. It lasts about a second on a normal start, stays only as long as the app is
still loading, and a tap anywhere ends it at once (as soon as the app is ready).

**Why this priority**: Without it the splash would be a daily annoyance for a reader who opens the app many times
a day.

**Independent Test**: With fake time: ready at once, the splash is still there at 0.8 s and gone after 0.9 s plus
the fade; not ready, it stays; ready late, it leaves within the fade; a tap before 0.9 s with the app ready ends it
within the fade; a tap with the app not ready waits for ready.

**Acceptance Scenarios**:

1. **Given** the app is ready at 0.2 s, **When** time passes, **Then** the splash is still shown at 0.8 s and is gone
   by 0.9 s plus the fade.
2. **Given** the app needs 2.5 s to load, **When** time passes, **Then** the splash stays until 2.5 s and ends within
   the fade after it.
3. **Given** the app is ready and the splash shows at 0.3 s, **When** the owner taps, **Then** the splash ends within
   the fade.
4. **Given** the app is not ready, **When** the owner taps, **Then** the splash stays until the app is ready, then
   ends within the fade.
5. **Given** the splash is skipped or ends normally, **When** it is gone, **Then** the «finished» callback has been
   called exactly once.

---

### User Story 4 - The splash respects «إزالة الرسوم المتحركة» (Priority: P2)

For an owner who turned the phone's animations off (reduce motion), the splash does not move at all: it shows the
finished drawing, stays 0.3 s once the app is ready, and is replaced by the Mushaf without a fade.

**Why this priority**: Constitution-level accessibility care already applies to the app (earlier features test
screen readers and large fonts); motion sensitivity is the same kind of care.

**Independent Test**: With the system «disable animations» flag on, the splash is drawn complete from its first
frame, no animation runs, and it ends 0.3 s after ready without a fade.

**Acceptance Scenarios**:

1. **Given** reduce motion is on, **When** the splash first draws, **Then** the tile, the name, the line and the thin
   line are all fully visible, at their final size and position.
2. **Given** reduce motion is on and the app is ready, **When** 0.3 s have passed since the first frame, **Then** the splash is gone with no fade (if the app becomes ready later, it is gone at that moment).

---

### User Story 5 - Readable and safe on every phone and every setting (Priority: P2)

The name and the line are readable (contrast of at least 4.5:1 against the splash background), the splash does not
overflow or throw on a 320 × 640 dp phone with a 2x system font, a screen reader announces the name and the line
once and does not read the Mushaf hidden behind it, and nothing behind it can be touched while it shows.

**Why this priority**: Earlier features hold every screen to the same bars (contrast, 320 dp, 2x font, screen
reader); the splash is a screen too.

**Independent Test**: A widget test at 320 × 640 with a 2x text scale finds no exception and no overflow; the colours
of the name and of the line against the background are computed and are at least 4.5:1.

**Acceptance Scenarios**:

1. **Given** a 320 × 640 dp window and a 2x system font, **When** the splash is shown, **Then** nothing overflows and
   nothing throws.
2. **Given** the splash is shown, **When** its colours are measured, **Then** the name against the background is at
   least 4.5:1 and the line against the background is at least 4.5:1.
3. **Given** a screen reader is on, **When** the splash is shown, **Then** it reads the name and the line as one
   item and does not read the page behind it.

---

### User Story 6 - Something can run when the splash finishes (Priority: P3)

Feature 008 (the first-run tips) shows its slider on the first launch only, after the splash. The splash offers a
callback that is called once when it is gone, whether it ended by itself or by a tap, so that feature can start
there without knowing anything about the splash's inside.

**Why this priority**: It is a small hook with no effect on the owner today, needed by the next feature.

**Independent Test**: A test passes a counting callback and checks it is called once, after the splash is gone and
never twice, for a normal end, a tap, and reduce motion.

**Acceptance Scenarios**:

1. **Given** a callback is passed, **When** the splash ends in any of the three ways, **Then** it is called exactly
   once and only after the splash is no longer drawn.
2. **Given** no callback is passed, **When** the splash ends, **Then** nothing else happens.

---

### Edge Cases

- The app finishes loading before the splash's first animated frame: the splash still shows its minimum time.
- The first loading fails with an error: the splash ends as if ready (it never hangs); the error is shown by the
  app as it was before (nothing is hidden).
- The phone is rotated during the splash (the manifest already handles the change itself): the splash redraws at the
  new size without restarting its timeline.
- The reduce-motion setting changes while the splash shows: the splash follows the new value at once (a running
  animation is dropped to the static drawing).
- The owner taps twice, or taps while the splash is already fading: the callback is still called once and nothing
  throws.
- The system font is very large or the window is very small: the text wraps or shrinks to fit, it never overflows.
- The device is an old one (Android 7): there is no adaptive icon and no system splash; the old-style icon and the
  dark drawable launch screen are used.
- The owner's phone has a theme or launcher that does not mask or tint icons: the full-colour adaptive layers or
  the old-style icon show as drawn.
- A test pumps `MushafApp(home: ...)` directly (every existing test): there is no splash, nothing changes.

## Requirements *(mandatory)*

### Functional Requirements

**The launcher icon**

- **FR-001**: The app MUST have a launcher icon that replaces the Flutter default and shows the design of icon 2: the
  teal eight-point star above two ivory pages, with grey page lines and a grey spine, a gold line curving under
  them, on a dark night background (gradient from #1A212A at the top to #0D1014 at the bottom, with a soft teal
  glow near the top).
- **FR-002**: For Android 8 and later the icon MUST be an adaptive icon with three layers: a background layer, a
  foreground layer and a monochrome layer for themed icons (Android 13 and later). The foreground's drawing, with its
  strokes, MUST lie inside the 66 dp safe circle of the 108 dp canvas so no launcher mask cuts it. The monochrome layer
  MUST be a single-colour silhouette of the same drawing inside the same circle.
- **FR-003**: For Android 7 (the minimum supported version) the icon MUST also exist as old-style PNG icons in the five
  densities, 48, 72, 96, 144 and 192 px, drawn as a rounded square from the same drawing.
- **FR-004**: The icon MUST be drawn from the same geometry and colours as the splash tile, so the two never
  disagree; the pictures MUST be reproducible from a script kept in the repository, with no download and no new
  package.

**The native launch screen**

- **FR-005**: Before the app's own first frame the screen MUST be dark, with no white or light frame, in both the day
  and the night resource sets: on Android 12 and later the system splash has the dark background and the icon
  without its background; before Android 12 the launch background is the dark colour with the icon centred.
- **FR-006**: The window background behind the app's first frame MUST also be dark in both resource sets.

**The in-app splash**

- **FR-007**: The production start of the app MUST show the splash on every launch, right after the native launch
  screen, in the night look regardless of the app look, and MUST hand over to the app (the Mushaf) when it ends.
  The app MUST keep loading while the splash shows, and the first frame of the splash MUST NOT wait for that loading,
  so the splash never delays it.
- **FR-008**: The splash MUST show, as in the design (390 × 844 reference): a background that is a radial gradient from
  #17313A at 50% across and 30% down to #0D1014; a few tiny stars (ivory, teal and gold dots) and two faint rings
  around the tile's centre; the 132 px icon tile with a corner radius of 34 and a teal glow; the name «مصحف الحافظ»
  in the heading font (Reem Kufi), 44 px, #ECE7DC; the line in the interface font (Cairo), 15 px, #9AA4AD; and a thin
  progress line 120 × 3 px, 64 px above the bottom, in #232A33 with a #6CC4B5 fill.
- **FR-009**: The motion MUST be light and take 1.4 s in full: the icon tile fades in and scales gently from a little
  smaller to its size; the star twinkles once; the name and the line fade up a short distance; the thin line fills.
  Every move MUST use an easing curve, none MUST bounce, and the first frame MUST be the night colour of the native launch screen (never white, never a
  jump from it): the tile and the text then ease in from nothing.
- **FR-010**: The splash MUST stay on screen for at least 0.9 s and until the app has finished its first loading, then
  fade out in 0.22 s. A tap anywhere MUST end the minimum-time wait at once: the splash then ends as soon as the app
  is ready.
- **FR-011**: If the system asks for reduced motion («إزالة الرسوم المتحركة»), the splash MUST be drawn complete and
  still from its first frame, stay at least 0.3 s from its first frame and until the app is ready, and be removed with no fade. A change of the setting
  while the splash shows MUST be followed at once.
- **FR-012**: While the splash shows, the app behind it MUST not receive touches and MUST not be read by a screen
  reader; the splash MUST be announced once as the name and the line.
- **FR-013**: The splash MUST offer a callback (`onFinished`) called exactly once when the splash is gone, after any of
  the three ways of ending (normal, tap, reduced motion), so another feature can run something then.
- **FR-014**: The splash MUST NOT overflow or throw on a 320 × 640 dp window with a 2x system font; its text MUST have a
  contrast of at least 4.5:1 against the splash background.
- **FR-015**: The splash MUST be drawn with Flutter widgets and painters only, with no new package and no new font
  or image asset; it MUST NOT read any setting, network or database of its own.
- **FR-016**: The splash MUST be wired only into the production start (`lib/main.dart`), so that every existing test,
  which pumps `MushafApp(home: ...)` directly, shows no splash and passes unchanged. The time from the start of the
  process to the app's own first frame MUST NOT grow, and the app's own loading MUST finish no later than before.

**Strings**

- **FR-017**: The Arabic strings of the splash (the name and the line) MUST live in one constants file with a doc
  comment marking the line as a proposal awaiting the owner (Constitution VI). The name MUST equal the app's title
  and the manifest label.

**General**

- **FR-018**: The feature MUST work fully offline, track nothing and send nothing off the device (Constitution IV); it
  MUST NOT touch the Quran text, the Mushaf pages, their fonts, the layout or the reading position (Constitution I,
  II).
- **FR-019**: The tests of the earlier features MUST pass unchanged.

### Key Entities

- **App icon**: one drawing (star, pages, lines, gold line, background) rendered as the adaptive icon's three layers
  and as five old-style PNGs. No state.
- **Native launch screen**: the dark window the phone shows before the app draws; resources only.
- **Splash**: a screen with a fixed timeline (full length 1.4 s, minimum 0.9 s, fade 0.22 s, reduced-motion minimum
  0.3 s), an input «the app is ready» and an output «finished». It stores nothing.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On the owner's phone, in day mode and in night mode, a cold start shows no white or light frame from the
  tap on the icon to the Mushaf (checked by eye and by a screen recording frame by frame).
- **SC-002**: With a ready app, the splash is gone within 1.2 s of its first frame (0.9 s plus the 0.22 s fade); with
  a tap, within 0.25 s of the tap; with reduced motion, 0.3 s after its first frame, or at once when the app becomes ready later.
- **SC-003**: With a slow load of any length, the splash is never gone before the app is ready, and it ends within
  0.25 s after ready.
- **SC-004**: The callback is called exactly once in 100% of the checked cases (normal, tap, reduced motion, tap while
  fading, tap while not ready).
- **SC-005**: At 320 × 640 dp with a 2x system font there is 0 overflow and 0 exception; the name and the line each
  have a contrast of at least 4.5:1.
- **SC-006**: The launcher icon is recognisable (star, pages, gold line) in the round, squircle and square masks and in
  themed mode on the owner's phone, with no part cut by the mask.
- **SC-007**: The resource check finds the adaptive icon with its three layers, all five PNG densities at 48, 72, 96,
  144 and 192 px, the dark launch screen in both resource sets, and all of it well-formed.
- **SC-008**: Every earlier test passes unchanged, and the time to the app's first frame is not longer than before
  (the loading work that used to run before the first frame now runs after it).

## Assumptions

- The Android minimum is 7.0 (API 24), as in the Gradle file; the adaptive layers sit in resources for Android 8 and
  later, the monochrome layer is ignored before Android 13.
- The tile in the splash has a slightly different shape from the adaptive icon: the splash draws the full-size art
  at the design's scale 0.9, the adaptive foreground is drawn a little smaller (scale 0.85) so it lies inside the
  safe circle. Both come from the same geometry.
- On Android 12 and later the system draws the splash icon inside a circle; the foreground layer fits that circle
  for the same reason it fits the adaptive mask. The system splash icon is static; an animated vector for it is out
  of scope.
- «The app is ready» means the app's own start-up loading (database, defaults, reminders, saved settings) has
  finished; the Mushaf page's own fonts load after that, behind the splash's fade, as they did before.
- The icon and the splash are the project's own artwork (the owner's choice from the design canvas): they add no
  external resource, so there is no new entry in `docs/research/licenses.md` and no new credit in About (Constitution
  V). The fonts used are the Reem Kufi and Cairo files the app already bundles.
- The app name stays «مصحف الحافظ».
- The in-app splash is Android-first like the rest of the app; it is plain Flutter, so it also draws on other
  platforms, but they are not tested (Scope and Distribution).
- Feature 008 (the first-run tips) is built at the same time by another session; it uses the callback of FR-013 and
  nothing else of this feature. Feature 004's look is not used by the splash.
- The constitution is at 1.3.0; this feature needs no amendment under the reading of Principle II recorded above.

## Open questions for the owner (default used meanwhile)

1. Does a short branded splash (no menu, no choice, about a second, then the Mushaf) fit Principle II («no home
   screen, splash menu or list before the Mushaf»)? Default: yes. Read strictly, «open directly on a Mushaf page» could
   forbid any screen before it; the analysis (tasks.md) rates that CRITICAL under the strict reading. Proposed cure, for the
   owner to approve through `/speckit-constitution` as a PATCH (1.3.1): add to Principle II «A brief branded launch screen
   (no controls, no choices, about a second at most, always followed by a Mushaf page) is not a splash menu.» Until then the
   feature stands on the reading recorded in the Clarifications. Feature 008's first-run tips slider is a larger case of the
   same question and is that feature's to answer.
2. The line under the name, «المصحف كاملاً بلا إنترنت وبلا إعلانات»: keep, change or remove? Default: keep (a
   proposal).
3. Should the splash really show on every launch? The owner said yes; if it later feels long, the 0.9 s minimum is one
   constant.
4. The splash is always dark even if the owner chose the light Emerald & Gold look. Default: yes.
