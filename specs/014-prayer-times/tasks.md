# Tasks: Prayer times (مواقيت الصلاة)

**Input**: design documents in `specs/014-prayer-times/` (spec.md, plan.md, research.md, data-model.md, contracts/,
quickstart.md); constitution 3.0.0

**Rules for every task**:
- **Test-first** (Principle IX): a task that writes a test makes it fail for the right reason before the next task makes
  it pass.
- **Commits**: one commit per task, with explicit paths only (`git commit -m ... -- <paths>`). Never `git add -A`, and no
  branch.
- **Existing tests**: they are not edited. The wird and Kahf reminder tests stay unchanged and green.
- **Before each commit**: `flutter analyze` reports no issue and the touched tests pass.
- **Speckit scripts**: run them with `SPECIFY_FEATURE_DIRECTORY=specs/014-prayer-times SPECIFY_FEATURE_NO_PERSIST=1`.
  `.specify/feature.json` stays on 003.
- **Strings**: every Arabic string is a proposal until the owner confirms it (Principle VI).

**Format**: `- [ ] T### [P?] [Story?] description with file path`. [P] means it can run in parallel (different files, no
open dependency).

## Phase 1: Setup

- [x] T001 Add `adhan_dart: 2.0.1` to `pubspec.yaml`. Read its LICENSE in the pub cache and confirm it is MIT. Add its line
  to `docs/research/licenses.md` (name, version, licence, URL, read date). Run `flutter pub get`, and commit `pubspec.yaml`,
  `pubspec.lock` and `docs/research/licenses.md`.
- [x] T002 [P] Write `tool/build_cities.py` (research D4):
  - Input: GeoNames `cities15000.txt` and `alternateNamesV2.txt`, downloaded by the owner or by hand into a scratch
    folder outside the repo. Their paths are arguments; the script never downloads anything.
  - Filter: Arab League and OIC country codes (listed in the script), population ≥ 100,000 or a capital (feature code
    `PPLC`).
  - Arabic name: the preferred `ar` name, else the first `ar` name, else the English name.
  - Output: `assets/prayer/cities.json` as `[{ar, en, cc, lat, lon, tz}]`, sorted by population descending, lat/lon to 3
    decimals.
  - Run it, check there are about 2,000 entries and the file is under 400 KB, and add the asset folder to `pubspec.yaml`.
  - Add the GeoNames line (CC BY 4.0, URL, date) to `docs/research/licenses.md`.
- [x] T003 [P] Write the failing `test/prayer/prayer_strings_test.dart`. It pins every string of
  `specs/014-prayer-times/contracts/ui.md` exactly:
  - «مواقيت», «مواقيت الصلاة», «تشغيل مواقيت الصلاة», «حدد موقعي», «اختار المدينة من القائمة», «تقريبًا»,
    «الصلاة القادمة»;
  - the six names «الفجر», «الشروق», «الظهر», «العصر», «المغرب», «العشاء»;
  - every line and button of the screen, the settings sheet and the month view;
  - the notification builders: `atPrayer('العصر')` gives «حان الآن موعد صلاة العصر», `before('العصر', 10)` gives «باقي ١٠
    دقائق على صلاة العصر»;
  - the time formatter: 16:05 gives «٤:٠٥ م» and 04:32 gives «٤:٣٢ ص»;
  - the countdown: 1h 23m 4s gives «بعد ١:٢٣:٠٤».
- [x] T004 Create `lib/prayer/prayer_strings.dart` with exactly those strings and builders, with a doc comment that they
  are proposals. T003 passes.

## Phase 2: Foundational (blocks every story)

### Settings (data-model.md, research D10)

- [x] T005 [P] Write the failing `test/prayer/prayer_settings_test.dart`. It tests `PrayerSettings.read(map)` and
  `toEntries()` with the rules verbatim from data-model.md:
  - `prayer.enabled` is false when absent.
  - `prayer.place` is absent when unusable. lat must be in −90..90 and lon in −180..180; a zone missing from the timezone
    database falls back to the phone's zone. `source` is `location`/`list`.
  - `prayer.method` is `auto` when absent or unknown.
  - `prayer.asr` is `standard`/`hanafi`, `standard` when absent.
  - `prayer.offsets` has six ints, each "−30..30", clamped on read, all 0 when absent.
  - `prayer.notify` has five entries `{mode: sound/silent/off, before: 0/5/10/15/20/30}`, default sound with 0; an unknown
    `before` becomes 0.
  - Parsing never throws; a round trip keeps every value.
