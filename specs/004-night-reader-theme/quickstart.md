# Quickstart: validating the Night Reader look

Prerequisites: Flutter 3.50 on the PATH, the repository at `<repo-root>`, for the phone checks the
owner's phone `<phone>` with USB debugging (never unlock it; ask before sending input). Contracts:
[contracts/dart-interfaces.md](contracts/dart-interfaces.md), [contracts/ui.md](contracts/ui.md); data:
[data-model.md](data-model.md).

## Automated

```bash
cd <repo-root>
flutter analyze
flutter test test/look test/settings test/mushaf test/render test/pdf test/wirds test/ayah test/backup
flutter test            # everything, Emerald tests unchanged
FULL_LAYOUT_CHECK=1 flutter test test/mushaf/page_layout_both_looks_test.dart   # all 604 pages, both looks (slow)
```

| # | Scenario | Test (new files only) | Expected |
|---|---|---|---|
| Q1 | The look model and its stored value | `test/look/look_choice_test.dart`, `look_settings_test.dart` | missing, empty, `purple` read as Emerald; `set` saves and notifies once; `reload` picks up a changed row |
| Q2 | Emerald is today's look | `test/look/emerald_identity_test.dart` | every `AppLook.emerald` token equals its `AppColors` value; `buildAppTheme()` has today's scheme; every earlier test passes unchanged |
| Q3 | Night contrast | `test/look/contrast_test.dart` | `contrastRatio` known values; every `AppLook.night.requiredPairs` meets its minimum; the decorative hairlines are listed |
| Q4 | Wird marker colours | `test/look/wird_marker_test.dart` | all 8 palette colours at 3:1 or more on `#161B22` in Night, unchanged in Emerald, still pairwise different |
| Q5 | Settings row and live switch | `test/settings/look_tile_test.dart`, `settings_look_test.dart` | two options, selected mark, 48 px targets, no overflow at 320 dp with the largest font; choosing Night changes the open Settings screen and the reader behind it at once; the choice survives a new `MushafApp` on the same database |
| Q6 | Screens in both looks | `test/wirds/wirds_night_test.dart`, `test/ayah/ayah_night_test.dart`, `test/settings/about_night_test.dart`, `test/mushaf/reader_night_test.dart` | each screen of FR-004 has no ivory block in Night, correct tokens, no overflow; Emerald as before |
| Q7 | The page in Night and layout invariance | `test/mushaf/page_look_night_test.dart`, `page_layout_both_looks_test.dart` | no paper and no frame painted, same `line-N` boxes and word boxes as Emerald, 6,236 end markers, highlight visible |
| Q8 | Picture and PDF in Night | `test/render/page_renderer_night_test.dart`, `test/pdf/pdf_job_night_test.dart` | background, ink, teal and hairline colours present in the render; the PDF sheet is the Night background; a look change after `start` does not change the running job |
| Q9 | Backup | `test/backup/backup_look_test.dart` | export contains `appLook`; a backup without it keeps Emerald; `"purple"` gives Emerald without error; importing `night` switches the open Settings |

## On the phone (owner's phone; real-device gate, Constitution IX)

1. Install the release build; open Settings, choose «القارئ الليلي»: the screen changes at once, then open every
   screen of FR-004 in turn and photograph it (screenshots via `adb exec-out screencap`).
2. Close the app, open it again: it starts in Night with no frame of the other look (watch the first second).
3. Reader: long press an ayah, see the highlight on the dark page, tap to hide the bars, swipe a page, pinch to 3x.
4. Share a page picture and a surah PDF in Night; open both in the share target; check the colours and the time and
   size (picture under 3 s, Al-Baqarah PDF under 60 s, as in feature 002).
5. Rotate, set the largest system font, open Settings and Wirds on the smallest window: nothing overflows.
6. Switch back to «زمردي وذهبي»: every screen is as before this feature.

Record the numbers and the findings in `research.md` (D12).
