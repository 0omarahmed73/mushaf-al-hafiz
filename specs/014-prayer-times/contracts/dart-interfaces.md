# Dart interfaces (014)

These are signatures and behaviour only; the bodies are the implementation's job. Every interface has its tests first.

```dart
// lib/prayer/prayer_calc.dart
enum Prayer { fajr, sunrise, dhuhr, asr, maghrib, isha }
class DayTimes { final DateTime date; final Map<Prayer, DateTime> utc; final bool highLatitude; }
class PrayerCalc {
  /// The six times of [date] (a local date of [place.zone]) as UTC instants, with offsets applied.
  static DayTimes day(DateTime date, Place place, PrayerSettings s);
  /// The method `auto` resolves to: EG→egyptian, SA→ummAlQura, AE→dubai, KW→kuwait, QA→qatar, MA→morocco,
  /// TR→turkiye, PK/IN/BD/AF→karachi, US/CA→northAmerica, else muslimWorldLeague.
  static CalcMethod methodFor(String countryCode);
  /// The next prayer after [now] (sunrise excluded), across midnight to tomorrow's Fajr.
  static (Prayer, DateTime) next(DateTime nowUtc, Place place, PrayerSettings s);
}

// lib/prayer/hijri.dart
class HijriDate { final int year, month, day; static HijriDate fromGregorian(DateTime d); String format(); }

// lib/prayer/cities.dart
class City { final String ar, en, cc, tz; final double lat, lon; }
class CityIndex {
  static Future<CityIndex> load(AssetBundle b);
  /// Normalised Arabic or English match on the name's start or any word's start; empty query → all, largest first.
  List<City> search(String query, {int limit = 50});
  City nearest(double lat, double lon);
}

// lib/prayer/location_port.dart
enum LocationAsk { granted, denied, deniedForever }
abstract class LocationPort {
  Future<LocationAsk> request();             // asks ACCESS_COARSE_LOCATION only
  Future<(double, double)?> current();      // one reading or null after 30 s / no provider
  Future<void> openAppSettings();
}

// lib/prayer/prayer_settings.dart
class PrayerSettings { /* fields of data-model.md */ 
  static PrayerSettings read(Map<String, String> settingsTable);
  Map<String, String> toEntries();
}

// lib/prayer/prayer_planner.dart
/// Prayer and before-prayer notifications from [now] to now + 48 h. Empty when disabled or no place.
List<PlannedReminder> planPrayers({required PrayerSettings s, required DateTime now, required bool exact});

// lib/reminders/reminder_service.dart (changed)
abstract class ReminderService {
  // existing members unchanged, plus:
  Future<bool> exactAllowed();              // canScheduleExactNotifications()
  Future<void> openExactSettings();         // requestExactAlarmsPermission()
  Future<void> showTest(String title, String body);  // FR-023, channel prayer_sound, now
}
// PlannedReminder gains: final ReminderKind kind (wird, kahf, prayerSound, prayerSilent, prayerBefore); final bool exact;
// equality includes both, so a change of exactness reschedules.
```

## Rules the tests pin

- `planPrayers` never returns an item in the past, never two items with the same id, and returns nothing when
  disabled.
- A wird reminder's id, channel and schedule mode are exactly as before 014 (the existing reminder tests stay
  unchanged and green).
- `buildReminderPlan` = the wird/Kahf plan + `planPrayers(...)`, in that order.
