# Dart Interfaces: Web Version (feature 012)

Signatures are the proposal of the plan; names may change in the first task of each group, the **shape and the rules** may not. Pure Dart classes live in `lib/web/` (no `package:web`, no `dart:js_interop`, so the VM tests
run them); browser adapters live in `lib/web/js/` and are imported only by `lib/main_web.dart` and by browser tests. `lib/main.dart` imports nothing from `lib/web/`.

## 1. Seams that already exist (unchanged unless the last column says so)

| Interface (file) | Android implementation | Web implementation | Edit to shared code |
|---|---|---|---|
| `ShareService` (`lib/ayah/share_service.dart`) | `PlatformShareService` | `WebShareService` (`lib/web/js/web_share_service.dart`) | `ShareOutcome` gains `copied`; callers handle it (written test-first; Android never returns it) |
| `BackupFiles` (`lib/backup/backup.dart`) | `PlatformBackupFiles` | `WebBackupFiles` (`lib/web/js/web_backup_files.dart`) | none |
| `LinkOpener` (`lib/links.dart`) | `PlatformLinkOpener` (MethodChannel) | `WebLinkOpener` (`lib/web/js/web_link_opener.dart`), reached through a conditional import and a `kIsWeb` branch in `PlatformLinkOpener.open` | a conditional import and one branch |
| `AssetBundle` given to `MushafRepository`, `AyahRepository`, `SearchService`, `PageFontLoader` | `rootBundle` | `WebDataBundle` (`lib/web/web_data_bundle.dart`, pure Dart) | none |
| `Reminders?` provider | `Reminders(...)` | `null` | none |
| `PageRenderer?`, `TempShareFiles?`, `PdfJob?` providers | built objects | `null` (FR-017: the two share entries and their heading are absent; `ayah_sheet.dart` already hides them) | none |
| `AppDatabase.open()` (`lib/wirds/db.dart`) | `driftDatabase(name: 'mushaf')` | the same call with `web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js'), onResult: ...)` | the `web:` argument and an optional `onWebStorage` callback; ignored on Android |
| `MushafApp` (`lib/app.dart`) | as now | three new **optional** parameters: `webEnvironment` (a `WebEnvironment?`), `scrollBehavior` (a `ScrollBehavior?`), `fontFallback` (a `List<String>?`) | additive, defaults reproduce today |
| `ReaderScreen` (`lib/mushaf/reader_screen.dart`) | as now | an optional `PageTurner? turner` hook so keyboard and arrows can turn pages and open the sheet | additive; shape fixed in the first reader task after reading the pager |
| Settings, About, Tips | as now | read `Provider<WebEnvironment?>`; when non-null they show the web sections of `contracts/ui.md` | additive, guarded by the provider, never by `kIsWeb` |

## 2. New pure classes (`lib/web/`)

```dart
/// What the web needs to know about its own run; provided only on the web.
class WebEnvironment {
  const WebEnvironment({required this.buildId, required this.dataVersion, required this.storage,
      required this.inputKind, required this.pack, required this.update, required this.instance});
  final String buildId;
  final String dataVersion;
  final ValueListenable<StorageStatus> storage;
  final ValueListenable<InputKind> inputKind;
  final OfflinePack pack;
  final ValueListenable<UpdateState> update;
  final InstanceGuard instance;
  Future<void> applyUpdate();                 // posts skipWaiting and reloads once (adapter-injected)
}

enum StorageStatus { unknown, durable, volatile, unsafeShared }
enum InputKind { touch, pointer }
enum UpdateState { none, waiting, applying }

/// Serves the Mushaf data from d/<dataVersion>/ through an injected fetch; everything else goes to [fallback].
class WebDataBundle extends CachingAssetBundle {
  WebDataBundle({required this.dataVersion, required Future<Uint8List> Function(Uri url) fetch,
      required AssetBundle fallback, String fontExtension = 'woff2'});
  // Keys it maps (rules, tested):
  //   assets/fonts/qpc-v2/p<N>.ttf  -> d/<v>/fonts/p<N>.<fontExtension>      (1 <= N <= 604, else FlutterError as rootBundle would)
  //   assets/mushaf/**              -> d/<v>/mushaf/**
  //   assets/ayah/**                -> d/<v>/ayah/**
  // any other key                   -> fallback.load(key)
  // A network refusal throws DataUnavailable(offline|failed); it never returns empty or partial bytes.
}
class DataUnavailable implements Exception { const DataUnavailable(this.kind, this.url); final DataUnavailableKind kind; final String url; }
enum DataUnavailableKind { offline, failed }

/// The whole-Mushaf download (research D10, data-model.md section 3). No browser code inside.
class OfflinePack {
  OfflinePack({required PackStore store, required PackFetcher fetcher, required PackLock lock,
      required StorageProbe storage, required Future<PackManifest> Function() manifest, int parallel = 4});
  ValueListenable<PackState> get state;
  Future<void> recheck();        // idle{missing}|complete, from the cache vs the manifest; never claims complete without checking
  Future<void> prepare();        // idle -> confirming (size computed, space checked); may end in failed(quota)
  Future<void> start();          // confirming|stopped|failed -> running; a call while running does nothing
  void stop();                   // running -> stopped; in-flight requests aborted; kept files stay
}
abstract interface class PackStore  { Future<Set<String>> keys(); Future<int?> length(String path); Future<void> put(String path, Uint8List bytes); }
abstract interface class PackFetcher { Future<Uint8List> fetch(String path, {required CancelToken cancel}); }  // throws on non-200
abstract interface class PackLock   { Future<T?> runExclusive<T>(String name, Future<T> Function() body); }    // null if held elsewhere
abstract interface class StorageProbe { Future<int?> freeBytes(); Future<PersistState> persist(); Future<PersistState> persisted(); }

/// One tab at a time (research D5).
class InstanceGuard {
  InstanceGuard(this._lock);
  ValueListenable<InstanceState> get state;
  Future<void> acquire();        // starting -> owner | blocked; with no lock API: owner and StorageStatus is judged elsewhere
  Future<void> retry();          // blocked -> owner | blocked
}
enum InstanceState { starting, owner, blocked }

/// Keyboard and mouse for the reader (pure Flutter, no web library).
class WebReaderControls extends StatelessWidget { const WebReaderControls({required this.turner, required this.child}); /* Shortcuts + Actions + arrows */ }
abstract interface class PageTurner { void next(); void previous(); void first(); void last(); void openAyahMenuAtFocus(); }
```

