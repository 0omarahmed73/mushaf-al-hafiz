# Study: prayer times and adhan (and ayah bookmarks)

Date: 2026-11-25. Status: research only, nothing decided, nothing built.
The owner asked for two features: a bookmark on an ayah, and prayer times with adhan "with full control".
This file covers what popular adhan apps offer, what users complain about, what Android allows, and what
the feature would cost this app.

## 1. The blocker to settle first: the constitution forbids it

Principle III says: "The app MUST NOT add adhan, qibla, duas, hadith or other non-Quran features". Its
rationale is that this is Muslim Pro's ground and would dilute the product. Prayer times therefore need an
amendment that reverses part of a principle (a MAJOR change, 2.0.0), decided by the owner, before a spec.

Other principles the feature touches:

| Principle | What it means for prayer times |
|---|---|
| II Mushaf first | Prayer times must not sit between the reader and the Mushaf: a separate screen, off by default. |
| IV Offline, private | Times must be computed on the phone. No prayer-time API, no map search online. Location never leaves the phone. |
| V Licensing | Every adhan recording and the city list need a named source and licence in `licenses.md`. |
| VII Reliability | An adhan that is late or silent is the top complaint about competitors. If we add it, it must be exact. |
| VIII App size | Each full adhan recording is about 1 to 3 MB. A city list is about 1 to 3 MB. |

## 2. What the popular apps offer

Sources are store pages and F-Droid listings read on 2026-11-25. Blog rankings were found but most are
written by app makers, so they are not used as evidence.

| Feature | Al-Azan (open source, no internet permission) | Mihrab (open source) | Muslim Pro / Athan / Salatuk class |
|---|---|---|---|
| Times computed on the phone | yes | yes for some countries, AlAdhan API elsewhere | mixed |
| Calculation method choice | many | many, plus official tables | yes |
| Asr: standard or Hanafi | yes | yes | yes |
| Minute offset per prayer | yes | yes | yes |
| Location | offline city search or GPS | GPS or online search | GPS |
| Adhan sound per prayer | yes, different for Fajr, any file from the phone | built-in or own file | large libraries (Athan's selling point) |
| Per prayer: adhan / short sound / silent | yes | yes | yes |
| Reminder before or after a prayer | yes | yes, with snooze | yes |
| Full-screen alert on the lock screen | yes | yes | some |
| Silence the phone during the prayer | yes (Do Not Disturb) | yes | some |
| Extra times: sunrise, midnight, last third | yes | partly | yes |
| Monthly timetable | yes | yes, share as picture or PDF | yes |
| Home-screen widget, pinned countdown | yes | yes | yes |
| Qibla | compass and map | compass | yes |
| Hijri date | yes | yes | yes |
| Prayer log, qada counter | qada counter | log with streak | some |
| Ads, account, tracking | none | none | ads and subscriptions |

Al-Azan is the closest model for this app: no ads, no internet permission, offline city search. Its
permission list shows the price of full control: precise and background location, exact alarms, foreground
service for audio, Do Not Disturb access, full-screen intent, draw over other apps, run at startup, ignore
battery optimisation.

## 3. What users complain about

From review roundups (secondary sources, treat as leads):

1. The adhan does not play, plays late, or plays silently. Battery managers on Samsung, Xiaomi, Huawei
   and Oppo kill the app.
2. The times look wrong: wrong default method for the country, wrong Asr rule, a few minutes off the
   local mosque, errors after a daylight-saving change.
3. Ads that open at the moment of the adhan.
4. Distrust of the location permission.
5. Widgets that freeze or show old times.

This app already answers 3 and 4. Points 1 and 2 are where the work is.

## 4. What it takes technically

**Calculation.** `adhan_dart` 2.0.1 (pure Dart, no network, port of the Adhan JavaScript library, Meeus
algorithms). It has presets for Egypt (19.5° / 17.5°), Umm al-Qura, Muslim World League, Karachi, Gulf,
Kuwait, Qatar, Dubai, Morocco, Algeria, Tunisia, Jordan, Turkey, North America and others; Hanafi Asr;
high-latitude rules; per-prayer minute adjustments. Licence: MIT (read on pub.dev, 2026-11-25).

**Owner's decision (2026-11-25):** scope B (times plus notification). The full adhan (scope C) is left
for a later stage.

**Location.** Two ways, both offline: (a) pick a city from a bundled list (no permission), (b) GPS, which
needs the location permission. The app has no location permission today. A bundled list needs a source
with a licence (GeoNames is CC BY, to confirm) and adds size.

**Exact time.** The app's reminders today are scheduled in inexact mode on purpose (a few minutes'
slack, no extra permission). An adhan needs exact alarms. On Android 14 and later `SCHEDULE_EXACT_ALARM`
is denied by default and the user must switch it on in system settings. `USE_EXACT_ALARM` is granted at
install but Google Play reserves it for alarm-clock and calendar apps; this app is not on Play, so the
Play rule does not bind it, but it would if Play is ever planned.

