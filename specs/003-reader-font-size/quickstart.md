# Quickstart: validating feature 003

Prerequisites: feature 002 assets built (`uv run python tool/build_ayah_assets.py`), `flutter pub get`.

## 1. Automatic checks

```bash
flutter analyze
flutter test test/settings test/mushaf test/ayah test/render test/backup
flutter test
```
Expected: analyze clean; all tests pass, including the unchanged feature 001 and 002 tests (SC-008). The
layout-invariance test covers 604 pages x 8 sizes (SC-003) and the render test proves the picture and the print
page do not depend on the setting (SC-007).

## 2. On the phone (release build, owner's phone; never touch the phone without the owner's go-ahead)

```bash
flutter build apk --release --dart-define=PAGE_TURN_TRACE=true
adb -s <phone> install -r build/app/outputs/flutter-apk/app-release.apk
```

| Check | Expected | Spec |
|---|---|---|
| Settings → «حجم الخط»: move the slider | the preview changes with the finger; value shows `NN%` | FR-001, FR-002, SC-002 |
| Close and reopen the app | the size is kept | FR-003, SC-005 |
| Long-press an ayah → «التفسير», «الترجمة», «معاني الكلمات» at 150% and 80% | panel text bigger / smaller; header and rows unchanged; longest tafsir (2:282 area) scrolls to its end | FR-006, SC-004 |
| Page 1, 2, 293, 604 at 150% portrait | page bigger, lines identical to 100%, drag moves it up/down/sideways, stops at the frame edges | FR-007, FR-008, FR-009 |
| At 150%, from the left edge swipe left→right | next page, shown at its top and right side; from the right edge right→left → previous page | FR-008, SC-009 |
| At 150%, drag sideways without reaching an edge | no page turn | spec edge case |
| At 150% long press a word, tap the number, tap the surah name, tap the page | menu + highlight, go-to popup, surahs list, bars toggle | FR-010 |
| Pinch at 150% | zoom up to 3x of the bigger page, pager locked, returns on pinch out | FR-010 |
| Rotate at 80%, 100%, 150% | page complete and reachable | edge cases |
| Page-turn trace (`adb logcat | grep PAGETURN`) at 80%, 100%, 150% | under 300 ms; record numbers in research.md D7 | SC-006 |
| «الحجم الافتراضي» | everything back to today's look | FR-004, FR-005 |
| Share a page picture and the Al-Fatiha PDF at 150% | same as at 100% | SC-007 |
| Settings → export, change the size, import | the exported size returns | FR-013, SC-005 |
| Airplane mode | nothing changes | SC-010 |

### Driving the phone with `adb` (what the first run taught)

Only with the owner's go-ahead and the phone unlocked by the owner. Use **browse mode** (open a surah from the
index or a page from the «صفحة» tab) so the wird position never moves; never tap «اجعلها موضعي». The screen is
1080 x 2340: the hamburger is at (112, 2110), the Settings slider's track runs from x = 957 (80%) to x = 122 (150%)
at y = 907, the Settings back arrow is at (1000, 170), the surah name that opens the index at (960, 150). An edge
turn at 150% is a `swipe` of 300-500 px along y = 1000 that starts with the page already against that edge; a long
press is a `swipe` with equal start and end and a 900 ms duration. `adb logcat -d | grep PAGETURN` gives the trace.
Pinch, rotation, closing the app, the share sheet, export/import and airplane mode are done by hand.
