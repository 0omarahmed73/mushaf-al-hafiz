# Implementation Plan: App Icon and Animated Splash Screen

**Branch**: `009-app-icon-splash` (work stays on `main`) | **Date**: 2026-11-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/009-app-icon-splash/spec.md`

## Summary

The app gets the owner's icon 2 and splash 2. The icon is one drawing kept as data (`lib/splash/icon_geometry.dart`) and
rendered three ways: the five legacy PNGs and the three Android vector layers (background, foreground, monochrome) by a
tool in `tool/`, and the tile of the in-app splash by a painter. The native launch screen is dark in the day and night
resource sets, on Android 12 and later and before. The in-app splash (`lib/splash/`) is a gate, `SplashGate(child,
ready, onFinished)`, wired only in `lib/main.dart`: `main()` now draws the splash first and loads the app behind it
(`_bootApp()`), so loading overlaps the splash; the splash stays at least 0.9 s and until the app is ready, a tap skips the
minimum, reduced motion shows it still for 0.3 s, and it fades out in 0.22 s. Pure parts (timeline, leaving rule, geometry)
are unit-tested; the widget is tested with fake time; the resources are checked by a file test.

## Technical Context

**Language/Version**: Dart 3.14 / Flutter 3.50 (Android first); Android resources (XML, PNG)

**Primary Dependencies**: `package:material_ui` is not used by the splash; it needs only `flutter/widgets`, `flutter/services`
(fonts by family name) and `dart:ui`. Nothing new is added to `pubspec.yaml`: no package, no font, no image asset.

**Storage**: none (no table, no setting, nothing in the backup)

**Testing**: `flutter test test/splash` with new files only; fake time through `tester.pump(Duration)`; accessibility flag
through `platformDispatcher.accessibilityFeaturesTestValue`; resources through `dart:io` and a small XML well-formedness
checker in `test/splash/support/`; a real-device check on the owner's phone (Constitution IX)

**Target Platform**: Android phone 7.0+ (minSdk 24), portrait and landscape, RTL

**Project Type**: mobile app

**Performance Goals**: first Flutter frame no later than today's; the loading work finishes no later than today; the splash
drawn at the display's frame rate (a handful of widgets and three small painters; the glow shadow of the tile is inside a
`RepaintBoundary` and is not repainted per frame)

**Constraints**: offline; no network, no tracking; Quran text, layout, fonts and reading position untouched; earlier tests
unchanged; nothing overflows at 320 × 640 with a 2x system font; text contrast ≥ 4.5:1; no new package; files outside the
allowed list (build.gradle.kts, `lib/mushaf`, `lib/settings`, docs, the constitution, existing tests) untouched

**Scale/Scope**: one gate widget and its helpers (about 8 small files), one tool, eleven resource files, one `main.dart` edit

## Constitution Check

*GATE: passed before research and again after the design (constitution 1.3.0).*

| Principle | Check |
|---|---|
| I Quran text integrity | No Quran text, page, layout or font is touched or drawn by the splash; the Mushaf loads behind it unchanged (FR-018). **Pass** |
| II Mushaf first | The splash is not a menu, list or home screen: it offers no choice, needs no tap, lasts about a second and always hands over to the Mushaf page, already loaded behind it. The reading proposed in the spec (Open question 1) is that this is not the «splash menu» the principle forbids; the owner chose a splash. Recorded as an interpretation, not a deviation, and asked of the owner. **Pass (interpretation to confirm)** |
| III Focus | No other feature, no dua, no hadith. **Pass** |
| IV Offline, private, free | No network, no analytics, no data stored or sent; no new package that could (FR-015, FR-018). **Pass** |
| V Licensing | The icon and splash are the project's own artwork; the fonts are the Reem Kufi and Cairo files already bundled and credited; nothing external is added, so no `licenses.md` entry and no About credit (spec Assumptions). **Pass** |
| VI Arabic, RTL | The splash is RTL; the name is the app's existing name; the one new Arabic string, the tagline, is a proposal in one constants file, listed for the owner (D9). **Pass** |
| VII Reliability | The reading position is not touched; the splash cannot delay the app past loading + the fade, and it never hangs (an error in loading ends it as ready). **Pass** |
| VIII App size | Five small PNGs replace five PNGs, three small vectors added, no asset, no font, no package. **Pass** |
| IX Quality gates | Tests first (the pure rules, then the widget, then the resources); `flutter analyze` clean on the touched files; the icon in the launcher masks, themed mode, the absence of a white flash and the feel of the motion are checked on the phone before the feature is called done (D8). **Pass** |

No deviation, so no Complexity Tracking entry. The feature touches `lib/main.dart`, which feature 008 (first-run tips) will
also edit to use `onFinished`: that is coordination, not a deviation; the edit is kept to one small hunk.

## Project Structure

### Documentation (this feature)

```text
specs/009-app-icon-splash/
├── plan.md              # this file
├── research.md          # decisions D1 to D10 (the two spikes are in D2 and D6)
├── data-model.md        # the timeline frame, the plan constants, the icon geometry
├── quickstart.md        # automated and phone validation
├── contracts/
│   ├── dart-interfaces.md   # signatures the tests are written against
│   └── android-resources.md # the resource files, their required content and the checks
├── checklists/
│   ├── requirements.md      # spec quality (done)
│   └── splash.md            # requirements quality for the plan, from /speckit-checklist
└── tasks.md             # from /speckit-tasks
```

### Source Code (repository root)

```text
lib/splash/
├── splash_strings.dart       # NEW: kSplashName, kSplashTagline (the tagline is a proposal)
├── splash_palette.dart       # NEW: every colour of the icon and the splash (from the design files)
├── splash_plan.dart          # NEW: constants and SplashPlan.mayLeave (pure, no Flutter import)
├── splash_timeline.dart      # NEW: SplashFrame and SplashTimeline (pure)
├── icon_geometry.dart        # NEW: the drawing as data + the path parser
├── app_icon_painter.dart     # NEW: AppIconPainter (CustomPainter)
├── splash_painters.dart      # NEW: background, thin line
├── splash_screen.dart        # NEW: SplashScreen (the animated overlay)
├── splash_gate.dart          # NEW: SplashGate (child under the overlay, onFinished once)
└── app_when_ready.dart       # NEW: AppWhenReady (dark box until the booted app exists)
lib/main.dart                 # EDIT: main() splits into _bootApp() and runApp(SplashGate(...))
tool/
├── app_icon_resources.dart   # NEW: writes the three Android vector layers from the geometry
└── make_app_icons.dart       # NEW: `flutter test tool/make_app_icons.dart` writes the PNGs and the vectors
android/app/src/main/res/
├── drawable/ic_launcher_background.xml        # NEW (generated)
├── drawable/ic_launcher_foreground.xml        # NEW (generated)
├── drawable/ic_launcher_monochrome.xml        # NEW (generated)
├── drawable/launch_background.xml             # REPLACED: dark + centred icon
├── drawable-v21/launch_background.xml         # REPLACED: the same
├── mipmap-anydpi-v26/ic_launcher.xml          # NEW: the adaptive icon
├── mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png  # REPLACED (generated)
├── values/colors.xml                          # NEW
├── values/styles.xml, values-night/styles.xml # REPLACED: dark LaunchTheme and NormalTheme
└── values-v31/styles.xml, values-night-v31/styles.xml   # NEW: Android 12+ system splash
test/splash/
├── support/xml_check.dart                     # NEW: a tiny well-formedness checker
├── support/xml_check_test.dart                # NEW
├── support/pixels.dart                        # NEW: paints a painter or decodes a PNG into pixels
├── support/splash_harness.dart                # NEW: fake-time helpers, finders, window size
├── splash_strings_test.dart                   # NEW (strings, name = title = manifest label, palette)
├── splash_plan_test.dart                      # NEW (pure)
├── splash_timeline_test.dart                  # NEW (pure)
├── icon_geometry_test.dart                    # NEW (parser, radius, design colours)
├── app_icon_painter_test.dart                 # NEW (pixels of the drawn icon)
├── android_icon_resources_test.dart           # NEW (adaptive icon, layers, PNG sizes and palette, generated = committed)
├── android_launch_resources_test.dart         # NEW (dark launch screen in day, night and v31 sets)
├── splash_painters_test.dart                  # NEW (background, thin line)
├── splash_screen_test.dart                    # NEW (content and play)
├── splash_gate_test.dart                      # NEW (child behind, directionality, state kept)
├── app_when_ready_test.dart                   # NEW
├── splash_wiring_test.dart                    # NEW (main.dart wiring, app.dart untouched, imports of lib/splash, pubspec)
├── splash_timing_test.dart                    # NEW (fake time: minimum, ready, tap)
├── splash_media_query_test.dart               # NEW (the gate's own MediaQuery, the production path)
├── splash_reduce_motion_test.dart             # NEW
├── splash_layout_test.dart                    # NEW (320 x 640 at 2x, contrast, semantics, touches, resize)
└── splash_finished_test.dart                  # NEW (onFinished once)
```

**Structure Decision**: one new folder `lib/splash/` holds everything the app runs; the Android files are resources; the tool
in `tool/` writes the generated ones. `lib/main.dart` is the only existing Dart file edited, in one small commit after
`git status` and `git log -- lib/main.dart`, and the feature 008 session is told the exact shape (`SplashGate.onFinished`)
by the coordinator through the report. `lib/app.dart` is not touched.

## Complexity Tracking

No violations to justify.
