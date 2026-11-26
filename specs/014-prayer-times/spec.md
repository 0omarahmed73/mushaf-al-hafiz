# Feature Specification: Prayer times (مواقيت الصلاة)

**Feature Branch**: none (shared tree, directory `specs/014-prayer-times`)

**Created**: 2026-11-26

**Status**: Draft

**Input**: The owner's request of 2026-11-25: «اضافة مواقيت الصلاة والأذان مع القدرة على التحكم الكامل فيهم». After the
study `docs/research/2026-11-25-prayer-times-study.md` he chose scope B: the prayer times plus one notification per prayer
with a short sound, and no full adhan recording. Constitution 2.2.0, Principle III, exception 2.0.0, sets the bounds.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See today's prayer times for my city (Priority: P1)

The reader turns prayer times on, lets the phone find the place (or picks a city from a list in the app), and sees
today's Fajr, sunrise, Dhuhr, Asr, Maghrib and Isha, with the next prayer marked and a countdown to it. Nothing leaves the
phone and no network is used.

**Why this priority**: The times are the base of everything else; with only this story the reader already has a useful,
private, ad-free timetable.

**Independent Test**: Turn the feature on, choose «القاهرة», compare the six times with the reference times for that day
and city, and see the countdown reach the next prayer.

**Acceptance Scenarios**:

1. **Given** prayer times have never been turned on, **When** the reader opens the app, **Then** the Mushaf opens as it
   always did and nothing about prayer times appears in the reader or asks for anything.
2. **Given** the prayer-times screen is opened for the first time, **When** the reader turns the feature on and taps
   «حدد موقعي», **Then** the phone asks for the approximate location only, and the times of that place appear.
2a. **Given** the reader refuses the location, **Then** the city list opens, searchable in Arabic, and the times of the
   chosen city appear; the app never asks for the location again unless the reader taps the button.
3. **Given** the city is Cairo, **When** the screen shows a day, **Then** each of the six times is within one minute of
   the reference times of the Egyptian General Authority of Survey for that date.
4. **Given** the times are shown, **When** a prayer time passes, **Then** the next prayer and its countdown move to the
   following prayer without the reader doing anything, and after Isha the next one is the next day's Fajr.

---

### User Story 2 - A notification at each prayer (Priority: P1)

For each prayer the reader chooses whether to get a notification at its time. The notification says which prayer it is
and plays a short sound (or none, if the reader chose silent for that prayer). It comes with the app closed and the
screen locked.

**Why this priority**: The owner asked for the adhan with control; scope B is the notification, so without it the
feature is not what he chose.

**Independent Test**: Set a city, turn notifications on for the next prayer, close the app, lock the phone, and wait for
the time on a real Samsung phone.

**Acceptance Scenarios**:

1. **Given** notifications are on for Dhuhr, **When** Dhuhr comes with the app closed and the screen locked, **Then** a
   notification «حان الآن موعد صلاة الظهر» (proposal) appears with the short sound, within one minute when exact timing
   was allowed.
2. **Given** the reader refused the exact-timing permission, **When** notifications are on, **Then** they still come in
   inexact mode, and the screen says once, plainly, that they may come a few minutes late, with a way to allow exact
   timing in the phone's settings.
3. **Given** Fajr is set to silent, **When** Fajr comes, **Then** the notification appears with no sound.
4. **Given** a reminder of 10 minutes is set for Asr, **When** it is 10 minutes before Asr, **Then** a reminder
   notification appears, and the Asr notification still comes at Asr.
5. **Given** the phone restarts, or its time zone or the clock changes (daylight saving), **When** the next prayer comes,
   **Then** its notification comes at the right new time without the reader opening the app.
6. **Given** the reader turns prayer times off, **Then** no prayer notification or reminder comes after that.

---

### User Story 3 - Adjust the calculation to match my mosque (Priority: P2)

The reader can change the calculation method (the default follows the city's country), the Asr rule (standard or
Hanafi), and add or subtract minutes for each prayer, so the times match the local mosque.

**Why this priority**: Wrong-looking times are the second biggest complaint about other apps; this is the control the
owner asked for.

**Independent Test**: Change the method and the Asr rule and set +2 minutes on Maghrib; the shown times and the next
notification change accordingly.

**Acceptance Scenarios**:

1. **Given** a city in Egypt, **Then** the default method is the Egyptian General Authority of Survey and the Asr rule is
   standard; **given** a city in Saudi Arabia, the default is Umm al-Qura.
2. **Given** +2 minutes on Maghrib, **Then** the shown Maghrib and its notification are both 2 minutes later.
3. **Given** the settings change, **Then** every scheduled notification is replaced by the new times at once.

---

### User Story 4 - The month's timetable (Priority: P3)

The reader opens a table of the current month (and can move to the next and previous months) with the six times of each
day, today marked.

**Why this priority**: Useful for planning, but not needed for the daily use.

