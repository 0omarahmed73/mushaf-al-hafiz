# Dart interfaces (feature 003)

## Size model and setting (`lib/settings/`)

```dart
abstract final class TextSize {
  static const List<int> steps = [80, 90, 100, 110, 120, 130, 140, 150];
  static const int defaultPercent = 100;
  static int parse(String? raw);               // lenient, never throws (data-model.md)
  static double factor(int percent) => percent / 100;
}

class TextSizeSettings extends ChangeNotifier {
  TextSizeSettings(WirdRepository repo);
  int get percent;  double get factor;  bool get isDefault;
  Future<void> load();                         // main() awaits it before runApp
  Future<void> set(int percent);               // snap, save, notify only on change
  Future<void> reset();                        // set(100)
  Future<void> reload();                       // after a backup import
}
```
`WirdRepository`: `Future<String?> textSizeRaw()` and `Future<void> setTextSizePercent(int percent)` over the key
`textSizePercent`. Provided as `ListenableProvider<TextSizeSettings?>`; a null provider means 100% (tests that do
not care).

## Page box and edge turn (`lib/mushaf/page_scale.dart`, pure)

```dart
const double kLandscapePageWidth = 600, kPageAspect = 1.75;     // moved from reader_screen.dart
enum PageFit { fits, scrollsVertically, pansBothWays }
class PageBox {
  PageBox(Size viewport, double factor);
  Size get base, scaled, content;  PageFit get fit;  Offset get startOffset;
}
enum PageTurn { none, next, previous }
PageTurn edgeTurn({
  required double startX, required double minX, required double maxX,   // matrix x at gesture start; range
  required double dx, required double dy, required double vx,           // finger travel and velocity
  double distance = 56, double flingVelocity = 700,
});
```
Rules: `next` when the gesture started at the left edge (`startX >= maxX`) and the finger moved right (left→right)
by `distance` or flung right faster than `flingVelocity`; `previous` when it started at the right edge
(`startX <= minX`) and the finger moved left likewise; `none` if `|dy| >= |dx|` or the page is not wider than the
viewport.

## Page viewport (`lib/mushaf/page_viewport.dart`)

```dart
class PageViewport extends StatefulWidget {
  const PageViewport({super.key, required this.page, required this.factor, required this.child,
      required this.onLockChanged, required this.onEdgeTurn});
  final int page;  final double factor;  final Widget child;      // child = the page card
  final void Function(int page, bool locked) onLockChanged;       // pager lock for this page
  final void Function(PageTurn turn) onEdgeTurn;                  // reader animates the pager
}
```
Keeps the keys `landscape-scroll` (vertical fit) and the existing `InteractiveViewer` limits (1x..3x). Adds keys
`page-pan` (the 2D viewer) for tests.

## Ayah reading texts (`lib/ayah/ui/reading_text.dart`)

```dart
class ReadingStyles {                           // all sizes = today's size x factor
  ReadingStyles(double factor);
  TextStyle get arabic, english, meaningWord, meaningText, note, source;
}
class ReadingScope extends StatelessWidget {    // reads TextSizeSettings; caps system scale x factor at 3.0
  const ReadingScope({super.key, required this.child});
  static ReadingStyles of(BuildContext context);
}
```
`TafsirView`, `TranslationView`, `MeaningsView` and `Paragraphs` take their styles from `ReadingScope.of`; the
Settings preview uses the same.
