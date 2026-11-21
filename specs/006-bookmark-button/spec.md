# Feature Specification: Bookmark Button in the Reader

**Feature Branch**: `006-bookmark-button` (work stays on `main`, as for features 001 to 005)

**Created**: 2026-11-21

**Status**: Draft

**Input**: User description (owner, Egyptian Arabic): "عايز احط ايقونة اني اضيف الصفحة دي في ال علامات تكون تحت رقم
الجزء على الشمال خالص" — an icon that adds the page being read to the bookmarks, placed under the juz number, at the
far left of the screen.

## Clarifications

### Session 2026-11-21

- Q: What does a tap on the icon do when the page is already bookmarked? → A: It removes the bookmark (the icon is
  a toggle: one tap adds, the next removes), and a duplicate is never created.
- Q: Which bookmarks make the icon filled, when a page can carry several (general, of one wird, with a note)? → A: Only
  the bookmarks of the current scope: the active wird's when following a wird, the general ones when browsing or with
  no wird. The icon removes only that kind and never touches another wird's bookmark.
- Q: Is there a message after a tap? → A: Yes, a short message under the bar with «تراجع» (undo), after an add and after
  a removal.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Bookmark the page I am reading with one tap (Priority: P1)

While reading, the reader taps a small bookmark icon under the juz number («جزء · حزب · ربع», at the top left of the
screen) and the page being shown is added to the bookmarks («علامات») without opening anything: no sheet, no note, no
second step.

**Why this priority**: This is the whole request. Today a bookmark needs three steps (bottom bar «علامات», the add
button, the note dialog), which is too long for something done in the middle of reading.

**Independent Test**: Open the reader on any page that has no bookmark, tap the icon, open «علامات»: the list has one
new entry for that page with no note. Repeat in browse mode and with a wird: the entry is general («عامة») in browse
mode and belongs to the wird otherwise, exactly as an entry added from the sheet.

**Acceptance Scenarios**:

1. **Given** the reader shows page N with no bookmark, **When** the reader taps the icon, **Then** one bookmark on page
   N with no note is saved and the icon shows that the page is bookmarked.
2. **Given** the reader follows a wird (not browsing), **When** it taps the icon, **Then** the bookmark belongs to that
   wird, and the wird's position, khatma count, today's portions and reminders do not change.
3. **Given** the reader is browsing (or has no wird), **When** it taps the icon, **Then** the bookmark is general
   («عامة»), as the sheet does.
4. **Given** a bookmark was added with the icon, **When** the reader opens «علامات», **Then** the entry is in the list
   (newest first) and can be opened and deleted like any other.

---

### User Story 2 - See at a glance whether this page is bookmarked (Priority: P1)

The icon shows two states: outlined when the page shown is not bookmarked, filled when it is. It follows the reader:
turning a page, adding or deleting a bookmark from the sheet, or restoring a backup updates it at once.

**Why this priority**: A button that does not say what it did cannot be trusted; the state is also how the reader
finds out that a page is already marked.

**Independent Test**: With a bookmark on page 50, swipe to page 50: filled; swipe to 51: outlined; delete the bookmark
from the sheet while on 50: outlined; add one from the sheet: filled.

**Acceptance Scenarios**:

1. **Given** a bookmark exists on page N, **When** the reader shows page N, **Then** the icon is filled.
2. **Given** the icon is filled, **When** the reader turns to a page without a bookmark, **Then** the icon is outlined.
3. **Given** the reader deletes the bookmark of the shown page in the sheet, **When** the sheet closes, **Then** the
   icon is outlined.

---

### User Story 3 - Tap the icon on a page that is already bookmarked (Priority: P2)

The icon is a toggle: a tap on the filled icon removes the bookmark of the shown page (of the current scope), a short
message offers «تراجع», and the icon becomes outlined. A duplicate is never created.

**Why this priority**: It decides whether a mistaken tap can be undone; it is small but it must be predictable.

**Independent Test**: On a bookmarked page tap the icon: the bookmark is gone and the message appears; tap «تراجع»: the
bookmark is back exactly as it was (note included).

**Acceptance Scenarios**:

1. **Given** the shown page has a bookmark of the current scope, **When** the reader taps the icon, **Then** that
   bookmark is removed, the icon is outlined and the message with «تراجع» appears.
