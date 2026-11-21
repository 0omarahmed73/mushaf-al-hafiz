# Implementation Plan: Bookmark Button in the Reader

**Branch**: `006-bookmark-button` (work stays on `main`) | **Date**: 2026-11-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/006-bookmark-button/spec.md`

## Summary

A bookmark icon sits at the far left end of the reader's top bar, under the «جزء · حزب · ربع» text. One tap adds a
bookmark on the page shown (no note, owned like the «علامات» sheet owns it); when the page already has a bookmark of
the current scope the icon is filled and a tap removes those bookmarks. A short message with «تراجع» follows each tap.
The icon state comes from one list of bookmark rows the reader controller reads with a one-shot query
(`bookmarkRows()`), refreshed after every change the reader knows about and filtered synchronously by (page, scope),
so it never flickers and never rebuilds the Mushaf page. The add, the removal and the undo are three small repository methods that decide from the database, not
from the screen. No table, no package, no resource and no page geometry changes.

## Technical Context

**Language/Version**: Dart 3.14 / Flutter 3.50 (Android first)

**Primary Dependencies**: `package:material_ui`, `drift`, `provider` (already used); nothing new

**Storage**: the existing `Bookmarks` table; no schema change, no migration; backups unchanged

**Testing**: `flutter test` with new files only (`test/bookmarks/`); repository tests on an in-memory drift database;
reader tests through `test/support/reader_harness.dart`; contrast walk from `test/support/contrast_walk.dart`;
real-device check on the owner's phone

**Target Platform**: Android phone, portrait and landscape, RTL

**Project Type**: mobile app

**Performance Goals**: the icon shows the right state within 100 ms of a page or bookmark change (SC-002); a tap
writes and shows the message in under 300 ms; the Mushaf page is not rebuilt by a bookmark change

**Constraints**: offline, no tracking; Quran text, layout and page geometry untouched (SC-007); earlier tests
unchanged; nothing overflows at 320 dp with a 2x system font; target ≥ 48 px; contrast ≥ 4.5:1

**Scale/Scope**: one small widget, three repository methods, one controller state, one top-bar edit, one message

## Constitution Check

*GATE: passed before research and again after the design (constitution 1.2.0).*

| Principle | Check |
|---|---|
| I Quran text integrity | No page, text, font or layout code is touched; the icon belongs to the top bar, outside the page. **Pass** |
| II Mushaf first | The top bar keeps its 84 px height and the page its rectangle; the icon sits in space the bar already had (D1); a measured before/after test pins it (SC-007). **Pass** |
| III No other duas | Not involved. **Pass** |
| IV Offline, private | Local database only; no network, no data leaves the device. **Pass** |
| V Licensing | No external resource: nothing added to `licenses.md`. **Pass** |
| VI Arabic, RTL | The icon is at the end edge of the RTL layout; every string is Arabic and is a proposal in `bookmark_strings.dart` until the owner confirms it (D8). **Pass** |
| VII Reliability | Add, removal and undo are transactions decided from the database; a failed write leaves the icon as it was (D3). **Pass** |
| VIII App size | A few hundred lines of code, no asset. **Pass** |
| IX Quality gates | Tests first (repository, controller, widget, geometry baseline); `flutter analyze` clean; the placement, the message and the undo are checked on the phone (D10). **Pass** |

No deviation, so no Complexity Tracking entry. `reader_screen.dart` is also edited by other features: coordination,
not a deviation (research D7).

## Project Structure

### Documentation (this feature)

```text
specs/006-bookmark-button/
├── plan.md              # this file
├── research.md          # decisions D1 to D11
├── data-model.md        # the bookmark scope, BookmarkToggle, the controller state
├── quickstart.md        # automated and phone validation
├── contracts/
│   ├── dart-interfaces.md   # signatures the tests are written against
│   └── ui.md                # place, states, strings, message, semantics
├── checklists/
│   └── requirements.md      # spec quality (done); the plan-quality checklist comes from /speckit-checklist
└── tasks.md             # from /speckit-tasks
```

### Source Code (repository root)

```text
lib/mushaf/bookmark_strings.dart        # NEW: every Arabic string of the feature (owner confirms these)
lib/mushaf/bookmark_button.dart         # NEW: the icon button (state, tooltip, semantics, 48 px target)
lib/wirds/wird_repository.dart          # EDIT (additive): toggleBookmark, undoBookmarkToggle, BookmarkToggle
lib/mushaf/reader_controller.dart       # EDIT (additive): pageBookmarked, toggleBookmark, refreshBookmarks (one-shot reads)
lib/mushaf/reader_screen.dart           # EDIT (small): the button in the top bar, the row reserve, the message
test/bookmarks/
├── bookmark_toggle_repository_test.dart  # NEW (add / remove / restore / scopes / two on a page / FK)
├── bookmark_controller_test.dart         # NEW (state per page and scope, busy tap, sheet changes, restore)
├── reader_bookmark_geometry_test.dart    # NEW (baseline rectangles, equal before and after)
├── reader_bookmark_button_test.dart      # NEW (place, tap, remove, undo, scopes, untouched data)
└── reader_bookmark_look_test.dart        # NEW (both looks, sizes, 320 dp / 2x, contrast, 48 px, semantics)
```

**Structure Decision**: the button and its strings are new files in `lib/mushaf/` beside the reader; the data rules
sit in `WirdRepository` next to the other bookmark methods so the sheet and the icon share one source of truth.
The reader gets the smallest edit that places the button, reserves its room and shows the message (research D7).

## Complexity Tracking

No violations to justify.
