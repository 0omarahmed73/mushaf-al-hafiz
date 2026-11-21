# Implementation Plan: First-Run Tips

**Branch**: `008-first-run-tips` (work stays on `main`) | **Date**: 2026-11-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/008-first-run-tips/spec.md`

## Summary

A self-contained component in the new folder `lib/onboarding/`: `TipsGate(child:)` shows a Material dialog once, after
the first frame, when the stored flag `tipsSeen` is not `'true'`. The dialog is a card with a `PageView` of six steps
(a small drawing made of shapes and icons, a title, one or two sentences), a dots indicator, «التالي» / «تخطي», and
«ابدأ» on the last step. Finishing, skipping and back write the flag through the repository's public
`readSetting` / `writeSetting`; any other way of closing writes nothing. The flag is read once (no drift stream). The
flag is one more row of the `settings` table, so it already travels in the backup; the only change outside the folder
is a small additive rule in `BackupService.importJson`: a setting that describes this phone (`tipsSeen`) is kept when
the imported file does not carry it. `showTips(BuildContext)` opens the same dialog at any time. Nothing in
`lib/main.dart`, `lib/app.dart`, `lib/mushaf/**`, `lib/settings/**` or `lib/wirds/**` is edited; the report gives the
coordinator the exact lines to add after the splash.

## Technical Context

**Language/Version**: Dart 3.14 / Flutter 3.50 (Android first)

**Primary Dependencies**: `package:material_ui`, `provider` (already used); nothing new

**Storage**: one existing table, `settings` (key `tipsSeen`, value `'true'`), read and written through
`WirdRepository.readSetting` / `writeSetting`; no new table, no new file, no migration

**Testing**: `flutter test` with new files only (`test/onboarding/`, one new support file
`test/support/tips_harness.dart`); contrast walk from `test/support/contrast_walk.dart`; a real-file database for the
restart test; the real reader for the truth tests; real-device check on the owner's phone

**Target Platform**: Android phone, portrait and landscape, RTL

**Project Type**: mobile app

**Performance Goals**: the popup opens within one second of the first frame (SC-001 in practice: one query and one
route push); a step change is a 250 ms slide, or none under reduced motion

**Constraints**: offline, no tracking; Quran text, layout and page geometry untouched; earlier tests unchanged; nothing
overflows at 320 dp with a 2x system font; targets at least 48 px; contrast 4.5:1 for text and 3:1 for icons; no drift
`watch*` stream in the gate

**Scale/Scope**: one dialog, one gate, one function, one store, six drawings, one strings file; one additive edit in
`lib/backup/backup_service.dart`

## Constitution Check

*GATE: passed before research and again after the design (constitution 1.3.0).*

| Principle | Check |
|---|---|
| I Quran text integrity | The tips show no Quran text: the drawings are bars and icons, the sentences name controls. No page, text, layout or font code is touched. **Pass** |
| II Mushaf first | The tips are a dialog over the reader; the reader is the first screen and keeps its state under it; nothing is shown before it, and closing returns to it exactly as it was (FR-002). **Pass** |
| III Focus | Teaches existing features only; adds no dua, adhkar, hadith or other feature. The khatm dua is deliberately not mentioned. **Pass** |
| IV Offline, private, free | Local flag in the existing database, nothing sent, no package or permission (FR-015). **Pass** |
| V Licensing | No external resource: shapes and the app's own icons. Nothing for `licenses.md` or About. **Pass** |
| VI Arabic and RTL | The dialog is forced right-to-left; the swipe is the paper direction (left to right moves forward); every string is a proposal in one file, written in Arabic, confirmed by the owner before the feature is done (FR-014). **Pass** |
| VII Reliability | The flag survives restarts (a database row); a read failure never blocks the reader (FR-007). **Pass** |
| VIII App size | A few kilobytes of Dart, no asset. **Pass** |
| IX Quality gates | Tests first for each task; pure rules (`isSeen`, the steps) separated and unit-tested; `flutter analyze` clean on the touched files; the swipe feel, the first launch after the splash and a large font are checked on the phone (quickstart). **Pass** |

No deviation, so no Complexity Tracking entry. Two coordination points, neither a deviation: `lib/backup/backup_service.dart`
is edited once, additively, after `git status` and `git log` on it (research D5); `lib/app.dart` / `lib/main.dart` are not
edited (the coordinator wires the gate, quickstart section 3).

## Project Structure

### Documentation (this feature)

```text
specs/008-first-run-tips/
├── plan.md              # this file
├── research.md          # decisions D1 to D14
├── data-model.md        # the flag, the steps, the dialog state, the backup rule
├── quickstart.md        # automated validation, the phone check, the wiring lines
├── contracts/
│   ├── dart-interfaces.md   # signatures the tests are written against
│   └── ui.md                # the six steps, every Arabic string, the controls, the wiring
├── checklists/
│   └── requirements.md      # spec quality (done); tips.md comes from /speckit-checklist
└── tasks.md             # from /speckit-tasks
```

### Source Code (repository root)

```text
lib/onboarding/
├── tips_strings.dart        # NEW: every Arabic string of the feature (owner confirms these)
├── tip_steps.dart           # NEW: TipPicture, TipStep, kTipSteps (pure Dart, no widgets)
├── tips_store.dart          # NEW: kTipsSeenKey, TipsStore (one-shot read, write), isSeen rule
├── tip_picture.dart         # NEW: the six drawings (shapes and icons; one gentle pulse)
├── tips_dialog.dart         # NEW: TipsDialog (PageView, dots, buttons, scroll body) and TipsOutcome
├── tips_gate.dart           # NEW: TipsGate and showTips
lib/backup/backup_service.dart   # EDIT (additive): kKeptOnImport and its use in importJson (research D5)
test/onboarding/
├── tips_strings_test.dart       # NEW: every string pinned (a change needs the owner again)
├── tip_steps_test.dart          # NEW: six steps, at most two sentences, no Quran text
├── tips_store_test.dart         # NEW: isSeen, seen, markSeen on an in-memory database
├── tip_picture_test.dart        # NEW: the six drawings: no text, scale down, one pulse
├── tips_gate_test.dart          # NEW: once, never again, rebuilt, real restart, enabled, failures, showTips
├── tips_dialog_test.dart        # NEW: dots, next, skip, finish, back, RTL swipe, guards, semantics
├── tips_show_again_test.dart    # NEW: showTips from any screen, twice, without a repository
├── tips_look_size_test.dart     # NEW: two looks, 412x915 and 320x640 with a 2x font, contrast, targets
├── tips_motion_test.dart        # NEW: reduced motion and the pulse
├── tips_backup_test.dart        # NEW: export, import, old file, kept flag, failed import
└── tips_reader_truth_test.dart  # NEW: each step's claim done on the real reader
test/support/tips_harness.dart   # NEW: pumps the gate or the dialog in either look, size and text scale
```

**Structure Decision**: one new folder holds everything new; the reader, Settings, the wirds and the app root are read,
never edited. The backup service gets one additive rule (research D5). `AppLook` and `buildAppTheme` (feature 004) are
used as they are.

## Complexity Tracking

No violations to justify.
