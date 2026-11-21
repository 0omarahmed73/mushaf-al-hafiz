# Feature Specification: First-Run Tips

**Feature Branch**: `008-first-run-tips` (work stays on `main`, as for features 001 to 007)

**Created**: 2026-11-21

**Status**: Draft

**Input**: User description (owner, Egyptian Arabic): "عايز تضيف في اول مرة اليوزر يفتح الابلكيشن زي بوب اب كده فيه شوية
تعليمات لليوزر ازاي يستخدم الابب، زي مثلا انه ممكن يدوس على الاية ضغطة مطولة يطلع له خيارات زي التفسير وكده. اشرح له
الحاجات اللي ممكن تبقى صعبة عليه على كذا مرحلة كإنه سلايدر" and later "السبلاش هتظهر كل مرة تفتح الابلكيشن, لكن
التعليمات اول مرة بس". In English: the first time a person opens the app, a popup with a few instructions on how to use
it, for example that a long press on an ayah opens options such as the tafsir; explain what may be hard to find in
several steps, like a slider. The splash screen (feature 009, built separately) shows on every launch; the tips show
only the first time, after the splash.

## Clarifications (proposed, owner confirms)

The owner did not take a clarify session for this feature; these are the decisions the author took from the request
and from reading the app. Each is recorded so the owner can overrule it (the questions to ask are in the report).

- Q: When do the tips appear? → A: On the first launch only, after the splash and over the reader, once the first
  frame is drawn. The reader is still the first screen (Constitution II); the tips are a popup on top of it.
- Q: What makes the tips "seen"? → A: The reader taps «ابدأ» on the last step, taps «تخطي», or uses the system back.
  From then on they never open by themselves, also after a restart and after restoring a backup. If the app is
  closed while they are open, or something else closes them (a notification that opens a page), they were not seen
  and appear again at the next launch.
- Q: Does a touch outside the popup close it? → A: No. A stray touch must not use up the tips; «تخطي» and back are
  the ways out.
- Q: How many steps and which? → A: Six, chosen from the things that are hard to find and checked against the code:
  the long press on an ayah, turning pages and jumping, hiding the bars and zooming, the daily wird, bookmarks, and
  size and look in the menu. Left out on purpose: the khatm dua (the reader meets it by itself at the end of the
  Mushaf), listening and tests (not built yet, shown as «قريباً»), reminders (Settings explains itself).
- Q: Does a person who updates from an older version see the tips? → A: Yes, once. The app cannot tell an update
  from a first install without a new rule, and the owner's own phone should see them. (Default recorded, owner may
  want the opposite.)
- Q: Is the flag part of the backup? → A: Yes, as one more setting. Restoring a backup on a new phone then does not
  show the tips again; a backup written before this feature has no flag and still imports; importing such a file
  never makes this phone forget that it has seen the tips.
- Q: Can the tips be opened again? → A: Yes, through a function any screen can call. The row in Settings that calls it
  is not part of this feature (Settings belongs to another feature); the owner decides if it is wanted.
- Q: What do the six step pictures show? → A: Small drawings made of shapes and the app's own icons, with no Quran
  text, no photo and no file. A gentle pulse on the long-press picture is allowed and is still when the phone
  asks for less motion.
- Q: Step 5 names the bookmark icon under the juz text (feature 006). → A: It is in the reader now; a test opens the
  real reader and checks that the icon exists, so the tip can never describe something that is gone.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See the tips once on the first launch, and leave them whenever I want (Priority: P1)

A person opens the app for the first time. After the splash the Mushaf page is there, and a popup card opens over it
with the first of six steps: a small picture, a title and one or two short Arabic sentences, dots that show where they
are, and two buttons. They swipe the card sideways like a slider (or tap «التالي»), read each step, and on the last
step tap «ابدأ». The popup closes and the Mushaf is as it was. At any step they can tap «تخطي» (or use back) and the
popup closes at once. The next time they open the app, and every time after, the tips do not appear.

**Why this priority**: This is the whole request: a first-launch popup, in steps, that shows once.

**Independent Test**: Open the app on an empty database: the popup appears after the first frame. Tap «التالي» five
times and «ابدأ»: it closes. Open the app again on the same database: no popup. Repeat with «تخطي» on step 1 and with
back on step 3: the same result.

**Acceptance Scenarios**:

1. **Given** the tips were never finished or skipped, **When** the app opens and the first frame is drawn, **Then** a
   popup shows step 1 of 6 over the reader.
