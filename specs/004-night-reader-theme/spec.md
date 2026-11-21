# Feature Specification: Night Reader Look (Second Theme)

**Feature Branch**: `004-night-reader-theme` (work stays on `main`, as for features 001 to 003)

**Created**: 2026-11-20

**Status**: Draft

**Input**: User description: "I wanna add this theme to the app, and toggle it from the settings." The owner sent
a screenshot of the Wirds + Today screen in the design canvas's direction B, «القارئ الليلي» (Night Reader,
boards B-Wirds and B-Reader of the app's design canvas), next to the look the app has today, «زمردي وذهبي»
(Emerald & Gold, direction C, `docs/design/emerald-gold.md`). Decided by the owner on 2026-11-20: the full
Night look (colours and shapes), and the shared page picture and surah PDF follow the chosen look.

## Clarifications

### Session 2026-11-20

- Q: How far does the Night look go? → A: The full look of the design, colours and shapes: near-black
  background, charcoal cards with a hairline border and rounded corners, a teal accent with an amber second
  accent, a round add button, pill-shaped buttons and tags, round dot markers, a floating rounded bottom bar in
  the reader, and the Mushaf page drawn straight on the dark background without the ivory card and the gold
  frame. Every other screen wears the same dark palette. It is not a recolour of today's shapes.
- Q: Do the shared page picture and the surah PDF follow the look? → A: Yes. A page shared while Night Reader is
  chosen is a Night picture or a Night PDF; with Emerald & Gold chosen they are as they are today.
