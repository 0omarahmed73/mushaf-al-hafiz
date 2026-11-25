# Site Contract: the published files (feature 012)

What a browser can rely on at the site's one address, and what `tool/build_web.sh` and the smoke test check. Values are the plan's proposals; the file layout and the rules in
«Zero third-party» are requirements (FR-027, FR-028, FR-029, FR-035).

## Tree of `build/web-site/` (the repository root of the site repository)

```text
index.html                    # lang="ar" dir="rtl", title «مصحف الحافظ», dark start screen, Arabic noscript and failure text, registers sw.js before Flutter starts
flutter_bootstrap.js
main.dart.js | main.dart.wasm + main.dart.mjs        # per the build flag (research D6)
flutter.js
manifest.json                 # name, icons, display "standalone", theme colour of the Night look, lang ar, dir rtl
version.json                  # { "buildId": "...", "dataVersion": "...", "flutter": "3.50.0" }
sw.js                         # generated from web/sw.js.in (contract below)
sqlite3.wasm                  # matching sqlite3 3.9.1, sha256 recorded in docs/research/licenses.md
drift_worker.js               # drift 2.35.4
canvaskit/ ...                # pruned: no *.symbols; the variants the smoke test needs
icons/ favicon.png
assets/                       # Flutter's own: AssetManifest, FontManifest, NOTICES, app fonts (Amiri Quran, Reem Kufi, Cairo + their OFL.txt), the khatm dua
d/<dataVersion>/
  pack.json                   # PackManifest (data-model.md section 3)
  fonts/p1 ... p604 .woff2    # or .ttf, one extension for all, decided by gate G1 (research D3)
  mushaf/meta.json, mushaf/pages/001.json ... 604.json
  ayah/text|tafsir|translation|gharib/001.json ... 114.json, ayah/sources.json
vercel.json                   # headers only
```

**Absent on purpose**: `assets/assets/fonts/qpc-v2/` and the other moved data (removed by the build), any `*.symbols`, any source map, any analytics or tracking file, `robots.txt` and `sitemap.xml` (the
README link is the way in; no deep links, spec Assumptions), any server code (FR-027).

## Headers (`vercel.json`)

| Path | Header |
|---|---|
| `/sw.js`, `/index.html`, `/`, `/flutter_bootstrap.js`, `/version.json`, `/manifest.json` | `Cache-Control: no-cache` |
| `/main.dart.*`, `/canvaskit/**`, `/sqlite3.wasm`, `/drift_worker.js`, `/assets/**`, `/icons/**` | `Cache-Control: public, max-age=0, must-revalidate` (not content-hashed; the service worker serves repeats) |
| `/d/**` | `Cache-Control: public, max-age=31536000, immutable` |
| `/sqlite3.wasm`, `/canvaskit/**/*.wasm`, `/main.dart.wasm` | `Content-Type: application/wasm` (checked in gate G4; set explicitly if the host's default is wrong) |
| everything | `Referrer-Policy: no-referrer`; `X-Content-Type-Options: nosniff`; `Permissions-Policy: camera=(), microphone=(), geolocation=(), notifications=(), payment=(), usb=()`; the CSP below |
| everything | **no** `Cross-Origin-Opener-Policy` and **no** `Cross-Origin-Embedder-Policy` (research D5: isolation off, decided once) |

```text
Content-Security-Policy: default-src 'none'; script-src 'self' 'wasm-unsafe-eval'; connect-src 'self'; img-src 'self' data: blob:;
font-src 'self' blob: data:; style-src 'self' 'unsafe-inline'; worker-src 'self' blob:; manifest-src 'self'; base-uri 'none';
form-action 'none'; frame-ancestors 'none'
```

`'unsafe-inline'` for scripts is added only if the generated `index.html` is proven to need it (research D6). Vercel's own features stay off: Web Analytics, Speed Insights, any toolbar (FR-028); the
build script cannot switch them off, so the checklist of the publish step names each (`docs/release/WEB_PUBLISH.md`).

## Zero third-party (FR-028, SC-005): a testable contract

1. **Network**: in a complete session (every screen, every action, a backup export and import, search, a wird, the whole-Mushaf download, offline reload) the browser makes **no request whose host differs from the
   site's** and the console has **no CSP violation**. The smoke test fails the run on either.
2. **Cookies and storage**: no cookie is set by the site (`document.cookie` empty, no `Set-Cookie` header from the host for site files); the only storage is IndexedDB (database), the Cache API (shell, data), and
   `localStorage`/`sessionStorage` not used.
3. **Bundle audit** (`tool/build_web.sh`): no file the browser loads is requested by URL from `gstatic.com`, `googleapis.com`, `jsdelivr`, `unpkg`, `cdnjs`, `cloudflare`, or any other host; strings of such a URL that
   exist inside engine code but are unreachable are listed and judged by the network log (research D7).
4. **Fonts**: the `tool/web_font_coverage.py` check passes (every code point the web build can show is in Cairo ∪ Amiri Quran ∪ Reem Kufi), so the engine never looks for a fallback font.
5. **What the host unavoidably sees** (FR-029, for the README's web section): ordinary requests for the site's files, which include **which page fonts were fetched** and their time and the visitor's address.
   Nothing else leaves the browser: no reader data, no search text, no notes.

## `sw.js` contract

| Item | Contract |
|---|---|
| Scope | `/` |
| Constants | `BUILD_ID`, `DATA_VERSION`, `CORE` (the core list) inlined by the build |
| Caches | `shell-<BUILD_ID>`, `data-<DATA_VERSION>`; any other cache whose name starts with `shell-` or `data-` is deleted at `activate` |
| `install` | opens the shell cache and adds `CORE`; **no `skipWaiting()`** |
| `activate` | deletes stale caches; `clients.claim()` **only if** there was no previous controller |
| `fetch` | GET, same origin only. Navigations: shell cache for `/index.html`, else network. `d/<DATA_VERSION>/**`: cache-first in `data-*`, miss → fetch → put (only a 200 whose length matches `Content-Length` when present); fetch failure with no cache → `Response(null, {status: 504})`. Other same-origin files: cache-first in `shell-*`, miss → fetch → put. A request for `d/<other version>/**` is not answered from any cache of this worker |
| Messages in | `{type:'capture', urls:[...]}` (the page lists `performance.getEntriesByType('resource')` after the first paint; the worker `cache.add`s each same-origin URL that is not in a cache); `{type:'skipWaiting'}` (only after the reader pressed the update button) |
| Messages out | `{type:'update-waiting'}` to every window when a new worker finishes installing while a controller exists |
| Never | background sync, push, notifications, periodic sync, analytics, any request to another origin |

## What the page must do about the site

- Register `sw.js` **before** Flutter bootstrap, from `index.html` (a few lines). If registration fails (private window of some browsers, `http` with no secure context) the app still runs, online, and says
  nothing wrong is lost (offline is the only loss).
- Never rely on the service worker for correctness: the app works with no worker (first visit, unsupported browser) and **never shows a page whose font or layout is missing** (Principle I): the web data
  bundle fails with a typed error instead (data-model.md section 4).
- Take the Web Lock (one-tab guard) **before** opening the database.

## Removing a resource or the whole site (FR-039)

To take one resource down the same day: delete its path under `d/<dataVersion>/` in the site repository and push (the host redeploys in seconds); a reader's cached copy remains in that browser until the next version
removes the cache, which is why the removal step also **bumps `dataVersion`** with the file removed from `pack.json` (the build does it). To take the whole site down: delete the Vercel project (or the repository),
then remove the README link. The steps are written in `docs/release/WEB_PUBLISH.md` in stage G.