**Sound.** A notification sound is meant to be short, and a channel's sound cannot be changed after the
channel is created. A full adhan (2 to 4 minutes) with a Stop button is normally played by the app from
a foreground service of type media playback, started by the alarm. That is new native-side work and new
permissions. A short sound (takbir only, 5 to 10 seconds) can be done as a plain notification with the
packages the app already has.

**Battery managers.** Samsung and others add their own limits. The app would need a guided "allow
background activity" step and a "test the adhan now" button. This phone (Samsung) is a good test device.

**Recordings.** No clearly public-domain adhan was found. Cambridge's Cairo recordings are CC BY-NC-ND
(no trimming). Freesound has a few with attribution licences (each to be checked). The safest ways: the
user picks a sound file from their own phone, or the owner records or gets written permission.

**Not verified in this study:** the maximum length Android accepts for a notification sound; whether
`flutter_local_notifications` 23 can raise a full-screen intent on Android 14+ without extra steps; the
exact licence of `adhan_dart` and of any city list; how close the Egyptian preset is to the times
printed by the Egyptian Survey Authority for Cairo (needs a check against a printed month).

## 5. Sizes of the three possible scopes

| Scope | What the reader gets | New permissions | Rough size of work |
|---|---|---|---|
| A. Times only | Today's times, next prayer countdown, city picker, method, Asr rule, offsets, monthly table, Hijri date | none | like one medium feature (about 011) |
| B. A + notification | A, plus per-prayer notification with a short sound, reminder before, silent or sound per prayer | exact alarm | A plus a medium feature |
| C. B + full adhan | B, plus full adhan with Stop, own sound file, different Fajr adhan, lock-screen alert, silence the phone, test button, battery guide | exact alarm, foreground service, full-screen intent, Do Not Disturb, optional GPS | the largest feature so far, with native Android code |

Qibla, widgets, prayer log and qada counter are separate features and are left out of all three.

## 6. Ayah bookmark (the first request)

Small and inside the current scope. Today a bookmark is a page (table `Bookmarks`: id, wirdId, page, note,
createdAt; schema version 1). An ayah bookmark needs two nullable columns (surah, ayah), which is the
first schema change (version 2 with a migration) and a new backup version that still reads version 1
files. The entry point already exists: a long press on a word opens the ayah sheet, which gets a
bookmark action. The bookmarks list shows «سورة X، آية N» and opens the page with that ayah marked.

## Sources

- Al-Azan listing: https://f-droid.org/en/packages/com.github.meypod.al_azan/
- Mihrab listing: https://f-droid.org/en/packages/com.prayer_times/
- adhan_dart: https://pub.dev/packages/adhan_dart
- Android exact alarms: https://developer.android.com/about/versions/14/changes/schedule-exact-alarms
- flutter_local_notifications issues (channel sound, Samsung alarms): https://www.github.com/MaikuB/flutter_local_notifications/issues/2287 , https://www.github.com/MaikuB/flutter_local_notifications/issues/2316
- Review roundup: https://unstar.app/blog/muslim-pro-quran-majeed-athan-pillars-tarteel-quran-prayer-apps-ranked-2026
- Samsung exact-alarm report: https://eu.community.samsung.com/t5/galaxy-s24-series/alarms-amp-reminders-section-disappears-after-denying-schedule/td-p/11895667
- Cambridge Cairo adhan recordings (CC BY-NC-ND): https://www.repository.cam.ac.uk/handle/1810/237156?show=full
- Freesound adhan recording: https://freesound.org/people/RJStefanski/sounds/255231
- Islamic Network thread on bundling an adhan: https://community.islamic.network/d/255-permission-to-bundle-an-adhan-audio-file-in-our-android-app-nurafiq
- Muslim Pro alternatives article: https://www.dhakatribune.com/feature/tech/420193/muslim-pro-alternatives-5-ad-free-prayer-and
