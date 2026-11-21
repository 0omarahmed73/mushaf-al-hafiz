# Feature Specification: Al-Kahf Reminder Day

**Feature Branch**: `007-kahf-day` (work stays on `main`, as for features 001 to 006)

**Created**: 2026-11-21

**Status**: Built; the strings, the day choice and the default hour are confirmed by the owner (2026-11-21); the phone check is open

**Input**: User description (owner, Egyptian Arabic): "عايز اضيف تعديلة بسيطة, اخلي اليوزر يختار تنبيه سورة الكهف يبقى
الخميس ولا الجمعة ويختار الساعة" — let the user choose whether the al-Kahf reminder comes on Thursday or on Friday,
and choose the hour. The on/off switch and the hour already exist (feature 001, FR-036 and FR-038); this feature adds
the choice of the day.

## Clarifications (proposed, owner confirms)

These were decided by default, not asked; the owner confirms or changes them before the feature is called done
(Constitution VI). The questions put to the owner are in research.md (D8).

**Owner's answers, 2026-11-21 (in chat):** (1) the hour has a default for each day: 10:00 in the morning for Friday when
the user has not set an hour, 21:00 for Thursday as before; an hour the user set, now or later, always wins; (2) one day
only, Thursday or Friday, as built; (3) every Arabic string of the feature as written in `lib/reminders/kahf_strings.dart`
is confirmed (Friday body, the cards «الخميس» and «الجمعة», the screen-reader name «الخميس (ليلة الجمعة)», the
Friday switch title and subtitle, the channel name). The items below that say otherwise are replaced by these answers.

- Q: What are the two days, and which is the default? → A: Thursday, which is the night of Friday («ليلة الجمعة»),
  exactly as the app behaves today, is the default; Friday is the other choice. Nothing else (no Saturday, no both
  days, no other weekday).
- Q: Does the hour belong to the day? → A: An hour the user chose belongs to neither day: it applies to whichever day
  is chosen, and choosing a day never changes it. Only the default depends on the day: while the user has not chosen an
  hour, the hour is 21:00 for Thursday and 10:00 for Friday, the row shows the one of the chosen day, and tapping the
  other day changes the row at once. An hour is chosen only in the hour picker (or restored from a backup that holds
  one); turning the reminder off and on, or choosing a day, never chooses an hour. (Owner, 2026-11-21.)
- Q: What does the Friday notification say? → A: Its title stays «سورة الكهف»; its body is «يوم الجمعة: لا تنسَ قراءة
  سورة الكهف». The Thursday notification keeps today's body «ليلة الجمعة: لا تنسَ قراءة سورة الكهف», unchanged.
- Q: Where is the choice, and when is it visible? → A: In Settings, directly under the al-Kahf switch and above the
  hour row, as two options side by side «الخميس» and «الجمعة» (a screen reader hears the first as «الخميس (ليلة
  الجمعة)»); it is shown only while the switch is on,
  like the hour row. Switching the reminder off and on again keeps the day.
- Q: When is the choice applied? → A: At once. A tap saves the day and the phone's schedule is rebuilt through the
  same path that already follows the switch and the hour; there is no «save» button.
- Q: What does a tap on the notification do? → A: The same on both days: it opens page 293 in browse mode.
- Q: Do the switch's own title and subtitle change? → A: Yes, only for Friday: they name the chosen day, because
  «ليلة الجمعة» and «كل خميس» would be wrong. For Thursday they stay exactly as today.
- Q: Does the backup carry the choice? → A: Yes, as one more setting in the file; an older backup without it is
  restored with Thursday, and an unknown value is read as Thursday.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Choose Friday instead of Thursday (Priority: P1)

The reader opens «☰» then Settings, sees under «التذكيرات» the al-Kahf switch (on), and under it the choice of the day
with «الخميس» selected and then the hour row. They tap «الجمعة». From then on the phone reminds them to
read surah al-Kahf on every Friday at the hour shown, with the Friday body, and no longer on Thursday. Tapping the
notification opens page 293.

**Why this priority**: This is the whole request. Without it the owner who reads al-Kahf on Friday has to be reminded
a day early.

**Independent Test**: Plan the reminders for a given date with the setting on Friday: only Fridays in the next 14 days,
at the chosen hour, with the Friday body; then on Thursday: only Thursdays, as before. In the Settings screen, tapping
«الجمعة» saves the day and rebuilds the schedule.

