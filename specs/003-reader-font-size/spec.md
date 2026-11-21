# Feature Specification: Text Size (Font Size)

**Feature Branch**: `003-reader-font-size` (work stays on `main`, as for features 001 and 002)

**Created**: 2026-11-20

**Status**: Implemented (phone checks T008, T016, T021 still open)

**Input**: User description: "The user can increase or decrease the font size." Decided by the owner on
2026-11-20: it applies to (1) the reading texts inside the ayah menu (tafsir al-Sa'di, the English
translation, the word meanings) and (2) the Mushaf page, where a bigger page keeps the Madinah Mushaf
1421H layout exactly and scrolls up and down inside the pager like the landscape layout; pinch zoom stays.
The control is one slider in Settings, with a live preview. Not in scope: the app's other text (lists,
settings, top and bottom bars). Default size = today's look.

## Clarifications

### Session 2026-11-20

- Q: Which text can be made bigger or smaller? → A: The tafsir, translation and word-meaning texts, and the
  Mushaf page. Not the rest of the app's text.
- Q: Where does the user change the size? → A: One slider in Settings. No A− / A+ buttons in the ayah menu.
- Q: What does «increase» mean on the Mushaf page, given that a portrait phone already shows the page at
  the full width of the screen? → A: A bigger page is wider than a portrait screen, so it can be moved
  sideways as well as up and down; a swipe past its side edge turns the page. The same applies in landscape.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Make the tafsir, translation and meanings bigger or smaller (Priority: P1)

The owner finds the tafsir text too small. In Settings there is one slider, «حجم الخط». They move it up and
see a preview sentence grow at once. They go back to the reader, long-press an ayah, open «التفسير», and the
text is bigger. They close the app, open it the next day, and the size is still the one they chose.

**Why this priority**: The tafsir, translation and meanings are long texts read from a phone; their size is
the most common reason to want a size control, and this story needs no change to the Mushaf page.

**Independent Test**: Move the slider to the largest size, open the tafsir, translation and meanings of one
ayah: all three are bigger than before. Move it to the smallest: all three are smaller. Restart the app: the
size is kept.

**Acceptance Scenarios**:

1. **Given** the default size, **When** the owner opens Settings, **Then** they see «حجم الخط» with a slider,
   the current size, a preview sentence at that size, and a way to go back to the default.
2. **Given** Settings is open, **When** the owner moves the slider, **Then** the preview text changes size
   while they move it, and the new size is saved without a separate «save» step.
3. **Given** a bigger size is chosen, **When** the owner opens the tafsir, the translation or the word meanings
   of any ayah, **Then** each of the three shows its text at the chosen size, still scrolling to its end.
4. **Given** the size was changed, **When** the app is closed and opened again, **Then** the chosen size is
   still in force.
5. **Given** the default size, **When** the owner opens the tafsir, **Then** it looks exactly as it did before
   this feature.

---

### User Story 2 - Make the Mushaf page bigger or smaller without changing it (Priority: P2)

The owner wants the Mushaf page itself larger. With the same slider, the page on screen grows; every page still
has the same lines, the same words on each line and the same page number, exactly as in the printed Madinah
Mushaf. A page that is bigger than the screen is moved with the finger, up and down and sideways, inside the
reader, and turning to the next page still works: a swipe that goes past the side edge of the page turns it.

**Why this priority**: It is the owner's second wish, but it touches the heart of the app (Constitution I and
II), so it comes after the safe text-size story.

**Independent Test**: Move the slider to a bigger size and open pages 1, 2, 293 and 604: the page is larger, no
line is broken differently, every word is present, a long press on a word still opens its ayah menu. Go back to
the default: the page looks exactly as before.

**Acceptance Scenarios**:

1. **Given** a bigger size, **When** the owner opens any page, **Then** the whole page is larger, with the same
   15 lines (8 on pages 1 and 2), the same words on each line, the same banners and number, and the text is
   as sharp as at the default size.
2. **Given** a bigger size and a page larger than the screen, **When** the owner drags up, down, left or right,
   **Then** the page moves and every line and every word can be reached, and the page never moves beyond its own
   edges (no empty space is shown past the frame).
3. **Given** a smaller size, **When** the owner opens a page, **Then** the page is smaller, centred on the screen
   with even margins, and every line is readable at the size shown.
4. **Given** any size at which the whole page fits the screen, **When** the owner swipes to turn the page,
   **Then** the next or previous page comes in as in the paper Mushaf (the next page from the left), and the
   reading position is saved as before.
5. **Given** a bigger size at which the page is wider than the screen, **When** the owner drags sideways inside
   the page, **Then** the page moves and does not turn; **When** the page is at its left edge and the finger
   keeps moving left to right, **Then** the next page comes in, and at its right edge a finger moving right to
   left brings the previous page. The page that comes in shows its top and its right side first (where reading
   starts), and the reading position is saved as before.