- Q: What is the control? → A: A two-way choice in Settings between «زمردي وذهبي» (today's look, the default) and
  «القارئ الليلي». It is not «follow the phone», because both looks are dark.
- Q: Does the design's font change come with the look? → A: No. The design canvas used IBM Plex Sans Arabic and
  Amiri; the owner replaced Plex with Cairo on 2026-11-20, so the interface stays in Cairo, headings in Reem Kufi
  and the basmallah in Amiri Quran. No new font or other resource is added.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Choose the Night Reader look and see the whole app change (Priority: P1)

The owner opens Settings and finds «المظهر» with two choices, each shown with a small sample of its colours:
«زمردي وذهبي» (selected) and «القارئ الليلي». They choose the second one and the app changes at once, without a
restart: the settings screen itself, and every screen behind it, now has the near-black background, charcoal cards,
teal accent and rounded shapes of the design. They open «أوراد» and see the Wirds + Today screen as in the
screenshot. They close the app, open it the next day, and it opens already in Night Reader, with no flash of the
other look. They choose «زمردي وذهبي» again and the app is exactly as it was before this feature.

**Why this priority**: It is the whole request: a second look, switched from Settings. The Mushaf page and the
sharing come after it, but the app is already usable at night once the screens and the switch exist.

**Independent Test**: Switch to Night Reader and open, one by one, the reader with its bars, the surahs and parts
list, «أوراد» with the today panel, the new wird form, the bookmarks sheet, the ayah menu with its tafsir,
translation and meanings views, the go-to-page popup, Settings and About: each is in the Night look, readable,
and nothing is cut off or overlaps. Restart the app: it is still Night Reader. Switch back: today's look.

**Acceptance Scenarios**:

1. **Given** the default look, **When** the owner opens Settings, **Then** they see «المظهر» with the two choices
   «زمردي وذهبي» (selected) and «القارئ الليلي», and a short note saying what the choice covers.
2. **Given** Settings is open, **When** the owner chooses «القارئ الليلي», **Then** the whole app, including the
   Settings screen they are on, changes to the Night look at once, without restart and without a separate «save»
   step.
3. **Given** Night Reader is chosen, **When** the owner opens «أوراد», **Then** the screen matches the design:
   a round add button at the top, a «ملخص اليوم» card with a dot for each wird and a «تم» pill button or a
   «✓ تم» mark, and a card for each wird with a hairline border, the active one outlined in teal and tagged
   «النشط», its type, page, bookmarks and khatmas shown as small pill tags and numbers, and a «ورد جديد»
   outlined pill button at the bottom.
4. **Given** Night Reader is chosen, **When** the owner opens the reader, **Then** its top line, the active wird
   pill, the page number and the bottom bar are in the Night look, the bottom bar floats as a rounded bar with
   the same items and actions as today (the disabled «استماع» and «اختبار» items stay disabled and labelled
   «قريباً»), and nothing is added to it.
5. **Given** Night Reader is chosen, **When** the owner opens each of the other screens and sheets listed in
   FR-004, **Then** each is in the Night look.
6. **Given** Night Reader was chosen, **When** the app is closed and opened again (or the phone is restarted),
   **Then** it opens in Night Reader from its first frame.
7. **Given** Night Reader is chosen, **When** the owner chooses «زمردي وذهبي», **Then** every screen is again
   exactly as it was before this feature.

---

### User Story 2 - Read the Mushaf page in the Night look (Priority: P2)

With Night Reader chosen, the owner opens the reader and the Mushaf page has no ivory card and no gold frame: its
text is light on the near-black background, the surah name sits between two hairlines in teal, the ayah-end
markers are small rings in teal, and the page number is quiet below the page. It is the same page: the same
lines, the same words on each line, the same line breaks as in the printed Madinah Mushaf 1421H, at every text size
chosen with feature 003 and at every pinch zoom. A long-pressed ayah is highlighted in a way that can be seen on
the dark background, and the owner can still tell the surah banner, the basmallah and the ayah numbers apart.

**Why this priority**: The page is the centre of the app (Constitution II), so its night look matters most after
the app's screens; but it touches the page drawing, so it comes after the safe screen restyle.

**Independent Test**: With Night Reader, open pages 1, 2, 3, 50, 293, 604 and a page with a surah banner in the
middle: each is complete and readable, the lines, words and line breaks are the same as with Emerald & Gold, a long
press highlights the ayah, and a tap still shows and hides the bars. Compare the words and lines of all 604 pages
in both looks: identical.

**Acceptance Scenarios**:

1. **Given** Night Reader, **When** the owner opens any page, **Then** the text is light on the dark background,
   with no ivory card and no gold frame, with the surah banner as a teal title between hairlines and the ayah
   markers as teal rings, and every word is easy to read.
2. **Given** either look, **When** the same page is opened, **Then** it has the same lines, the same words on each
   line in the same order and the same line breaks (Constitution I); only colours, borders and the frame around
   the page differ.
3. **Given** Night Reader and a long press on a word, **When** the ayah menu opens, **Then** the words of that ayah
   are highlighted with a colour that stands out from the dark background without hiding the text, and the
   highlight goes away when the menu closes.
4. **Given** Night Reader and a text size or zoom other than the default (feature 003), **When** the owner
   reads, **Then** the page is complete, scrolls and turns as it does in Emerald & Gold.
5. **Given** the page number, the surah name and the part markers around the page, **When** they are shown in
   Night Reader, **Then** they are readable and the taps on the page number and the surah name behave as before.

---

### User Story 3 - Share a Night page as a picture or a PDF (Priority: P3)

With Night Reader chosen, the owner long-presses an ayah and shares the page as a picture, or shares the surah as
a PDF. The picture and the PDF pages are drawn in the Night look, the same as the page in the app: dark
background, light text, teal title and rings. With Emerald & Gold chosen they are as they are today.

**Why this priority**: The sharing of feature 002 is already done and works in one look; this keeps it
consistent with the app (the owner asked that a shared page look like the page in the app).

**Independent Test**: With Night Reader, share the picture of a page and look at it in the share target (or the
saved file): it has the Night page look. Prepare the PDF of a short surah: every sheet has the Night background
edge to edge and the Night page. Switch to Emerald & Gold and do the same: the files are as before this feature.

**Acceptance Scenarios**:

1. **Given** Night Reader, **When** the owner shares «مشاركة الصفحة كصورة», **Then** the picture is the page as
   the app draws it in Night Reader, with the look's background around it, at the same size and sharpness as
   today.
2. **Given** Night Reader, **When** the owner shares «مشاركة السورة PDF», **Then** every sheet of the PDF is filled
   edge to edge with the Night background and carries the Night page, and the file stays the same size class as
   today (spec 002 limits).
3. **Given** the owner changes the look while a PDF is being prepared, **When** it finishes, **Then** the PDF has
   the look that was in force when it was started, and a started job is not corrupted by the change.
4. **Given** Emerald & Gold, **When** the owner shares a picture or a PDF, **Then** it is exactly as it was before
   this feature.

---

### User Story 4 - Keep the choice in a backup, and fall back safely (Priority: P3)

The owner exports a backup and imports it on another phone; the look chosen comes with it. A backup made before
this feature, or a file with a wrong value, does not break anything: the app simply opens in Emerald & Gold.

**Why this priority**: A consistency rule and a safety net; the feature is useful without it.

**Independent Test**: Choose Night Reader, export, switch to Emerald & Gold, import the file: Night Reader is back.
Import an old backup without the setting: Emerald & Gold, nothing else changed. Import a file with the setting
set to an unknown word: Emerald & Gold, no error message.

**Acceptance Scenarios**:

1. **Given** a backup exported with Night Reader chosen, **When** it is imported after the look was changed,
   **Then** Night Reader is in force, at once.
2. **Given** a backup made before this feature (no look in it), **When** it is imported, **Then** the look is
   Emerald & Gold and nothing else changes.
3. **Given** a stored look that is missing or is not one of the two known values, **When** the app starts or the
   file is imported, **Then** the app uses Emerald & Gold, shows no error, and does not change anything else.

---

### Edge Cases

- A wird whose colour the owner picked from the palette is shown with a marker dot: in Night Reader the dot must
  stay visible and tell wirds apart on the charcoal card (a dark brown or slate colour must not disappear), while
  the stored colour the owner picked is not changed and Emerald & Gold shows it as today.
- The look is changed from Settings while the reader is the screen behind it: when the owner goes back, the reader
  is already in the chosen look and still on the same page, at the same size and zoom.
- The look is changed while the ayah menu, a dialog or a snack bar is open (for example the PDF strip): it
  updates too, with no flash and no lost state.
- The Settings backup status messages, error messages, disabled buttons, text fields (with their focus and error
  states), switches, sliders and the feature 003 preview are all part of the look and readable in both.
- The system's own parts the app does not draw (the status bar, the navigation bar, the share sheet, a time
  picker or a file picker) stay as the phone draws them; the app does not claim to restyle them, but its own bars
  and sheets around them do not clash.
