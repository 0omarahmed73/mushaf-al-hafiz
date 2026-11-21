# Tasks: Al-Kahf Reminder Day

**Input**: `specs/007-kahf-day/` (spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md,
checklists/kahf.md)

**Rules**: test-first (a failing test is written and run red before the code that makes it pass); one commit per
task; `git add` explicit paths only and `dart format` on explicit files only (other sessions edit this tree: never
`git add -A`, `git stash`, `git reset`, `git checkout`, `git restore`, `git clean`); commit with
`git commit -m "..." -- <explicit paths>`; **new tests go in NEW files** (`test/kahf/`): the tests of features 001 to
006 are never edited and must keep passing (spec FR-011, SC-002). Check `git status` and `git log -- <file>` before
every task. `.specify/feature.json` is NOT changed (speckit scripts run with `SPECIFY_FEATURE_DIRECTORY=specs/007-kahf-day
SPECIFY_FEATURE_NO_PERSIST=1`); no git branch is created. Files this feature may edit: `lib/reminders/**`,
`lib/settings/settings_screen.dart`, `lib/wirds/wird_repository.dart` (only the Al-Kahf parts: the `readSetting` and
`writeSetting` added by another session stay), `lib/backup/backup_service.dart` (only if T006 finds something red),
new files under `test/kahf/` and, only if a test cannot do without, new files under `test/support/`. Never edited:
`lib/mushaf/**`, `lib/main.dart`, `lib/app.dart`, `android/**`, `pubspec.yaml`, `docs/**`, the constitution, any
existing test or support file. Tests are run by file or folder, with a timeout and the output in a file, never the
whole suite; widget tests that write to the database with `tester.runAsync` while a drift `watch*` stream is listened
inside the fake-async zone can hang, so they use one-shot reads. Known harmless issue: at 320 dp the reader's bottom
bar overflows in other features' tests (not these). Arabic UI strings are proposals until the owner confirms them
(T009): the feature is not done before that. Commit trailer: `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.

Key: **FR/SC** are the spec's requirement and success-criterion ids; "data-model.md X" is the cited definition. The
user stories are US1 (choose Friday), US2 (nothing changes by default), US3 (backup), US4 (looks and sizes).

## Phase 1: Setup

- [X] T001 Test-first: `test/kahf/kahf_day_test.dart` (red: the files do not exist): `KahfDay.fromStorage` returns
  thursday for `null`, `''`, `'monday'`, `'Friday'` (case matters) and `'thursday'`, friday for `'friday'`;
  `storageValue` is `'thursday'` / `'friday'` and `weekday` is `DateTime.thursday` / `DateTime.friday`; every
  constant of contracts/dart-interfaces.md `kahf_strings.dart` equals its text exactly (the seven proposals and the two
  switch texts of today), and `kKahfBodyFriday` differs from `kKahfBody`; then create `lib/reminders/kahf_day.dart` (no imports; data-model.md `KahfDay`) and `lib/reminders/kahf_strings.dart`
  (a doc comment says the proposals wait for the owner, T009; nothing else in the file) (spec FR-001, FR-008, FR-013;
  research D1, D7, D8)

---

## Phase 2: Foundational (blocks every story)

**Purpose**: the pure planning rule and the stored setting. Nothing visible changes.

- [X] T002 Test-first: `test/kahf/kahf_planner_test.dart` (red: no `kahfDay` parameter): a helper builds plans with
  `planReminders` like `test/reminders/reminder_planner_test.dart` (no wirds, `kahfEnabled: true`, `kahfPage: 293`);
  for **every date of 2026** as today (at 10:00, hour 21:00) and for each day: Thursday plans only Thursdays with
  the body `kKahfBody`, Friday only Fridays with `kKahfBodyFriday`; title `kKahfTitle`, payload `page:293`, the hour is
  the chosen one (try 21:00 and 07:30), nothing in the past or beyond 14 days, two notifications when today is not the chosen
  weekday or its hour is still ahead and one when today is the chosen weekday and its hour has passed (07:30 at 10:00),
  ids all different and equal `kKahfIdBase + (days from today)`; the plan without the parameter equals the plan with
  `KahfDay.thursday` for every date; a plan never holds a notification on the other weekday; today's notification is
  planned when its hour is still ahead and skipped when not (Friday 22:00 with Friday chosen: one notification, id
  `900007`; Thursday 10:00 with Friday chosen: first id `900001`); switched off, none for either day; a wird reminder
  at the same minute coexists with both. Then edit `lib/reminders/reminder_planner.dart`: the optional
  `KahfDay kahfDay = KahfDay.thursday` parameter, the weekday and the body from it, nothing else (spec FR-003, FR-004,
  FR-005, SC-001, SC-002; data-model.md `The plan rule`; research D2)
- [X] T003 Test-first: `test/kahf/kahf_repository_test.dart` and `test/kahf/kahf_scheduler_test.dart` (red), both on an
  in-memory `AppDatabase`, no widgets: the repository returns Thursday on a fresh database, Friday after
  `setKahfDay(KahfDay.friday)` and Thursday after `setKahfDay(KahfDay.thursday)`; a stored `'monday'` and an empty
  string (inserted straight into the `settings` table) read as Thursday; `setKahfDay` does not change `kahfEnabled`
  or `kahfMinutes` and `setKahf` does not change the day; `reminderInputs(now).kahfDay` follows the setting and a
  `ReminderInputs` built without it is Thursday (data-model.md `The setting`, `ReminderInputs.kahfDay`); the scheduler
  test (clock Friday 2026-11-20 10:00, as `test/reminders/reminder_scheduler_test.dart`): the default plan holds the
  two Thursdays 26 Nov and 3 Dec at 21:00 with today's body; after `repo.setKahfDay(friday)` and the scheduler's pause
  the phone's schedule is replaced by one holding the two Fridays 20 Nov and 27 Nov at 21:00 with the Friday body and
  the wirds' notifications unchanged, and after switching back Thursdays again; with the switch off the plan holds
  none and `kahfDay()` still returns Friday; `buildReminderPlan` equals `planReminders` with the stored values. Then
  edit `lib/wirds/wird_repository.dart` (the Al-Kahf block only: key `kahfDay`, `kahfDay()`, `setKahfDay`, the
  `ReminderInputs.kahfDay` optional parameter and its value in `reminderInputs`; check `git status` and
  `git log -- lib/wirds/wird_repository.dart` first) and `lib/reminders/reminder_scheduler.dart` (`kahfDay:
  inputs.kahfDay`) (spec FR-001, FR-005, FR-007, SC-003; research D4, D5)

---

## Phase 3: User Story 1 and 2 (P1) - choose the day; nothing moves by default

**Goal**: spec User Stories 1 and 2. **Independent test**: in Settings, with the reminder on, the choice shows
Thursday selected; tapping «الجمعة» saves Friday and the switch texts name Friday; a fresh install behaves as before.

- [X] T004 [US1] Test-first: `test/kahf/kahf_settings_test.dart` (red) through `test/support/harness.dart`
  (`pumpAppWith(t, home: const SettingsScreen(), reminders: ...)` as `test/settings/settings_screen_test.dart`; one-shot
  reads with `t.runAsync(repo.kahfDay)`): with the switch on the keys `kahf-day`, `kahf-day-thursday` and
  `kahf-day-friday` are found, in the order switch, choice, hour row (top to bottom), with the labels «الخميس» and «الجمعة» and no
  visible «يوم التذكير», and Thursday is selected (its card has the check icon and the accent outline, Friday's has neither); the switch title
  and subtitle are today's strings; tapping «الجمعة» saves Friday (`repo.kahfDay()`), moves the mark and changes the
  switch title to «تذكير سورة الكهف يوم الجمعة» and the subtitle to «كل جمعة في الوقت الذي تختاره», leaving
  `kahfEnabled` and `kahfMinutes` as they were; tapping it again changes nothing; tapping Thursday brings today's texts
  back; with the switch turned off `kahf-day` and `kahf-time` are gone and turning it on shows the kept day; a saved
  Friday is shown when Settings opens; with notifications not allowed the permission card shows and the choice still
  saves. Then edit `lib/settings/settings_screen.dart` (check `git status` and `git log` first; additive): `_kahfDay`
  loaded in `_load`, `_saveKahfDay`, a private widget for the choice as contracts/ui.md describes (two cards, stacked
  under 340 dp or a large system font, `Semantics`, look tokens only) between the switch and the hour row, and the
  switch title and subtitle from `kahf_strings.dart` by the day; the Thursday strings stay byte for byte; the three
  existing settings test files stay green unchanged (spec FR-002, FR-007, FR-008, US1, US2; research D6, D7)
- [X] T005 [US1] Use the neutral name in the phone's notification settings. Test-first: add to
  `test/kahf/kahf_day_test.dart` (red) a group that reads `lib/reminders/reminder_service.dart` as text (the plugin cannot
  run in a test) and asserts that it contains `kKahfChannelName`, that it no longer contains the literal `سورة الكهف
  ليلة الجمعة`, and that the channel id `kahf_reminders` is still there; `kKahfChannelName` itself has neither «الخميس»
  nor «الجمعة». Then edit `lib/reminders/reminder_service.dart` so the al-Kahf channel is named `kKahfChannelName`
  (the channel id and the wird channel stay as they are) (spec FR-008; research D7)

**Checkpoint**: the owner can pick the day and the schedule follows it; the feature works without backup or look
checks.

---

## Phase 4: User Story 3 (P2) - the choice survives backup and restore

**Goal**: spec User Story 3. **Independent test**: export on Friday, import into a fresh database: Friday.

- [X] T006 [US3] Write `test/kahf/kahf_backup_test.dart` on two in-memory databases (no widgets, as
  `test/backup/backup_service_test.dart`): export with Friday has `settings['kahfDay'] == 'friday'` and importing it
  into an empty database gives Friday and a plan of Fridays; export with the day never set has no `kahfDay` key and
  imports as Thursday; an export with the key removed (an older backup) passes `check` and `importJson` and gives
  Thursday even when the target database held Friday (the table is replaced); a file with `'kahfDay': 'monday'` is
  accepted and reads as Thursday; `kBackupVersion` is still 1. These are expected to pass at once because settings are
  a generic key/value map (research D10): say so in the commit message, prove each assertion can fail by changing its
  expected value in the test file temporarily (and restoring it), and change `lib/backup/backup_service.dart` only if a
  case is red for a reason the test shows (spec FR-009, SC-004; research D10)

---

## Phase 5: User Story 4 (P2) - fits both looks and every size

**Goal**: spec User Story 4. **Independent test**: Settings in both looks, at 320 dp with a 2x system font.

- [X] T007 [US4] Write `test/kahf/kahf_settings_look_test.dart` through `test/support/look_harness.dart`
  (`LookApp.create`, `show(t, const SettingsScreen(), screen:, textScale:)`): for each look (Emerald, Night) and each of
  412 x 915 and 320 x 640 with `textScale` 1.0 and 2.0, with Thursday and with Friday saved, there is no exception
  (`tester.takeException()`), both cards are inside the screen and at least 48 px high and wide, the cards do not
  overlap each other, and `contrastIssues(t)` of `test/support/contrast_walk.dart` is empty; at 320 dp with 2x the cards
  are stacked (one above the other) and at 412 dp with 1x they are side by side; the choice is the same at reading
  sizes 80, 100 and 150 (`repo.setTextSizePercent`); the semantics tree has each card as a button with its label, the
  saved one `isSelected` and the Thursday card named «الخميس (ليلة الجمعة)», the group named «يوم التذكير»
  (dispose the `SemanticsHandle`); the choice
  recolours when the look changes while Settings is shown (`LookApp.choose`). Fix whatever is red in
  `lib/settings/settings_screen.dart` (same commit rules as T004); a case that passes at once is proved able to fail
  by a temporary change of one expectation (spec FR-010, SC-005, US4; contracts/ui.md The choice)

---

## Phase 6: Polish and sign-off

- [X] T008 Regression and hygiene, no new behaviour: `dart format` on exactly the files this feature created or
  edited (`lib/reminders/kahf_day.dart`, `lib/reminders/kahf_strings.dart`, `lib/reminders/reminder_planner.dart`,
  `lib/reminders/reminder_scheduler.dart`, `lib/reminders/reminder_service.dart`, `lib/settings/settings_screen.dart`, the
  Al-Kahf block of `lib/wirds/wird_repository.dart` by hand if the file would be reformatted elsewhere, and
  `test/kahf/*.dart`); `flutter analyze` on those paths reports nothing; run
  `timeout 600 flutter test test/kahf test/reminders test/settings test/backup --reporter expanded` (output in the
  scratchpad) and `timeout 600 flutter test test/wirds/wird_repository_test.dart`: everything passes with no existing
  test edited; `git diff --stat` of the feature's commits touches only the allowed paths (no `pubspec.yaml`, `android/**`,
  `lib/wirds/db.dart` or `lib/backup/**` unless T006 found a red case), so no package, permission or table was added
  (spec FR-012); record the counts in the
  commit message (spec FR-011, SC-002; Constitution IX)
- [ ] T009 Owner's confirmation and phone check (manual; **not done by the agent**; the main box stays unchecked
  until the phone check is done):
  - [X] The owner confirmed the strings and answered the open questions of research D8 on 2026-11-21 (in chat): every
    string of `lib/reminders/kahf_strings.dart` as written, one day only, and a default hour of 10:00 for Friday
    (built in T010 to T012).
  - [ ] The phone check of quickstart.md «On the phone» (Friday and Thursday notification arrive with the right body at
    the day's default hour, the tap opens page 293 in browse mode, a chosen hour wins, backup keeps the day). The agent
    must ask before any install or input on the phone (spec SC-006; Constitution VI, IX)

---

## Dependencies and order

- T001 first (the enum and the strings). T002 and T003 both need T001; T002 and T003 touch different files and can be
  written in parallel, but each commits alone.
- T004 needs T003 (the repository). T005 needs only T001. T006 needs T003. T007 needs T004.
- T008 needs everything but T009; T009 is the owner's and can happen while T008 runs.
- MVP: T001 to T004 (the choice works end to end). T005 to T007 finish the quality bars; T008 and T009 close it.

## Implementation strategy

One small commit per task, red then green, in the order above. If a test that is supposed to be red passes at once
(T006, parts of T007), the commit message says so and the task proves the assertion can fail. After T008 run
`/speckit-analyze` and `/speckit-converge`; whatever converge appends is done the same way.

---

## Phase 7: The owner's answers of 2026-11-21 (default hour per day)

**Rules as above.** These tasks change code the earlier tasks wrote, so tests of this feature that the new rule changes
(the Friday hour in `kahf_settings_test`, `kahf_repository_test`, `kahf_scheduler_test`) are updated in the same commit
as the code; no test of features 001 to 006 is edited.

- [X] T010 [US1] Default hour per day, test-first: `test/kahf/kahf_default_time_test.dart` (red) pins spec FR-014 and
  SC-007: `KahfDay.thursday.defaultMinutes` is 1260 and `friday` 600; with no hour chosen `kahfMinutes()` follows the day
  and nothing is stored; a chosen hour wins for both days; `setKahf` also chooses; `setKahfEnabled` stores no hour and
  `setKahfMinutes` leaves the switch; a stored text that is not a number counts as no hour; `reminderInputs` carries the
  same hour; the scheduler plans Friday at 10:00 by default, then the chosen 07:30, then Thursday at 07:30; in Settings
  tapping «الجمعة» shows 10:00 at once and «الخميس» 21:00 again, the switch off and on stores nothing, a chosen hour wins
  over the new day's default, and an hour confirmed in the picker is stored and then wins. Then code: `defaultMinutes` on
  `KahfDay`, the day-aware `kahfMinutes()`, `kahfMinutesChosen()`, `setKahfEnabled`, `setKahfMinutes` and `reminderInputs`
  reading the day once (`lib/wirds/wird_repository.dart`, Al-Kahf block only), and `lib/settings/settings_screen.dart`
  (the switch saves the switch only, the picker saves the hour only, a day change moves an unchosen hour at once)
  (spec FR-014, SC-007, US1/AC6-AC8; research D3; data-model.md `The setting`, `KahfDay.defaultMinutes`)
- [X] T011 The owner's confirmations in the documents: record the answers in spec.md (Clarifications, FR-013, FR-014,
  SC-007, Assumptions, Status), research.md (D3, D8), data-model.md, contracts/ and quickstart.md; the header of
  `lib/reminders/kahf_strings.dart` and the name of the strings group in `test/kahf/kahf_day_test.dart` say the strings are
  confirmed, no longer proposals; T009's string part is ticked (spec FR-013; Constitution VI)
- [X] T012 Two documentation leftovers: the settings-key comment in `lib/wirds/db.dart` names `kahfDay` and says when
  `kahfMinutes` is stored; `specs/001-mushaf-reader-wirds/contracts/notifications.md` gets one line saying that feature 007
  chooses Thursday or Friday and the default hour per day (the table row keeps its words; no other line of feature 001
  changes)