- [x] T006 Create `lib/prayer/prayer_settings.dart`, and add `watchPrayerSettings()` and `setPrayerSettings()` to
  `lib/wirds/wird_repository.dart` (one transaction writing the `prayer.*` keys). T005 passes.
- [x] T007 [P] Write the failing `test/prayer/prayer_backup_test.dart`:
  - A backup with prayer settings restores them.
  - Restoring a backup from before 014 (no `prayer.*` keys) keeps the current prayer settings (research D10).
  - The backup version is unchanged.
- [x] T008 Add the six `prayer.*` keys to `kKeptOnImport` in `lib/backup/backup_service.dart`. T007 passes, and the
  existing backup tests stay green.

### Calculation (research D1, D2, D5, D9)

- [x] T009 [P] Create the fixtures `test/prayer/fixtures/egypt_2026.json` (Cairo, Alexandria, Aswan; the 1st of each month
  of 2026; six times each, in local time) and `test/prayer/fixtures/makkah_2026.json` (Umm al-Qura). The header of each
  names its published source and link (research D2). If no primary source can be read, stop and ask the owner for a
  printed timetable; do not use another app's numbers.
- [x] T010 [P] Write the failing `test/prayer/prayer_calc_test.dart`:
  - Every fixture time is within ±1 minute with method `auto` (SC-001).
  - Hanafi Asr is later than standard on the same day.
  - A +2 offset on Maghrib moves only Maghrib, by 2 minutes.
  - `methodFor` returns the table of contracts/dart-interfaces.md.
  - `next()` at 23:00 Cairo returns tomorrow's Fajr; just after Dhuhr it returns Asr; sunrise is never next.
  - Oslo on 21 June sets `highLatitude` true and still gives six ordered times.
  - The DST day of a zone with daylight saving (America/New_York, 8 March 2026) gives times in the correct local offset.
  - A month of times is computed in under 100 ms.
- [x] T011 Create `lib/prayer/prayer_calc.dart` (Prayer, DayTimes, PrayerCalc) over `adhan_dart`. T010 passes.
- [x] T012 [P] Write the failing `test/prayer/hijri_test.dart`: the tabular conversion gives 1 Ramadan 1447 for 18 Feb
  2026 (±1 day, as research D9 allows; pin the exact tabular result), and 1 Muharram 1448 for 16 June 2026 (±1). `format()`
  gives «١ رمضان ١٤٤٧ هـ».
- [x] T013 Create `lib/prayer/hijri.dart`. T012 passes.

### Cities and place (research D3, D4)

- [x] T014 [P] Write the failing `test/prayer/cities_test.dart` on the real asset:
  - It loads in under 300 ms.
  - Searching «الاسكندريه» finds الإسكندرية.
  - Searching «القاهره» finds القاهرة; «cairo» finds it too; «مكه» finds مكة المكرمة.
  - An empty query gives the largest cities first.
  - `nearest(30.04, 31.24)` is Cairo, and `nearest(21.42, 39.83)` is Makkah.
  - Every entry has a zone that exists in the timezone database.
  - Each keystroke search takes under 50 ms.
- [x] T015 Create `lib/prayer/cities.dart`, reusing the Arabic normalisation of feature 011's search (import it, do not
  copy it). T014 passes.
- [x] T016 [P] Write the failing `test/prayer/location_port_test.dart`. It runs against a mocked `MethodChannel`
  `app.hafiz.mushaf/location`:
  - `request()` maps `granted`/`denied`/`deniedForever`.
  - `current()` returns a pair or null; a channel error gives null, not a throw.
  - `FakeLocationPort` exists for the widget tests.