**Independent Test**: Open the table, see 28 to 31 rows for the month, with today marked; move one month forward.

**Acceptance Scenarios**:

1. **Given** the month table, **Then** each row shows the date (Gregorian, and Hijri if shown elsewhere) and the six times
   with the same rules as the day view.

---

### Edge Cases

- The city has no Isha or Fajr by the usual angle in summer (high latitude): a high-latitude rule is applied and the
  screen says so.
- The day the clocks change: the times of that day are right in the new local time, and no notification comes twice or
  is lost.
- The reader travels: the place stays the one found or chosen until the reader taps «حدد موقعي» again; if the phone's
  time zone differs from the place's, the screen says so in one line and offers to find the place again.
- Notifications are turned off for the whole app in the phone's settings: the screen says so and offers to open the
  phone's settings; nothing breaks.
- The phone's battery manager stops the app (Samsung and others): the screen explains, once, how to allow the app to run
  in the background, and a «جرّب التنبيه» (proposal) button sends a test notification at once.
- A prayer notification and a wird reminder fall at the same minute: both come, as two notifications.
- A restore from a backup made before this feature: prayer settings stay as they are (off if never set).
- The reader opens the app days later: the screen shows today, not the last day it was opened.

## Requirements *(mandatory)*

### Functional Requirements

**Turning on and the place in the app**

- **FR-001**: Prayer times MUST be off when the app is installed or updated. While off, the only trace is the bottom-bar
  item of FR-002; no time is shown and no notification is scheduled.
- **FR-002**: Prayer times MUST be a separate screen, opened from the bottom bar's item that today reads «استماع» with
  «قريبًا» (a placeholder that does nothing): that item becomes «مواقيت الصلاة» (proposal) and opens the screen, which
  turns the feature on from inside it. The Mushaf stays the first screen, and nothing is added to the page itself.
  (Owner, 2026-11-26: «ممكن نشيل menu الصوتيات ونحط مكانها مواقيت الصلاة».)
- **FR-003**: Turning the feature on MUST start with finding the place; until there is a place no time is shown.

**Place and calculation**

- **FR-004**: The place MUST come first from the phone's location, through a «حدد موقعي» (proposal) button. Only the
  approximate (coarse) location permission is asked, only when the reader taps that button, never at start and never in
  the background. The place is found once and kept; it changes only when the reader taps the button again. (Owner,
  2026-11-26: "GPS, no internet"; constitution 3.0.0.)
- **FR-004a**: If the reader refuses the permission, location is off, or no place is found within 30 seconds, the screen
  MUST offer a city list bundled in the app: the large cities of the Arab and Muslim-majority countries, searchable by
  Arabic and English name, tolerant of hamza and taa marbuta spelling like the surah search of feature 011. (Owner:
  «يختار مدينته من قايمة».) The reader can also open the list at any time instead of the location.
- **FR-004b**: The screen MUST show the place it uses: the city's name when chosen from the list, or the nearest city of
  the bundled list with «تقريبًا» (proposal) when found by location.
- **FR-005**: The coordinates MUST be kept on the phone only and used for nothing but prayer times. The app MUST NOT use
  the network for prayer times and MUST NOT ask for the precise or background location.
- **FR-006**: All times MUST be calculated on the phone from the place's coordinates, the date, the time zone and the
  chosen settings. The time zone is the city's for a city from the list, and the phone's for a place found by location.
- **FR-007**: The calculation method MUST default by the place's country (the nearest listed city's country for a place found by location) (Egypt: the Egyptian General Authority of
  Survey; Saudi Arabia: Umm al-Qura; others as the plan records) and MUST be changeable from a list of the common
  methods, each named in Arabic.
- **FR-008**: The Asr rule MUST be choosable: standard (the default) or Hanafi.
- **FR-009**: Each of the six times MUST accept a whole-minute offset from −30 to +30, default 0.
- **FR-010**: In places where Fajr or Isha cannot be found by the usual angle, a high-latitude rule MUST be applied and
  the screen MUST say so in one line.

**The screen**

- **FR-011**: The day view MUST show the date (Gregorian and Hijri), the city, and the six times (Fajr, sunrise, Dhuhr,
  Asr, Maghrib, Isha), with the next prayer marked and a countdown to it that moves on by itself.
- **FR-012**: The month view MUST show every day of a month with the six times, today marked, and move between months.
- **FR-013**: Times MUST be shown in the city's local time, in the digits the app already uses for times, 12-hour with
  «ص»/«م» (proposal).
- **FR-014**: The screen MUST follow the current look (Emerald & Gold, Night Reader), be right to left, have 48 dp touch
  targets, and show no overflow at 320 dp wide with a 2x system font; text contrast at least 4.5:1.

**Notifications**

- **FR-015**: For each of the five prayers (not sunrise) the reader MUST be able to choose: no notification, a
  notification with sound, or a silent notification. Default for all five when the feature is first turned on: a
  notification with sound.
