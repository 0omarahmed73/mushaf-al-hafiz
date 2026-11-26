# Implementation Plan: Prayer times (مواقيت الصلاة)

**Branch**: none (shared tree) | **Date**: 2026-11-26 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/014-prayer-times/spec.md` (clarified 2026-11-26)

## Summary

Prayer times work on the phone, with no network. Each step:

- **Times.** The six times are calculated from the place by `adhan_dart` (MIT, pure Dart).
- **Place.** The place comes from one approximate-location reading, made through a small Kotlin channel over the
  platform `LocationManager` (no Google Play services, no new Dart package). The bundled city list is the fallback and
  also names the place.
- **Notifications.** They join the existing reminder plan, so one scheduler owns every notification. The current service
  cancels *all* pending notifications before scheduling, so a separate prayer scheduler would wipe the wird reminders,
  or be wiped by them (research D6).
- **Exactness.** Prayer notifications use exact alarms when the reader allowed them (`SCHEDULE_EXACT_ALARM`), and inexact
  ones otherwise. Wird reminders stay inexact.
- **Sound.** A short bundled takbir plays on its own notification channel.
- **Storage.** Settings are new keys in the existing `Settings` table, so the backup carries them with no new backup
  version and no schema change.
- **Entry.** The bottom bar's «استماع / قريبًا» placeholder becomes «مواقيت الصلاة» and opens the new screen.

## Technical Context

**Language/Version**: Dart 3 / Flutter 3.50; Kotlin for the location channel.

**Primary Dependencies**:
- Existing: `flutter_local_notifications` 23, `timezone`, `flutter_timezone`, `workmanager`, `drift`, `provider`,
  `material_ui`.
- New: `adhan_dart` 2.0.1 (MIT, research D1).

**Storage**: drift `Settings` key/value table, new keys `prayer.*` (data-model.md). No schema change.

**Testing**: `flutter test`.
- Unit tests: calculation against reference tables (research D2), the planner, the Hijri date, city search and nearest
  city.
- Widget tests: the screen in both looks, at 320 dp with a 2x font.
- A fake ReminderService for scheduling, and a fake location port.

**Target Platform**: Android (minSdk 24, targetSdk from Flutter). The real-device check is on the owner's Samsung.

**Project Type**: mobile app (single Flutter project).

**Performance Goals**:
- A day's six times calculate in under 5 ms; a month in under 100 ms.
- The screen opens in under 300 ms.
- City search answers each keystroke in under 50 ms over about 2,000 cities.

**Constraints**:
- No INTERNET permission.
- Only the approximate location, asked on tap and never in the background.
- Exact alarms are optional.
- The app grows by less than 1 MB (city list about 150 KB compressed, takbir about 60 KB, `adhan_dart` code).

**Scale/Scope**: 1 new screen with a month view, 1 settings sheet, about 2,000 bundled cities, and up to 10 notifications
a day.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle (3.0.0) | How this plan meets it | Status |
|---|---|---|
| I Quran text | The feature touches no Quran data or page. | Pass |
| II Mushaf first | Separate screen; the app still opens on the Mushaf; only the placeholder bar item changes (FR-002). | Pass |
| III Scope, exception 2.0.0 + place rule 3.0.0 | Times, countdown, place, method, Asr rule, offsets, month table, short-sound notification and reminder. No full adhan, no qibla, no widgets. Location is approximate, on tap only, kept on the phone, with a city-list fallback. | Pass |
| IV Offline, private | Calculation on the phone. Location from the platform provider only. Coordinates stored in local settings and never sent. No INTERNET permission (a test checks the merged manifest). | Pass |
| V Licensing | `adhan_dart` MIT; GeoNames CC BY 4.0 (attribution in About); the takbir recording needs a named source or the owner's own recording (T-blocker, research D8). | Pass with an open item |
| VI Arabic strings | Every string is in `prayer_strings.dart` as a proposal; the owner confirms before done. | Pass |
| VII Reliability | Exact alarms when allowed, inexact fallback with a message, daily background refresh, boot receiver (existing), a test button, a battery guide. | Pass |
| VIII Size | Under 1 MB added. | Pass |
| IX Test-first, real device | Every unit has a failing test first; Samsung check with the screen locked and the app closed (quickstart). | Pass |

Post-design re-check: Pass. One item is open: the takbir source (V). It blocks "done", but not the work: the code uses
the phone's default sound until the file exists, and a test fails while the file or its licence line is missing.

## Project Structure

### Documentation (this feature)

```text
specs/014-prayer-times/
├── spec.md, plan.md, research.md, data-model.md, quickstart.md
├── contracts/dart-interfaces.md, contracts/ui.md
└── checklists/requirements.md
```

### Source Code (repository root)

```text
lib/prayer/
├── prayer_strings.dart        # every Arabic string (proposals)
├── prayer_settings.dart       # PrayerSettings value + read/write of the prayer.* keys
├── prayer_calc.dart           # DayTimes for a date/place/settings (wraps adhan_dart), method defaults by country
├── hijri.dart                 # tabular Hijri date
├── cities.dart                # City, CityIndex (load, search, nearest)
├── location_port.dart         # LocationPort (Kotlin channel) + fake for tests
├── prayer_planner.dart        # PlannedReminder items for the next 48 h of prayers and reminders
├── prayer_screen.dart         # day view, countdown, settings entry
├── prayer_month_screen.dart   # month table
├── prayer_settings_sheet.dart # method, Asr, offsets, per-prayer choices
└── place_flow.dart            # «حدد موقعي», permission, city list fallback
lib/reminders/
├── reminder_planner.dart      # PlannedReminder gains kind (wird/kahf/prayer/prayerSilent/prayerBefore) and exact flag
├── reminder_scheduler.dart    # buildReminderPlan also adds the prayer plan
└── reminder_service.dart      # per-item channel and schedule mode; exact-alarm check/request
lib/mushaf/reader_screen.dart  # the «استماع» bar item → «مواقيت الصلاة»
assets/prayer/cities.json      # generated by tool/build_cities.py from GeoNames (not run at app build)
android/app/src/main/res/raw/takbir.ogg
android/app/src/main/kotlin/app/hafiz/mushaf/MainActivity.kt  # + location channel
android/app/src/main/AndroidManifest.xml  # + ACCESS_COARSE_LOCATION, SCHEDULE_EXACT_ALARM
tool/build_cities.py
test/prayer/*.dart
```

**Structure Decision**: a new `lib/prayer/` folder like `lib/large_ayah/`. Scheduling stays in `lib/reminders/`, so there
is one owner of the phone's notification schedule.

## Complexity Tracking

| Deviation | Why needed | Simpler alternative rejected because |
|---|---|---|
| Native Kotlin location channel | One approximate reading without Google Play services or a large plugin | `geolocator` pulls in `play-services-location` and more permissions plumbing than one reading needs (research D3) |
| Reminder plan gains prayer items and per-item exactness | The service cancels all pending notifications on each refresh | A second scheduler would erase the other's notifications (research D6) |
