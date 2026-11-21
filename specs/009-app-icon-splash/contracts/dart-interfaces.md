# Contract: code interfaces of feature 009

Signatures are what the tests are written against (test-first). Bodies are decided in the tasks. All files are under
`lib/splash/` unless said otherwise.

## `splash_strings.dart`

```dart
/// The app's name; equal to MushafApp.title and the manifest label.
const String kSplashName = 'مصحف الحافظ';
/// PROPOSAL (Constitution VI): the line under the name, from the design; the owner confirms or replaces it.
const String kSplashTagline = 'المصحف كاملاً بلا إنترنت وبلا إعلانات';
```

## `splash_palette.dart`

`abstract final class SplashColors` with `const Color` members: `background` #0D1014, `backdropGlow` #17313A, `name`
#ECE7DC, `tagline` #9AA4AD, `progressTrack` #232A33, `progressFill` #6CC4B5, `ringNear` #232A33, `ringFar` #1B2128,
`tileTop` #1A212A, `star` #6CC4B5, `pageLeft` #ECE7DC, `pageRight` #D6D0C1, `pageInk` #8A939C, `gold` #E3B05A, plus the
tiny-star colours.

## `splash_plan.dart` (pure, no Flutter import)

```dart
abstract final class SplashPlan {
  static const Duration fullDuration = Duration(milliseconds: 1400);
  static const Duration minimum = Duration(milliseconds: 900);
  static const Duration reducedStay = Duration(milliseconds: 300);
  static const Duration fade = Duration(milliseconds: 220);
  static bool mayLeave({
    required Duration elapsed,
    required bool ready,
    required bool skipped,
    required bool reducedMotion,
  });
}
```

Rules the unit tests fix: not ready never leaves, at any elapsed time and with a tap; ready at 899 ms does not leave and at 900
ms does; ready and skipped leaves at 0 ms; reduced motion leaves at 300 ms and not at 299 ms; skipped but not ready never leaves.

## `splash_timeline.dart` (pure, no Flutter import)

```dart
class SplashFrame { /* the fields of data-model.md, all final, const constructor */ }
abstract final class SplashTimeline {
  static SplashFrame at(Duration elapsed);
  static const SplashFrame finalFrame;
}
```

Rules the unit tests fix: at 0 ms `tileOpacity == 0`, `nameOpacity == 0`, `lineOpacity == 0`, `progress == 0`, `backdrop == 0`; every
field stays in its range for 0..2000 ms in 1 ms steps; opacities, `tileScale`, `backdrop`, `stars` and `progress` never go
backwards; `twinkle` is 0 outside 400..800 ms and peaks once in it; from 900 ms every field except `progress` equals the final
frame; from 1400 ms the whole frame equals `finalFrame`; negative durations clamp to the first frame.

## `icon_geometry.dart`

```dart
abstract final class AppIconGeometry {
  static const double canvas = 108;
  static const String starSquare, starDiamond, pageLeft, pageRight, spine, pagesLinesLeft, pagesLinesRight, goldLine;
  static const String monochromeStar, monochromePageLeft, monochromePageRight;
  static const IconPlacement legacy;    // scale 0.9, pivot (54, 54), shift (0, 2)
  static const IconPlacement adaptive;  // scale 0.85, pivot (54, 54.55), shift (0, -0.55)
  static Path parsePath(String d);      // M L C Z absolute; FormatException otherwise
  static double farthestFromCentre(IconPlacement placement); // strokes included, from (54, 54)
}
class IconPlacement { const IconPlacement(this.scale, this.pivot, this.shift); final double scale; final Offset pivot, shift; Offset apply(Offset p); }
```

Rules the unit tests fix: `parsePath` of a rectangle string has the right bounds; a curve's bounds; `FormatException` for `A`, a
lower-case command and a missing number; `farthestFromCentre(adaptive) <= 33`; `farthestFromCentre(legacy) > 33` (the placements
differ for a reason); the star diamond is the square turned 45°; the fills and strokes equal the design's colours.

## `app_icon_painter.dart`