6. **Given** any size, **When** the owner pinches to zoom, **Then** zoom works on top of the chosen size (1× to
   3× of it), and a tap still shows or hides the bars.
7. **Given** any size, **When** the owner long-presses a word, taps the page number or the surah name, **Then**
   the ayah menu, the go-to-page popup and the surahs list open exactly as at the default size.

---

### User Story 3 - Go back to the default and keep the size in a backup (Priority: P3)

The owner is not happy with the size and wants the old look back with one press. Later, they export a backup
and import it on another phone; the size comes with it.

**Why this priority**: A safety net and a consistency rule; the feature is useful without it.

**Independent Test**: Choose a size, press «الحجم الافتراضي»: the slider returns to the default and both the
texts and the page look as before. Export, change the size, import: the exported size is back.

**Acceptance Scenarios**:

1. **Given** any size, **When** the owner presses «الحجم الافتراضي», **Then** the size is the default at once,
   in the preview, in the ayah texts and on the page.
2. **Given** a backup exported at one size, **When** it is imported after the size was changed, **Then** the
   size of the backup is in force.
3. **Given** a backup made before this feature (it has no size), **When** it is imported, **Then** the size is
   the default and nothing else changes.

---

### Edge Cases

- Pages 1 and 2 (8 lines) and pages with the surah banner and basmallah: they scale like every other page and
  keep their layout.
- A drag that starts in the middle of a page that is wider than the screen and ends past its side edge: the page
  moves to its edge and stops; only a new swipe that starts at the edge turns the page, so a page is never turned
  by accident while reading it sideways.
- A very long tafsir at the largest size: the text is never cut off; the user can scroll to its last line.
- A phone whose system font size is already large: the size setting and the system setting both apply to the
  covered texts, and the result is kept within a usable limit.
- A stored size outside the allowed range or not a number (for example in an edited backup file): the app uses
  the default size and does not fail.
- The screen is rotated, or the phone is a tablet, while a size other than the default is in force: the page
  uses the same chosen size and stays complete and reachable.
- The surah PDF and the page picture shared from the ayah menu: they never follow this setting (they are made
  from the standard page), so a shared page looks the same whatever the owner's own size is.
- A word highlighted by a long press, or hidden words in a later feature: the highlight covers exactly the
  words of the ayah at every size.

## Requirements *(mandatory)*

### Functional Requirements

**Setting and preview**

- **FR-001**: Settings MUST have one control, «حجم الخط», a slider over a fixed set of sizes between a smallest
  and a largest one, with the default in a marked position, showing the current size as a percentage.
- **FR-002**: Under the slider Settings MUST show a preview sentence that changes size while the slider is
  moved, using the same kind of text as the tafsir (Arabic, Cairo) and the translation (English).
- **FR-003**: The chosen size MUST be saved at once, kept after the app closes and after the phone restarts,
  and MUST need no other screen or confirmation.
- **FR-004**: Settings MUST have «الحجم الافتراضي», which returns the size to the default (today's look) in one
  press.
- **FR-005**: The default size MUST be exactly today's look: with the default size every screen of the app is
  unchanged by this feature.

**Where the size applies**

- **FR-006**: The size MUST apply to the text of the tafsir, the translation and the word meanings (words and
  meanings) in the ayah menu, and to nothing else in the ayah menu (rows, headings, buttons keep their size).
- **FR-007**: The size MUST apply to the Mushaf page: all its words, surah banners, basmallah, page number and
  frame scale together, so the page looks like the same page made larger or smaller.
- **FR-008**: When the chosen size makes the Mushaf page larger than the space the reader gives it, in portrait
  or in landscape, the user MUST be able to move it up, down and sideways so that every part of it can be
  reached, and MUST still be able to turn pages by swiping: a swipe past the page's side edge (left edge for the
  next page, right edge for the previous one) turns the page. A page that comes in starts at its top and its
  right side. At sizes where the whole page fits the screen, swiping turns the page as before.
- **FR-009**: At every size the Mushaf page MUST keep the exact Madinah Mushaf 1421H layout: the same lines per
  page, the same words on each line in the same order, the same line breaks and the same page numbers.
  Nothing in the text, its order or its line distribution is changed by this feature (Constitution I).
- **FR-010**: At every size the reader MUST behave as before: the reading position and wird progress are saved
  as for the default size, the page turns in the same direction, a tap shows and hides the bars, pinch zoom
  works from 1× to 3× of the chosen size (the page cannot be turned while it is zoomed, as before), and a long press on a word opens its ayah menu with the ayah
  highlighted (Constitution II, feature 002).
- **FR-011**: The size MUST NOT change the page picture or the surah PDF that the owner shares: they are made
  from the standard page whatever the setting is.