- A phone with a large system font size, a small phone, or the screen rotated: nothing overflows or is cut off in
  either look; the 48 px touch targets stay.
- Text over the Mushaf page, such as the tafsir in the ayah menu, is in the same dark palette and is as readable
  as at night in a dark room: no bright white blocks anywhere in Night Reader.
- The very first frame after the app starts, and the screen shown while pages load: they already use the saved
  look (no flash of the other look).

## Requirements *(mandatory)*

### Functional Requirements

**The choice**

- **FR-001**: Settings MUST have a row «المظهر» with a two-way choice between «زمردي وذهبي» and «القارئ الليلي»,
  where each option is shown with a small sample of its colours and the chosen one is clearly marked, with touch
  targets of at least 48 px and a label a screen reader can announce.
- **FR-002**: The default MUST be «زمردي وذهبي». With it chosen, every screen, the page picture and the surah PDF
  MUST be exactly as they were before this feature (nothing visible changes).
- **FR-003**: Choosing a look MUST apply to the whole app at once, without a restart, a separate confirmation or a
  loss of the screen, page, zoom or text size the owner was on; and the choice MUST be kept after the app closes
  and after the phone restarts.

**The Night Reader look**

- **FR-004**: In Night Reader every screen and sheet the app draws MUST wear the Night look: the reader and its
  top line, active-wird pill, page number and bottom bar; the surahs and parts index; «أوراد» with its today
  panel; the wird form; the bookmarks sheet; the ayah menu and its tafsir, translation and meanings views; the PDF
  progress strip; the go-to-page popup; Settings (including the backup section and the text-size preview of
  feature 003); About; and all dialogs, snack bars, text fields, switches, sliders and buttons. No part of the app
  MUST keep a bright or ivory block that clashes with the dark look, except where the Mushaf page itself is
  concerned (FR-007).
- **FR-005**: The Night look MUST use the shapes of the design as well as its colours: a near-black background,
  charcoal cards with a hairline border and generously rounded corners, a teal main accent with an amber second
  accent, a round add button, pill-shaped buttons and tags, round dot markers for wirds, hairline separators, and a
  rounded bottom bar in the reader that floats in its own slot below the page instead of sitting on the screen's edge. The exact
  values are fixed in the plan from the design canvas.
