# Data Model: Web Version (feature 012)

The web version adds **no table, no column and no change to the backup file format** (spec assumption, FR-040). The reader's data (wirds, wird days, bookmarks, settings) is the same four tables of
`lib/wirds/db.dart`, stored by drift in the browser (research D5). Everything below is either **web-only state kept in memory**, **a few `Settings` rows**, **the browser's caches**, or **files of the site**.
Names are the plan's proposals for the implementation.

## 1. Stored in the database (existing `Settings` table, key/value; no migration)

| Key | Value | Written when | In the backup file? |
|---|---|---|---|
| `webDataNoticeSeen` | `1` | the reader dismisses the first-use notice (FR-021) | exported like every setting (the exporter writes all rows), **ignored by Android** (unknown key); on **import** it is in `kKeptOnImport` (the existing set that keeps the device's own value when the file has none), so restoring a phone file does not bring the notice back |
| `webTipsPointer` | not stored | `InputKind` is decided in memory per session (research D15) | no |

Everything else the web needs of the existing settings (look, reading size, text size, `lastViewedPage`, `tipsSeen`, `activeWirdId`, reminder keys) is unchanged. **Reminder keys imported from a phone file are
kept and written back unchanged on export** (FR-023): the web code never deletes or rewrites `kahfEnabled`, `kahfDay`, `kahfMinutes`, `notifyEnabled`, `notifyMinutes` columns; a test imports a file with them and
exports it again and compares.

## 2. In-memory web state (`WebEnvironment`, provided only on the web; `null` on Android)

```text
WebEnvironment
  buildId        : String             # "1.0.0+<sha>", baked in by --dart-define=BUILD_ID
  dataVersion    : String             # 12 hex, baked in by --dart-define=DATA_VERSION (research D4)
  storage        : ValueListenable<StorageStatus>
  inputKind      : ValueListenable<InputKind>
  pack           : OfflinePack        # section 3
  update         : ValueListenable<UpdateState>
  instance       : InstanceGuard      # the one-tab guard
```

| Type | Values | Meaning | Transitions |
|---|---|---|---|
| `StorageStatus` | `unknown`, `durable`, `volatile`, `unsafeShared` | `durable`: IndexedDB or OPFS chosen by drift; `volatile`: `inMemory` (private window or storage refused): nothing survives; `unsafeShared`: a store that is not safe for several tabs and the lock API is missing | set once from drift's `onResult` at boot; never changes in a session |
| `InputKind` | `touch`, `pointer` | whether the last primary pointer event was a finger or a mouse/trackpad; selects tips wording and the on-screen arrows | any pointer event may flip it; the tips take the value at the time they open |
| `UpdateState` | `none`, `waiting`, `applying` | a new service worker is installed and waiting | `none` → `waiting` (worker reports) → `applying` (button pressed) → page reloads |
| `InstanceState` | `starting`, `owner`, `blocked` | the one-tab guard | `starting` → `owner` (lock acquired) or `blocked` (held by another tab); `blocked` → `owner` when the other tab closes and the reader presses «حاول مرة أخرى» |
| `PersistState` | `unknown`, `granted`, `denied`, `unsupported` | answer of `navigator.storage.persist()`/`persisted()` | `unknown` → one of the others after the download flow asked, rechecked at every start by `persisted()` |

## 3. The offline pack (the whole-Mushaf download, FR-031, research D10)

```text
PackManifest            # d/<dataVersion>/pack.json, written by tool/build_web.sh
  dataVersion  : String
  files        : List<PackFile>          # about 1,330 entries: the files of the pack under d/<dataVersion>/ (not source files, not requests); the build writes the exact number
PackFile
  path   : String        # relative to d/<dataVersion>/, e.g. "fonts/p293.woff2"
  bytes  : int           # exact length
  sha256 : String        # hex

OfflinePack            # state machine; no browser code inside (fetch, cache, lock are injected)
  state     : ValueListenable<PackState>
  start()   : Future<void>     # size sheet is shown by the UI before this is called
  stop()    : void
  recheck() : Future<void>     # compares the data cache with the manifest at every start

PackState
  idle        { missingBytes, totalBytes }              # button shown; missingBytes==0 means complete
  confirming  { missingBytes }                          # the size sheet
  running     { doneBytes, totalBytes, currentPath }
  stopped     { doneBytes, totalBytes }                 # the reader stopped it; resumable
  failed      { doneBytes, totalBytes, reason }         # reason: network | quota | integrity
  complete    { totalBytes }
```

**Rules (validation)**:
- `idle.missingBytes = sum(bytes of files whose path is not in the data cache with the same length)`; `complete` only when that sum is 0 after `recheck()`; the tile **never** claims complete without checking
  (eviction, D11).
- A file is written to the cache only after its length and sha256 equal the manifest's; a mismatch counts as a failed file (`integrity`), is retried, and is never cached (Principle I: a corrupt font is never served
  from the cache).
