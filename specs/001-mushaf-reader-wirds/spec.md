# Feature Specification: Mushaf Reader, Wirds and Reminders

**Feature Branch**: `001-mushaf-reader-wirds`

**Created**: 2026-11-20

**Status**: Draft

**Input**: User description: "Mushaf reader with multiple wirds, daily portions, bookmarks, local reminders
(wird + al-Kahf on Thursday evening), file backup and an About screen." (full description: see
`docs/speckit-prompts.md`, Feature 1 → specify)

## Clarifications

### Session 2026-11-20

- Q: Should a qiyam portion read after midnight count for the previous night or the new day? → A: Qiyam wirds start their "day" at 04:00 local time; anything before 04:00 counts for the previous night. Reading wirds keep midnight.
- Q: When a wird's goal is changed mid-day, does today's portion change? → A: If today's portion is not done, it is recalculated immediately from its start page; if it is done, the new goal applies from the next wird day. Changing the start page moves the wird's position immediately.
- Q: How are bookmarks organised? → A: One shared list, newest first, each showing its wird's name or «عامة». A bookmark belongs to the active wird when created outside browse mode; in browse mode or with no wird it is «عامة».
- Q: Should reminders keep coming if the app is not opened for a long time? → A: Yes. A daily on-phone background refresh (no server) keeps reminders scheduled indefinitely. Deleting a wird cancels its reminders immediately; tapping a stale one opens the reader at the last viewed page.
- Q: How is the hizb shown in the top bar? → A: «جزء J · حزب H · ربع Q» with hizb 1–60 and quarter 1–4 within the hizb, e.g. «جزء 25 · حزب 49 · ربع 4».

## User Scenarios & Testing *(mandatory)*

One person on their Android phone reads a daily Quran wird, alone. Competing apps forget the last
position, put menus before the Mushaf, or offer no multiple khatmas. This feature delivers the real
Madinah Mushaf opening straight at where the user stopped, several named wirds each with its own
position and daily portion, bookmarks, local reminders, file backup and an About screen.

### User Story 1 - Read the real Mushaf from where I stopped (Priority: P1)

The user opens the app and is immediately on a page of the Madinah Mushaf 1421H, at the position of
their active wird. They turn pages like a paper Mushaf, see where they are (juz, hizb, surah), zoom
in when needed, and jump to any surah, juz or page.

**Why this priority**: The Mushaf is the centre of the product (Constitution II). Without a correct,
complete Mushaf that remembers the position, nothing else has value.

**Independent Test**: Install the app, open it: a Mushaf page appears with no screen before it.
Swipe, jump via the index, close and reopen: the app returns to the right page.

**Acceptance Scenarios**:

1. **Given** a first launch, **When** the app opens, **Then** page 1 is shown directly (no screen
   before it), its first line is the al-Fatiha title and the first word is 1:1:1.
2. **Given** the active wird is at page 50, **When** the app opens, **Then** page 50 is shown.
3. **Given** page 50 is shown, **When** the user swipes with the finger moving left→right,
   **Then** page 51 is shown and the active wird's position becomes 51.
4. **Given** the user picks «الكهف» in the index, **When** the page opens, **Then** page 293 is
   shown, the top bar includes «جزء 15» and «الكهف», the browse banner with «اجعلها موضعي» is
   visible, and the wird's position has not changed.
5. **Given** browse mode on page 293, **When** the user taps «اجعلها موضعي», **Then** the wird's
   position becomes 293 and browse mode ends.
6. **Given** page 1 or 2, **When** it is shown, **Then** its 8 lines are centred horizontally, have
   the same line height as a 15-line page, sit vertically centred, and are not stretched or justified.
7. **Given** any 15-line page, **When** it is shown, **Then** ayah lines are justified edge to edge
   and centred lines stay centred.
8. **Given** the user pinches to zoom, **When** the zoom is above 1×, **Then** the same page layout
   is enlarged (up to 3×) and swiping pages is disabled until zoom returns to 1×.
9. **Given** a page is shown, **When** the user taps it, **Then** the top and bottom bars toggle.

---

### User Story 2 - Keep several wirds with a daily portion (Priority: P2)

The user keeps several named wirds (for example a daily reading wird and a qiyam wird). Each has its
own position and a daily goal. A collapsible «ملخص اليوم» panel above the Mushaf shows today's
portion for every wird and lets them mark it done.

**Why this priority**: Multiple wirds with their own positions is the main gap against the large
competitors and the daily structure the user lives by.

**Independent Test**: Create a qiyam wird with 2 pages per night; it appears labelled «قيام الليل»;
the panel shows a portion for each wird; «تم» marks one done.

