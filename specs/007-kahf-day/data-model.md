# Data Model: Al-Kahf Reminder Day

No table, column or migration is added. One row is added to the existing key/value `settings` table
(`lib/wirds/db.dart`).

## The setting

| Key | Value | Default | Read rule |
|---|---|---|---|
| `kahfDay` | `thursday` or `friday` | `thursday` (the row is absent) | any other text, and a missing row, read as `thursday` |

It sits beside `kahfEnabled` (`true`/`false`, default `true`) and `kahfMinutes` (minutes after midnight). The three
together say: whether, on which weekday, and at what hour.

`kahfMinutes` is written **only when the user chooses an hour** (the picker, or a restored backup). When the row is
absent (or holds text that is not a number) the hour is the default of the chosen day: `KahfDay.defaultMinutes`, 1260 =
21:00 for Thursday and 600 = 10:00 for Friday (owner, 2026-11-21). A default is never stored, so it follows a later
change of day; a chosen hour wins for both days.

## KahfDay (a value, not stored)

| Value | `storageValue` | `weekday` | `defaultMinutes` | Notification body |
|---|---|---|---|---|
| `thursday` | `thursday` | `DateTime.thursday` (4) | 1260 (21:00) | «ليلة الجمعة: لا تنسَ قراءة سورة الكهف» (today's, unchanged) |
| `friday` | `friday` | `DateTime.friday` (5) | 600 (10:00) | «يوم الجمعة: لا تنسَ قراءة سورة الكهف» (confirmed 2026-11-21) |

`KahfDay.fromStorage(null)` and `fromStorage('monday')` are `thursday`.

## The plan rule (planner)

For each day `d` from today for `horizonDays` (14) days: when `kahfEnabled` and `d.weekday == kahfDay.weekday`, the
planned notification is at `d` with the hour `kahfMinutes`, skipped when that moment is not after `now`. Its fields:

| Field | Value |
|---|---|
| `id` | `kKahfIdBase + k` (900000 + the day's offset k from today, 0..13): unique in a plan, above every wird id |
| `at` | `d` at `kahfMinutes ~/ 60`:`kahfMinutes % 60` local time |
| `title` | «سورة الكهف» |
| `body` | by the table above |
| `payload` | `page:293` (browse mode) |

In any plan at most 2 notifications of al-Kahf exist (14 days hold two of any weekday), and all are on one weekday.

## ReminderInputs

Gains `kahfDay` (a `KahfDay`, optional, default `thursday`) beside `kahfEnabled` and `kahfMinutes`. `kahfMinutes` is
the hour in use: the chosen one, else the default of `kahfDay`, computed from the same day that is in the same value.

## Backup file

The `settings` object of the backup gets `"kahfDay": "friday"` when the day was set; nothing is written for a day that
was never set. The file format version is unchanged. Import restores whatever string is there; an unknown string is
read as Thursday.

## State transitions

| Event | Writes | Then |
|---|---|---|
| Tap «الجمعة» (day was Thursday) | `kahfDay = friday` | scheduler replans; plan holds Fridays only |
| Tap «الخميس» | `kahfDay = thursday` | scheduler replans; plan holds Thursdays only |
| Switch off | `kahfEnabled = false` | plan holds no al-Kahf; `kahfDay` kept |
| Switch on again | `kahfEnabled = true` | plan holds the kept day |
| Choose an hour in the picker | `kahfMinutes` | the hour is now chosen: the plan uses it on the kept day and it stays when the day changes |
| Tap the other day with no hour chosen | `kahfDay` only | the shown hour and the plan move to the new day's default (10:00 Friday, 21:00 Thursday) |
| Tap the other day with an hour chosen | `kahfDay` only | the hour is unchanged |
| Switch off or on | `kahfEnabled` only | no hour is chosen by it |
| Import a backup | all settings replaced | refresh forced; `kahfDay` is the file's or Thursday |
