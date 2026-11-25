# Feature Specification: Large Ayah Mode

**Feature Branch**: `015-large-ayah-mode` (work stays on `main`, as for features 001 to 013)

**Created**: 2026-11-25

**Status**: Implemented and checked on the owner's phone (2026-11-26). Constitution 2.2.0; tasks T001 to T031 done,
convergence tasks T032 to T035; see "Convergence 2026-11-26" below

**Input**: User description (owner, Egyptian Arabic): «يبقى في مود لكبار السن بحيث ان الاية تبقى حجمها كبير وكل اية في
صفحة او كل ايتين, ممكن نعملها انه يختار الصفحة فيها كام اية» — "a mode for elderly readers where the ayah is large and each
ayah is on its own screen, or every two ayat; we could let the reader choose how many ayat a screen holds".

## Study (2026-11-25)

What the app has today, and what it means for this mode:

- **The Mushaf page** (feature 001) draws each of the 604 pages from the per-page QCF V2 fonts (`assets/fonts/qpc-v2`,
  one font per page, 153 MB) and the QUL layout data (`assets/mushaf/pages`). Every word is one glyph of its page's font,
  and the last word of each ayah is its end marker. The page geometry is fixed: 15 lines, the same words on each line.
- **The reading size** (feature 003, `TextSize`, 80 % to 150 %) scales the whole page and the reading texts of the ayah
  menu. At 150 % a page line is still a page line: on a phone the words stay small for a weak eye, and a larger page no
  longer fits the screen. It cannot give one ayah per screen.
- **No ayah crosses a page in this edition** (checked over the 604 page files in feature 013: 2:282 fills page 48 alone).
  So every ayah's words are glyphs of one page font, and every ayah belongs to exactly one page.
- **Ayah lengths**: 6,236 ayat, from 1 word to 128 words (2:282); 534 ayat have more than 25 words and 99 more than 40.
  At a size that suits a weak eye (about 5 to 7 words a line on a phone), 2:282 needs about 20 lines and cannot fit one
  screen. Long ayat are a real case, not a corner.
- **A second text exists**: `assets/ayah/text` holds every ayah word by word as Unicode text (QUL «KFGQPC Hafs script»),
  used for sharing and search. The bundled Amiri Quran font (148 KB, SIL OFL) draws the basmala line today. Drawing ayat
  in Amiri from that text would be a different calligraphy from the Madinah print, and the KFGQPC text uses marks made
  for the KFGQPC Hafs font; whether Amiri draws every one of them correctly is not proven.
- **Position, wirds and bookmarks are page-based** (`currentPage`, portions by `startPage`/`endPage`, page bookmarks);
  ayah bookmarks and notes (feature 013) and the ayah long-press sheet (feature 002) work by ayah.
- **Looks** (feature 004): Emerald & Gold and Night; the ayah bookmark tint (feature 013) has its own switch.

### Constitution

The mode touches two principles. The owner chose an amendment, now constitution 2.2.0 (Clarifications, FR-001).

- **Principle I** says the distribution of the text "on pages and lines MUST never be modified". The mode changes no
  stored data and no word, but it shows an ayah's words on new lines that are not the Mushaf's lines.
- **Principle II** says the app "MUST open directly on a Mushaf page" and every feature starts from it and returns to it.
  If the mode stays on after the app is closed (FR-006), the app would open on ayah screens, not on a Mushaf page.

## Clarifications

### Convergence 2026-11-26 (what the documents now say the code does)

- Built and tested: FR-001 to FR-019 in `lib/large_ayah/` with the wiring in `lib/mushaf/reader_screen.dart`,
  `lib/settings/settings_screen.dart`, `lib/wirds/wird_repository.dart`, `lib/app.dart` and `lib/main.dart`;
  `lib/mushaf/mushaf_page.dart` is not edited. The whole-Mushaf check (SC-001) runs in `test/large_ayah/whole_mushaf_test.dart`;
  `flutter analyze` is clean and the whole suite passes (counts in quickstart.md).