- `start()` while `running` is a no-op (single flight); a second tab cannot start it (Web Lock `mushaf-al-hafiz-pack`).
- `stopped` and `failed` keep every file already cached; `start()` resumes by skipping cached files.
- `QuotaExceededError` → `failed(quota)`, removes nothing.
- Order of fetching: page 1 to 604, fonts and their layout JSON together (so a partial pack is a readable prefix), then the ayah data; the reader's own on-demand fetches are never blocked by the run.

**Transitions**: `idle → confirming → running → complete`; `running → stopped | failed → running`; `complete → idle` when `recheck()` finds missing files.

## 4. The browser's caches (written by `sw.js` and by `OfflinePack`; never by the database code)

| Cache name | Holds | Created | Deleted |
|---|---|---|---|
| `shell-<buildId>` | the core list and every same-origin file of the shell that the page loaded (captured after first load, then at runtime): `index.html`, `flutter_bootstrap.js`, `main.dart.*`, the engine variant the browser uses, `sqlite3.wasm`, `drift_worker.js`, icons, `assets/**` that remain (app fonts, `AssetManifest`, `FontManifest`, `NOTICES`, the dua, `sources.json`) | at `install` (core), filled by the capture message and at runtime | at `activate` of a later worker (any `shell-*` that is not its own) |
| `data-<dataVersion>` | the files of `d/<dataVersion>/` the reader opened, or all of them after the pack | first fetch of a data file | at `activate` of a worker whose `dataVersion` differs |

A cached data file is exactly the bytes of the site's file (checked by sha256 only in the pack path; the on-demand path trusts the immutable URL and the host's integrity). Page turning needs a font **and** its layout
JSON: the web bundle reports a page ready only when both were read, so Principle I's «a page is shown only when its own font and layout are ready» holds offline as online.

## 5. Files of the site (what exists after `tool/build_web.sh`; full tree in `contracts/site.md`)

| Entity | Fields | Rule |
|---|---|---|
| `dataVersion` | 12 hex of `sha256` over the sorted `path:sha256` lines of `d/<v>/` (without `pack.json`) | recomputed on every build; equal data gives an equal version, so an unchanged Quran dataset never invalidates readers' caches |
| `buildId` | `<pubspec version>+<git short sha>` | in `sw.js`, `version.json`, the app and Settings |
| `core list` | `index.html`, `flutter_bootstrap.js`, `manifest.json`, `icons/Icon-192.png`, `version.json` | the only precache of install; about 0.5 MB |
| `sw.js` | build id, data version, core list, three rules (research D9) | generated from `web/sw.js.in`; its bytes change with every build so browsers see an update |
| `vercel.json` | headers only | no rewrites (the app has no routes and no deep links) |

## 6. Relationships

```text
AppDatabase (drift, in the browser)  --onResult-->  StorageStatus  --> notices (Settings, start)
InstanceGuard (Web Lock)             --blocked-->   the one-tab screen (the database is not opened)
WebDataBundle(dataVersion)           --fetch-->     d/<dataVersion>/...  <--cache-first-- sw.js (data-<dataVersion>)
OfflinePack                          --cache.put--> data-<dataVersion>    <-- manifest (pack.json)
sw.js (waiting)                      --message-->   UpdateState --> Settings line and button
```

No entity here reaches the Quran text: the text, its order and the page and line distribution stay exactly the generated files (Principle I, FR-035); the web only moves bytes.
