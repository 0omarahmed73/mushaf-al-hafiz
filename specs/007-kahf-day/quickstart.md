# Quickstart: Al-Kahf Reminder Day

## Automated (no phone)

```bash
cd <repo-root>
timeout 600 flutter test test/kahf test/reminders test/settings test/backup --reporter expanded
flutter analyze lib/reminders lib/settings/settings_screen.dart lib/wirds/wird_repository.dart test/kahf
```

Expected: every test passes (the tests of features 001 to 006 unchanged), analyze reports nothing. Known harmless
issue: at 320 dp the reader's bottom bar overflows in other features' tests; it is not part of these files.

What the new tests prove, by file (see tasks.md): `kahf_day_test` the enum and the strings; `kahf_planner_test` both
days for every date of a year; `kahf_repository_test` the default, the write and the unknown value; `kahf_scheduler_test`
that a day change replans; `kahf_backup_test` export, import, an old backup and an unknown value; `kahf_settings_test`
the control and the switch texts; `kahf_settings_look_test` both looks, 320 dp with a 2x font, contrast, 48 px and
semantics.

## On the phone (owner, Constitution IX; ask before any install)

1. Settings: the al-Kahf switch is on, the choice shows «الخميس» selected, the hour row shows 21:00.
2. Tap «الجمعة»: it shows selected, the hour row shows 10:00 (nobody chose an hour), the switch texts say «يوم الجمعة»
   and «كل جمعة». Close and reopen the app: still Friday and 10:00. Tap «الخميس»: 21:00 again. Pick an hour in the row
   (say 08:00) and tap the other day: 08:00 stays.
3. Set the hour two minutes ahead on a Friday (or move the phone's date to a Friday): the notification arrives with the
   Friday body, even with the screen locked; tap it: page 293 opens in browse mode.
4. Tap «الخميس» and move the date to a Thursday: the notification arrives with today's body.
5. Export a backup on Friday, import it: the choice is Friday again.
6. Both looks, large system font: nothing is cut off.
