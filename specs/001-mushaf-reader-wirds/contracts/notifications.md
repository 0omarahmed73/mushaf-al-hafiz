# Contract: Local notifications

Planned by the pure function `planReminders(...)` and scheduled by `ReminderService.reschedule(plan)`.
All times are phone-local (`timezone` + `flutter_timezone`). Mode: `inexactAllowWhileIdle`.

| Kind | When | ID | Title | Body | Payload | Tap opens |
|---|---|---|---|---|---|---|
| Wird | each day in the next 14 days at `notifyMinutes`, for wirds with `notifyEnabled`; today skipped if done or time passed (for qiyam, "today" is the wird day starting 04:00) | `wirdId * 100 + dayOffset` | «ورد: <name>» | «من ص A إلى ص B» | `wird:<id>` | reader on that wird, not browse mode |
| al-Kahf | every Thursday (the night of Friday) in the next 14 days at `kahfMinutes` (default 1260 = 21:00), if `kahfEnabled` | `900000 + dayOffset` | «سورة الكهف» | «ليلة الجمعة: لا تنسَ قراءة سورة الكهف» | `page:293` | page 293 in browse mode |

Feature 007 (specs/007-kahf-day): the al-Kahf notification falls on Thursday (the row above, the default) or on Friday
with the body «يوم الجمعة: لا تنسَ قراءة سورة الكهف», by the setting `kahfDay`; `kahfMinutes` is the hour the user chose,
else 21:00 for Thursday and 10:00 for Friday.

`dayOffset` = days from today (0…13). For days after today, A–B in the body is the portion that would
start from the wird's current position.

## Rescheduling triggers

App start, app resume, any wird create/update/delete, «تم», Kahf setting change, successful import,
and a daily background refresh (WorkManager periodic task, ~24 h) so the schedule never runs out.
Each run cancels all then schedules the new plan. Deleting a wird cancels its ids at once; a tapped
`wird:<id>` whose wird no longer exists opens browse mode at `lastViewedPage`.

## Android requirements

`POST_NOTIFICATIONS` (requested at runtime on Android 13+; if denied, settings show a line and a
request button), `RECEIVE_BOOT_COMPLETED` and the plugin's boot receiver so schedules survive a restart.
No exact-alarm permission.
