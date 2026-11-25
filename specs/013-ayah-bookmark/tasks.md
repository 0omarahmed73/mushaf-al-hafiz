# Tasks: Ayah Bookmark

**Input**: `specs/013-ayah-bookmark/` (spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md,
checklists/requirements.md, checklists/ayah-bookmark.md)

**Rules**: test-first: a failing test is written and run red before the code that makes it pass (Constitution IX), so each
implementing task is preceded by its failing-test task, and a test task's commit is red for its own file until its
implementing task (every other suite stays green on every commit; run only the new file for the red check). One commit per
task; `git add` explicit paths only and `dart format` on explicit files only (other sessions edit this tree: never
`git add -A`, never `git commit -a`); check `git status` and `git log -- <file>` before every task. **New tests go in NEW
files** (`test/migration/`, `test/ayah_bookmarks/`, helper `test/support/ayah_bookmark_harness.dart`): the tests of features
001 to 011 are never edited and must keep passing (spec FR-020), with the exceptions of T007 and T011 (one number each,
research D13).
`.specify/feature.json` is NOT changed (speckit scripts run with `SPECIFY_FEATURE_DIRECTORY=specs/013-ayah-bookmark
SPECIFY_FEATURE_NO_PERSIST=1`). No git branch, never push. The Quran text, page data, fonts and layout code are never touched;
**no new package, permission, asset or table**. After every task that edits `reader_screen.dart`, `mushaf_page.dart`,
`reader_controller.dart`, `ayah_sheet.dart`, `bookmarks_sheet.dart`, `app.dart`, `main.dart` or `wird_repository.dart` run the
earlier suites: `flutter test test/mushaf test/look test/bookmarks test/onboarding test/motion test/ayah test/settings
test/search test/backup test/wirds test/khatm test/kahf`. Features 005, 006, 010 and 011 code in those files is not
refactored: only the additions named in the task and, for 006, the two lines of the fix (T008, T017).
Known harmless issue (feature 006 T020): at 320 dp the reader's bottom bar overflows; ignore errors whose widget chain
contains `_BottomBar`. Lesson from features 006 and 010: a widget test that writes the database inside `tester.runAsync`
while a drift `watch*` stream is listened in the fake-async zone can hang; write through the app or before the pump; real
asset loading in widget tests runs outside the fake clock (`settleReader` of `test/support/`). Write an Arabic character
itself in a Dart test string, never an escape. Commit trailer: `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.

**Phone tasks** are marked **[PHONE]**: the phone <phone> is never unlocked by the agent; any input and any install needs
the owner's OK in chat for that step; the owner exports a backup first (quickstart). **Owner task** **[OWNER]**: Constitution
VI, the feature is not done before it. **Shared-file windows [R]** mark an edit of `reader_screen.dart` /
`mushaf_page.dart` / `ayah_sheet.dart` / `bookmarks_sheet.dart`: minimal, additive, one commit, after `git status` is clean
for that file and `git log -- <file>` shows no unfinished work of another session.

Key: **FR/SC** are the spec's ids; "data-model.md X" is the field or rule implemented; "D#" is a research decision.

## Phase 1: Setup (before ANY edit of `lib/`)

- [x] T001 [US4] Write `test/migration/make_v1_fixture_test.dart`, skipped unless `--dart-define=MAKE_DB_V1=true`, with a header
  saying it is only valid against the version-1 layout; run it on the UNCHANGED code: it opens a file database through the
  real `AppDatabase` and `WirdRepository`, fills at least 50 bookmarks (general and of 3 wirds, with and without notes, pages
  1 and 604, Arabic notes up to 200 characters), 3 wirds, 12 portions and 8 settings (`activeWirdId`, `textSizePercent`,
  `appLook`, ...), closes it, writes `test/migration/fixtures/mushaf_v1.sqlite` and `mushaf_v1_expected.json` (every row of
  every table as text, with ISO times). Commit the test and both files together; confirm `PRAGMA user_version` of the file is 1
  (spec FR-013, SC-003; D2; data-model.md Bookmarks, Settings)
- [x] T002 [US7] Record the geometry baseline on the unchanged code: `test/ayah_bookmarks/reader_tint_geometry_test.dart`
  pumps the reader through `test/support/reader_harness.dart` at 412 x 915 and 320 x 640 in both looks
  (`LookChoice.emerald`, `LookChoice.night`) at 100 percent, measures the rectangles of the page card, the 15 `line-N`, five
  words per page (`w<id>`), the surah banner, `page-number` and `top-bar` on pages 1, 2, 48, 49 and 604, prints them, and
  the numbers become literals (tolerance 0.01); run green on the unchanged code and commit **before any edit of `lib/`**
  (spec FR-016, SC-010; D6, D11)
- [x] T003 [P] Write the failing `test/ayah_bookmarks/ayah_bookmark_strings_test.dart` that pins every string of the spec's
  Assumptions table, for surah «البقرة» ayah 282 and page 48 (function strings) and as constants, and checks `kBookmarkUndo` of
  feature 006 is the undo label (spec FR-017, Constitution VI; contracts/dart-interfaces.md strings)
- [x] T004 Create `lib/mushaf/ayah_bookmark_strings.dart` with exactly those strings, marked in a doc comment as proposals
  awaiting T048 (the owner's wording «ملاحظة للآية» noted); make T003 green (spec FR-017; contracts/dart-interfaces.md)

---

## Phase 2: Foundational (data, repository, backup, pure logic; blocks every story; nothing visible changes)

**US4: nothing is lost on update or restore**

- [x] T005 [US4] Write the failing tests `test/migration/migration_v1_to_v2_test.dart` and `fresh_install_test.dart`: the
  fixture is copied to a temporary file and opened with the new `AppDatabase(NativeDatabase(file))`; every row of `wirds`,
  `wird_days`, `bookmarks`, `settings` equals `mushaf_v1_expected.json` field by field; every bookmark has `surah` and `ayah`
  null; `user_version` is 2; `PRAGMA foreign_key_check` is empty; `PRAGMA table_info(bookmarks)` and the normalised
  `sqlite_master.sql` equal those of a fresh in-memory database; a fresh database is version 2 at once; the constraints (`surah`
  alone, `ayah` alone, `surah` 0 and 115, `ayah` 0 and 287 fail; a page row and an ayah row insert); the interrupted run
  (`migrationDebugHook` throws after step 'surah') then a normal open finishes with all rows equal; a file that already has both
  columns but `user_version` 1 opens without error; 5 000 bookmarks migrate in under 1 s (spec FR-013, SC-003; data-model.md
  Bookmarks.surah, Bookmarks.ayah; D1, D2)
- [x] T006 [US4] Edit `lib/wirds/db.dart`: `Bookmarks.surah` and `Bookmarks.ayah` with the checks of data-model.md,
  `schemaVersion` 2, `onUpgrade` (one transaction, each `addColumn` guarded by `PRAGMA table_info`, `migrationDebugHook`
  test-only parameter), `beforeOpen` unchanged; regenerate `lib/wirds/db.g.dart` with `dart run build_runner build
  --delete-conflicting-outputs`; make T005 green; `flutter analyze` on the files; `test/wirds`, `test/backup`, `test/bookmarks`
  unchanged and green (spec FR-013, FR-008, SC-003; data-model.md Bookmarks.surah, Bookmarks.ayah; D1, D2)
- [x] T007 [US4] Edit the one assertion of `test/backup/backup_service_test.dart` named `version 2 is a newer backup`: the number
  becomes 3 (it passes before and after T011); with the same number in `test/settings/backup_ui_test.dart`, made in T011
  (commit c6f85b4, found when T011 first ran), these are the only edits of existing tests of this feature, with the reason of
  research D13 in the commit message (spec FR-020; D13)

**US1, US2, US8: the repository decides**

- [x] T008 [US2] [US8] Write the failing tests `test/ayah_bookmarks/ayah_bookmark_repository_test.dart` and
  `page_toggle_fix_test.dart` on an in-memory `AppDatabase` (one DB per test): `toggleAyahBookmark` adds one with no note and the
  given page when the scope has none, deletes all of the scope's rows (note included) when it has some, never reads or deletes a
  page bookmark, another wird's, or a general one when `wirdId` is set (and the reverse); two rows of the scope (made by
  restore) are both removed; `ArgumentError` for page 0 and 605; `saveAyahNote` the four cases of data-model.md (create with
  note; replace on every row of the scope keeping id, page, owner, time; clear keeping the bookmark; empty on none returns null
  and writes nothing), trimming, spaces only = empty; `undoAyahBookmarkChange` for each kind restores exactly (ids, `createdAt`,
  notes, surah, ayah; a deleted wird comes back general; twice changes nothing); `ayahBookmarkRows`; `ayahMarksOf`; and the **006
  regression**: with a page bookmark and an ayah bookmark of the scope on one page, `toggleBookmark` removes only the page
  bookmark and returns it in `removed`; with only an ayah bookmark it adds a page bookmark and leaves the ayah one; the
  undo restores exactly the page rows. Run it red on today's code (spec FR-003, FR-004, FR-005, FR-006, FR-011, FR-021,
  SC-001, SC-009, SC-012, SC-013; data-model.md AyahBookmarkChange, the four saves)
- [x] T009 [US2] [US8] Create `lib/wirds/ayah_bookmark_change.dart`; edit `lib/wirds/wird_repository.dart`: fix
  `toggleBookmark` (page bookmarks only), add `ayahBookmarkRows`, `toggleAyahBookmark`, `saveAyahNote`,
  `undoAyahBookmarkChange`, `ayahMarksOf`, `ayahTintRaw`, `setAyahTint`, each transaction as research D4 says (`Bookmarks.wirdId` by the scope rule, `Bookmarks.page`, `Bookmarks.note` trimmed, `AyahBookmarkChange.kind/addedId/removed/before`; data-model.md); make T008 green;
  `test/wirds`, `test/bookmarks` unchanged and green (spec FR-003 to FR-006, FR-011, FR-021; D4; contracts/dart-interfaces.md)

**US4: backup**

- [x] T010 [US4] Write the failing `test/ayah_bookmarks/ayah_bookmark_backup_test.dart` (the real meta through
  `MushafRepository(FileBundle()).loadMeta()` of `test/support/motion_probe.dart`): an export with no ayah bookmark is exactly
  version 1 with no `surah`/`ayah` keys (compared with the current bytes); with one it is version 2 and every bookmark has both
  keys; a round trip of at least 20 ayah bookmarks in 3 scopes with notes into another database is equal field by field
  (surah, ayah, page, note, owner, time) and the settings `ayahTint` too; a version-1 file restores completely; a version-1
  file with a surah is invalid; invalid ayah bookmarks (no such ayah 2:287, surah alone, ayah alone, page not the ayah's page,
  surah 0 / 115) are refused as `invalid` with nothing changed; version 3 is `newerVersion` with nothing changed; the exported
  version-2 file says 2, which the rule `version > 1` of an older build refuses (cite `lib/backup/backup_service.dart`); a file
  with an ayah bookmark and a service with no meta is invalid; the import still fails halfway to nothing (the existing
  `debugHook` stages) (spec FR-014, SC-004; data-model.md Backup file; D3)
- [x] T011 [US4] Edit `lib/backup/backup_service.dart`: `kBackupVersionAyah`, `kBackupHighestRead`, `kBackupVersion` kept at 1,
  `BackupService(db, {debugHook, meta})`, the version rule, the export keys, the import validation; edit `lib/main.dart` (one
  line: `meta: await mushafRepository.loadMeta()` into `BackupService`); make T010 green; `test/backup`, `test/kahf` unchanged
  and green (spec FR-014; D3)

**Pure logic and settings**

- [x] T012 [P] [US7] Write the failing `test/ayah_bookmarks/ayah_tint_ids_test.dart` on real page data (`FileBundle`): an
  ayah of one page gives exactly its words' ids, the end marker included; 2:282 is wholly on page 48 (and nothing of it on 47, 49, 50:
  no ayah crosses a page in this edition, spec correction of 2026-11-26); an empty set gives empty; two ayat give the union; an ayah not on the page gives empty;
  the surah-start ayah that begins on the previous page is found by its words (spec FR-016, FR-025, SC-014; D6)
- [x] T013 [P] [US7] Create `lib/mushaf/ayah_tint.dart` (`ayahTintIds`); make T012 green (spec FR-025; D6)
- [x] T014 [P] [US7] Write the failing `test/ayah_bookmarks/ayah_tint_settings_test.dart`: `enabled` is true with nothing or
  junk stored, false for `'false'`; `set(false)` saves and notifies once, the same value again notifies nobody; `reload()`
  follows a value written behind its back (a restored backup); `load()` never writes (spec FR-024, SC-017; data-model.md Settings
  `ayahTint`; D7)
- [x] T015 [P] [US7] Create `lib/settings/ayah_tint_settings.dart` (uses `ayahTintRaw`/`setAyahTint` of T009; data-model.md Settings `ayahTint`: absent or unknown text is on); make T014 green
  (spec FR-024; D7)

**Controller**

- [x] T016 [US1] [US8] Write `test/support/ayah_bookmark_harness.dart` (seeding bookmarks by ayah, pumping the reader with the
  fake share/ayah bundle, finders for `ayah-bookmark`, `ayah-note`, the message) and the failing
  `test/ayah_bookmarks/controller_ayah_test.dart` (a real `ReaderController` over an in-memory repository, real meta): `ayahMarks`
  is empty before `init()` ends, holds the scope's ayat only, follows `switchWird`, `jumpTo`, `makeThisMyPosition`, deletion of
  the wird and an add, remove and restore done straight on the repository (the list sheet's path), is replaced only on a real
  change (count notifications); `pageBookmarked` is false for a page with only an ayah bookmark and true with a page bookmark;
  `toggleAyahBookmark` and `saveAyahNote` store `pageOfAyah` as the page, own the bookmark by the scope rule, return null
  while busy, and never call `notifyListeners` (spec FR-002, FR-003, FR-005, FR-011, FR-022, SC-002; data-model.md Scope,
  Controller state; D5)
- [x] T017 [US1] [US8] Check `git status` / `git log -- lib/mushaf/reader_controller.dart`, then edit it: `pageBookmarked`
  filters `b.surah == null` (the 006 fix), `ayahMarks`, `attachMeta`, `ayahState`, `toggleAyahBookmark`, `saveAyahNote`,
  `undoAyahBookmarkChange` with the shared busy guard (data-model.md Controller state `pageBookmarked`, `ayahMarks`, `_toggleBusy`; `Bookmarks.page` = `pageOfAyah`); make T016 green; the existing controller tests unchanged and green (spec
  FR-003, FR-011, FR-022; D5; contracts/dart-interfaces.md)

---

## Phase 3: User Stories 1 and 2 (P1): add and remove an ayah bookmark from the sheet

**Independent test**: long press a word, tap the bookmark row, the list gains one entry; long press again, the row reads
«remove»; tap it, the bookmark is gone; «تراجع» brings it back.

- [x] T018 [P] [US1] [US2] Write the failing `test/ayah_bookmarks/ayah_sheet_rows_test.dart` (the sheet alone with a fake
  `AyahBookmarkPort` whose `state` is synchronous: the first frame already shows the right state): the bookmark row `ayah-bookmark` sits in the ayah's group after «معاني الكلمات», not in «الصفحة
  والسورة»; label, icon and semantics value per state (`isSemantics(isButton: true, hasTapAction: true, label, value)`, dispose
  the handle); at least 48 x 48; a tap calls `toggle` once, pops the sheet and calls `onChange`; with no port the sheet has
  exactly the rows it has today; no row has a long-press handler (spec FR-001, FR-002, FR-017, SC-002; contracts/ui.md §1)
- [x] T019 [US1] [US2] Create `lib/ayah/ayah_bookmark_port.dart`; **[R]** edit `lib/ayah/ui/ayah_sheet.dart` additively: optional
  `bookmarks` on `showAyahSheet` and `AyahSheet`, `SheetRow.semanticsValue`, the bookmark row; make T018 green; `test/ayah`
  unchanged and green (spec FR-001, FR-002; D8; contracts/dart-interfaces.md)
- [x] T020 [US1] [US2] Write the failing `test/ayah_bookmarks/reader_ayah_bookmark_test.dart` (reader harness, new file): long
  press a word, tap `ayah-bookmark`: exactly one ayah bookmark with the ayah, `pageOfAyah` as page (also 2:282 on 48), no note,
  owned by the wird (wird mode) or general (browse mode); the message «تمت إضافة علامة على سورة X · آية N» with «تراجع» above
  the bottom bar; «تراجع» removes it; the sheet again says «remove»; a tap removes with the removal message and «تراجع»
  restores with note and time; a bookmark of another wird is neither shown nor touched; a quick double tap leaves one or none;
  a failing write shows no «added» message; the wird position, khatma count, today's portions, last viewed page and settings are
  unchanged after each action; the ayah highlight ends after the tap (spec FR-003 to FR-007, FR-019, SC-001, SC-008, SC-009)
- [x] T021 [US1] [US2] **[R]** Edit `lib/mushaf/reader_screen.dart` (minimal, additive): `_controller.attachMeta(meta)` where the
  meta is loaded, the `AyahBookmarkPort` built from the controller and passed to `showAyahSheet` in `_openAyahMenu`, and a new
  helper `_showAyahBookmarkMessage(AyahBookmarkChange)` (the 006 `_toggleBookmark` is not changed or refactored; the message
  strings come from T004); make T020 green; run the earlier suites (spec FR-006, FR-007; D8, D12)

---

## Phase 4: User Story 3 (P1): the list and going back to the ayah

- [x] T022 [P] [US3] Write the failing `test/ayah_bookmarks/bookmarks_list_ayah_row_test.dart` (the sheet over an in-memory
  repository): an ayah row shows «سورة X · آية N», «ص P», its note (3 lines max) and the owner tag, has
  `Icons.auto_stories_outlined` that a page row does not, semantics label «علامة على سورة X آية N، صفحة P، ثم ...»; page rows are
  unchanged (same widgets as before); one list, newest first; the swipe deletes either kind; a tap on an ayah row pops an
  `AyahTarget` with the ref and the page, a tap on a page row pops the `int`; a long surah name does not push «ص P» out at 320 dp
  with a 2x font (spec FR-010, SC-006; contracts/ui.md §4)
- [x] T023 [US3] **[R]** Edit `lib/wirds/bookmarks_sheet.dart` additively: optional `meta`, the ayah row in `_BookmarkTile`, the
  `AyahTarget` pop; make T022 green; `test/bookmarks` unchanged and green (spec FR-010; D10)
- [x] T024 [US3] Write the failing reader tests (added to a new file `test/ayah_bookmarks/reader_open_ayah_bookmark_test.dart`):
  opening an ayah row closes the sheet, shows the page where the ayah begins in browse mode with the wird unmoved, exactly that
  ayah's words highlighted (2:282 on page 48), brought into view; on the page already shown only the highlight and reveal
  happen; the first touch clears the highlight; a page row still jumps as before (spec FR-012, SC-005; D10)
- [x] T025 [US3] **[R]** Edit `lib/mushaf/reader_screen.dart` `_openBookmarks`: `showModalBottomSheet<Object>`, pass `meta` to
  the sheet, `AyahTarget` result goes to `_showFoundAyah`, an `int` to `jumpTo` as today; make T024 green; run the earlier suites,
  including `test/search` (spec FR-012; D10)

---

## Phase 5: User Story 8 (P1): the page icon keeps its own meaning

- [x] T026 [US8] Write `test/ayah_bookmarks/reader_page_icon_test.dart` through the reader: a page with only an ayah bookmark
  of the scope shows the outlined icon; a tap adds a page bookmark, the ayah bookmark is untouched; a page with both: a tap
  removes only the page bookmark and the message undo brings back exactly it (id, note, owner, time) and the ayah bookmark and
  its note never changed; in wird mode and in browse mode; another scope's bookmarks never count. These pass on the code of
  T009 and T017; prove the regression is real by temporarily reverting only the two filters (`surah.isNull()` in
  `toggleBookmark`, `b.surah == null` in the controller), running this file red, and restoring them; record the red result
  in the commit message (spec FR-011, SC-012, SC-009)

---

## Phase 6: User Story 6 (P2): the note

**Independent test**: «ملاحظة للآية» creates the bookmark with a note, replaces it, clears it; cancel changes nothing.

- [x] T027 [P] [US6] Write the failing `test/ayah_bookmarks/ayah_note_dialog_test.dart`: title «ملاحظة على سورة X · آية N»; the
  field is `ayah-note-field`, opens with the current note, autofocus, stops at 200 characters; the line under it is
  «ستُضاف علامة على الآية مع الملاحظة» when there is no bookmark and «اترك الحقل فارغًا لإزالة الملاحظة وإبقاء العلامة» when there
  is; «حفظ» calls `onSave` with the typed text and closes with true; «إلغاء», the back gesture and a tap outside return
  false/null and call nothing; when `onSave` throws the dialog stays open with the typed text and shows «تعذّر الحفظ، حاول مرة
  أخرى»; targets 48 px (spec FR-015, FR-021; contracts/ui.md §2)
- [x] T028 [US6] Create `lib/ayah/ui/ayah_note_dialog.dart` (`showAyahNoteDialog`; the field stops at 200 characters: data-model.md Bookmarks.note); make T027 green (spec FR-015; D9)
- [x] T029 [P] [US6] Write the failing note rows in `test/ayah_bookmarks/ayah_sheet_note_row_test.dart`: the row `ayah-note`
  «ملاحظة للآية» comes right after the bookmark row, is a visible full row with no gesture needed, shows the start of the note
  as a line and the value «عليها ملاحظة» / «ليس عليها ملاحظة»; a tap opens the dialog prefilled; cancel leaves the sheet open; a
  save pops the sheet and calls `onChange` with the repository's change; case (d) pops the sheet and calls nothing (spec FR-001,
  FR-015, FR-021; contracts/ui.md §1)
- [x] T030 [US6] Write the failing reader tests `test/ayah_bookmarks/reader_ayah_note_test.dart` (written before the row exists, so
  red): a note on an unbookmarked ayah creates one bookmark with that note owned by the scope and shows «تمت إضافة علامة مع ملاحظة
  على سورة X · آية N»; on a bookmarked ayah it replaces the note, no second row, id, page, owner and time unchanged, «تم حفظ
  الملاحظة ...»; an empty save clears the note and keeps the bookmark, «تمت إزالة الملاحظة ...»; an empty save on no bookmark
  creates nothing and shows nothing; «تراجع» restores exactly after each of the three; removing a bookmark that has a note and
  «تراجع» bring the note back; the note shows in the list as a page note does and survives a backup round trip; a note saved for
  one scope is not shown in another; nothing of the wird moves (spec FR-021, FR-004, FR-019, SC-009, SC-013; data-model.md
  Bookmarks.note, AyahBookmarkChange.before)
- [x] T031 [US6] **[R]** Edit `lib/ayah/ui/ayah_sheet.dart` additively: the note row and the wiring to `showAyahNoteDialog` and
  the port's `saveNote` (the reader's port and message helper were built in T021 for every change kind); make T029 and T030 green;
  `test/ayah` unchanged and green (spec FR-015, FR-021; D8, D9; data-model.md Bookmarks.note)

---

## Phase 7: User Story 7 (P2): the tint on the Mushaf page

**Independent test**: bookmark an ayah, the next frame has a light tint behind its words and nothing moved; remove it, gone; the
setting off, none anywhere.

- [x] T032 [P] [US7] Write the failing `test/ayah_bookmarks/tint_contrast_test.dart`: from the tokens of `PageLook` in both looks
  it computes the tint blended on the paper and asserts: ink on it at least 4.5:1 (expected 12.04 / 11.69), Night's end marker on
  it at least 4.5:1 (7.0), the tint against the bare paper between 1.15 and 1.50, its hue at least 40 degrees from the
  highlight's blended hue (57 / 125), the highlight's wash stronger than the tint's; prints the numbers (spec FR-023, SC-015;
  D6)
- [x] T033 [US7] Edit `lib/mushaf/page_look.dart`: `bookmarkTint` (`0x290F766E` Emerald, `0x24E4C877` Night, default
  `0x290F766E`); make T032 green (spec FR-023; D6)
- [x] T034 [P] [US7] Write the failing `test/ayah_bookmarks/mushaf_page_tint_test.dart`: `MushafPage` with `tintedWordIds`
  decorates exactly those words with `tintColor` (a `DecoratedBox`, radius 4); a word in both sets shows the highlight colour and
  not the tint; no set means the widget tree equals today's; every word and line rectangle is identical with and without the tint
  (0 px); the words keep their `ValueKey('w<id>')` (spec FR-016, FR-023, SC-010; contracts/dart-interfaces.md)
- [x] T035 [US7] **[R]** Edit `lib/mushaf/mushaf_page.dart` (`tintedWordIds`, `tintColor`, the one `else if` in `_word`) and
  `lib/mushaf/mushaf_page_card.dart` (pass them through, `look.bookmarkTint`); make T034 green; `test/mushaf`, `test/search`,
  `test/render`, `test/motion` unchanged and green (spec FR-016; D6)
- [x] T036 [US7] Write the failing `test/ayah_bookmarks/reader_tint_test.dart` through the reader: with bookmarks of the wird, of
  another wird and general ones on one page, exactly the current scope's ayat have their words tinted in each of the three states
  (wird, browse, no wird), none for a page bookmark; 2:282 is tinted on page 48 and nothing on page 49; two ayat that follow each other are tinted separately, word by word; a long press shows the highlight
  in place of the tint and the tint is back after the sheet closes; opening from the list and a search result do the same; the
  tint is present in the first frame after an add, and gone in the first frame after a removal, an undo, a delete from the list
  sheet, a restore (`reload`), a wird switch and a wird deletion; the setting off tints nothing and on again returns without a
  restart; the page picture of `PageRenderer` has no tint (spec FR-016, FR-022 to FR-027, SC-014, SC-016, SC-017)
- [x] T037 [US7] Extend `test/ayah_bookmarks/reader_tint_geometry_test.dart` (T002's file, a second group): the same rectangles
  as the T002 literals with 200 ayah bookmarks and the tint on, in both looks and both sizes, equal (0 px); and
  `test/ayah_bookmarks/reader_tint_rebuild_test.dart` (new): with 200 bookmarks and the tint on, a page turn builds `MushafPage`
  at most once, a bookmark change on another page and a database answer that changes no tint build it 0 times, adding or removing
  one bookmark builds only the pages that show it, a bars toggle builds none; no database read happens in a turn (count
  repository calls); uses `test/support/motion_harness.dart` (spec FR-026, SC-010, SC-016; D6)
- [x] T038 [US7] **[R]** Edit `lib/mushaf/reader_screen.dart` `_PageItem` (additive): a `ValueListenableBuilder` on
  `controller.ayahMarks` (the notifier is passed once as a field so the cached pager is not rebuilt), `context.watch` of
  `AyahTintSettings?`, `ayahTintIds` for its own `PageData`, the ids compared with `setEquals` in `_cardFor`; make T036 and T037
  green; run the earlier suites, `test/motion` above all (spec FR-016, FR-022, FR-025, FR-026; D6, D12)
- [x] T039 [P] [US7] Write the failing `test/ayah_bookmarks/settings_tint_switch_test.dart`: Settings has a switch
  `ayah-tint-switch` titled «تظليل الآيات التي عليها علامة» with the line under it, on by default, a toggle saves at once and the
  reader behind follows, the value comes back after a restart and after a backup restore (the reader reloads it), 48 px, no
  overflow at 320 dp with a 2x font (spec FR-024, SC-017, SC-007; contracts/ui.md §6)
  - Commit fde230a fixed how this test drives the app before T040 made it green: back by `BackButton`, and after a restore
    it waits for the «تم استرجاع النسخة الاحتياطية» message to go; no assertion changed.
- [x] T040 [US7] Edit `lib/settings/settings_screen.dart` (one `SwitchListTile` after the text-size tile), `lib/app.dart`
  (`ayahTint` parameter and `ListenableProvider<AyahTintSettings?>.value`), `lib/main.dart` (create and `load()` before the first
  frame), and **[R]** `lib/mushaf/reader_screen.dart` (`reload()` of it after a restore, with the text size); make T039 green;
  run the earlier suites (spec FR-024; D7)

---

## Phase 8: User Story 5 (P2): both looks, every size

- [x] T041 [US5] Write `test/ayah_bookmarks/ayah_bookmark_look_size_test.dart` (contrast walk of
  `test/support/contrast_walk.dart`): the ayah sheet with both rows in both states, the note field, an ayah row and a page row in
  the list, the Settings switch, in Emerald & Gold and Night Reader, at 80, 100 and 150 percent, at 412 x 915 and 320 x 640 with a
  2x system font, portrait and landscape: no overflow (ignoring the known `_BottomBar` one), every target at least 48 x 48,
  text and icon contrast at least 4.5:1, a look change is followed at once (spec FR-017, SC-006, SC-007)
- [x] T042 [US5] Fix only what T041 finds in the new widgets (`lib/ayah/ui/ayah_sheet.dart` rows, `ayah_note_dialog.dart`,
  `bookmarks_sheet.dart` row, the settings tile), with the failing case kept in the test; if it finds nothing, commit the test
  alone and say so (spec FR-017, SC-007)

---

## Phase 9: Phone, owner, polish

- [x] T043 Run `dart format` on the files of this feature, `flutter analyze` (no issues) and the whole `flutter test`; fix
  nothing outside this feature's files; check that `pubspec.yaml`, `pubspec.lock`, `android/` and `assets/` are unchanged by this feature (`git diff` of the commits since T001; spec FR-018, no package, permission or resource); record the counts and the printed numbers of T032 and T037 in research.md under
  "Measured" (spec SC-010, SC-016; Constitution IX)
- [x] T044 [PHONE] [US4] With the owner present and his OK for each step: he exports a backup first; build the release APK of
  this feature; **install it over the existing release build**; open it: every wird, position, bookmark, text size and look is as
  before; `Settings` and «علامات» open; record what was seen (the real migration of real data; spec SC-003, SC-011; D15,
  quickstart steps 1)
  - Result 2026-11-25: the owner exported a backup and said «سطّب». Release APK (179 571 336 bytes, certificate SHA-256
    9f4dcdaa…7546137c, the same key as the installed build) installed with `adb install -r` over versionCode 1 on
    <phone>: Success; firstInstallTime stayed 2026-11-21, lastUpdateTime 2026-11-25 20:28. The owner opened the app
    himself and answered «كله موجود» to "are your old bookmarks and wird still there". Text size and look were not asked
    about one by one.
- [ ] T045 [PHONE] [US1] [US2] [US3] [US6] [US7] [US8] With the owner: quickstart steps 2 to 9 on the phone in Emerald & Gold and
  Night Reader (the two rows, the message and undo, the note, the list and going back to the ayah, the page icon, 2:282 on page 48,
  the tint against the highlight, the switch, rotation and a large system font, a backup export and import); the page-turn
  frame numbers of `specs/010-smooth-motion/phone/measure.sh` before and after with 200 bookmarks if he wants numbers; never
  unlock the phone; record the owner's words (spec SC-011, SC-015, SC-016)
  - Open at convergence (T049): the owner tried the feature on the phone and confirmed his data (T044) and the show-note row
    (T051), but the steps 2 to 9 were not walked and recorded one by one, so this task stays open.
- [ ] T046 [PHONE] If T044 or T045 finds a defect, fix it test-first (a new failing test in the matching file, then the code),
  one commit each, and re-check only that step with the owner; otherwise this task is closed by a one-line note (spec SC-011)
- [x] T047 [P] Update `docs/research/licenses.md` only if a resource was added (none is expected: write "nothing added" in the
  commit message) and README only if the owner says «ارفع» for the release (spec FR-018)
- [x] T048 [OWNER] The owner confirms every Arabic string of `lib/mushaf/ayah_bookmark_strings.dart` word by word: the bookmark
  row, the note row «ملاحظة للآية», the note field title, label, two lines and failure line, the five messages, the list row,
  the Settings title and line, and «عرض الملاحظة», «تعديل», «إغلاق» (T051); also the details of the note flow listed in the spec's "Author's reading". Any change goes
  through T003's test first and needs his confirmation again. **Blocks "done"** (Constitution VI; spec FR-017)
  - Confirmed 2026-11-25: shown the full list of strings (including «عرض الملاحظة», «تعديل», «إغلاق»), the owner answered
    «كلها تمام».
- [x] T049 Converge (`speckit-converge`): re-read spec, plan, research, data-model, contracts and quickstart against the code
  that was built; fix any document that says something the code does not (numbers measured in T043, a name that changed), mark
  the checklist's notes, set the spec's Status to Implemented, and list what is left (spec all FR/SC; Constitution IX)
  - Result 2026-11-25: converged, no task appended (FR-001 to FR-028 and SC-001 to SC-017 are built and tested; what only
    the phone can show is T045). Documents corrected: the spec (Status, a convergence note, the page-crossing leftovers in a
    clarification, an edge case and SC-002, FR-010/015/017/026/028 and SC-016 as built, the FR-028 strings in the table), the
    plan, research D5/D8/D9/D10 and "Measured", data-model, both contracts, quickstart, both checklists' notes, this file.
    Left: T045 and T046 (the phone walk with the owner). Older, not of this feature: at 320 dp with a 2x system font the Mushaf
    page and the reader's bars overflow (research "Measured").

---

## Phase 10: The owner's request of 2026-11-25 (read the note)

The owner, after trying the feature on the phone: «i want an additional button to show the note not just edit or add».

- [x] T050 [US6] Write the failing `test/ayah_bookmarks/ayah_sheet_show_note_test.dart`: the strings «عرض الملاحظة», «تعديل»,
  «إغلاق»; no row with no bookmark, no note or a note of spaces; with a note the row `ayah-note-show` right after `ayah-note`, a
  full row, 48 px, its own icon; a tap shows the whole note (`ayah-note-view-text`, no line limit) under the note title and
  writes nothing; «إغلاق» and the back gesture return to the open sheet; «تعديل» opens the field prefilled and a save goes
  through the port as from the note row, «إلغاء» writes nothing; a button for a screen reader; at 320x640 and 640x320 with a 2x
  font the note scrolls and both buttons are on the screen (spec FR-028)
- [x] T051 [US6] Add the three strings to `lib/mushaf/ayah_bookmark_strings.dart`, `showAyahNoteView` to
  `lib/ayah/ui/ayah_note_dialog.dart` and the row to `lib/ayah/ui/ayah_sheet.dart` `_bookmarkRows` (additive; the existing
  rows and tests unchanged); make T050 green; T048 now also covers the three strings (spec FR-028)
  - Phone 2026-11-25 21:01: installed over the previous build after the owner's «سطّب» (data kept); the owner tried it and
    answered «تمام».

---

## Dependencies and order

- **T001 and T002 first, before any edit of `lib/`** (the real v1 file and the geometry baseline come from the unchanged code).
  T003 is independent; T004 needs T003.
- T005 needs T001; T006 needs T005. T007 any time before T011 (it passes before and after). T008 needs T006 (the columns);
  T009 needs T008. T010 needs T006 (the schema; it seeds rows straight into the database); T011 needs T010 and T007.
- T012 and T014 are independent of the database tasks; T013 needs T012; T015 needs T014 and T009 (`ayahTintRaw`).
- T016 needs T009 and the real meta; T017 needs T016.
- T018 needs T004; T019 needs T018; T020 needs T016, T017, T019; T021 needs T020. **T021, T025, T038, T040 are the [R] windows of
  `reader_screen.dart`: in this order, each after `git status` is clean for the file.**
- T022 needs T004; T023 needs T022; T024 needs T021 and T023; T025 needs T024.
- T026 needs T009 and T017 (and T021 for the message).
- T027 needs T004; T028 needs T027; T029 needs T019 and T028; T030 needs T021; T031 needs T029 and T030.
- T032 needs T002; T033 needs T032; T034 needs T033; T035 needs T034; T036 needs T013, T015, T017, T035; T037 needs T002, T035;
  **T038 needs T036 and T037**; T039 needs T015; T040 needs T039 and T038.
- T041 needs T031, T023, T040; T042 needs T041.
- T043 needs every code task. T044 needs T043 and the owner. T045 needs T044. T046 only if they find something. T048 needs T004,
  T031, T040 (the strings are final); T049 is last.

## Parallel opportunities

T003 with T001/T002 (a different file); T012, T014 (and later T032, T034, T039) are independent pure or screen-local tests;
T022 and T027 (two files); the owner's reading of the strings (T048) can start as soon as T031 and T040 are committed.

## Implementation strategy

**MVP is Phases 1 to 5**: nothing is lost on update and restore, the bookmark can be added, removed and found again, and the
page icon cannot delete it. Phase 6 adds the note, Phase 7 the tint (the part that touches the Mushaf page, with its numbers
pinned first), Phase 8 proves the quality bars, Phase 9 checks the real update on the phone and asks the owner. Every task is
one commit; the data work (T001-T011) is finished and proved against a real version-1 file before any widget exists, because
that is the part that must never go wrong.

## Summary

| | Count |
|---|---|
| Tasks | 51 (T001-T051) |
| Phases | 10 (Setup 4, Foundational 13, US1+US2 4, US3 4, US8 1, US6 5, US7 9, US5 2, Phone/owner/polish 7, the owner's request 2) |
| Test-first pairs (failing test task or tasks, then the implementing task) | 18 |
| Touching `lib/mushaf/reader_screen.dart` (windows **[R]**) | T021, T025, T038, T040 (4) |
| Other edits of existing `lib/` files | `db.dart` + `db.g.dart` (T006), `wird_repository.dart` (T009), `backup_service.dart` + `main.dart` (T011), `reader_controller.dart` (T017), `ayah_sheet.dart` (T019, T031, T051), `ayah_note_dialog.dart` (new in T028; T042, T051), `bookmarks_sheet.dart` (T023, T042), `page_look.dart` (T033), `mushaf_page.dart` + `mushaf_page_card.dart` (T035), `settings_screen.dart` + `app.dart` + `main.dart` (T040) |
| Edits of existing tests | 2 (T007 and T011, one number each) |
| Phone tasks (owner present) | T044, T045, T046 |
| Owner task | T048 (blocks "done") |
| Converge | T049 |