- **FR-012**: The size MUST NOT change the app's other text (lists, Settings, top and bottom bars, wird and
  bookmark screens); a phone's own system font-size setting keeps working for that text as before.

**Data, backup, robustness**

- **FR-013**: The size MUST be stored with the app's other settings on the phone only, and MUST be part of the
  backup file together with them, so that importing a backup brings the size back. A backup that has no size
  MUST import without error and leave the default size.
- **FR-014**: A stored size that is missing, not a number or outside the allowed range MUST be treated as the
  default size, without an error message and without changing the stored value of anything else.
- **FR-015**: This feature MUST work fully offline, MUST NOT send any data from the phone, and MUST NOT add any
  new external resource, font or data file (so nothing is added to the About credits).
- **FR-016**: Turning to another page MUST stay as fast at every size as at the default size (spec 001 SC-007),
  and changing the size MUST apply to the reader the next time it is shown without restarting the app.

**Arabic strings (confirmed by the owner on 2026-11-20)**

- **FR-017**: The Settings row and its parts MUST use these Arabic strings: row title «حجم الخط»; the value as
  «100%»; the reset button «الحجم الافتراضي»; the label of the preview «معاينة»; a short note «يُطبَّق على
  التفسير والترجمة ومعاني الكلمات وعلى صفحة المصحف»; the preview sentences are ordinary example text (not
  Quran text) written for this feature.

### Key Entities *(include if feature involves data)*

- **Text size setting**: one value, the owner's chosen size as a percentage of the default (default 100%), one
  of a fixed set of steps between the smallest and the largest. Stored with the other settings, exported and
  imported with them. It has no relation to a wird, a bookmark or the reading position.
- **Preview**: a sample sentence in Arabic and one in English shown in Settings at the chosen size; it is never
  Quran text.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: From the reader, the owner can reach «حجم الخط», change the size and be back on their page in
  under 15 seconds, with no more than 5 taps and no dialog to confirm.
- **SC-002**: While the slider moves, the preview changes size within one frame of each step (it never lags
  behind the finger by a visible amount).
- **SC-003**: At every step of the slider, on every one of the 604 pages, the lines and the words on each line
  are identical to the default size: 0 differences in an automatic comparison of all 604 pages at every step.
- **SC-004**: At the largest size, the full text of the longest tafsir entry can be read to its last line, and
  at every size no word of the tafsir, the translation or the meanings is cut off.
- **SC-005**: After closing and reopening the app, and after an export followed by an import, the size is the
  one chosen, in 100% of tries.
- **SC-006**: At every size, turning to the next page shows the new page's text in under 300 ms on the owner's
  phone (the same target as spec 001 SC-007), and the reading position is saved as at the default size.
- **SC-007**: A page picture and a surah PDF shared at any size are the same file as at the default size (same
  pixels for the same page).
- **SC-008**: At the default size, all of the earlier features' tests pass unchanged (the default looks exactly
  as today), and at the largest and smallest sizes the owner finds the reader, the ayah menu and the page
  readable on the real phone.
- **SC-009**: At the largest size, the top left corner, the bottom right corner and every line of any page can be
  reached by dragging, and the next and previous page can each be reached with one swipe past the side edge; no
  page is turned while the owner only moves it sideways to read (checked on the real phone, in portrait and
  landscape).
- **SC-010**: No network access happens at any point in this feature; airplane mode changes nothing.

## Assumptions

- The sizes are a short list of steps of 10% from 80% to 150% (eight steps), with 100% the default. These
  numbers are proposed by this spec and not stated by the owner; they can be changed in the plan.
- One slider means one size for both the texts and the page; the owner chose one control. Two separate sliders
  are not part of this feature.
- The preview shows only the two reading texts (Arabic and English); the Mushaf page is not previewed in
  Settings, the owner sees it when they return to the reader.
- On a portrait phone the Mushaf page at the default size already uses the full width of the screen (every line
  is justified to the width), so every bigger size is wider than the screen. The owner decided (2026-11-20)
  that such a page is moved sideways as well as up and down, and that a swipe past its side edge turns it
  (FR-008). The default size, and every size below it, fit the screen.
- In landscape the page already keeps its portrait shape and scrolls up and down; a bigger size there uses the
  extra screen width and the same vertical scrolling.
- The page picture and the PDF use the standard page by design (FR-011): they are meant to be read by other
  people on other screens.
- The phone's system font setting is not replaced by this feature; it keeps scaling the app's other text, and
  for the three reading texts the two settings multiply within a usable limit (to be fixed in the plan).
- Settings and backup already store every setting as a key and a value, so a new setting travels in the backup
  file without a change of the file format's version.
- No new Arabic UI string is final until the owner confirms it (Constitution VI): the owner confirmed the
  strings in FR-017 on 2026-11-20.
