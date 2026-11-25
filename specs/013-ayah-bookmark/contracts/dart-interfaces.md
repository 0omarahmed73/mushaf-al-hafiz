# Contract: Dart interfaces (feature 013)

Signatures the tests are written against. Names may change only together with their tests. Nothing here is code to paste;
bodies are the tasks' business. `Bookmark`, `BookmarksCompanion`, `Wird` are the generated drift classes (after the schema
change `Bookmark` has `int? surah` and `int? ayah`).

## `lib/wirds/db.dart`

```dart
class Bookmarks extends Table {
  // existing columns unchanged ...
  IntColumn get surah => integer().nullable()();   // CHECK surah IS NULL OR 1..114
  IntColumn get ayah  => integer().nullable()();   // CHECK (ayah IS NULL) = (surah IS NULL) AND (ayah IS NULL OR 1..286)
}

class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e, {this.migrationDebugHook});   // test only: called with 'surah' after step 1, 'ayah' after step 2
  final Future<void> Function(String step)? migrationDebugHook;
  int get schemaVersion => 2;
  // onCreate: createAll (version 2 at once). onUpgrade(from < 2): one transaction, each addColumn guarded by PRAGMA table_info.
  // beforeOpen: PRAGMA foreign_keys = ON (unchanged).
}
```

## `lib/wirds/ayah_bookmark_change.dart`

```dart
enum AyahChangeKind { added, removed, createdWithNote, noteReplaced, noteCleared }

class AyahBookmarkChange {
  const AyahBookmarkChange({required this.kind, required this.ref, required this.page,
      this.addedId, this.removed = const [], this.before = const []});
  final AyahChangeKind kind;
  final AyahRef ref;
  final int page;                          // where the ayah begins
  final int? addedId;                      // added, createdWithNote
  final List<Bookmark> removed;            // removed
  final List<({int id, String? note})> before;   // noteReplaced, noteCleared
}
```

## `lib/wirds/wird_repository.dart` (additive, and one fix)

```dart
/// FIXED (feature 006's method): selects and deletes PAGE bookmarks only (surah IS NULL). Everything else unchanged.
Future<BookmarkToggle> toggleBookmark(int page, {int? wirdId});

/// The ayah bookmarks of [ref] in the scope [wirdId] (null = general), newest first. For the sheet's state.
Future<List<Bookmark>> ayahBookmarkRows(AyahRef ref, {int? wirdId});

/// One transaction: none in the scope -> insert one with no note -> added; some -> delete all -> removed(rows).
/// ArgumentError for a page outside 1..604.
Future<AyahBookmarkChange> toggleAyahBookmark(AyahRef ref, {required int page, int? wirdId});

/// The four cases of data-model.md; trims [note]. Returns null for "no bookmark and an empty note" (nothing written).
/// A non-empty note on several rows of the scope is written to all of them.
Future<AyahBookmarkChange?> saveAyahNote(AyahRef ref, {required int page, int? wirdId, String? note});

/// Exactly the state before [change]: deletes the added id; re-inserts removed rows with id, createdAt, note, surah, ayah
/// (insertOrIgnore; a wird that no longer exists -> general); writes each `before` note back. Twice changes nothing more.
Future<void> undoAyahBookmarkChange(AyahBookmarkChange change);

/// The ayat that have an ayah bookmark in the scope; pure.
Set<AyahRef> ayahMarksOf(Iterable<Bookmark> rows, int? scopeWirdId);

Future<String?> ayahTintRaw();            // raw 'ayahTint'
Future<void> setAyahTint(bool enabled);
```

`addBookmark(page, note, {wirdId})` and `removeBookmark(id)` are unchanged (a page bookmark; delete by id for either kind).

## `lib/mushaf/ayah_tint.dart` (pure)

```dart
/// Ids of every word of [page] (the end marker included) whose ayah is in [marks]. Empty when [marks] is empty.
/// Uses the words of the page, never a stored page, so each page tints its own words (no ayah crosses a page here).
Set<int> ayahTintIds(PageData page, Set<AyahRef> marks);
```

## `lib/settings/ayah_tint_settings.dart`

```dart
class AyahTintSettings extends ChangeNotifier {
  AyahTintSettings(WirdRepository repo);
  bool get enabled;                  // true until a stored 'false'
  Future<void> load();               // never writes
  Future<void> reload();             // after a restored backup
  Future<void> set(bool enabled);    // saves at once; notifies only on a real change
}
```

## `lib/mushaf/page_look.dart`, `mushaf_page.dart`, `mushaf_page_card.dart` (additive)