**Acceptance Scenarios**:

1. **Given** the al-Kahf reminder is on and the day is Thursday, **When** the reader taps «الجمعة», **Then** the choice
   shows «الجمعة» selected, the day is saved, and the phone's schedule holds al-Kahf notifications on Fridays only.
2. **Given** the day is Friday and the user chose 07:30, **When** the schedule is built for the next 14 days, **Then**
   it holds one al-Kahf notification on each Friday in that period at 07:30, titled «سورة الكهف», with the Friday body,
   and none on any other weekday.
3. **Given** it is Friday at 10:00 and the user chose 21:00, **When** the day is Friday, **Then** today's notification
   is still scheduled (its hour has not passed); at 22:00 it is not, and the next one is in seven days.
4. **Given** the day is Friday, **When** the reader taps the notification, **Then** the reader opens page 293 in
   browse mode, exactly as the Thursday notification does.
5. **Given** the reader taps «الخميس», **When** the schedule is rebuilt, **Then** it holds al-Kahf
   notifications on Thursdays only, with today's body.
6. **Given** the user never chose an hour (the row shows 21:00), **When** the reader taps «الجمعة», **Then** the row
   shows 10:00 at once, the schedule holds the Fridays at 10:00, and tapping «الخميس» shows 21:00 and the Thursdays at
   21:00 again.
7. **Given** the user chose an hour (for example 07:30), **When** the reader switches the day either way, **Then** the
   row keeps 07:30 and the schedule uses it.
8. **Given** the user never chose an hour and Friday is chosen, **When** the reader turns the reminder off and on, **Then**
   the row still shows 10:00 and no hour has been chosen (a later change of day still moves it).

---

### User Story 2 - Nothing changes for someone who never touches it (Priority: P1)

A reader who updates the app, or restores an older backup, and never opens the new choice keeps the reminder as it was:
Thursday at the chosen hour (21:00 unless changed), with today's title and body, one every Thursday in the next 14 days.

**Why this priority**: The reminder already works for the owner; a new setting must not move it.

**Independent Test**: On a database with no day setting, and on a backup file written before this feature, the plan and
the Settings screen are exactly what they were before: Thursday selected, the same notifications, the same switch
texts.

**Acceptance Scenarios**:

1. **Given** no day has ever been saved, **When** the schedule is built, **Then** it is the Thursday schedule of
   feature 001 (same ids, hours, title, body and payload).
2. **Given** an older backup without the day, **When** it is imported, **Then** the import succeeds, the day is
   Thursday and the schedule is rebuilt.
3. **Given** the saved day is a value the app does not know, **When** the app reads it, **Then** it is treated as
   Thursday and nothing fails.

---

### User Story 3 - The choice survives backup and restore (Priority: P2)

The reader exports a backup while the day is Friday, later restores it on a fresh install, and the day is Friday
again, with the schedule rebuilt for Fridays.

**Why this priority**: Constitution IV says backup is by file only; a setting lost on restore would silently move the
reminder to the wrong day.

**Independent Test**: Export with Friday, import into an empty database: the day reads Friday, the plan holds Fridays.
Export with Thursday: the day reads Thursday.

**Acceptance Scenarios**:

1. **Given** the day is Friday, **When** a backup is exported and imported, **Then** the day is Friday afterwards.
2. **Given** the day is Thursday and was never changed, **When** a backup is exported and imported, **Then** the day
   is Thursday afterwards.

---

### User Story 4 - It fits the screen in both looks, at every size (Priority: P2)

The two options are readable and easy to hit in Emerald & Gold and in Night Reader, at the three reading sizes, on a
narrow phone and with a large system font; they never overflow, and a screen reader tells which one is selected.

**Why this priority**: Constitution VI and the look and size rules of features 003 and 004 apply to every control.

**Independent Test**: Pump Settings in both looks at 320 dp wide with a 2x system font: no overflow, both options
visible, each at least 48 px high, contrast at least 4.5:1, the selected one announced as selected.

**Acceptance Scenarios**:

1. **Given** a 320 dp window with a 2x system font, **When** Settings is shown with the reminder on, **Then** both
   options are visible (they may stack) and nothing overflows or is cut off.
2. **Given** either look, **When** the choice is drawn, **Then** the selected option is marked by more than colour
   (a check or an outline, as the look choice does) and every text and mark has the required contrast.
