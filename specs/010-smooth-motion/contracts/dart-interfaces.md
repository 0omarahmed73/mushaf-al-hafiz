# Dart Interfaces: Smooth Motion (feature 010)

Signatures the tasks build and the tests pin. Names may change in the code if the test and this file change together.

## `lib/motion/motion.dart`

```dart
abstract final class Motion {
  static const Duration barIn = Duration(milliseconds: 200);
  static const Duration barOut = Duration(milliseconds: 160);
  static const Duration cardIn = Duration(milliseconds: 220);
  static const Duration cardOut = Duration(milliseconds: 160);
  static const Duration jump = Duration(milliseconds: 180);
  static const Duration swap = Duration(milliseconds: 160);
  static const Duration look = Duration(milliseconds: 220);
  static const Duration edgeTurn = Duration(milliseconds: 300);
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const double barSlide = 24;   // dp
  static const double cardSlide = 12;  // dp

  /// True while the phone's «remove animations» is on.
  static bool reduced(BuildContext context);

  /// [d], or Duration.zero when [reduced].
  static Duration of(BuildContext context, Duration d);
}
```

## `lib/motion/fade_slide_switcher.dart`

```dart
/// AnimatedSwitcher with a fade and a vertical slide of [slide] dp (negative: from above). A null child is "nothing";
/// the old child stays until its fade ends, ignores pointers and is excluded from semantics while it leaves.
class FadeSlideSwitcher extends StatelessWidget {
  const FadeSlideSwitcher({super.key, required this.child, required this.slide,
      this.durationIn = Motion.barIn, this.durationOut = Motion.barOut});
  final Widget? child;   // give it a key that is its state, so a change of state switches
  final double slide;    // dp, + is down
  final Duration durationIn, durationOut;
}
```

## `lib/motion/fade_in_on_change.dart`

```dart
/// Shows [child] and, whenever [value] changes (compared with ==), fades it in from 0 over [duration] (and grows it from
/// [fromScale] to 1.0 when that is below 1.0). One child at any time: nothing of the old value stays in the tree.
/// Duration.zero when Motion.reduced. Used for the bookmark icon (scale 0.8) and the wird name (no scale).
class FadeInOnChange extends StatefulWidget {
  const FadeInOnChange({super.key, required this.value, required this.child,
      this.duration = Motion.swap, this.fromScale = 1.0});
  final Object? value;
  final Widget child;
  final Duration duration;
  final double fromScale;
}
```

## `lib/motion/jump_fade.dart`

```dart
/// Fades its child in from 0.35 to 1.0 over Motion.jump each time [controller].play() is called (Duration.zero when reduced).
class JumpFadeController extends ChangeNotifier { void play(); }
class JumpFade extends StatefulWidget {
  const JumpFade({super.key, required this.controller, required this.child});
}
```

## `lib/motion/look_fade.dart` (last task of US3)

```dart
/// Wraps the app's home. [LookFadeHost.of(context).capture()] takes the picture of the screen before the look is set;
/// the host then shows that picture over the new look and fades it out over Motion.look. No-op when reduced or when
/// there is no host above (tests that do not ask for it).
class LookFadeHost extends StatefulWidget { const LookFadeHost({super.key, required this.child}); }
class LookFade { static Future<void> around(BuildContext context, Future<void> Function() change); }
```

## `lib/motion/frame_trace.dart`

```dart
abstract final class FrameTrace {
  static const bool enabled = bool.fromEnvironment('FRAME_TRACE');
  /// Registers a timings callback printing the lines of data-model.md when [enabled]; does nothing otherwise.
  static void install({void Function(String line) log = debugPrint});
  /// `build=<ms> raster=<ms> total=<ms>` with two decimals, from a FrameTiming (pure, tested).
  static String formatFrame(FrameTiming t);
}
```

## Additions to existing classes

```dart
// lib/mushaf/mushaf_repository.dart
PageData? peek(int page);          // the cached page, no I/O, no cache reordering side effects beyond "recently used"
Future<void> prefetch(int page);   // loadPage that ignores errors; reads each file once (the first word of the next page is
                                   // remembered from the prefetch of that page, no second read)

// lib/mushaf/page_font_loader.dart
void prefetch(int page, {int direction = 1});   // nearest first, then the direction the reader is turning; unchanged
                                                // for existing callers (default direction)

// lib/mushaf/reader_controller.dart
void pageSeen(int page);           // sets the page and notifies; writes nothing
Future<void> savePosition();       // the writes of onPageShown (setPage when following a wird, then setLastViewedPage)
Future<void> onPageShown(int page) // unchanged behaviour: pageSeen(page) then savePosition()

// lib/mushaf/position_saver.dart (Stage C)
class PositionSaver {
  PositionSaver({required Future<void> Function() save, Duration delay = const Duration(milliseconds: 400)});
  void markDirty();                // (re)starts the timer
  Future<void> flush();            // saves now if dirty; completes when the write is done
  void dispose();                  // flushes? no: the owner calls flush() first; dispose cancels the timer
}
```

## The reader (`reader_screen.dart`, windows R1 to R3)

- R1: `_PageItemState` caches its `MushafPageCard` (rebuilt only when data, family, look, factor, highlight, meta or the callbacks
  change); the screen no longer wraps the `Scaffold` in a `ListenableBuilder`: the top bar, the card layer and the pager
  listen to what they show; `PageView.builder(allowImplicitScrolling: true, scrollCacheExtent: ScrollCacheExtent.pixels(1))`;
  `_onPageChanged` keeps calling `onPageShown` (the write is unchanged in Stage A) and no longer starts any prefetch; the
  prefetch of data and fonts runs from the pager's `ScrollEndNotification`; `PAGEWARM` line under `PAGE_TURN_TRACE`.
- R2: bars through `FadeSlideSwitcher` in their fixed slots; the card through `FadeSlideSwitcher` with its barrier outside;
  `JumpFade` around the pager and `controller.play()` after `_syncPager`'s `jumpToPage`; `_onEdgeTurn` uses `jumpToPage` when
  `Motion.reduced(context)`; the wird name in `_TopBar` through `FadeInOnChange`.
- R3 (Stage C): `_onPageChanged` calls `pageSeen` and marks the saver dirty instead of calling `onPageShown`; `flush()` on lifecycle
  pause/inactive/detached, before `Navigator.push`, in `dispose`, and before a jump.
