// Every Arabic string of the reader's bookmark icon (feature 006, contracts/dart-interfaces.md).
//
// These are PROPOSALS until the owner confirms them (task T015, Constitution VI). Changing one means the owner must
// confirm it again. N is the page number, written with Western digits like the page number the page draws.

/// Tooltip and screen-reader label while the page has no bookmark of the current scope.
String kBookmarkAdd(int page) => 'إضافة علامة للصفحة $page';

/// Tooltip and screen-reader label while the page has one.
String kBookmarkRemove(int page) => 'إزالة العلامة من الصفحة $page';

/// What a screen reader hears as the state of the icon.
const String kBookmarkStateOn = 'عليها علامة';
const String kBookmarkStateOff = 'ليس عليها علامة';

/// The message after an add and after a removal.
String kBookmarkAdded(int page) => 'تمت إضافة علامة للصفحة $page';
String kBookmarkRemoved(int page) => 'تمت إزالة العلامة من الصفحة $page';

/// The action of both messages.
const String kBookmarkUndo = 'تراجع';
