# Implementation Plan: Ayah Actions and Sharing

**Branch**: `002-ayah-actions-sharing` (work stays on `main`; the feature directory is
`specs/002-ayah-actions-sharing`) | **Date**: 2026-11-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-ayah-actions-sharing/spec.md`

## Summary

A long press on any word of the Mushaf opens a bottom sheet for that ayah: share the ayah (exact Quran
text + reference), read Tafsir al-Sa'di, read the Saheeh International translation, see the difficult
words with their meanings, and share the page as a picture or the surah as a PDF. Everything is offline;
only what the user hands to the share sheet leaves the app.

Approach (decisions and evidence in [research.md](research.md)):

- Four read-only datasets built from approved sources by a new validated tool into per-surah JSON
  assets (Unicode ayah words aligned to the Mushaf's word keys; tafsir with ayah-range groups;
  translation; gharib meanings from two classical books).
- One shared offscreen renderer of the real Mushaf page widget gives the page picture (PNG, app look)
  and the PDF pages (the same app look, in colour, as 256-colour indexed Flate images on an emerald sheet;
  amended 2026-11-20, was print look in gray) written by a small PDF writer of our own: **no new package**.
- The long press reuses the per-word `onLongPress` already in `MushafPage`; tap, swipe and zoom are
  untouched. No new permanent button in the reader.

## Technical Context

**Language/Version**: Dart / Flutter 3.50 (stable), Android first (package `app.hafiz.mushaf`);
Python 3 (uv) for the asset tool.

**Primary Dependencies**: existing only: `provider`, `share_plus` 13, `path_provider`, `material_ui`.
**No new package** (PDF is written by our own ~150-line writer; PNG is encoded by the engine).

**Storage**: bundled read-only assets `assets/ayah/{text,tafsir,translation,gharib}/NNN.json` (git-ignored,
rebuilt by `tool/build_ayah_assets.py`) plus `assets/ayah/sources.json`; temporary share files in
`<temp>/share/`. No database change (no user data is added).

**Testing**: `flutter test` (pure logic first, then widget tests with `test/support/harness.dart`, fakes
for share/renderer), `pytest tool/` for the build tool, real-device checks (quickstart.md).

**Target Platform**: Android phone, portrait, offline (airplane mode) (the owner's Samsung SM-S721B).

**Project Type**: mobile app (Flutter), single project.

**Performance Goals**: menu opens < 0.5 s after the hold registers (SC-001); picture < 3 s (SC-004);
48-page PDF < 60 s and < 40 MB, cancel < 2 s (SC-005). Measured on the dev machine: ≈ 0.16 s and ≈ 0.3 MB
per dense page; on the phone to be checked.

**Constraints**: Quran text never altered (I); offline, nothing sent (IV); licences recorded before use and
credited in About (V); added data ≤ 40 MB (SC-009, measured 8.95 MB raw, 2.64 MB gzip); the reader never freezes
(PDF steps are async, heavy work in an isolate).

**Scale/Scope**: 6,236 ayahs × 4 datasets; 604 pages; PDFs up to 48 pages (Al-Baqarah).

## Constitution Check

*GATE: passed before research and re-checked after design (Constitution 1.1.0).*

| Principle | Result | How |
|---|---|---|
| I. Quran text integrity | **Pass with automated gates** | Shared text = source words unchanged, word-aligned with the Mushaf keys, build-time and `flutter test` checks over all 6,236 ayahs; tafsir, translation and meanings shown set apart and labelled; the picture and PDF reuse the Mushaf layout. |
| II. Mushaf comes first | Pass | No new permanent buttons; every action opens from the page and returns to the same page, zoom and position. |
| III. Focus | Pass | Tafsir, translation, meanings and sharing are Quran features, not adhan, qibla, duas or hadith. |
| IV. Offline, private, free | Pass | No network in the app; sharing is initiated by the user; data is downloaded only on the developer machine, at build time. |
| V. Licensing and attribution | **Pass once the owner approves the four downloads** | Licences read and recorded in `docs/research/licenses.md`; About credits planned in this feature; the weak points (QUL «no copyright information», translator's rights, classical books only) are listed as R1–R4 for the owner. |
| VI. Arabic and RTL | Pass | Arabic RTL sheet and strings (proposed strings in contracts/ui.md for the owner to confirm); the English translation is its own LTR panel (spec FR-010). |
| VII. Reliability | Pass | Reading position untouched; a PDF job cannot leave a half file; failures are explained. |
| VIII. App size | Pass | 8.95 MB raw / 2.64 MB gzip (measured), limit 40 MB; text is bundled; no download. |
| IX. Quality gates | Pass (planned) | Test-first; pure logic in `lib/ayah/` without widgets; analyzer clean; real-device checklist in quickstart.md; one commit per task. |
| Scope (1.1.0) | Pass | Exactly one translation, Saheeh International, bundled, shown only from the ayah menu, credited in About. |

**Complexity Tracking**: no principle is violated. Two deliberate simplicity choices, recorded so they are
not mistaken for omissions: (1) our own PDF writer instead of a dependency (research D7; a vector PDF stays
open as a gated upgrade), (2) a second representation of the Quran text (Unicode words) because the page
glyphs cannot be shared, guarded by the alignment checks of D1.

## Project Structure

### Documentation (this feature)

```text
specs/002-ayah-actions-sharing/
├── plan.md              # this file
├── research.md          # Phase 0: decisions D1–D10, licences, sizes, downloads to approve
├── data-model.md        # Phase 1: entities, validation, states
├── quickstart.md        # Phase 1: how to build the data and verify the feature
├── contracts/
│   ├── assets.md          # JSON assets and the build tool's checks
│   ├── share-formats.md   # shared text, file names, PNG and PDF structure
│   ├── dart-interfaces.md # services and controllers the UI and tests depend on
│   └── ui.md              # gestures, sheet layout, progress strip, Arabic strings
├── checklists/requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
lib/
├── ayah/                         # new; pure Dart unless named *_view / *_sheet
│   ├── ayah_ref.dart             # AyahRef, ayah of a word, highlighted ids on a page
│   ├── models.dart               # TafsirEntry, TafsirResult, GharibEntry, Source
│   ├── surah_pages.dart          # SurahPages (first and last page of a surah)
│   ├── page_picture_action.dart  # render → temp file → share of the page picture
│   ├── ayah_repository.dart      # text / tafsir / translation / gharib lookups (cached, isolate decode)
│   ├── share_text.dart           # ﴿ … ﴾ + [سورة …: n]; tafsir / translation share text
│   ├── file_names.dart           # «سورة البقرة.pdf», «مصحف - صفحة 293.png»
│   ├── share_service.dart        # ShareService interface + PlatformShareService + TempShareFiles
│   ├── failures.dart             # ShareFailure kinds → Arabic messages
│   ├── ui/ayah_sheet.dart        # AyahSheet (menu rows and the menu-to-detail navigation)
│   ├── ui/tafsir_view.dart · translation_view.dart · meanings_view.dart
│   └── ui/pdf_progress_strip.dart
├── render/                       # new
│   ├── page_renderer.dart        # PageRenderer interface, offscreen implementation, canonical 400×600 page size
│   └── indexed_flate.dart        # RGBA → 256-colour palette + indices → Flate (runs in an isolate); was gray_flate.dart
├── pdf/                          # new
│   ├── a4_layout.dart            # page placement maths
│   ├── pdf_writer.dart           # streaming writer (header, objects, xref)
│   └── pdf_job.dart             # PdfJob controller: states, progress, cancel
└── mushaf/
    ├── page_look.dart            # new: PageLook.screen colours (the print look was dropped on 2026-11-20)
    ├── mushaf_page_card.dart     # new: ring + paper + frame + MushafPage, extracted from _PageItem
    ├── mushaf_page.dart          # small change: PageLook colours, number font
    └── reader_screen.dart        # small change: long press wiring, highlight, sheet, strip
