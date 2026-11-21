# Quickstart: build, run and validate

## Prerequisites

- Flutter 3.50 stable with the Android toolchain (`flutter doctor` shows Android ✓); a connected
  Android phone with USB debugging.
- `uv` (for Python + `fonttools[woff]` + `pytest`).
- Raw data present in `data-raw/` (`qul/`, `quran-data.js`, `quran-uthmani.txt`).

## 1. Generate and validate the Quran assets

```bash
uv run --with pytest --with 'fonttools[woff]' pytest tool/ -q
uv run --with 'fonttools[woff]' python tool/build_quran_assets.py
```

Expected: tests pass; the build prints `604 pages, 83668 words, 604 fonts`; `ls assets/fonts/qpc-v2 | wc -l` → `604`.
Format and validation rules: [contracts/assets.md](./contracts/assets.md).

## 2. App tests and analysis

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter analyze
```

Expected: all tests pass; `No issues found!`.

## 3. Release build

```bash
flutter build apk --release
```

Record the APK size (fonts alone are expected to add roughly 100 MB; see research.md R2).

## 4. Device validation (maps to Success Criteria)

Install with `flutter install --release`, then check:

| # | Scenario | Expected |
|---|---|---|
| 1 | First launch | Page 1 directly, «الورد اليومي» active (SC-001) |
| 2 | Pages 1, 2, 293, 604 | 1–2 centred and not stretched; 293 shows the al-Kahf title mid-page; 604 is juz 30 |
| 3 | Swipe finger left→right | Next page |
| 4 | Pinch-zoom | Up to 3×, no paging while zoomed |
| 5 | Index → «الكهف» | Page 293, banner «اجعلها موضعي»; tap it → wird moves to 293 |
| 6 | Add a «قيام الليل» wird, 2 pages | Listed with its label; the «ملخص اليوم» card (chip in the top bar) shows its portion (SC-003) |
| 7 | «تم» on a portion | Tick; position moves to the page after B |
| 8 | Bookmark page 77, go to 10, tap it | Page 77 in browse mode |
| 9 | Wird reminder 2 minutes ahead, lock phone | Arrives; tap opens that wird (SC-004) |
| 10 | al-Kahf notification (Thursday 21:00; or its tap intent) | Opens page 293 in browse mode |
| 11 | Restart phone | Scheduled reminders still arrive |
| 12 | Export → change data → import | Data identical to the export (SC-005); backup format: [contracts/backup-file.md](./contracts/backup-file.md) |
| 13 | Airplane mode through all of the above | Nothing changes (SC-006) |
| 14 | About | The dedication, the developer card with its three links, six credits (Tanzil, QUL, King Fahd Complex, Amiri Quran, Reem Kufi, Cairo) and «النص القرآني لم يُعدَّل» |

## 5. Measuring a page turn (SC-007)

Build with the trace on and watch the log while turning pages on the phone:

```bash
flutter build apk --release --dart-define=PAGE_TURN_TRACE=true
adb logcat -s flutter | grep PAGETURN
```

Each page logs `PAGETURN page=<n> ms=<t>`: the time from the page being created (when the swipe starts and
it begins to slide in) to its text being painted. That is longer than "from the end of the fling", so
staying under 300 ms here means the target is met. Measure at least 10 turns spread over pages 1–604
and note the phone model.
