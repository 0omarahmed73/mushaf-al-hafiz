# Contract: code interfaces of feature 005

Signatures are what the tests are written against (test-first). Bodies are decided in the tasks.

## `lib/khatm/last_page_swipe.dart` (pure, no Flutter import)

```dart
/// Decides whether one drag at the last page of the Mushaf opens the khatm dua (spec FR-001, research D1, D2).
class LastPageSwipe {
  static const double minDistance = 48;        // logical pixels
  static const double minFlingDistance = 16;   // logical pixels
  static const double minFlingVelocity = 300;  // logical pixels per second

  void start();                                 // a new gesture: forward distance = 0
  void overscroll(double delta);                // adds delta when delta > 0, ignores 0 and negatives
  double get distance;                          // forward distance so far
  bool end({required double velocity});         // true: open; always resets the distance
}
```

Rules the unit tests fix: 47.9 px slow → false; 48 px slow → true; 16 px with 300 px/s → true; 15.9 px with 5000 px/s
→ false; 16 px with 299 px/s → false; negative overscroll never adds; two gestures never add together; `end()`
twice in a row answers false the second time.

## `lib/khatm/dua_text.dart`

```dart
class DuaUnavailable implements Exception { const DuaUnavailable(); }

class DuaText {
  const DuaText(this.paragraphs);
  final List<String> paragraphs;
  static const String assetPath = 'assets/khatm/dua.txt';
  static DuaText parse(String text);              // splits at blank lines, drops the final newline only
  static Future<DuaText> load(AssetBundle bundle); // throws DuaUnavailable on any failure or no paragraph
  String get text;                                 // paragraphs joined by a blank line
}
```

## `lib/khatm/dua_strings.dart` (the owner's confirmation touches only this and the asset)

```dart
const String kDuaTitle = 'دعاء ختم القرآن';
const String kDuaNote = 'دعاء وليس من نص القرآن';
const String kDuaAmen = 'آمين';
const String kDuaUnavailable = 'تعذّر تحميل نص الدعاء';
const String kDuaCreditName = 'دعاء ختم القرآن';
const String kDuaCreditUse = 'الدعاء المتعارف عليه في ختام المصاحف';
const String kDuaCreditNote = 'لا يوجد نص ثابت عن النبي ﷺ؛ الصياغة متداولة';
```

## `lib/khatm/khatm_dua_screen.dart`

```dart
/// A full-screen route. Pops `true` for «آمين»; the back arrow and the system back pop with no result.
class KhatmDuaScreen extends StatefulWidget {
  const KhatmDuaScreen({super.key});
}
```

Keys: `khatm-note` (the label), `khatm-panel` (the dua's panel), `khatm-text-<n>` (paragraph n), `khatm-amen`
(«آمين»), `khatm-unavailable` (the fallback message). Reads `DefaultAssetBundle`, `ReadingScope`, `context.look`.

## Reader (`lib/mushaf/reader_screen.dart`), additive edits only

- `import '../khatm/...'` (the screen, the rule, the strings are not needed).
- Field `final LastPageSwipe _lastSwipe = LastPageSwipe();` and `bool _duaOpen = false;`.
- `NotificationListener<ScrollNotification>(onNotification: _onPagerScroll, child: PageView.builder(...))`.
- `bool _onPagerScroll(ScrollNotification n)`: depth 0 and horizontal only; Start → `_lastSwipe.start()`;
  Overscroll with `overscroll > 0` → `_lastSwipe.overscroll(...)`; End → `_lastSwipe.end(velocity:
  n.dragDetails?.velocity.pixelsPerSecond.dx ?? 0)` and, when true, `_openDua()`. Always returns false.
- `Future<void> _openDua()`: returns if `_duaOpen` or not mounted; sets `_duaOpen`; pushes `KhatmDuaScreen`;
  clears `_duaOpen`; when the result is `true` and mounted, `_controller.onPageShown(1)`.
- `_onEdgeTurn`: before the early return, `if (turn == PageTurn.next && index == MushafMeta.pageCount - 1) {
  unawaited(_openDua()); return; }`.

## `lib/settings/about_screen.dart`

One more tuple in `AboutScreen.credits`: `(kDuaCreditName, kDuaCreditUse, kDuaCreditNote)`.