3. **Given** a screen reader, **When** it reaches the options, **Then** each is a button with its label and the
   selected one is announced as selected.

---

### Edge Cases

- The reader changes the day on the day itself: on Thursday at 18:00 with the hour at 21:00, choosing Friday removes
  today's Thursday notification and schedules the Fridays; on Friday at 22:00 choosing Thursday leaves the next
  notification on next Thursday. The rule that skips an hour already passed is the existing one.
- A notification already shown in the notification tray stays there when the day changes; only the waiting ones are
  replaced.
- The reminder is off: the choice is hidden and nothing is scheduled for al-Kahf; the saved day is kept and applies
  when the switch is turned on again.
- Notifications are not allowed by the phone: the permission card shows as today; the choice still works and is saved.
- The hour is changed after the day: both are kept; the plan uses the new hour on the chosen day and the hour is now
  chosen, so it stays when the day changes.
- A backup written before this feature may hold an hour (any earlier change of the switch stored 21:00): it is a chosen
  hour and wins over Friday's default; a backup with no hour leaves the default of the day.
- A wird reminder and an al-Kahf reminder at the same minute: both are scheduled, as today (their ids never clash).
- A backup written by a later version holds a day value this app does not know: it is read as Thursday; nothing is
  rejected for that.
- Leaving Settings by the system back, rotating the phone, or a change of look keeps the saved day and what is shown.
- The Friday and the Thursday notification of the same week never both exist at once: only one day is planned.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST keep one setting for the day of the al-Kahf reminder, with exactly two values, Thursday and
  Friday. A missing value, and any value that is not one of the two, MUST be read as Thursday.
- **FR-002**: Settings MUST show the choice of the day directly under the al-Kahf switch and above the hour row, as two
  options labelled «الخميس» and «الجمعة» (the first named «الخميس (ليلة الجمعة)» for a screen reader), only while the switch is on. The saved option is shown
  selected, with a mark other than colour. Tapping the other option MUST save it at once, without a button.
- **FR-003**: With Thursday chosen, the plan MUST hold exactly what feature 001 FR-036 requires today: one notification
  on every Thursday of the next 14 days at the chosen hour, titled «سورة الكهف», with the body «ليلة الجمعة: لا تنسَ
  قراءة سورة الكهف», skipping a Thursday whose hour has already passed.
- **FR-004**: With Friday chosen, the plan MUST hold one notification on every Friday of the next 14 days at the chosen
  hour, titled «سورة الكهف», with the body «يوم الجمعة: لا تنسَ قراءة سورة الكهف», skipping a Friday whose hour has
  already passed, and MUST hold none on any other weekday.
- **FR-005**: The al-Kahf notifications MUST have ids that are unique for each day of the planned period and never clash
  with a wird's ids, for both days (the id scheme of feature 001 is kept).
- **FR-006**: Tapping an al-Kahf notification of either day MUST open page 293 in browse mode.
- **FR-007**: Choosing a day, like switching the reminder or changing its hour, MUST rebuild the phone's schedule through
  the existing refresh path, replacing the waiting notifications of the old day; no other reminder changes.
- **FR-008**: The title and subtitle of the al-Kahf switch MUST name the chosen day: for Thursday they stay exactly
  «تذكير سورة الكهف ليلة الجمعة» and «كل خميس في الوقت الذي تختاره»; for Friday they are «تذكير سورة الكهف يوم
  الجمعة» and «كل جمعة في الوقت الذي تختاره». The name of the notification channel in the phone's own settings
  MUST NOT name a day.
- **FR-009**: Export MUST write the day with the other settings, and import MUST restore it. A backup written before
  this feature MUST still be accepted and MUST leave the day as Thursday; the file format version does not change.
  After an import the schedule MUST follow the restored day (the existing import already asks for a new schedule).
- **FR-010**: The choice MUST follow the chosen look (Emerald & Gold, Night Reader) with at least 4.5:1 contrast for text
  and 3:1 for marks, each option MUST be at least 48 px high, nothing MUST overflow at 320 dp wide with a 2x system font
  (the options may stack), and a screen reader MUST hear the group as «يوم التذكير», and each option as a button with its
  name and the chosen one as selected.
- **FR-011**: Thursday's default hour (21:00), the horizon (14 days), the permission card, the hour picker, the wird reminders,
  the background refresh, the backup screens and every test of features 001 to 006 MUST be unchanged by this feature
  (the existing tests pass without any edit).
