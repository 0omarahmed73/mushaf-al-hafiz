# Feature Specification: Khatm Dua After the Last Page

**Feature Branch**: `005-khatm-dua` (work stays on `main`, as for features 001 to 004)

**Created**: 2026-11-20

**Status**: Draft

**Input**: User description: "I wanna add دعاء ختم القرآن after the user finish reading the last page, and after
finishing the duaa it takes him back to page 1." Constitution 1.2.0 (commit 220945e, approved by the owner on
2026-11-20) allows exactly this one supplication; Principle III still forbids every other dua, adhkar and hadith.

## Clarifications

### Session 2026-11-20

- Q: The constitution forbade duas (Principle III). May it be amended for this one? → A: Yes, an exception for
  «دعاء ختم القرآن» only: one supplication after the last page, no dua section. Done in constitution 1.2.0.
- Q: When does the dua appear after the last page (604)? → A: On the forward swipe from page 604, the same
  gesture that turns a page. Not on a "تم" of a wird, and no extra button.
- Q: Who decides the wording? There is no fixed authentic text from the Prophet ﷺ. → A: The customary wording,
  taken from a named source and shown to the owner, who confirms it word by word before the feature is done.
  Research found one widely circulated wording with no book, narrator or grading behind it (see Assumptions).
- Q: What happens when the dua is finished? → A: A button «آمين» takes the reader to page 1; going back leaves
  the reader on page 604. The khatma counts of the wirds are not changed by this screen.
- Q: What counts as «the forward swipe»: a slow drag, a fling, a small accidental touch? → A: A deliberate drag of
  at least 48 px, or a flick of at least 16 px released at 300 px/s or more; a smaller touch does nothing. The
  numbers are a little stricter than the pager's own page-turn rule on purpose, because turning to the next page
  costs nothing while opening a screen does, and they are tuned on the phone. (Default recorded, not asked.)
- Q: What if page 604 is zoomed in? → A: The page pans and the dua does not open; the reader resets the zoom
  first. (Default recorded, not asked.)
- Q: Where does «آمين» sit? → A: It is the last item of the scrolling content, under the dua, so it is visible at
  once when the dua fits and one scroll away when it does not. It is not pinned to the screen edge, so a large
  font never hides text behind it. (Default recorded, not asked.)
- Q: How does «آمين» treat browse mode and an active wird? → A: Showing page 1 is an ordinary page change: in browse
  mode the last viewed page becomes 1; when the reader follows a wird, that wird's position becomes 1 exactly as
  a swipe to page 1 would, and its khatma count is changed only by «تم». The dua screen itself writes nothing
  else. (Default recorded, not asked.)
- Q: What if the dua text cannot be read? → A: The screen still opens with the title, the label, a short Arabic
  message in place of the text, and a working «آمين» and back. (Default recorded, not asked.)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Finish the Quran, read the dua, start again from page 1 (Priority: P1)

The reader turns the pages until the last one, page 604, and reads it. They swipe forward once more, as they would
to turn to the next page. Instead of nothing happening, a quiet screen opens with the title «دعاء ختم القرآن», a
line under it saying that this is a supplication and not part of the Quran text, and the dua. They read it,
scrolling if it is long, and tap «آمين» at the end. The screen closes and the Mushaf shows page 1, ready for the
next khatma. If they close the app and open it the next day, it opens on page 1.

**Why this priority**: This is the whole request. Without it the end of the Mushaf is a dead end.

**Independent Test**: With a test reader on page 604, a forward swipe opens the dua screen; tapping «آمين» shows
page 1 and the saved position is page 1. With the reader on any of pages 1 to 603, the same swipe only turns the
page.

**Acceptance Scenarios**:

1. **Given** the reader shows page 604 not zoomed in, **When** the reader swipes forward, **Then** the dua
   screen opens over the Mushaf.
2. **Given** the dua screen is open, **When** the reader taps «آمين», **Then** the screen closes and page 1 is
   shown at once, without turning through the pages in between, and the saved position is page 1.
3. **Given** the reader tapped «آمين» and closes and reopens the app, **When** the app opens, **Then** it shows
   page 1.
4. **Given** the reader is on page 603 or any earlier page, **When** the reader swipes forward, **Then** the next
   page is shown as today and no dua opens.

---

### User Story 2 - Leave the dua without finishing it (Priority: P2)

