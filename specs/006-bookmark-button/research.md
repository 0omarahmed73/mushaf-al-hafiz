# Research: Bookmark Button in the Reader

Decisions made before design. Each has the decision, the reason, and what was set aside.

## D1. Placement: a Stack over the top bar, room reserved in the second row

**Decision**: `_TopBar` (84 px, `reader_screen.dart`) keeps its `Padding > Column` exactly. It is wrapped in a `Stack`
and the button is a `PositionedDirectional(end: 10, bottom: 0)` 48 × 48 child: it covers y 36–84 of the bar, so its
centre (y 60) is the centre of the second row, directly under the juz text (which is the first row's end side). The
second row gets `Padding(end: 48)` so the pill, the «اليوم» chip and, in browse mode, «اجعلها موضعي» never reach the
icon: «اجعلها موضعي» moves to the left of the pill side of the icon, never under it.

**Reason**: the row is 36 px and a 48 px target does not fit in it; a hit area cannot be larger than its parents'
bounds, but the bar is 84 px and only 72 px are used, so a Stack child can have the full 48 px without changing the
bar, the Column or the page below (FR-003, FR-010). The first row (surah name and juz text) ends at about y 34, so the
button does not overlap it.

**Alternatives**: making the second row 48 px (moves the pill and chip and shrinks the gap; changes existing layout);
a smaller 36 px button (fails the 48 px rule); putting the icon in the first row beside the juz text (not "under").

## D2. State: one list read once and refreshed, filtered synchronously

**Decision** (amended during T009: first written as a stream): `ReaderController` reads the table with a one-shot
`WirdRepository.bookmarkRows()` in `init()`, `reload()`, after its own `addBookmark()` / `toggleBookmark()` /
`undoBookmarkToggle()`, when the active wird is replaced, and (from the reader) after the «علامات» sheet closes, and
keeps the `Bookmark` rows (`refreshBookmarks()`). `pageBookmarked` is a `ValueNotifier<bool>` recomputed (a) when the
list is refreshed and (b) in `_notify()` (page, wird or browse mode changed): true when a row has `page == _page` and
`wirdId == scopeWirdId`, where `scopeWirdId = (_browsing || _wird == null) ? null : _wird!.id`. The icon listens to
this notifier only, so a bookmark change does not call the controller's `notifyListeners()` and the Mushaf page is
not rebuilt (SC-002, performance).

**Reason**: a page change is answered from memory in the same frame (no flicker, no wrong state while a per-page
query is in flight); the list is at most a few hundred small rows. Every writer is known: the icon, the controller's
own add, the sheet (refresh on close), the wirds screen (the reader reloads on return) and a restore (the reader
reloads), so the icon and the sheet agree whenever the user can see both. A long-lived drift `watch*` stream was
tried first and rejected: tests that write the database inside `tester.runAsync` while such a stream is listened in
the fake-async zone hang (a lesson of this project), and the stream gave no extra correctness here.

**Alternatives**: a stream `watchBookmarks()` for the controller's lifetime (the hang above); a per-page stream
`watchPageBookmarks(page, wirdId)` re-subscribed on every page change (a gap with a wrong state, more subscriptions);
reading the table on each tap only (stale icon after the sheet).

## D3. Operations decided from the database, in one transaction each

**Decision**: `WirdRepository.toggleBookmark(page, {wirdId})` in one transaction selects the rows with that page and
scope: none → inserts one (no note) and returns `BookmarkToggle.added(id)`; some → deletes them and returns
`BookmarkToggle.removed(rows)`. `undoBookmarkToggle(result)` deletes the added id, or re-inserts the removed rows with
their original `id`, `createdAt` and `note` (`InsertMode.insertOrIgnore`; a row whose wird has been deleted since is
re-inserted general, `wirdId` null). `ReaderController.toggleBookmark()` ignores a tap while the previous one is
being written (`_toggleBusy`), so a double tap cannot add twice; a second deliberate tap after the first finished
removes (FR-009). A failed write throws; the notifier is only changed by a refresh after a successful write, so the icon keeps the real state.

**Reason**: the decision never depends on what the screen believed; undo is exact (SC-009); ids are never reused by
SQLite (`AUTOINCREMENT`), so restoring the original id cannot collide.

**Alternatives**: toggling from the cached state (a stale cache could add a duplicate); undo by re-adding with new
ids (loses the order and the createdAt); one SnackBar per tap queued (replaced instead, D4).

## D4. The message: a floating SnackBar above the bottom bar

**Decision**: the reader shows `ScaffoldMessenger.of(context).showSnackBar` after `hideCurrentSnackBar()`, with
`behavior: SnackBarBehavior.floating`, a margin whose bottom is the bottom bar's 68 px plus 8 when the bars are
visible (so the message never covers the bar's «علامات» item, the page number or the icon), content from
`bookmark_strings.dart` and `SnackBarAction(label: 'تراجع')`. The action closure captures that tap's `BookmarkToggle`,
so «تراجع» undoes exactly that tap and only while the message is shown; a new tap replaces the message. The reader
already uses a plain SnackBar for the restored-backup message, so no new mechanism is introduced.

**Reason**: the standard, accessible, self-dismissing component; a floating margin keeps the bars usable.

**Alternatives**: a custom overlay (more code, same result); no message (rejected by the owner, spec Clarifications).

## D5. Semantics and tooltip

**Decision**: `BookmarkButton` is an `IconButton` (`Icons.bookmark_add_outlined` / `Icons.bookmark_added`; amended in T009: `bookmark_border` is the bottom bar's «علامات» icon and the feature 004 reader test finds it by glyph, and the outlined «add» glyph is the one the sheet's «إضافة علامة» button already uses) with
`tooltip` = the action text («إضافة علامة للصفحة N» or «إزالة العلامة من الصفحة N») and a `Semantics` wrapper
(`button: true`, `value`: «عليها علامة» or «ليس عليها علامة»). N is written with Western digits, like the existing
«إضافة علامة للصفحة N» in the sheet and the page number the page draws (`Text('$page')`).

**Reason**: the screen reader hears the action and the state; the tooltip shows on long press for sighted users.

## D6. Colours from the look

**Decision**: outlined `look.textSecondary` (the colour of the juz text next to it), filled `look.accent`; both are
drawn on `look.background` (the bar has no fill of its own). The contrast walk of `test/support/contrast_walk.dart`
checks both states in both looks; if either fails, the implementation picks `look.heading` for the filled state and
records it in this file.

**Reason**: no new colour; the two tokens already pass 4.5:1 on the background in their own checks.

## D7. Coordination and the files touched

**Decision**: `reader_screen.dart` is edited once, small, in one commit (the Stack, the row reserve, `_toggleBookmark`
with the message). Feature 004 (colours) and feature 005 (the khatm dua: `_onPagerScroll`, `_openDua`, `_lastSwipe`)
finished their edits there; those lines stay untouched. Right before editing: `git status` and
`git log -- lib/mushaf/reader_screen.dart`. `wird_repository.dart` and `reader_controller.dart` get additive methods
only. The other sessions (002, 003, 004) are idle; if one becomes active on these files, the one who edits second
rebases on the committed text.

## D8. Strings are proposals until the owner confirms them (Constitution VI)

**Decision**: all strings live in `lib/mushaf/bookmark_strings.dart` (spec Assumptions list them). A task near the end
shows the owner the exact text and asks; the feature is not done until answered.

## D9. Page geometry is pinned by a baseline test

**Decision**: before any edit, `reader_bookmark_geometry_test.dart` records, on the unchanged code, the rectangles of
`top-bar`, the pager page, `page-number`, `wird-pill` and the «اليوم» chip at 412 × 915 and 320 × 640 in both looks;
those numbers are literals in the test and the test stays green after the edit (SC-007, FR-003). The earlier layout
tests of features 001 to 004 stay unchanged.

## D10. Phone check

**Decision**: on the owner's phone (<phone>; never unlock it, ask before any input or install): the icon under
the juz text at the far left in both looks, one tap adds, a tap removes, «تراجع», the message above the bar,
browse mode with «اجعلها موضعي», rotation, large system font. The feel of the target is judged by the owner (SC-008).

## D11. Not in this feature

A note when adding with the icon, a list of the page's bookmarks on the icon, a long-press menu and an icon on
other screens are out of scope; the sheet stays the place for notes.
