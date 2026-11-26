// The prayer notifications to keep scheduled (feature 014, US2, FR-015..FR-021, data-model.md): the next 48 hours of
// prayers and their reminders, earliest first. The daily background refresh and every settings change extend it.
import '../reminders/reminder_planner.dart';
import 'prayer_calc.dart';
import 'prayer_settings.dart';
import 'prayer_strings.dart';

const Duration kPrayerHorizon = Duration(hours: 48);

/// Ids: `kPrayerIdBase + dayIndex * 10 + slot`, dayIndex 0..2 from today's local date at the place, slot 0..4 for the
/// prayer (fajr, dhuhr, asr, maghrib, isha) and 5..9 for the reminder before it.
List<PlannedReminder> planPrayers({
  required PrayerSettings s,
  required DateTime now,
  required bool exact,
}) {
  final place = s.place;
  if (!s.enabled || place == null) return const [];
  final nowUtc = now.toUtc();
  final end = nowUtc.add(kPrayerHorizon);
  final today = PrayerCalc.localDate(nowUtc, place);
  final out = <PlannedReminder>[];
  for (var dayIndex = 0; dayIndex < 3; dayIndex++) {
    final times = PrayerCalc.day(today.add(Duration(days: dayIndex)), place, s);
    for (var slot = 0; slot < kFivePrayers.length; slot++) {
      final prayer = kFivePrayers[slot];
      final name = kPrayerNames[prayer.index];
      final at = times.utc[prayer]!;
      final n = s.notify[slot];
      if (n.mode != NotifyMode.off && at.isAfter(nowUtc) && !at.isAfter(end)) {
        out.add(
          PlannedReminder(
            id: kPrayerIdBase + dayIndex * 10 + slot,
            at: at.toLocal(),
            title: atPrayer(name),
            body: place.name,
            payload: 'prayer',
            kind: n.mode == NotifyMode.silent
                ? ReminderKind.prayerSilent
                : ReminderKind.prayerSound,
            exact: exact,
          ),
        );
      }
      if (n.before > 0) {
        final early = at.subtract(Duration(minutes: n.before));
        if (early.isAfter(nowUtc) && !early.isAfter(end)) {
          out.add(
            PlannedReminder(
              id: kPrayerIdBase + dayIndex * 10 + 5 + slot,
              at: early.toLocal(),
              title: beforePrayer(name, n.before),
              body: place.name,
              payload: 'prayer',
              kind: ReminderKind.prayerBefore,
              exact: exact,
            ),
          );
        }
      }
    }
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out;
}