- **FR-012**: The feature MUST work offline, add no package, no permission and no database table, and send nothing off
  the device (Constitution IV, VII).
- **FR-013**: Every new Arabic string MUST live in one file, marked as a proposal until the owner confirms it
  (Constitution VI); the owner confirmed all of them on 2026-11-21.
- **FR-014**: While the user has not chosen an hour, the hour of the reminder MUST be the default of the chosen day:
  21:00 for Thursday and 10:00 for Friday. The hour row, the plan and the scheduler MUST use that same value, the row
  MUST change at once when the day changes, and a default MUST NOT be stored. An hour chosen in the picker (or restored
  from a backup) MUST win for both days; turning the reminder off and on and choosing a day MUST NOT choose an hour.

### Key Entities *(include if feature involves data)*

- **Al-Kahf day**: the one new setting, with two values (Thursday, Friday), stored with the other settings and carried by
  backups. Absent means Thursday.
- **Al-Kahf hour** (existing setting, new reading rule): stored only when the user chose it; otherwise the default of the
  chosen day (21:00 Thursday, 10:00 Friday).
- **Al-Kahf notification** (existing): a title, a body, the hour, the payload for page 293 and an id. This feature adds
  a second body (Friday) and chooses which weekday is planned; it adds no field to the plan.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For every date in a test year and each of the two days, the plan holds al-Kahf notifications only on the
  chosen weekday, at most one per date, none in the past, none beyond 14 days, and their ids are all different (both
  days, 100% of the tested dates).
- **SC-002**: With no saved day, and with an older backup restored, the plan is identical to the plan before this feature
  (same ids, times, texts and payload) in 100% of the tested cases, and every existing test passes without edit.
- **SC-003**: After a tap on «الجمعة» the saved day is Friday, and the scheduler, running on the same database with the
  notification service faked, replaces the phone's schedule with Fridays only within its usual short pause.
- **SC-004**: Export then import keeps the day in 100% of the tested cases (Friday, Thursday, never set), and a backup
  without the day imports.
- **SC-005**: In both looks, at 320 dp wide with a 2x system font and at the three reading sizes, 0 overflows, each
  option at least 48 px high, contrast met (4 of 4 text and mark checks per look).
- **SC-006**: The owner, trying it on the phone with the system clock moved to a Thursday and to a Friday (or by
  waiting a notification), receives the reminder on the day chosen with the right body, and tapping it opens page 293
  (owner's own check, Constitution IX).
- **SC-007**: With no hour chosen, the shown hour and the planned hour are 10:00 with Friday and 21:00 with Thursday in
  100% of the tested cases (the repository, the scheduler and the Settings screen), nothing is stored for them, and with
  a chosen hour both days use it.

## Assumptions

- "Thursday" and "Friday" are the phone's local weekdays, as the existing planning already is; the app does not
  compute the Islamic day from sunset.
- A chosen hour is shared by both days; only the default differs (FR-014). The owner asked for an earlier default for
  Friday because 21:00 on Friday is already after sunset, the night of Saturday.
- The existing 14-day horizon and the refresh on start, resume, change and the daily background job are enough for the
  new day; no change to them.
- The two-option control is drawn in the same style as the look choice of feature 004 (two cards, stacked when narrow),
  reusing its colours; a plain two-segment control is the alternative if it reads better on the phone.
- The two cards are short («الخميس», «الجمعة») and have no visible heading because the Settings screen is tight: its own
  existing tests need the «التطبيق» section still on screen at 412 x 915 with the permission card shown, which leaves
  room for one 48 px row. The fuller wording is for the screen reader. The owner confirmed the short labels on
  2026-11-21.
- Arabic strings, confirmed by the owner on 2026-11-21 (Constitution VI): option labels shown
  «الخميس» and «الجمعة», the first named «الخميس (ليلة الجمعة)» for a screen reader; the name of the group «يوم
  التذكير» (screen reader only); the Friday body «يوم الجمعة: لا تنسَ قراءة سورة الكهف»; the Friday switch title «تذكير سورة الكهف يوم الجمعة» and subtitle «كل جمعة في الوقت الذي تختاره»; the
  channel name «تذكير سورة الكهف». The Thursday strings are today's.
- The phone check follows Constitution IX; the owner is asked before any install or input on the phone.