- [x] T017 Create `lib/prayer/location_port.dart`. Add the `location` channel to
  `android/app/src/main/kotlin/app/hafiz/mushaf/MainActivity.kt` per research D3:
  - `request` asks `ACCESS_COARSE_LOCATION` only.
  - `current` uses the last known location under 1 day old, else `getCurrentLocation` (API 30+) or
    `requestSingleUpdate`, with providers fused > network > gps and a 30-second timeout.
  - `openSettings` opens the app's details page.
  Add `<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>` to `AndroidManifest.xml`. T016
  passes, and `flutter build apk --debug` compiles.

### One scheduler (research D6, D7)

- [x] T018 [P] Write the failing `test/reminders/reminder_kind_test.dart` (a new file; existing reminder tests untouched):
  - `PlannedReminder` has `kind` and `exact`, and equality includes them.
  - A wird reminder built the old way has kind `wird`, exact false, and the same id, title, body, payload and time as
    before.
  - `FakeReminderService` records the kind and exact flag of each scheduled item.
- [x] T019 Change `lib/reminders/reminder_planner.dart` and `lib/reminders/reminder_service.dart`:
  - Channels by kind: `prayer_sound` (the sound `takbir` from `res/raw`, or the default until the file exists),
    `prayer_silent` (no sound), and `prayer_before` (default sound).
  - The schedule mode is `exactAllowWhileIdle` when `exact`, else `inexactAllowWhileIdle`.
  - Add `exactAllowed()`, `openExactSettings()` and `showTest()`.
  - Add `<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>` to `AndroidManifest.xml`, and update
    its comment at line 3.
  T018 passes, and every existing reminder test passes unedited.

## Phase 3: User Story 1 - See today's prayer times for my city (P1) MVP

**Goal**: the screen with the place flow, today's times and the countdown.
**Independent test**: turn it on, pick Cairo from the list, and see six correct times and a countdown.

- [x] T020 [P] [US1] Write the failing `test/prayer/bar_item_test.dart` through the reader harness:
  - The bottom bar has `bar-prayer` («مواقيت», tooltip «مواقيت الصلاة») where «استماع» was, and «استماع» is gone.
  - The bar's height and the page rectangle equal the values recorded before the edit (measure them on the current code
    and write them in the test).
  - Tapping `bar-prayer` opens `prayer-screen`.
  - The large-ayah view of feature 015 is checked the same way if it shows the bar.
  - Both looks; 320 dp with a 2x font, no overflow.
- [x] T021 [US1] Edit `_BottomBar` in `lib/mushaf/reader_screen.dart` (one minimal commit; run `git status` and
  `git log -1 -- lib/mushaf/reader_screen.dart` first). Add an `onPrayer` callback that pushes `PrayerScreen`. T020
  passes.
- [x] T022 [P] [US1] Write the failing `test/prayer/prayer_screen_place_test.dart` with `FakeLocationPort`:
  - Off: shows `prayer-off`, and nothing is scheduled.
  - `prayer-enable` leads to `prayer-place`.
  - `place-locate` granted at (30.04, 31.24) shows `prayer-day` with «القاهرة تقريبًا» and the phone's zone.
  - Denied: `place-failed` shows and the list opens.
  - deniedForever: `place-settings` also shows.
  - No reading in 30 s (fake timeout): `place-failed`.
  - Picking «الإسكندرية» from the list gives source `list` and the city's zone.
  - `request()` is never called before the tap (FR-004).
- [x] T023 [US1] Create `lib/prayer/place_flow.dart` and the off, no-place and showing states of
  `lib/prayer/prayer_screen.dart`. T022 passes.
- [x] T024 [P] [US1] Write the failing `test/prayer/prayer_screen_day_test.dart` with a fixed clock:
  - Six rows with the right times for Cairo.
  - `prayer-next` names the next prayer and its row is marked.
  - The countdown ticks each second.
  - After Isha the next prayer is tomorrow's Fajr.
  - Header: the Hijri date `prayer-hijri`.
  - `zone-differs` shows only when the phone's zone differs from the place's; `high-lat` shows only for a high-latitude
    place.
  - The Gregorian and Hijri dates update after midnight without reopening.
  - Both looks, the contrast walk, 320 dp with a 2x font, and semantics.
