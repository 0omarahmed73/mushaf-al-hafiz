# Research: App Icon and Animated Splash Screen (feature 009)

Decisions made while planning, on 2026-11-21, after reading `lib/main.dart`, `lib/app.dart`, `lib/theme.dart`,
`pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, the five files under `android/app/src/main/res/`,
`MainActivity.kt`, `android/app/build.gradle.kts` (read only; another session owns it), the design files
`Icon2.dc.html` and `Splash2.dc.html`, and after two throw-away spikes (D2, D6). Nothing here needs the owner's answer
except the four open questions at the end of the spec; each has a default.

## D1. Where the splash sits and how the app boots

Today `main()` opens the database, loads defaults, starts reminders, cleans the share folder, reads the text size
and the look, and only then calls `runApp`. Until then the phone shows the native launch screen, so a splash drawn
by Flutter could not overlap that loading; it would only add its length on top.

**Decision**: split `main()` in two inside `lib/main.dart`. `main()` becomes

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = _bootApp();                       // the old body, returning the MushafApp instead of runApp-ing it
  runApp(SplashGate(ready: app, child: AppWhenReady(app)));
}
```

`_bootApp()` is the old body unchanged, ending in `return MushafApp(...)`. The first Flutter frame (the splash) is
now drawn while the database and the rest load behind it, so the loading finishes no later than before (it starts
in the same turn) and the first frame is earlier than before (FR-016). `SplashGate` lays the child under the splash
in a `Stack`; `AppWhenReady` shows a dark box until the future completes and then the app.

**Alternatives rejected**
- Keep loading before `runApp` and wrap the finished `MushafApp` in the gate: the splash then costs its full length
  on top of the load, and the native screen stays up for the whole load (worse than today for the first frame).
- Put the gate in `MushafApp` (`MaterialApp.builder` or `home`): touches `app.dart`, changes the widget tree every
  existing test pumps, and a gate inside the `Navigator` makes the splash a route before the reader.
- A splash route pushed over the reader: the same, plus a back-button path out of the splash.

**Why the gate may sit above `MaterialApp`**: it needs only `Directionality`, `MediaQuery` and explicit text styles,
all of which it provides itself (D4); it uses no theme, no localisation and no provider, so it cannot be affected by
the app look (FR-008, FR-015).

## D2. The clock, the minimum time and the exit

**Spike** (throw-away widget test, deleted afterwards): a bare `pumpWidget` has a `MediaQuery` above it in tests
(`MediaQuery.maybeOf` is non-null), `MediaQueryData.fromView(View.of(context))` works, setting
`tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: true)` makes
`disableAnimations` true after one pump, `tester.view` can set 320 × 640, and `tester.runAsync` lets
`Picture.toImage(...).toByteData(png)` run. In production `runApp` does not provide a `MediaQuery` above the root, so
the gate wraps its splash in `MediaQuery.fromView` when `MediaQuery.maybeOf` is null (it also then follows later
changes of the accessibility flags).

**Decision**: one `AnimationController` is the clock of the splash. Full motion: duration 1400 ms, the elapsed
`Duration` of the ticker is compared with the 900 ms minimum; reduced motion: duration 300 ms, no painting from it.
A second controller (220 ms) fades the splash out. No `Timer`, so tests use `tester.pump(Duration)` only.
The pure rule `SplashPlan.mayLeave(elapsed, ready, skipped, reducedMotion)` answers when to start leaving:
`ready && (skipped || elapsed >= minimum)`; it is called after every tick and after every change of `ready` or a tap.
On reaching it: reduced motion removes the splash at once; otherwise the 220 ms fade runs and then the splash is
removed and `onFinished` is called once (after the removal rebuild, from a post-frame callback).

**Why elapsed time of the ticker and not wall time**: it stops when frames stop (an app in the background), so a
splash never "uses up" its minimum while hidden, and it is exactly what fake time advances.

**Alternatives rejected**: a `Timer` plus a controller (two clocks that can disagree; the exact-boundary test then
needs two pumps); `Future.delayed` (untestable without extra plumbing); the 1.4 s controller alone with leaving at its
end (would make a ready app wait 0.5 s for nothing).

## D3. Choreography (the pure timeline)

`SplashTimeline.at(Duration elapsed)` returns one immutable `SplashFrame`; the widget only paints it. Beats in ms
from the first frame, with easing and no bounce (FR-009):

