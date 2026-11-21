# Research: Al-Kahf Reminder Day

Decisions made before design. Each has the decision, the reason, and what was set aside.

## D1. The day is an enum with a stored text value

**Decision**: `enum KahfDay { thursday, friday }` in `lib/reminders/kahf_day.dart` with no imports. Each value carries
its `storageValue` (`'thursday'`, `'friday'`) and its `weekday` (`DateTime.thursday`, `DateTime.friday`).
`KahfDay.fromStorage(String?)` returns the matching value and `thursday` for `null` and for any other text.

**Reason**: the planner, the repository and the Settings screen all need it, and the repository should not import the planner
(which imports the database file); a file with no imports can be imported by all three without a cycle. A text value in the
settings table is how every other setting is stored, and a text lets an unknown value from a newer backup be read
safely (FR-001).

**Alternatives**: an integer weekday (a stored `4` or `5` is less readable in a backup and any other number needs
its own guard); a boolean `kahfOnFriday` (cannot grow, and the owner already named the key `kahfDay`).

## D2. The planner gets one optional parameter

**Decision**: `planReminders(..., KahfDay kahfDay = KahfDay.thursday, ...)`. The loop that today tests
`day.weekday != DateTime.thursday` tests `day.weekday != kahfDay.weekday`; the body is `kKahfBody` for Thursday and
`kKahfBodyFriday` for Friday. Title, payload, hour rule, 14-day horizon and the id `kKahfIdBase + dayOffset` do not
change.

**Reason**: every existing call and test passes no `kahfDay` and gets today's behaviour (FR-003, FR-011, SC-002). The id
is `900000 + offset` where the offset is the day's distance from today, so it is unique per planned day for either
weekday (FR-005); the schedule is always replaced as a whole (`cancelAllPendingNotifications` then schedule), so an
id used by a Thursday plan yesterday and by a Friday plan today can never be both pending.

**Alternatives**: a second id base for Friday (no benefit, the plan holds one weekday only; it would also change
`isKahf`, which tests `id >= kKahfIdBase`); a list of days (out of scope: one day only, spec Clarifications).

## D3. A chosen hour is shared; only the default depends on the day (owner, 2026-11-21)

**Decision**: `kahfMinutes` stays one setting for both days and is written only when the user chooses an hour (the
picker, `setKahfMinutes`) or a backup restores one. While it is absent the hour in use is `KahfDay.defaultMinutes` of
the chosen day: 21:00 for Thursday, 10:00 for Friday. The repository's `kahfMinutes()` is that rule, `reminderInputs`
computes it from the day it read in the same call, so the planner and the scheduler use the very value the screen
shows. A default is never stored, so it follows a later change of day; a chosen hour wins for both days.

**Reason**: the owner asked for an earlier default on Friday (21:00 on Friday is after sunset) and said an hour the user
set must always win. Storing the default would turn it into a chosen hour the first time anything was saved.

**Consequence in Settings**: the switch used to save the switch and the shown hour together (`setKahf`), which would
have stored the default as a chosen hour on any tap of the switch. The screen now saves the switch alone
(`setKahfEnabled`) and the hour alone (`setKahfMinutes`); `setKahf` stays for the existing callers and tests. When the
day changes with no hour chosen the shown hour changes at once to the new default.

**Backups**: an older backup that holds `kahfMinutes` (any earlier tap of the switch stored 21:00) restores a chosen
hour, which wins over Friday's default; a backup without it leaves the default of the day.

**Alternatives**: one default for both days (the owner chose against it); storing the default with the day (loses the
"never chosen" fact); a separate hour per day (twice the settings, not requested).

## D4. No new refresh path

**Decision**: `setKahfDay` writes one row to `settings`. `WirdRepository.watchReminderInputs()` already reads the
`settings` table, so the scheduler's listener replans after its 400 ms pause and replaces the schedule through
`ReminderService.reschedule`, exactly as for the switch and the hour (FR-007). `reminderInputs` reads the day and
`buildReminderPlan` passes it to the planner.

**Reason**: it is the same path that the existing switch and hour use, and it is the path that `watchReminderInputs`'s
doc comment describes; nothing is added to the app, `main.dart` or the background job, and the daily background
refresh builds its plan with `buildReminderPlan` too, so it follows the day.