- [x] T025 [US1] Complete the day view in `lib/prayer/prayer_screen.dart`. T024 passes.

## Phase 4: User Story 2 - A notification at each prayer (P1)

**Goal**: per-prayer notifications that arrive with the app closed.
**Independent test**: Dhuhr notification arrives with the screen locked on the Samsung.

- [x] T026 [P] [US2] Write the failing `test/prayer/prayer_planner_test.dart`:
  - Off or no place gives an empty plan.
  - On with defaults gives the five prayers for 48 hours from `now`, never in the past and never sunrise.
  - The ids follow data-model.md "1,000,000 + dayIndex × 10 + slot" (unique).
  - Kinds follow the mode (sound gives `prayerSound`, silent gives `prayerSilent`, off gives no item).
  - `before` 10 adds a `prayerBefore` 10 minutes earlier (skipped if already past).
  - `exact` follows the argument; the payload is `prayer`.
  - The titles and bodies are the builders of T004 with the place's name.
- [x] T027 [US2] Create `lib/prayer/prayer_planner.dart`. T026 passes.
- [x] T028 [P] [US2] Write the failing `test/prayer/prayer_scheduling_test.dart` with a fake service and an in-memory
  database:
  - `buildReminderPlan` is the wird and Kahf plan followed by the prayer plan.
  - A change of any `prayer.*` key reschedules (through the existing debounce).
  - Turning off removes every prayer item and keeps every wird item.
  - With `exactAllowed()` false, the items are inexact.
  - The background refresh (`reminderCallbackDispatcher` path, called directly) plans prayers too.
  - A wird reminder and a prayer at the same minute both stay.
- [x] T029 [US2] Wire the prayer plan into `lib/reminders/reminder_scheduler.dart` (`buildReminderPlan` reads the prayer
  settings and `exactAllowed()`) and `lib/reminders/background_refresh.dart`. T028 passes. The existing reminder tests are
  unedited and green.
- [x] T030 [P] [US2] Write the failing `test/prayer/prayer_notify_ui_test.dart`:
  - `prayer-bell-<p>` cycles sound, silent, off and saves each step.
  - `exact-off` shows when exact timing is not allowed, and its button calls `openExactSettings()`.
  - `notif-off` shows when notifications are off.
  - `prayer-test` calls `showTest()` once.
  - `prayer-battery` opens the guide sheet.
  - `prayer-disable` turns the feature off.
  - The app resume re-checks exact timing.
  - Tapping a notification with payload `prayer` opens `prayer-screen` (through `NotificationTaps`).
- [x] T031 [US2] Implement these in `lib/prayer/prayer_screen.dart` and the payload route in the app's tap handler. T030
  passes.
- [x] T032 [US2] Takbir (research D8). Write `test/prayer/takbir_asset_test.dart`, marked as the release blocker: it
  checks that `android/app/src/main/res/raw/takbir.ogg` exists, is under 10 seconds (read the Ogg header) and under 150
  KB, and that `docs/research/licenses.md` has a line naming its source and licence. It stays red until the owner gives
  the recording (his own, or a CC0 / CC BY one he approves). When it exists: add the file and the line, then switch
  `prayer_sound` to it. A channel's sound is fixed once the channel exists, so if a build with the default sound was ever
  installed, use a new channel id (`prayer_sound_2`).

## Phase 5: User Story 3 - Adjust the calculation (P2)

**Goal**: method, Asr rule and offsets.
**Independent test**: +2 on Maghrib changes the shown time and the next notification.

- [x] T033 [P] [US3] Write the failing `test/prayer/prayer_settings_sheet_test.dart`:
  - `set-method` lists «تلقائي (حسب البلد)» first, then the methods by their Arabic names; a choice changes the times.
  - `set-asr` switches standard/Hanafi.
  - `set-offset-<p>` steppers clamp at −30..+30.
  - `set-notify-<p>` sets the mode and the minutes before.
  - Every change is saved and reschedules once.
  - Both looks, 320 dp with a 2x font.
- [x] T034 [US3] Create `lib/prayer/prayer_settings_sheet.dart`. T033 passes.

