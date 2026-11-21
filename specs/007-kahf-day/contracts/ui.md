# UI contract: Al-Kahf Reminder Day

## Settings, «التذكيرات» section (top to bottom)

| Row | Key | When |
|---|---|---|
| al-Kahf switch (title and subtitle follow the day) | `kahf-switch` | always |
| the choice of the day | `kahf-day` | only while the switch is on |
| the hour row | `kahf-time` | only while the switch is on; shows the chosen hour, else the default of the chosen day (21:00 Thursday, 10:00 Friday), and follows a change of day at once |

Switch texts: Thursday «تذكير سورة الكهف ليلة الجمعة» / «كل خميس في الوقت الذي تختاره» (today's); Friday «تذكير سورة
الكهف يوم الجمعة» / «كل جمعة في الوقت الذي تختاره» (confirmed 2026-11-21).

## The choice (`kahf-day`)

- No visible heading (the screen has no room, research D6); the group is `Semantics(container: true, label: «يوم
  التذكير»)` for a screen reader.
- Two cards: `kahf-day-thursday` showing «الخميس» (named «الخميس (ليلة الجمعة)» for a screen reader) and
  `kahf-day-friday` showing «الجمعة». In a row of two equal cards; stacked (a column of two) when the width available
  to the choice (the window width minus the 18 px list padding on each side: 376 dp on a 412 dp window, 284 dp on a
  320 dp one) is under 340 dp or the system text makes 15 px text larger than 17 px.
- Each card: at least 48 px high (the whole choice adds 48 px to the screen's height when side by side), rounded by
  `look.cardRadius`, 15 px semi-bold text in `look.text`; unselected: 1 px `look.controlBorder`; selected: 2 px
  `look.accent` outline and a `Icons.check_circle` 22 px in `look.accent`.
- A tap on the unselected card saves its day at once; a tap on the selected one does nothing.
- Semantics per card: button, `selected` set for the chosen one, label = the card's name.
- Colours only from the look tokens, so both looks follow; no new colour.

## The notification (unchanged in shape)

| Day | Title | Body | Payload | Id |
|---|---|---|---|---|
| Thursday | سورة الكهف | ليلة الجمعة: لا تنسَ قراءة سورة الكهف | `page:293` | `900000 + dayOffset` |
| Friday | سورة الكهف | يوم الجمعة: لا تنسَ قراءة سورة الكهف | `page:293` | `900000 + dayOffset` |

Android channel `kahf_reminders`, named «تذكير سورة الكهف» in the phone's system settings.

## Backup

`settings.kahfDay` is `"thursday"` or `"friday"` when present. No change to the file format version, the screens or
the messages of export and import.
