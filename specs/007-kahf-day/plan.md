# Implementation Plan: Al-Kahf Reminder Day

**Branch**: `007-kahf-day` (work stays on `main`) | **Date**: 2026-11-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/007-kahf-day/spec.md`

## Summary

One new setting, `kahfDay` (`thursday` default, `friday`), chosen in Settings under the al-Kahf switch and used by the
reminder planner: the al-Kahf notification is planned on the chosen weekday instead of always on Thursday, with the
Friday body for Friday. The planner stays a pure function (one new optional parameter, so every existing call and test
is unchanged); the repository reads and writes the setting and hands it to the planner through `ReminderInputs`; the
scheduler already replans on every settings change, so no new refresh path exists. The hour has a default per day
(21:00 Thursday, 10:00 Friday; owner, 2026-11-21): `kahfMinutes()` is the chosen hour else the day's default, never stored,
and the Settings switch no longer stores the hour (research D3). Backups carry the setting for free
because they export the whole settings table; only tests are added there. The new Arabic strings live in one file as
proposals the owner confirms.

## Technical Context

**Language/Version**: Dart 3.14 / Flutter 3.50 (Android first)

**Primary Dependencies**: `package:material_ui`, `provider`, `drift` (already used); nothing new

**Storage**: one more row in the existing `settings` key/value table (`kahfDay`); no table, no column, no migration

**Testing**: `flutter test` with new files only (`test/kahf/`); the planner, repository, scheduler and backup are tested
without widgets; the Settings screen through `test/support/harness.dart` and `test/support/look_harness.dart`; contrast
walk from `test/support/contrast_walk.dart`; real-device check on the owner's phone

**Target Platform**: Android phone, portrait and landscape, RTL

**Project Type**: mobile app

**Performance Goals**: the choice is saved and shown in the same frame as the tap; the schedule is replaced within the
scheduler's usual pause (400 ms)

**Constraints**: offline, no tracking; earlier tests unchanged; nothing overflows at 320 dp with a 2x system font;
targets at least 48 px; contrast 4.5:1 / 3:1; the Quran text, the Mushaf and the reader are not touched

**Scale/Scope**: 2 new small files in `lib/reminders/`, edits of 4 existing files (`reminder_planner.dart`,
`reminder_scheduler.dart`, `reminder_service.dart`, `wird_repository.dart`) and of `settings_screen.dart`; 7 new test
files

## Constitution Check

*GATE: passed before research and again after the design (constitution 1.2.0).*

| Principle | Check |
|---|---|
| I Quran text integrity | No Quran text, page, layout or font is touched; the notification body is a reminder sentence, not Quran text. **Pass** |
| II Mushaf first | The notification still opens page 293 in browse mode (FR-006); nothing is added to the reader. **Pass** |
| III No other duas | The Friday body is a reminder to read surah al-Kahf, not a dua, adhkar or hadith text; the existing Thursday body is the same kind. No new religious text is added. **Pass** |
| IV Offline, private | A local setting only; no network, no data sent, no permission, no package (FR-012). **Pass** |
| V Licensing | No external resource. **Pass** |
| VI Arabic, RTL | All new strings are Arabic, in one file, marked as proposals until the owner confirms (FR-013, research D8); the control is RTL and follows the looks. **Pass** |
| VII Reliability | Reminders stay local notifications scheduled by the phone with `zonedSchedule`; the existing refresh on start, resume, change and in the background applies to the new day; a failing refresh still never takes the app down. **Pass** |
| VIII App size | A few hundred bytes of code and one setting row. **Pass** |
| IX Quality gates | Tests first for every task (pure planner, repository, scheduler, backup, Settings); `flutter analyze` clean; the real notification on the phone is checked by the owner (quickstart). **Pass** |

No deviation, so no Complexity Tracking entry. `lib/settings/settings_screen.dart` and `lib/wirds/wird_repository.dart`
are also edited by other sessions in the same tree: coordination, not a deviation (research D9).

## Project Structure

### Documentation (this feature)

```text
specs/007-kahf-day/
├── plan.md              # this file
├── research.md          # decisions D1 to D10 and the owner's open questions (D8)
├── data-model.md        # the setting, KahfDay, the plan rule, ReminderInputs
├── quickstart.md        # automated and phone validation
├── contracts/
│   ├── dart-interfaces.md   # signatures the tests are written against
│   └── ui.md                # the Settings control, the notification table, the backup note
├── checklists/
│   └── requirements.md      # spec quality (done); the plan checklist comes from /speckit-checklist
└── tasks.md             # from /speckit-tasks
```

### Source Code (repository root)

```text
lib/reminders/
├── kahf_day.dart               # NEW: enum KahfDay { thursday, friday } (storage value, weekday, fromStorage); no imports
├── kahf_strings.dart           # NEW: every new Arabic string of the feature (proposals), plus today's switch texts
├── reminder_planner.dart       # EDIT: optional `kahfDay`; weekday and body from it
├── reminder_scheduler.dart     # EDIT: pass inputs.kahfDay
└── reminder_service.dart       # EDIT: the channel name from kahf_strings (neutral)
lib/wirds/wird_repository.dart  # EDIT (Al-Kahf parts only): kahfDay(), setKahfDay(), ReminderInputs.kahfDay, the day-aware kahfMinutes(), kahfMinutesChosen(), setKahfEnabled(), setKahfMinutes()
lib/wirds/db.dart               # EDIT (a doc comment: the settings keys)
lib/settings/settings_screen.dart  # EDIT: the choice under the switch, day-aware switch texts
lib/backup/backup_service.dart  # NOT edited (settings are a generic key/value map; tests only)
test/kahf/
├── kahf_day_test.dart              # NEW (KahfDay, strings)
├── kahf_planner_test.dart          # NEW (both days, every date of a year, ids, body, payload)
├── kahf_repository_test.dart       # NEW (default, set, unknown value, ReminderInputs)
├── kahf_scheduler_test.dart        # NEW (a day change replans; default plan unchanged)
├── kahf_backup_test.dart           # NEW (export, import, old backup, unknown value)
├── kahf_default_time_test.dart     # NEW (the default hour per day: repository, scheduler, Settings, picker)
├── kahf_settings_test.dart         # NEW (choice, visibility, saving, switch texts)
└── kahf_settings_look_test.dart    # NEW (both looks, sizes, 320 dp / 2x, contrast, 48 px, semantics)
```

**Structure Decision**: all new code is in `lib/reminders/` (the enum and the strings) plus one private widget inside
`settings_screen.dart`; nothing is added to `lib/mushaf/`, `lib/main.dart`, `lib/app.dart`, `android/` or
`pubspec.yaml`. The planner keeps its signature compatible: `kahfDay` is optional with the Thursday default.

## Complexity Tracking

No violations to justify.