2. **Given** step 1 of 6 is shown, **When** the reader taps «التالي», **Then** step 2 slides in and the dots show the
   second dot as the current one; on step 6 the buttons are «ابدأ» only.
3. **Given** any step is shown, **When** the reader swipes the card from left to right (the paper-Mushaf direction),
   **Then** the next step comes in from the left; a swipe the other way goes back one step; on step 1 and on step 6 the
   swipe that would go beyond the end does nothing.
4. **Given** any step is shown, **When** the reader taps «تخطي» or uses back, **Then** the popup closes and the reader
   is exactly as it was.
5. **Given** the reader finished or skipped the tips, **When** the app is opened again (a new process on the same
   database), **Then** the popup does not appear.
6. **Given** the popup is shown, **When** the reader touches the dimmed area outside it, **Then** nothing happens.

---

### User Story 2 - The steps teach what is hard to find, and nothing that is not there (Priority: P1)

The six steps are the things a new reader would not discover alone, each one true of the app as it is today.

**Why this priority**: A tip that describes a control that does not exist is worse than no tip, and the owner asked
for the hard things in particular.

**Independent Test**: For each step, open the real reader and do what the step says: the thing it names exists and
does what is said (the ayah menu with its rows, the index, the go-to-page dialog, the bars, the wird pill and today's
chip, the bookmark icon and the bottom item, Settings with its size and look rows).

**Acceptance Scenarios**:

1. **Given** step 1, **When** the reader long-presses a word of an ayah on the page, **Then** the ayah menu opens with
   «التفسير» (tafsir al-Sa'di), «الترجمة» (English), «معاني الكلمات» and the share rows (the ayah, the page as a picture,
   the surah as a PDF).
2. **Given** step 2, **When** the reader taps the surah name in the top bar, **Then** the index opens; **When** it taps
   the page number, **Then** the go-to-page dialog opens; swiping from left to right shows the next page.
3. **Given** step 3, **When** the reader taps the page, **Then** both bars hide and a second tap shows them; two fingers
   moved apart zoom the page.
4. **Given** step 4, **When** the reader taps the wird name or «أوراد», **Then** the wirds list opens; **When** it taps
   «ملخص اليوم», **Then** today's portion opens with a «تم» button.
5. **Given** step 5, **When** the reader taps the bookmark icon under the juz text, **Then** the page is bookmarked, and
   «علامات» in the bottom bar lists it.
6. **Given** step 6, **When** the reader taps «القائمة» in the bottom bar, **Then** Settings opens with «حجم الخط» and
   «المظهر» («زمردي وذهبي» and «القارئ الليلي»).

---

### User Story 3 - Open the tips again later (Priority: P2)

A reader who skipped the tips, or forgot them, can have them shown again by any screen that calls the function
`showTips`. They run in full, end the same way, and change nothing else in the app.

**Why this priority**: Small, and it makes the tips useful after the first day; it is a function only, because the row
that would call it lives in Settings, which this feature does not edit.

**Independent Test**: With the tips already seen, call `showTips`: the popup opens at step 1; finishing it leaves the
stored state "seen".

**Acceptance Scenarios**:

1. **Given** the tips were seen, **When** `showTips` is called, **Then** the popup opens at step 1 and closes the same
   ways.
2. **Given** a popup is already open, **When** `showTips` is called again, **Then** a second one does not open.

---

### User Story 4 - The popup is comfortable in both looks, at every size, for everyone (Priority: P2)

The popup uses the colours of the look the reader chose (Emerald & Gold or Night Reader), follows the phone's font
size, stays readable on a 320 dp phone with a 2x font (the text scrolls, the buttons stay in view), is usable with a
screen reader, and keeps still when the phone asks for less motion.

**Why this priority**: The constitution's quality bars (contrast, 48 px targets, no overflow at 320 dp with a 2x font)
apply to every new screen; a first-run popup that fails them fails for the people who need tips most.

**Independent Test**: Pump the popup in both looks at 412 x 915 and at 320 x 640 with a 2x system font, on every step:
no overflow, every text and icon at least 4.5:1 (icons 3:1), buttons at least 48 px high, a screen reader hears
"step N of 6", the titles as headings and the buttons as buttons; with reduced motion no animation runs.

**Acceptance Scenarios**:

1. **Given** either look at 320 x 640 with a 2x font, **When** any step is shown, **Then** nothing overflows, the body
   text scrolls inside the card and the dots and buttons stay visible.