```dart
// PageLook: final Color bookmarkTint;  emerald 0x290F766E, night 0x24E4C877 (default for a look that does not set it: 0x290F766E)
// MushafPage / MushafPageCard: Set<int> tintedWordIds = const {};  Color tintColor (card passes look.bookmarkTint)
// _word: highlighted -> highlightColor (as today); else tinted -> tintColor; same DecoratedBox(radius 4); no size change.
```

## `lib/mushaf/reader_controller.dart` (additive; one fix)

```dart
ValueListenable<bool> get pageBookmarked;              // FIX: page rows only (surah == null)
ValueListenable<Set<AyahRef>> get ayahMarks;           // scope's bookmarked ayat; replaced only on a real change
void attachMeta(MushafMeta meta);                      // for pageOfAyah; called by the reader at start
({bool bookmarked, String? note}) ayahState(AyahRef ref);   // synchronous: read from the in-memory rows, so the sheet's first frame is right
Future<AyahBookmarkChange?> toggleAyahBookmark(AyahRef ref);       // null while busy
Future<AyahBookmarkChange?> saveAyahNote(AyahRef ref, String? note);  // null while busy or for case (d)
Future<void> undoAyahBookmarkChange(AyahBookmarkChange change);
```

All of them end with `refreshBookmarks()`; none calls `notifyListeners()` for a bookmark change.

## `lib/ayah/ayah_bookmark_port.dart`

```dart
/// What the ayah sheet needs from the reader; null in tests that do not exercise bookmarks.
class AyahBookmarkPort {
  const AyahBookmarkPort({required this.state, required this.toggle, required this.saveNote, required this.onChange});
  final ({bool bookmarked, String? note}) Function(AyahRef ref) state;   // synchronous, from memory (D5, D8)
  final Future<AyahBookmarkChange?> Function(AyahRef ref) toggle;
  final Future<AyahBookmarkChange?> Function(AyahRef ref, String? note) saveNote;
  final void Function(AyahBookmarkChange change) onChange;   // the reader shows the message with «تراجع»
}
```

## `lib/ayah/ui/ayah_sheet.dart` and `ayah_note_dialog.dart`

```dart
Future<void> showAyahSheet(BuildContext context, {required AyahRef ref, required MushafMeta meta, required int page,
    AyahBookmarkPort? bookmarks});                      // optional: the one added parameter
// AyahSheet gets `final AyahBookmarkPort? bookmarks;`. SheetRow gets `final String? semanticsValue;` and
// `final int? subtitleMaxLines;` (null = as today for both).
// Keys: ValueKey('ayah-bookmark'), ValueKey('ayah-note'), and ValueKey('ayah-note-show') only when the note is not empty.

/// true = saved (the dialog closed); false/null = cancelled. [onSave] gets the typed text (possibly empty) and does the write;
/// if it throws, the dialog stays open with the typed text and shows kAyahNoteFailed. Max 200 characters.
Future<bool?> showAyahNoteDialog(BuildContext context,
    {required String title, required String? initialNote, required bool bookmarkExists,
     required Future<void> Function(String text) onSave});
// Keys: ValueKey('ayah-note-field'), ValueKey('ayah-note-save'), ValueKey('ayah-note-cancel'). The dialog is scrollable.
const int kAyahNoteMaxLength = 200;

/// FR-028: the whole note to read. true = «تعديل» (the caller opens the note field); false/null = «إغلاق», back, outside.
/// Writes nothing. Scrollable.
Future<bool?> showAyahNoteView(BuildContext context, {required String title, required String note});
// Keys: ValueKey('ayah-note-view'), ValueKey('ayah-note-view-text'), ValueKey('ayah-note-view-close'),
// ValueKey('ayah-note-view-edit').
```

## `lib/wirds/bookmarks_sheet.dart` (small)

`BookmarksSheet` gets `MushafMeta? meta` (surah names). A tile of a bookmark with `surah != null` shows the ayah row of ui.md;
its tap pops `AyahTarget(AyahRef(surah, ayah), page)`; a page row pops the `int`, as today. Keys: `ValueKey('bookmark-ayah-icon-<id>')`
on the icon of an ayah row.

## `lib/backup/backup_service.dart`

```dart
const int kBackupVersion = 1;            // unchanged: the base format
const int kBackupVersionAyah = 2;        // written only when an ayah bookmark exists
const int kBackupHighestRead = 2;        // what _parse accepts; above -> BackupProblem.newerVersion

BackupService(AppDatabase db, {Future<void> Function(String)? debugHook, MushafMeta? meta});
// exportJson: version = any ayah bookmark ? 2 : 1; surah/ayah keys only in version 2.
// importJson/check: reads 1 and 2; validates ayah bookmarks (data-model.md); a file with an ayah bookmark and no meta -> invalid.
```

