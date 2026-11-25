# Implementation Plan: Large Ayah Mode

**Branch**: `015-large-ayah-mode` (work stays on `main`, as for features 001 to 013) | **Date**: 2026-11-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/015-large-ayah-mode/spec.md` (clarified on 2026-11-25; constitution 2.2.0)

## Summary

A separate view of the Mushaf for weak eyes: each screen shows 1, 2 or 3 ayat (the reader's choice, 1 by default) at two
to three times the Mushaf's letter size, in the Madinah print's own QCF V2 glyphs re-wrapped on new lines; an ayah too long
for one screen is cut between words into parts on consecutive screens. The screens of a page are made by one pure, tested
function from measured word widths (research D3, D4); a screen never mixes two pages, so the position, the wirds and the
bookmarks stay page-based and are moved by the same `ReaderController.onPageShown` the Mushaf pager calls (D6).

The view replaces the Mushaf pager inside the reader screen, under the same bars, today panel, ayah sheet, highlight and
tint (D7). An anchored pager walks screen by screen, because the number of screens of the whole Mushaf is not known without
measuring all 604 pages (D5). Four keys in the settings table hold the switch, the count, the size step and the last ayah
shown; the backup already carries every key (D8). Nothing is added to `pubspec.yaml`, no asset, no permission, and
`lib/mushaf/mushaf_page.dart` is not edited.

## Technical Context

**Language/Version**: Dart 3.14 / Flutter 3.50 (Android first)

**Primary Dependencies**: `package:material_ui`, `provider`, `drift` (existing); nothing new

**Storage**: four new keys in the key/value `Settings` table (`largeAyah`, `largeAyahCount`, `largeAyahSize`,
`largeAyahAt`); no schema change, no backup format change

**Testing**: `flutter test`; new files under `test/large_ayah/`; pure tests for the layout, the navigator and the settings;
a whole-Mushaf test over the 604 page files (SC-001); widget tests through `test/support/reader_harness.dart` with the real
QCF fonts loaded as `test/render/` does; contrast walk from `test/support/contrast_walk.dart`; real-device check on the
owner's phone (quickstart.md)

**Target Platform**: Android phone, portrait and landscape, RTL

**Project Type**: mobile app

**Performance Goals**: laying out a page's screens (measure about 140 glyphs, then the pure layout) under 30 ms on the
phone, done ahead for the neighbour pages so a swipe never waits for it; a swipe between screens holds the frame numbers
of feature 010 SC-001; turning the mode on shows the first screen in under 300 ms once the page font is loaded

**Constraints**: offline, no tracking; the Quran data and the Mushaf page untouched (constitution 2.2.0 Principle I); every
word exactly once and in order (automatic check); a screen never holds two pages; no word cut or off screen at 320 dp; no
scrolling; targets at least 48 px; contrast at least 4.5:1; the phone's text scale does not enlarge the mode; earlier tests
unchanged

**Scale/Scope**: 1 pure layout function, 1 navigator, 1 measurer, 1 settings notifier with 4 keys, 2 widgets (pager,
screen), 1 settings tile with 2 choices, 1 top-bar button, reader wiring; about 9 Arabic strings (contracts/ui.md)

## Constitution Check

*GATE: passed before research and again after the design (constitution 2.2.0).*

| Principle | Check | Result |
|-----------|-------|--------|
| I. Quran Text Integrity | Glyphs only from the page's QCF V2 font (D1); every word once and in order, checked over the whole Mushaf (D10, SC-001); no stored data changed; the Mushaf page not edited; a screen never holds two pages and shows its page number (FR-005, FR-008); never presented as the Mushaf page (own header, «المصحف» button) | Pass (2.2.0 "Large-ayah view") |
| II. The Mushaf Comes First | Turned on and off from the Mushaf (Settings via «القائمة»; «المصحف» back); opens on the mode only when left on, first install on the Mushaf (D8); the ayah sheet, bookmarks and wirds work from it (D6, D7) | Pass (2.2.0 exception) |
| III. Focus | A reading view of the Quran only; nothing outside the Quran | Pass |
| IV. Offline, Private, Free | No network, no permission, no data leaves the phone; backup by the existing file | Pass |
| V. Licensing | No new resource (the QCF fonts, Reem Kufi and Amiri Quran are already recorded and credited) | Pass |
| VI. Arabic and RTL | RTL lines; the next screen comes in from the left (D5); strings in contracts/ui.md are proposals until the owner confirms them | Pass, strings open |
| VII. Reliability | The position survives restarts through the controller, plus `largeAyahAt` for the screen inside a page (D6) | Pass |
| VIII. App Size | No asset added; a screen waits for its page font like the Mushaf page (D4) | Pass |
| IX. Quality Gates | Test-first; the layout and navigator are pure and unit-tested; analyze clean; real-phone walk in quickstart.md; one commit per task | Pass |

No deviation; Complexity Tracking is empty.

## Project Structure

### Documentation (this feature)

```text
specs/015-large-ayah-mode/
├── spec.md
├── plan.md              # this file
├── research.md          # phase 0
├── data-model.md        # phase 1
├── quickstart.md        # phase 1
├── contracts/
│   ├── dart-interfaces.md
│   └── ui.md
├── checklists/requirements.md
└── tasks.md             # /speckit-tasks (not made here)
```

### Source Code (repository root)

```text
lib/large_ayah/
├── screen_layout.dart        # pure: wrap, group, split (D3)
├── screen_navigator.dart     # next/previous/screenOfAyah over pages (D5)
├── word_measurer.dart        # glyph widths per page and size, cached (D4)
├── large_ayah_settings.dart  # the four keys (D8)
├── large_ayah_strings.dart   # the proposed Arabic strings
├── large_ayah_screen.dart    # one screen in a PageLook
└── large_ayah_pager.dart     # the anchored pager
lib/wirds/wird_repository.dart     # readers and writers of the four keys
lib/mushaf/reader_screen.dart      # shows the pager instead of the Mushaf pager while on; «المصحف» button
lib/settings/settings_screen.dart  # the tile at the top
lib/main.dart                      # makes and provides LargeAyahSettings, as TextSizeSettings; reloads it after a restore

test/large_ayah/
├── screen_layout_test.dart
├── screen_navigator_test.dart
├── whole_mushaf_test.dart        # SC-001
├── large_ayah_settings_test.dart
├── large_ayah_screen_test.dart   # glyphs, size (SC-002), 2:282 at 320 dp (SC-005), looks
├── reader_mode_test.dart         # on/off, swipe, regroup, sheet, tint, position, jump, khatm, restart
└── backup_keys_test.dart
```

**Structure Decision**: the existing single Flutter app; the feature's own code in `lib/large_ayah/`, with small wiring in
the reader, the settings screen, the repository and `lib/main.dart`.

## Phases after this plan

`/speckit-checklist` (optional), `/speckit-tasks`, `/speckit-analyze`, then implement test-first, one commit per task, and
converge. The owner confirms the strings of contracts/ui.md before the feature is called done, and the real-phone walk of
quickstart.md needs his «سطّب».

## Complexity Tracking

None.