2. **Given** either look, **When** a step is drawn, **Then** every text reaches 4.5:1 and every icon 3:1 against what is
   behind it.
3. **Given** a screen reader, **When** the reader moves to a step, **Then** it hears "الخطوة N من 6", the title as a
   heading, and the buttons by their names.
4. **Given** the phone asks for reduced motion, **When** a step is shown or «التالي» is tapped, **Then** the pulse is a
   still picture and the step changes without a slide.

---

### Edge Cases

- The app is closed while the popup is open: the flag was not written, the tips open again next launch.
- The database cannot be read when the app starts: no popup, the reader opens normally, nothing is shown or stored.
- The flag cannot be written when the reader finishes: the popup still closes; the tips may show once more next time.
- A notification opens a page while the popup is open: the popup is closed by that navigation and counts as not seen.
- The phone is rotated while a step is shown: the same step stays, the card is re-laid out and scrolls if it must.
- The reader swipes quickly through several steps, or taps «التالي» twice fast: it never goes past step 6 and never
  skips the last step by accident.
- The phone's font size changes while the popup is open: the popup follows. The look cannot change while it is open, because
  Settings is behind it (the card keeps the look it was opened in).
- A backup made before this feature is imported: it still imports; the phone keeps knowing it has seen the tips. A
  backup made after it carries the flag, so a new phone never shows them to a person who finished them before.
- The popup is shown over a reader that is still loading its page: the reader finishes loading underneath and is
  usable the moment the popup closes.
- A step names a control that is not always on screen (the «ملخص اليوم» chip is hidden when there is no portion today, and
  the bars are hidden by default in landscape: since 2026-11-21 they are shown there too): the step describes the usual state, which is the state of a new reader
  (the first launch creates «الورد اليومي» with a portion), and a tap on the page brings the bars back.
- The tips contain no Quran text, so the Quran text is not touched (Constitution I).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: On the first launch, within one second of the first frame being drawn, a popup card MUST open over the
  reader showing the first of the tips' steps. It MUST NOT open again once the tips were finished or skipped, including after the app is
  closed and opened again on the same data, and including when the same screen is rebuilt.
- **FR-002**: The popup MUST be a card over the reader (the reader stays the first screen), MUST NOT close when the dimmed
  area outside it is touched, and MUST open after the splash of feature 009 and not under or beside it.
- **FR-003**: There MUST be six steps. Each MUST have a small drawing made only of shapes and the app's own icons, a
  short title and one or two short sentences in Arabic, and MUST describe something the app really does today (spec
  Assumptions lists what was checked).
- **FR-004**: The steps MUST be swiped sideways like a slider, in the right-to-left direction of the paper Mushaf (a
  swipe from left to right shows the next step), with dots that show the current step and the number of steps.
- **FR-005**: «التالي» MUST show the next step. «تخطي» MUST close the tips. On the last step the buttons MUST be only
  «ابدأ», which closes the tips; the system back MUST do what «تخطي» does.