| Part | From | To | Motion |
|---|---|---|---|
| background glow (the radial gradient) | 0 | 500 | fades in from the flat #0D1014 of the native screen |
| tiny stars | 150 | 650 | fade in |
| tile | 0 | 600 | opacity 0 → 1 (easeOut), scale 0.92 → 1 (easeOutCubic) |
| star twinkle | 400 | 800 | one pulse: scale 1 → 1.3 → 1 and a teal halo 0 → 0.45 → 0 (sine, once) |
| name | 350 | 800 | opacity 0 → 1, rises 14 px (easeOutCubic) |
| line | 450 | 900 | opacity 0 → 1, rises 10 px |
| thin line | 0 | 1400 | fill 0 → 1 (easeOutCubic): 95% at 900 ms |

Everything but the thin line is settled at 900 ms, the minimum time, so a splash that leaves at 900 ms never cuts a
move short. After 1400 ms the frame stays final. Reduced motion paints `SplashTimeline.finalFrame` (everything
visible, thin line full) and never calls `at`. Tests assert: each value stays in its range, monotone where the beat is
a one-way move, equal to the final frame from 900 ms (except the thin line) and from 1400 ms (all), and the first
frame shows nothing but the flat background.

## D4. Self-contained widget (no theme, no provider, no package)

The splash draws with `CustomPainter` (icon art, background, thin line), `Transform`/`Opacity` (tile, name, line) and
`Text` with explicit `TextStyle`s: `fontFamily: 'ReemKufi'` with `fontVariations: [FontVariation('wght', 700)]` at
44 px and `fontFamily: 'Cairo'` at 15 px, colours from `splash_palette.dart`, `decoration: TextDecoration.none`.
The two family names are the ones `lib/theme.dart` and `pubspec.yaml` already declare; the splash does not import
`theme.dart`, so a change of the app look cannot reach it. Direction is `TextDirection.rtl` set by the gate (the
Arabic text and the Stack both need one, and no `MaterialApp` is above). The name sits in a `FittedBox(scaleDown)` and
the whole column in a `FittedBox(scaleDown)` as a safety net, so a 2x system font on 320 × 640 can never overflow
(FR-014); the system text scale is read from the `MediaQuery` and is not capped, the box scales the result down.

**Alternatives rejected**: `flutter_svg`/`flutter_native_splash`/`flutter_launcher_icons` (forbidden by the brief, and a
dependency for one picture); Lottie/Rive (heavier than the whole feature); a pre-rendered PNG tile (a second copy of
the drawing that could disagree with the icon).

## D5. One drawing for the launcher icon, the splash tile and the vector layers

`lib/splash/icon_geometry.dart` holds the drawing as data: the SVG path strings of `Icon2.dc.html` (absolute `M L C Z`
only), their fills and strokes, the star as two squares plus a hole, and the colours. A 30-line parser turns a path
string into a `ui.Path`. Three consumers:

1. `AppIconPainter` (splash tile and the PNG tool) draws it with the design's scale 0.9 on the 108 canvas;
2. `tool/app_icon_resources.dart` writes the Android vector layers from the same strings, with the adaptive scale
   0.85 (the foreground must sit inside the 66 dp circle: the minimal enclosing circle of the art at scale 1 has a
   radius of 37.95 on the 108 canvas; × 0.9 would be 34.2, over 33; × 0.85 is 32.3, inside);
3. the tests compare the committed XML with what the tool would write, and measure the real radius.

The star's eight-point outline for the monochrome layer is computed, not drawn by eye: outer radius 6·√2 = 8.4853 at
multiples of 45°, inner radius 6/cos 22.5° = 6.4944 at 22.5° + multiples of 45°, centred on (54, 25).

**Alternatives rejected**: hand-copying numbers into three XML files and a painter (the first typo would put the icon
and the splash out of step, the very thing FR-004 forbids); parsing the `.dc.html` files at build time (they are
design-canvas files outside the repo).

## D6. Rasterising the PNGs

Checked on this machine: `rsvg-convert`, `inkscape`, `convert`/`magick` are not installed; `python3` has Pillow 10.2
but no `cairosvg`. Pillow has no Bézier curves or gradients, and drawing the icon a second time by hand in another
language would be the disagreement D5 avoids. **Spike**: a `testWidgets` file under `tool/` runs with `flutter test
tool/<file>.dart` (the explicit path works for a file that is not under `test/`), and inside `tester.runAsync` a
`PictureRecorder` → `toImage` → `toByteData(png)` writes a valid PNG (110 bytes for a 10 × 10 square).

