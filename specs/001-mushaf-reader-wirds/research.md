# Research: Mushaf Reader, Wirds and Reminders

Phase 0 output for [plan.md](./plan.md). Technical Context had no NEEDS CLARIFICATION items; this file
records the decisions behind it, measured facts, and the defaults chosen for clarify points left open.

## R1. Page rendering: word-level layout + per-page QCF V2 fonts

- **Decision**: Render each page from QUL's 15-line layout (`pages` table: page, line, type,
  centred, first/last word id) and QUL's QCF V2 word glyphs, one widget per word, using the page's own
  font (`qpc_p<page>`).
- **Rationale**: Gives the exact printed line distribution (Constitution I) and per-word control needed
  later for hiding (self-test) and highlighting (audio). Data verified locally: 9,046 layout rows,
  604 pages, 83,668 words; pages 1–2 have 8 lines; al-Kahf starts on page 293 (line 10), 2:255 on
  page 42, 114:1 on page 604, page 3 holds words 78–215.
- **Alternatives considered**: 604 page images (no word control); Unicode Uthmani text with a generic
  font reflowed into 15 lines (does not reproduce printed line breaks reliably).

## R2. Fonts: WOFF2 → TTF at build time

- **Decision**: Decompress each `p{N}.woff2` with `fontTools.ttLib.woff2.decompress` into
  `assets/fonts/qpc-v2/p{N}.ttf`; load at runtime with `FontLoader('qpc_p$N')`, once per page,
  prefetching N±2.
- **Rationale**: Flutter's font loader accepts TTF/OTF, not WOFF2.
- **Measured size**: samples p1/p50/p300/p604 grow ~1.6× (WOFF2 → TTF); 604 fonts ≈ 150 MB raw TTF
  (WOFF2 total 95 MB). The APK stores assets compressed (~0.66 of TTF on a sample), so expect roughly
  100 MB for fonts in the APK. Acceptable for a private APK (Constitution VIII bundles Quran data).
- **Alternatives considered**: download fonts on demand (breaks fully-offline first use); ship
  compressed fonts and inflate on first launch (doubles install footprint, more code). Revisit only if
  the measured release APK size is a problem (Task 11 records it).

## R3. Surah titles and basmallah: Amiri Quran

- **Decision**: Draw «سورة <name>» boxes and the basmallah line in Amiri Quran (`AmiriQuran.ttf`, SIL
  OFL 1.1), committed with `OFL.txt`.
- **Rationale**: QUL's layout gives these lines no words; QCF V2 page fonts don't carry them. OFL allows
  bundling with attribution.
- **Alternatives considered**: QUL's separate surah-name font (licence also unpublished).

## R4. Metadata: juz, hizb quarter, surah names

- **Decision**: Parse Tanzil `quran-data.js` with regexes only (`Sura`, `Juz`, `HizbQaurter` arrays;
  drop the `[115, 1]` sentinel; expect exactly 240 quarters). A page's juz and quarter are those of its
  first ayah word; `ayahPage` is the page of an ayah's first word.
- **Rationale**: Juz/hizb boundaries are ayah-based and edition-independent; page numbers come from the
  QUL layout, not from Tanzil's own page table (which follows an older print).
- **Alternatives considered**: Tanzil `Page` array (may differ from the 1421H print).

## R5. User data: drift (SQLite)

- **Decision**: drift with tables `Wirds`, `WirdDays`, `Bookmarks`, `Settings` (key/value); tests use
  `NativeDatabase.memory()`.
- **Rationale**: Typed queries, streams for UI updates, transactional import, easy in-memory tests.
- **Alternatives considered**: `sqflite` (no codegen, but untyped and no reactive streams);
  key-value storage only (no transactions for import, awkward per-day rows).

## R6. Reminders: local, inexact, rolling 14-day window + daily background refresh

- **Decision**: `flutter_local_notifications.zonedSchedule` with `timezone` + `flutter_timezone`,
  `AndroidScheduleMode.inexactAllowWhileIdle`; one one-shot notification per wird per day for the next
  14 days (skipping today if done or past), plus each Thursday's al-Kahf reminder (the night of Friday) in that window.
  Cancel-all + reschedule on app start, resume, wird change and «تم», **and once a day in the
  background** via the `workmanager` package (Android WorkManager periodic task, ~24 h, no network
  constraint, survives reboot), so reminders never run out even if the app is not opened
  (clarification 2026-11-20). Manifest:
  `POST_NOTIFICATIONS` (runtime request on Android 13+), `RECEIVE_BOOT_COMPLETED` and the plugin's
  boot receiver so scheduled notifications survive restarts.
- **Rationale**: One-shot daily items let "skip today if already done" work without background code;
  inexact mode avoids the exact-alarm permission; a few minutes' delay is acceptable for reminders.
- **Deleted wird**: deleting a wird cancels its notification ids immediately; a stale `wird:<id>` tap
  for a missing wird opens the reader in browse mode at `lastViewedPage`.
- **Alternatives considered**: repeating daily notification (can't skip a done day); exact alarms
  (extra permission, not needed); background worker re-planning daily (more code and battery).

## R7. Clarify points: answered and defaults

Rows marked *(answered)* were settled by the owner in the 2026-11-20 clarify session and are now in the
spec. The others remain designer defaults; change them by re-running `/speckit-clarify`.

| Point | Default used in this plan |
|---|---|
| Qiyam day boundary *(answered)* | Qiyam wird day starts at 04:00 local; reading wirds at midnight (FR-028). |
| Editing goal / start page mid-day *(answered)* | Open portion: B recalculated now; done portion: from next wird day. Start page edit moves the position now and recreates an open portion (FR-029). |
| «تم» when already past B | Position stays (FR-031: moves only if behind). |
| Bookmarks *(answered)* | One shared list, newest first, with wird name or «عامة»; browse mode or no wird → «عامة» (FR-033). |
| Reminders when the app isn't opened *(answered)* | Daily background refresh keeps them going (FR-037, R6). |
| Default time when turning a new wird's reminder on | 20:00. |
| Hizb in the top bar *(answered)* | «جزء J · حزب H · ربع Q», H 1–60, Q 1–4 (FR-011). |
| Today panel default | Closed on first launch (the Mushaf comes first, Constitution II); opened from a chip in the top bar over the page; its open/closed state is remembered. Decided 2026-11-20 together with the Emerald & Gold design. |
| Night mode, UI fonts | Follow the system light/dark setting; system Arabic UI font; Mushaf fonts as R1/R3. |
| Wird colour | Fixed palette of 8 colours. |
| Ayah-level «علامة» | Not in this feature; bookmarks stay page-level. |

## R8. Licences

- **Decision**: Task 1 creates `docs/research/licenses.md` with four entries: Tanzil metadata (Tanzil
  licence: attribution, no modification), QUL layout + word data and KFGQPC QCF V2 fonts ("no licence
  published; used in a private, non-commercial APK with visible attribution and no modification",
  owner decision 2026-11-20, spec FR-042), Amiri Quran (SIL OFL 1.1).
- Also adds a research note (non-blocking for this feature): Quranpedia gharib al-Quran data — word or
  ayah level? licence? Feature 4 depends on the answer.

## R9. Page direction

- **Decision**: `PageView.builder(reverse: true)` inside `Directionality(textDirection: ltr)`; index 0 is
  page 1. With `reverse`, the next item sits to the left, so a left→right finger fling reveals it.
- **Rationale**: Matches the paper Mushaf and Quran Android (Constitution VI). Verified by a widget test
  (fling +400 px → next page) and on device.
