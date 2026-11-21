# Implementation Plan: Night Reader Look (Second Theme)

**Branch**: `004-night-reader-theme` (work stays on `main`) | **Date**: 2026-11-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/004-night-reader-theme/spec.md`

## Summary

A second look, «القارئ الليلي» (direction B of the design canvas), chosen in Settings next to today's «زمردي وذهبي»
(default, unchanged). The choice is one value in the existing settings table (key `appLook`), carried by the
existing backup. The look is a Flutter `ThemeExtension` (`AppLook`: colours and shape tokens) carried by the
`ThemeData` that `MushafApp` builds from the saved choice before the first frame; every screen reads it through
`context.look` instead of the static `AppColors`, one file per task, with `AppLook.emerald` holding exactly today's
values so Emerald stays identical. The Mushaf page takes a per-look `PageLook` (no paper and no frame in Night, the
same box and the same lines), the page picture and the surah PDF are drawn with the look in force when the share
or the job starts. The page data, fonts, geometry, About credits and licences are not touched. Details and
alternatives are in [research.md](research.md).

## Technical Context

**Language/Version**: Dart 3.14 / Flutter 3.50 stable (`package:material_ui/material_ui.dart`)

**Primary Dependencies**: provider (`ListenableProvider` for the new notifier), drift (settings table, no schema
change), existing `ThemeData`/`ThemeExtension`; no new package

**Storage**: the existing `Settings` key/value table, new key `appLook` (string `emerald` or `night`); exported and
imported by `BackupService` like every setting; no migration

**Testing**: `flutter test` (pure tests for the look parse, the contrast function and every Night colour pair, the
wird-marker lift of all 8 palette colours; widget tests for the Settings row and for each migrated screen in both
looks; a data-level test over all 604 pages that lines, words and line boxes are equal in both looks; renderer and
PDF tests in Night); real-device check on the owner's phone

**Target Platform**: Android (phone, portrait and landscape; tablets by the same rules)

**Project Type**: mobile-app (single Flutter project)

**Performance Goals**: page turn text visible under 300 ms in both looks (spec SC-008, 001 SC-007); switching the look
under 1 second (SC-001); picture under 3 s and 48-page PDF under 60 s as in 002 (SC-007)

**Constraints**: offline, no tracking, no new resource, no new font; Emerald pixel-identical and every earlier
test passing unchanged; Quran text and geometry untouched (Constitution I, II); Arabic RTL UI with proposed strings
the owner confirms

**Scale/Scope**: 2 looks x about 11 screens and sheets, 13 source files migrated from `AppColors` (about 170 colour
uses), 8 wird palette colours, 604 pages

## Constitution Check

*GATE: passed before research; re-checked after design (below).*

| Principle | Check | Result |
|---|---|---|
| I. Quran Text Integrity | Page data, page fonts and the line distribution are not touched; a look only changes colours, borders and the frame around the page. The Night page keeps the box of the Emerald card (same paddings and the same border width, the frame colour is transparent), so no line can move. Test: for all 604 pages the line count, words per line, word order and the measured line boxes are equal in both looks (SC-004). The ayah-end markers are found from the data (research D3) and only their text colour changes. | Pass |
| II. The Mushaf Comes First | Nothing new before the page; the look is chosen in Settings and applies on return; the reader behaves the same in both looks (FR-009). The bottom bar floats inside the same slot, so the page box is not changed. | Pass |
| III. Focus | A display preference; no new content type. | Pass |
| IV. Offline, Private, Free | Local settings row only; no network, no analytics. | Pass |
| V. Licensing | No new external resource, font, image or data (FR-017); the design's IBM Plex Sans Arabic and Amiri are NOT added; `licenses.md` and About credits unchanged. | Pass |
| VI. Arabic and RTL | Four new Arabic strings listed in `contracts/ui.md` for the owner to confirm; page turning unchanged. | Pass (owner to confirm strings) |
| VII. Reliability | The look survives restart; a bad stored value falls back to Emerald; a running PDF job keeps the look it started with. | Pass |
| VIII. App Size | Nothing is added to the bundle. | Pass |
| IX. Quality Gates | Test-first tasks, pure logic separated (`AppLook`, `LookChoice`, `contrastRatio`, `markerColor`), analyze clean, real-device check of every screen in both looks, cold start without a flash, the picture and the PDF in Night, and a page turn. | Pass |

Post-design re-check: no violation. One interface change is recorded in Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/004-night-reader-theme/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── dart-interfaces.md
│   └── ui.md
├── checklists/requirements.md
└── tasks.md              # /speckit-tasks
docs/design/night-reader.md   # the look's values, next to emerald-gold.md (a task)
```

### Source Code (repository root)

