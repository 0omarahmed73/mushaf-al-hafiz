# Data Model: Bookmark Button in the Reader

No table, column or setting is added. The feature reads and writes the existing `Bookmarks` table
(`lib/wirds/db.dart`): `id` (auto-increment, never reused), `wirdId` (nullable, set null when the wird is deleted),
`page` (1 to 604), `note` (nullable), `createdAt`.

## Scope

The scope of a tap is `scopeWirdId`:

| Reader state | `scopeWirdId` |
|---|---|
| Following a wird (not browsing, a wird exists) | the active wird's id |
| Browsing, or no wird exists | `null` (general, «عامة») |

A bookmark is "of the current scope" when its `page` equals the page shown and its `wirdId` equals `scopeWirdId`
(`null` equals `null`). Only those bookmarks make the icon filled, and only those are removed by a tap (FR-005,
FR-006). Bookmarks of another wird, or general ones while following a wird, are never read or written by the icon.

## BookmarkToggle (a value, not stored)

The result of one tap, kept by the message so «تراجع» can undo exactly that tap.

| Field | Constraint |
|---|---|
| `page` | the page the tap was on (1..604) |
| `addedId` | the new bookmark's id when the tap added; `null` when it removed |
| `removed` | the `Bookmark` rows the tap deleted (id, wirdId, page, note, createdAt); empty when it added |

Exactly one of `addedId != null` and `removed.isNotEmpty` is true.

## Controller state (not stored)

| Field | Meaning |
|---|---|
| `pageBookmarked` (`ValueListenable<bool>`) | true when the page shown has a bookmark of the current scope; recomputed from the list when the list is refreshed, or the page, the active wird or the browse mode changes; false until the first read answers |
| `_bookmarks` | the rows of the last one-shot read (`bookmarkRows()`), refreshed by `refreshBookmarks()` |
| `_toggleBusy` | true while a tap is being written; a second tap in that time is ignored |

## State transitions

```text
not bookmarked --tap--> add one (no note)  --> bookmarked   (message «تمت إضافة…» + «تراجع»)
bookmarked     --tap--> remove all of scope --> not bookmarked (message «تمت إزالة…» + «تراجع»)
«تراجع» after an add    --> delete that id
«تراجع» after a removal --> re-insert the rows (same id, createdAt, note; wird gone -> general)
```