The reader opened the dua by a swipe but wants to stay on page 604 (they swiped by mistake, or want to read the
page again). They go back, with the back arrow or the phone's back gesture, and are on page 604 exactly as they
left it. If they swipe forward again later, the dua opens again.

**Why this priority**: The dua must never trap the reader or move them without being asked. It follows the main
flow because the main flow works without it, but a missing way out would be a defect.

**Independent Test**: Open the dua from page 604, go back with each of the two controls, and check the page shown
and the saved position are still 604; swipe forward again and check the dua opens again.

**Acceptance Scenarios**:

1. **Given** the dua screen is open, **When** the reader taps the back arrow, **Then** the screen closes and page
   604 is shown, and the saved position is page 604.
2. **Given** the dua screen is open, **When** the reader uses the phone's back gesture or button, **Then** the same
   happens.
3. **Given** the reader came back to page 604, **When** the reader swipes forward again, **Then** the dua opens
   again.

---

### User Story 3 - A dua that is clearly not the Quran and is comfortable to read (Priority: P2)

The dua is a human supplication, not the words of Allah in the Mushaf, and it must never be mistaken for them. It
is set in the interface font, never in the Mushaf's script, with a label under the title saying so. It follows the
reading text size the reader chose in Settings, scrolls when it does not fit, and wears whichever look the reader
chose, «زمردي وذهبي» or «القارئ الليلي», with readable contrast, large enough touch targets, and no overflow on a
small phone or a large system font. A screen reader announces the title as a heading and «آمين» as a button.

**Why this priority**: Constitution Principle I (the Quran text is never confused with anything else) and the
quality bars of the earlier features apply to every new screen.

**Independent Test**: Open the dua in both looks, at the three reading sizes, on a 320 dp wide window with a 2x
system font: nothing overflows, every text meets its contrast, «آمين» can be reached, the text uses the interface
font and not the Quran font, and the label is present.

**Acceptance Scenarios**:

1. **Given** the dua screen is open, **When** the reader looks at it, **Then** it shows the title, the label
   «دعاء وليس من نص القرآن» under the title, the dua and «آمين», and no Quran word is repeated on it.
2. **Given** the reader chose a larger reading size in Settings, **When** the dua opens, **Then** its text is at
   that size.
3. **Given** the dua is longer than the screen, **When** the reader scrolls, **Then** all of it can be read and
   «آمين» can be reached.
4. **Given** either look is chosen, **When** the dua opens, **Then** it is in that look's colours and shapes.

---

### User Story 4 - The wording is the owner's, and its source is told honestly (Priority: P3)

There is no fixed authentic text from the Prophet ﷺ for the dua at the end of the Quran, so the app uses the
customary wording found at the end of many mushafs. The owner reads the proposed wording word by word and confirms
it (or replaces it) before the feature is called done. «حول التطبيق» names where the wording came from and says
plainly that it is the customary wording and not a fixed text from the Prophet ﷺ.

**Why this priority**: It does not change how the feature works, but Constitution Principles V and VI forbid
calling the feature done without it.

**Independent Test**: The bundled wording equals the text the owner confirmed, character for character, and the
About screen and the licences record name its source and say that it is customary.

**Acceptance Scenarios**:

1. **Given** the owner confirmed the wording, **When** the dua screen is shown, **Then** it displays exactly that
   text, with nothing added, removed or reordered.
2. **Given** the reader opens «حول التطبيق», **When** they read the credits, **Then** a line names the source of
   the dua's wording and says it is the customary wording with no fixed text from the Prophet ﷺ.

---

### Edge Cases

- The reader zooms in on page 604 (pinch) and then drags sideways: the page pans and no dua opens; the dua can be
  opened only from a page that is not zoomed in.
- The reader swipes forward on page 604 twice in quick succession, or flings: exactly one dua screen opens.
- The reader jumps to page 604 from the index, from go-to-page, from a bookmark, from a wird or from a
  notification: page 604 is shown as any page and the dua does not open until the reader swipes forward.
- The reader reaches page 604 by turning pages and does nothing: the dua does not open by itself.
- The phone is rotated, or the app goes to the background and comes back, while the dua is open: the dua is still
  open and the reader's place on it is kept.
- The app is closed or killed while the dua is open: the next start shows page 604 (the position was never
  changed), not the dua.
- The reader is in browse mode (jumped here) or follows a wird: «آمين» shows page 1 and the position becomes page 1
  by the same rule as any page change; opening the dua alone changes no position.
