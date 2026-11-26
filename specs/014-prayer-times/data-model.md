# Data model: Prayer times (014)

No database schema change. Every field is in the `Settings` key/value table (research D10). Bundled data is read-only.

## PrayerSettings (stored)

| Field | Key | Type / values | Default | Rule |
|---|---|---|---|---|
| enabled | `prayer.enabled` | bool | false | FR-001: while false nothing is shown or scheduled |
| place | `prayer.place` | Place JSON or absent | absent | FR-003: no times until present |
| method | `prayer.method` | one of `egyptian, ummAlQura, muslimWorldLeague, karachi, dubai, kuwait, qatar, morocco, turkiye, northAmerica` (the names of `adhan_dart`'s enum) or `auto` | `auto` | `auto` = by the place's country (FR-007) |
| asr | `prayer.asr` | `standard` / `hanafi` | `standard` | FR-008 |
| offsets | `prayer.offsets` | 6 ints (fajr, sunrise, dhuhr, asr, maghrib, isha), each −30..30 | all 0 | FR-009; out of range is clamped on read |
| notify | `prayer.notify` | 5 entries (fajr, dhuhr, asr, maghrib, isha) of {mode: `sound`/`silent`/`off`, before: 0/5/10/15/20/30} | sound, 0 | FR-015, FR-017 |

An unreadable value falls back to its default, and the screen still opens (Principle VII).

## Place (stored inside PrayerSettings)

| Field | Type | Rule |
|---|---|---|
| lat, lon | double, 3 decimals (about 100 m; the reading is about 2 km anyway) | −90..90, −180..180 |
| zone | IANA id | must exist in the `timezone` database, else the phone's zone |
| name | string | the list city's Arabic name, or the nearest list city's name for a location reading |
| source | `location` / `list` | for a location reading, «تقريبًا» is shown after the name (FR-004b) |
| country | ISO 3166 alpha-2 | the method default (FR-007) |

## City (bundled, `assets/prayer/cities.json`)

`{ar, en, cc, lat, lon, tz}`, about 2,000 entries, sorted by population descending (the empty search shows the largest
first). Built by `tool/build_cities.py` from GeoNames (CC BY 4.0).

## DayTimes (derived, never stored)

`date`, plus `fajr, sunrise, dhuhr, asr, maghrib, isha` as UTC instants with offsets applied, plus `highLatitude: bool`
(FR-010). Calculated by `PrayerCalc.day(date, place, settings)`.

## Planned prayer notification (derived, scheduled)

It is a `PlannedReminder` with:

- `kind`: `prayerSound`, `prayerSilent` or `prayerBefore`;
- `exact`: whether exact alarms are allowed;
- `id`: 1,000,000 + dayIndex × 10 + slot, where slot is 0–4 for the prayer itself and 5–9 for the reminders before it;
- `at`: the instant;
- `payload`: `prayer`, which opens the screen (FR-022).

The planner makes them for the next 48 hours from now.

## State: the feature on the screen

off → (turn on) → no place → (location granted and found, or a city picked) → showing.
In "showing", tapping «حدد موقعي» or picking another city replaces the place. Turning off returns to off, keeps the
other settings, and cancels every prayer notification.