```dart
/// Draws the icon on a 108-unit canvas scaled to the paint size: background (when asked) and art in the legacy placement.
class AppIconPainter extends CustomPainter {
  const AppIconPainter({this.twinkle = 0, this.withBackground = true, this.placement, Listenable? repaint});
  // twinkle 0..1: the star grows to 1.3x and a teal halo of up to 0.45 alpha is drawn behind it
}
```

## `splash_painters.dart`

```dart
/// The background of the 390 x 844 reference: the radial gradient (centre 50% across and 30% down, #17313A at the centre to
/// #0D1014 at 62% of the distance to the farthest corner), the eight tiny stars and the two rings. Everything is placed
/// in reference coordinates and mapped to the real size by x * width / 390 and y * height / 844; radii use width / 390.
class SplashBackgroundPainter extends CustomPainter { const SplashBackgroundPainter({required this.backdrop, required this.stars}); }
/// The thin line: a 120 x 3 track (#232A33, radius 2) with a #6CC4B5 fill of `progress` x 120.
class ProgressLinePainter extends CustomPainter { const ProgressLinePainter({required this.progress}); }
```

## `splash_screen.dart`

```dart
/// The animated overlay. Owns the clock, the exit fade and the tap; does not know about the app behind it.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.ready, this.onGone});
  final bool ready;           // true when the app has finished its first loading
  final VoidCallback? onGone; // called once, after the fade (or at once with reduced motion), from the gate
}
```

Behaviour the widget tests fix (fake time): the first frame shows a flat background; the tile, name, tagline and thin line
appear in order; with `ready: true` from the start the overlay is still there at 899 ms and starts leaving at 900 ms, gone after
the fade; with `ready: false` it stays at 5 s; turning `ready` true later leaves within the fade; a tap before 900 ms with ready
leaves within the fade; a tap while not ready waits; two taps and a tap while fading call `onGone` once; reduced motion paints
the final frame at once and is gone 300 ms after ready with no fade; the reduce-motion flag turned on mid-way drops to the
static drawing; 320 × 640 at a 2x text scale throws nothing and overflows nothing; the colours of the name and of the tagline
have a contrast ratio of at least 4.5 against both the flat and the glow colour of the background; one semantics node with the
name and the tagline.

## `splash_gate.dart`

```dart
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child, this.ready, this.onFinished});
  final Widget child;
  final Future<void>? ready;   // null means ready at once; an error counts as ready
  final VoidCallback? onFinished;
}
```

Behaviour the tests fix: the child is built from the first frame (loading overlaps) and keeps its state when the splash is gone;
while the splash shows the child gets no pointer events and no semantics; `onFinished` is called once, after the overlay has been
removed from the tree; a `ready` future that fails ends the splash like a success; the gate supplies its own `Directionality`
(RTL) and a `MediaQuery` when none is above it.

## `app_when_ready.dart`

```dart
/// A dark box until [app] completes, then the app it produced; an error is rethrown from build so it is not hidden.
class AppWhenReady extends StatelessWidget { const AppWhenReady(this.app, {super.key}); final Future<Widget> app; }
```

## `lib/main.dart` (the one existing file edited)

`main()` calls `WidgetsFlutterBinding.ensureInitialized()`, starts `_bootApp()`, and calls
`runApp(SplashGate(ready: app, child: AppWhenReady(app)))`. `_bootApp()` is the old body ending in `return MushafApp(...)`.
No other behaviour of the start changes.

## `tool/app_icon_resources.dart` and `tool/make_app_icons.dart`

```dart
/// The text of each generated Android resource, computed from AppIconGeometry (tool/app_icon_resources.dart).
abstract final class AppIconResources {
  static String background();   // res/drawable/ic_launcher_background.xml
  static String foreground();   // res/drawable/ic_launcher_foreground.xml
  static String monochrome();   // res/drawable/ic_launcher_monochrome.xml
}
```

`tool/make_app_icons.dart` is a `testWidgets` file run by hand: `flutter test tool/make_app_icons.dart`; it writes the five
PNGs and the three XML files under `android/app/src/main/res/` and nothing else.
