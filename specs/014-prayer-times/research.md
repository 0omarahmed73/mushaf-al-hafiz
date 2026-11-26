# Research: Prayer times (014)

Date: 2026-11-26. It builds on `docs/research/2026-11-25-prayer-times-study.md` and constitution 3.0.0.

## D1. Calculation library

- **Decision**: `adhan_dart` 2.0.1.
- **Rationale**:
  - It is pure Dart, works offline, and is MIT-licensed (per the study's reading of pub.dev; T001 checks it again and
    records it in `docs/research/licenses.md`).
  - It has presets for Egypt (Fajr 19.5°, Isha 17.5°), Umm al-Qura, Muslim World League, Karachi, Dubai, Kuwait, Qatar,
    Morocco, Turkey and North America.
  - It also has Hanafi Asr, high-latitude rules and per-prayer adjustments.
- **Alternatives**: writing the astronomy ourselves (more risk for no gain); an online API (forbidden by IV).

## D2. Reference for correctness (SC-001)

- **Decision**: a fixture of times for Cairo, Alexandria and Aswan on 12 dates (the 1st of each month, 2026), taken from
  a published Egyptian timetable.
- **Source**: the Egyptian General Authority of Survey or Dar al-Ifta. The owner or T002 records which source, with its
  link, in the fixture's header.
- **Tolerance**: ±1 minute.
- **Second fixture**: Makkah under Umm al-Qura, from ummulqura.org.sa, to prove that the method switch works.
- **Alternatives**: comparing with another app (not a primary source).

**What was found (2026-11-26, T009)**: no monthly table of the Authority could be read. The fixture holds the Authority's
times for Cairo and Alexandria on 11 and 24 January 2026, as quoted by Sada El-Balad (elbalad.news). Dostor's pages
refused the fetch, and Aswan's rows looked copied, with a wrong Dhuhr. All 24 values are within 1 minute of `adhan_dart`'s
Egyptian method. The Makkah fixture was dropped; a test that switching the method changes the times stands in for it.
The real check stays the owner's comparison with his mosque on the phone (quickstart step 2).

## D3. Getting the place without the network

- **Decision**: a small Kotlin `MethodChannel` (`app.hafiz.mushaf/location`) in MainActivity. It has two methods:
  - `request()`: runs the platform permission request for `ACCESS_COARSE_LOCATION` and returns the result (granted,
    denied, or denied forever).
  - `current()`: returns one reading. It uses `getLastKnownLocation` when that is under 1 day old. Otherwise it calls
    `LocationManager.getCurrentLocation` (API 30+), or `requestSingleUpdate` on older phones, with a 30-second timeout.
    The provider is chosen in this order: `fused` (API 31+), then `network`, then `gps`.
- **Accuracy**: Android coarsens the reading to about 2 km for coarse-only apps. That is well under 1 minute of prayer
  time (1 minute of longitude is about 27 km at the equator).
- **Network**: the app never uses the network. The phone's own provider may use Wi-Fi scanning, but that is the system,
  not the app. The app has no INTERNET permission.
- **Rationale**: no Google Play services dependency and no new Dart package; a few dozen lines of Kotlin.
- **Alternatives**: `geolocator` (pulls in `play-services-location` and its fused client, and is larger); `location`
  (same issue).

## D4. City list (the fallback, and the name shown)

- **Decision**: build `assets/prayer/cities.json` once, by `tool/build_cities.py`, from GeoNames `cities15000.txt` and
  `alternateNamesV2` (Arabic names).
- **Scope**:
  - Countries: the Arab League and the OIC member countries.
  - Cities: population ≥ 100,000, plus every capital.
  - Expected size: about 2,000 cities.
- **Fields**: Arabic name (falls back to the English name), English name, country code, lat/lon to 3 decimals, and the
  IANA time zone.
- **Licence**: CC BY 4.0, credited in About as «بيانات المدن: GeoNames (CC BY 4.0)» (proposal).
- **Size**: about 150 KB in the APK after compression.
- **Search**: normalised Arabic (hamza forms → ا, ة → ه, ى → ي, diacritics removed), the same normalisation as feature
  011's search (reuse its function).
- **Nearest city**: a linear scan over 2,000 cities, under 1 ms.
- **Alternatives**:
  - The whole world: about 25k cities, 1–2 MB. Not asked for; the location covers everyone anyway.
  - Egypt only: too narrow for the fallback.

## D5. Time zone

- **Decision**:
  - A city from the list uses its IANA zone (`timezone` package database, already bundled).
  - A place found by location uses the phone's zone at the moment it was found (`flutter_timezone`); that zone is stored
    with the place.
- Times are calculated as UTC instants, and shown and scheduled in that zone. Instants are absolute, so a later
  daylight-saving or zone change of the phone does not shift a prayer.
