# Research: Web Version (feature 012)

Written on 2026-11-21 after reading `spec.md` (clarified 2586c56, FR-017 amended 4c94af2), the constitution 1.4.0 (753d03f), the feasibility spike report
(`/tmp/claude-1000/-home-omar-Projects/594a7d94-d936-4527-b032-30937d92ae18/scratchpad/web-spike/REPORT.md`, measured in a copy of the project, Flutter 3.50.0 / Dart 3.14.0, headless
Chromium), `lib/wirds/db.dart`, `lib/main.dart`, `lib/app.dart`, `lib/ayah/share_service.dart`, `lib/ayah/ui/ayah_sheet.dart`, `lib/backup/backup_files.dart`,
`lib/reminders/*`, `lib/links.dart`, `lib/mushaf/page_font_loader.dart`, `lib/settings/settings_screen.dart`, `lib/settings/about_screen.dart`,
`docs/research/licenses.md`, `tool/release.sh`, `tool/build_quran_assets.py`, and the owner's measurements of 2026-11-21 (page fonts as WOFF2: 97.7 MB, 604 of 604
compared with the TTFs, 0 mismatches). Nothing was built, deployed, uploaded or signed in to for this plan.

**How to read the numbers.** Sizes are exact bytes from the spike or the owner's run unless marked *estimate*. Anything marked **UNVERIFIED** is a hypothesis that an
early gate (G1 to G7, below) turns into a measurement before the dependent design is fixed; each has a fallback so the plan does not stop on it. Milliseconds are not
predictions for the owner's phone.

**New fact found while writing this plan (not in the spike).** `data-raw/qul/x-font-qpc-v2-woff2/` already holds the 604 **original** QUL files `p1.woff2` to `p604.woff2`
(about 94.4 MiB on disk, `du` of the folder). `tool/build_quran_assets.py` (line 202) decompresses them to TTF only because the code says «Flutter cannot load WOFF2».
So the WOFF2 route needs no conversion at all: serve the very files QUL published, byte for byte (D3).

## Index of decisions

| # | Decision | Needs the owner? |
|---|---|---|
| D1 | Hosting: a separate built-site repository connected to Vercel through Git (route A); the deploy test is the first gate that needs the owner | **yes** (account, «ارفع», repository visibility) |
| D2 | Traffic caps and how they are watched | yes (what to do if hit) |
| D3 | Page fonts: serve QUL's original WOFF2 if Flutter accepts it (gate G1), else TTF; fonts are read through a web `AssetBundle` | no (gate decides) |
| D4 | How data is laid out and versioned: `d/<dataVersion>/`, immutable | no |
| D5 | Storage: cross-origin isolation OFF; IndexedDB through drift; a one-tab guard | yes (one-tab guard) |
| D6 | Build flags: `--wasm`, `--no-web-resources-cdn`, `--pwa-strategy=none`; a strict CSP | yes (`--wasm` default) |
| D7 | Zero requests to other hosts, bundled Arabic fallback fonts | no |
| D8 | Licences for each new artifact | yes (About line) |
| D9 | Offline: own service worker, capture after first load, no skip-waiting, update button | yes (update button) |
| D10 | The whole-Mushaf download: size from a manifest, progress, stop, resume, single flight | yes (the size in the label) |
| D11 | Eviction warning and `navigator.storage.persist()` | yes |
| D12 | Platform seams: a second entry point and web implementations behind the existing interfaces | no |
| D13 | Web input and layout | no |
| D14 | Links, About, the takedown line | no |
| D15 | Notices, Settings and first-run (strings are proposals) | owner confirms strings |
| D16 | Tests, test-first, and the real-browser gate | owner does the real-browser check |
| D17 | `tool/build_web.sh`, versioning, the README later | no |
| D18 | The spec's success-criteria numbers: what the spike supports and how each is measured | owner may correct numbers |

## D1. Hosting: route A, a separate built-site repository connected to Vercel through Git

**Decision**: the site is **static files only**, built on this machine by `tool/build_web.sh` (D17) into `build/web-site/` and then, in a step the owner approves with
«ارفع», committed to a **separate repository that holds only the built site** (name proposed: `mushaf-al-hafiz-web`) which Vercel deploys through its Git
integration with **no build command, no framework, output directory `.`** and a `vercel.json` that carries only headers (D6, `contracts/site.md`). Nothing is uploaded
with the Vercel CLI.

**Evidence** (spike, Vercel docs fetched 2026-11-21): Hobby allows 100 MB of source files for a CLI upload, 15,000 files, 100 deployments a day; "no upper limit for output files
created during a build"; Fast Data Transfer 100 GB a month; 1,000,000 CDN requests a month and, over a limit, a 30-day wait; gzip and brotli are automatic for `ttf`, `otf`, `wasm`,
`json`, `js`. The complete site is about 135 to 160 MB (61 MB shell, of which about 38 MB is `canvaskit/` and about 20 to 25 MB of that is removable; 94 to 98 MB of fonts as WOFF2,
about 13 MB of JSON), so the **CLI upload (100 MB) is exceeded** whichever font format is used. Largest single file 7.3 MB; about 1,700 files.