**Decision**: `tool/make_app_icons.dart` is a throw-away-style test run on demand with
`flutter test tool/make_app_icons.dart`. It draws `AppIconPainter` at 48, 72, 96, 144 and 192 px as a rounded square
(corner radius 25% as in the design's large preview) with transparent corners and writes the five
`mipmap-*/ic_launcher.png`, then writes the three vector layers (D5). It writes only inside
`android/app/src/main/res/`. A note in its header says how to run it.

## D7. Native launch screen

- `res/values/colors.xml`: `splash_background` = #0D1014 (the colour at the edge of the splash gradient, so the
  native screen and the first Flutter frame match).
- Before Android 12: `drawable/launch_background.xml` and `drawable-v21/launch_background.xml` (the latter wins on every
  supported device, minSdk 24) become a `layer-list`: the dark colour and the foreground vector centred at 140 dp
  (the size at which its art matches the splash tile's art: 1.1 per canvas unit = 132/108 × 0.9). `LaunchTheme` in
  both `values` and `values-night` takes the `Theme.Black.NoTitleBar` parent so even a missing attribute is dark;
  `NormalTheme` gets the dark window background in both sets (the window shows behind the app on a resize).
- Android 12 and later: `values-v31/styles.xml` and `values-night-v31/styles.xml` set
  `windowSplashScreenBackground`, `windowSplashScreenAnimatedIcon` (the foreground vector: the system masks the
  icon into a circle two thirds of its 288 dp, the same 2/3 ratio as the adaptive icon, so the art that fits the
  adaptive safe circle fits here) and `windowSplashScreenAnimationDuration`. Night and day files are identical on
  purpose: dark in both. The icon is static; an animated vector for the system splash is out of scope.
- The manifest needs no edit: `android:icon="@mipmap/ic_launcher"` resolves to the adaptive XML in
  `mipmap-anydpi-v26` on Android 8 and later and to the PNG below; the label is already «مصحف الحافظ». No
  `roundIcon` (only Android 7.1 launchers read it, and there the square icon shows).

**Checking resources without building the app**: `aapt2 compile` and `aapt2 link` from the SDK's build-tools
(`~/Android/Sdk/build-tools/36.0.0/aapt2`) validate every resource XML and reference against `android.jar`
(platforms/android-36). Run on the present resources with a scratch manifest it compiles; the new files go through the
same check in the quickstart. This produces a resource table in a scratch folder only, not an APK of the app.

## D8. What the tests can and cannot prove

Provable in Flutter tests: the timeline and the rules (pure); the widget with fake time (minimum, ready, tap,
reduce motion, once-only callback, 320 × 640 at 2x, contrast, semantics, the child behind is not touchable); the child
is built (loading overlaps); the gate wraps `AppWhenReady`; the resource files exist, are well formed, refer to
existing layers, have the five PNG sizes and the palette, and match the geometry; the foreground's real radius.
Only the phone shows: that the icon looks right in the launcher masks and themed mode, that there is no white flash,
that the Android 12 system splash looks acceptable before ours, that the first Flutter frame is not later than before,
and the feel of the motion. Those go in the quickstart as the real-device check (Constitution IX).

## D9. Tagline and name strings

`lib/splash/splash_strings.dart` holds `kSplashName` = «مصحف الحافظ» and `kSplashTagline` = «المصحف كاملاً بلا إنترنت
وبلا إعلانات». The tagline is the design's line; a test pins both strings and the equality of the name with
`MushafApp.title` and with the manifest label (so a rename cannot leave the splash behind). The constants file has the
«proposal until the owner confirms» doc comment (Constitution VI, FR-017). The name is also the screen reader's label.

## D10. What is not done (and why)

- An animated system splash on Android 12 (an `animated-vector`): it cannot be checked without a device and the system
  splash lasts a few hundred milliseconds.
- `roundIcon`, a 512 px store icon, iOS and web icons: not distributed that way (Scope and Distribution).
- Showing the splash on a warm start or after the phone is rotated: the brief says every launch; a warm start is not a
  launch of the process.
- A setting to turn the splash off: not asked for; the 0.9 s minimum and a tap are the answer to «it is long».
