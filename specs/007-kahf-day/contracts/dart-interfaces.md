# Dart interfaces: Al-Kahf Reminder Day

The signatures the tests are written against. Nothing outside these changes.

## `lib/reminders/kahf_day.dart` (new, no imports)

```dart
enum KahfDay {
  thursday('thursday', DateTime.thursday, 21 * 60),
  friday('friday', DateTime.friday, 10 * 60);

  const KahfDay(this.storageValue, this.weekday, this.defaultMinutes);
  final String storageValue;   // 'thursday' | 'friday'
  final int weekday;           // DateTime.thursday | DateTime.friday
  final int defaultMinutes;    // the hour while the user has not chosen one: 1260 | 600

  /// The value stored as [raw]; Thursday for null and for any text that is not a storage value.
  static KahfDay fromStorage(String? raw);
}
```

## `lib/reminders/kahf_strings.dart` (new)

Every constant is `const String`; the doc comment records that the owner
confirmed them on 2026-11-21.

| Constant | Text | Status |
|---|---|---|
| `kKahfBodyFriday` | يوم الجمعة: لا تنسَ قراءة سورة الكهف | confirmed 2026-11-21 |
| `kKahfDayHeading` | يوم التذكير | confirmed (screen reader only) |
| `kKahfDayThursdayLabel` | الخميس | confirmed (shown) |
| `kKahfDayThursdayName` | الخميس (ليلة الجمعة) | confirmed (screen reader) |
| `kKahfDayFridayLabel` | الجمعة | confirmed |
| `kKahfSwitchTitleFriday` | تذكير سورة الكهف يوم الجمعة | confirmed |
| `kKahfSwitchSubtitleFriday` | كل جمعة في الوقت الذي تختاره | confirmed |
| `kKahfChannelName` | تذكير سورة الكهف | confirmed |
| `kKahfSwitchTitleThursday` | تذكير سورة الكهف ليلة الجمعة | today's (not a proposal) |
| `kKahfSwitchSubtitleThursday` | كل خميس في الوقت الذي تختاره | today's (not a proposal) |

`kKahfTitle` («سورة الكهف») and `kKahfBody` (Thursday's body) stay in `reminder_planner.dart`.

## `lib/reminders/reminder_planner.dart`

```dart
List<PlannedReminder> planReminders({
  required List<Wird> wirds,
  required Map<int, bool> doneToday,
  Map<int, ({int start, int end})> todayPortions = const {},
  required bool kahfEnabled,
  required int kahfMinutes,
  KahfDay kahfDay = KahfDay.thursday,   // NEW, optional
  required int kahfPage,
  required DateTime now,
  int horizonDays = 14,
});
```

Behaviour: the al-Kahf notifications are on the days whose `weekday == kahfDay.weekday`; body `kKahfBody` for Thursday,
`kKahfBodyFriday` for Friday; everything else as before.

## `lib/wirds/wird_repository.dart`

```dart
class ReminderInputs {
  const ReminderInputs({
    required this.wirds, required this.doneToday, required this.todayPortions,
    required this.kahfEnabled, required this.kahfMinutes,
    this.kahfDay = KahfDay.thursday,     // NEW, optional
  });
  final KahfDay kahfDay;
}

// in WirdRepository (setKahf is unchanged and still stores both the switch and the hour)
Future<KahfDay> kahfDay();               // missing or unknown stored text -> thursday
Future<void> setKahfDay(KahfDay day);    // writes settings key 'kahfDay'
Future<int> kahfMinutes();               // the chosen hour, else kahfDay().defaultMinutes (never stored)
Future<bool> kahfMinutesChosen();        // whether kahfMinutes holds an hour the user chose
Future<void> setKahfEnabled(bool on);    // the switch alone: stores no hour
Future<void> setKahfMinutes(int m);      // the picker: the hour is now chosen
```

`reminderInputs(now)` fills `kahfDay` and a `kahfMinutes` computed from that same day; `watchReminderInputs()` already
emits on a `settings` change. The Settings screen uses `setKahfEnabled` for the switch and `setKahfMinutes` for the
picker (so a switch tap no longer chooses an hour) and, when the day changes with no hour chosen, shows the new day's
`defaultMinutes` at once.

## `lib/reminders/reminder_scheduler.dart`

`buildReminderPlan` passes `kahfDay: inputs.kahfDay` to `planReminders`.

## `lib/reminders/reminder_service.dart`

`LocalNotificationService.reschedule` names the al-Kahf channel `kKahfChannelName` (the id `kahf_reminders` is unchanged).

## `lib/backup/backup_service.dart`

No change.
