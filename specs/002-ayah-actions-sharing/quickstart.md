# Quickstart: validating feature 002 (ayah actions and sharing)

How to build the data, run the checks and prove the feature on the owner's phone. Details live in
[contracts/](contracts/) and [data-model.md](data-model.md); this file only says what to run and what to
expect.

## 0. Prerequisites

- Feature 001 assets exist (`assets/mushaf/`, `assets/fonts/qpc-v2/`).
- The owner has approved the four downloads (research.md, last table). Put the files in the git-ignored
  `data-raw/ayah/` with the names in contracts/assets.md.
- `uv`, Flutter 3.50, `adb` with the phone authorised. The phone is a secure-locked device: never unlock it for the owner.

## 1. Build and check the data (FR-013, SC-002, SC-003, SC-009)

```bash
uv run python tool/build_ayah_assets.py
```
Expect: `OK` per check (text 6,236 ayahs / 77,432 words; Tanzil cross-check; tafsir coverage; translation
6,236 lines; gharib entries and the share of ayahs they cover), the raw and gzip size per kind and the total
(≤ 40 MB), and `assets/ayah/` written. Any failure prints its reason and writes nothing.

```bash
uv run --with pytest pytest tool/
```
Expect the existing tests plus `test_build_ayah_assets.py` passing (each check also has a test that feeds it a
broken input and expects the build to stop).

## 2. Automated checks

```bash
flutter analyze
flutter test
```
Expect no analyzer issue and all tests passing, including: the all-6,236-ayahs text integrity test, the share-text
and file-name tests, the A4 layout and PDF writer tests, the PDF job tests (one at a time, cancel leaves no file),
the long-press widget tests (long press opens, tap still toggles bars, drag/fling/pinch never open, banner does
nothing, highlight appears and clears) and the sheet tests (menu, tafsir covers line, translation LTR, meanings
none-line, share buttons call the fake `ShareService` with the exact text).

## 3. On the phone (real device; Constitution IX)

```bash
flutter run --release -d <device>
```
To read the times and keep the files the phone made, build once with the trace switch and follow the log:

```bash
flutter build apk --release --dart-define=AYAH_MENU_TRACE=true
adb logcat -s flutter:I | grep -E "AYAHMENU|PICTURE|PDF"
adb pull /sdcard/Android/data/app.hafiz.mushaf/files/picture-293.png   # the picture as the phone made it
```
The log gives `AYAHMENU ms=` (hold to sheet), `PICTURE page= render_ms= total_ms= bytes=` and
`PDF surah= pages= ms= bytes=`. The switch is off in a normal build: nothing is logged and no copy is kept.
Touch the phone only when the owner says so: it is theirs and stays locked.

Do these in order and write the result in the task list:

1. **Long press feel (SC-001).** Hold on a word of 2:255: the ayah is highlighted, a small tick is felt, the sheet
   opens in under half a second after the hold. Do 50 mixed gestures (taps, swipes, pinch, holds on the banner and
   the page number): a menu opens only for holds on an ayah's words; taps still toggle the bars.
2. **Share the ayah (FR-007).** «مشاركة» → share to a notes app: exactly `﴿ … ﴾` and `[سورة البقرة: 255]`.
3. **Tafsir, translation, meanings (SC-002).** Check by hand 1:1, 2:255, 114:6 and seven more ayahs spread over the Mushaf:
   reference, tafsir, English text and meanings are the right ones; a grouped tafsir shows its covers line; an ayah with no
   difficult word shows «لا توجد كلمات غريبة في هذه الآية»; the tafsir and translation share buttons offer their text
   with the reference and the source name.
4. **Picture (SC-004).** From page 293 choose «مشاركة الصفحة كصورة»: ready in under 3 s, 2000×3000, looks like the app
   page (SC-010: same ivory, gold frame, green banners and dark ink, no fallback red or underline; compare with a
   screenshot of the same page); open it in the gallery and zoom twice: every word sharp. Try pages 1, 2 and 604.
5. **PDF (SC-005).** From an ayah of Al-Baqarah choose «مشاركة السورة PDF»: the strip shows «صفحة N من 48», page turning
   still works meanwhile, done in under 60 s, file under 40 MB, 48 A4 pages in order, in the app's colours (green sheet, ivory page, gold frame), centred.
   Open it in a PDF viewer and print preview. Repeat on Al-Fatiha (1 page) and Al-Ikhlas (page 604 with its neighbours).
   Cancel midway: stops within 2 s, no file offered. Start a second one while the first runs: refused. Lock the
   screen during a PDF: it finishes or resumes, never offers a half file.
6. **Offline (SC-006).** Airplane mode: steps 1–5 behave the same; the app never asks for the network.
7. **Failures (SC-007).** Fill the phone's free space (or use a tiny test quota), start a PDF: the Arabic no-space message,
   reader intact. Close the share sheet without sharing: no message.
8. **Credits (SC-008).** Open About: each bundled source is credited with its link and version, and
   `docs/research/licenses.md` lists them all.

## 4. Done when

Analyzer clean, all tests green, the checks in section 3 passed on the phone, `docs/research/licenses.md` and About
updated, every task committed, `/speckit-converge` reports no gap.