- The screen shows one line when the phone's zone differs from the place's.

## D6. One scheduler for all notifications

- **Fact**: `LocalNotificationService.reschedule` calls `cancelAllPendingNotifications()` and then schedules the plan.
- **Decision**:
  - `buildReminderPlan` appends the prayer plan (from `prayer_planner.dart`) to the wird and Kahf plan.
  - `PlannedReminder` gains a `kind` that picks the channel: wird, kahf, prayerSound, prayerSilent or prayerBefore.
  - It also gains `exact`: true for prayer items, and only when exact alarms are allowed.
  - Prayer ids live in their own range (1,000,000 and up), so they never meet wird ids.
  - The scheduler's existing triggers already cover changes: the settings stream (prayer keys sit in the same `Settings`
    table), the app resume, and the daily `workmanager` refresh.
  - The planner covers the next 48 hours of prayers, so a day without opening the app is covered (FR-021), and the daily
    refresh extends it.
- **Rationale**: two schedulers would erase each other.
- **Alternative**: cancelling by id range in two services. Rejected: it needs `getPendingNotificationRequests` on every
  refresh and is fragile.

## D7. Exact alarms and Google Play

- **Decision**: declare `SCHEDULE_EXACT_ALARM`, not `USE_EXACT_ALARM`.
  - Play reserves `USE_EXACT_ALARM` for alarm-clock and calendar apps.
  - `SCHEDULE_EXACT_ALARM` is denied by default on Android 14+, and the reader allows it in system settings. The screen
    offers to open that setting through `requestExactAlarmsPermission()` of the notifications plugin.
  - The app checks with `canScheduleExactNotifications()` on every refresh, so a withdrawn permission falls back to
    `inexactAllowWhileIdle` by itself, and the screen shows the "may be a few minutes late" line (FR-018).
- **Release check**: the Play Console may ask for the restricted-permission declaration for exact alarms. The answer is
  "user-set prayer-time notifications at the exact prayer time". Recorded in `docs/release/GOOGLE_PLAY.md` when the
  version ships.
