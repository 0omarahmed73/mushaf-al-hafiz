# Implementation Plan: Mushaf Reader, Wirds and Reminders

**Branch**: `001-mushaf-reader-wirds` | **Date**: 2026-11-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-mushaf-reader-wirds/spec.md`

**Order of authority**: spec.md (including its Clarifications) → this plan and its artifacts
(research.md, data-model.md, contracts/) → tasks.md. The earlier
`docs/superpowers/plans/2026-11-20-plan-1-mushaf-and-wirds.md` is background only: it predates the
2026-11-20 clarifications (qiyam wird day, mid-day goal edits, shared bookmark list, daily background
reminder refresh, hizb format), and wherever it differs, the documents above win.

## Summary

Build the first slice of «مصحف الحافظ»: an Android app that opens straight on the real Madinah Mushaf
1421H at the active wird's position, with multiple wirds (reading, qiyam), per-day portions, bookmarks,
local reminders (wird + Thursday-evening al-Kahf), JSON file backup and an About screen.

Technical approach: a Python build script turns the QUL QCF-V2 downloads plus Tanzil metadata into
read-only per-page JSON, a `meta.json` and 604 per-page TTF fonts, validated before anything is
written. A Flutter app renders each page word by word from those assets (so later features can hide or
highlight words), keeps user state in a drift (SQLite) database, and isolates the pure rules (portion
maths, position rules, reminder planning) in unit-tested Dart files.

## Technical Context

**Language/Version**: Dart with Flutter 3.50 (stable); Python 3 for the asset build script

**Primary Dependencies**: `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `provider`,
`flutter_local_notifications`, `timezone`, `flutter_timezone`, `workmanager` (daily background
reminder refresh), `share_plus`, `file_picker`, `path_provider`; dev: `drift_dev`, `build_runner`. Script: `fonttools[woff]` via `uv`

**Storage**: read-only bundled assets for Quran data (per-page JSON, `meta.json`, per-page TTF fonts);
on-device SQLite (drift) for user data; JSON file for backup

**Testing**: `pytest` (asset pipeline), `flutter_test` unit + widget tests, real-device checklist

**Target Platform**: Android, minSdk 24, package `app.hafiz.mushaf`, app name «مصحف الحافظ»

**Project Type**: mobile app (single Flutter project) + build-time asset tool

**Performance Goals**: next page text visible < 300 ms on a mid-range phone (SC-007); 604 pages
render with no overflow on 360×640 and 412×915 (SC-002)

**Constraints**: fully offline, no network calls; no analytics/ads; Arabic RTL UI; next page enters
from the left; Quran text never modified; data validated before shipping; inexact alarms (no
exact-alarm permission)

**Scale/Scope**: 1 user per phone; 604 pages, 83,668 words, 114 surahs, 6,236 ayahs; ~10 screens and
sheets (reader, index, wirds, wird form, today panel, bookmarks, settings, about)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | How this plan complies | Status |
|---|---|---|
| I. Quran text integrity | Text, glyphs and line layout come unmodified from QUL QCF V2 1421H; `validate()` checks 604 pages, 8/15 lines, words 1…83,668 exactly once in order, and aborts the build on failure. | PASS |
| II. Mushaf first | `ReaderScreen` is the home route; today panel and bars sit on top of the page; position persisted per wird plus `lastViewedPage`. | PASS |
| III. Focus | No non-Quran features. | PASS |
| IV. Offline, private, free | No network packages used; backup is file export/import only; no accounts/server. | PASS |
| V. Licensing and attribution | `docs/research/licenses.md` written in the first task, recording QCF V2/QUL as "no licence published" per the owner's decision (spec FR-042); generated assets git-ignored; About credits all four sources. | PASS |
| VI. Arabic and RTL | App-wide RTL; `PageView(reverse: true)` in an LTR wrapper so the next page enters from the left; strings copied from the spec. | PASS |
| VII. Reliability | Positions in SQLite survive restarts; portions keyed by wird day; reminders are local, rescheduled on start/resume/changes and by a daily on-phone background task, `RECEIVE_BOOT_COMPLETED`. Audio not in this feature. | PASS |
| VIII. App size | Quran data bundled; no audio in this feature. | PASS |
| IX. Quality gates | TDD per task; pure logic in `portion.dart`, `reader_controller.dart`, `reminder_planner.dart`; `flutter analyze` clean; device checklist in Task 11; one commit per task. | PASS |

No violations, so Complexity Tracking is empty.

**Post-design re-check (after Phase 1)**: still PASS on all nine principles. Phase 1 added only
user-data fields (`todayPanelExpanded` setting, an 8-colour palette), the backup and notification
formats, and confirmed by measurement that bundled fonts add roughly 100 MB to the APK (research.md R2).
That is within Principle VIII (Quran data bundled) for a private APK; Task 11 records the real size.

## Project Structure

### Documentation (this feature)

```text
specs/001-mushaf-reader-wirds/
├── plan.md              # This file
├── research.md          # Phase 0: decisions and open-question defaults
├── data-model.md        # Phase 1: Quran assets + user data entities
├── quickstart.md        # Phase 1: how to build, run and validate
├── contracts/
│   ├── assets.md        # page JSON, meta.json, font files
│   ├── backup-file.md   # backup JSON format
│   ├── notifications.md # reminder titles, bodies, ids, payloads
│   └── dart-interfaces.md # module interfaces other features build on
├── checklists/requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks; not created here)
```

### Source Code (repository root)

```text
tool/
├── build_quran_assets.py
└── test_build_quran_assets.py
data-raw/                       # git-ignored QUL + Tanzil downloads (already present)
assets/
├── mushaf/meta.json            # generated, git-ignored
├── mushaf/pages/p001.json …    # generated, git-ignored
├── fonts/qpc-v2/p1.ttf …       # generated, git-ignored
└── fonts/amiri/AmiriQuran.ttf + OFL.txt   # committed (OFL)
lib/
├── main.dart, app.dart
├── mushaf/   models, mushaf_repository, page_font_loader, mushaf_page,
│             reader_controller, reader_screen, index_screen
├── wirds/    db (+ db.g.dart), portion, wird_repository, wirds_screen,
│             wird_form_screen, today_panel, bookmarks_sheet
├── reminders/ reminder_planner, reminder_service
├── settings/ settings_screen, about_screen
└── backup/   backup_service
test/         mirrors lib/ (mushaf/, wirds/, reminders/, backup/)
android/      generated by flutter create; manifest permissions + receivers
docs/research/licenses.md
```

**Structure Decision**: one Flutter project at the repository root (Android only for now) plus a
Python build tool in `tool/`. Code is split by feature area (`mushaf`, `wirds`, `reminders`,
`settings`, `backup`), not by technical layer, so later features (audio, hifz, tests) add their own
folders and consume `mushaf/` and `wirds/` through the interfaces in `contracts/dart-interfaces.md`.

## Implementation Phases

Execution order and phases are defined in [tasks.md](./tasks.md): Setup → Foundational → US1 (MVP) →
US2 → US3 → US4 → US5 → Polish, each story test-first and checked on a real phone before the next.

## Open Points Carried Forward

- The 2026-11-20 clarify session settled the qiyam day (04:00), mid-day goal edits, bookmark list,
  indefinite reminders (daily background refresh, adds `workmanager`) and the hizb format; the plan
  artifacts were updated to match. Remaining designer defaults are listed in research.md R7.

## Complexity Tracking

No constitution violations.