```text
lib/
├── theme.dart                       # AppColors stay (= Emerald tokens); AppLook ThemeExtension (tokens, shapes,
│                                    #   AppLook.emerald / AppLook.night, rowRadius, darkCards), context.look,
│                                    #   buildAppTheme({AppLook look = AppLook.emerald}) (there is no app_look.dart)
├── look/                            # NEW (pure and small)
│   ├── look_choice.dart             #   LookChoice enum, lenient parse, LookChoice.pageLook
│   ├── look_settings.dart           #   AppLookSettings ChangeNotifier over WirdRepository
│   ├── contrast.dart                #   contrastRatio, lift-to-contrast for the wird markers
│   └── wird_marker.dart             #   markerColor(look, paletteColor) + the dot/diamond marker widget
├── settings/
│   ├── look_tile.dart               # NEW «المظهر» row: two options with colour samples
│   └── settings_screen.dart         # + the tile, + reload after a backup import, colours -> context.look
├── mushaf/
│   ├── page_look.dart               # + night, per-look fields (banner style, marker, number, highlight)
│   ├── mushaf_page_card.dart        # unchanged geometry; reads the look it is given
│   ├── mushaf_page.dart             # banner "rules" style, end-marker colour, page number colour (colours only)
│   ├── mushaf_repository.dart       # + derived end-marker word ids (no data change)
│   └── reader_screen.dart           # colours only + the look to MushafPageCard (LAST, after feature 003)
├── render/page_renderer.dart        # picture/pdfPage take a look (default Emerald)
├── pdf/pdf_job.dart                 # start() captures the look; writer sheet colour from it
├── ayah/ui/*, wirds/*, settings/about_screen.dart, text_size_tile.dart   # AppColors -> context.look
├── app.dart, main.dart              # provide AppLookSettings, load before runApp, theme from the choice
test/
├── look/        (look_choice, look_settings, contrast + night pairs, wird_marker, emerald_identity)
├── settings/    (look_tile, settings look, backup look)
├── mushaf/      (page_look_night, page_layout_both_looks, reader in night)
├── render/ pdf/ (picture and PDF in night)
├── wirds/ ayah/ (screens in both looks)
```

**Structure Decision**: single Flutter project as in features 001 to 003; the look model, its parse and the
contrast maths are pure Dart under `lib/look/` so they can be tested without a widget tree; the screens only
change where they read their colours.

## Coordination (shared folder)

Other sessions work in this folder. Before every task check `git status` and `git log`.

| Files | Owner | Rule for this feature |
|---|---|---|
| `lib/mushaf/reader_screen.dart`, `page_scale.dart`, `page_viewport.dart`, `lib/settings/text_size_tile.dart`, `lib/ayah/ui/reading_text.dart` | feature 003 session until its tasks T014-T022 are committed | colour-only edits happen in the LAST tasks of this feature (phase 7), after that session has committed and `git status` shows them clean |
| `lib/render/*`, `lib/pdf/*`, `lib/mushaf/page_look.dart`, `test/support/fake_renderer.dart`, `fake_pdf.dart` | feature 002 (done, the 002 session may still polish) | edit only when `git status` shows them clean; the interface change is one task |
| `.specify/feature.json` | whoever runs speckit last | NOT changed by this feature; run speckit scripts with `SPECIFY_FEATURE_DIRECTORY=specs/004-night-reader-theme SPECIFY_FEATURE_NO_PERSIST=1` |

## Complexity Tracking

No Constitution Check violations. One recorded deviation from a quiet rule instead:

| Deviation | Why needed | Simpler alternative rejected because |
|---|---|---|
| `PageRenderer.picture` and `pdfPage` gain an optional `look` parameter, so the two test fakes in `test/support` (`fake_renderer.dart` and the renderer fakes inside 002 tests, if any) get the same optional parameter (behaviour unchanged) | the look must reach the off-screen renderer explicitly and be frozen when a job starts (FR-011) | a global "current look" read by the renderer would let a look change corrupt a running PDF job; a second sub-interface (`LookAwareRenderer`) keeps old fakes untouched but leaves two code paths to test forever |
| `PageLook` gets one field beyond data-model.md: `bannerRule` (the colour of the two hairlines of the Night surah title) | the Night frame is transparent, so it cannot carry the hairline colour the design gives the title rules | reusing `frame` would draw the hairlines invisible; reusing `ring` is null in Night |
| `PageData.endMarkerIds` is derived in `MushafRepository.loadPage`, and the last word of a page needs the next page's first word: it comes from the memo, a loaded page in the cache, or one extra small asset read that is not kept as a page; when none is available the word is simply not marked (page 604's last word is always marked; never throws) | an ayah-end marker is the last word of an ayah, and an ayah can end on the first word of the next page (T021 said never to wait for a second page) | marking only words inside the loaded page misses the ayahs that end on the next page's first word; loading the next page as a page would delay every page turn |
| `AppLook` gains `rowRadius(own)` and `darkCards` beyond the first token list | menu rows and panels take the card radius in Night but their own radius in Emerald; the transient surfaces (snack bar, dialog, menu, tooltip) are charcoal only for dark cards | a second set of radius tokens per screen duplicates `cardRadius`; reading the colour's luminance in each screen repeats the same threshold |
| The reader's top line uses `heading` for the surah name and `controlBorder` for the wird pill outline, and the bar items use `heading` | the contract's row names `textSecondary` for the surah name, which would turn Emerald's gold name muted and break the pixel-identical default; `heading` is gold in Emerald and the light ink in Night | adding a token only for the surah name; the design's `#9AA4AD` for it stays out of Night until the owner asks |