**Alternatives**: calling `scheduler.refresh()` from the Settings screen after the tap (a second path that can
disagree with the first; the screen's `setKahf` does not do it either).

## D5. The repository: new accessors, `setKahf` unchanged

**Decision**: `Future<KahfDay> kahfDay()` reads `kahfDay` through `KahfDay.fromStorage`; `Future<void>
setKahfDay(KahfDay)` writes `day.storageValue`. `setKahf({enabled, minutes})` is unchanged. `ReminderInputs` gets
`kahfDay` as an optional named parameter defaulting to Thursday, filled by `reminderInputs`.

**Reason**: existing callers and tests of `setKahf` and `ReminderInputs` compile and behave as before (FR-011). The
read of an unknown value is the same function as the read of a missing one (FR-001).

**Alternatives**: `setKahf(..., day: ...)` (changes the call sites and forces the screen to write three rows for one
tap); storing the weekday number.

## D6. The Settings control: two compact cards, like the look choice, with no visible heading

**Decision**: a private widget in `settings_screen.dart`, shown only while the switch is on, between the switch and the
hour row: two option cards in a `Row` of equal width (stacked in a `Column` when the width available to the choice (the
window width minus 18 px of list padding on each side) is under 340 dp or the system text scale makes 15 px text
larger than 17 px; the look choice of feature 004 uses the same idea). Each card is a button of `minHeight` 48 showing
a short label («الخميس», «الجمعة») in 15 px semi-bold `look.text`, with an outline of `look.accent` 2 px plus a check
icon when selected (so selection is not colour alone) and `look.controlBorder` 1 px otherwise, and a `Semantics(button:
true, selected: ..., label: <name>)` whose name for Thursday is the fuller «الخميس (ليلة الجمعة)». The group is a
`Semantics(container: true, label: «يوم التذكير»)`, not a visible heading. A tap saves the day at once. Keys:
`kahf-day` (the whole choice), `kahf-day-thursday`, `kahf-day-friday`.

**Reason**: the look choice already solved the same problem (two options, both looks, contrast, narrow phone, large
font); reusing its shape keeps Settings consistent. The size is forced by an existing test: `test/settings/
settings_night_test.dart` (Night, permission card shown, 412 x 915) reads the colour of the «التطبيق» label, which
sits 54 px inside the visible area of the list before this feature, and the rule is that no existing test is edited.
A 48 px single-line row fits (6 px to spare in that test's font); a 56 px card, a visible heading or a label that wraps
to two lines does not. So the visible labels are the short ones and the explanation «ليلة الجمعة» stays in the switch
title for Thursday and in the screen reader's name.

**Alternatives**: the longer visible label «الخميس (ليلة الجمعة)» with a visible heading «يوم التذكير» (needs 100+ px,
breaks that test); `SegmentedButton` (clips the long label); a dropdown or dialog row (two taps, and the choice is
hidden); two radio list tiles (112 px); a switch "Friday instead of Thursday" (not self-explanatory).

## D7. Texts of the switch follow the day

**Decision**: Thursday keeps the strings in the existing tests («تذكير سورة الكهف ليلة الجمعة», «كل خميس في الوقت الذي
تختاره»); Friday uses «تذكير سورة الكهف يوم الجمعة» and «كل جمعة في الوقت الذي تختاره». The Android channel name
(visible only in the phone's system settings) becomes the neutral «تذكير سورة الكهف».

**Reason**: «ليلة الجمعة» and «كل خميس» would be wrong once Friday is chosen (FR-008); the channel keeps its id
`kahf_reminders`, so existing installs keep their channel and its sound settings; only the visible name is updated
when the plugin creates the channel again.

**Alternatives**: leave the texts alone (wrong when Friday is chosen); a generic title for both days (would change the
Thursday strings the existing tests find).

## D8. Strings in one place, and the open questions for the owner

**Decision**: `lib/reminders/kahf_strings.dart` holds every new string and today's two switch texts, with a doc
comment that says the new ones were confirmed by the owner on 2026-11-21 (Constitution VI; they were proposals before). `kKahfTitle` and `kKahfBody`
stay in `reminder_planner.dart` where the existing tests import them from.

**Owner's answers, 2026-11-21 (in chat)**: (1) Friday's default hour is 10:00 in the morning, Thursday's stays 21:00, an
hour the user set always wins (decision D3); (2) one day only, as built; (3) every string of `kahf_strings.dart` is
confirmed as written (question 3 and 4 below: the short labels and the Friday switch texts included). Question 3's
alternative (a visible long label and heading) is therefore closed.

**Questions that were put to the owner** (Egyptian Arabic):

1. «الجمعة الساعة 9 بالليل بتبقى بعد المغرب يعني ليلة السبت. تحب الساعة تفضل واحدة للخميس والجمعة زي ما هي، ولا لما
   تختار الجمعة تبقى الساعة الافتراضية أبكر (مثلاً 10 الصبح)؟»
2. «نص تنبيه الجمعة المقترح: "يوم الجمعة: لا تنسَ قراءة سورة الكهف" — تمام ولا تغيّره؟»
3. «اسمَي الاختيارين "الخميس" و"الجمعة" (وقارئ الشاشة يقرأ الأول "الخميس (ليلة الجمعة)") — تمام؟ ولو عايز الاسم الطويل
   "الخميس (ليلة الجمعة)" ظاهر مع عنوان "يوم التذكير"، ده محتاج مساحة أكتر في شاشة الإعدادات.»
4. «لما تختار الجمعة، عنوان المفتاح بيبقى "تذكير سورة الكهف يوم الجمعة" وتحته "كل جمعة في الوقت الذي تختاره" — تمام؟»
5. «عايز اختيار واحد بس (خميس أو جمعة)، ولا عايز تنبيه في اليومين مع بعض؟ دلوقتي بنعمل اختيار واحد.»

**Reason**: the answers change only text and one default, never the design.

## D9. Coordination in the shared tree

**Decision**: edits to `wird_repository.dart` (the Al-Kahf block only; the `readSetting`/`writeSetting` added by another
session stay) and `settings_screen.dart` are small and additive; before each, `git status` and `git log -- <file>`
are checked and only the feature's own paths are committed with `git commit -m ... -- <paths>`. Nothing in
`lib/mushaf/`, `lib/main.dart`, `lib/app.dart`, `android/`, `pubspec.yaml`, `docs/` or an existing test is edited.
`.specify/feature.json` is never written.

## D10. Backup needs no code

**Decision**: `BackupService` exports every row of `settings` and imports every `settings` string, so `kahfDay` is
carried without a change; a backup without it leaves the key unset (read as Thursday, D1) and an unknown value is
read as Thursday. The import path already asks the scheduler to refresh (`refresh(force: true)`), which replans with
the restored day. New tests pin the four cases (FR-009).

**Reason**: nothing in the parser validates setting keys, only that every value is a string; adding validation would
reject a backup from a later version for a harmless reason.

**Alternatives**: validating `kahfDay` on import (rejects instead of defaulting; the spec says default).