- **FR-006**: The Night look MUST keep today's content and behaviour: the same text, items, actions, order and
  navigation on every screen, the bottom bar's items as they are (including the disabled «استماع» and «اختبار»),
  and the fonts (Cairo for the interface, Reem Kufi for headings, Amiri Quran for the basmallah). Only colours,
  borders, corner radii, marker shapes and the bar's floating form differ.

**The Mushaf page**

- **FR-007**: In Night Reader the Mushaf page MUST be drawn on the dark background without the ivory card and the
  gold frame: light text, the surah banner as a teal title between hairlines, ayah-end markers as teal rings, the
  basmallah in the same family of light colours, and the page number below the page, all readable.
- **FR-008**: At every size and zoom and in both looks the Mushaf page MUST keep the exact Madinah Mushaf 1421H
  layout: the same lines per page, the same words on each line in the same order, the same line breaks and the same
  page numbers. Nothing in the Quran text, its order or its line distribution is changed by this feature
  (Constitution I). Only colours, borders and the frame around the page may differ between the looks.
- **FR-009**: The reader MUST behave in Night Reader exactly as in Emerald & Gold: the reading position and wird
  progress are saved, the page turns in the same direction, a tap shows and hides the bars, pinch zoom and the text
  size of feature 003 work, and a long press on a word opens its ayah menu with the ayah highlighted (Constitution
  II). The highlight MUST cover exactly the words of the ayah, MUST stand out from the dark page (the highlighted
  word's background differs from the page background by a contrast ratio of at least 1.5:1) and MUST keep the
  words readable (the ink on the highlighted background reaches 4.5:1).

**Sharing**

- **FR-010**: The shared page picture MUST be drawn in the look in force when the owner starts the share, equal to
  the page the app shows in that look, with the look's background around it, at the same size and sharpness as
  today. With Emerald & Gold it MUST be as before this feature.
- **FR-011**: Every sheet of the surah PDF MUST be filled edge to edge with the background colour of the look in
  force when the job was started and MUST carry the page in that look. A look change after the start MUST NOT
  change or corrupt a job already running. With Emerald & Gold the PDF MUST be as before this feature. In a Night
  picture and in the images of a Night PDF each colour of the page (background, ink, title, hairline) MUST be
  reproduced within 6 of 255 per channel, as the existing check does for the Emerald look (feature 002 FR-014).
  Failure, cancel and size rules are those of feature 002, unchanged.

**Readability and quality**

- **FR-012**: In Night Reader, ordinary text MUST have a contrast ratio of at least 4.5:1 against the colour
  behind it, and large text, icons and the borders that mark a control or a chosen state at least 3:1, with no
  information given by colour alone (the active wird has a tag as well as an outline, a chosen look has a mark as
  well as a colour). Colours taken from the design that fall below this MUST be lightened and the change recorded.
- **FR-013**: A wird's colour, chosen by the owner from the fixed palette, MUST stay stored as chosen. In Night
  Reader its marker MUST be shown in a form that meets the 3:1 contrast against the card it is on, so that every
  palette colour is visible; a colour is only lightened (its hue is kept), so the eight markers stay different
  from each other. In Emerald & Gold it MUST look as today.
- **FR-014**: In both looks nothing MUST overflow or be cut off on a small phone (320 dp wide), with the system
  font size at its largest setting, or with the screen rotated, and the 48 px touch targets MUST stay.
- **FR-015**: The saved look MUST be known before the first frame is drawn, so that the app never shows the wrong
  look first, and switching looks MUST NOT make page turning or scrolling slower than with Emerald & Gold (spec 001
  SC-007).

**Data, backup, robustness, licences**

- **FR-016**: The choice MUST be stored with the app's other settings on the phone only, and MUST be part of the
  backup file with them, so that importing a backup brings the look back. A backup that has no look, or a stored
  value that is not one of the two known looks, MUST be treated as «زمردي وذهبي», without an error message and
  without changing the stored value of anything else. An imported look MUST apply at once; an import that fails
  part way MUST leave everything, the look included, as it was.
- **FR-017**: This feature MUST work fully offline, MUST NOT send any data from the phone, and MUST NOT add any
  new external resource, font, image or data file (so nothing is added to the About credits or to
  `docs/research/licenses.md`).

**Arabic strings (proposed, owner to confirm)**

- **FR-018**: The Settings row and its parts MUST use these Arabic strings: row title «المظهر»; the options
  «زمردي وذهبي» and «القارئ الليلي»; a short note «يُطبَّق على التطبيق كله وعلى الصورة وملف PDF اللذين تشاركهما».
  They are proposals until the owner confirms them (Constitution VI). All other strings of the app are unchanged.

### Key Entities *(include if feature involves data)*

- **Look setting**: one value, which of the two looks the owner chose (default «زمردي وذهبي»). Stored with the
  other settings, exported and imported with them; it has no relation to a wird, a bookmark, the reading position
  or the text size of feature 003.
- **Look (theme)**: the complete set of colours, borders, corner shapes, markers and bar form of one design
  direction, applied to every screen, to the Mushaf page and to the shared picture and PDF. There are exactly two:
  Emerald & Gold (today's) and Night Reader.
- **Page look**: the colours and frame of a drawn Mushaf page in a given look (paper or none, ink, frame or none,
  banner, ayah markers, highlight, background). It never carries any text or layout; the page's lines and words
  are the same in both.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The owner can switch from Emerald & Gold to Night Reader in at most 4 taps from the reader (menu,
  Settings, the choice, back), and every screen they open afterwards is in the Night look, in under 1 second per
  switch and with no restart.
- **SC-002**: In a screen-by-screen review of the 11 screens and sheets named in FR-004, in both looks, 100% are
  in the right look with no bright or ivory block left in Night Reader, no overflow on a 320 dp phone and no
  control smaller than 48 px.
- **SC-003**: With Emerald & Gold chosen, every earlier feature's tests pass unchanged and the screens and the
  page look the same as before this feature (nothing the owner can notice).
- **SC-004**: In both looks, the words, lines and line breaks of all 604 pages are identical to the printed
  Madinah Mushaf 1421H layout and to each other (the existing page checks pass with either look).
- **SC-005**: Every text and icon pair of Night Reader meets the contrast of FR-012 (4.5:1 for ordinary text, 3:1
  for large text, icons and control borders), checked from the look's colour pairs for 100% of them.
- **SC-006**: The saved look is in force from the first frame in 100% of cold starts in a test on the phone, with
  no frame in the other look, and the look survives closing the app, a phone restart and a backup round trip.
- **SC-007**: A page picture and a 48-page surah PDF (Al-Baqarah) made in Night Reader come out in the Night look
  and stay within the limits of feature 002 (picture offered in under 3 seconds, PDF ready in under 60 seconds on
  the owner's phone, the share size limit of that spec), and are no slower than the same job in Emerald & Gold.
- **SC-008**: Turning to the next page in Night Reader shows the new page's text in under 300 ms, as in Emerald
  & Gold (spec 001 SC-007 still holds), and pinch zoom stays smooth, on the owner's phone.

## Assumptions

- The owner is the only user; the look is a personal preference, not per wird or per screen.
- The design canvas's direction B is the source of the Night look. The canvas shows only the reader and the Wirds
  + Today screen; for every other screen the plan derives the look from the same palette and shapes, and the owner
  confirms it on the phone (Constitution IX).
- Both looks are dark, so «follow the phone's dark mode» does not apply, and no light theme is added.
- The Emerald & Gold look and its colours are not changed in any way; its tokens only move behind a common
  interface.
- Wirds colours stay as the owner picked them in the fixed palette; only how their marker is shown in Night
  Reader may be adapted (FR-013).
- Feature 002 (page picture and PDF, `PageLook`) and feature 003 (text size, its Settings preview and reader
  wiring) are being finished by their own sessions; this feature builds on their code after they land and does not
  change their specs. The files they own (the reader's gesture and sizing code) are touched only for colours.
- The status bar and navigation bar icons follow the look's brightness where the app controls them; anything else
  the system draws stays the system's.
- The first frame problem is solved by loading the look together with the other settings before the app starts, as
  feature 003 does for the text size.