**Acceptance Scenarios**:

1. **Given** a first launch, **When** setup runs (even twice), **Then** exactly one wird exists:
   «الورد اليومي», type «قراءة», 20 pages per day, start page 1, reminder on at 20:00, active.
2. **Given** the wirds screen, **When** the user adds a wird of type «قيام الليل» with 2 pages per
   day, **Then** it appears in the list with its colour dot, type label «قيام الليل», «ص: N»,
   bookmark count and khatma count, and its reminder defaults to off.
3. **Given** the type picker, **When** it opens, **Then** «قراءة» and «قيام الليل» are selectable
   and «حفظ» and «مراجعة» are shown disabled with «قريباً».
4. **Given** a wird at page 212 with 5 pages per day and no portion yet today, **When** the panel
   shows it, **Then** the row reads «📖 <name>: من ص 212 إلى ص 216».
5. **Given** that portion, **When** the user presses «تم», **Then** the row shows a tick and the
   wird's position moves to 217 (it was behind).
6. **Given** a wird at page 600 with 20 pages per day, **When** today's portion is computed,
   **Then** it is 600–604; **When** «تم» is pressed, **Then** the khatma count increases by 1 and
   the position becomes page 1.
7. **Given** two wirds, **When** the user swipes pages while one is active, **Then** only that
   wird's position changes.
8. **Given** the wirds list, **When** the user taps a wird, **Then** it becomes active and the
   reader shows its position.
9. **Given** the user deletes a wird, **When** they confirm «حذف الورد؟», **Then** it is removed;
   if it was active, the first remaining wird becomes active; if none remain, the reader opens in
   browse mode at the last viewed page.

---

### User Story 3 - Be reminded of my wird and of al-Kahf on Thursday evening (Priority: P3)

The user gets a daily local reminder for each wird whose reminder is on, and a Thursday-evening reminder (the night of Friday) to
read Surat al-Kahf. Tapping a reminder takes them to the right place in the Mushaf.

**Why this priority**: Reminders turn the wird into a habit, but the app is useful without them.

**Independent Test**: Set a wird reminder 2 minutes ahead, lock the phone, wait: the reminder
arrives and opens that wird. Trigger the al-Kahf reminder: it opens page 293.

**Acceptance Scenarios**:

1. **Given** a wird with reminder on at 20:00 and today's portion not done, **When** 20:00 local
   time arrives, **Then** a notification «ورد: <name>» with body «من ص A إلى ص B» appears, even
   with the screen locked.
2. **Given** today's portion is already done, **When** the reminder time arrives, **Then** no
   notification appears today; the next one is tomorrow.
3. **Given** the reminder time has already passed today when the reminder is set, **Then** the first
   notification is tomorrow.
4. **Given** the user taps a wird notification, **Then** the reader opens on that wird at its
   position, not in browse mode.
5. **Given** the al-Kahf reminder is on (default 21:00), **When** Thursday 21:00 local time arrives,
   **Then** a notification «سورة الكهف» / «ليلة الجمعة: لا تنسَ قراءة سورة الكهف» appears; tapping
   it opens page 293 in browse mode.
6. **Given** notification permission is denied, **When** the user opens settings, **Then** a line
   says so with a button to request it, and the rest of the app works normally.
7. **Given** the phone restarts, **Then** scheduled reminders still arrive.

---

### User Story 4 - Bookmark pages (Priority: P4)

The user marks pages they want to return to, for the active wird, optionally with a note.

**Why this priority**: Useful but secondary to reading and the daily wird.

**Independent Test**: Add a bookmark on page 77, go to page 10, tap the bookmark: page 77 opens in
browse mode.

**Acceptance Scenarios**:

1. **Given** page 77 is shown outside browse mode, **When** the user adds a bookmark with an optional
   note, **Then** it appears at the top of «علامات» with the active wird's name; added in browse mode,
   it appears labelled «عامة».
2. **Given** the bookmark list, **When** the user taps a bookmark, **Then** its page opens in browse
   mode without moving the wird's position.
3. **Given** the bookmark list, **When** the user swipes a bookmark away, **Then** it is deleted.

---

### User Story 5 - Back up my data and see the credits (Priority: P5)

The user exports all their data to a file and can restore it later. An About screen credits every
source and states that the Quran text was not modified.

**Why this priority**: Protects the user's progress (there is no server) and fulfils the
attribution duty (Constitution V).

**Independent Test**: Export, change data, import the file: everything is exactly as at export.

**Acceptance Scenarios**:

