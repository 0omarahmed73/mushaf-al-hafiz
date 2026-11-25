# Feature Specification: Ayah Bookmark

**Feature Branch**: `013-ayah-bookmark` (work stays on `main`, as for features 001 to 011)

**Created**: 2026-11-25

**Status**: Implemented (2026-11-25, converged in task T049). Every task of tasks.md is done except the step-by-step phone
walk T045 and its follow-up T046; see "Convergence 2026-11-25" below

**Input**: User description (owner, Egyptian Arabic): «اني اقدر اضيف علامة على اية زي ما بعمل على الصفحة» — "I want to be
able to add a bookmark on an ayah, the way I do on a page". The three open points of the first draft were answered by the
owner on 2026-11-25 and are encoded below; nothing is left marked open.

## Clarifications

### Convergence 2026-11-25 (task T049: what the documents now say the code does)

- Built and tested: every FR-001 to FR-028 is in the code (`lib/`), checked by the tests of `test/migration/` and
  `test/ayah_bookmarks/`; the two existing tests named in FR-020 are the only existing tests edited (one number each).
- Decisions made during implementation, now written in the requirements they touch: the backup writes version 2 only when
  an ayah bookmark exists (FR-014, unchanged since the first plan); the page behind the «علامات» sheet keeps its tint while
  the sheet is open and loses it in the first frame after the sheet closes (FR-026, research D5); the note field and the note
  view scroll on a narrow phone with a large system font (FR-015, FR-028); the page row of «علامات» gives its owner tag at most
  half the row (FR-010); the rows of the ayah sheet name themselves by their visible label, as the existing rows do (FR-017).
- The owner: confirmed every Arabic string on 2026-11-25 («كلها تمام», T048); installed the update over the release build
  and found his data intact («كله موجود», T044); asked for FR-028 and checked it on the phone («تمام», T051). The full phone
  walk of quickstart steps 2 to 9 (T045) was not done step by step: he tried the feature, but SC-011, SC-015 (telling the tint
  from the highlight by eye) and the phone part of SC-016 are not yet recorded step by step. The note flow of "Author's
  reading" below is built as written; the owner used it on the phone, but his «كلها تمام» answered the list of strings, not
  each point of that reading.
- Not of this feature, recorded only: with a 2x system font the Mushaf page's lines and the reader's bars overflow at 320 dp
  (features 001, 002, 006), which puts «علامات» and the menu button off the screen (research "Measured").

### Correction 2026-11-26 (a wrong fact found during implementation)

(Written on 2026-11-25, commit d706cbf; the heading keeps the date the tests cite.)

The first drafts said that an ayah can continue on the next page and named 2:282 "on pages 48 and 49". That is wrong for
this edition: both implementing agents checked the 604 page files and no ayah crosses a page (2:282 fills page 48 alone;
page 49 opens with 2:283). FR-025, SC-014, the scenarios and the tasks below are corrected: each page tints the words of
a bookmarked ayah that are drawn on it, read from the page's own words, and 2:282 is tested on page 48 only.

### Session 2026-11-25 (the owner's answers)

- Q: Does the Mushaf page show that an ayah is bookmarked? → A: «تظليل خفيف ورا الآية»: a light, permanent tint behind every
  bookmarked ayah on the Mushaf page. It changes no glyph, no line and no geometry; it is drawn for the bookmarks of the
  current scope only; it is told apart from the temporary highlight of a long press and of a search result in both looks;
  the text on it keeps contrast of at least 4.5:1; it can be switched off in Settings (default on); an ayah that crosses
  two pages would be tinted on both (none does in this edition: see the correction above); it appears and disappears within one frame of an add or a removal; it does not slow page
  turning (FR-016, FR-022 to FR-026, SC-014 to SC-017).
- Q: Does an ayah bookmark change the top-bar bookmark icon of feature 006? → A: «لا، كل واحدة لوحدها»: the icon keeps
  meaning "this page has a PAGE bookmark of the current scope"; its tap adds and removes page bookmarks only and never
  deletes an ayah bookmark; «تراجع» restores exactly. Today's code removes every bookmark of the page in scope, ayah
  bookmarks included once this feature exists, so the fix and a regression test are part of this feature (FR-011, SC-012).