## Phase 6: User Story 4 - The month's timetable (P3)

- [x] T035 [P] [US4] Write the failing `test/prayer/prayer_month_test.dart`:
  - February 2026 has 28 rows; today is marked `month-today`.
  - `month-next` and `month-prev` work.
  - Each row's times equal `PrayerCalc.day` for that date.
  - It opens in under 300 ms.
  - Both looks, 320 dp with a 2x font.
- [x] T036 [US4] Create `lib/prayer/prayer_month_screen.dart`. T035 passes.

## Phase 7: Polish and cross-cutting

- [x] T037 [P] Write `test/prayer/manifest_permissions_test.dart`. It reads the merged debug manifest after a build, or the
  source manifest if the build is unavailable in tests:
  - `ACCESS_COARSE_LOCATION` and `SCHEDULE_EXACT_ALARM` are present.
  - `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION` and `USE_EXACT_ALARM` are absent (SC-007).
  Also check the release APK with `aapt2 dump permissions` and record the output in the task note.
- [x] T038 [P] Add the credits to About (`lib/settings/about_screen.dart`): `adhan_dart` (MIT), GeoNames (CC BY 4.0) and
  the takbir's source, with a widget test in `test/prayer/about_credits_test.dart`.
- [x] T039 Update `PRIVACY.md` (both languages):
  - The approximate location is used on the phone only for prayer times and never sent.
  - The exact-alarm permission is used for the prayer notifications.
  Commit it locally. The push to the public repository waits for the owner's «ارفع».
- [x] T040 Run `dart format` on the new files only, then `flutter analyze` and the whole suite, and record the counts.
- [ ] T041 The owner confirms every Arabic string of `lib/prayer/prayer_strings.dart` (Principle VI). Record his words.
- [ ] T042 [PHONE] Install on the owner's Samsung after his «سطّب» and a backup. Walk quickstart steps 1–9 with the screen
  locked and the app closed (Principles III, VII, IX). Record each step's result. Any defect gets a failing test first,
  then the fix.
- [ ] T043 Converge (`/speckit-converge`) and record the result.
- [x] T044 Redesign the day view as design A «قوس الشمس», the one the owner picked from three Claude Design options
  on 2026-11-26 (research D13). Test first in `test/prayer/prayer_screen_arc_test.dart`. Add `lib/prayer/sun_arc.dart`,
  and restyle `lib/prayer/prayer_screen.dart`. The new string `atClock` («الساعة …») joins the T041 list.
- [x] T045 After seeing T044 the owner asked (2026-11-26) for Cairo in place of Reem Kufi for the headings in the whole
  app except the Mushaf, and for the three buttons as equal icon tiles in one row. Test first in
  `test/settings/heading_font_test.dart` and `test/prayer/prayer_screen_arc_test.dart`. `kHeadingFont` is now Cairo
  bold, and so is the splash name. Reem Kufi stays only for the surah title (`kTitleFont`).
- [x] T046 The owner's screenshot of «حدد موقعي» (2026-11-26) showed the phone's own font. The theme's filled-button
  style, and Night's snack bar and tooltip styles, had no font family, so their text dropped Cairo everywhere in the
  app. They now name Cairo. Test first in `test/settings/ui_font_everywhere_test.dart`.
- [x] T047 The month table as design C «أيام تتفتح», the owner's pick of three (2026-11-26), with the Islamic days
  he asked for. Test first in `test/prayer/prayer_month_design_test.dart` and `test/prayer/islamic_events_test.dart`.
  The arc label also names Cairo now, and the hero is set tight as in design A (commit 9846c2e). New proposal strings
  for T041: `kToday` («النهارده»), `monthSummary`, and the eleven event names in `lib/prayer/islamic_events.dart`.

## Dependencies

- Setup (T001–T004), then Foundational (T005–T019), then the stories.
- US1 (T020–T025) is the MVP. US2 (T026–T032) needs T019 and the screen of US1. US3 and US4 need only the Foundational
  phase and the screen.
- T032 is blocked on the recording and can finish last. T041 and T042 come before "done", and T043 is last.

## Parallel opportunities

