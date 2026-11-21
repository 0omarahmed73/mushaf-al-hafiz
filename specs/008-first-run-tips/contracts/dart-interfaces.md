# Dart interfaces: First-Run Tips

The tests are written against these signatures. Folder `lib/onboarding/`. Arabic strings are in `ui.md`.

## tips_strings.dart

Constants (all proposals until the owner confirms them; the file's doc comment says so):

```dart
const String kTipsDialogLabel;          // the dialog's name for a screen reader
const String kTipsNext, kTipsSkip, kTipsStart;
String kTipsStepOf(int step, int total); // «الخطوة N من M»
const String kTipLongPressTitle, kTipLongPressBody;
const String kTipTurnPagesTitle, kTipTurnPagesBody;
const String kTipBarsZoomTitle, kTipBarsZoomBody;
const String kTipWirdTitle, kTipWirdBody;
const String kTipBookmarksTitle, kTipBookmarksBody;
const String kTipSizeLookTitle, kTipSizeLookBody;
```

## tip_steps.dart (pure Dart, no widget import)

```dart
enum TipPicture { longPress, turnPages, barsAndZoom, wird, bookmarks, sizeAndLook }

class TipStep {
  const TipStep({required this.picture, required this.title, required this.body});
  final TipPicture picture;
  final String title;
  final String body;
}

/// The six steps, in order.
const List<TipStep> kTipSteps;
```

## tips_store.dart

```dart
const String kTipsSeenKey = 'tipsSeen';

class TipsStore {
  const TipsStore(WirdRepository repository);

  /// The store of the app's repository, or null when the context has no `Provider<WirdRepository>`.
  static TipsStore? maybeOf(BuildContext context);

  /// The rule: only exactly 'true' means seen.
  static bool isSeen(String? stored);

  /// One read, no stream. Throws what the repository throws.
  Future<bool> seen();

  /// Writes 'true'.
  Future<void> markSeen();
}
```

## tip_picture.dart

```dart
/// The drawing of a step on a 240 x 112 design box scaled down to fit. [active] is true only for the step on
/// screen: the one decorative pulse runs only then, and never under reduced motion. Excluded from the semantics.
class TipPictureView extends StatefulWidget {
  const TipPictureView({super.key, required this.picture, required this.active});
  final TipPicture picture;
  final bool active;
}
```

## tips_dialog.dart

```dart
enum TipsOutcome { finished, skipped }

/// The card: PageView of kTipSteps, dots, buttons. Pops the route with a TipsOutcome.
class TipsDialog extends StatefulWidget {
  const TipsDialog({super.key});
}
```

Keys (for tests): `tips-dialog`, `tips-pages` (the `PageView`), `tips-dots`, `tips-next`, `tips-skip`, `tips-start`,
`tips-step-title-N` (N = 0..5), `tips-body-N`, `tips-picture-N`.

## tips_gate.dart

```dart
/// Shows [child]; once, after the first frame, opens the tips when `tipsSeen` is not 'true' (and [enabled]).
class TipsGate extends StatefulWidget {
  const TipsGate({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;
}

/// Opens the tips now (any state), waits until they close, then stores `tipsSeen` when the reader finished or
/// skipped. A second call while one is open returns at once. Never throws.
Future<void> showTips(BuildContext context);
```

## lib/backup/backup_service.dart (additive)

```dart
/// Settings that describe this phone rather than the user's data: importJson keeps the phone's value when the file
/// has none for the key.
const Set<String> kKeptOnImport = {'tipsSeen'};
```