- **FR-016**: The sound MUST be a short takbir clip bundled in the app (owner, 2026-11-26: «تكبيرة قصيرة جوه
  التطبيق»), under 10 seconds, never a full adhan. The recording needs a named source whose licence allows bundling,
  or the owner's own recording; until one is found, the feature cannot be called done (FR-026).
- **FR-017**: For each prayer the reader MAY set a reminder before it: off (default), 5, 10, 15, 20 or 30 minutes.
- **FR-018**: Notifications MUST come at the prayer's time within one minute when the phone allows exact timing; the
  only new permission MAY be exact timing (alarms). If it is refused or withdrawn, notifications MUST still be
  scheduled in inexact mode, and the screen MUST say they may come a few minutes late and offer the phone's setting.
- **FR-019**: Notifications MUST come with the app closed and the screen locked, MUST survive a restart of the phone,
  and MUST follow a change of time zone, date or clock, including daylight saving.
- **FR-020**: Changing the city, a method, a rule, an offset or a notification choice MUST replace the scheduled
  notifications at once; turning the feature off MUST cancel all of them.
- **FR-021**: The app MUST keep at least the next 24 hours of prayer notifications scheduled at all times it is allowed
  to run, so that a day without opening the app still gets its notifications.
- **FR-022**: Tapping a prayer notification MUST open the prayer-times screen.
- **FR-023**: The screen MUST offer a «جرّب التنبيه» (proposal) button that sends one test notification with the chosen
  sound at once, and a short guide for phones that stop apps in the background.
- **FR-024**: Prayer notifications MUST use their own notification category, separate from the wird reminders, so the
  reader can control them apart in the phone's settings; wird reminders MUST behave exactly as before.

**Data, credits, privacy**

- **FR-025**: The prayer settings (on/off, city, method, Asr rule, offsets, notification choices, reminders) MUST be kept
  on the phone, and MUST be part of the backup file; a backup from before this feature MUST still restore.
- **FR-026**: The calculation library, the city list and the takbir recording MUST each have a named source and
  licence in `docs/research/licenses.md` and a credit in About.
- **FR-027**: The privacy policy MUST name the approximate location (used on the phone for prayer times only, never sent)
  and the exact-alarm permission before the feature ships; Play's Data safety answer stays "no data collected" because
  nothing leaves the phone, and is checked again at release.
- **FR-028**: Every Arabic string of the feature is a proposal until the owner confirms it (Principle VI).

### Key Entities

- **Place**: latitude, longitude, time zone, the name shown, and how it was found (location or list). Kept on the phone.
- **City**: Arabic name, English name, country, latitude, longitude, time zone. Read-only, bundled (the fallback list).
- **Prayer settings**: on/off, chosen city, method, Asr rule, six offsets, and for each of the five prayers a
  notification choice (none / sound / silent) and a reminder (off or minutes).
- **Day times**: the six times of one date for the chosen city and settings; derived, never stored.
- **Scheduled notification**: one prayer or reminder at one moment; replaced whenever the settings or the clock change.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For Cairo, Alexandria and Aswan on 12 dates spread over a year, every shown time is within 1 minute of the
  Egyptian General Authority of Survey's published times (or of a second reference the plan names).
- **SC-002**: From the bottom bar, a reader who has never used the feature sees their place's times in under 30 seconds,
  by location or by the list.
- **SC-003**: On the owner's Samsung phone, with the app closed and the screen locked, 5 of 5 prayer notifications in a
  day arrive within 1 minute with exact timing allowed, and within 15 minutes with it refused.
- **SC-004**: After a phone restart and after a time-zone change, the next notification arrives at the right time
  without opening the app.
- **SC-005**: With the feature off, the app's first screen, start time and the reader's page layout are unchanged
  (existing tests stay green), and no notification is scheduled.
- **SC-006**: The screen has no overflow at 320 dp wide with a 2x system font, in both looks.
- **SC-007**: The app still does not request the Internet, precise location or background location permission; the
  only permissions added are approximate location (asked on the reader's tap) and exact alarms.

## Assumptions

- Calculation uses `adhan_dart` 2.0.1 (MIT, pure Dart, offline), as the study found; the plan confirms the licence.
- Hijri date: the arithmetic (Umm al-Qura style) date, which may differ by a day from a sighted month; no adjustment in
  this feature unless the plan finds it cheap. [Assumption; the owner may ask for a ±1 day setting later.]
- A city from the list fixes the time zone; a place found by location uses the phone's time zone at the moment it was found.
- Wird reminders (feature 001) stay inexact and unchanged.
- The full adhan, qibla, GPS, home-screen widgets, a prayer log, qada, adhkar and silencing the phone are out of scope
  (constitution 2.2.0, Principle III).
- Google Play: `USE_EXACT_ALARM` is reserved by Play for alarm and calendar apps, so the app uses
  `SCHEDULE_EXACT_ALARM`, which the reader grants in the phone's settings; the plan checks Play's current rule.