- In Setup: T002 and T003.
- In Foundational: T005, T007, T009, T010, T012, T014, T016 and T018 (all test or data files).
- After US1: US3 and US4 in parallel with US2.

## Implementation strategy

1. MVP = US1: the times on the screen with no notifications. That is already useful and needs no new permission except
   the approximate location.
2. Then US2: the notifications.
3. Then US3 and US4.
4. A Play build happens only after T042 passes on the phone and the owner says so.

## Notes

- T040 (2026-11-26): `dart format` was run on the feature's files and `flutter analyze` reports no issues. The whole
  suite: 2,538 passed, 1 skipped, 2 failed. The two failures:
  - `test/onboarding/tips_backup_test.dart` pinned the kept-on-import keys. It was updated for the prayer keys
    (research D12) and passes now.
  - `test/prayer/takbir_asset_test.dart` is the planned release blocker (T032), waiting for the recording.
- T037: the source manifest test passes. The release APK still needs a check with `aapt2 dump permissions` before a
  Play build. The debug build adds INTERNET for development, as it always has.
- T037 release check (2026-11-26): `aapt2 dump permissions` on the arm64 release APK of commit 3124689 lists
  POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, SCHEDULE_EXACT_ALARM, ACCESS_COARSE_LOCATION, VIBRATE, FOREGROUND_SERVICE,
  FOREGROUND_SERVICE_SHORT_SERVICE, WAKE_LOCK and ACCESS_NETWORK_STATE. There is no INTERNET, fine or background location,
  or USE_EXACT_ALARM.
- T042 install (2026-11-26): the phone had the Play build 1.0.0 (Google's signature). After the owner's backup, his
  «سطّب» and «امسح وسطّب», it was uninstalled and the laptop build of commit 3124689 (1.0.2+3 with feature 014) was
  installed. The owner restores his data from the backup. The steps of the walk come next.
- T044 install (2026-11-26): the phone was back on the Play build 1.0.0, so the laptop build was refused (signatures
  differ). After the owner's backup and «امسح وسطّب», the Play build was uninstalled and the laptop build of commit
  134aa39 (1.0.2+3, design A) was installed at 13:18. The owner restores his data from the backup.
- T045 install (2026-11-26): after the owner's «سطّب», the build of commit e025899 was installed over it at 13:40 (same
  key, data kept).
- T046 install (2026-11-26): after the owner's «سطّب», the build of commit cf4d811 was installed over it at 14:00 (same
  key, data kept).
- T047 install (2026-11-26): at the owner's «خلص وسطب», the build of commit ba4cc41 was installed over it at 14:39
  (same key, data kept).
- T032 (2026-11-26): the owner first chose the Al-Azhar Park adhan (Freesound, CC0), then gave his own file
  `cd17c7200df5.mp3`, an adhan by Mohammed Al Damradach tagged www.assabile.com. No open licence was found for it. He
  was told, and said «استعملها عادي». He then asked for the first 30 seconds instead of the first takbir, so the clip
  is 30 s, not under 10 s as research D8 planned (130 KB, under the 150 KB limit). The «بصوت» channel is now
  `prayer_sound_2` with `takbir` as its sound, and `res/raw/keep.xml` keeps the file in release builds. licenses.md
  records the missing licence; About credits the reciter and the site.
- T032 install (2026-11-26): after the owner's «سطّب», the build of commit 31dacf9 was installed over it at 15:10
  (same key, data kept). `aapt2 dump resources` shows `raw/takbir` in the release APK (130,509 bytes).
- [x] T048 The owner's screenshot (2026-11-26) showed the month chips one per line, with this month stretched full
  width; design C has one row of four chips. Both screens were checked against their designs item by item. Two gaps
  were found and fixed: the chips are now one row of four 40 px pills, scrolling sideways when a large font makes
  them too wide, and «تقريبًا» is a 13 px secondary-colour text after the city name. `prayer_screen_place_test.dart`
  now finds the name and «تقريبًا» as two texts; nothing else in it changed.
- T048 install (2026-11-26): after the owner's «سطّب», the build of commit c8bc4e3 was installed over it at 15:34
  (same key, data kept).