- **FR-006**: Finishing (the last step's «ابدأ»), skipping and back MUST store that the tips were seen. Closing the
  popup in any other way MUST NOT.
- **FR-007**: The stored state MUST be read once when the screen starts (not followed live) and a failure to read it
  MUST leave the app working with no popup. A failure to write MUST NOT keep the popup open.
- **FR-008**: The stored state MUST be part of the backup file like the other settings. A backup without it MUST
  still import, and importing any backup MUST NOT make this phone forget that the tips were seen.
- **FR-009**: A function MUST open the same popup at any time, whatever the stored state, and return when it closes;
  a second call while one is open MUST do nothing.
- **FR-010**: The popup MUST use the colours and shapes of the chosen look (Emerald & Gold, Night Reader), with at
  least 4.5:1 contrast for text and 3:1 for icons, in every step.
- **FR-011**: The popup MUST follow the phone's font size; at 320 dp wide with a 2x system font nothing MUST overflow,
  the step's content MUST scroll, and the dots and buttons MUST stay in view. Every button MUST be at least 48 px high.
- **FR-012**: A screen reader MUST hear the dialog's name, the current step as "الخطوة N من 6", each title as a heading
  and each button by its name; the dots MUST NOT be read one by one.
- **FR-013**: When the phone asks for reduced motion the popup MUST draw no animation (no pulse, no slide, no dot
  growth); otherwise the one decorative animation (a pulse on the long-press picture) MUST be gentle and MUST stop
  when its step is not shown.
- **FR-014**: Every Arabic string MUST live in one file, marked as a proposal until the owner confirms it
  (Constitution VI). No string is machine-translated.
- **FR-015**: The feature MUST work offline, add no package, asset, permission or database table, send nothing off the
  phone, and leave the Quran text, page data, fonts and layout untouched.
- **FR-016**: The component MUST be self-contained in its own folder and be added to the app with one wrapper around the
  reader and nothing else; no existing screen's behaviour or test changes with it. The one change outside the folder is
  the additive backup rule of FR-008 (a setting that describes this phone is kept when a file has none for it).

### Key Entities *(include if feature involves data)*

- **Tips seen flag**: one yes/no fact stored on the phone with the other small settings: the tips have been finished
  or skipped. Absent means not seen. It travels in the backup file.
- **Tip step**: one of six fixed steps: a drawing, a title and a short text. Not stored, not editable.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On an empty database the popup appears after the first frame in 100 percent of the tested launches, and
  in 0 percent of the launches after the tips were finished, skipped or left by back (tested with a rebuilt screen on
  the same data and with a restart that reopens the stored data from its file).
- **SC-002**: A reader reaches the end in 6 taps (5 of «التالي», 1 of «ابدأ») or leaves in 1 tap («تخطي») from any
  step; a swipe from left to right moves forward on 5 of 5 tested steps.
- **SC-003**: Each of the six steps has at most two sentences and each of the six statements is confirmed by a test on
  the real reader (6 of 6, User Story 2).
- **SC-004**: In 2 looks at 320 x 640 with a 2x font, on all 6 steps: 12 of 12 combinations without overflow, with
  every text at least 4.5:1 and every icon at least 3:1, and with every button at least 48 px high.
- **SC-005**: A backup written by a phone that has seen the tips, imported on an empty phone, leaves that phone with the
  tips seen; a backup without the flag imports and leaves a phone that has seen them as it was (2 of 2).
- **SC-006**: With reduced motion on, no animation controller runs in the popup on any step.
- **SC-007**: On the owner's phone the owner sees the popup on the first launch after the splash, swipes through it like
  a slider, and does not see it on the second launch (the owner's own check; the wording is the owner's to confirm).

## Assumptions

- "First launch" means an empty stored state. A person who updates from an older version also sees the tips once (see
  Clarifications).
- What each tip says was read in the code on 2026-11-21 and is pinned by tests on the real reader:
  - Long press: a long press on a word of the page highlights its ayah and opens the ayah menu with «مشاركة»
    (the ayah), «التفسير» (tafsir al-Sa'di), «الترجمة» (Saheeh International, English), «معاني الكلمات», «مشاركة
    الصفحة كصورة» and «مشاركة السورة PDF» (`lib/mushaf/reader_screen.dart`, `lib/ayah/ui/ayah_sheet.dart`).
  - Turning and jumping: the page turns with a swipe from left to right (Constitution VI); a tap on the surah name
    row opens the index (tabs «السور», «الأجزاء», «صفحة»); a tap on the page number opens «الانتقال إلى صفحة».
  - Bars and zoom: a tap on the page hides and shows both bars (shown in landscape too since 2026-11-21, when the owner asked for it); pinch zoom goes from
    1x to 3x.
  - Wird: on the first launch the app creates «الورد اليومي»; its name is a pill in the top bar that opens the wirds
    list, next to «ملخص اليوم» (done of total) which opens today's portion with «تم»; «أوراد» in the bottom bar opens
    the list, where «ورد جديد» adds one.
  - Bookmarks: the bookmark icon (feature 006) under the juz text toggles a bookmark on the page; «علامات» in the
    bottom bar lists them.
  - Settings: the bottom bar's «القائمة» opens Settings, which holds «حجم الخط» (80 to 150 percent) and «المظهر»
    («زمردي وذهبي», «القارئ الليلي»).
- Proposed Arabic strings (Constitution VI: the owner confirms every one before the feature is done) are in
  `lib/onboarding/tips_strings.dart`, each with a doc comment, and are listed in `contracts/ui.md`. The step pictures carry no text.
- The tips are a proposal reviewed by the owner in the report (the clarify step of the workflow was done as proposed
  decisions because the owner could not be asked during the build).
- The popup is a Material dialog; the reader keeps its own state under it (nothing about the page, wird or bars changes
  while it is open).
- The splash (feature 009) and the wiring of the component into the app belong to others: this feature delivers the
  component, its tests and the exact lines to add (`quickstart.md`).
- The phone check follows Constitution IX; the owner is asked before any install or input on the phone.
