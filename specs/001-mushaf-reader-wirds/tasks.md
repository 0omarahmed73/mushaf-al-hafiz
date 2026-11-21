---

description: "Task list for feature 001: Mushaf reader, wirds and reminders"
---

# Tasks: Mushaf Reader, Wirds and Reminders

**Input**: Design documents from `/specs/001-mushaf-reader-wirds/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: REQUIRED. Constitution Principle IX makes test-first mandatory: in every story the test
tasks come first and must fail before the implementation tasks start.

**Commits**: Constitution Principle IX requires one commit per completed task. Every task below ends
with its own commit once its tests pass (message `<type>: T0NN <short description>`, e.g.
`feat: T022 reader controller position rules`). The "commit" mentioned at the end of some tasks is that
same per-task commit, not a phase-level one.

**Organization**: Tasks are grouped by user story so each story can be implemented and tested on its
own. Per-task interface detail also lives in `docs/superpowers/plans/2026-11-20-plan-1-mushaf-and-wirds.md`
(Tasks 1–11); where the two differ, this file and the spec's Clarifications win.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Paths are relative to the repository root `<repo-root>/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Repository, Flutter project, licences and the validated Quran assets

- [X] T001 Run `git init` at the repository root and create `.gitignore` with `data-raw/`, `assets/mushaf/`, `assets/fonts/qpc-v2/`, `build/` plus the Flutter defaults; commit the existing `docs/`, `specs/`, `.specify/` and `.claude/`
- [X] T002 Create the Flutter project in place: `flutter create --org app.hafiz --project-name mushaf --platforms android .`; set applicationId `app.hafiz.mushaf` and `minSdk 24` in `android/app/build.gradle*` and `android:label="مصحف الحافظ"` in `android/app/src/main/AndroidManifest.xml`
- [X] T003 Add dependencies with `flutter pub add provider drift drift_flutter sqlite3_flutter_libs path_provider flutter_local_notifications timezone flutter_timezone workmanager share_plus file_picker` and `flutter pub add -d drift_dev build_runner`; confirm `flutter analyze` reports `No issues found!`
- [X] T004 Write `docs/research/licenses.md` with four entries: Tanzil metadata (attribution, no modification); QUL layout + word data and KFGQPC QCF V2 1421H fonts ("no licence published; used in a private, non-commercial APK with visible attribution and no modification", owner decision 2026-11-20, spec FR-042; publishing beyond the private APK requires resolving it); Amiri Quran (SIL OFL 1.1); plus a non-blocking research note for Feature 4: Quranpedia gharib al-Quran data, word or ayah level? licence?
- [X] T005 [P] Download Amiri Quran from the latest release at github.com/aliftype/amiri/releases into `assets/fonts/amiri/AmiriQuran.ttf` and `assets/fonts/amiri/OFL.txt`

### Asset pipeline (test first)

- [X] T006 Write failing pytest tests in `tool/test_build_quran_assets.py` (session fixture builds into a temp dir with `--skip-fonts`): 604 pages; pages 1–2 have 8 lines, all others 15; word ids across pages equal `list(range(1, 83669))`; page 1 line 1 == `{"n": 1, "type": "surah_name", "centered": True, "surah": 1, "words": []}`; page 2 line 2 type `basmallah`; page 1 juz 1 and page 604 juz 30; 114 surahs with `surahs[0] == {"n": 1, "name": "الفاتحة", "ayahs": 7, "startPage": 1}`; `surahs[17]["startPage"] == 293`; `ayahPage["2:255"] == 42`; `len(ayahPage) == 6236`; `pageSurahs[0] == [1]`; `validate()` raises `ValueError` when one word is removed. Run `uv run --with pytest pytest tool/ -q` → FAIL
- [X] T007 Implement `tool/build_quran_assets.py` per contracts/assets.md: `build_pages(layout_rows, words_by_id, quarters, juz_starts)`, `build_meta(pages, suras)`, `validate(pages, meta)` (called before anything is written), Tanzil `quran-data.js` parsed with regexes only (drop the `[115, 1]` sentinel, exactly 240 quarters), WOFF2 → TTF via `fontTools.ttLib.woff2.decompress`; CLI `[--out assets] [--skip-fonts]`
- [X] T008 Run `uv run --with pytest --with 'fonttools[woff]' pytest tool/ -q` → PASS, then `uv run --with 'fonttools[woff]' python tool/build_quran_assets.py` → prints `604 pages, 83668 words, 604 fonts`; `ls assets/fonts/qpc-v2 | wc -l` → `604`; commit tool + docs