- Q: Can an ayah bookmark carry a note? → A: «ملاحظة الاية تضاف لما ادوس ع الاية دوسة مطولة هلاقي خيار اضافي اسمه ملاحظة
  للاية» (the owner's correction of the same day to his first answer). The long press is the existing long press on a word of
  the ayah, which already opens the ayah sheet; the sheet gets a second, separate and visible action named «ملاحظة للآية»
  beside the bookmark action. There is no long press on the bookmark action and no hidden gesture (FR-001, FR-015, FR-021,
  SC-013).

### Author's reading of the note answer (assumptions, mine, awaiting the owner's confirmation)

- Tapping «ملاحظة للآية» opens a small note field. It opens pre-filled with the current note of the ayah's bookmark of the
  current scope, if any.
- Saving a non-empty note creates the ayah bookmark with that note in the current scope when the ayah has none, and
  replaces the note of the existing ayah bookmark of that scope otherwise.
- Saving an empty note (or one of spaces only) on an existing ayah bookmark clears the note and keeps the bookmark. Saving
  an empty note when the ayah has no bookmark does nothing (no bookmark without a reason is created).
- Cancelling changes nothing. The sheet action shows whether the ayah already has a note.
- The plain bookmark action still adds with no note in one tap, and removes the bookmark with its note on the next tap;
  «تراجع» restores the note exactly.
- The note appears in the list «علامات» as the note of a page bookmark does today, and has the same maximum length as
  the note of a page bookmark (200 characters). Editing the note of a PAGE bookmark stays out of scope.

### Author's decisions (first draft, 2026-11-25, unchanged)

- Q: Where is an ayah bookmark added? → A: In the ayah menu (feature 002): long press a word, the ayah is highlighted and
  the sheet «سورة X · آية N» opens; it gets a bookmark action (one tap, no note, no dialog) and, beside it, the note action.
- Q: What does the bookmark action do when the ayah is already bookmarked? → A: It shows that state and removes the bookmark
  (a toggle, as the icon of feature 006), with a short message and «تراجع».
- Q: Which bookmarks count as "this ayah is bookmarked"? → A: The ones of the current scope, by the rule of feature 006
  (the active wird's when the reader follows a wird, the general ones when browsing or with no wird).
- Q: What is stored? → A: Everything a page bookmark stores plus the surah and the ayah. The page is the page where the ayah
  begins, worked out from the fixed Mushaf edition and stored, so that the list, the backup and the old code keep working.
- Q: Does a page bookmark change? → A: No. Page bookmarks, their icon (except the fix of FR-011), their list rows and their
  backup entries are as they are today.
- Q: Is the data safe on the update? → A: This is the app's first change of its database layout (it is at version 1 now).
  Every wird, portion, bookmark and setting already on the phone MUST still be there after the update.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Bookmark an ayah from its menu with one tap (Priority: P1)

While reading, the reader long presses a word. The ayah is highlighted and its menu opens, titled «سورة X · آية N». A new
action in it bookmarks that ayah. The reader taps it and goes back to reading.

**Why this priority**: This is the whole request. Today the only mark the reader can leave is on a page, and a page holds
up to 15 lines and several ayat; a memoriser marks the ayah they stopped at or want to come back to.

**Independent Test**: Long press a word of an ayah that has no bookmark, tap the new action, open «علامات»: the list has one
new entry «سورة X · آية N» with the page where the ayah begins and no note. Repeat in browse mode and with a wird: the entry
is general («عامة») in browse mode and belongs to the wird otherwise, exactly as a page bookmark does.

**Acceptance Scenarios**:

1. **Given** the ayah sheet of an ayah with no bookmark of the current scope, **When** the reader taps the bookmark action,
   **Then** one bookmark is saved with that surah, that ayah and the page where the ayah begins, with no note, and a short
   message with «تراجع» appears.
2. **Given** the reader follows a wird (not browsing), **When** it adds an ayah bookmark, **Then** the bookmark belongs to that
   wird, and the wird's position, khatma count, today's portions and reminders do not change.
3. **Given** the reader is browsing (or has no wird), **When** it adds an ayah bookmark, **Then** the bookmark is general
   («عامة»).
4. **Given** a long ayah (for example 2:282, which fills page 48), **When** it is bookmarked, **Then** the stored page is
   the page it is on.
5. **Given** the reader taps «تراجع» while the message is shown, **When** the message closes, **Then** the bookmark is gone,
   as if the tap had not happened.

---

### User Story 2 - See that an ayah is already bookmarked, and remove it (Priority: P1)

The bookmark action in the ayah sheet shows two states: «add» when the ayah has no bookmark of the current scope, «remove»
when it has. Tapping it in the second state removes the bookmark (with its note, if it has one), with a short message and
«تراجع».

**Why this priority**: An action that does not say what it will do cannot be trusted, and without the state the reader
creates duplicates without knowing.

**Independent Test**: Bookmark an ayah, long press it again: the action reads as «remove». Tap it: the bookmark is gone;
tap «تراجع»: it is back with its note and its time. Long press the next ayah: «add».

**Acceptance Scenarios**:

1. **Given** an ayah with a bookmark of the current scope, **When** its sheet opens, **Then** the action shows the «remove»
   state (label, icon and the state a screen reader hears).
2. **Given** the «remove» state, **When** the reader taps the action, **Then** that ayah's bookmarks of the current scope are
   removed, no other bookmark is touched, and the message with «تراجع» appears.
3. **Given** the same ayah has a bookmark of another wird, **When** the reader adds or removes in its own scope, **Then** the
   other wird's bookmark is neither shown as this scope's state nor touched.
4. **Given** a quick double tap on «add», **When** it is handled, **Then** the ayah ends bookmarked once or not at all, never
   twice in one scope.
5. **Given** an ayah bookmark with a note, **When** the reader removes it and then taps «تراجع», **Then** the bookmark is back
   with the same note, owner and time.

---

### User Story 3 - Find an ayah bookmark in the list and go back to it (Priority: P1)

The bottom-bar item «علامات» opens the same list as today. An ayah bookmark is a row titled «سورة X · آية N» with its page
number, and it looks different from a page bookmark at a glance. Tapping it shows the page and highlights that ayah the way a
search result is highlighted (feature 011), until the next touch or page turn. Swiping it deletes it.

**Why this priority**: A bookmark is only worth something if it brings the reader back to the exact place; the ayah itself,
not only its page, is the point of this feature.

**Independent Test**: With one page bookmark and one ayah bookmark in the list, the two rows are told apart without reading
the small print; tap the ayah row: the reader shows the page, the ayah is highlighted, and the first touch clears the
highlight. Swipe the row: it is deleted.

**Acceptance Scenarios**:

1. **Given** the list holds page bookmarks and ayah bookmarks, **When** it is shown, **Then** all are in one list, newest
   first, each with its wird's name or «عامة» as today.
2. **Given** an ayah row, **When** it is read, **Then** it shows «سورة X · آية N», «ص P» and, if any, its note, and carries a
   mark that a page row does not carry.
3. **Given** an ayah row, **When** the reader taps it, **Then** the sheet closes, the reader shows the page where the ayah
   begins in browse mode (the wird does not move, as for a page bookmark) and the ayah's words on that page are highlighted
   until the next touch or turn.
4. **Given** the page is already the one shown, **When** the reader taps an ayah row, **Then** the ayah is highlighted and
   brought into view with no page change.
5. **Given** an ayah row, **When** the reader swipes it, **Then** it is deleted as a page bookmark is.

---

### User Story 4 - Nothing is lost when the app is updated or restored (Priority: P1)

The reader's bookmarks, wirds, portions, khatma counts and settings survive the update that brings this feature. A backup
file made before the update (version 1) still restores completely; a backup made after it (with ayah bookmarks) restores
completely on the new app and is refused with a clear message by an older build.

**Why this priority**: This is the first time the app changes how it stores data. A Quran app that loses a year of wird
progress or bookmarks on an update loses the owner's trust (Constitution VII), and the owner has a release build installed on
the phone now.

**Independent Test**: Take a database made by the current build with N bookmarks (page ones, general and of wirds, with and
without notes), wirds, portions and settings; open it with the new build: every row is there, equal in every field, and the
new fields of the old bookmarks are empty. Restore a version-1 backup file: all of it is restored. Export, then restore, a
backup that holds ayah bookmarks: they come back equal.

**Acceptance Scenarios**:

1. **Given** a phone with the current build's data, **When** the new build opens it for the first time, **Then** every wird,
   portion, bookmark (with its id, page, note, owner and time) and setting is present and equal, and every old bookmark is a
   page bookmark.
2. **Given** a version-1 backup file, **When** it is imported, **Then** it restores completely and its bookmarks are page
   bookmarks.
3. **Given** a backup exported after this feature, **When** it is imported into the same app, **Then** page and ayah
   bookmarks come back equal (surah, ayah, page, note, owner, time).
4. **Given** a backup file whose version is newer than the app knows (an older build given a file that holds ayah
   bookmarks), **When** it is imported, **Then** it is refused with the existing message «هذه النسخة الاحتياطية أحدث من هذا
   التطبيق. لم يتغيّر شيء.» and nothing changes.
5. **Given** an import that fails halfway, **When** it ends, **Then** nothing changed, as today.
6. **Given** a backup file whose ayah bookmark names an ayah that does not exist, or a page that is not where that ayah
   begins, **When** it is imported, **Then** it is refused as an invalid file and nothing changes.
7. **Given** an update that stops halfway (the process is killed during the change of layout), **When** the app starts
   again, **Then** it opens with all the data and finishes the change, never stuck and never with the data half changed.

---

### User Story 5 - It fits the screen in both looks, at every size (Priority: P2)

The new actions, the note field, the list row and the Settings switch are readable and easy to hit in Emerald & Gold and in
Night Reader, at the three reading sizes, on a narrow phone and with a large system font. The Mushaf page is as it was
printed.

**Why this priority**: Constitution Principles I and II (the Mushaf page is the product) and the look and size rules of
features 003 and 004 apply to every new control.

**Independent Test**: Pump the ayah sheet, the note field, the list and Settings in both looks, at 80, 100 and 150 percent,
at 320 dp wide with a 2x system font: no overflow, every target at least 48 px, contrast at least 4.5:1; the page rectangle
and glyphs are equal to what they were before the feature.

**Acceptance Scenarios**:

1. **Given** any look, **When** an action, the note field or the row is drawn in any state, **Then** its text and icon have at
   least 4.5:1 contrast against what is behind them.
2. **Given** 320 dp with a 2x system font, **When** the ayah sheet, the note field and the list are shown, **Then** nothing
   overflows or is cut off, and a long surah name does not push the page number out.
3. **Given** an ayah that has a bookmark, **When** its page is drawn, **Then** nothing but a background tint behind its words
   differs from before (FR-016).

---

### User Story 6 - Add a note to an ayah from its menu (Priority: P2)

The ayah sheet has a second action beside the bookmark action, named «ملاحظة للآية». The reader taps it, writes a note in a
small field and saves. The ayah is bookmarked with that note (or its existing bookmark gets the note). The note shows in
«علامات» under the ayah's title.

**Why this priority**: The owner asked for it («هلاقي خيار اضافي اسمه ملاحظة للاية»); the one-tap bookmark stays the fast path.

**Independent Test**: Long press an ayah that has no bookmark, tap «ملاحظة للآية», write «أراجع هنا» and save: one ayah
bookmark with that note exists and «علامات» shows it. Long press the same ayah: the note action says it has a note; tap it, the
field holds «أراجع هنا»; change it, save: the note is replaced and the bookmark is still one. Open it, empty the field, save:
the note is gone and the bookmark stays.

**Acceptance Scenarios**:

1. **Given** an ayah with no bookmark of the current scope, **When** the reader taps «ملاحظة للآية», writes a non-empty note
   and saves, **Then** one ayah bookmark with that note exists in the current scope (the owner rule of FR-003) and a message
   with «تراجع» appears.
2. **Given** an ayah with a bookmark of the current scope, **When** the reader saves a non-empty note, **Then** that
   bookmark's note is replaced, no second bookmark is created, and its owner, page and time do not change.
3. **Given** an ayah with a bookmark that has a note, **When** the reader saves an empty note, **Then** the note is cleared,
   the bookmark stays, and the message says the note was removed.
4. **Given** an ayah with no bookmark, **When** the reader saves an empty note, **Then** nothing is created and no message
   appears.
5. **Given** the note field is open, **When** the reader cancels (the button, the back gesture or a tap outside), **Then**
   nothing changes and the ayah sheet is still open.
6. **Given** a saved note, **When** the reader taps «تراجع», **Then** the bookmark and the note are as they were before the
   save (the bookmark removed if the save created it, the previous note back if the save replaced or cleared it).
7. **Given** an ayah bookmark with a note, **When** its sheet opens, **Then** the note action shows that the ayah has a note
   (the note's start under the label, and the state a screen reader hears).

---

### User Story 7 - See the bookmarked ayat on the Mushaf page (Priority: P2)

A light tint stays behind every ayah that has a bookmark of the current scope, on the Mushaf page, so the reader sees at a
glance where their marks are. It can be switched off in Settings.

**Why this priority**: The owner chose it («تظليل خفيف ورا الآية»). It is P2 because the bookmark works without it, but it
touches the Mushaf page itself, so its limits (Principles I and II) are the strictest of the feature.

**Independent Test**: Bookmark an ayah: the next frame draws a light tint behind its words and nothing else on the page
moved. Remove the bookmark: the tint is gone in the next frame. Long press the tinted ayah: the usual highlight shows (not the
tint), and the tint is back when the menu closes. Switch the setting off: no tint on any page, the bookmarks are still
there. Switch to a wird that has no bookmark on this page: the tint is gone.

**Acceptance Scenarios**:

1. **Given** an ayah with a bookmark of the current scope and the setting on, **When** its page is shown, **Then** every word
   of the ayah on that page (the end-of-ayah marker included) has the tint behind it.
2. **Given** a bookmark of another wird (or a general one while following a wird, or a wird's one while browsing), **When**
   the page is shown, **Then** that ayah is not tinted.
3. **Given** a PAGE bookmark on the page, **When** the page is shown, **Then** nothing is tinted (a page bookmark marks no
   ayah).
4. **Given** a bookmarked ayah, **When** its page is shown, **Then** exactly the words of that ayah drawn on the page are
   tinted, and no word on any other page.
5. **Given** a tinted ayah, **When** the reader long presses it or opens it from the list or from a search result, **Then**
   the temporary highlight is drawn on its words in place of the tint, looks as it did before this feature, and the tint
   returns when the highlight ends.
6. **Given** the setting is off, **When** any page is shown, **Then** no tint is drawn; bookmarks, the sheet's states and the
   list are as with the setting on.
7. **Given** the page picture and the surah PDF that the ayah sheet shares, **When** they are made, **Then** they carry no
   tint.

---

### User Story 8 - The page icon keeps its own meaning (Priority: P1)

The top-bar bookmark icon of feature 006 still means "this page has a page bookmark of the current scope". Tapping it adds or
removes page bookmarks only. An ayah bookmark on the same page neither fills the icon nor is deleted by it.

**Why this priority**: Without this, one tap on the icon would silently delete the reader's ayah bookmarks and their notes.

**Independent Test**: A page with an ayah bookmark of the scope and no page bookmark: the icon is outlined; tap it: a page
bookmark is added and the ayah bookmark is still there; tap again: only the page bookmark is removed; «تراجع» brings back that
page bookmark and nothing else changed.

**Acceptance Scenarios**:

1. **Given** a page with only an ayah bookmark of the current scope, **When** the page is shown, **Then** the icon shows the
   «no bookmark» state.
2. **Given** a page with a page bookmark and an ayah bookmark of the scope, **When** the reader taps the filled icon, **Then**
   only the page bookmark (or bookmarks) of the scope is removed; the ayah bookmark and its note stay.
3. **Given** that removal, **When** the reader taps «تراجع», **Then** exactly the removed page bookmark comes back (id, note,
   owner, time) and no ayah bookmark changed.
4. **Given** a page with only an ayah bookmark, **When** the reader taps the outlined icon, **Then** one page bookmark is added
   and the ayah bookmark is untouched.

---

### Edge Cases

- The same ayah may carry a bookmark in several scopes (the general one and one for each of two wirds). The sheet's state, the
  toggle, the note action, the tint and the undo concern only the current scope; the list shows every one, each with its owner.
- An ayah bookmark and a page bookmark may sit on the same page. They are separate entries; none replaces or removes the
  other (FR-011).
- Two ayat on the same page, each bookmarked: two rows, each opening and highlighting its own ayah, and both tinted.
- Two bookmarked ayat that follow each other: each is tinted word by word; the tint of one never extends to the other.
- No ayah continues on the next page in this edition (correction of 2026-11-26); each page still tints only the words drawn
  on it, read from the page itself (FR-025), and the stored page is where the ayah begins.
- Deleting a wird turns its bookmarks general, ayah bookmarks included (as page bookmarks today): the ayah, surah, page and
  note stay; the tint follows the new scope rule at once.
- A restore from a backup replaces the bookmarks; the sheet's state, the tint and the list follow without restarting the
  reader.
- A tap on an action with the database failing (disk full) saves nothing and shows no «added» message; the state stays what
  it really is. A failed note save keeps the note field open with the text the reader typed.
- The message, the swipe and «تراجع» only act on that tap; leaving the reader or turning the page while the message is shown
  does not repeat or undo anything.
- A stale open ayah sheet is not kept across a wird switch: the states are read when the sheet opens and after each tap.
- A note typed longer than 200 characters cannot be entered (the field stops at 200); a note of spaces only is an empty note.
- A restored backup may hold two ayah bookmarks of the same ayah in one scope (the app never creates this). The bookmark
  action then reads «remove» and removes both; the note action edits all of them to the same note (FR-021).
- The khatm dua screen (feature 005) and the other full screens are not touched.
- The web version (feature 012) is paused; nothing is specified for it here beyond FR-018.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The ayah sheet (feature 002) MUST show two more actions for the ayah it is titled with, in the group of the
  ayah's actions («مشاركة»، «التفسير»، «الترجمة»، «معاني الكلمات»), not in the section «الصفحة والسورة»: the bookmark action
  (FR-002) and, next to it, the note action «ملاحظة للآية» (FR-015). Each MUST be a full-width visible row with a 48 px
  target and the look of the other actions. (FR-028 adds a third row, «عرض الملاحظة», when the ayah has a note.) Neither depends on a long press, a swipe or any gesture other than the tap, and
  no existing action changes.
- **FR-002**: The bookmark action MUST show the state «add» when the ayah has no bookmark of the current scope and «remove»
  when it has one, read when the sheet opens, and MUST be right in the first frame of the sheet (a tap closes the sheet, so it is read again at the next opening). The scope rule is feature 006's: the active
  wird's bookmarks when the reader follows a wird, the general ones when browsing or with no wird.
- **FR-003**: One tap on «add» MUST save one bookmark with the ayah's surah and ayah, the page where the ayah begins, no note
  and an owner chosen as the «علامات» sheet chooses it (the active wird outside browse mode, general in browse mode or with no
  wird; feature 001 FR-033).
- **FR-004**: One tap on «remove» MUST remove every ayah bookmark of that ayah in the current scope (with its note), MUST NOT
  touch a page bookmark or another scope's bookmark, and MUST NOT create a duplicate.
- **FR-005**: Two taps in quick succession on «add» MUST leave the ayah bookmarked once or not at all, never two ayah
  bookmarks of the same ayah in one scope. The decision MUST come from the stored data, not from what the screen believed.
- **FR-006**: After each tap on the bookmark action a short message MUST appear in the reader, with the action «تراجع»: «تمت
  إضافة علامة على سورة X · آية N» or «تمت إزالة العلامة من سورة X · آية N». «تراجع» MUST undo exactly that tap (remove what it
  added, or restore what it removed with its owner, note and time). The message goes away by itself, and a new tap replaces it.
- **FR-007**: A tap on the bookmark action or a save of the note MUST do nothing besides FR-003, FR-004, FR-021 and their
  message: no page turn, no change of the wird position, khatma count, today's portions, reminders, last viewed page or
  settings. After the tap or the save the sheet closes and the ayah's highlight ends, as after the other actions.
- **FR-008**: A bookmark MUST be either a page bookmark (no surah, no ayah) or an ayah bookmark (surah 1 to 114 and an ayah
  that exists in that surah, both present). Its page MUST be the page where that ayah begins in the fixed Mushaf edition
  (Constitution I) and MUST NOT be chosen by the user.
- **FR-009**: Every page bookmark, the «إضافة علامة للصفحة N» button and the note dialog of the list MUST work exactly as
  before. Old code that reads a bookmark's page MUST keep getting the right page. The top-bar icon of feature 006 keeps its
  look, place and messages and changes only as FR-011 says.
- **FR-010**: In the list «علامات» an ayah bookmark MUST be one row in the same list and the same order as page bookmarks
  (newest first), titled «سورة X · آية N», showing «ص P», its note if any (as a page bookmark's note is shown today), and its
  wird name or «عامة». It MUST be told apart from a page row by a mark other than colour alone (its own icon, and the word
  «آية» in its label), and MUST be deleted by the same swipe. (Built: neither row lets a long owner tag push «ص P» out at
  320 dp with a 2x font; the ayah row's tag shrinks, the page row's tag takes at most half the row, T042.)
- **FR-011**: The top-bar bookmark icon of feature 006 MUST keep meaning "the page shown has a PAGE bookmark of the current
  scope" (an ayah bookmark never fills it). Its tap MUST add a page bookmark when the scope has none on the page, and
  otherwise remove the PAGE bookmarks of the scope on that page only; it MUST NOT delete, change or count an ayah bookmark,
  and MUST NOT touch another scope's bookmark. «تراجع» after it MUST restore exactly the rows it removed (id, page, owner,
  note, time). Today's `toggleBookmark(page, wirdId)` removes every bookmark of the page in the scope; it MUST be corrected as
  part of this feature, and a regression test MUST fail on the old behaviour and pass on the new. The icon's data and its
  state MUST never disagree.
- **FR-012**: Opening an ayah row MUST close the sheet and show the page where the ayah begins in browse mode (the wird does
  not move), with the ayah's words on that page highlighted and brought into view by the mechanism of a search result (feature
  011), until the next touch, turn or opened screen. If the page is the one shown, only the highlight and the reveal happen.
- **FR-013**: The database layout MUST change to hold the surah and the ayah of a bookmark, and the update MUST keep every row
  of every table: wirds, portions, bookmarks (id, page, note, owner, time) and settings, all equal, with the surah and ayah of
  old bookmarks empty. A failed or interrupted migration MUST NOT leave the data half changed or the app unable to start. This
  is the first change of the layout, so it MUST be tested against a real database file made by the previous layout, before the
  feature is done. A fresh install MUST get the new layout directly.
- **FR-014**: The backup file MUST get a new version number (2) that carries the surah and the ayah of an ayah bookmark; it is
  written as version 2 only when at least one ayah bookmark exists, and otherwise exactly as today (version 1, no surah or ayah
  keys), so a file with page bookmarks only is still read by an older build. The app MUST still import every version-1 file
  completely (a version-1 file that carries a surah or an ayah is invalid). A file with a version above what the app knows MUST be refused with
  the existing message and change nothing (the current code does this for any version above its own). An ayah bookmark whose
  ayah does not exist, whose surah or ayah is alone, or whose page is not the page where the ayah begins MUST make the file
  invalid and change nothing. The restore MUST still replace the tables in one transaction. The notes of ayah bookmarks travel
  in the same `note` field as page notes. The Settings switch of FR-024 travels in the file's `settings` as every setting
  does.
- **FR-015**: The note action «ملاحظة للآية» MUST open a small note field (an optional text, at most 200 characters, the same
  limit as the note of a page bookmark; built as a dialog whose title scrolls with the field, so the field and both buttons
  stay reachable at 320 dp with a 2x system font, T042) titled with the ayah, pre-filled with the current note of the ayah's bookmark of the
  current scope when there is one. The action MUST show whether the ayah already has a note (the start of the note under its
  label, and the state a screen reader hears). The field has a save button and a cancel button, both with 48 px targets, and
  a line that says what saving does in the state it is in (FR-021). Cancelling by the button, the back gesture or a tap
  outside changes nothing and leaves the ayah sheet open.
- **FR-016**: The Mushaf page MUST draw a light, permanent tint behind every word of every ayah that has an ayah bookmark of the
  current scope (FR-022), unless the setting of FR-024 is off. The tint MUST change no glyph, no word, no line and no
  geometry: the position and size of every word, line, banner and page rectangle are equal with and without the tint, in
  every frame (Constitution I and II); the page-layout invariance tests stay green.
- **FR-017**: Every control MUST have an Arabic tooltip and a screen-reader label that name the action and the ayah and say
  the state (built: the new controls are full rows and text buttons whose visible label is their name, as the existing rows
  of the ayah sheet; the ayah is named by the sheet's title, the state by the row's value; there is no icon-only control); targets MUST be at least 48 by 48 px; colours MUST come from the chosen look (Emerald & Gold, Night Reader) with
  at least 4.5:1 contrast in every state and follow a look change at once; everything MUST fit without overflow at the three
  reading sizes (80, 100, 150 percent), at 320 dp wide with a 2x system font, in portrait and landscape. The Arabic strings
  are in Assumptions; the owner confirmed every one on 2026-11-25 (T048, Constitution VI).
- **FR-018**: The feature MUST work offline and add no package, permission or bundled resource (so no entry in
  docs/research/licenses.md). Ayah bookmarks, notes and the tint setting stay on the phone and travel only in the backup file
  (Constitution IV). The data format stays one for the paused web version (feature 012): that version, when built, reads and
  writes the same backup file.
- **FR-019**: The wird position, khatma count, today's portions, reminders and last viewed page MUST NOT change by any
  bookmark action of this feature (add, remove, note, undo, delete, open from the list; opening moves the reader as every
  opening of a page does, without moving the wird).
- **FR-020**: The existing tests of features 001, 002, 006, 010 and 011 MUST pass without change, with one deliberate
  exception: the two assertions that a version-2 file is "newer" (`test/backup/backup_service_test.dart` and the
  newer-backup case of `test/settings/backup_ui_test.dart`) cannot stay true once the app reads version 2; the number
  becomes 3 in each, and nothing else in any existing test changes. The bottom
  bar, the khatm dua swipe, the page turn, the search and the share actions MUST behave as before.
- **FR-021**: Saving the note field MUST behave as follows, decided from the stored data in one transaction: (a) a non-empty
  note (after trimming) on an ayah with no bookmark of the current scope creates the ayah bookmark with that note (owner as
  FR-003); (b) a non-empty note on an ayah with a bookmark of the scope replaces that bookmark's note, leaving its id, page,
  owner and time as they are, and creating nothing; (c) an empty note on an ayah with a bookmark clears its note and keeps the
  bookmark; (d) an empty note on an ayah with no bookmark does nothing and shows no message. After (a) to (c) a short message
  with «تراجع» MUST appear, naming the ayah; «تراجع» MUST bring back exactly the state before the save (the bookmark removed
  after (a), the previous note back after (b) and (c)). A failed write keeps the field open with the typed text and shows
  nothing as saved. Editing the note of a page bookmark stays out of scope.
- **FR-022**: The tint MUST be drawn only for the ayah bookmarks of the current scope, by the rule of FR-002: following a wird,
  those of the active wird; browsing or with no wird, the general ones. It MUST follow a change of scope (switching the wird,
  entering or leaving browse mode, deleting the wird) at once, and MUST never be drawn for a page bookmark or for another
  scope's bookmark. This is testable: with bookmarks of a wird, of another wird and general ones on one page, exactly the
  words of the current scope's ayat are tinted, in each of the three states.
- **FR-023**: The tint MUST be told apart from the temporary highlight of a long press and of a search result, in both looks
  (Emerald & Gold, Night Reader): the two colours, blended over the page paper, MUST differ in hue by at least 40 degrees
  and be distinct to the eye in the owner's check; and while an ayah has the temporary highlight its words show the highlight
  in place of the tint, looking exactly as before this feature. The page text drawn on the tint MUST keep a contrast of at
  least 4.5:1 against the tinted background, in both looks, in the measured test. The tint MUST also stay visible: against the
  bare paper its blended colour differs from the paper (a stated minimum is set in the plan and tested).
- **FR-024**: Settings MUST get one switch for the tint, on by default, saved at once, kept across restarts, carried by the
  backup, changing the reader live (no restart). Off, no page draws a tint; every other behaviour of this feature is as with it
  on. The proposed label is in Assumptions.
- **FR-025**: Each page MUST tint exactly the words of a bookmarked ayah that are drawn on it, taken from the page's own
  words and never from the bookmark's stored page, including a surah's first ayah whose title is on the previous page. (No
  ayah crosses a page in this edition: see the correction of 2026-11-26.)
- **FR-026**: The tint MUST appear in the first frame after the write that adds the bookmark is known to have succeeded, and
  disappear in the first frame after a removal, an undo, a delete from the list «علامات», a restore or a wird deletion (within one frame).
  For a delete from the list, "after" means after the sheet closes: the reader reads the table again when the «علامات» sheet
  is closed (feature 006 D2, research D5), so the page behind keeps the tint while the sheet is open. It MUST NOT slow page
  turning: a page turn builds the incoming Mushaf page at most once and no other page, with the tint on and with 200 ayah
  bookmarks (the budget of feature 010 SC-003); adding or removing one bookmark rebuilds at most the pages that show it; a
  database answer that changes no tint rebuilds no page; the tint of a page is worked out from rows already in memory, never by
  a database read in a frame of a turn; and on the owner's phone the page-turn frame numbers of feature 010 SC-001 still hold
  with 200 bookmarks in the database and the tint on.
- **FR-027**: The page picture and the surah PDF that the ayah sheet shares MUST carry no tint (they are not reading aids), as
  they carry no highlight today.
- **FR-028** (the owner's request of 2026-11-25, after trying the feature): besides editing, the reader MUST be able to read
  an ayah's note in full. When the ayah's bookmark of the current scope has a note (not empty after trimming), the ayah sheet
  MUST show a second visible row «عرض الملاحظة» right after «ملاحظة للآية». A tap opens the whole note, never cut, under the
  title of the note field, with two buttons: «تعديل» opens the note field prefilled (the same flow as «ملاحظة للآية») and
  «إغلاق» (or the back gesture) returns to the sheet, which stays open; reading writes nothing. With no note the row is not
  shown. The row and the two buttons keep 48 px targets, and the note scrolls at 320 dp with a 2x system font. The three
  strings were confirmed by the owner with the others (T048), and he checked the row on the phone (T051).

### Key Entities *(include if feature involves data)*

- **Bookmark** (existing, extended): an id, a page 1 to 604, an optional note (at most 200 characters when typed in the app),
  the wird it belongs to or none (general), the time it was added, and now an optional ayah: a surah (1 to 114) and an ayah
  number that exists in it, both or neither. A bookmark with an ayah is an ayah bookmark; one without is a page bookmark. The
  page of an ayah bookmark is where the ayah begins.
- **Ayah reference** (existing, unchanged): surah and ayah number, as the ayah sheet and search already use.
- **Bookmark change** (existing from feature 006 as the toggle, extended): what one tap or one save added, removed or
  rewrote, kept by the message so that «تراجع» undoes exactly that action; it now concerns a page, an ayah, or the note of an
  ayah.
- **Backup file** (existing, extended): version 1 (page bookmarks only) is still read; version 2 adds the ayah of a bookmark.
- **Tint setting** (new, one stored switch): on or off, on by default, stored with the other settings.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An ayah is bookmarked with a long press and one tap on the action (two touches, no dialog); the bookmark count
  grows by exactly 1 per bookmarked ayah, never by 2.
- **SC-002**: The bookmark action shows the right state (add or remove) within one frame of the sheet appearing and within
  one frame of a tap, in 100 percent of the tested cases (first ayah of surah 1, last ayah of 114, the longest ayah 2:282
  (no ayah crosses a page in this edition), an ayah with bookmarks of two wirds, an ayah of a deleted wird).
- **SC-003**: Zero data loss on update: with a database of N existing rows in each table (at least 50 bookmarks, general and
  of several wirds, with and without notes, plus wirds, portions and settings) made by the previous layout in a real database
  file, 100 percent of the rows are present and equal after the update, 0 of the old bookmarks is an ayah bookmark, the
  migrated layout equals a fresh install's, and an interrupted update (stopped after its first step) leaves the data intact
  and finishes on the next start.
- **SC-004**: A version-1 backup file restores 100 percent of its content; a backup with ayah bookmarks restores equal to what
  was exported (round trip on at least 20 ayah bookmarks in 3 scopes, notes included); a file of a newer version, or with an
  invalid ayah bookmark (3 kinds: no such ayah, surah alone, wrong page), is refused with nothing changed.
- **SC-005**: Opening an ayah bookmark from the list lands on the page where the ayah begins with exactly that ayah's words
  on the page highlighted, in 100 percent of the tested cases (including 2:282 on page 48), and the first touch clears it.
- **SC-006**: In the list an ayah row and a page row are told apart without colour (an icon and the word «آية»), in both
  looks (2 of 2).
- **SC-007**: At 320 dp wide with a 2x system font, in both looks, at 80, 100 and 150 percent, the ayah sheet (both actions),
  the note field, the list and the Settings switch show no overflow and nothing is cut off (every combination); every touch
  target is at least 48 by 48 px; contrast is at least 4.5:1 in every state in both looks.
- **SC-008**: After any action of this feature the wird position, khatma count, today's portions, reminders, last viewed page,
  other bookmarks and settings are the same as before it (checked on a wird and in browse mode).
- **SC-009**: «تراجع» brings the bookmarks back to exactly the state before the tap or save (same ayat, owners, notes, times
  and count) in 100 percent of the tested cases (an add, a removal of one, a removal of two, a note added, replaced and
  cleared, a page-icon removal).
- **SC-010**: The page rectangle, the page glyphs, the position of every word and line, and the top bar height are equal to
  the values before the feature, with the tint on or off (0 px difference), and the existing tests of features 001, 002, 006,
  010 and 011 pass without any change (FR-020's one exception aside).
- **SC-011**: On the owner's phone, after the update installed over the current release build, the owner finds all existing
  bookmarks, wirds and positions as they were, adds an ayah bookmark from its menu on the first try, adds an ayah note with
  «ملاحظة للآية», sees the tint, and opens a bookmark from the list to the highlighted ayah (owner's own check, Constitution
  IX).
- **SC-012**: With a page that holds a page bookmark and an ayah bookmark of the scope, the top-bar icon's tap removes the
  page bookmark and leaves the ayah bookmark in 100 percent of the tested cases (wird mode, browse mode, undo included); the
  regression test fails on the code before the fix.
- **SC-013**: The note flow gives the right result in all four cases of FR-021 (create, replace, clear, nothing) and for
  cancel, in 100 percent of the tested cases, and the note is shown in the list and survives a backup round trip.
- **SC-014**: With bookmarks of the wird, of another wird and general ones on one page, exactly the words of the current
  scope's ayat are tinted (3 of 3 scope states), and none for a page bookmark; 2:282 is tinted on page 48 and
  nothing of it on pages 47, 49 and 50.
- **SC-015**: In both looks the tint and the temporary highlight differ in hue by at least 40 degrees over the page paper, the
  page text on the tint has contrast at least 4.5:1 (measured, with the numbers recorded), and the owner tells the two apart
  on the phone.
- **SC-016**: The tint shows in the first frame after an add and goes in the first frame after a removal, an undo, a delete
  from the list (once the list sheet is closed), a restore or a wird switch (tested by frame counts); the page-turn rebuild counts of feature 010 SC-003 hold with 200 bookmarks and
  the tint on; on the phone the frame numbers of feature 010 SC-001 hold with the same data.
- **SC-017**: With the setting off no word of any page is tinted; switched on again it returns without a restart; the setting
  is carried by a backup round trip (3 of 3).

## Assumptions

- **What was read in the code on 2026-11-25**: the bookmarks table has an id, a nullable wird (set to null when the wird is
  deleted), a page 1 to 604, a nullable note and a creation time, at database version 1 and with no migration yet; the page
  bookmark toggle of feature 006 works on the page and the scope only, so today it would also count and remove any ayah
  bookmark on the page, which is why FR-011 exists; the backup is a JSON file with app «mushaf-hafiz» and version 1, and the
  current code already refuses a version above its own with «هذه النسخة الاحتياطية أحدث من هذا التطبيق. لم يتغيّر شيء.»; the
  ayah sheet is opened by a long press and identifies the ayah by surah and ayah; a search result already shows a page with
  its ayah highlighted until the next touch or turn; the list's only dialog adds a bookmark with an optional note (at most 200
  characters) for the shown page and no bookmark can be edited today.
- The page of an ayah bookmark is where the ayah begins, as feature 011 shows it, taken from the Mushaf data of the fixed
  edition; it is never typed by the user.
- An ayah bookmark added by the bookmark action has no note. A note is written only through «ملاحظة للآية» (FR-015, FR-021). A
  bookmark's note can be changed only by that action, and only for ayah bookmarks; page bookmarks are still never edited,
  only added and deleted, as today.
- The sheet closes after a tap on the bookmark action or after a save of the note, and the message shows in the reader, the
  same message style as feature 006, long enough to read and to tap «تراجع». Cancelling the note field does not close the
  sheet.
- The backup writes version 2 only when at least one bookmark is an ayah bookmark, and version 1 (without the surah and ayah
  keys) otherwise. A file with page bookmarks only is therefore still readable by an older build; this is the author's decision
  of 2026-11-25 (the first draft said "always 2"): it is the same format read by one parser, not a second format to keep, it
  lets the existing assertion that a fresh export says version 1 stay true, and it limits the reach of the "refused by an
  older build" case to files that really need the new fields. Moving back to an older build on a phone that already has the new
  database is not supported: updates only go forward.
- The tint is a reading aid of the reader's page only: not drawn in the shared page picture or the surah PDF (FR-027), and
  not for page bookmarks (a page bookmark marks no ayah).
- The tint colours, the exact limits of FR-023 and FR-026 and their measurements are the plan's to fix; the requirement here is
  that they hold and are tested.
- Feature 012 (web) is paused and is not touched; it will read the same backup file.
- The Arabic strings (Constitution VI), proposed by the author and confirmed by the owner word by word on 2026-11-25
  («كلها تمام», T048); X is the surah's name as the index writes it, N the ayah number and P the page, in Western digits as
  elsewhere. «ملاحظة للآية» is the owner's own wording for the note action:

| Where | Proposed string |
|---|---|
| Bookmark action, state add (label, tooltip) | «إضافة علامة على الآية» |
| Bookmark action, state remove | «إزالة العلامة من الآية» |
| Heard by a screen reader, state add / remove | «ليس عليها علامة» / «عليها علامة» (the strings of feature 006) |
| Message after an add | «تمت إضافة علامة على سورة X · آية N» |
| Message after a removal | «تمت إزالة العلامة من سورة X · آية N» |
| Undo button | «تراجع» (feature 006) |
| Note action label | «ملاحظة للآية» (the owner's wording) |
| Note action, heard by a screen reader, with / without a note | «عليها ملاحظة» / «ليس عليها ملاحظة» |
| Note action, line under the label when the ayah has a note | the start of the note itself (one line) |
| Note field title | «ملاحظة على سورة X · آية N» |
| Note field label | «الملاحظة» |
| Note field line when the ayah has no bookmark yet | «ستُضاف علامة على الآية مع الملاحظة» |
| Note field line when the ayah has a bookmark | «اترك الحقل فارغًا لإزالة الملاحظة وإبقاء العلامة» |
| Note field buttons | «إلغاء» / «حفظ» (as the page note dialog) |
| Message after a note creates the bookmark | «تمت إضافة علامة مع ملاحظة على سورة X · آية N» |
| Message after a note replaces another | «تم حفظ الملاحظة على سورة X · آية N» |
| Message after a note is cleared | «تمت إزالة الملاحظة من سورة X · آية N» |
| List row title | «سورة X · آية N» |
| List row page | «ص P» (as today) |
| List row semantics label | «علامة على سورة X آية N، صفحة P، ثم اسم الورد أو عامة» |
| Word marking an ayah row (tag or label) | «آية» |
| Owner tag | the wird's name, or «عامة» (as today) |
| Note field, when saving fails | «تعذّر الحفظ، حاول مرة أخرى» |
| Row that shows the whole note (FR-028) | «عرض الملاحظة» |
| Buttons of the note view (FR-028) | «تعديل» / «إغلاق» |
| Settings switch title | «تظليل الآيات التي عليها علامة» |
| Settings switch line under it | «ظلّ خفيف خلف كل آية عليها علامة في صفحة المصحف» |
| Refusal of a newer file | «هذه النسخة الاحتياطية أحدث من هذا التطبيق. لم يتغيّر شيء.» (existing) |
| Refusal of an invalid file | «ملف النسخة الاحتياطية تالف أو غير صالح. لم يتغيّر شيء.» (existing) |

- The phone check follows Constitution IX and includes the update installed over the existing release build; the owner is asked
  before any install or input on the phone (the phone <phone> is never unlocked by the agent), and a backup file is
  exported first as a precaution.