## `lib/mushaf/ayah_bookmark_strings.dart` (confirmed by the owner on 2026-11-25, T048)

```dart
const String kAyahBookmarkAddLabel = 'إضافة علامة على الآية';
const String kAyahBookmarkRemoveLabel = 'إزالة العلامة من الآية';
const String kAyahStateOn = 'عليها علامة';  const String kAyahStateOff = 'ليس عليها علامة';   // same words as 006
String kAyahBookmarkAdded(String surah, int ayah);              // «تمت إضافة علامة على سورة X · آية N»
String kAyahBookmarkRemoved(String surah, int ayah);            // «تمت إزالة العلامة من سورة X · آية N»
const String kAyahNoteLabel = 'ملاحظة للآية';
const String kAyahNoteHas = 'عليها ملاحظة';  const String kAyahNoteNone = 'ليس عليها ملاحظة';
String kAyahNoteTitle(String surah, int ayah);                  // «ملاحظة على سورة X · آية N»
const String kAyahNoteField = 'الملاحظة';
const String kAyahNoteHintNew = 'ستُضاف علامة على الآية مع الملاحظة';
const String kAyahNoteHintExisting = 'اترك الحقل فارغًا لإزالة الملاحظة وإبقاء العلامة';
const String kAyahNoteCancel = 'إلغاء';  const String kAyahNoteSave = 'حفظ';
const String kAyahNoteFailed = 'تعذّر الحفظ، حاول مرة أخرى';
String kAyahNoteCreated(String surah, int ayah);                // «تمت إضافة علامة مع ملاحظة على سورة X · آية N»
String kAyahNoteSaved(String surah, int ayah);                  // «تم حفظ الملاحظة على سورة X · آية N»
String kAyahNoteRemoved(String surah, int ayah);                // «تمت إزالة الملاحظة من سورة X · آية N»
String kAyahRowTitle(String surah, int ayah);                   // «سورة X · آية N»
String kAyahRowPage(int page);                                  // «ص P»
const String kAyahRowWord = 'آية';  const String kAyahOwnerGeneral = 'عامة';
String kAyahRowLabel(String surah, int ayah, int page, String owner);   // «علامة على سورة X آية N، صفحة P، ثم اسم الورد أو عامة»
const String kAyahNoteShowLabel = 'عرض الملاحظة';                // FR-028
const String kAyahNoteEdit = 'تعديل';  const String kAyahNoteClose = 'إغلاق';
const String kAyahTintTitle = 'تظليل الآيات التي عليها علامة';
const String kAyahTintSubtitle = 'ظلّ خفيف خلف كل آية عليها علامة في صفحة المصحف';
```

The «تراجع» label is `kBookmarkUndo` of feature 006. The file defines exactly the strings of the spec's Assumptions table,
one constant or function each, and the strings test pins them.

## Tests mapped to contracts

| Contract | Test file (all new, except the two numbers of D13) |
|---|---|
| db.dart, migration | `test/migration/*` |
| repository, undo, 006 fix | `test/ayah_bookmarks/ayah_bookmark_repository_test.dart`, `page_toggle_fix_test.dart` |
| backup | `ayah_bookmark_backup_test.dart` (+ one number in `test/backup/backup_service_test.dart` and one in `test/settings/backup_ui_test.dart`, D13) |
| `ayahTintIds` | `ayah_tint_ids_test.dart` |
| `AyahTintSettings` | `ayah_tint_settings_test.dart` |
| controller | `controller_ayah_test.dart` |
| sheet rows, note field, note view | `ayah_sheet_rows_test.dart`, `ayah_sheet_note_row_test.dart`, `ayah_note_dialog_test.dart`, `reader_ayah_note_test.dart`, `ayah_sheet_show_note_test.dart` (FR-028, which also pins its three strings) |
| list row | `bookmarks_list_ayah_row_test.dart` |
| tint painting, geometry, rebuild | `mushaf_page_tint_test.dart`, `reader_tint_test.dart`, `reader_tint_geometry_test.dart`, `reader_tint_rebuild_test.dart`, `tint_contrast_test.dart` |
| Settings switch | `settings_tint_switch_test.dart` |
| page icon fix at reader level | `reader_page_icon_test.dart` |
| opening from the list | `reader_open_ayah_bookmark_test.dart` |
| end to end, look and size, strings | `reader_ayah_bookmark_test.dart`, `ayah_bookmark_look_size_test.dart`, `ayah_bookmark_strings_test.dart` |