**Rationale**: a repository is the only route that needs no second host (FR-028: a second origin for the fonts would be a request to another host) and does not circumvent the
CLI limit (the owner's rule: no splitting across projects to dodge a limit). It needs no build on Vercel, so no Flutter SDK has to be installed there, and the site served is
exactly the one that passed the checks on this machine. GitHub accepts a 150 MB repository comfortably (largest file 7.3 MB, far under 100 MB); fonts never change between releases, so
Git stores them once and a release commit changes only the shell.

**UNVERIFIED**: whether a Git-connected deployment of a 135 to 160 MB repository is accepted by Hobby (the docs state the 100 MB limit for the CLI only), that Vercel serves
`.wasm` as `application/wasm`, and that the CDN compresses `ttf`/`wasm`/`json` as documented. **Gate G4** answers these with a real deployment, which needs the owner to sign in
to Vercel and say «ارفع» (FR-036, FR-037) even for a preview: a preview is a deployment. Until G4 passes nothing in this plan depends on Vercel except the file layout, which
is the same on any static host.

**Ordered fallbacks if G4 fails (each needs the owner and, for the second and third, a constitution amendment because 1.4.0 names Vercel)**:
1. Remove the removable weight (the `.symbols` files, unused CanvasKit variants) and retest: it helps only if the limit counts the repository.
2. Move the **whole site** (not just the fonts) to another free static host: Cloudflare Pages Free (20,000 files, 25 MiB per file) or GitHub Pages (1 GB site, about 100 GB a month soft
   bandwidth). It stays one origin, so FR-028 holds. Amendment: Principle V and Scope say «hosted on Vercel».
3. The APK stays the only distribution; the web is dropped. (Stated so the owner sees it is an option, not recommended.)

**Rejected**: (B) build on Vercel: needs the Flutter SDK downloaded inside the build (an unofficial image, a second download of 1 GB at every deploy, not testable here) and the
generated fonts are not in any repository (they are git-ignored on purpose), so the build would have to fetch them from somewhere. (C) fonts on a second origin: breaks FR-028 and
shows visitors' addresses to a second host. (D) two Vercel projects to split 100 MB: circumvents a limit.

**Owner decision needed (visibility of the site repository)**: the 604 fonts and the data then live in a Git history that cannot be unpublished. Recommended default: the
site repository is **private** (Vercel Hobby deploys private repositories of a personal account). The fonts are public files of the site anyway (FR-033), but a private
repository lets the owner take them down by deleting the project without a public Git history of them. If Hobby refuses private repositories from this account, the owner decides
between public and fallback 2.

**Owner decision needed (the deploy test)**: G4 is the first moment the owner is needed. The test: the owner signs in to Vercel, creates the project from the site repository,
deploys once, and says «ارفع» for that deployment. Recommended default: do it as soon as the shell builds (stage D), with a **placeholder site** (the shell and 3 fonts, not the whole
Mushaf) first to check headers and MIME at no cost, then the full site. A preview has Vercel's own authentication in front of it by default, so the check from a phone needs the
owner signed in there or the production address, which is the real address; therefore the plan puts G4 before the owner's browser gate (F) and counts it as the owner's
«ارفع» only for the test project, whose address is not published anywhere (SC-013 is judged on the README, which is not edited before the final «ارفع»).

## D2. Traffic caps

**Decision**: stay on the free caps (100 GB a month, 1,000,000 requests a month), reduce what is requested, and **watch, not automate**: the owner looks at Vercel's usage page; nothing in
the site reports usage (FR-028 forbids analytics, including the host's).

**Numbers** (spike, WOFF2 changes storage more than transfer because Vercel already brotli-compresses TTF to about 100.2 MiB): a first visit is about 4 MB and 25 requests; a page turn is
about 160 to 170 KB and 2 requests (font and layout JSON); one complete reading is about 100 MB; a whole-Mushaf download is about 110 MB (WOFF2) or about 172 MB (TTF) and about 1,210
HTTP requests (an estimate of the number of requests of one whole-Mushaf download: fonts and layout files first; it counts requests, not the entries of `pack.json` (about 1,330, data-model.md) nor the 1,676 source files of the spec; the build prints the real numbers). 100 GB is therefore about 900 whole-Mushaf downloads **or** about 1,000 complete readings **or** about 600,000 page turns; 1 M requests is about 480,000 page turns or about 800
whole-Mushaf downloads.

**Mitigations in the design** (all measured by gate G5/G6): immutable one-year `Cache-Control` on `d/<dataVersion>/` and on hashed shell files; a service worker that answers every repeat from
the browser (D9), so a reader pays for a page once per browser; prefetch of only page ±2 (already the app's rule); no automatic bulk download (FR-031); pruned CanvasKit; the whole-Mushaf
download fetches each file once and skips what is already cached (D10).

**Owner decision needed (if a cap is hit)**: the host stops the site for 30 days. Recommended default: accept this, state in the README that the APK is the other way (the spec already says
so), and look at the usage page after the README link is added and after any mention in public. Alternative: an identical mirror on a second free host with its own address (only the owner
would give readers that address; not built now).

## D3. Page fonts: QUL's original WOFF2 if Flutter accepts it, else TTF

**Decision**: the web version fetches each page font with a **web `AssetBundle`** (D12) that maps the existing key `assets/fonts/qpc-v2/p<N>.ttf` to `d/<dataVersion>/fonts/p<N>.<ext>`, where
`<ext>` is one constant. `PageFontLoader` is **not edited** (its bundle is already a constructor argument). The extension is chosen by gate **G1**:

- **G1 passes** (a `FontLoader` fed WOFF2 bytes renders glyphs in CanvasKit and in skwasm on Chromium, and in the engine each browser actually falls back to): serve **the original
  `data-raw/qul/x-font-qpc-v2-woff2/p<N>.woff2` byte for byte** (about 94.4 MiB; the owner's conversion measured 97.7 MB). No conversion step, nothing to verify beyond the files'
  sha256 against `data-raw`, and the web serves exactly what QUL published (Principle I and V are simplest this way). The owner's converted copies
  (`scratchpad/w2out/`, `w2conv.py`: fonttools and brotli, all 604 identical in cmap, hmtx, unitsPerEm and glyf outlines) are the **fallback inside the fallback**: usable if a WOFF2
  produced by us loads where QUL's original does not (not expected).
- **G1 fails** (expected possibility: `assets/fonts` code says «Flutter cannot load WOFF2», and CanvasKit's Skia is the same engine family): serve the **TTF** the app already generates
  (`assets/fonts/qpc-v2/p<N>.ttf`, 159,004,392 bytes). Transfer is the same as WOFF2 within a few percent because the host brotli-compresses TTF (about 100.2 MiB measured); what changes
  is the **storage** in the Cache API (a cached response is stored decoded: 159 MB, not 94), the repository and the whole-Mushaf download size (about 172 MB with TTF, about 110 MB with WOFF2; the spec now says the real size computed from the manifest).
- A third option, decoding WOFF2 to TTF in the browser with a small WebAssembly decoder, is **rejected for now**: it adds a new binary artifact with its own licence and a runtime step in
  the one path Principle I cares about most. It is revisited only if the Cache API quota proves too small for the TTF route on the browsers the owner uses (gate G5 measures the quota).

**What G1 must do** (an early task, before any code that depends on the extension): a 30-line page `web/` test in Playwright that registers `p1`, `p2` with `FontLoader` from bytes in
the three engines, draws the page, and compares a screenshot with the TTF render; plus the same in a `flutter test --platform chrome` where it runs. The pass condition is a pixel-identical render of
pages 1, 2 and 50 and no console error.

**Rejected**: rendering the page with the browser's own `FontFace` (it takes WOFF2 natively) by embedding an HTML element: the Mushaf page is painted by Flutter's own text engine, and moving it
to DOM text would be a second renderer for the core screen (Principle I risk, geometry risk, FR-003).

## D4. Data layout and versioning: one immutable directory

**Decision**: the build moves everything the Mushaf needs out of Flutter's `assets/assets/` tree into `d/<dataVersion>/` and serves it with `Cache-Control: public, max-age=31536000,
immutable`:

```text
d/<dataVersion>/fonts/p1 ... p604 .woff2|.ttf     # D3
d/<dataVersion>/mushaf/meta.json, mushaf/pages/NNN.json
d/<dataVersion>/ayah/{text,tafsir,translation,gharib}/NNN.json, ayah/sources.json
d/<dataVersion>/pack.json                         # the manifest of the files above: path, bytes, sha256 (D10)
```

`dataVersion` = first 12 hex of the sha256 of the sorted `path:sha256` lines of those files, computed before the Flutter build and passed to it with `--dart-define=DATA_VERSION=...`.
It is baked into the app, into `sw.js` (D9) and into `pack.json`'s name, so **an app can never ask for data of another version**. The Flutter assets copied into the build for these
paths (and the 604 TTFs, which `pubspec.yaml` lists under `assets:`) are **deleted** by the build script after `flutter build web`, so the site holds each file once.

**Rationale**: Flutter's asset URLs (`assets/assets/...`) are not content-hashed, so they cannot be `immutable`; a versioned directory can. Service worker caches and the CDN cache are keyed
by URL, so a changed dataset is a new URL and old and new can never be mixed (spec edge case: «a new version ... never left with a mix of old and new files»). Data changes only if the
generated Quran data is rebuilt, which is exceptionally rare (Principle I); when it happens the cost is that readers fetch pages again, which is acceptable and honest.

**Alternatives**: keep Flutter's own `assets/assets/` paths and an `immutable` header (wrong when content changes at the same URL); versioned query strings (`?v=`; an `immutable` header on a
URL with a query is honoured, but the CDN and the Cache API treat the key more fragilely, and a directory is easier to delete from the site repository).

## D5. Storage: cross-origin isolation OFF, IndexedDB through drift, and a one-tab guard

**Decision**: **no COOP/COEP headers** (cross-origin isolation off). The database is opened with drift's `DriftWebOptions(sqlite3Wasm: 'sqlite3.wasm', driftWorker: 'drift_worker.js')` and the
implementation drift picks for the browser (shared IndexedDB, or a dedicated worker with IndexedDB where there is no `SharedWorker`). This is **decided once and never changed after the first
public release**, written in the release notes of the site (D17), because IndexedDB and OPFS are different stores: turning isolation on later would make existing readers' data look empty.

**Evidence** (spike): without headers Chromium chose `sharedIndexedDb` and the data survived a reload; with `COOP same-origin` and `COEP require-corp` it chose `opfsLocks` and `crossOriginIsolated`
was true (so skwasm could be multi-threaded). Firefox can use `opfsShared` without headers (source comments, untested); Safari untested; fallbacks `unsafeIndexedDb` and `inMemory` exist and
`onResult` reports which was chosen.

**Rationale**: the owner's preference is the choice that works across Chromium, Firefox and Safari **without** cross-origin isolation. IndexedDB is the one store all three have; OPFS-based
modes depend on features that arrive at different times and on headers that restrict embedding. Nothing in this site embeds a cross-origin resource, so isolation would cost nothing in
features, but it would give a speed benefit only to skwasm threading, which this app (a reader, not a game) does not need (G3 measures it). Off is also the smaller change from what the
spike observed to work.

**What the app does with `onResult`**: it maps drift's result to a `StorageStatus` (data-model.md): `durable` (IndexedDB or OPFS), `volatile` (`inMemory`: a private window or a browser that refuses
storage, the notice of FR-021 and the proposed string «أنت في نافذة خاصة: لن يُحفظ شيء بعد إغلاقها.»), `unsafeShared` (see the guard below).

**The one-tab guard (edge case "two tabs", spec says the plan chooses the simplest safe behaviour)**. Decision: the app takes a **Web Lock** (`navigator.locks.request('mushaf-al-hafiz-app',
{ifAvailable: true}, ...)`, held for the life of the tab). A second tab does not open the database; it shows one screen in the app's look: «التطبيق مفتوح في تبويب آخر. استخدم ذلك التبويب» with
a «حاول مرة أخرى» button (proposal). Reasons: (a) drift's tab synchronisation is solid only with a shared worker, and **Chrome on Android has had no `SharedWorker`** (UNVERIFIED for the
current version: **gate G2** reads which implementation drift picks on the owner's phone and on desktop Firefox and WebKit); where drift falls back to `unsafeIndexedDb`, two tabs can corrupt data;
(b) the guard works the same everywhere and is about 40 lines; (c) a reader seldom needs two tabs of a reader. Web Locks exist in Chrome, Firefox and Safari 15.4+; where `navigator.locks` is
missing the guard is skipped and a `unsafeShared`-class status shows the notice. **Owner decision needed**: recommended default is the guard; the alternative is to allow two tabs where G2
shows drift is safe.

**Persistence and size**: the database is a few kilobytes of rows (wirds, days, bookmarks, settings); its weight is irrelevant. What matters is eviction (D11).

## D6. Build flags, the renderer, the site's headers and CSP

**Decision**: `flutter build web --release -t lib/main_web.dart --wasm --no-web-resources-cdn --pwa-strategy=none --base-href /`.

- `--no-web-resources-cdn`: the engine (`canvaskit`, `skwasm`) and the default Roboto come from our origin instead of `www.gstatic.com` / `fonts.gstatic.com` (spike). Required by FR-028.
- `--pwa-strategy=none`: Flutter's generated `flutter_service_worker.js` only unregisters itself and gives no offline use; we ship our own (D9).
- `--wasm`: dart2wasm with skwasm and an automatic JS+CanvasKit fallback. Chromium 137+ runs wasm; Safari 26.2+ and Firefox 147+ have it off by default unless `wasmAllowList` and then fall back. The
  spike ran both paths and QCF glyphs rendered correctly in both (main.dart.wasm 4.26 MB, 1.26 MB brotli; main.dart.js 5.67 MB, 1.15 MB brotli). **Owner decision needed**: recommended default is
  `--wasm` for speed; the fallback is the plain JS build (smaller site, one renderer, the path with the longest track record). **Gate G3** compares both on the owner's phone: render equality on
  pages 1, 2, 50, 293, 604, long-press, first paint time and 20 turns, and picks. If skwasm shows any glyph difference, the JS build wins without asking.
- Pruning: delete `canvaskit/*.symbols` (8.6 MB) at once; other variants (about 12 to 17 MB: `skwasm_heavy` and the variants a browser does not use) are removed **only after** the smoke test (D16) has
  loaded the app in Chromium, Firefox and WebKit from the pruned tree.
- **Cross-origin isolation: off** (D5), so `vercel.json` carries no COOP/COEP.

**Headers** (`contracts/site.md` has the file): `sw.js`, `index.html`, `flutter_bootstrap.js`, `version.json`: `no-cache`; `main.dart.*`, `canvaskit/**`, `sqlite3.wasm`, `drift_worker.js`, `assets/**`:
`max-age=0, must-revalidate` (not content-hashed by Flutter, so they cannot be immutable; the service worker serves repeats); `d/**`: one year, immutable; plus on everything `Referrer-Policy:
no-referrer`, `X-Content-Type-Options: nosniff`, `Permissions-Policy` denying camera, microphone, geolocation, notifications (the site asks for none, spec Differences table), and a **Content-Security-Policy**:

```text
default-src 'none'; script-src 'self' 'wasm-unsafe-eval'; connect-src 'self'; img-src 'self' data: blob:; font-src 'self' blob: data:;
style-src 'self' 'unsafe-inline'; worker-src 'self' blob:; manifest-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'
```

The CSP is the **enforcing half of FR-028**: a request to another host is refused by the browser, so a stray fallback-font fetch cannot succeed silently; the smoke test (D16) also fails the run if
the browser reports a CSP violation or any request to another host. `'unsafe-inline'` for scripts is added **only if** the generated `index.html` needs it (the bootstrap is a file, so it should not);
G3 and the smoke test show it.

## D7. Zero requests to other hosts, and the Arabic fallback fonts

**Decision**: the built site must make **no request to any host but its own**; this is a testable contract (`contracts/site.md`, section «Zero third-party»), enforced three ways: the CSP (D6), the
smoke test's request log (D16), and a **bundle audit** in `tool/build_web.sh` that fails if the output contains the strings `gstatic.com`, `googleapis.com` or `fonts.google` in any file the browser loads
(the engine's own fallback URL list is inside `canvaskit/*.js`/`main.dart.*`; `--no-web-resources-cdn` rewrites the engine location but the fallback font URL list lives in the engine code, so the audit
must read the files first and the **bundled fallback below must make that code path unreachable**; whether the string is present but unused is what G7 decides, and the audit then checks the
network log instead of the string).

**Fallback fonts**: Flutter web asks `fonts.gstatic.com` for Noto Sans Arabic (and Noto Sans Symbols, Emoji) when a glyph is missing from every font it has. The app already bundles **Amiri Quran**,
**Reem Kufi** and **Cairo** (static 400/500/600/700; Arabic and Latin; `docs/research/licenses.md`, all SIL OFL 1.1). The decision is to **reuse them** as the only fonts and make sure a missing glyph
cannot occur: (1) a Python script `tool/web_font_coverage.py` (fonttools; a dev tool, not shipped) collects every code point the web build can show (every Arabic string in `lib/`, the per-ayah
tafsir, translation, meanings and dua files, the About and notice strings, digits, punctuation) and checks each against Cairo ∪ Amiri Quran ∪ Reem Kufi; it **fails the build on a gap** and lists it;
(2) `MushafApp` gets an optional `fontFallback` list that `main_web.dart` fills with `['Cairo', 'AmiriQuran', 'ReemKufi']` so Flutter never goes looking elsewhere; (3) no emoji and no symbol
outside those fonts anywhere in the strings (checked by the same script). Latin text of the English translation is in Cairo. **If** the script finds a Quranic annotation mark or a Cairo gap, Amiri Quran
(which covers Quranic marks) is first in the fallback for the Arabic text style; only if a glyph is in none of them does the plan return to the owner with the exact code points (a new font would
then be a new licence entry, D8). **UNVERIFIED** until G7 runs the script.

**Rejected**: bundling Noto Sans Arabic (a fourth font family, 1+ MB, a new licence entry, for glyphs the three bundled fonts probably cover); leaving the CDN default on (violates FR-028).

## D8. Licences for each new artifact (`docs/research/licenses.md`, before any deploy; SC-016)

The spec says the web distribution of the Mushaf resources is recorded for each (FR-033) and a feature that adds a resource adds its entry (Development Workflow). **This plan changes
`docs/research/licenses.md` only in the implementation stage G, test-first by a script that fails if a row is missing; it is not edited now.** Rows to add or extend:

| Artifact | Where it comes from | Licence (to be read and recorded, not assumed) | Note |
|---|---|---|---|
| The 604 page fonts, layout JSON, word data, tafsir, translation, meanings, dua | already rows | existing statuses | extend each row's conditions: «also served as public files of the website (1.4.0)» |
| `sqlite3.wasm` | `sqlite3.dart` releases, the build matching `sqlite3` 3.9.1 (spike used a devtools copy, not for production) | SQLite is public domain; the wasm build and `sqlite3.dart` are MIT (read the repository's LICENSE) | pinned by sha256 in the repository next to `web/` |
| `drift_worker.js` | `drift` 2.35.4 package root (363 KB) | MIT (read the package's LICENSE) | must match the drift version, regenerated with the package |
| Flutter engine files (`canvaskit/`, `skwasm`, `main.dart.js` runtime) | Flutter 3.50.0 SDK | BSD-3 (Flutter, Skia, CanvasKit); read `assets/NOTICES` in the build (1.5 MB), which Flutter generates | the build ships `NOTICES` so the licence text travels with the site |
| Amiri Quran, Reem Kufi, Cairo | already rows | OFL 1.1 | extend: served on the web too; their `OFL.txt` are copied beside the fonts in the site |
| `fonttools`, `brotli` (only if the converted fallback of D3 is used) | build machine only | MIT / MIT (read) | not shipped |
| Playwright (D16) | `tool/web_smoke` dev only | Apache-2.0 | not shipped |

**About on the web**: it shows every credit of the Android About screen (FR-034) and nothing is added for fonts already credited. **Owner decision needed**: recommended default is **one new line**
in the web About, «مكوّنات برمجية مفتوحة المصدر» with a link to the licence page the app already can show (Flutter's `showLicensePage` reads the same `NOTICES`), because `sqlite3.wasm`, `drift` and the Flutter
engine ship to the reader's browser (a notice requirement of MIT and BSD), unlike on Android where the APK lists them in its own licence screen; the alternative is licences.md only.

## D9. Offline: our own service worker

**Decision**: a hand-written `sw.js` (about 150 lines, generated from `web/sw.js.in` by the build with the build id and `dataVersion`), no library and no Workbox (zero third-party at build
and run time). Its rules:

| Request | Rule |
|---|---|
| `index.html`, the app start (navigations) | answered from the shell cache of **this** service worker's version (cache-first); the cache and the worker are one version, so old and new files are never mixed |
| shell files (`main.dart.*`, `flutter_bootstrap.js`, `canvaskit/**`, `sqlite3.wasm`, `drift_worker.js`, `assets/**`, icons) | cache-first; on a miss, fetch, **put into the shell cache**, answer |
| `d/<dataVersion>/**` | cache-first in the data cache `data-<dataVersion>`; on a miss, fetch and put; a failed fetch with nothing cached answers `504` so the app shows its own «this page needs a connection once» (FR-032) |
| any other host | not handled (the browser's CSP refuses it anyway) |

- **Install** precaches only a **core** list (about 0.5 MB: `index.html`, `flutter_bootstrap.js`, `manifest.json`, the icon, `version.json`). It does **not** precache `canvaskit/` or the engine
  variants: which variant a browser needs differs (Chromium variant, full CanvasKit, skwasm, skwasm_heavy), and precaching all of them would download about 38 MB on a first visit, over SC-008's
  15 MB. Instead (**capture after first load**): when the first page has painted, the app posts a message to the worker with the same-origin URLs from
  `performance.getEntriesByType('resource')`; the worker `cache.add`s each one. They are in the browser's HTTP cache from the first load, so this usually costs no new transfer (gate G6 measures
  whether it did). A visit after an update is controlled from its start and fills the cache at runtime by the cache-first rule, so no list is ever needed.
- **No `skipWaiting`.** A new worker installs in the background and **waits** until every tab of the old one is closed, then activates at the next start with a new shell cache `shell-<buildId>` (old
  shell caches and old `data-*` caches are deleted at activation). `clients.claim()` is called only on the **first** install (no previous controller), so the capture above works.
- **Update flow**: when a new worker is waiting, the app shows in Settings a line «يوجد تحديث جاهز للتطبيق» and a button «تطبيق التحديث» (proposals): the button posts `skipWaiting` and reloads
  once. Never automatic, never during reading (a reload mid-page is a loss of place). **Owner decision needed**: recommended default is the button; the alternative is no button (the update applies
  when the owner closes every tab, which for an installed home-screen copy can be a long time).
- **Data and wirds survive an update**: the database is not in the caches (IndexedDB), and drift migrates by `schemaVersion` as on Android.
- A bug in `sw.js` can brick offline use for everyone, so (D16) it has a test-first Playwright suite, the file is versioned, and `version.json` plus a `sw.js` with `Cache-Control: no-cache` let a
  fixed worker replace a broken one at the next visit.
- The worker is registered by a few lines in `index.html` **before** Flutter's bootstrap, never by Flutter's `serviceWorkerSettings` (that is the `--pwa-strategy=none` setting).

**Alternatives**: Flutter's default worker (no offline at all, spike); `--pwa-strategy=offline-first` (precaches the whole `assets/` list, i.e. about 160 MB of fonts: breaks SC-008 and FR-031's «not
in bulk automatically»); Workbox (an npm dependency at build time for 150 lines, and its CDN default would be a third-party request).

## D10. The whole-Mushaf download button (FR-031, FR-042)

**Decision**: a **Settings** tile (the spec's default, a second place is a proposal only; recommended default: Settings only) shows the proposed label, **the real size first**, and on tap runs
`OfflinePack` (data-model.md, `contracts/dart-interfaces.md`):

1. **Size first**: it reads `d/<dataVersion>/pack.json` (the manifest of D4: every file with its bytes and sha256), sums the bytes **of the files not yet in the data cache**, and shows a
   confirmation sheet: «تنزيل المصحف كاملًا للقراءة بلا إنترنت (نحو N ميجابايت)» with N from the manifest (rounded to 5 MB), «ابدأ»/«إلغاء». The label's «170» is replaced by the computed N,
   because the real figure is about **110 MB with WOFF2 and about 172 MB with TTF** (decided by G1). **Owner decision needed**: recommended default is the computed number (the constitution 1.4.0 and
   spec say «about 170 MB»; if G1 picks WOFF2 it is a PATCH-level wording correction recorded in the next constitution housekeeping, not a blocker).
2. **Space check**: `navigator.storage.estimate()`; if the free quota is below 1.5 x N the sheet says so and does not start (message proposal «مساحة المتصفح لا تكفي لتنزيل المصحف كاملًا»).
3. **Persistence**: on «ابدأ» only, it calls `navigator.storage.persist()` (D11).
4. **Run**: 4 requests at a time (HTTP/2 multiplexes them), each file `fetch`ed and `cache.put` into `data-<dataVersion>` after its byte length and sha256 are checked against the manifest; a file already
   cached with the right length is **skipped**, so a restart resumes where it stopped and a second press after completion finishes at once. Progress is bytes done / bytes total from the
   manifest, shown as a bar and «٣٧٪»-style text.
5. **Stop**: «إيقاف التنزيل» sets a flag and aborts in-flight requests with an `AbortController`; the files already kept stay (the next press continues).
6. **Safe to press twice**: a single in-flight guard in the page (a second tap while running is ignored) and a Web Lock `mushaf-al-hafiz-pack` (so a second tab, which the one-tab guard prevents anyway,
   cannot start a second run).
7. **Failure**: a failed file is retried 3 times with a growing wait, then the run stops with «تعذّر إكمال التنزيل. اضغط مرة أخرى للمتابعة» and the progress kept; a `QuotaExceededError` stops it with
   the space message and removes nothing.
8. **Done**: the tile reads «المصحف كاملًا متاح الآن بلا إنترنت» (the proposal) when `cache.keys()` holds all manifest files; it is **rechecked at every start** (the browser may have evicted some, D11) and
   goes back to the button, never claiming what is not there.

**Why not the service worker**: a download that runs in the page can show progress and can be stopped by the reader; the worker only serves the cache. Both write the same cache. A background fetch API
(`BackgroundFetch`) is Chromium-only and not needed.

## D11. Eviction warning and `persist()`

**Decision**: the browser may delete a site's data under storage pressure or, on Safari, after seven days without a visit (ITP; an installed home-screen copy is exempt). Policy:

- `navigator.storage.persist()` is requested **once, in the whole-Mushaf download flow, after the reader taps «ابدأ»** (the one moment the reader has asked for something big to be kept), and its
  answer is shown in Settings as one line: «المتصفح سيحتفظ ببياناتك» or «المتصفح قد يمسح بياناتك عند امتلاء الجهاز، فاحتفظ بنسخة احتياطية.» (proposals). Chromium decides silently by engagement; **Firefox shows
  its own permission prompt** for `persist()`. This is a deviation from the spec's table row «The browser asks for nothing» and is logged in Complexity Tracking; keeping it tied to the download button
  means the prompt appears right after a tap that explains it, not at a random time.
- The data-loss notice (FR-021) is the main protection: it is shown on first use and kept in Settings together with the backup button, so the owner of a year of wird history knows.
- No periodic reminder to back up (would be a nag; not in the spec).
- **Owner decision needed**: recommended default as above (only in the download flow); the alternative asks `persist()` the first time a wird or bookmark is saved (best protection of the database, but
  a Firefox prompt at an unexpected time).

## D12. Platform seams: Android untouched, web through a second entry point

**Decision**: **a second entry point `lib/main_web.dart`** (built with `-t lib/main_web.dart`) wires the web implementations explicitly; `lib/main.dart`, which Android builds, is **not edited**. Shared
code is edited only where a seam cannot be a constructor argument, with an optional parameter whose default is today's behaviour, and each edit has a test written first that proves the Android
path is unchanged (D16). The list, by existing interface:

| Seam (file) | Android today | Web | How |
|---|---|---|---|
| Boot (`main.dart`) | database, reminders, temp folder, renderer, PDF | database with `DriftWebOptions`, no reminders, no temp folder, no renderer, no PDF, data from a web bundle, single-tab guard, storage status | `main_web.dart` (about 80 lines, a copy of the parts of `_bootApp` that apply). Complexity Tracking item 1 |
| Database (`lib/wirds/db.dart`) | `driftDatabase(name: 'mushaf')` | adds `web: DriftWebOptions(...)` with `onResult` forwarding the chosen implementation | one edited expression, ignored on Android (spike: compiled, ran) |
| Data and fonts (`MushafRepository(rootBundle)`, `AyahRepository`, `SearchService(bundle:)`, `PageFontLoader(bundle:)`) | `rootBundle` | `WebDataBundle` (pure Dart, `lib/web/web_data_bundle.dart`): reads keys under `assets/mushaf/`, `assets/ayah/`, `assets/fonts/qpc-v2/` from `d/<dataVersion>/` through an injected fetch function, delegates the rest (the khatm dua, the app fonts) to `rootBundle` | no edit of those classes |
| Sharing text (`ShareService`) | `PlatformShareService` over `share_plus` | `WebShareService`: `navigator.share({text})` where `navigator.canShare` allows it, otherwise `Clipboard` copy and a new outcome `ShareOutcome.copied` the UI answers with «تم نسخ نص الآية»; user dismissal (`AbortError`) is `dismissed`; `shareFile` throws `ShareFailure` (never called, D13) | adds one enum value `copied` and handles it where `ShareOutcome` is switched on (found by the analyzer; Android never returns it) |
| Picture and PDF (`ayah_sheet.dart`) | `PagePictureAction` and `PdfJob` | **absent** (FR-017): `main_web.dart` provides `null` for `PageRenderer`, `TempShareFiles`, `PdfJob`; `ayah_sheet.dart` already hides both entries and the heading when the providers are null (read: lines 33-45, 273) | no edit. The bundle audit (D17) proves `lib/pdf/`, `lib/render/` and the picture action are not in the web output |
| Backup (`BackupFiles`) | `PlatformBackupFiles` (temp file, share sheet, `file_picker`) | `WebBackupFiles`: `share` builds a `Blob` from the JSON, clicks a hidden `<a download>` and shows «تم تنزيل الملف»; `pick` uses `file_picker` as now (it only uses `readAsBytes`, which works on the web) with the same 20 MB cap and a fallback input of `package:web` if the spike's cancel behaviour fails (G5) | new class in `lib/web/js/`, wired in `main_web.dart` |
| Links (`links.dart`, `about_screen.dart:93`) | `PlatformLinkOpener` over a `MethodChannel` | `WebLinkOpener`: `window.open(url, '_blank', 'noopener,noreferrer')` called **synchronously inside the tap** (a popup blocker refuses it after an `await`); https only as now | `links.dart` gets a conditional import and a `kIsWeb` branch in `PlatformLinkOpener.open`; `AboutScreen`'s default stays |
| Reminders (`reminder_*`, `background_refresh.dart`, `main.dart:113`) | scheduled local notifications, workmanager | **not created**; `Reminders` provider is `null`; Settings shows the one line (D15) | `main_web.dart` never imports `background_refresh.dart`. The settings edit is gated on a `WebEnvironment?` provider (below), not on `kIsWeb` |
| `path_provider` users (`TempShareFiles`, `backup_files.dart`, `pdf_*`) | temp files | none are constructed | no edit; they compile for the web (the spike showed `dart:io` imports compile and only fail when called) and are tree-shaken |
| `compute()` (`ayah_repository.dart:133`) | isolate | runs on the main thread on the web (spike) | measured in G6; a 530 KB tafsir file parsed on the main thread; if a frame over 100 ms shows, parse in slices as feature 011 does |
| Web-only facts the UI needs | n/a | `WebEnvironment` (a plain Dart object with `StorageStatus`, `OfflinePack`, `UpdateState`, `InputKind`, the build id) provided with `Provider<WebEnvironment?>` | an additive optional parameter on `MushafApp`; `null` on Android. Settings, tips and the reader read it |

**Rule kept**: web-only code that imports `package:web` / `dart:js_interop` lives in `lib/web/js/` and is imported only by `main_web.dart` and by browser tests; everything else in `lib/web/` is
**pure Dart with injected functions**, so it runs in the plain VM test suite. Android's `lib/main.dart` imports nothing from `lib/web/`.

**`package:web`, not a new pub package**: `package:web` and `dart:js_interop` give `navigator.share`, `navigator.locks`, `navigator.storage`, `caches`, `Blob`, `window.open`, `fetch` and
`serviceWorker`. `package:web` is already a transitive dependency of Flutter and drift; it is added as a **direct** dependency (a one-line `pubspec.yaml` change, no new code on Android). No
`url_launcher`, no `universal_html`, no `idb`, no `workbox`.

**Rejected**: `kIsWeb` branches inside the shared classes (they would import web libraries on Android's compile and make the Android tests depend on web code); editing `main.dart` to pick the platform
(its tests, and the Android boot, would change in a feature that promises Android does not change, FR-040); a Flutter flavour (flavors are for Android/iOS native builds).

## D13. Web input and layout

- **Mouse drag turns pages**: the spike showed touch swipes turn pages but mouse drags do not (Flutter's default scroll behaviour excludes the mouse). `MushafApp` gets an optional `scrollBehavior`;
  `main_web.dart` passes one whose `dragDevices` adds `PointerDeviceKind.mouse` and `trackpad`. Direction is unchanged: the same `PageView`, the same RTL.
- **Keyboard**: ← next page (the next page is on the left, FR-004), → previous, `PageDown`/`Space` next, `PageUp` previous, `Home`/`End` first/last (the last opens the dua exactly as a swipe
  past 604 does, never skipping it), `Esc` closes a sheet, `/` or `Ctrl+K` opens search from the index, `Tab` reaches every control with a visible focus ring. They are `Shortcuts`/`Actions` in a widget `WebReaderControls`
  (pure Flutter, VM-testable) around the reader that calls an additive optional `PageTurner` hook of `ReaderScreen` (the hook is designed in the first reader task, after reading the pager; the reader's
  baseline tests stay unchanged and a new test pins the hook).
- **On-screen arrows**: shown only when the last pointer event was a mouse (`InputKind.pointer`), one on each side, ≥ 48 px, hidden with the bars; never on touch.
- **Ayah menu without a long press**: `onSecondaryTap` (right-click) and `Enter`/`Space` on a focused word open the same sheet; the long press stays (FR-015). Browser context menu is suppressed only over the page.
- **Layout**: no change to page geometry. The page already keeps its Mushaf shape and is centred in landscape (feature 010 geometry); on a 1920 px window it is the landscape rule. Gate: a widget test
  pins the page rectangle at 360x800, 800x1280 and 1920x1080 and a Playwright screenshot shows no stretching; bars stay reachable. 4K scales by device pixel ratio, not by re-flow.
- **Reading size, text size, Night look, RTL**: unchanged code. `html lang="ar" dir="rtl"` and a dark `body` background in `index.html` so the start screen matches the Night look and there is no white flash;
  the same icon as the app for the tab and `manifest.json`.
- **Reduced motion**: Flutter maps `prefers-reduced-motion` to `MediaQuery.disableAnimations`; feature 010's motion code already honours it; Playwright emulates `reducedMotion: 'reduce'` (D16).
- **Browser zoom and system font**: the Mushaf geometry is independent of text scale (Principle I), as on Android; verified in the smoke run at 150% zoom.
- **Accessibility**: Flutter's web semantics tree is built on demand; no gate beyond keyboard reach (SC-011); screen-reader quality on the web is out of this feature (stated, not claimed).

## D14. Links, About, the takedown line

About on the web is the Android About plus the three items of FR-034: (1) the line «إن كنت صاحب حق في أي مورد واعترضت، افتح بلاغًا في صفحة المشروع على GitHub، وسيُزال المورد أو يُسحب الموقع.»
with the Issues address `https://github.com/0omarahmed73/mushaf-al-hafiz/issues`; (2) links to the repository and to the Android release `…/releases/tag/v1.0.0`, labelled «تطبيق أندرويد»; (3) the open-source
line of D8 if the owner agrees. They appear **only on the web** through `WebEnvironment` (the Android About is unchanged, FR-040). Links open in a new tab with `noopener,noreferrer` so the place in the
Mushaf is not lost (the Mushaf is a canvas app in the first tab, which `window.open` leaves running). A test compares the credits shown on the web with those of the Android About and with
`assets/ayah/sources.json` (the existing About test pattern).

## D15. Notices, Settings, tips, strings

All new Arabic strings are **proposals in one file** `lib/web/web_strings.dart` (like feature 011's `search_strings.dart`), each a constant with a comment naming the spec row; the owner confirms each
word by word before «ارفع» (FR-041, SC-014); a test fails if a string is not in the spec's table or in `contracts/ui.md`'s additions. `contracts/ui.md` lists them.

- **First use notice**: one dismissible bar (not a modal; Principle II: the Mushaf page is the first screen) on the first visit, after the tips, with «بياناتك محفوظة في هذا المتصفح…»; remembered
  in the existing `Settings` table under a new key `webDataNoticeSeen`. Web-only keys are **excluded from the backup export** so the backup format does not change (FR-040, spec assumption); a test written
  first reads how `BackupService` selects settings keys and pins that the new key is not exported and that imported reminder keys are written back unchanged (FR-023).
- **Settings on the web**: «التذكيرات» section replaced by one line; a «بياناتك» section with the data-in-browser sentence, the backup export/import buttons (they already exist), storage status line, the
  persistence line, the whole-Mushaf tile, the update line when waiting, and the build id.
- **Tips**: the first-run tips (feature 008) are worded for touch; on a pointer device they say mouse and keyboard («اسحب بالفأرة أو استخدم السهمين» proposal). `InputKind` is decided once at the first
  pointer event of the session and stored only in memory.
- **Private window / no storage**: `StorageStatus.volatile` shows «أنت في نافذة خاصة: لن يُحفظ شيء بعد إغلاقها.» on every start, not once, because it stays true.
- **Share fallback and file saved**: «تم نسخ نص الآية» and «تم تنزيل الملف» (a snack bar like Android's).
- **Waiting, failure, offline page**: the Mushaf page's own states («جارٍ تحميل الصفحة…», «تعذّر تحميل الصفحة. تحقّق من الاتصال.» + «إعادة المحاولة», «هذه الصفحة تحتاج اتصالًا بالإنترنت مرة واحدة.»)
  come from the existing reader error path; the web only has to make the web bundle's failures **typed**: a `DataUnavailable.offline` (the worker answered 504 or `navigator.onLine` is false) versus
  `DataUnavailable.failed`, so the reader can tell them apart (FR-032).
- **Tab title and boot failure**: `<title>مصحف الحافظ</title>`, and a static Arabic message inside `index.html` for «JavaScript off» and for «this browser cannot start the app».

## D16. Tests (Principle IX): test-first, what runs where

1. **VM unit tests** (`flutter test`, `test/web/`, pure Dart with injected fakes; written first): `WebDataBundle` key mapping and typed failures; `OfflinePack` as a state machine over a fake store and fake
   fetch (size first, skip cached, progress, stop, resume, double press, quota error, retry, eviction recheck); `pack.json` and `dataVersion` parsing; `StorageStatus` from drift results; the one-tab guard over a
   fake lock; `WebShareService` decision table (canShare yes/no, dismissed, failure); `WebBackupFiles` file name and content (the bytes equal what `Backup` produced); `WebLinkOpener` synchronous call;
   keyboard map; `InputKind`; every web string present once; the licences script; the web-keys-not-in-backup test.
2. **Browser tests** (`flutter test --platform chrome`, `@TestOn('browser')`): the `package:web` adapters against the real Blob, Cache API, Web Locks, `navigator.share` absence, `window.open`. Viable
   if Chrome and its driver run in this environment; if not, those cases move to the Playwright script below, and the plan says so in the task's evidence rather than skipping them silently.
3. **Android guard**: the existing **2067 tests stay green and unchanged** (`git diff` of `test/` touches only new files; a script in the quickstart compares the list of existing test files and their
   hashes with those recorded at stage 0); `flutter analyze` reports no issues; the Android build's `pubspec.lock` additions are only `package:web` as a direct dependency; the APK size changes by
   under 1 MB (SC-007; `tool/release.sh` numbers before and after, measured not estimated; the `kIsWeb`-guarded Settings widgets are tree-shaken).
4. **Headless Chromium smoke** (`tool/web_smoke/smoke.py`, Python Playwright run with `uv run --with playwright python ...`; a dev tool outside `pubspec.yaml`): serves `build/web-site/` with a
   local static server that sets the same headers as `vercel.json`; loads the site; **logs every request** and fails on any host but `127.0.0.1:<port>` and on any CSP violation; turns 20 pages with
   keyboard and with a mouse drag; opens the index, search, Settings, About; creates a wird and a bookmark; **reloads and checks the data survived**; exports a backup (the download event) and imports it;
   shuts the network (`context.set_offline(True)`), **reloads and reads**; runs the whole-Mushaf download against the local server and then opens 20 never-opened pages offline; emulates `reducedMotion`; at
   360, 800 and 1920 px checks no horizontal scroll; screenshots pages 1, 2, 50, 293, 604 in both looks for the owner's side-by-side. It runs on Chromium; on Firefox and WebKit as **best effort** (gate G2
   and G3 results go in the research notes), because Safari and Firefox are not gates (constitution Scope).
5. **Page text comparison for all 604 pages** (SC-003, FR-002, FR-035): the existing generated JSON is the single source of the lines for both targets (the web bundle serves the same files, verified by sha256 against
   the build), so the check is: `tool/build_web.sh` compares `d/<v>/mushaf/pages/*.json` and the fonts with `assets/` file by file (zero differences), and runs the existing validation (`validate` in
   `tool/build_quran_assets.py`: 604 pages, line counts, every word once and in order) **before** it builds; a failing validation stops the web build (FR-035). The rendering on the phone and desktop is the
   owner's side-by-side (pages 1, 2, 50, 293, 604), which no script can replace.
6. **Real-browser check by the owner** (constitution 1.4.0 Principle IX, FR-042): a current Chrome on the owner's Android phone and a current desktop browser: how pages render, the turning direction, landscape,
   a slow connection, reload and return, backup export and import (including a file exported by the Android v1.0.0 app), airplane mode after a visit, the whole-Mushaf download, the one-tab guard, the share
   fallback, each new Arabic string. `quickstart.md` writes the procedure. **Only the owner can verify** the Arabic wording, the visual side-by-side, the feel of page turning on the phone, and Vercel sign-in.
   Safari on iPhone and Firefox: best effort, results recorded, not a gate.

## D17. `tool/build_web.sh`, versioning, README later

`tool/build_web.sh` (in the house style of `tool/release.sh`: `set -euo pipefail`, refuses with a clear message) does, in order: (1) refuse if the generated assets are missing or the font count is not 604; (2) run the
validation of `tool/build_quran_assets.py` and the sha256 check of the copied data against `assets/` (FR-035); (3) compute `dataVersion` (D4); (4) `flutter build web ...` (D6) with `--dart-define=DATA_VERSION`
and `--dart-define=BUILD_ID`; (5) assemble `build/web-site/`: copy the shell, move data into `d/<dataVersion>/` (fonts from `data-raw` WOFF2 or from `assets` TTF per G1), delete the moved paths from
`assets/assets/`, delete `canvaskit/*.symbols`, write `pack.json`, `sw.js` from `web/sw.js.in`, `vercel.json`, `version.json`; (6) the **audit**: no moved paths remain, no file over 25 MiB, file count, no
string of D7 in loaded files, no `lib/pdf` or `lib/render` library in the `--dump-info` of the build (FR-017), total size printed, `sw.js` core list files exist; (7) print the size, file count and the build id.
It **never** pushes, never runs Vercel, never uploads. `tool/web_smoke/` runs after it. Publishing is a separate documented manual step (`docs/release/WEB_PUBLISH.md`, written in stage G, which includes the
**takedown steps of FR-039**: delete the Vercel project or remove one directory from the site repository and push; the README link edit).

**Versioning**: the app version is `pubspec.yaml`'s (1.0.0); the web adds a **build id** `1.0.0+<git short sha>` shown in Settings, and the site has its own changelog in `docs/release/WEB_PUBLISH.md`. The cache names
carry the build id and the data version, so every release is a clean replacement.

**README (a later requirement, not edited now)**: after «ارفع» and the owner's check, `README.md` and `README.en.md` get the link and the section (FR-038). The plan records the rewording list for that step:
«تطبيق أندرويد» header, «بلا إنترنت» (offline after the first visit on the web), the permissions section (the browser asks for nothing), the size lines, what a web host sees (FR-029), the differences table, and the
backup instructions. No change to `README*` in this planning step.

## D18. The spec's success criteria: what the spike supports, and how each is measured

| SC | Proposed number | Spike support | How it is measured (gate or stage) |
|---|---|---|---|
| SC-001 | first page 8 s first visit, 3 s later | first visit about 4 MB and 25 requests (measured), no timing | Playwright with CDP throttling to 10 Mbit/s and the phone's stopwatch; first visit and repeat (G6) |
| SC-002 | next page under 1 s in 95% of turns; jump 3 s | one turn about 166 KB + 1 KB, 2 requests (measured), no timing | 100 turns by Playwright with a throttled link; prefetch ±2 keeps most turns local; the phone's feel (owner) |
| SC-003 | zero line differences for 604 pages; owner sees none on five pages | QCF glyphs correct in CanvasKit and skwasm on pages 1 and 4 (observed) | file-by-file equality + validation in the build (D16.5), screenshots, the owner's side-by-side |
| SC-004 | results within 1 s; ready within 5 s | not measured | the feature 011 spelling table run in the browser (a Dart test on the real data in the VM, and the same table by Playwright), search preparation timed in G6; `compute()` jank noted |
| SC-005 | zero requests to other hosts, no tracking cookie | engine and Roboto move with `--no-web-resources-cdn` (measured); the Noto fallback still came from a CDN | CSP + request log + bundle audit (D6, D7, D16.4); cookie jar empty |
| SC-006 | backup round trip 100% | format unchanged | a VM test with a real v1.0.0 export; the owner imports a phone export in the browser and back (D16.6) |
| SC-007 | existing tests, analyze, permissions, APK < 1 MB | web build compiled with zero code changes | the Android guard (D16.3) |
| SC-008 | 15 MB before the first page | about 4 MB (js), 3.7 MB (wasm) estimated | transferred bytes in the smoke run, **including** the post-load capture of D9 |
| SC-009 | data survives 20 reloads, browser and device restarts | survived one reload (observed) | Playwright 20 reloads and a context restart (IndexedDB persists in a persistent context); the owner restarts the phone |
| SC-010 | offline start within 3 s; all 604 pages after the button | no offline in the default build | Playwright offline reload, then the pack and 20 never-opened pages; the owner's airplane mode |
| SC-011 | 360 to 1920 px, no sideways scroll, keyboard only | not measured | Playwright widths and a keyboard-only script; the owner on a desktop |
| SC-012 | one click from the README | n/a | after «ارفع» only |
| SC-013 | nothing online before «ارفع»; one public address after | n/a | the owner's statement and a search; the test project of G4 is not public |
| SC-014 | owner confirms every new Arabic string | n/a | the strings file with a confirmation column; a test lists unconfirmed ones |
| SC-015 | zero reminder controls and prompts | the web build shows what the web provides | Playwright walks every screen and asserts no `Notification.requestPermission` call and the one line |
| SC-016 | licences recorded and constitution 1.4.0 | constitution 1.4.0 is in force (753d03f) | the licences script (D8) and the release checklist |

**Numbers the owner may want to correct**: SC-008's 15 MB holds with a wide margin on the spike's figures **if** the capture of D9 costs no new transfer; SC-001's 8 s depends on `--wasm` or JS (G3). The label of
FR-031 and SC-010's size (about 170 MB) are corrected by G1 (D10).

## Early gates (the owner's list, in the order they run; none needs the owner except G4 and the real-browser gate)

| Gate | Question | Pass | Fallback |
|---|---|---|---|
| G1 | Does Flutter web's `FontLoader` (CanvasKit and skwasm) accept WOFF2 bytes? | pages 1, 2, 50 render identical to TTF in Chromium, Firefox, WebKit | serve TTF (D3) |
| G2 | Which storage does drift pick on Chrome Android, desktop Chrome, Firefox, WebKit? Two tabs? | durable store chosen; guard works | inMemory/unsafe: notice + guard |
| G3 | `--wasm` vs JS: same pixels, first paint, 20 turns | equal pixels, not slower | JS build |
| G4 | Does Vercel accept the Git-connected site (size, `.wasm` MIME, compression, headers)? Needs the owner and «ارفع» | deployment serves all files with the headers | fallbacks of D1 |
| G5 | Service worker: offline start, runtime caching, update, pack on Chromium/Firefox/WebKit; quota | all green | bug fixes; Safari best effort |
| G6 | First visit bytes (with capture), search preparation, `compute()` jank, page-turn times | within SC-008 and the others | slice parsing; fewer prefetches |
| G7 | Do Cairo, Amiri Quran and Reem Kufi cover every code point the app can show? | zero gaps | one more font and a licence row, back to the owner |

## Early gate results (Phase 1, run on 2026-11-21; evidence in `specs/012-web-version/gates/`)

The owner approved all eleven plan decisions on 2026-11-21 with the recommended option. The gates ran on Chromium only (headless, the cached chromium-1255): Firefox and WebKit are **not run** because no
engine is installed and the owner did not approve a download (`evidence/downloads-approved.md`); the owner's phone is not tested yet.

| Gate | Verdict | Measured | Decision it fixes |
|---|---|---|---|
| G1 | **PASS** (Chromium) | `FontLoader` fed QUL's original WOFF2 draws pages 1, 2, 50 with 0 differing pixels against the TTF, in CanvasKit and in skwasm; CanvasKit and skwasm also equal each other. Whole Mushaf 110,924,164 bytes with WOFF2, 172,180,056 with TTF | **`fontExtension = woff2`** (D3 first branch); the download label shows about 110.9 MB from `pack.json` |
| G2 | **PASS** (Chromium) | drift picks `sharedIndexedDb` with COOP/COEP off; data survives a reload; two tabs wrote 60 of 60 rows with no error and nothing lost | storage `durable`; the one-tab guard is kept (needed for engines that fall to `unsafeIndexedDb`, not run) but is not what prevents corruption on Chromium |
| G3 | **PASS** (Chromium) | 0 differing pixels JS vs wasm; first paint 194 ms wasm vs 299 ms JS; 20 page turns median 48 ms vs 86 ms (localhost probe) | **`--wasm` stays**; repeat on the real app in Phase 11 |
| G4 | **PREPARED, waits for the owner** (T014 to T016) | synthetic site of 1,667 files and 144.7 MB ready in the scratchpad as a local repository with no remote | nothing is pushed or deployed; the publish path stays blocked until G4 is PASS |
| G7 | **FAIL, one gap** | U+065E (ARABIC FATHA WITH TWO DOTS) is in no bundled font; it occurs 1,807 times in 757 distinct words of the ayah text (96 surah files) and in `lib/search/search_trace.dart` | the fallback list stays Cairo, AmiriQuran, ReemKufi; **the owner decides** whether to add one OFL font that has U+065E (a new licence row, D8), recommended; the Mushaf page fonts are not affected |

G5 and G6 belong to later phases. The fallback-font result is G7's: the three bundled fonts are not enough for the ayah text on the web until the owner decides about U+065E.

## What is not in this plan

Two-page spread, deep links, install prompts, push notifications, recitation, hifz tools, a second translation, accessibility certification, SEO, analytics of any kind, a custom domain, Safari on iPhone as a gate, the
README edit, `docs/research/licenses.md` edit, `web/`, `lib/` and `test/` edits (all later stages), and any deployment.
