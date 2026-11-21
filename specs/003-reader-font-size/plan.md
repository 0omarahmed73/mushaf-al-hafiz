# Implementation Plan: Text Size (Font Size)

**Branch**: `003-reader-font-size` (work stays on `main`) | **Date**: 2026-11-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-reader-font-size/spec.md`

## Summary

One setting, «حجم الخط», 80%–150% in eight steps of 10% (default 100%), stored in the existing settings table under
one key and therefore carried by the existing backup. It scales (1) the tafsir, translation and word-meaning
texts of the ayah menu, by a multiplier on their font sizes, and (2) the Mushaf page in the reader, by laying the
unchanged page card out in a box of today's size times the factor: smaller sizes centre the page, bigger sizes
make it scroll up and down and, when it is wider than the screen, move sideways too, with a swipe from the side
edge turning the page. The page card, the page data, the fonts, the offscreen renderer, the picture and the PDF
are not touched. Details and alternatives are in [research.md](research.md).

## Technical Context

**Language/Version**: Dart 3.14 / Flutter 3.50 stable (`package:material_ui/material_ui.dart`)

**Primary Dependencies**: provider (`ListenableProvider` for the new notifier), drift (settings table, no schema
change), existing `InteractiveViewer`, `PageView`, `Slider`; no new package

**Storage**: the existing `Settings` key/value table, new key `textSizePercent` (string, e.g. `"120"`); exported
and imported by `BackupService` like every setting; no migration

**Testing**: `flutter test` (pure unit tests for the size model and the page box/edge-turn maths; widget tests
with the reader harness in `test/mushaf/reader_screen_test.dart`; a data-level test over all 604 page JSON files;
a real-font render check on sample pages); real-device check on the owner's phone

**Target Platform**: Android (phone, portrait and landscape; tablets by the same rules)

**Project Type**: mobile-app (single Flutter project)

**Performance Goals**: page turn under 300 ms at every size (spec SC-006, 001 SC-007); the slider preview follows
the finger within one frame (SC-002)

**Constraints**: offline, no tracking, no new resource; default size pixel-identical to today; renderer, picture
and PDF independent of the setting; Arabic RTL UI with strings the owner confirmed on 2026-11-20

**Scale/Scope**: 604 pages x 8 sizes; two screens touched (Settings, reader) plus the three ayah views

## Constitution Check

*GATE: passed before research; re-checked after design (below).*

| Principle | Check | Result |
|---|---|---|
| I. Quran Text Integrity | Page data, fonts and line distribution are not touched. Each line is a row of its own words from the page JSON (no re-flow), the font is sized from the box width, so every line still fits at every size. Test: words per line from the data equal at all steps for all 604 pages, and real-font renders of sample pages show the same words per line and no overflow (SC-003). | Pass |
| II. The Mushaf Comes First | Nothing new before the page. Size is changed in Settings and applies to the reader on return. Page turning, position saving and the tap/long-press behaviours are kept at every size (FR-010). | Pass |
| III. Focus | A reading-comfort setting for existing text; no new content type. | Pass |
| IV. Offline, Private, Free | Local settings row only; no network, no analytics. | Pass |
| V. Licensing | No new external resource, font or data (FR-015); `licenses.md` and About unchanged. | Pass |
| VI. Arabic and RTL | New Arabic strings are listed in `contracts/ui.md` and were confirmed by the owner on 2026-11-20; page turning direction unchanged (next page from the left); the edge rule is mirrored for RTL reading (research D3). | Pass |
| VII. Reliability | The size and the reading position survive restart; a bad stored value falls back to the default. | Pass |
| VIII. App Size | Nothing is added to the bundle. | Pass |
| IX. Quality Gates | Test-first tasks, pure logic separated (`TextSize`, `PageBox`, `edgeTurn`), analyze clean, real-device check of the sideways pan and edge turn, and of the page-turn time at 150%. | Pass |

Post-design re-check: no violation; Complexity Tracking is empty.

## Project Structure

### Documentation (this feature)

```text
specs/003-reader-font-size/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── dart-interfaces.md
│   └── ui.md
├── checklists/requirements.md
└── tasks.md              # /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── settings/
│   ├── text_size.dart              # NEW pure: steps, parse (lenient), factor
│   ├── text_size_settings.dart     # NEW ChangeNotifier over WirdRepository
│   ├── text_size_tile.dart         # NEW Settings row: slider, preview, reset
│   └── settings_screen.dart        # + the tile
├── wirds/wird_repository.dart      # + textSizePercent get/set (key textSizePercent)
├── mushaf/
│   ├── page_scale.dart             # NEW pure: PageBox, PageFit, edgeTurn, initial offset
│   ├── page_viewport.dart          # NEW widget: fits / scrolls / pans both ways, per-page controller
│   └── reader_screen.dart          # _PageItem uses PageViewport; pager lock from the viewport
├── ayah/ui/
│   ├── reading_text.dart           # NEW ReadingStyles + ReadingScope (factor, system scale cap)
│   ├── sheet_detail.dart, tafsir_view.dart, translation_view.dart, meanings_view.dart  # use ReadingStyles
├── app.dart, main.dart             # provide TextSizeSettings
test/
├── settings/ (text_size_test, text_size_settings_test, text_size_tile_test, backup text size)
├── mushaf/   (page_scale_test, page_layout_invariance_test, page_viewport_test, reader size tests)
├── ayah/     (reading_text_test)
└── render/   (picture and print page independent of the setting)
```

**Structure Decision**: single Flutter project as in features 001 and 002; the page box and edge-turn rules are
pure Dart files so they can be tested without a widget tree; the new widgets sit beside their screens.

## Complexity Tracking

No Constitution Check violations. One design risk is recorded instead of a violation: the sideways pan with an
edge turn (research D3) replaces the shared zoom controller by one controller per page; if the phone check shows
it is not good enough, the fallback is option B of the spec's FR-008 discussion (bigger sizes only where there is
room), which needs the owner's decision.