- **Sources**: [Android 14 exact alarms](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms);
  [a developer write-up of Play's exact-alarm declaration](https://medium.com/gravel-engineering/exact-alarm-permission-google-plays-ticking-time-bomb-for-android-developers-e29e4d20b572)
  (secondary).

## D8. The takbir sound

- **Decision**: `android/app/src/main/res/raw/takbir.ogg`, under 10 seconds, mono, about 60 KB. It is the sound of the
  channel `prayer_sound`.
  - A channel's sound cannot change after the channel is made, so there are separate channels: `prayer_sound`,
    `prayer_silent` (no sound) and `prayer_before` (the phone's default sound, so a reminder is told apart from the time
    itself).
- **Source**: open. The owner is asked to record it himself (no licence needed: his own work, credited as he wishes), or
  T-task finds a recording whose licence allows bundling and changes (CC0 or CC BY).
  - Until the file exists, `prayer_sound` uses the phone's default sound.
  - A test fails while `takbir.ogg` or its line in `licenses.md` is missing; that test is marked as the release blocker.

## D9. Hijri date

- **Decision**: the tabular Islamic calendar (arithmetic, 30-year cycle), about 30 lines of Dart in `hijri.dart`, with
  tests on known dates.
- It can differ by a day from the announced month. The screen shows it as is; a ±1 day setting is left for later.
- **Alternatives**: a package (a dependency for 30 lines); Umm al-Qura tables (larger data).

## D10. Storage and backup

- **Decision**: keys `prayer.enabled`, `prayer.place` (JSON: lat, lon, zone, name, source), `prayer.method`,
  `prayer.asr`, `prayer.offsets` (six ints) and `prayer.notify` (five entries: mode and minutes before) in the
  `Settings` table.
- **Backup**: the backup already carries the whole `Settings` table, so the prayer settings travel with it.
- **Old backups**: a backup from before 014 has no `prayer.*` keys. To keep the reader's prayer settings when restoring
  it (spec edge case), the `prayer.*` keys are added to `kKeptOnImport`: they are kept when the file does not have them.
- No schema change and no new backup version.

## D11. Entry point

- **Decision**: in `reader_screen.dart` `_BottomBar`, replace `const _BarItem(icon: Icons.headphones, label: 'استماع',
  soon: true)` with `_BarItem(icon: Icons.mosque_outlined, label: 'مواقيت' (proposal), onTap: onPrayer)`.
- Key `bar-prayer`. The bar's height and the page geometry stay unchanged (existing layout tests).
- The full title «مواقيت الصلاة» is the screen's title and the item's tooltip. The bar label is shorter so it fits at 320 dp
  with a 2x font, like the other bar labels.

## D12. Found while building (2026-11-26)

- **Old tests edited (T021)**: replacing «استماع» with «مواقيت» is what FR-002 asks for, so the four places in older
  tests that named «استماع» now name «مواقيت» or tap «اختبار» (still «قريباً») instead:
  - `test/mushaf/reader_screen_test.dart`;
  - `test/mushaf/reader_night_test.dart` (three labels and the headphones icon);
  - `test/search/reader_search_highlight_test.dart`.
  Nothing else in them changed.
- **About (T038)**: the prayer sources are a block of their own at the end of About, so the main credit list keeps its
  rows. `test/settings/about_screen_test.dart` checked a credit high on the screen only after scrolling to the bottom,
  and that worked only because the list ended there. It now scrolls back up to that credit before checking it; nothing
  else in it changed.
- **Backup (T008)**: `test/onboarding/tips_backup_test.dart` pinned `kKeptOnImport` to the tips flag alone. It now
  pins the tips flag plus the six prayer keys, which is the change research D10 asked for.
- **A bug that was there before**: at 320 dp wide with a 2x system font, the reader's bottom bar overflows by 298 px, and
  an item's column by 21 px. This was measured on the code before 014. Phones with a large font, like the testers' A52,
  may see the bar cut off. It needs its own fix and is not part of this feature.

## D13. The day view's design (2026-11-26)

- **Decision**: the owner looked at the first build and said the design could be nicer. He was shown three options
  on a Claude Design canvas: A «قوس الشمس», B «خط اليوم» and C «صفحة المصحف». He picked A. The day view now has:
  - a header with the place, «غيّر المكان», and both dates on one line;
  - a hero card on the bar colour. In it, an arc of the sun from sunrise to maghrib (`SunArcPainter`). The part the
    sun has crossed is solid, each prayer has a dot, and the next prayer has a ring and its name. Under the arc:
    «الصلاة القادمة», the name in the heading font, the countdown, and «الساعة …»;
  - rows without boxes. The next row is tinted and outlined in the accent, and past rows are dimmed;
  - «جدول الشهر» as the filled main button, then «ضبط المواقيت» and «جرّب التنبيه». «لو التنبيه مبيوصلش» and «إيقاف
    مواقيت الصلاة» are quiet text buttons at the end.
- **Rationale**: the arc shows where the day stands at a glance. It is decoration only: every time is also in the
  rows, so the arc is left out of the semantics tree, and it labels only the next prayer so it stays readable at
  320 dp.
- **Tests changed on purpose**: `prayer_screen_day_test.dart` found «الصلاة القادمة: العصر» as one line; it now finds
  the name on its own line. `prayer_notify_ui_test.dart` scrolls to the exact-alarm line and the buttons before tapping,
  since the taller hero puts them below the first screen. Nothing else in them changed.

## D14. The month table and the Islamic days (2026-11-26)

- **Decision**: the owner picked design C «أيام تتفتح» from three on the Claude Design canvas. The table now has:
  - three month chips at the top (the month before, this month, the month after);
  - a card per day with a badge (the day and its weekday), the Hijri date, and a closed line with Fajr and Maghrib;
  - today open, with all six times and the next prayer outlined; a tap opens or closes any day;
  - the table scrolls to today when it opens.
- **Islamic days**: named on their card by fixed Hijri date (`lib/prayer/islamic_events.dart`): the Hijri new year,
  Ashura, the Mawlid (12 Rabi' al-Awwal, added at the owner's word «ضيف المولد النبوي»), the first of Ramadan, the last ten nights, Eid al-Fitr, the day of Arafah, Eid al-Adha and the days of
  Tashreeq. The calendar is tabular (D9), so a day can be one off the announced month. Isra and Mi'raj and the
  middle of Sha'ban are left out until the owner asks for them.
- **Test changed on purpose**: `prayer_month_test.dart` read the six times of day 17 from its closed row; it now opens
  the day first, since a closed day shows only Fajr and Maghrib. Nothing else in it changed.

## D15. The takbir recording (2026-11-26)

- **Decision**: the first 30 seconds of an adhan by Mohammed Al Damradach, from the owner's file. It is cut, faded at
  both ends, set to −16 LUFS, and stored as mono 22 kHz Ogg Vorbis (130 KB) in `res/raw/takbir.ogg`. It plays on
  the new channel `prayer_sound_2`, since Android keeps the default sound on the old `prayer_sound`.
- **Licence**: the file names www.assabile.com, and no open licence or reuse terms were found for it. This departs
  from D8 and Principle VIII, which ask for a recording that is the owner's own, CC0 or CC BY. The owner was told,
  with two CC0 options, and chose this file («استعملها عادي»). licenses.md records it as unlicensed. Before a public
  Play release, get the rights holder's permission or replace the file.
- **Length**: D8 planned under 10 seconds. The owner asked for 30.

