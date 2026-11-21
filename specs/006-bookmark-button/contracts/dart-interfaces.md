# Contract: Dart interfaces (tests are written against these)

## `lib/wirds/wird_repository.dart` (additive)

```dart
/// What one tap on the reader's bookmark icon did, so that «تراجع» can undo it (data-model.md).
class BookmarkToggle {
  const BookmarkToggle.added(this.page, int id) : addedId = id, removed = const [];
  const BookmarkToggle.removed(this.page, this.removed) : addedId = null;
  final int page;
  final int? addedId;
  final List<Bookmark> removed;
  bool get wasAdded => addedId != null;
}

class WirdRepository {
  /// In one transaction: no bookmark on [page] of the scope [wirdId] (null = general) -> adds one with no note;
  /// otherwise deletes all of them. [ArgumentError] when [page] is not 1..604.
  Future<BookmarkToggle> toggleBookmark(int page, {int? wirdId});

  /// Undoes [toggle]: deletes the added id, or re-inserts the removed rows with their id, note and createdAt
  /// (a row whose wird no longer exists comes back general). Rows that already exist are left as they are.
  Future<void> undoBookmarkToggle(BookmarkToggle toggle);
}
```

`addBookmark`, `removeBookmark`, `watchBookmarks`, `bookmarkCount` are unchanged. New: `bookmarkRows()` (one-shot read of the
table) and the public `readSetting` / `writeSetting` wrappers (used by feature 008).

## `lib/mushaf/reader_controller.dart` (additive)

```dart
/// True while the page shown has a bookmark of the current scope (data-model.md). Changing it does not call
/// `notifyListeners()`, so only the icon rebuilds.
ValueListenable<bool> get pageBookmarked;

/// One tap on the icon: `repo.toggleBookmark(page, wirdId: scopeWirdId)`. Returns null (and does nothing) while the
/// previous tap is still being written.
Future<BookmarkToggle?> toggleBookmark();

/// Undoes a tap (`repo.undoBookmarkToggle`).
Future<void> undoBookmarkToggle(BookmarkToggle toggle);
```

```dart
/// Reads the bookmark table once and recomputes `pageBookmarked`. Called by `init()`, `reload()`, `addBookmark()`, a
/// change of the active wird, `toggleBookmark()` / `undoBookmarkToggle()`, and by the reader after the «علامات» sheet
/// closes (the sheet writes to the repository directly).
Future<void> refreshBookmarks();
```

There is no stream: a drift `watch*` stream kept alive for the controller's lifetime makes widget tests that write the
database inside `tester.runAsync` hang, and the icon only has to be right when the reader knows something changed.
`dispose()` disposes the notifier.

## `lib/mushaf/bookmark_button.dart` (new)

```dart
/// The icon: outlined or filled, 48 x 48, tooltip and semantics from bookmark_strings.dart.
class BookmarkButton extends StatelessWidget {
  const BookmarkButton({super.key, required this.page, required this.bookmarked, required this.onPressed});
  final int page;
  final ValueListenable<bool> bookmarked;
  final VoidCallback onPressed;
}
```

Key: `ValueKey('bookmark-button')`.

## `lib/mushaf/bookmark_strings.dart` (new; the owner confirms them)

```dart
String kBookmarkAdd(int page)     => 'إضافة علامة للصفحة $page';
String kBookmarkRemove(int page)  => 'إزالة العلامة من الصفحة $page';
const kBookmarkStateOn  = 'عليها علامة';
const kBookmarkStateOff = 'ليس عليها علامة';
String kBookmarkAdded(int page)   => 'تمت إضافة علامة للصفحة $page';
String kBookmarkRemoved(int page) => 'تمت إزالة العلامة من الصفحة $page';
const kBookmarkUndo = 'تراجع';
```
