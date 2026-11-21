# Dart interfaces (feature 004)

Signatures only; bodies are written test-first in the tasks. Names are proposals fixed here so the tasks and tests
agree.

## `lib/look/look_choice.dart` (pure)

```dart
enum LookChoice {
  emerald,
  night;

  /// Lenient: null, empty, unknown text or a wrong case-sensitive word -> [emerald]. Never throws.
  static LookChoice parse(String? raw);

  /// The look's constants.
  AppLook get look;
  PageLook get pageLook;
}
```

## `lib/look/look_settings.dart`

```dart
class AppLookSettings extends ChangeNotifier {
  AppLookSettings(WirdRepository repository);
  LookChoice get choice;          // emerald until loaded
  AppLook get look => choice.look;
  PageLook get pageLook => choice.pageLook;
  Future<void> load();            // once, before the first frame
  Future<void> reload();          // after a backup import; notifies only on a change
  Future<void> set(LookChoice c); // saves, then notifies only on a change
}
```

`WirdRepository` gains `Future<String?> appLookRaw()` and `Future<void> setAppLook(String value)` (key `appLook`),
next to `textSizeRaw`.

## `lib/theme.dart`

```dart
@immutable
class AppLook extends ThemeExtension<AppLook> {
  // colours and shapes as in data-model.md (final fields, const constructor)
  static const AppLook emerald;   // built from AppColors: today's values
  static const AppLook night;
  @override AppLook copyWith(...);
  @override AppLook lerp(ThemeExtension<AppLook>? other, double t); // t < .5 ? this : other (the theme is switched instantly)
}

extension LookContext on BuildContext {
  /// The look of the current Theme; Emerald when the Theme has none (plain MaterialApp in tests).
  AppLook get look;
}

ThemeData buildAppTheme({AppLook look = AppLook.emerald}); // buildAppTheme() is today's theme, unchanged
```

`AppColors`, `headingStyle`, `kHeadingFont`, `kUiFont`, `kBoldVariation` stay as they are. `headingStyle(size, color)`
keeps its signature (screens pass `context.look.heading`).

## `lib/look/contrast.dart` (pure)

```dart
double contrastRatio(Color a, Color b);                   // WCAG 2.x, 1.0 .. 21.0
Color liftToContrast(Color color, Color against, double ratio); // raises HSL lightness in 1% steps; color if already enough
```

## `lib/look/wird_marker.dart`

```dart
Color markerColor(AppLook look, Color palette);          // Emerald: palette; Night: liftToContrast(palette, look.cardFill, 3.0)
class WirdMarker extends StatelessWidget { const WirdMarker({super.key, required Color color}); } // diamond 10 px (Emerald) or dot 8 px (Night)
```


`AppLook` exposes `List<({String name, Color fg, Color bg, double min})> get requiredPairs` (text 4.5, large text
and icons 3.0, controls' borders 3.0) used by the contrast test, and `Set<String> get decorative` naming the
hairline pairs that are exempt.

## `lib/mushaf/page_look.dart`

```dart
enum BannerStyle { framed, rules }

class PageLook {
  const PageLook({
    required Color paper, required Color ink, required Color frame, required double frameWidth,
    required Color bannerText, required Color background, Color? ring, Color? bannerFill,
    BannerStyle bannerStyle = BannerStyle.framed,
    Color? numberColor,                 // null = ink (today)
    Color highlight = const Color(0x55FFC107),
    Color? endMarker,                   // null = the line's ink
  });
  static const PageLook screen;         // Emerald, unchanged
  static const PageLook emerald = screen;
  static const PageLook night;
}
```

`MushafPageCard` keeps its parameters (`look` defaults to `PageLook.screen`); the reader passes
`context.read<AppLookSettings?>()`'s page look (Emerald when absent). `MushafPage` gains the optional `bannerStyle`,
`numberColor`, `endMarkerIds`, `endMarkerColor`; with the defaults it draws exactly as today.

## `lib/mushaf/models.dart` and `mushaf_repository.dart`

`PageData` gains `Set<int> endMarkerIds` (derived in `MushafRepository.loadPage`; empty for a hand-built `PageData`
in tests that does not supply it). No JSON change.

## `lib/render/page_renderer.dart`, `lib/pdf/pdf_job.dart`, `lib/ayah/page_picture_action.dart`

```dart
abstract interface class PageRenderer {
  Future<Uint8List> picture(int page, {PageLook look = PageLook.screen});
  Future<IndexedPage> pdfPage(int page, {PageLook look = PageLook.screen});
}

class PdfJob {
  bool start(int surah, {PageLook look = PageLook.screen}); // the look is frozen for the whole job
}

class PagePictureAction {
  PagePictureAction({required renderer, required files, required share, PageLook look = PageLook.screen});
}
```

The default writer factory of `PdfJob` builds `PdfWriter(..., sheet: look.background)`; a `writerFactory` supplied by
a test is called as before.

## `lib/app.dart`

`MushafApp` gains `AppLookSettings? appLook` (null in tests = Emerald), provides
`ListenableProvider<AppLookSettings?>.value`, and builds `MaterialApp(theme: buildAppTheme(look: ...),
themeAnimationDuration: Duration.zero)` inside a `ListenableBuilder` on it. `main.dart` creates and loads it before
`runApp`.
