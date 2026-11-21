# Implementation Plan: Khatm Dua After the Last Page

**Branch**: `005-khatm-dua` (work stays on `main`) | **Date**: 2026-11-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/005-khatm-dua/spec.md`

## Summary

A forward swipe on page 604 opens a full-screen «دعاء ختم القرآن»; «آمين» shows page 1 (the ordinary page change, so
the saved position becomes 1), back leaves the reader on page 604. The gesture is read from the pager's own scroll
notifications (a clamped overscroll at the last page, decided by a small pure rule) and, for a page wider than the
screen, from the edge-turn that already exists. The dua is one bundled text file shown in the interface font at
the owner's reading size in the card colours of the chosen look. All new code is in `lib/khatm/`; the reader
gets one listener, one handler and one branch, About gets one credit, and `docs/research/licenses.md` one section.
The wording is a proposal the owner confirms before the feature is done (research D8).

## Technical Context

**Language/Version**: Dart 3.14 / Flutter 3.50 (Android first)

**Primary Dependencies**: `package:material_ui`, `provider` (already used); nothing new

**Storage**: none new (no table, no setting, nothing in the backup); one bundled asset `assets/khatm/dua.txt`

**Testing**: `flutter test` with new files only (`test/khatm/`); reader tests through `test/support/reader_harness.dart`;
contrast walk from `test/support/contrast_walk.dart`; real-device check on the owner's phone

**Target Platform**: Android phone, portrait and landscape, RTL

**Project Type**: mobile app

**Performance Goals**: the dua opens in under 1 second; showing page 1 after «آمين» in under 1 second (SC-003)

**Constraints**: offline, no tracking; Quran text, layout and page geometry untouched; earlier tests unchanged;
nothing overflows at 320 dp with a 2x system font; targets ≥ 48 px; contrast 4.5:1 / 3:1

**Scale/Scope**: one screen, one rule class, one text asset, three one-line edits in existing files

## Constitution Check

*GATE: passed before research and again after the design (constitution 1.2.0).*

| Principle | Check |
|---|---|
| I Quran text integrity | The dua is never in the Quran font or the page, repeats no Quran word, is labelled «دعاء وليس من نص القرآن»; no page, text, layout or font code is touched; the layout tests stay green (FR-010, FR-018). **Pass** |
| II Mushaf first | The dua is a route reached only from the reader's swipe and returns to it; the position is never lost: «آمين» saves page 1 through the ordinary rule, back changes nothing (FR-006, FR-007). **Pass** |
| III No other duas | The 1.2.0 exception covers exactly this one supplication under its rules: separate screen from the Mushaf (D3), offline (D4), named source in licenses and About (D6), owner confirmation (D8), set apart and labelled (D3). One text file, no list, no key per dua (FR-015). **Pass** |
| IV Offline, private | Bundled text, no network, no data stored or sent (FR-017). **Pass** |
| V Licensing | The wording's origin and the absence of a fixed source are recorded in `licenses.md` and credited honestly in About in the same feature (D6). No other resource. **Pass** |
| VI Arabic, RTL | The screen is Arabic and RTL; the forward swipe is the paper direction (finger left to right, the pager's own); all strings are proposals in `dua_strings.dart` until the owner confirms them (D8). **Pass** |
| VII Reliability | The position survives restarts: it is only changed through the ordinary page-change path that already persists (D5). **Pass** |
| VIII App size | One text file of a few hundred bytes. **Pass** |
| IX Quality gates | Tests first (`LastPageSwipe` is pure and unit-tested before the UI); `flutter analyze` clean; the swipe feel, rotation and large font are checked on the phone (D10). **Pass** |

No deviation, so no Complexity Tracking entry. The feature touches two files that feature 004 is also editing
(`reader_screen.dart`, `about_screen.dart`): this is coordination, not a deviation (research D7).

## Project Structure

### Documentation (this feature)

```text
specs/005-khatm-dua/
├── plan.md              # this file
├── research.md          # decisions D1 to D11 (the spike that fixed the detection is in D1)
├── data-model.md        # the text asset, DuaText, LastPageSwipe, the reader flag
├── quickstart.md        # automated and phone validation
├── contracts/
│   ├── dart-interfaces.md   # signatures the tests are written against
│   └── ui.md                # the gesture table, the screen, the credit
├── checklists/
│   └── requirements.md      # spec quality (done); look.md-style plan checklist comes from /speckit-checklist
└── tasks.md             # from /speckit-tasks
```

### Source Code (repository root)

```text
assets/khatm/dua.txt                    # NEW: the one bundled text (owner-confirmed wording)
lib/khatm/
├── last_page_swipe.dart                # NEW: the pure rule (no Flutter import)
├── dua_text.dart                       # NEW: DuaText.parse / load, DuaUnavailable
├── dua_strings.dart                    # NEW: every Arabic string of the feature (owner confirms these)
└── khatm_dua_screen.dart               # NEW: the full-screen route
lib/mushaf/reader_screen.dart           # EDIT (additive): listener, handler, _duaOpen, one edge-turn branch
lib/settings/about_screen.dart          # EDIT (one tuple in `credits`)
pubspec.yaml                            # EDIT (one asset line)
docs/research/licenses.md               # EDIT (one section)
test/khatm/
├── last_page_swipe_test.dart           # NEW
├── dua_text_test.dart                  # NEW
├── khatm_dua_screen_test.dart          # NEW (both looks, sizes, 320 dp / 2x, contrast, font, label, fallback)
├── reader_khatm_test.dart              # NEW (swipe at 604, 603, jump, wide page, zoomed, once, «آمين»)
├── reader_khatm_back_test.dart         # NEW (back, second swipe, rotation, background)
├── khatm_dua_look_test.dart            # NEW (reading sizes, looks, contrast, 320 dp / 2x, semantics)
└── khatm_about_test.dart               # NEW
```

**Structure Decision**: one new folder `lib/khatm/` holds everything new; the reader and About get the smallest
additive edits, each in its own commit after checking `git status`/`git log` and telling the feature 004 session
(research D7). `ReadingStyles` (feature 003) and `AppLook` (feature 004) are used as they are, not edited.

## Complexity Tracking

No violations to justify.