2. **Given** the removal message is shown, **When** the reader taps «تراجع», **Then** the removed bookmark is back with
   its note and the icon is filled.
3. **Given** the shown page also has a bookmark of another wird, **When** the reader removes with the icon, **Then**
   the other wird's bookmark stays.

---

### User Story 4 - It fits the screen in both looks, at every size (Priority: P2)

The icon sits where the owner asked, never covers or pushes anything, and is readable and easy to hit in Emerald &
Gold and in Night Reader, at the three reading sizes, on a narrow phone and with a large system font.

**Why this priority**: Constitution Principles I and II (the Mushaf page is the product) and the look and size rules
of features 003 and 004 apply to every new control in the reader.

**Independent Test**: Pump the reader in both looks, at 80, 100 and 150 percent, at 320 dp wide with a 2x system
font, in wird mode and in browse mode: no overflow, the icon and «اجعلها موضعي» both visible and tappable, the page
rectangle equal to what it was before the feature, contrast of the icon at least 4.5:1 in both states.

**Acceptance Scenarios**:

1. **Given** the reader is in browse mode, **When** it is shown at 320 dp wide with a 2x system font, **Then** the
   icon and «اجعلها موضعي» do not overlap and neither is cut off.
2. **Given** any look, **When** the icon is drawn outlined or filled, **Then** it has at least 4.5:1 contrast against
   what is behind it.
3. **Given** the page was laid out before the feature, **When** the icon is added, **Then** the page and the top bar
   have the same size and position as before.

---

### Edge Cases

