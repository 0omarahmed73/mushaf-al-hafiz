# Data Model: Ayah Bookmark

The feature extends the `Bookmarks` table (`lib/wirds/db.dart`), adds one setting and one backup version. Nothing else in
the database changes.

## Bookmarks (schema version 2)

| Column | Type | Constraint | Meaning |
|---|---|---|---|
| `id` | integer | primary key, autoincrement (never reused) | unchanged |
| `wirdId` | integer, null | references `Wirds(id)`, `ON DELETE SET NULL` | the owner; null = general («عامة»); unchanged |
| `page` | integer | `CHECK page BETWEEN 1 AND 604` | a page bookmark: the page; an ayah bookmark: **the page where the ayah begins** (`MushafMeta.pageOfAyah`) |
| `note` | text, null | none in the database; the app's field stops at 200 characters | unchanged; now also the note of an ayah bookmark |
| `createdAt` | datetime | default now | unchanged |
| `surah` | integer, **new**, null | `CHECK surah IS NULL OR surah BETWEEN 1 AND 114` | null on every page bookmark and on every row made before version 2 |
| `ayah` | integer, **new**, null | `CHECK (ayah IS NULL) = (surah IS NULL) AND (ayah IS NULL OR ayah BETWEEN 1 AND 286)` | both or neither with `surah`; that the ayah exists in its surah is checked where rows are made and on import |

**Kind** (derived, never stored): *ayah bookmark* when `surah IS NOT NULL`, *page bookmark* otherwise.

**Rules**

- An ayah bookmark's `page` equals `pageOfAyah(surah, ayah)` (Constitution I; the user never chooses it). Checked by the
  controller when it makes the row and by the backup import.
- At most one ayah bookmark of the same (surah, ayah) per scope is ever created by the app (the toggle and the note save decide
  from the table in one transaction). A restored file may hold more; operations then act on all of them.
- A page bookmark may coexist with ayah bookmarks on the same page; they never replace each other.
- Deleting a wird sets `wirdId` to null on its bookmarks of both kinds (the existing foreign key); `surah`, `ayah`, `page` and
  `note` stay.
- Migration 1 to 2: both columns added by `ALTER TABLE ... ADD COLUMN`, each guarded by "the column is not there yet"; no row is
  changed (D2).

## Scope (extends feature 006's)

`scopeWirdId` is the active wird's id while the reader follows a wird, null (general) when browsing or with no wird.

| Question | Rows read |
|---|---|
| Does the page icon show «has a bookmark»? | `kind = page`, `page == page shown`, `wirdId == scopeWirdId` |
| Does the bookmark action show «remove»? / is the ayah tinted? | `kind = ayah`, `(surah, ayah) == ref`, `wirdId == scopeWirdId` |
| Does the note action show a note? | the ayah rows above; the first non-null `note` |
| Is «عرض الملاحظة» shown (FR-028)? | that note, not empty after trimming |
| What does the list show? | every row, newest first |

## AyahBookmarkChange (a value, not stored)

What one tap of the bookmark action, or one save of the note, did; kept by the message so «تراجع» undoes exactly that.

| Field | Constraint |
|---|---|
| `kind` | `added`, `removed`, `createdWithNote`, `noteReplaced`, `noteCleared` |
| `ref` | the ayah (`AyahRef`) |
| `page` | the page where the ayah begins |
| `addedId` | the new row's id for `added` and `createdWithNote`, else null |
| `removed` | the `Bookmark` rows deleted, for `removed`, else empty |
| `before` | for `noteReplaced` and `noteCleared`: `(id, previous note)` of every row the save changed, else empty |

Exactly one of the three payloads (`addedId`, `removed`, `before`) is set for each kind.

## The four saves of the note (FR-021)

| Ayah has a bookmark in scope? | Note after trimming | Result | Change kind | Message |
|---|---|---|---|---|
| no | non-empty | one bookmark with the note (owner as the bookmark action) | `createdWithNote` | «تمت إضافة علامة مع ملاحظة على سورة X · آية N» |
| yes | non-empty | note replaced on every row of the scope; nothing else changes | `noteReplaced` | «تم حفظ الملاحظة على سورة X · آية N» |
| yes | empty | note set to null; the bookmark stays | `noteCleared` | «تمت إزالة الملاحظة من سورة X · آية N» |
| no | empty | nothing | none (`null`) | none |

Cancelling is not a save: nothing is called.

## State transitions of the bookmark action

```text
no bookmark in scope --tap--> insert one, no note   --> bookmarked   (message «تمت إضافة…» + «تراجع»)
bookmarked           --tap--> delete the scope's rows --> none        (message «تمت إزالة…» + «تراجع»)
«تراجع» after an add             --> delete that id
«تراجع» after a removal          --> re-insert the rows (same id, createdAt, note, surah, ayah; wird gone -> general)
«تراجع» after createdWithNote    --> delete that id
«تراجع» after noteReplaced/Cleared --> write each `before` note back by id
```

## Controller state (not stored)

| Field | Meaning |
|---|---|
| `pageBookmarked` (`ValueListenable<bool>`) | the page icon: page rows of the page and scope only (the 006 field, now filtered by kind) |
| `ayahMarks` (`ValueListenable<Set<AyahRef>>`) | the ayat with an ayah bookmark of the scope; replaced only when the set changes; empty until the first read answers |
| `_bookmarks` | the rows of the last one-shot read (`bookmarkRows()`), refreshed by `refreshBookmarks()` |
| `_toggleBusy` | true while the icon's tap, an ayah tap or a note save is being written; a second call in that time is ignored |

## Tint (derived per page, never stored)

`ayahTintIds(page, marks)` = ids of the words of `page` whose (surah, ayah) is in `marks`. Empty when the setting is off.
No ayah crosses a page in this edition (spec correction of 2026-11-26), so an ayah bookmark's words are all on its stored
page; the function still reads the page's own words and never the stored page.

## Settings table: one new key

| Key | Values | Default |
|---|---|---|
| `ayahTint` | `'true'`, `'false'` | absent or unknown text = on |

## Backup file

```text
{ "app": "mushaf-hafiz", "version": 1 | 2, "exportedAt": ..., "wirds": [...], "wirdDays": [...],
  "bookmarks": [ { "id", "wirdId", "page", "note", "createdAt" }            // version 1, and version 2 page bookmarks
               | { ..., "surah": 2, "ayah": 282 } ],                         // version 2 only
  "settings": { ..., "ayahTint": "false" } }
```

| Rule | Version 1 file | Version 2 file |
|---|---|---|
| written when | no ayah bookmark exists (exactly today's bytes) | at least one exists; every bookmark then carries `surah` and `ayah` (null for a page bookmark) |
| read by this app | completely; a non-null `surah` or `ayah` makes it invalid | completely, after the checks below |
| read by an older build | yes | refused: `newerVersion`, the existing message, nothing changes |
| ayah bookmark checks | n/a | both present or both null; `surah` 1..114; `ayah` 1..the surah's count; `page == pageOfAyah(surah, ayah)`; else `invalid`, nothing written |
| restore | one transaction replacing all tables (unchanged); the settings kept on import (`tipsSeen`) unchanged | same |