1. **Given** user data exists, **When** the user exports, **Then** a single file
   «mushaf-backup-YYYY-MM-DD.json» (today's date) with all wirds, daily portions, bookmarks and
   settings is offered for sharing.
2. **Given** a valid backup file, **When** the user imports it and confirms
   «سيُستبدل كل ما في التطبيق. متابعة؟», **Then** all user data is replaced at once by the file's
   content.
3. **Given** a file from another app or from a newer backup version, **When** the user imports it,
   **Then** it is rejected with a message and nothing changes.
4. **Given** the About screen, **Then** it credits Tanzil (metadata), QUL by Tarteel (page layout
   and word data), King Fahd Glorious Quran Printing Complex (QCF V2 1421H fonts), and the Amiri Quran,
   Reem Kufi and Cairo fonts (SIL OFL), and shows «النص القرآني لم يُعدَّل».

---

### Edge Cases

- Pages 1–2: centred, not stretched, not justified (US1 scenario 6).
- A portion reaching page 604 completes the khatma and restarts at page 1 (US2 scenario 6).
- Day rollover while the app is open or closed, and a phone timezone change: today's portion is keyed
  by the wird day (FR-028: local date for reading, 04:00 boundary for qiyam) and is recreated on
  the next wird day from the wird's position then; it is never reused from the previous day.
- Target date today or in the past: the daily amount is "all remaining pages today" (e.g. current
  page 600 → 5 pages), never zero, negative or an error.
- Deleting the active wird / every wird: no crash; fallback as in US2 scenario 9.
- A page number outside 1–604 (index field or stored data) is rejected; the reader never shows a
  non-existent page.
- Small screens (360×640 and 412×915 logical points): every page renders with no overflow and every
  word visible.
- Airplane mode: no behaviour changes.
- Browse mode while paging: paging in browse mode does not move any wird's position and does not
  complete a portion.

## Requirements *(mandatory)*

### Functional Requirements

**Mushaf content**

- **FR-001**: The app MUST display the Madinah Mushaf 1421H, riwayat Hafs: 604 pages, 15 lines per
  page except pages 1–2 (8 lines), with the same words on the same lines as the printed Mushaf;
  114 surahs, 6,236 ayahs, 83,668 words.
- **FR-002**: Every word MUST appear exactly once, in order, across the 604 pages; the bundled data
  MUST be validated against these counts before it is shipped, and a failed validation MUST stop
  the build (Constitution I).
- **FR-003**: Surah title lines MUST show «سورة <name>» in a bordered box; basmallah lines MUST
  show «بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ».
- **FR-004**: On 15-line pages, ayah lines MUST be justified edge to edge and centred lines MUST stay
  centred. On pages 1–2 the 8 lines MUST be centred, use the same line height as a 15-line page, and
  sit vertically centred.
- **FR-005**: The page number MUST be centred at the bottom of each page.
- **FR-006**: Each word on a page MUST be an individually addressable element that can later be
  hidden (keeping its space) or highlighted.
- **FR-007**: Reference values MUST hold: al-Kahf starts on page 293; 2:255 is on page 42; page 604
  is in juz 30.

**Reader**

- **FR-008**: The app MUST open directly on the Mushaf page of the active wird at its position, with
  no screen before it.
- **FR-008a**: While a page's Mushaf font is not yet available, the page MUST keep its layout area
  empty with the page number visible and show the text as soon as the font is ready; it MUST NOT
  show the text in a substitute font.
- **FR-009**: Swiping with the finger moving left→right MUST show the next page; right→left MUST
  show the previous page.
- **FR-010**: A tap on the page MUST toggle a top bar and a bottom bar.
- **FR-011**: The top bar MUST show «جزء J · حزب H · ربع Q» for the page (J = juz 1–30, H = hizb 1–60,
  Q = quarter 1–4 within that hizb, e.g. «جزء 25 · حزب 49 · ربع 4»), the surah name(s) on the page,
  the active wird's name, and in browse mode a banner with «اجعلها موضعي».
- **FR-012**: The bottom bar MUST show «استماع» (disabled, «قريباً»), «علامات», «أوراد», «اختبار»
  (disabled, «قريباً») and «☰» (settings).
- **FR-013**: Pinch-zoom MUST enlarge the same page layout up to 3×; page swiping MUST be disabled
  while zoomed above 1×.
- **FR-014**: An index MUST offer three tabs: «السور» (surah name and start page), «الأجزاء» (juz and
  its first page), and a page-number field accepting only 1–604.

**Position rules**

- **FR-015**: Swiping pages while not in browse mode MUST set the active wird's position to the
  shown page.
- **FR-016**: Jumping from the index, a bookmark or a notification payload of type "page" MUST enter
  browse mode and MUST NOT move any wird's position.
- **FR-017**: «اجعلها موضعي» MUST set the active wird's position to the shown page and end browse mode.
- **FR-018**: Each wird MUST keep its own position; changing one MUST NOT change another.
- **FR-019**: The last viewed page MUST be remembered across restarts.
- **FR-020**: Deleting the active wird MUST make the first remaining wird in list order (as shown on
  the wirds screen) active; deleting every wird
  MUST open the reader in browse mode at the last viewed page; neither MAY crash.

**Wirds**

- **FR-021**: Users MUST be able to add, edit and delete any number of wirds, including several of
  the same type. Each wird has: name, type, current position (page 1–604), optional daily goal,
  reminder on/off and time, colour, khatma count.
- **FR-022**: Types «قراءة» and «قيام الليل» MUST be selectable and walk through the Mushaf in
  order; «حفظ» and «مراجعة» MUST be visible but disabled with «قريباً».
- **FR-023**: The daily amount MUST be: pages per day if set (it wins over a target date); else
  ceil(remaining ÷ days left) for a target date, where remaining = 604 − current page + 1 and days
  left = days from today to the target date inclusive, minimum 1; else 20 pages per day.
  Example: page 1 on 2026-11-20 with target 2026-12-19 → 21 pages per day.
- **FR-024**: First launch MUST create exactly one active wird «الورد اليومي» (type «قراءة», 20 pages
  per day, page 1, reminder on at 20:00); running first-launch setup again MUST NOT create another.
- **FR-025**: A new wird's reminder MUST default to on for «قراءة» and off for «قيام الليل».
- **FR-026**: The wirds screen («أوراد») MUST list each wird with name, colour dot, type label,
  «ص: N», bookmark count and khatma count; tapping a wird MUST make it active and show it in the
  reader; deleting MUST ask «حذف الورد؟».
- **FR-027**: The wird form MUST offer: name, type, start page, amount (pages per day or target
  date), reminder on/off and time, colour.

**Today's portion**

- **FR-028**: Each wird MUST have at most one portion per wird day, from page A (the wird's position
  when that day's portion is first needed) to page B = min(A + daily amount − 1, 604). A wird day is
  the phone's local calendar date for «قراءة» wirds; for «قيام الليل» wirds it starts at 04:00 local
  time, so 00:00–03:59 belongs to the previous night (e.g. 01:00 on 21 Nov counts for 20 Nov).
- **FR-029**: A day's portion MUST stay the same for the rest of that wird day and MUST be created
  anew on the next wird day, following the phone's current local time including after a timezone
  change, whether the app was open or closed. Exception: when the user edits the wird's goal and
  today's portion is not done, B MUST be recalculated immediately (A unchanged); if today's portion is
  done, the new goal applies from the next wird day. Editing the start page MUST set the wird's
  position to it immediately; an open portion is then recreated from the new position.
- **FR-030**: A portion MUST count as done when the user presses «تم» or the wird's position has
  passed page B.
- **FR-031**: «تم» MUST mark today's portion done and, if the wird's position is at or before B, move
  it to the page after B; after page 604 this completes the khatma: khatma count + 1 and position 1.
- **FR-032**: A collapsible «ملخص اليوم» card MUST show one row per reading and qiyam wird: its
  name, its colour, «من ص A إلى ص B», and either a «تم» button or a tick once done. It opens over the
  Mushaf from a small «ملخص اليوم» chip in the top bar (showing how many portions are done, e.g.
  «1/2») and does not move the page; it is closed on first launch and its open/closed state is
  remembered. The same card also heads the wirds screen.

**Bookmarks**

- **FR-033**: Users MUST be able to add a bookmark on the current page with an optional note. It
  belongs to the active wird when created outside browse mode; in browse mode or when no wird exists
  it is a general bookmark labelled «عامة». «علامات» MUST show one shared list of all bookmarks,
  newest first, each with its page, note and wird name (or «عامة»); tapping one opens its page in
  browse mode; swiping deletes it. A wird's bookmark count counts the bookmarks belonging to it.

**Reminders**

- **FR-034**: For each wird with its reminder on, the phone MUST show one local notification per day
  at the chosen local time, titled «ورد: <name>» with body «من ص A إلى ص B»; no notification MAY
  appear for a day whose portion is already done or whose time has already passed.
- **FR-035**: Tapping a wird notification MUST open the reader on that wird at its position, not in
  browse mode. Deleting a wird MUST cancel its scheduled reminders immediately; if a notification for
  a deleted wird is still tapped, the reader MUST open in browse mode at the last viewed page.
- **FR-036**: An al-Kahf notification MUST appear every Thursday (the night of Friday) at the chosen
  local time (default 21:00), titled «سورة الكهف» with body «ليلة الجمعة: لا تنسَ قراءة سورة الكهف»; tapping it
  MUST open page 293 in browse mode. Users MUST be able to change its time or switch it off.
- **FR-037**: Reminders MUST arrive with the screen locked and after a phone restart, and MUST be
  produced by the phone itself (no server). They MUST keep arriving indefinitely even if the app is
  never opened: the phone refreshes the schedule at least once a day in the background, as well as on
  app start, resume and any change to wirds or settings.
- **FR-038**: Settings MUST offer: al-Kahf reminder on/off and time; when notification permission is
  denied, a line saying so and a button to request it; a link to About; export and import.

**Backup and About**

- **FR-039**: Export MUST write all user data (wirds, daily portions, bookmarks, settings) to one file
  named «mushaf-backup-YYYY-MM-DD.json» and offer it for sharing.
- **FR-040**: Import MUST ask «سيُستبدل كل ما في التطبيق. متابعة؟» and then replace all user data at
  once; a file from another app or a newer backup version MUST be rejected with nothing changed; a
  failed import MUST leave existing data intact.
- **FR-041**: The About screen MUST credit Tanzil (metadata), QUL by Tarteel (page layout and word
  data), King Fahd Glorious Quran Printing Complex (QCF V2 1421H fonts), and the Amiri Quran, Reem Kufi
  and Cairo fonts (SIL OFL), and show «النص القرآني لم يُعدَّل».
- **FR-042**: Before this feature ships, the licence of each bundled resource (QCF V2 1421H fonts, QUL
  page layout and word data, Tanzil metadata, Amiri Quran, Reem Kufi, Cairo) MUST be recorded in
  `docs/research/licenses.md` (Constitution V). Because QUL publishes no copyright information for
  the QCF V2 layout, word data and fonts (which originate from the King Fahd Complex), they MUST be
  recorded there as "no licence published; used in a private, non-commercial APK with visible
  attribution and no modification" (owner decision, 2026-11-20). Publishing beyond the private APK
  (e.g. Google Play) MUST first resolve this licence.

**General**

- **FR-043**: The whole UI MUST be Arabic and right-to-left.
- **FR-044**: The feature MUST work fully offline and MUST NOT make any network access.

### Key Entities

- **Mushaf page**: one of 604 pages; ordered lines; juz, hizb and quarter of the page; the surahs it
  contains.
- **Line**: number on its page; kind (ayah, surah title, basmallah); centred or justified; for ayah
  lines, the ordered words.
- **Word**: unique number (1–83,668); its location (surah:ayah:word); the glyph shown.
- **Surah**: number, Arabic name, ayah count, start page.
- **Wird**: name, type (reading, qiyam; hifz and review reserved), current page, daily goal (pages
  per day or target date), reminder on/off and time, colour, khatma count, order.
- **Daily portion**: belongs to a wird and a wird day (FR-028); start page, end page, done.
- **Bookmark**: page, optional wird, optional note, creation time.
- **Settings**: active wird, last viewed page, al-Kahf reminder on/off and time.
- **Backup file**: app identifier, backup version, export time, and all wirds, daily portions,
  bookmarks and settings.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Opening the app shows a Mushaf page with no screen before it, at the active wird's
  position, every time (including after restarts).
- **SC-002**: All 604 pages show every one of the 83,668 words exactly once and in order, with no
  overflow on 360×640 and 412×915 screens.
- **SC-003**: A user can create a qiyam wird with 2 pages per night in under 1 minute, see it labelled
  «قيام الليل», and see today's portion for every wird in the panel.
- **SC-004**: A wird reminder set 2 minutes ahead arrives with the phone locked and opens that wird;
  the al-Kahf notification opens page 293.
- **SC-005**: Export followed by import restores exactly the same wirds, portions, bookmarks and
  settings (100% field equality).
- **SC-006**: No network access happens at any point; airplane mode changes nothing.
- **SC-007**: Turning to the next page feels immediate: the new page's text is visible in under 300 ms
  on a mid-range phone.

## Assumptions

- Position rules, defaults (20 pages per day, 20:00 reminder, Thursday 21:00 al-Kahf, reminder on/off by type)
  are designer decisions and may change later.
- Restricting a qiyam wird to memorised pages comes with the hifz feature.
- "Done by paging past B" counts only paging outside browse mode, since browse mode never moves the
  wird.
- Bookmarks remain listed if their wird is deleted (shown as «عامة»).
- The device runs a reasonably recent Android version; one user per phone.
- Page-turn speed target (SC-007) is a reasonable default for a reading app, not stated by the user.
