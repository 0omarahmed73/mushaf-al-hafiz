# Implementation Plan: Ayah Bookmark

**Branch**: `013-ayah-bookmark` (work stays on `main`, as for features 001 to 011) | **Date**: 2026-11-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/013-ayah-bookmark/spec.md` (clarified on 2026-11-25)

## Summary

A bookmark can now be on an ayah, not only on a page. The ayah sheet (opened by the existing long press) gets two visible
rows: the bookmark action (one tap adds with no note, the next tap removes) and «ملاحظة للآية» (a small note field that
creates the bookmark with a note, replaces the note, or clears it). The Mushaf page draws a light tint behind the words of
every ayah bookmarked in the current scope, through the same per-word decoration the temporary highlight already uses, so
no glyph, line or rectangle moves. The top-bar icon of feature 006 keeps meaning "page bookmark" and its toggle is fixed to
touch page bookmarks only.

The risky part is data: this is the app's **first database migration**. `Bookmarks` gets two nullable columns (`surah`,
`ayah`), checked as "both or neither", added by an idempotent, transactional step 1 to 2, proved by a test that opens a real
version-1 database file. The backup file learns an optional pair of keys: it is written as version 2 only when an ayah
bookmark exists (so a page-only file is still read by older builds and the existing assertions of version 1 stay true), is
read in both versions, and an ayah bookmark is validated against the real ayah counts and the real page of that ayah.

The controller keeps the one-shot list of feature 006 (no stream) and derives from it two things: the page icon (page
bookmarks of the page and scope) and a set of bookmarked ayat of the scope. Each Mushaf page item listens to that set and
turns it into the ids of its own words, so a bookmark change rebuilds only the pages whose tint changed. Nothing is added
to `pubspec.yaml`, no asset, no permission.

## Technical Context

**Language/Version**: Dart 3.14 / Flutter 3.50 (Android first)

**Primary Dependencies**: `package:material_ui`, `drift` (+ `drift_dev` already a dev dependency), `provider`; nothing new

**Storage**: `Bookmarks` gets `surah` and `ayah` (nullable); `schemaVersion` 1 to 2 with `onUpgrade`; one new key `ayahTint`
in the key/value `Settings` table; backup file format version 2 (written only when needed), version 1 still read

**Testing**: `flutter test` with new files only (`test/ayah_bookmarks/`, `test/migration/`), plus two deliberate one-number
edits of existing tests (research D13: `test/backup/backup_service_test.dart`, `test/settings/backup_ui_test.dart`); repository tests on in-memory drift databases; the migration test on a real v1
file; reader tests through `test/support/reader_harness.dart` and `bookmark_harness.dart`; rebuild counts through
`test/support/motion_harness.dart`; contrast walk from `test/support/contrast_walk.dart`; real-device check on the owner's
phone

**Target Platform**: Android phone, portrait and landscape, RTL

**Project Type**: mobile app

**Performance Goals**: a bookmark change shows (tint, sheet state) within one frame of the write's answer (SC-016); a page
turn builds the incoming `MushafPage` at most once and no other (feature 010 SC-003) with 200 ayah bookmarks and the tint
on; the page-turn frame numbers of feature 010 SC-001 hold on the phone with the same data; opening a database with 5 000
bookmarks migrates in under 1 s (measured in a test, a guard, not a promise to the owner)

**Constraints**: offline, no tracking; Quran text, layout and page geometry untouched (0 px difference with the tint on or
off); earlier tests unchanged except research D13; nothing overflows at 320 dp with a 2x system font; targets at least 48
px; contrast at least 4.5:1; data never lost (Constitution VII)

**Scale/Scope**: 2 columns, 1 migration step, 1 setting, 1 corrected repository method, 1 pure
tint function, 7 new repository members (five ayah and note methods, two for the setting), 1 settings notifier, 3 sheet rows (the third, «عرض الملاحظة», only when the ayah has a note: FR-028), 1 note dialog and 1 note view, 1 list row kind, 1 settings switch, backup v2

## Constitution Check

*GATE: passed before research and again after the design (constitution 2.0.0); re-checked at convergence (T049) against
2.1.0, whose change (Principle V and the distribution section: Google Play allowed) touches nothing of this feature.*

| Principle | Check |
|---|---|
| I Quran text integrity | No Quran text, order, font, page data or line distribution is touched. The tint is a background decoration behind existing words, drawn by the decoration the highlight already uses; a test pins every word and line rectangle equal with the tint on and off (D6). The page of an ayah bookmark comes from the fixed edition's `pageOfAyah`, never from the user, and the backup refuses a page that is not that page (D3). **Pass** |
| II Mushaf first | No new screen: the actions live in the ayah sheet that already opens from the page, the tint lives on the page, the list is the existing sheet. The reader still opens on the page; the position is not touched by any action (FR-019). A page-turn rebuild budget and a geometry baseline are tests (D6, D11). **Pass** |
| III No other duas | Not involved (a note is the reader's own text, stored on the phone). **Pass** |
| IV Offline, private, free | Local database only; notes, bookmarks and the tint setting travel only in the backup file; no network, no analytics. **Pass** |
| V Licensing | No external resource, package or font: nothing added to `docs/research/licenses.md`. **Pass** |
| VI Arabic and RTL | Every string is Arabic; all are in `lib/mushaf/ayah_bookmark_strings.dart` and the owner confirmed them word by word on 2026-11-25 (task T048, «كلها تمام»); «ملاحظة للآية» is the owner's own wording. **Pass** |
| VII Reliability | The migration is idempotent and transactional, tested on a real v1 file, with an interruption test; every write decided from the database in one transaction; the backup import stays one transaction. **Pass** |
| VIII App size | A few hundred lines, no asset. **Pass** |
| IX Quality gates | Tests first (the real v1 fixture is made from the unchanged code before the first `lib/` edit); pure logic separated (`ayahTintIds`, `AyahBookmarkRules`); `flutter analyze` clean; the migration, tint, note flow and look are checked on the phone with the owner's OK. **Pass** (convergence: the update over the release build, T044, and the note view, T051, were checked on the phone; the step-by-step walk T045 is still open, so the feature is implemented but not yet "done" by this principle) |

No deviation, so no Complexity Tracking entry. `reader_screen.dart`, `mushaf_page.dart` and `reader_controller.dart` are
edited by other features too: coordination, not a deviation (research D12).

## Project Structure

### Documentation (this feature)

```text
specs/013-ayah-bookmark/
├── plan.md              # this file
├── research.md          # decisions D1 to D15
├── data-model.md        # columns, constraints, scope, kinds, changes, settings, backup JSON
├── quickstart.md        # automated and phone validation
├── contracts/
│   ├── dart-interfaces.md   # signatures the tests are written against
│   └── ui.md                # sheet rows, note field, list row, tint, settings switch, strings
├── checklists/
│   ├── requirements.md      # spec quality (done)
│   └── ayah-bookmark.md     # requirements-quality checklist from /speckit-checklist
└── tasks.md             # from /speckit-tasks
```

### Source Code (repository root)

```text
lib/wirds/db.dart                          # EDIT: Bookmarks.surah / ayah, schemaVersion 2, onUpgrade (idempotent, transactional)
lib/wirds/db.g.dart                        # REGENERATED (build_runner)
lib/wirds/wird_repository.dart             # EDIT: toggleBookmark fixed (page bookmarks only); NEW methods for the ayah
lib/wirds/ayah_bookmark_change.dart        # NEW: AyahBookmarkChange (the value «تراجع» undoes)
lib/wirds/bookmarks_sheet.dart             # EDIT (small): ayah row, pops an AyahTarget for an ayah row; a page row's tag at most half the row (T042)
lib/ayah/ayah_bookmark_port.dart           # NEW: what the ayah sheet needs from the reader (state, toggle, save note)
lib/ayah/ui/ayah_sheet.dart                # EDIT (additive): optional `bookmarks`, two rows (+ «عرض الملاحظة» with a note), SheetRow semanticsValue and subtitleMaxLines
lib/ayah/ui/ayah_note_dialog.dart          # NEW: the note field (scrollable) and showAyahNoteView (FR-028)
lib/mushaf/ayah_bookmark_strings.dart      # NEW: every Arabic string of the feature (owner confirms)
lib/mushaf/ayah_tint.dart                  # NEW: ayahTintIds(PageData, Set<AyahRef>) pure
lib/mushaf/page_look.dart                  # EDIT (additive): `bookmarkTint` colour in both looks
lib/mushaf/mushaf_page.dart                # EDIT (small): `tintedWordIds`, `tintColor`; the highlight wins
lib/mushaf/mushaf_page_card.dart           # EDIT (additive): passes the two through
lib/mushaf/reader_controller.dart          # EDIT: page icon from page bookmarks only; ayahMarks; ayah actions
lib/mushaf/reader_screen.dart              # EDIT (small): port to the sheet, list result, tint wiring, message helper
lib/settings/ayah_tint_settings.dart       # NEW: the switch's notifier (key ayahTint)
lib/settings/settings_screen.dart          # EDIT (small): one SwitchListTile
lib/app.dart, lib/main.dart                # EDIT (small): provide AyahTintSettings; BackupService gets the Mushaf meta
lib/backup/backup_service.dart             # EDIT: version rule, surah/ayah export and validated import
test/migration/
├── make_v1_fixture_test.dart              # NEW (skipped unless asked): writes the real v1 file from the UNCHANGED code
├── fixtures/mushaf_v1.sqlite              # NEW (binary, a few KB): made by the real v1 layout
├── fixtures/mushaf_v1_expected.json       # NEW: every row of it, as text
├── migration_v1_to_v2_test.dart           # NEW (every row equal, layout equals a fresh v2, interrupted, idempotent)
└── fresh_install_test.dart                # NEW (a new database is v2 at once)
test/support/ayah_bookmark_harness.dart    # NEW (seeding, pumping, finders)
test/support/ayah_sheet_port_harness.dart  # NEW (the sheet alone with a fake, synchronous port)
test/support/tint_harness.dart             # NEW (the reader with the tint: tinted and highlighted words, first-frame checks)
test/ayah_bookmarks/
├── ayah_bookmark_repository_test.dart     # NEW (toggle, scopes, note save rules, undo exactness)
├── page_toggle_fix_test.dart              # NEW (006 regression: page icon never touches an ayah bookmark)
├── ayah_bookmark_backup_test.dart         # NEW (v1 read, v2 round trip, version rule, validation, old-build refusal)
├── ayah_tint_ids_test.dart                # NEW (pure: ids per page, 2:282 on page 48 only, a surah's first ayah)
├── ayah_tint_settings_test.dart           # NEW (default on, saved, reload after restore)
├── controller_ayah_test.dart              # NEW (marks per scope, icon from page bookmarks only, busy guard)
├── ayah_sheet_rows_test.dart              # NEW (the bookmark row: states, semantics, no gesture needed)
├── ayah_sheet_note_row_test.dart          # NEW (the note row, prefill, cancel keeps the sheet)
├── ayah_note_dialog_test.dart             # NEW (the four cases, cancel, prefill, length, failure keeps text)
├── ayah_sheet_show_note_test.dart         # NEW (FR-028: «عرض الملاحظة», «تعديل», «إغلاق»)
├── reader_ayah_bookmark_test.dart         # NEW (end to end: long press, tap, message, undo, scopes)
├── reader_ayah_note_test.dart             # NEW (end to end: the four saves, undo, list, backup)
├── reader_open_ayah_bookmark_test.dart    # NEW (open an ayah row: page, highlight, reveal)
├── reader_page_icon_test.dart             # NEW (006 icon fix at reader level, with the revert proof)
├── bookmarks_list_ayah_row_test.dart      # NEW (row, mark, note, swipe, open to AyahTarget)
├── mushaf_page_tint_test.dart             # NEW (MushafPage: tinted words, the highlight wins, no size change)
├── reader_tint_test.dart                  # NEW (painted words, scopes, layering, setting off, 2:282 on page 48 only)
├── settings_tint_switch_test.dart         # NEW (the Settings switch)
├── reader_tint_geometry_test.dart         # NEW (0 px difference with the tint on and off; baseline)
├── reader_tint_rebuild_test.dart          # NEW (rebuild budget with 200 bookmarks)
├── tint_contrast_test.dart                # NEW (4.5:1 text on tint, hue distance from the highlight, both looks)
├── ayah_bookmark_look_size_test.dart      # NEW (320 dp / 2x, both looks, three sizes, 48 px)
└── ayah_bookmark_strings_test.dart        # NEW (pins every string; confirmed by the owner, T048)
```

**Structure Decision**: the data rules sit in `WirdRepository` next to the other bookmark methods so the sheet, the icon,
the list and the backup share one source of truth; everything that can be pure (`ayahTintIds`, scope filtering) is a
function with its own test; new widgets and strings are new files, and the four big existing files (`reader_screen.dart`,
`mushaf_page.dart`, `ayah_sheet.dart`, `bookmarks_sheet.dart`) get the smallest additive edits (research D12).

## Complexity Tracking

No violations to justify.