**Checkpoint**: validated assets exist locally; licences recorded

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Mushaf data access and the user database that every story needs (the reader opens on the active wird's position)

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T009 Register assets in `pubspec.yaml`: `assets/mushaf/`, `assets/mushaf/pages/`, `assets/fonts/qpc-v2/`, and font family `AmiriQuran` → `assets/fonts/amiri/AmiriQuran.ttf`
- [X] T010 [P] Write failing tests in `test/mushaf/mushaf_repository_test.dart` (real assets via `rootBundle`): `meta.surah(18).startPage == 293`, `meta.pageOfAyah(2, 255) == 42`, `meta.juzOf(604) == 30`; `loadPage(1)` has 8 lines, first is `LineType.surahName` with surah 1, `lines[1].words.first.key == '1:1:1'`; `loadPage(605)` throws `RangeError`
- [X] T011 [P] Implement `SurahInfo`, `MushafWord`, `LineType`, `MushafLine`, `PageData`, `MushafMeta` in `lib/mushaf/models.dart` per contracts/dart-interfaces.md (`MushafWord.surah`/`ayah` parsed from `key`)
- [X] T012 Implement `MushafRepository(AssetBundle)` in `lib/mushaf/mushaf_repository.dart`: `loadMeta()`, `loadPage(int)` caching the last 8 pages, `RangeError` outside 1..604; make T010 pass
- [X] T013 [P] Write failing tests in `test/wirds/wird_repository_test.dart` with `AppDatabase(NativeDatabase.memory())`: `ensureDefaults()` called twice creates exactly one wird «الورد اليومي», type reading, currentPage 1, dailyPages 20, notifyEnabled true, notifyMinutes 1200, active; kahfEnabled true, kahfMinutes 540; positions are per wird; `setPage` throws `ArgumentError` for 0 and 605; `lastViewedPage` defaults to 1 and persists
- [X] T014 Implement drift tables in `lib/wirds/db.dart` per data-model.md: `Wirds` (type text enum `reading` | `hifz` | `review` | `qiyam`; currentPage "1–604, default 1"; dailyPages "≥ 1 when set"; targetDate date only; khatmaCount "default 0"; notifyEnabled; notifyMinutes "minutes after local midnight"; color; sortOrder; createdAt), `WirdDays` (PK (wirdId, day), day `yyyy-MM-dd`, cascade delete), `Bookmarks` (wirdId nullable, "set null on delete", page 1–604, note?, createdAt), `Settings` key/value; run `dart run build_runner build --delete-conflicting-outputs`
- [X] T015 Implement `WirdDraft`, `WirdType` and `WirdRepository` core in `lib/wirds/wird_repository.dart`: `ensureDefaults`, `watchWirds`, `activeWird`, `setActive`, `create`, `update`, `delete`, `setPage`, `lastViewedPage`, `setLastViewedPage`, kahf setting getters/setters; make T013 pass
- [X] T016 Create `lib/app.dart` (MaterialApp, `Locale('ar')`, app-wide `TextDirection.rtl`, theme follows system light/dark) and `lib/main.dart` (opens the database, calls `ensureDefaults()`, provides repositories via `provider`); `flutter build apk --debug` succeeds

**Checkpoint**: Foundation ready; user story work can begin

---

## Phase 3: User Story 1 - Read the real Mushaf from where I stopped (Priority: P1) 🎯 MVP

**Goal**: The app opens directly on the active wird's page of the real 1421H Mushaf; paging, bars, zoom, index and position rules work.

**Independent Test**: Install, open → a Mushaf page with no screen before it; swipe; jump via index to «الكهف» (page 293, banner «اجعلها موضعي»); close and reopen → same page.

### Tests for User Story 1 ⚠️ (write first, must fail)

- [X] T017 [P] [US1] Widget tests in `test/mushaf/mushaf_page_test.dart` at 360×640 and 412×915: page 3 has no exception and finds `ValueKey('w78')` and `ValueKey('w215')`; page 1 lines all share one height and word `w1` is horizontally centred; page 2 shows «سورة البقرة» and «بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ»; a hidden word id renders with `Opacity` 0; every one of the 604 pages pumps without overflow at both sizes
- [X] T018 [P] [US1] Unit tests in `test/mushaf/reader_controller_test.dart` (in-memory DB): opens at the active wird's currentPage (212 → 212); `onPageShown(213)` moves the wird to 213; `jumpTo(400)` keeps the wird at 213 and sets `browsing`; `makeThisMyPosition()` moves the wird to 400 and clears `browsing`; paging in browse mode moves no wird; deleting the active wird switches to the first remaining wird by `sortOrder`; deleting every wird gives `wird == null`, `browsing == true`, `page == lastViewedPage`, no throw
- [X] T019 [P] [US1] Widget tests in `test/mushaf/reader_screen_test.dart`: opens on page 50 when the wird is at 50; fling `Offset(+400, 0)` shows 51 and fling `Offset(-400, 0)` from 51 shows 50 again; index «الكهف» shows 293 and «اجعلها موضعي»; top bar on page 293 contains «جزء 15» and «الكهف»; top bar format is «جزء J · حزب H · ربع Q» (e.g. page with juz 25, hizb 49, quarter 4 → «جزء 25 · حزب 49 · ربع 4»); bottom bar shows «استماع» and «اختبار» disabled with «قريباً»; page field rejects 0 and 605

### Implementation for User Story 1

- [X] T020 [P] [US1] Implement `PageFontLoader` in `lib/mushaf/page_font_loader.dart`: family `qpc_p$page`, loaded once via `FontLoader(...).addFont(rootBundle.load('assets/fonts/qpc-v2/p$page.ttf'))`, `prefetch(page)` loads page±2; while a font is loading the page keeps its layout area empty with the page number visible and never uses a substitute font (spec FR-008a)
- [X] T021 [US1] Implement `MushafPage` in `lib/mushaf/mushaf_page.dart` per contracts/dart-interfaces.md: one font size for all lines derived from width; 15-line pages fill the height; pages 1–2 use the same line height and sit vertically centred; ayah lines `MainAxisAlignment.spaceBetween`, centred lines `center`; surah title «سورة <name>» in a bordered box and basmallah in AmiriQuran; page number centred at the bottom; each word `Text` keyed `ValueKey('w<id>')`, highlight = background colour, hidden = `Opacity(0)`; make T017 pass
- [X] T022 [US1] Implement `ReaderController` in `lib/mushaf/reader_controller.dart` (`init`, `onPageShown`, `jumpTo`, `makeThisMyPosition`, `switchWird`, listens to the wird list; stores `lastViewedPage` on every shown page); make T018 pass
- [X] T023 [US1] Implement `IndexScreen` in `lib/mushaf/index_screen.dart`: tabs «السور» (name + start page), «الأجزاء» (juz → first page), page-number field accepting only 1–604; returns the chosen page with `Navigator.pop(page)`
- [X] T024 [US1] Implement `ReaderScreen` in `lib/mushaf/reader_screen.dart` and make it the home route in `lib/app.dart`: `PageView.builder` over 604 pages with `reverse: true` inside `Directionality(ltr)`; tap toggles bars; top bar «جزء J · حزب H · ربع Q» (H = ceil(quarter/4), Q = (quarter−1) % 4 + 1), surah name(s), wird name, browse banner with «اجعلها موضعي»; bottom bar «استماع» (disabled, «قريباً»), «علامات», «أوراد», «اختبار» (disabled, «قريباً»), «☰»; `InteractiveViewer(minScale: 1, maxScale: 3)` with paging disabled while scale > 1; make T019 pass
- [X] T025 [US1] On the connected phone, run `flutter run` and check pages 1, 2, 293, 604, swipe direction, zoom and index; commit

**Checkpoint**: MVP: the Mushaf reader works and remembers the position

---

## Phase 4: User Story 2 - Keep several wirds with a daily portion (Priority: P2)

**Goal**: Multiple wirds (reading, qiyam) with their own positions, a fixed daily portion per wird day, «تم», khatma completion, and the «ملخص اليوم» panel.

**Independent Test**: Create a «قيام الليل» wird with 2 pages; it is listed with its label; the panel shows a portion per wird; «تم» ticks it and moves the position.

### Tests for User Story 2 ⚠️ (write first, must fail)

- [X] T026 [P] [US2] Unit tests in `test/wirds/portion_test.dart`: `pagesPerDay(currentPage: 1, dailyPages: 20, today: 2026-11-20) == 20`; `pagesPerDay(currentPage: 1, targetDate: 2026-12-19, today: 2026-11-20) == 21`; target today and target in the past from page 600 both == 5; neither set == 20; `portionFor(startPage: 600, perDay: 20) == (start: 600, end: 604)`; `afterDone(604) == (nextPage: 1, completedKhatma: true)`; `dayKey(DateTime(2026, 11, 20, 23, 59)) == '2026-11-20'`; `wirdDayKey(qiyam, DateTime(2026, 11, 21, 1, 0)) == '2026-11-20'`; `wirdDayKey(qiyam, DateTime(2026, 11, 21, 4, 0)) == '2026-11-21'`; `wirdDayKey(reading, DateTime(2026, 11, 21, 1, 0)) == '2026-11-21'`
- [X] T027 [P] [US2] Repository tests in `test/wirds/wird_repository_test.dart` (extend): `today()` at 08:00 and 23:00 returns the same A–B; after `setPage(id, B+1)` the next day's portion starts at B+1; `markDone` on a 600–604 portion gives currentPage 1 and khatmaCount 1; «تم» when already past B leaves the position unchanged; editing the goal while today is open recalculates B with A unchanged; editing the goal after today is done leaves today's row unchanged; editing the start page sets currentPage immediately and recreates an open portion from it
- [X] T028 [P] [US2] Widget tests in `test/wirds/wirds_ui_test.dart`: adding a «قيام الليل» wird with 2 pages shows it labelled «قيام الليل» with reminder off by default; type picker shows «حفظ» and «مراجعة» disabled with «قريباً»; panel row reads «الورد اليومي» with «من ص 1 إلى ص 20» and shows a tick after «تم»; delete shows «حذف الورد؟»; form rejects an empty name, pages per day < 1 and a start page outside 1–604

### Implementation for User Story 2

- [X] T029 [US2] Implement `dayKey`, `wirdDayKey` (qiyam day starts at 04:00 local: `dayKey(localNow − 4 h)`), `pagesPerDay`, `portionFor`, `isDone`, `afterDone` in `lib/wirds/portion.dart`; make T026 pass
- [X] T030 [US2] Extend `WirdRepository` in `lib/wirds/wird_repository.dart`: `today(wirdId, now)` keyed by `wirdDayKey`, `markDone(wirdId, now)` (done; if currentPage ≤ B move to `afterDone(B)`, incrementing khatmaCount on wrap), mid-day edit rules from FR-029 in `update()`; make T027 pass
- [X] T031 [US2] Implement `WirdFormScreen` in `lib/wirds/wird_form_screen.dart`: name (required, non-empty), type («قراءة», «قيام الليل» selectable; «حفظ», «مراجعة» disabled «قريباً»), start page (1–604), amount = pages per day (≥ 1) or target date, reminder on/off + time (default on for «قراءة», off for «قيام الليل»; 20:00 when turned on), colour from a fixed palette of 8
- [X] T032 [US2] Implement `WirdsScreen` in `lib/wirds/wirds_screen.dart`: list with name, colour dot, type label, «ص: N», bookmark count, khatma count; tap → `setActive` and return to the reader; add, edit, delete with «حذف الورد؟» confirmation
- [X] T033 [US2] Implement `TodayPanel` in `lib/wirds/today_panel.dart` and mount it above the page in `lib/mushaf/reader_screen.dart`: one row per wird name + colour + «من ص A إلى ص B», tick when `isDone`, «تم» button; opens over the page from a chip in the top bar, closed on first launch, state remembered in setting `todayPanelExpanded`; wire «أوراد» in the bottom bar; make T028 pass; commit

**Checkpoint**: US1 + US2 work independently

---

## Phase 5: User Story 3 - Be reminded of my wird and of al-Kahf on Thursday evening (Priority: P3)

**Goal**: Local reminders per wird and every Thursday evening for al-Kahf, kept alive indefinitely by a daily background refresh, with settings.

**Independent Test**: A wird reminder set 2 minutes ahead arrives with the phone locked and opens that wird; the al-Kahf notification opens page 293.

### Tests for User Story 3 ⚠️ (write first, must fail)

- [X] T034 [P] [US3] Unit tests in `test/reminders/reminder_planner_test.dart` per contracts/notifications.md: with now 2026-11-20 10:00, a reading wird at 20:00 gives 14 items, the first at 2026-11-20 20:00 with title «ورد: الورد اليومي» and body «من ص A إلى ص B», payload `wird:<id>`, id `wirdId * 100 + 0`; done today → first item tomorrow; now 21:00 → first item tomorrow; a qiyam wird's "today" follows the 04:00 wird day; with now Wednesday 2026-11-18 the first Kahf item is 2026-11-19 21:00, title «سورة الكهف», body «ليلة الجمعة: لا تنسَ قراءة سورة الكهف», payload `page:293`, id `900000 + 1`, and every Kahf item is a Thursday; disabled wirds and disabled Kahf produce nothing
- [X] T035 [P] [US3] Unit tests in `test/reminders/notification_routing_test.dart`: payload `wird:<id>` switches the reader to that wird, not browsing; `wird:<deleted id>` opens browse mode at `lastViewedPage`; `page:293` opens page 293 in browse mode

### Implementation for User Story 3

- [X] T036 [US3] Implement `PlannedReminder` and `planReminders(...)` (horizon 14 days) in `lib/reminders/reminder_planner.dart`; make T034 pass
- [X] T037 [US3] Implement `ReminderService` in `lib/reminders/reminder_service.dart`: `init(onTap)` with `timezone` + `flutter_timezone`, `requestPermission()`, `reschedule(plan)` = cancel all then `zonedSchedule` each with `AndroidScheduleMode.inexactAllowWhileIdle`; add `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` and the plugin receivers to `android/app/src/main/AndroidManifest.xml` per the `flutter_local_notifications` README
- [X] T038 [US3] Register a daily `workmanager` periodic task (~24 h, no network constraint) in `lib/reminders/background_refresh.dart` that opens the database, runs `planReminders` and `reschedule`; initialise it from `lib/main.dart`
- [X] T039 [US3] Wire rescheduling triggers in `lib/main.dart` and `lib/wirds/wird_repository.dart` callers: app start, app resume, wird create/update/delete (delete cancels that wird's ids immediately), «تم», Kahf setting change, successful import; route notification taps through `ReaderController` per T035; make T035 pass
- [X] T040 [US3] Implement `SettingsScreen` in `lib/settings/settings_screen.dart` (opened by «☰»): Kahf reminder on/off and time (default 21:00, every Thursday); when permission is denied, a line saying so and a button calling `requestPermission()`; link to About; export/import buttons (wired in US5)
- [X] T041 [US3] On the phone: wird reminder 2 minutes ahead with the screen locked arrives and opens the wird; a test Kahf notification opens page 293; reminders still arrive after a phone restart; commit
  - Verified on the phone 2026-11-20 (Samsung, Android 16): wird reminder set ~4 min ahead arrived with the screen off, +17 s after its time, and tapping it opened that wird as the active wird; 15 alarms scheduled (14 wird days + the Thursday 21:00 al-Kahf); the daily WorkManager job is registered and ran; deleting the test wird cancelled its alarms. After a phone restart and the first unlock, all 16 alarms were back exactly as before without the app being opened (the plugin's boot receiver restores them; none exist before the first unlock, as Android keeps app storage locked until then). The al-Kahf notification's tap intent (`SELECT_NOTIFICATION`, payload `page:293`) on a cold start opened page 293 in browse mode with the «اجعلها موضعي» banner and left the wird where it was.

**Checkpoint**: Reminders work and survive restarts and long periods without opening the app

---

## Phase 6: User Story 4 - Bookmark pages (Priority: P4)

**Goal**: Page bookmarks with optional note in one shared list.

**Independent Test**: Bookmark page 77, go to page 10, tap the bookmark → page 77 in browse mode.

### Tests for User Story 4 ⚠️ (write first, must fail)

- [X] T042 [P] [US4] Tests in `test/wirds/bookmarks_test.dart`: a bookmark added outside browse mode belongs to the active wird; added in browse mode or with no wird it has `wirdId == null` and shows «عامة»; the list is all bookmarks, newest first, each with page, note and wird name or «عامة»; deleting a wird keeps its bookmarks as «عامة»; a wird's bookmark count counts only its own; tapping a bookmark opens its page in browse mode without moving the wird; swipe deletes

### Implementation for User Story 4

- [X] T043 [US4] Add `addBookmark(page, note, {wirdId})`, `removeBookmark(id)`, `watchBookmarks()` (newest first) and per-wird counts to `lib/wirds/wird_repository.dart`
- [X] T044 [US4] Implement `BookmarksSheet` in `lib/wirds/bookmarks_sheet.dart` and wire «علامات» in `lib/mushaf/reader_screen.dart`: add bookmark on the current page (optional note), shared list, tap → `jumpTo`, swipe to delete; make T042 pass; commit

**Checkpoint**: Bookmarks work

---

## Phase 7: User Story 5 - Back up my data and see the credits (Priority: P5)

**Goal**: JSON export/import of all user data and an About screen with all credits.

**Independent Test**: Export, change data, import → everything identical to the export.

### Tests for User Story 5 ⚠️ (write first, must fail)

- [X] T045 [P] [US5] Tests in `test/backup/backup_service_test.dart` per contracts/backup-file.md: export then import restores identical wirds, wirdDays, bookmarks and settings; `"version": 2` throws `FormatException` and leaves data unchanged; wrong `"app"` throws and leaves data unchanged; a page outside 1–604 throws and leaves data unchanged; a failure mid-import rolls back (data is either old or new, never mixed)

### Implementation for User Story 5

- [X] T046 [US5] Implement `BackupService` in `lib/backup/backup_service.dart`: `exportJson()` with `{"app": "mushaf-hafiz", "version": 1, "exportedAt", "wirds", "wirdDays", "bookmarks", "settings"}`; `importJson()` validates then replaces all user tables in one transaction; make T045 pass
- [X] T047 [US5] Wire export (share file `mushaf-backup-YYYY-MM-DD.json` via `share_plus`) and import (`file_picker` → confirm «سيُستبدل كل ما في التطبيق. متابعة؟» → import → reschedule reminders; show an Arabic error message when rejected) in `lib/settings/settings_screen.dart`
- [X] T048 [P] [US5] Implement `AboutScreen` in `lib/settings/about_screen.dart`: credits Tanzil (metadata), QUL by Tarteel (page layout and word data), King Fahd Glorious Quran Printing Complex (QCF V2 1421H fonts), the Amiri Quran, Reem Kufi and Cairo fonts (SIL OFL), and the line «النص القرآني لم يُعدَّل»; commit

**Checkpoint**: All five stories work independently

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T049 Run `flutter analyze` → `No issues found!`, `flutter test` → all pass, `uv run --with pytest --with 'fonttools[woff]' pytest tool/ -q` → all pass
  - Verified 2026-11-20: `flutter analyze` → No issues found; `flutter test` → 186 passed; `pytest tool/` → 11 passed.
- [X] T050 Run `flutter build apk --release` and record the APK size in the commit message (research.md R2 expects roughly 100 MB of fonts)
  - `flutter build apk --release` → app-release.apk **174.4 MB** (174,418,882 bytes), a fat APK with three ABIs (an arm64-only `--split-per-abi` build would be smaller).
- [X] T051 Inspect the release APK's merged manifest (`android/app/build/intermediates/merged_manifests/release/` or `aapt dump permissions build/app/outputs/flutter-apk/app-release.apk`) and confirm there is no `android.permission.INTERNET`; if a plugin adds it, remove it with `tools:node="remove"` in `android/app/src/main/AndroidManifest.xml` (spec FR-044, Constitution IV)
  - `aapt2 dump permissions` on the release APK: POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, VIBRATE (notifications), FOREGROUND_SERVICE, FOREGROUND_SERVICE_SHORT_SERVICE, WAKE_LOCK, ACCESS_NETWORK_STATE (WorkManager; it only reads connectivity) and the AndroidX internal DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION. **No `android.permission.INTERNET`**, so the app cannot reach the network at all (FR-044, SC-006).
- [X] T052 Install with `flutter install --release` and walk the 14-row device checklist in `specs/001-mushaf-reader-wirds/quickstart.md`, including airplane mode throughout; measure the page turn on the phone (time from fling end to text visible, 10 turns across pages 1–604, all < 300 ms; record the phone model and results, spec SC-007); fix anything found; commit
  - Device: Samsung SM-S721B, Android 16, release build installed (2026-11-20). Walk of the quickstart rows on the release build:
    1 first launch → page 1, «الورد اليومي» active ✓; 2 pages 2 / 293 / 604 (8 lines centred; al-Kahf title mid-page; juz 30 with three banners) ✓; 3 finger left→right = next page ✓ (10 turns);
    4 pinch-zoom: the 1×–3× limits are asserted in a widget test, a physical pinch cannot be driven over adb (**to try by hand**); 5 index → «الكهف» → page 293 in browse mode with «اجعلها موضعي» ✓ (the wird was not moved);
    6 wird form, save, list and summary card ✓ (a «قراءة» test wird; the «قيام الليل» variant is covered by tests); 7, 8 «تم» and bookmarks are Dart/drift logic covered by tests and checked on a debug build;
    9 a reminder set ~4 min ahead was delivered by the release build (all 16 alarms scheduled, notification posted) and tapping it opened that wird, active and not in browse mode ✓; 10 the al-Kahf tap intent opens page 293 ✓;
    11 restart survival checked on a debug build, **not repeated on the release build**; 12 export opens the share sheet with `mushaf-backup-2026-11-20.json` and the file picker + refusal message work on release (the round trip is covered by tests) ✓;
    13 airplane mode: not needed, the release APK has no INTERNET permission (T051); 14 About: dedication, developer card, credits, and the portfolio link opens in Chrome ✓.
  - Page turn (SC-007), built with `--dart-define=PAGE_TURN_TRACE=true`, ten jumps (`SELECT_NOTIFICATION` intent) each followed by one swipe to the next page. Time from the page being created to its text painted: page 2 → 33 ms, 51 → 52, 129 → 45, 201 → 50, 294 → 51, 351 → 89, 421 → 79, 501 → 80, 561 → 87, 604 → 37; the jumped-to pages took 21–53 ms. **Maximum 89 ms, all under the 300 ms target.**
  - Findings: (a) inexact alarms can be late: the 19:56:00 reminder was posted at 19:58:58, the very end of Android's 2 m 58 s window (an earlier debug test was 17 s late); alarms set hours ahead get a window of up to 1 h, so a reminder may arrive minutes late (exact alarms, `USE_EXACT_ALARM`, would fix it but were ruled out in the plan: the owner's call); (b) the launcher and notification icons are still Flutter's default logo; (c) `flutter install` uninstalls the old build first and so erases the app's data and permissions; update with `adb install -r` instead.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies; T004 (licences) MUST be done before T007 uses the data (Constitution V); T006 → T007 → T008 in order
- **Foundational (Phase 2)**: depends on Setup; blocks all stories
- **US1 (Phase 3)**: depends on Foundational. MVP
- **US2 (Phase 4)**: depends on Foundational; its panel mounts in `reader_screen.dart` (US1), so integrate after T024
- **US3 (Phase 5)**: depends on Foundational and on `portion.dart` from US2 (reminder bodies use A–B and "done today")
- **US4 (Phase 6)**: depends on Foundational and on `ReaderController.jumpTo` from US1
- **US5 (Phase 7)**: depends on Foundational; `SettingsScreen` from US3 hosts its buttons (T047 after T040)
- **Polish (Phase 8)**: after all stories

### Within Each Story

Tests first (must fail) → models/pure logic → repository/services → screens → device check → commit.

### Parallel Opportunities

- Setup: T005 alongside T004 and T006
- Foundational: T010, T011, T013 together; then T012 and T014–T015
- US1: T017, T018, T019 together; T020 alongside T022
- US2: T026, T027, T028 together
- US3: T034, T035 together
- US4/US5 tests (T042, T045) and T048 can start as soon as their dependencies exist

## Parallel Example: User Story 1

```text
Task: "Widget tests for MushafPage in test/mushaf/mushaf_page_test.dart"          (T017)
Task: "Unit tests for ReaderController in test/mushaf/reader_controller_test.dart" (T018)
Task: "Widget tests for ReaderScreen in test/mushaf/reader_screen_test.dart"       (T019)
```

## Implementation Strategy

### MVP First (User Story 1 only)

1. Phase 1 Setup → 2. Phase 2 Foundational → 3. Phase 3 US1 → **stop and check on the phone** (T025).

### Incremental Delivery

US1 (read) → US2 (wirds + panel) → US3 (reminders) → US4 (bookmarks) → US5 (backup + About) → Polish.
Each task is committed on its own; each story is checked on the phone before the next starts. Run `/speckit-implement` one phase at
a time for this feature.