- A page can carry several bookmarks (a general one and ones of two wirds, or two added from the sheet). The icon
  counts only the current scope (the active wird's when following a wird, the general ones otherwise); a bookmark of
  another wird does not make it filled.
- If the current scope has two bookmarks on the page (both added from the sheet), a removal by the icon removes both
  and «تراجع» brings both back.
- A quick double tap must never create two bookmarks on the same page.
- The bookmark list is read from the database: until the first answer arrives the icon is shown outlined and a tap is
  handled against the answer, not against a guess.
- Turning pages quickly, rotating the phone, and returning from the background keep the icon right for the page shown.
- Deleting a wird turns its bookmarks general: the icon of such a page follows the rule above (filled when browsing,
  outlined while following another wird).
- Leaving the reader while the message is shown, or turning the page, does not undo or repeat anything; «تراجع» is only
  valid while the message is shown and only for that tap.
- A restore from a backup replaces the bookmarks: the icon follows without restarting the reader.
- The khatm dua screen (feature 005) and the other full screens do not have the icon.
- A zoomed page (feature 003) does not move the icon: it belongs to the top bar, not to the page.
- Saving can fail (disk full): the icon keeps the real state (outlined) and nothing else changes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The reader MUST show a bookmark icon button directly under the «جزء · حزب · ربع» text of its top bar, at
  the far left end of the screen (the same edge as that text).
- **FR-002**: In browse mode the icon and the text button «اجعلها موضعي» MUST both stay fully visible and tappable,
  without overlap, at every size of FR-013.
- **FR-003**: Adding the icon MUST NOT change the size or position of the Mushaf page or the height of the top bar
  (the page geometry tests of features 001 to 004 stay green unchanged).
- **FR-004**: One tap on the icon, on a page that is not bookmarked, MUST save one bookmark on the page shown, with no
  note, owned exactly as the «علامات» sheet owns it (the active wird outside browse mode, general in browse mode or
  with no wird; feature 001 FR-033).
- **FR-005**: The icon MUST be drawn filled when the page shown has at least one bookmark of the current scope (the
  active wird's when the reader follows a wird, the general ones when browsing or with no wird), and outlined
  otherwise, and MUST follow page changes, additions and deletions made in the «علامات» sheet, wird deletion, a wird
  switch and a backup restore.
- **FR-006**: A tap on the icon when the page counts as bookmarked (FR-005) MUST remove every bookmark of the current
  scope on that page, MUST NOT touch bookmarks of another wird, and MUST NOT create a duplicate.
- **FR-007**: After each tap, add or removal, a short message MUST appear under the top bar: «تمت إضافة علامة للصفحة N»
  or «تمت إزالة العلامة من الصفحة N», each with «تراجع». «تراجع» MUST undo exactly that tap: it removes what the tap
  added, or restores what it removed (page, owner and note as they were). The message goes away by itself and a new
  tap replaces it.
- **FR-008**: A tap MUST do nothing besides FR-004, FR-006 and FR-007: no page turn, no change of the wird position,
  khatma count, today's portions, reminders, last viewed page or settings.
- **FR-009**: Two taps in quick succession on a page that was not bookmarked MUST leave the page bookmarked once or
  not at all (add then remove), never two bookmarks of the current scope on the same page.
- **FR-010**: The touch target MUST be at least 48 by 48 px without enlarging the top bar.
- **FR-011**: The icon MUST have an Arabic tooltip and a screen-reader label that name the action and the page, and a
  screen reader MUST hear the two states. The proposed strings are in Assumptions and the owner confirms them
  (Constitution VI).
- **FR-012**: Its colours MUST come from the chosen look (Emerald & Gold, Night Reader) with at least 4.5:1 contrast in
  both states, and the icon MUST follow a later look change at once.
- **FR-013**: It MUST fit without overflow at the three reading sizes (80, 100, 150 percent), at 320 dp wide with a 2x
  system font, in portrait and landscape, in wird mode and in browse mode.
- **FR-014**: It MUST work offline, add no package, resource or permission, change no database table, and leave
  export and import of backups as they are.
- **FR-015**: The bottom bar, the «علامات» sheet, the khatm dua swipe (feature 005), the page turn and every earlier
  test MUST be unchanged by this feature.

### Key Entities *(include if feature involves data)*

- **Bookmark** (existing, unchanged): a page 1 to 604, an optional note, the wird it belongs to or none (general), and
  the time it was added. This feature adds and reads bookmarks; it adds no field.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A page is bookmarked with one tap: one touch, no sheet, no dialog; the bookmark count grows by exactly 1
  per bookmarked page, never by 2.
- **SC-002**: After a page change or a bookmark change the icon shows the right state within 100 ms, in 100 percent of
  the tested cases (pages 1, 2, 604, a page with several bookmarks, a page of a deleted wird).
- **SC-003**: At 320 dp wide with a 2x system font, in both looks, at 80, 100 and 150 percent, in wird mode and in
  browse mode, there is no overflow and nothing is cut off (12 of 12 combinations).
- **SC-004**: The icon has at least 4.5:1 contrast in both states in both looks (4 of 4).
- **SC-005**: The touch target is at least 48 by 48 px in every combination of SC-003.
- **SC-006**: After a tap the wird position, khatma count, today's portions, other bookmarks, reminders and settings are
  the same as before it (checked on a wird and in browse mode).
- **SC-007**: The page rectangle and the top bar height are equal to the values before the feature, and the existing
  mushaf, wirds, ayah, khatm and settings tests pass without any change to those tests.
- **SC-009**: «تراجع» brings the bookmarks back to exactly the state before the tap (same pages, owners, notes and
  count) in 100 percent of the tested cases (an add, a removal of one bookmark, a removal of two, a removal with a
  note).
- **SC-008**: On the owner's phone the owner finds the icon where asked (under the juz number, far left) on the first
  look, and one tap bookmarks the page (owner's own check).

## Assumptions

- "Far left" is the left edge of the screen in the reader's right-to-left layout, the same edge as the juz text, one
  row below it, in the second row of the top bar where «اجعلها موضعي» also sits in browse mode.
- The icon is a plain outlined or filled bookmark glyph from the icons the app already uses; the app's look tokens
  colour it (no new colour is added).
- A bookmark added with the icon has no note; the owner can still add a note from the «علامات» sheet.
- Proposed Arabic strings (Constitution VI: the owner confirms them before the feature is done): tooltip and label
  when not bookmarked «إضافة علامة للصفحة N»; tooltip and label when bookmarked «إزالة العلامة من الصفحة N»; the two
  states heard by a screen reader «عليها علامة» and «ليس عليها علامة»; the messages «تمت إضافة علامة للصفحة N» and
  «تمت إزالة العلامة من الصفحة N»; the undo button «تراجع». N is the page number.
- The message of FR-007 is the app's standard short message (it stays a few seconds, the default length), shown above
  the bottom bar so it never covers the icon or the page number.
- The bookmarks of the current scope are read from the same list the «علامات» sheet shows, so the sheet and the icon
  never disagree.
- Existing bookmarks, backups and the data model stay as they are, so no migration and no new test data file.
- The phone check follows Constitution IX; the owner is asked before any install or input on the phone.