tool/
├── build_ayah_assets.py          # new: inputs in data-raw/ayah/, validates, writes assets/ayah/
├── ayah_text_known_differences.json   # new: reviewed exceptions of the Tanzil cross-check (expected: 2:72 only)
├── tafsir_without_own_entry.json      # new: the 59 ayahs the Sa'di text does not comment on (pinned)
└── test_build_ayah_assets.py     # new
assets/ayah/                      # generated, git-ignored
test/
├── ayah/ …                       # unit tests for every pure file above, all-6,236-ayahs integrity test
├── render/ , pdf/                # renderer, writer and job tests
└── mushaf/reader_screen_test.dart  # long press / tap / swipe cases added
docs/research/licenses.md         # rows for the four sources; About credits in lib/settings/about_screen.dart
```

**Structure Decision**: one Flutter project, new folders `lib/ayah`, `lib/render`, `lib/pdf` kept apart from
`lib/mushaf` so Mushaf code only gains the extracted page card and the long-press wiring. Services are
provided in `lib/app.dart` like `Backup` and faked in tests.

## Phase 1 outputs

[data-model.md](data-model.md) · [contracts/](contracts/) · [quickstart.md](quickstart.md)

## Decisions for the owner (before implementation)

1. Approve the four downloads (research.md, last table) and the licence readings (R1–R4).
2. Tafsir source: QUL resource 24 (recommended) or Quranpedia book 3.
3. Gharib: only the two classical books (recommended) or all four.
4. PDF: raster in our own writer (recommended, ≈ 15 MB for Al-Baqarah) or ask for vector (needs the `pdf` package).
5. Confirm the Arabic strings proposed in contracts/ui.md.