- Decisions made during implementation, written in the requirements they touch: FR-007 shows the screen that holds the
  previous first ayah (screens are cut from the page's first ayah); FR-008 keeps the 18 page-end surah titles on their
  page; FR-010 keeps 3 lines in a short box; the «المصحف» button sits at the end of the view's own header line, not in
  the top bar (contracts/ui.md).
- Tasks T024 and T026 added no code: T018's wiring already made T023's and T025's tests pass.
- The owner: chose the amendment, the Madinah glyphs, 1 to 3 ayat and the split of long ayat; approved constitution 2.2.0
  («طبّقه»); confirmed every Arabic string («كلها تمام», T029); had the Google Play build replaced by this release build
  with his backup of 2026-11-25 20:22 («امسح وسطّب», «رجعت»); walked quickstart steps 1 to 10 on the phone, every step
  «أيوه», and found all three sizes comfortable («التلاتة كويسين», SC-006).
- Not done: nothing is pushed (needs his «ارفع»); the Play listing is not updated with this feature, and Play updates do
  not reach the phone until the backup, uninstall and install steps are done the other way round.

### Session 2026-11-25

- Q: Principles I and II: a constitution amendment for a separate large-ayah view, or only a statement in this spec? →
  A: an amendment (MINOR, 2.2.0) («تعديل صغير للدستور»). It allows a separate view that shows the same words in order on
  new lines, changes no stored data, leaves the Mushaf page as it is, and lets the app open on the mode when the reader
  left it on.
- Q: Which script draws the ayat in the mode? → A: the Madinah print's own glyphs, the QCF V2 page fonts the Mushaf
  already uses («خط مصحف المدينة»); Amiri Quran is not used for the ayat.
- Q: Which numbers of ayat per screen are offered, and how is an ayah too long for one screen shown? → A: 1, 2 or 3 ayat
  per screen («١ أو ٢ أو ٣»), 1 by default; a too-long ayah is split into parts on consecutive screens, turned like any
  screen («تتقسم على كذا صفحة»), not scrolled.
- Q (T029, 2026-11-26): are the Arabic strings of contracts/ui.md right («الآيات الكبيرة», «آية أو آيتان أو ثلاث في
  الصفحة، بخط كبير», «عدد الآيات في الصفحة», «آية واحدة», «آيتان», «ثلاث آيات», «حجم الخط», «كبير», «أكبر», «أكبر جدًا»,
  «تتبع ←», «المصحف», «الرجوع إلى المصحف», and the header «البقرة ٢٥٥ · صفحة ٤٢»)? → A: «كلها تمام»; they are confirmed
  as written (Principle VI).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Read one ayah (or a few) at a large size (Priority: P1)

An elderly reader whose eyes cannot follow the Mushaf page on a phone turns on the large ayah mode from the reader. The
screen now shows the ayah where they were, alone (or with the next one or two, as chosen), in large letters that fill
the width. They swipe to the next screen in the same direction as turning a Mushaf page, and read on.

**Why this priority**: it is the whole request; without it there is no feature.

**Independent Test**: open the Mushaf on page 50, turn the mode on, check the first screen shows 3:1 (and the next ayat
if more than one per screen is chosen) at the large size; swipe forward and back and check the ayat follow in order with
none missed or repeated.

**Acceptance Scenarios**:

1. **Given** the Mushaf shows page 50, **When** the reader turns the mode on, **Then** the first screen starts at the
   first ayah of page 50 (after the title of Al Imran and the basmala, which appear at the top of that screen).
2. **Given** the mode is on with N ayat per screen, **When** the reader swipes to the next screen, **Then** it shows the
   next ayat in Mushaf order; the next screen comes in from the left, as a Mushaf page does (Principle VI).
3. **Given** the last screen of a page, **When** the reader swipes forward, **Then** the next screen starts with the first
   ayah of the next page.
4. **Given** the mode is on, **When** the reader turns it off, **Then** the Mushaf opens on the page of the first ayah that
   was on the screen.

---

### User Story 2 - Choose how many ayat a screen holds (Priority: P1)

The reader (or someone setting the phone up for them) chooses how many ayat each screen shows. The choice stays.

**Why this priority**: the owner named it in the request.

**Independent Test**: change the number in the mode's settings and check the screens regroup at once, on the screen that
holds the same first ayah, and that the choice survives a restart.

**Acceptance Scenarios**:

1. **Given** the mode shows 2:5 and 2:6 on one screen, **When** the reader changes the number to 1, **Then** the screen
   shows 2:5 alone.
2. **Given** a choice was made, **When** the app is closed and opened again, **Then** the same number is used.

---

### User Story 3 - Keep everything else working in the mode (Priority: P2)

While in the mode the reader still follows the day's wird, keeps their position, bookmarks an ayah, and opens the ayah
sheet (tafsir, translation, meanings, share, bookmark, note) with a long press, in both looks.

**Why this priority**: without it the mode is a dead end the reader must leave for every action.

**Independent Test**: inside the active wird, swipe through the mode to the next page's ayat and check the wird's
position moved; long-press an ayah and check the same sheet opens for that ayah; check both looks.

**Acceptance Scenarios**:

1. **Given** an active wird at page 10, **When** the reader reads in the mode until the screens show ayat of page 11,
   **Then** the wird's position is page 11, exactly as turning the Mushaf page to 11 would set it.
2. **Given** the mode, **When** the reader long-presses an ayah, **Then** that ayah is highlighted and the ayah sheet opens
   for it, with the same rows as in the Mushaf.
3. **Given** an ayah bookmark on 2:255, **When** its screen is shown, **Then** 2:255 carries the same tint as in the
   Mushaf (when the tint switch is on).
4. **Given** the Night look, **When** the mode is on, **Then** its screens use the Night look's colours.

---

### Edge Cases

- **A long ayah** (2:282, 128 words; 99 ayat over 40 words) does not fit one screen at the large size: it is split into
  parts on consecutive screens (FR-019); no screen scrolls.
- **Several ayat on a screen that would not fit together**: the screen shows fewer ayat rather than shrinking them, and
  the next screen starts at the first ayah not shown (FR-009).
- **The end of a page**: a screen never holds ayat of two pages (FR-008), so the last screen of a page can hold fewer
  ayat than chosen.
- **A surah start**: the surah's title and the basmala (when the surah has one) open its first screen, as on the page;
  At-Tawbah has no basmala.
- **The first and last ayah of the Mushaf**: no screen before 1:1; after the last ayah of An-Nas, a forward swipe does
  what the last page's swipe does today (the khatm supplication, feature 005).
- **A jump** (the index, «اذهب إلى صفحة», a bookmark, a search result, a reminder tap) while in the mode: the mode opens
  on the target page's first ayah, or on the target ayah itself when the jump names one; the browse rules of feature 001
  apply as in the Mushaf.
- **The system font size**: the mode's size is the app's own; the phone's large-text setting does not enlarge it further
  beyond what fits (as the Mushaf page, which another change makes ignore the system size).
- **A small phone** (320 dp wide) and **landscape**: the size fits the width; every word stays whole and on screen.

## Requirements *(mandatory)*

### Functional Requirements

**Constitution**

- **FR-001**: The constitution is amended (2.2.0, 2026-11-25, wording approved by the owner with «طبّقه»: Principle I's
  "Large-ayah view" bullet, Principle II's exception) to allow a separate large-ayah view under Principles I and II:
  it shows the same words of the fixed edition in the same order on new lines, changes no stored Quran data, never
  replaces or alters the Mushaf page, says the Mushaf page number of what it shows, and MAY be where the app opens when
  the reader left it on. The mode MUST NOT change any stored Quran data, and the Mushaf page stays as it is.

**What a screen shows**

- **FR-002**: A screen MUST show whole ayat in Mushaf order, every word of each ayah exactly once and in order, with its
  end-of-ayah marker and number. No word, mark or ayah MAY be dropped, repeated or reordered.
- **FR-003**: The ayat MUST be drawn in the Madinah print's own glyphs: each word is its glyph in its page's QCF V2 font,
  the same one the Mushaf page draws, only larger and on new lines. No other font or text MAY stand in for a word; while a
  page's font is not ready, its screen waits, as the Mushaf page does.
- **FR-004**: The words of an ayah MUST wrap onto as many lines as the size needs, right to left, without breaking a word.
- **FR-005**: A screen MUST say where it is: the surah name, the ayah numbers it shows and the Mushaf page number.

**How many ayat**

- **FR-006**: The reader MUST be able to choose 1, 2 or 3 ayat per screen; 1 is the default. The choice, and whether the
  mode is on, MUST survive restarts (when the mode was on, the app opens on it, by the amendment of FR-001) and MUST travel in the backup file (feature 001's export) like the other settings.
- **FR-007**: Changing the number (or the size, or turning the phone) MUST regroup the screens at once and show the screen
  that holds the first ayah of the screen shown before (for a split ayah, its first part); since screens are cut from the
  page's first ayah (FR-008), that ayah is not always first on its new screen.
- **FR-008**: Screens are made from each page's ayat in order: the first screen of a page starts with its first ayah, and
  no screen holds ayat of two pages. So the Mushaf page of a screen is always one page. A surah title on a page's last
  line (18 pages, e.g. 76 and 584) stays on its page, at the end of that page's last screen (found at implementation,
  research D3).
- **FR-009**: When the chosen number of ayat does not fit a screen at the size, the screen MUST show as many whole ayat as
  fit (at least one), and the next screen MUST start with the next ayah. The size MUST NOT shrink to make them fit.
- **FR-019**: An ayah that does not fit one screen alone MUST be split into parts on consecutive screens, cut only between
  words, each part filling its screen; no other ayah shares those screens. Every part but the last MUST show that the
  ayah goes on (proposed label «تتبع»), and the last part ends with the ayah's end marker. A long press on any part acts on
  the whole ayah (FR-014). The parts are derived from the size and the screen, never stored; turning the phone or changing
  the size cuts again, starting at the first part of the ayah shown.

**Size**

- **FR-010**: The mode MUST have its own text size, larger than the Mushaf page at its largest step; the default is large
  enough that a line holds about 5 to 7 words on a 360 dp phone. The reader MAY choose among a few larger sizes (the
  plan proposes the steps; the Arabic labels are proposals until the owner confirms them). The feature 003 setting does
  not change. A box too short for 3 lines at the chosen size (a phone on its side at the largest step) gets the size
  that holds 3 lines, so a title, a basmala and a line of words always fit (research D2).

**Moving and position**

- **FR-011**: Swiping MUST move one screen forward or back, in the Mushaf's direction (Principle VI).
- **FR-012**: The position and the wirds MUST follow the page of the shown screen with the same rules as turning a Mushaf
  page (feature 001, FR-015 to FR-020): inside the active wird the wird moves to that page; after a jump the mode browses.
  Leaving the mode opens the Mushaf on that page.
- **FR-013**: Turning the mode on MUST start at the first ayah of the Mushaf page shown; a search result opened while in
  the mode MUST open at the screen holding that ayah.

**Everything else**

- **FR-014**: A long press on an ayah MUST open the same ayah sheet as in the Mushaf (feature 002, with feature 013's
  bookmark and note rows) for that ayah. Sharing a page picture shares the Mushaf page of that ayah, as today.
- **FR-015**: Ayah bookmarks MUST be tinted as in the Mushaf (feature 013, with its switch); the page bookmark icon and
  «علامات» MUST act on the page of the shown screen.
- **FR-016**: Both looks (Emerald & Gold, Night) MUST apply to the mode, with the contrast rules of feature 004.
- **FR-017**: The mode MUST be turned on from the reader's menu («القائمة», then the switch at the top of Settings: two
  taps) and off in one tap from the mode («المصحف» in its top bar) or from the same switch; the number of ayat and the
  size are chosen under that switch. The Arabic labels are proposals until the owner confirms them (Principle VI):
  the mode «الآيات الكبيرة», the number «عدد الآيات في الصفحة», the values «آية واحدة», «آيتان», «ثلاث آيات».
- **FR-018**: The mode MUST work fully offline and add no permission and no network use (Principle IV).

### Key Entities

- **Large-ayah setting**: whether the mode is on, the number of ayat per screen, the mode's size step. Stored with the
  other settings and in the backup.
- **Screen** (derived, never stored): one page number, and either a run of 1 to 3 consecutive whole ayat of that page or
  one part of a split ayah (FR-019).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Reading the whole Mushaf screen by screen in the mode shows each of the 6,236 ayat exactly once, in order,
  with each ayah's words in the same order as on its page (checked automatically for 1, 2 and 3 ayat per screen and with long ayat split).
- **SC-002**: On a 360 dp phone at the default size, the letters of the mode are at least twice the height of the Mushaf
  page's letters at 100 %.
- **SC-003**: The reader can turn the mode on from the Mushaf in at most 2 taps, and back.
- **SC-004**: After reading in the mode into the next page of the active wird and closing the app, the app opens on that
  page with the wird's position moved, exactly as if the Mushaf page had been turned.
- **SC-005**: Every ayah, including 2:282, can be read to its last word in the mode on a 320 dp phone by turning screens
  only, without any word cut or off screen and without scrolling.
- **SC-006**: The owner (or an elderly reader he picks) reads a few screens on the phone and says the size is comfortable
  (real-device check, Principle IX).

## Assumptions

- The mode is for Android, as the reader is. The web version (feature 012) is paused; if it resumes, it decides there
  whether to show the mode.
- The mode is a view of the same data and draws the existing QCF V2 fonts; it adds no Quran asset (Principle VIII).
- No audio exists in the app yet; when recitation is added, its feature decides how it follows the mode.
- Pinch zoom is not offered in the mode; the size steps replace it.
- The mode does not replace the Mushaf page as the app's default: a first install opens on the Mushaf; the app opens in
  the mode only when the reader left it on (FR-006).