- A backup is exported or imported: the dua has no data of its own, so nothing changes.
- The dua text file is missing or unreadable (a broken build): the dua screen shows the title, the label and a
  short Arabic message instead of the text, and «آمين» and back still work.
- The system text scale is very large: the text scrolls and «آمين» is still reachable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A forward swipe on page 604, the gesture that on any other page turns to the next page (the finger
  moving left to right, as on paper, Constitution VI), while the page is not zoomed in, MUST open the dua
  screen (a page wider than the screen because of the reading size is not zoomed in: it opens the dua through
  its edge turn). A drag counts when its forward travel is at least 48 px, or at least 16 px with a release speed of at
  least 300 px/s (values tuned on the phone, research D2); anything smaller MUST do nothing.
- **FR-002**: Nothing else MUST open the dua. Reaching page 604 by turning pages, from the index, by go-to-page,
  from a bookmark, from a wird, from a notification or by restarting the app MUST NOT open it, and a forward swipe
  on any of pages 1 to 603 MUST only turn the page as it does today.
- **FR-003**: Only one dua screen MUST be open at a time, however many swipes or flings arrive.
- **FR-004**: While page 604 is zoomed in, a sideways drag MUST pan the page and MUST NOT open the dua.
- **FR-005**: No button, banner, hint or other control MUST be added to the reader for this feature.
- **FR-006**: Tapping «آمين» MUST close the dua screen and show page 1 at once, without turning through the pages
  between, and the reading position MUST become page 1 by the same rule as any page change today (the active wird's
  position when the reader follows a wird, the last viewed page in browse mode), so the next start opens on
  page 1.
- **FR-007**: Going back, with the back arrow or the phone's back gesture or button, MUST close the dua screen and
  leave the reader on page 604 with the saved position unchanged; a later forward swipe MUST open the dua again.
- **FR-008**: Opening or finishing the dua MUST NOT change the khatma count of any wird, today's portions or their
  done marks, bookmarks, reminders or settings. The only stored change is the position of FR-006.
- **FR-009**: The dua screen MUST show the title «دعاء ختم القرآن», directly under it the label «دعاء وليس من نص
  القرآن», then the dua, then the button «آمين». The owner confirmed these Arabic strings on 2026-11-21
  (Constitution VI).
- **FR-010**: The dua MUST be set in the interface font and MUST NOT be set in the Quran font, and it MUST NOT appear
  inside the Mushaf page. The wording the owner confirmed on 2026-11-21 quotes the verse 2:201 and uses words that
  also occur in the Quran (no sentence of the Quran text is shown apart from the supplication); they stay part of the
  supplication, in the interface font, under the label of FR-009. (Amended on 2026-11-21: the first draft said the
  screen must repeat no Quran word, which no real supplication can meet.)
- **FR-011**: The dua text MUST follow the reading text size chosen in Settings and the system text scale with the
  cap that applies to the other reading texts; a text longer than the screen MUST scroll, and «آمين» MUST be the
  last item of the scrolling content, under the dua, so it is reachable at every screen size and text size.
- **FR-012**: The screen MUST be in the look the reader chose (Emerald & Gold or Night Reader), right to left, with
  text contrast of at least 4.5:1 (3:1 for large text and icons), touch targets of at least 48 px, and nothing
  overflowing on a 320 dp wide window with a 2x system font.
- **FR-013**: For a screen reader the title MUST be a heading, «آمين» a labelled button, the back arrow a button
  labelled «رجوع», and the text MUST be read in order.
- **FR-014**: A rotation or a trip of the app to the background MUST keep the dua screen open as it was. A restart
  of the app MUST NOT restore it: the reader opens on the saved position.
- **FR-015**: The dua's wording MUST live in one bundled text file and the screen MUST show it exactly, with
  nothing added, removed, trimmed or reordered. The app MUST contain exactly one dua and no list, section or
  collection of duas, adhkar or hadith (Constitution III).
- **FR-016**: Before the feature is called done the owner MUST confirm the wording word by word. The source of the
  wording MUST be named in `docs/research/licenses.md` and credited in «حول التطبيق», and the credit MUST say that
  the wording is the customary one and that there is no fixed text from the Prophet ﷺ (Constitution V, VI).
- **FR-017**: The feature MUST work fully offline, send nothing off the device and track nothing (Constitution IV).
- **FR-018**: The Quran text, the 15-line layout, the page geometry and the way a swipe turns pages 1 to 604 MUST
  NOT change, and the tests of the earlier features MUST pass unchanged (Constitution I, II).
