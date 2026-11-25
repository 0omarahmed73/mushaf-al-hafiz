# Research: Ayah Bookmark

Decisions made before design. Each has the decision, the reason, and what was set aside. Code facts were read on
2026-11-25 (`lib/wirds/db.dart`, `wird_repository.dart`, `bookmarks_sheet.dart`, `lib/mushaf/*`, `lib/ayah/ui/ayah_sheet.dart`,
`lib/backup/backup_service.dart`, `lib/settings/*`, `lib/look/*`, `test/support/*`).

## D1. Schema version 2: two nullable columns, checked together

**Decision**: `Bookmarks` gets `surah INTEGER NULL` and `ayah INTEGER NULL`. `schemaVersion` becomes 2. The constraints:

- `surah`: `CHECK (surah IS NULL OR surah BETWEEN 1 AND 114)`.
- `ayah`: `CHECK ((ayah IS NULL) = (surah IS NULL) AND (ayah IS NULL OR ayah BETWEEN 1 AND 286))` (286 is the longest surah).

The cross-column "both or neither" lives on `ayah`, the column added second, because SQLite refuses a CHECK that names a column
that does not exist yet when the column is added with `ALTER TABLE ... ADD COLUMN`; every INSERT and UPDATE of the row checks
it, whichever column is written. That an ayah really exists in its surah (`ayah <= surah's count`) and that `page` is where it
begins are not expressible in SQL here (the counts live in `meta.json`); they are enforced where rows are made: the
repository's ayah methods take the page from `MushafMeta.pageOfAyah` (the reader supplies it) and the backup import validates
(D3). A fresh install creates the version-2 table directly through `onCreate` (drift's `createAll`), which is the same DDL as
the migration produces (D2 proves it).

**Reason**: nullable columns are the one change that cannot lose or rewrite an old row (every old bookmark reads as a page
bookmark, `surah` and `ayah` null), and `ADD COLUMN` rewrites nothing. The page stays in every row, so old code, the list's
order, the backup's `page` field and the `page` CHECK keep working (FR-009).

**Alternatives**: a new `AyahBookmarks` table (two tables to list, delete, back up and keep in order, and `watchBookmarks`
would need a union: more code and more ways to lose data); one `ayahKey` text column (`"2:282"`: not checkable, not sortable,
needs parsing); replacing `page` by the ayah (breaks old code and the page bookmarks); a `kind` column (redundant with
`surah IS NULL`).

## D2. The migration: idempotent, transactional, proved on a real file

**Decision**: `MigrationStrategy.onUpgrade(m, from, to)` does, for `from < 2`, inside one transaction:

1. if `PRAGMA table_info(bookmarks)` has no `surah`, `m.addColumn(bookmarks, bookmarks.surah)`;
2. if it has no `ayah`, `m.addColumn(bookmarks, bookmarks.ayah)`.

Each step is guarded by the table's real columns, so a migration that was stopped after step 1 and starts again does not fail
with "duplicate column": the app can never be left unable to open. drift sets `user_version` only after `onUpgrade` returns,
so an interrupted run is retried at the next start; SQLite's DDL is transactional, so with the explicit transaction a stopped
run also leaves no half step (whether drift already wraps `onUpgrade` in its own transaction is verified by the interruption
test; the guards make the result right either way). `beforeOpen` (foreign keys on) is unchanged. No row is read, written or
deleted by the migration.

**Proof (test-first, FR-013, SC-003)**:

- **A real version-1 file.** Before the first edit of `lib/`, a skipped-unless-asked test (`make_v1_fixture_test.dart`, run with
  `--dart-define=MAKE_DB_V1=true`) opens a file database with the UNCHANGED code (so `user_version = 1` and the real v1 DDL),
  fills it through the real repository (at least 50 bookmarks: general, of 3 wirds, with and without notes, pages 1 and 604,
  Arabic notes of 200 characters; 3 wirds; 12 portions; 8 settings including `activeWirdId`, `textSizePercent`, `appLook`),
  closes it and writes `test/migration/fixtures/mushaf_v1.sqlite` and `mushaf_v1_expected.json` (every row of every table, as
  text). Both are committed before any change to `db.dart`; after that the generator can only run against a v1 layout, so it
  stays skipped and says so in its header.
- **The migration test** copies the fixture to a temporary file (never opens the committed one in place), opens it with the new
  `AppDatabase` over `NativeDatabase(file)`, and compares every row of `wirds`, `wird_days`, `bookmarks`, `settings` with the
  expected JSON field by field, `surah`/`ayah` null on every bookmark, `user_version` 2, `PRAGMA foreign_key_check` empty.
- **Layout equality**: `PRAGMA table_info` and the normalised `sqlite_master.sql` of `bookmarks` after migration equal those of a
  fresh install (a fresh in-memory database), so the two paths cannot drift apart.
- **Interruption**: a test-only `migrationDebugHook` (like `BackupService.debugHook`) throws after step 1; the file then opens
  again, finishes, and all rows are equal; and a database that already has both columns opened as version 1 (the half-finished
  state) opens without error.
- **Check works**: inserting `surah` without `ayah`, `ayah` without `surah`, `surah` 0 or 115, `ayah` 0 or 287 fails; a page
  bookmark and an ayah bookmark insert.
- **Size guard**: 5 000 bookmarks migrate in under 1 s.

**Alternatives**: drift's schema tooling (`drift_dev schema dump`, `schema steps`, `SchemaVerifier`): it is the project's own
dev dependency and is the right tool from the second migration on, but for one additive step it adds generated files
(`drift_schemas/`, `test/generated/`) and a build step, and proves less than a real file: the verifier checks the structure, not
that a year of rows survives. Recorded: adopt it at schema 3. Recreating the table (copy, drop, rename): needed only for
changes `ADD COLUMN` cannot do, and it is the riskier way to touch the owner's data. A backup export before migrating inside
the app: the owner exports by hand first (quickstart), and an automatic file would be a new place data leaves the database
(Principle IV).

## D3. Backup: version 2 only when needed; ayah bookmarks validated against the real Mushaf

**Facts** (`lib/backup/backup_service.dart`): `kBackupVersion = 1` is both what is written and the highest version read;
`_parse` throws `BackupProblem.newerVersion` when `version > kBackupVersion` (line `if (version > kBackupVersion)`), which
`settings_screen.dart` shows as «هذه النسخة الاحتياطية أحدث من هذا التطبيق. لم يتغيّر شيء.»; `importJson` replaces all tables
in one transaction with `debugHook` stages.

**Decision**:

- **Writing**: `exportJson` writes `version: 2` and, on every bookmark, the keys `surah` and `ayah` when the table holds at
  least one ayah bookmark; otherwise `version: 1` and no `surah`/`ayah` keys: byte-for-byte what today's code writes. So a
  phone that never uses ayah bookmarks keeps producing files an older build reads, and `test/kahf/kahf_backup_test.dart`
  (`expect(kBackupVersion, 1)`) and `backup_service_test.dart` (`map['version'] == 1`) stay true.
- **Constants**: `kBackupVersion` stays `1` and keeps meaning "the base format" (nothing existing changes); new
  `kBackupVersionAyah = 2` is the version that carries ayah bookmarks; `kBackupHighestRead = kBackupVersionAyah` is what
  `_parse` compares with (`version > kBackupHighestRead` → `newerVersion`).
- **Reading version 1**: unchanged, and a bookmark that carries a non-null `surah` or `ayah` in a version-1 file is invalid
  (a v1 file never has them). **Reading version 2**: `surah` and `ayah` are both absent/null (a page bookmark) or both ints;
  `surah` 1..114; `ayah` 1..`meta.surah(surah).ayahs`; `page == meta.pageOfAyah(surah, ayah)`; otherwise `BackupProblem.invalid`,
  nothing written. `note` is read as today (no length limit on import: a restored note is never lost for being long).
- **Where the meta comes from**: `BackupService` gets a `MushafMeta? meta` constructor argument (`main.dart` passes
  `await mushafRepository.loadMeta()`, which it already awaits for the PDF job on the next lines). `check` stays synchronous.
  A file with an ayah bookmark and no meta is refused as invalid (it cannot be checked): production always has the meta;
  existing tests that build `BackupService(db)` never import ayah bookmarks, so they are unchanged.
- **An older build given a file with ayah bookmarks** reads `version: 2` and takes the `newerVersion` branch above: it shows
  the existing message and changes nothing. The guarantee is the old code's, cited above; the test asserts that the exported
  file says `version: 2`, which the old rule `version > 1` refuses.
- The Settings switch `ayahTint` is one more entry of the `settings` map: nothing special in the format. An older build keeps it
  as an unused setting (its `_parse` accepts any string setting).

**Reason**: the owner's phone has a release build; a rollback or a second device should not need a new format when nothing new
is in the file. The version field says what the file needs. It is one parser reading one format with optional keys.

**Alternatives**: always writing 2 (the first draft: it would break the two existing assertions and make every file unreadable
by an old build for nothing); a separate `ayahBookmarks` list (then an old build would read the file, silently dropping the
ayah bookmarks, and restoring would lose them: worse than refusing); checking existence by loading the meta inside
`importJson` (async, and `check` is sync).

## D4. Repository: ayah operations, undo, and the fix of the 006 toggle

**The bug** (`wird_repository.dart`, `toggleBookmark`): it selects every bookmark with `page == page` and the scope's owner and,
when any exists, deletes all of them. Once ayah bookmarks exist, the page icon would delete them, and
`ReaderController._updatePageBookmarked` would fill the icon for an ayah bookmark (it tests `page` and `wirdId` only).

**Decision**:

- `toggleBookmark(page, {wirdId})` adds `& b.surah.isNull()` to its selection (page bookmarks only) and `addBookmark` is
  unchanged. `ReaderController._updatePageBookmarked` adds `b.surah == null`. These are the only 006 edits; every 006 test uses
  page bookmarks (`surah` null) and stays green; the new regression test fails on the old code (it makes an ayah bookmark
  first).
- New, each in one transaction and decided from the database:
  - `toggleAyahBookmark(AyahRef ref, {required int page, int? wirdId}) → AyahBookmarkChange`: rows of (surah, ayah, scope): none
    → insert one (no note) → `added(id)`; some → delete them all → `removed(rows)`.
  - `saveAyahNote(AyahRef ref, {required int page, int? wirdId, String? note}) → AyahBookmarkChange?`: trims; rows of the scope;
    the four cases of FR-021: no row and a non-empty note → insert with the note → `createdWithNote(id)`; rows and a non-empty
    note → update `note` of every row (id, page, owner, time untouched) → `noteReplaced(before)` where `before` is the rows
    before; rows and an empty note → set `note` null → `noteCleared(before)`; no row and an empty note → `null` (nothing
    written, no message).
  - `undoAyahBookmarkChange(change)`: `added`/`createdWithNote` → delete that id; `removed` → re-insert the rows with their id,
    `createdAt`, note, surah, ayah (`insertOrIgnore`; a deleted wird makes it general, as 006); `noteReplaced`/`noteCleared` →
    write each `before` note back by id; run twice changes nothing more.
  - `ayahBookmarkRows(ref, wirdId)`: the sheet's state (is there a bookmark, what note) read when the sheet opens and after a
    tap.
- The page given to `toggleAyahBookmark`/`saveAyahNote` is checked 1..604 only; that it equals `pageOfAyah` is guaranteed by
  the one caller (the reader controller, which holds the meta) and tested there, and validated again on import.
- A pure helper `ayahMarksOf(List<Bookmark> rows, int? scopeWirdId) → Set<AyahRef>` (rows with a surah in the scope) is what
  the controller and the tests share.

**Reason**: one source of truth next to the 006 methods; the same shape as `BookmarkToggle`/`undoBookmarkToggle` so the message
and the undo work the same way; `BookmarkToggle` itself is left untouched so feature 006's tests and code stay as they are.

**Alternatives**: extending `BookmarkToggle` with note kinds (touches 006's value and its tests); making the page icon filter
in the controller only (leaves the repository able to delete ayah bookmarks: the bug stays one call away); a stream
`watchAyahBookmarks(page, scope)` per page (rejected for the reason of feature 006 D2: a long-lived drift stream hangs tests that
write inside `runAsync`, and re-subscribing per page leaves a wrong-state gap).

## D5. Controller state: one list, two derived values

**Decision**: `ReaderController` keeps its one-shot `_bookmarks` list (`refreshBookmarks()` after its own writes, after the
«علامات» sheet closes, on wird replacement and on `reload()` after a restore: unchanged from 006 D2). From it:

- `pageBookmarked` (006): now `b.page == _page && b.wirdId == scope && b.surah == null`.
- `ayahMarks`: `ValueListenable<Set<AyahRef>>`, recomputed in the same places as `pageBookmarked` and replaced only when the set
  really changed (`setEquals`), so a bookmark change on another page or in another scope notifies nobody. It does not call
  the controller's `notifyListeners()` (so the screen is not rebuilt, as for the icon).
- Ayah actions: `ayahState(ref)` (synchronous, from the in-memory rows: has a bookmark of the scope, its note), `toggleAyahBookmark(ref)` and `saveAyahNote(ref, note)`
  with the same busy guard as `toggleBookmark` (a second call while one is being written returns null and writes nothing),
  each followed by `refreshBookmarks()`. The page is `meta.pageOfAyah(ref.surah, ref.ayah)`; the controller gets the meta
  from the reader at `init` (`attachMeta`) so it stays free of assets.

- **While the «علامات» sheet is open** (as built): the sheet deletes and adds rows on the repository directly, and the
  controller reads the table again only when the sheet closes (`_openBookmarks` calls `refreshBookmarks()` after it). So the
  page behind the sheet keeps the tint of a row deleted there until the sheet closes, and loses it in the first frame after
  (the test "a delete from the list sheet" of `reader_tint_test.dart`); the page icon of 006 behaves the same way.

**Reason**: the same lessons as 006: answered from memory in the same frame, no flicker, no per-page query, no stream.

## D6. Painting the tint: the highlight's own path, one more colour, a per-page listener

**Facts**: `MushafPage._word` wraps a word's `Text` in `DecoratedBox(color: highlightColor, radius 4)` when its id is in
`highlightedWordIds`; a `DecoratedBox` adds no size, so the layout cannot move. `_PageItem` caches its `MushafPageCard` and
rebuilds it only when data, family, look, meta or the highlight set (`setEquals`) change (feature 010 T010). Page pictures and
PDF pages draw the same card with no highlight.

**Decision**:

- `PageLook` gets `bookmarkTint` (additive, with a default) and `MushafPage`/`MushafPageCard` get `tintedWordIds` (default
  empty) and `tintColor`. In `_word`, a word in the highlight set is decorated with `highlightColor` exactly as today; else a
  word in the tint set is decorated with `tintColor` (same radius 4, same `DecoratedBox`). So the highlight wins and replaces the
  tint (no blend), and while the menu is open the highlighted ayah looks exactly as before the feature (FR-023). The
  end-of-ayah marker is a word of the page, so it is tinted with its ayah.
- **The ids come from the page's own words**: `ayahTintIds(PageData page, Set<AyahRef> marks)` returns the ids of every word of
  `page` whose `(surah, ayah)` is in `marks`. It never uses the bookmark's stored page, so no special case is needed (FR-025; no ayah crosses a page in
  this edition, spec correction of 2026-11-26), and a surah's first ayah that begins on the previous page
  needs none either. About 140 set lookups per page.
- **Who listens**: each `_PageItem` listens to `controller.ayahMarks` (a `ValueListenableBuilder` below the card cache) and to
  `AyahTintSettings.enabled` (`context.watch`, null provider = on). It computes the ids with `ayahTintIds` for its own `PageData`
  and passes them to `_cardFor`, which compares them with `setEquals` like the highlight. A change that alters no word of this
  page returns the cached card: `MushafPage` is not built (the budget of FR-026). The pager (`_pagerFor`) is not rebuilt: it
  passes the same notifier object every time.
- **Colours** (tokens in `PageLook`, measured over the page paper; hue is HSL, contrast is WCAG 2.x; the numbers are the test's
  expected values):

| Look | Paper | Highlight (blended on paper) | Tint token | Tint blended on paper | Hue of highlight / tint | Ink on tint | Tint vs paper |
|---|---|---|---|---|---|---|---|
| Emerald & Gold | `FBF5E3` | `0x55FFC107` gives (252,228,154) | `0x290F766E` (teal green, 16%) | (213,225,208) | 45 / 102 degrees (57 apart) | `14231D`: 12.04:1 | 1.24:1 |
| Night Reader | `0D1014` | `0x4D6CC4B5` gives (42,70,69) | `0x24E4C877` (gold, 14%) | (43,42,34) | 178 / 53 degrees (125 apart) | `ECE7DC`: 11.69:1 | 1.32:1 |

  The text keeps at least 4.5:1 with a wide margin (11.7 to 12.0); the one other coloured thing drawn on a tinted word, Night
  Reader's ayah end marker `6CC4B5`, has 7.0:1 on the tinted dark page (Emerald's markers use the ink). The limits the tests
  hold, so that "light" and "visible" are numbers: the tint blended on the paper has a contrast with the bare paper of **at
  least 1.15:1 (visible) and at most 1.50:1 (light, never a block of colour)**; the text and the end marker on it at least 4.5:1;
  its hue at least 40 degrees from the highlight's, and the highlight's wash is stronger than the tint's (a larger distance
  from the paper). The distinction from the highlight is hue (at least 40
  degrees, the spec's rule) and strength (the highlight is the stronger wash). The test recomputes all of these from the tokens, so
  a later change of a colour that breaks a rule fails. The owner confirms by eye on the phone (SC-015).
- The surah banner, the page number and the ayah end markers keep their colours; only the background of the word boxes changes.
  Words in a line are laid out with `spaceBetween`, so the gap between two tinted words is not tinted, exactly as with the
  highlight today (the page is a row of word boxes; a continuous band would need new geometry, which Principle I and II forbid).

**Alternatives**: a `CustomPaint` underlay of line-wide rectangles (a second layer to keep aligned with the word boxes, and
runs the risk of drifting from them); marking words in `PageData` (the data is the fixed edition and shared across tests:
never stored with state); one `ChangeNotifier` that rebuilds every page on any bookmark change (breaks the rebuild budget);
tinting through `Text.style.backgroundColor` (changes the text widget the tests and the highlight find by key); painting the tint
also under the highlight with alpha blending (two layers over each other muddy the highlight that the owner knows).

## D7. The tint switch: one key in `Settings`

**Decision**: key `ayahTint`, values `'true'`/`'false'`; absent or any other text reads as on. `AyahTintSettings`
(`ChangeNotifier`, like `TextSizeSettings` and `AppLookSettings`) has `enabled`, `load()` (never writes), `reload()` (after a
restore), `set(bool)` (saves at once, notifies only on a real change). `WirdRepository` gets `ayahTintRaw()` /
`setAyahTint(bool)` next to `appLookRaw()` / `setAppLook`. `MushafApp` provides it (`ListenableProvider<AyahTintSettings?>.value`
as for the text size; a null provider means on, so tests that do not build it are unchanged). `main.dart` loads it before the
first frame, so the first frame already has the right answer. The reader reloads it after a backup was restored, with the text
size and the look. The backup carries it as any setting.

**Alternatives**: a column (no: a setting is a setting); a separate table; reading the key on every page build (a read per
frame).

## D8. The two sheet rows: no hidden gesture

**Decision**: `showAyahSheet` gets an optional `AyahBookmarkPort? bookmarks` (null: no rows, so every existing sheet test is
unchanged). With a port, `AyahSheet` shows, after «معاني الكلمات» and before «الصفحة والسورة»:

1. the bookmark row (`ValueKey('ayah-bookmark')`): label «إضافة علامة على الآية» or «إزالة العلامة من الآية», icon
   `Icons.bookmark_add_outlined` / `Icons.bookmark_remove_outlined`, screen-reader value «ليس عليها علامة» / «عليها علامة». A tap
   calls `port.toggle(ref)`, pops the sheet and hands the change to `port.onChange`;
2. the note row (`ValueKey('ayah-note')`): label «ملاحظة للآية», icon `Icons.edit_note`, subtitle = the start of the note when
   the ayah has one (one line, ellipsis), value «عليها ملاحظة» / «ليس عليها ملاحظة». A tap opens the note field.

`SheetRow` gets two optional parameters (additive; null = today's behaviour): `semanticsValue` (the state heard; with a
value the row also carries its tap as the semantics action) and `subtitleMaxLines` (the note's start on one line, ellipsis).
FR-028 (the owner's request after trying the feature) adds a third row, `ValueKey('ayah-note-show')` «عرض الملاحظة»
(`Icons.sticky_note_2_outlined`), right after the note row and only when the scope's bookmark has a non-empty note; it opens
`showAyahNoteView` (the whole note, `ValueKey('ayah-note-view-text')`, with «تعديل», which goes on to the note field, and
«إغلاق»; reading writes nothing). The state is read with
the port's **synchronous** `state(ref)` when the sheet builds, from the controller's in-memory rows (refreshed after every write
and after the «علامات» sheet closes), so the first frame of the sheet already shows the right state (SC-002: no frame with a
wrong state, no future to wait for); the decision of a tap still comes from the database in one transaction. A tap always
closes the sheet, so the next opening reads again. The note field is a dialog (`showDialog`) over the sheet; cancel returns to the sheet; save closes
both and reports the change.

**Reason**: the owner asked for a visible second action and no hidden gesture. The long press that opens the sheet already
exists (feature 002). A long press on the row, an icon on the same row, a swipe or a popup menu would each be a hidden gesture or
a smaller target; two full rows are the simplest, the most reachable by a screen reader (each is one button), and need no
custom semantics action.

**Alternatives**: one row with a trailing small "note" button (a second target inside a row, 48 px not guaranteed at 320 dp);
a long press on the bookmark row (what the first brief said; the owner's correction replaced it); putting the note in the
«علامات» list (not where he said).

## D9. The note field

**Decision**: `showAyahNoteDialog(context, title:, initialNote:, bookmarkExists:, onSave:)` → `bool?` (true = saved and closed; `onSave`
does the write and may throw). Layout like the page-note dialog of `bookmarks_sheet.dart`: `AlertDialog`, title «ملاحظة على سورة X · آية N»,
`TextField` (`ValueKey('ayah-note-field')`, autofocus, `maxLength: 200`, `minLines: 1`, `maxLines: 3`, `counterText: ''`, label
«الملاحظة»), the dialog `scrollable: true` so that the title scrolls with the field and the buttons stay below (T042: at 320 dp
with a 2x font the title alone is eight lines), under it one line telling what saving will do («ستُضاف علامة على الآية مع الملاحظة» when the ayah has no bookmark,
«اترك الحقل فارغًا لإزالة الملاحظة وإبقاء العلامة» when it has one), buttons «إلغاء» and «حفظ» (`ValueKey('ayah-note-save')`,
48 px). The sheet's `onSave` calls the port's `saveNote`; a `null` result of the repository (case d) closes the
dialog and the sheet with no message. A thrown error keeps the dialog open with the typed text and shows a short line
(«تعذّر الحفظ، حاول مرة أخرى») in the dialog.

**Reason**: the same control the owner already knows from the page-note dialog; the explanatory line replaces the hint a hidden
gesture would have needed.

## D10. List rows and opening an ayah bookmark

**Decision**: `_BookmarkTile` shows, for a bookmark with `surah != null`: leading `Icons.auto_stories_outlined` (22 px, the
card's ink), title «سورة X · آية N» (X from the meta: the sheet reads it through `context.read<MushafRepository>().loadMeta()`
once, or the reader passes `meta`; the sheet gets an optional `MushafMeta? meta` and falls back to «آية N» with the surah
number if absent), then «ص P», the note and the owner tag exactly as today; its tag may shrink (`Flexible`) so «ص P» is never
pushed out. A page row is unchanged, except that its tag takes at most half the row (T042: a long wird name hid «ص P» at
320 dp with a 2x font; a shorter tag lays out exactly as before). Tapping an ayah row pops
`AyahTarget(AyahRef(surah, ayah), page)` (the class of feature 011); a page row still pops the `int`. The reader's
`_openBookmarks` becomes `showModalBottomSheet<Object>` and, for an `AyahTarget`, calls `_showFoundAyah(target)` (feature 011's
own method: it reads the page's words, sets the highlight and the reveal, and jumps only if the page is not the one shown, in
browse mode as the index does). The first touch clears the highlight through the existing pointer listener; the tint stays (it
is the permanent mark, and the highlight replaces it on those words while it lasts). `_clearFound()` at the start of
`_openBookmarks` is already there.

**Alternatives**: a new highlight mechanism (duplicates 011's and its tests); jumping to the page and showing nothing (the owner
asked for the ayah itself).

## D11. Tests first, in this order

1. Before any `lib/` edit: the **real v1 fixture** (D2) and the **geometry baseline** of the reader with no bookmark
   (`reader_tint_geometry_test.dart` records rectangles of the page, lines, words and top bar on the unchanged code at 412 x 915
   and 320 x 640 in both looks; they must stay equal with the tint on and off).
2. Repository tests (toggle, note cases, undo, scopes) and the **006 regression** (red on today's code).
3. Migration tests (red until `onUpgrade` exists), then backup tests.
4. Pure tests: `ayahTintIds`, the colour rules, `AyahTintSettings`.
5. Controller, sheet, dialog, list row, reader end-to-end, tint painting, rebuild budget, look and size.
6. Strings pinned. Each implementing task is preceded by its failing test (Constitution IX, one commit per task).

## D12. The shared tree: smallest edits to the four big files

`reader_screen.dart` (1 242 lines), `mushaf_page.dart`, `ayah_sheet.dart` and `bookmarks_sheet.dart` are touched by earlier
features whose tests must stay green. Edits are additive and small, each its own task, each after `git status` and
`git log -- <file>`: `reader_screen.dart` gets (a) the port passed to `showAyahSheet` in `_openAyahMenu`, (b) the `Object` result
of the list, (c) the tint wiring in `_PageItem`, (d) a new message helper `_showAyahBookmarkMessage` (the 006
`_toggleBookmark` is left as it is, not refactored), (e) the reload of the tint switch after a restore. The khatm dua lines, the
pager cache, the pointer listener, the bars and the search code are not edited.

## D13. Existing tests that must change, and why (FR-020)

A grep of `test/` for what this feature can break found exactly:

- `test/backup/backup_service_test.dart` line 160-161: `version 2 is a newer backup` (`m['version'] = 2` expecting
  `newerVersion`). After this feature version 2 is read, so the number becomes 3. This is the one deliberate edit of an existing
  test, its own task, its own commit, with this paragraph as the reason.
- `test/settings/backup_ui_test.dart` (the case "another app's file, a newer backup and a damaged file are refused"): it puts
  `'version': 2` on a page-only file and expects the newer-backup message. Same reason, same one-number edit (2 to 3), made with
  T011. The first grep missed it; it was found when T011 ran (commit b120f93 records the stop).
- `test/kahf/kahf_backup_test.dart:124` `expect(kBackupVersion, 1)` and `backup_service_test.dart:70` `map['version'] == 1` stay
  true on purpose (D3).
- Any test that counts the rows of the ayah sheet through the reader (the reader now passes a port): found by running the whole
  suite after T021 (the reader passes the port); if one counts rows, the count is not edited, the reader adds the rows only when the port is
  provided and the sheet tests pass no port; a reader-level test that fails is reported to the owner rather than edited (the
  task says so).
- `schemaVersion` is not asserted anywhere in `test/` (grep), so nothing else follows from 1 to 2.

## D14. The web version (feature 012) is paused

Nothing is built for it. The data format stays one: the same `Bookmarks` columns would map to the same backup keys (`surah`,
`ayah`, `note`), the same settings key `ayahTint`, and the same rules (scope, both-or-neither, page of the ayah from the fixed
edition). When feature 012 resumes it reads and writes this file; this feature's backup tests are the contract.

## D15. The phone, and what a test cannot show

The owner's phone <phone>: never unlocked by the agent; any input and any install needs the owner's OK; a backup is
exported by the owner first (the update goes over the existing release build, which is the real migration of real data). What
only the phone shows: the update over the real data, the look of the tint on the real screen in both looks and in sunlight,
whether the tint and the highlight are told apart, the long press then the two rows by hand, the note keyboard, page-turn
smoothness with many bookmarks (feature 010's frame measurement script is reused), the back gesture on the note field.

## Measured (T043, 2026-11-25)

Taken on the main checkout after T042 (commit a858970), on the development machine, no phone.

- **`flutter analyze`**: `No issues found!`. Two `curly_braces_in_flow_control_structures` infos in this feature's own tests
  (`mushaf_page_tint_test.dart`, `tint_contrast_test.dart`) were fixed by adding the braces; no assertion changed.
- **The whole `flutter test`**: 2328 passed, 1 skipped, 0 failed (8 min 21 s). Before T041 it was 2297 passed, 1 skipped; the 31
  more are `test/ayah_bookmarks/ayah_bookmark_look_size_test.dart`.
- **`dart format`**: the 34 Dart files this feature created are clean. Of the earlier files it edited, `mushaf_page.dart`,
  `mushaf_page_card.dart`, `test/backup/backup_service_test.dart` and `test/settings/backup_ui_test.dart` were not
  format-clean before the feature (commit 257370a) and were left as they are; the others were clean and still are.
- **Nothing added** (FR-018): `git diff 257370a HEAD -- pubspec.yaml pubspec.lock android assets` is empty.
- **T032, the numbers `tint_contrast_test.dart` prints** (they equal the table of D6):

| Look | Tint on paper | Highlight on paper | Ink on tint | End marker on tint | Tint vs paper | Highlight vs paper | Hue highlight / tint | Wash highlight / tint |
|---|---|---|---|---|---|---|---|---|
| Emerald & Gold | (213,225,208) | (252,228,154) | 12.04:1 | (the ink) | 1.24:1 | 1.15:1 | 45.3 / 102.4 (57.0 apart) | 75.0 / 47.0 |
| Night Reader | (43,42,34) | (42,70,69) | 11.69:1 | 7.00:1 | 1.32:1 | 1.87:1 | 177.9 / 53.3 (124.5 apart) | 78.5 / 42.1 |

- **T037** prints nothing; what it asserts passed: with 200 ayah bookmarks and the tint on, every measured rectangle of
  `reader_tint_geometry_test.dart` equals the literal taken before the feature (0 px difference, both looks, both sizes), and in
  `reader_tint_rebuild_test.dart` a page turn builds `MushafPage` at most once and reads no bookmark, a bookmark change on
  another page and a database answer that changes no tint build it 0 times, one bookmark added or removed builds only the page
  that shows it, a bars toggle builds none. The three files together are 49 tests, all green.
- **T041 found, T042 fixed** (all with a 2x system font): the note field at 320 x 640 overflowed by 48 px and «حفظ» could not be
  touched, and at 640 x 320 the field was cut off (the title now scrolls with the field); the page row of «علامات» at 320 x 640
  lost «ص P» behind a long tag (the tag now takes at most half the row). Contrast (4.5:1, texts and icons), 48 px targets and
  the look change needed nothing.
- **The T039 test's driver** (`settings_tint_switch_test.dart`, a test of this feature, fixed in commit fde230a before T040
  made it green): its back step tapped `BackButton` instead of looking for the English tooltip 'Back', and after a restore it
  waits for the «تم استرجاع النسخة الاحتياطية» message to go before tapping the bottom bar; no assertion changed.
- **Again at convergence (T049, 2026-11-25, after T051, commit 6fd29aa)**: `flutter analyze` `No issues found!`; the whole
  `flutter test` 2341 passed, 1 skipped, 0 failed (8 min 38 s): the 2328 of T043 plus the 13 of
  `ayah_sheet_show_note_test.dart` (T050).
- **Seen, older than this feature, not touched**: with a 2x system font the Mushaf page's lines and the reader's bars overflow
  (features 001 and 002; feature 006 T020), which puts «علامات» and the menu button of the bottom bar off a 320 dp screen; and
  at 640 x 320 with a 2x font the list of «علامات» is left a window about 21 px high under its heading and button.