**Rules**
- `WebDataBundle.load` for a page's font and layout returns bytes **only** from a 200 response of the right version; a service-worker `504` is `offline`, a thrown fetch is `offline` when the adapter says the browser is offline and
  `failed` otherwise. The reader's existing error path maps them to «هذه الصفحة تحتاج اتصالًا بالإنترنت مرة واحدة.» and «تعذّر تحميل الصفحة. تحقّق من الاتصال.» (FR-008, FR-032).
- `OfflinePack`'s only side effects are through the four injected interfaces, so every rule of data-model.md section 3 is a VM test with fakes (including «press twice», «stop mid-file», «quota», «integrity mismatch»).
- No class of this file reads or writes wirds, bookmarks, positions or search text, or makes a request that carries any of them.

## 3. Browser adapters (`lib/web/js/`, `package:web`, imported by `main_web.dart` and browser tests only)

| Adapter | Implements | Browser API | Notes |
|---|---|---|---|
| `WebFetcher` | `PackFetcher`, and the `fetch` of `WebDataBundle` | `fetch`, `AbortController` | `cache: 'default'`, so the service worker and the HTTP cache answer |
| `CachePackStore` | `PackStore` | `caches.open('data-<v>')`, `cache.keys/put` | length of a cached entry from the stored response body |
| `WebLockApi` | `PackLock`, and the lock of `InstanceGuard` | `navigator.locks.request(name, {ifAvailable: true})` | held by an unresolved promise for the tab's life (`InstanceGuard`) or for the run (`OfflinePack`) |
| `WebStorageProbe` | `StorageProbe` | `navigator.storage.estimate/persist/persisted` | `persist()` is called only from `OfflinePack.start()` |
| `WebShareService` | `ShareService` | `navigator.share`, `navigator.canShare`, `Clipboard` | `canShare({text})` checked first; `AbortError` → `dismissed`; no `share` → copy → `copied` |
| `WebBackupFiles` | `BackupFiles` | `Blob`, `URL.createObjectURL`, a hidden `<a download>`, revoke after the click; `pick` via `file_picker` | file name from `backupFileName(now)`; the bytes are exactly the JSON passed in |
| `WebLinkOpener` | `LinkOpener` | `window.open(url, '_blank', 'noopener,noreferrer')` | the call is the first thing `open` does (no `await` before it); https only; returns `false` if the window is null (blocked) |
| `ServiceWorkerBridge` | feeds `UpdateState`, sends `capture` and `skipWaiting` | `navigator.serviceWorker` | absent or failed registration → `UpdateState.none`, offline is simply unavailable |
| `PointerKindListener` | feeds `InputKind` | pointer events | in memory only |

Adapters hold no policy: each is a thin function over one browser API, which is why the policy classes above are testable without a browser, and why a browser test of an adapter is small.

## 4. What the Android code sees

Nothing changes: `lib/main.dart` is not edited; the only shared-code edits are the optional parameters and hooks listed in section 1, each guarded by a test written first that builds the Android path with the new
parameters left at their defaults and compares what is shown (existing baselines of features 006 to 011 stay equal). `flutter analyze` reports no issues and the APK adds under 1 MB (SC-007).