- **FR-019**: If the dua text cannot be read, the screen MUST still open with the title, the label, a short Arabic
  message and a working «آمين» and back.

### Key Entities

- **Khatm dua**: the one supplication of the app: its title, its label, its wording (one bundled text) and the
  line naming the source of the wording. It has no state; it is the same every time.
- **Reading position**: already in the app (the active wird's position, or the last viewed page in browse mode).
  This feature changes it only when «آمين» shows page 1 (FR-006).
- **Last page**: page 604, the page the forward swipe leaves from.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On page 604 not zoomed in, 100% of forward swipes open the dua; on each of pages 1 to 603 none
  does. Nothing else opens it (jumps, bookmarks, wirds, notifications, restart).
- **SC-002**: After «آمين», the reader is on page 1 in 100% of tries, and after a restart the app opens on page 1.
  After going back instead, the reader is on page 604 and after a restart the app opens on page 604.
- **SC-003**: The dua opens within 1 second of the swipe on the owner's phone, and showing page 1 after «آمين»
  takes under 1 second.
- **SC-004**: Opening and finishing the dua changes no khatma count, no portion, no bookmark, no reminder and no
  setting (the only stored change is the position of FR-006), checked for a reader with a wird and one without.
- **SC-005**: In both looks, at the three reading sizes and with a 2x system font on a 320 dp window, 0 overflows,
  every text meets its contrast and every control is at least 48 px, with «آمين» reachable.
- **SC-006**: The wording shown equals the bundled text and the bundled text equals the owner-confirmed text,
  character for character, and no Quran word appears on the screen.
- **SC-007**: All tests of the earlier features pass unchanged, and the Mushaf pages are drawn exactly as before
  (same line boxes and word order on the sampled pages).
- **SC-008**: The owner, trying it on the phone, finds the dua opens only on the forward swipe from the last page
  and that going back never moves them.

## Assumptions

- «Forward swipe» is the pager being pulled past its last page; a fling counts as well as a slow drag, and a tiny
  accidental drag does not. The distances are fixed in the plan and tuned on the phone.
- The dua opens only from a page that is not zoomed in (FR-004); the reader resets the zoom first. This is the
  simplest rule that keeps a zoomed page's panning safe.
- «آمين» showing page 1 follows the ordinary rule for a page change (FR-006). With an active wird this moves the
  wird's position to page 1 as any swipe to page 1 would; the khatma count of the wird is changed only by «تم», as
  today, so the dua cannot count a khatma twice.
- **Confirmed on 2026-11-21 (FR-016):** the owner replaced the proposal below with their own longer wording (eleven
  paragraphs, from «اللهم ارحمني بالقرآن» to «وسلم تسليماً كثيراً»), kept its diacritics as written and the sign ۞ at
  the end of each paragraph but the last, and chose the shorter credit sentence «لا يوجد نص ثابت عن النبي ﷺ؛ الصياغة
  متداولة». The exact text is `assets/khatm/dua.txt`. The owner has not named where the added paragraphs come from;
  that stays open in `docs/research/licenses.md`.
- Original wording proposal (replaced, kept here for the record): the customary text that opens «اللهم ارحمني بالقرآن،
  واجعله لي إماماً ونوراً وهدىً ورحمة، اللهم ذكرني منه ما نسيت، وعلمني منه ما جهلت، وارزقني تلاوته آناء الليل
  وأطراف النهار، واجعله لي حجة يا رب العالمين». It is printed at the end of many mushafs and listed first on
  mawdoo3.com «دعاء ختم القرآن» (updated 2024-08-06) and again on albayan.ae (2024-04-08). No page gives a book,
  a narrator or a grading for it, and none ties it to the Madinah Mushaf of the King Fahd Complex; those pages say
  there is no fixed text from the Prophet ﷺ. The owner may extend it, shorten it or replace it with another
  customary wording from a named source; changing it touches only the one text file.
- The source line to record is «الدعاء المتعارف عليه في ختام المصاحف، ولا يوجد نص ثابت عن النبي ﷺ»; the sites above
  are where the wording was found, not an authority for it. The owner confirms this line too.
- There is no translation, no audio and no sharing of the dua in this feature.
- Feature 004 (the Night Reader look) is being built at the same time: this screen uses the look tokens from its
  first version, and the files both features touch (the reader screen) are edited one feature after the other.
