# Contract: Dart interfaces (feature 015)

Names are the plan's proposal; tasks may refine signatures but not behaviour. All new code is under `lib/large_ayah/`.

## screen_layout.dart (pure, no Flutter import beyond `foundation`)

```dart
class LayoutAyah { AyahRef ref; List<MushafWord> words; List<double> widths; List<OpeningLine> opening;
                   List<OpeningLine> trailing; } // trailing: the page-end surah title, on the page's last ayah only
enum OpeningKind { surahTitle, basmala }
class OpeningLine { OpeningKind kind; int? surah; }
sealed class ScreenItem {}  // OpeningItem(OpeningLine line) | AyahItem(AyahRef ref, List<List<MushafWord>> lines)
class LargeScreen { int page; List<ScreenItem> items; ({int number, int of})? part;
                    // getters: ayat, opening, lines, words, continues
}
List<LayoutAyah> pageAyat(PageData page); // the page's ayat with their opening and trailing lines (widths 0)

/// Throws ArgumentError when count is not 1..3, linesPerScreen < 3 or lineWidth <= 0.
List<LargeScreen> layoutPage({required int page, required List<LayoutAyah> ayat, required double lineWidth,
    required double wordGap, required int linesPerScreen, required int count});
```

## screen_navigator.dart

```dart
class ScreenRef { int page; int index; }
abstract interface class ScreenSource { Future<List<LargeScreen>> screensOf(int page); }
class ScreenNavigator {
  ScreenNavigator(ScreenSource source, {required int Function(AyahRef) pageOfAyah});
  Future<LargeScreen> screen(ScreenRef r); Future<ScreenRef> clamp(ScreenRef r); Future<ScreenRef> lastOf(int page);
  Future<ScreenRef?> next(ScreenRef r);      // null after the last screen of 604
  Future<ScreenRef?> previous(ScreenRef r);  // null before the first screen of 1
  Future<ScreenRef> screenOfAyah(AyahRef a); // first part when split
  Future<ScreenRef> firstOf(int page);
}
```

## word_measurer.dart

```dart
class WordMeasurer { WordMeasurer(PageFontLoader fonts);
  Future<List<double>> widths(int page, List<MushafWord> words, double fontSize); } // cached, last 8 pages
```

## large_ayah_settings.dart

```dart
class LargeAyahSettings extends ChangeNotifier {
  LargeAyahSettings(WirdRepository repo, {MushafMeta? meta}); // meta checks `at` against the real ayah counts
  bool get on; int get count; int get sizeStep; double get factor; AyahRef? get at; // setAt does not notify
  static const List<double> factors = [2.0, 2.5, 3.0];
  Future<void> load(); Future<void> reload();
  Future<void> setOn(bool v); Future<void> setCount(int n); Future<void> setSizeStep(int s); Future<void> setAt(AyahRef a);
}
```

`WirdRepository` gains `largeAyahRaw()` style readers and writers for the four keys, as for `ayahTint` (feature 013).

## large_ayah_view.dart (widgets)

- `LargeAyahPager`: the anchored `PageView` (research D5) with `sourceFor(LargeGeometry)`, `layoutKey` (the count),
  `factor`, `target` (`LargeTarget.page` / `LargeTarget.ayah`, with a token); callbacks `onScreenShown(LargeScreen)`,
  `onWordLongPress(int page, MushafWord)` (the reader loads the page and calls its `_openAyahMenu`), `onTap` (bars),
  `onPastEnd` (khatm).
- `LargeGeometry` (`page_screens.dart`): font size, line height, line width and lines per screen of a box, shared by the
  layout and the widget; `PageScreens` is the `ScreenSource` of the app.
- `LargeAyahScreen`: draws one `LargeScreen` in a `PageLook`; words keyed `ValueKey('lw<id>')`; takes `highlightedWordIds`
  and `tintedWordIds` as the Mushaf page does.

## Reader changes (`lib/mushaf/reader_screen.dart`, `lib/settings/settings_screen.dart`)

- The reader shows `LargeAyahPager` instead of its Mushaf pager while `LargeAyahSettings.on`; jumps, search targets,
  wird switches and restored backups re-anchor it. `lib/mushaf/mushaf_page.dart` is not edited. `MushafApp` takes
  `largeAyah` and provides it; `lib/main.dart` makes and loads it.
- Settings gains the tile of contracts/ui.md at the top of its list.
