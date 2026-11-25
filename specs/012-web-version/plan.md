# Implementation Plan: Web Version of «مصحف الحافظ»

**Branch**: `012-web-version` (work stays on `main`) | **Date**: 2026-11-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/012-web-version/spec.md` (clarified 2586c56; FR-017 amended 4c94af2; constitution 1.4.0 in force, 753d03f)

## Summary

The same Flutter app, built a second time for the browser as **static files** and served from one address: a reader that opens on a Mushaf page, wirds with khatma and bookmarks, search, the ayah menu, backup by
download and file chooser, and the two looks. It adds no table, no backup-format change and no Android behaviour change. The plan, with the reasons in `research.md`:

- **Entry point and seams (D12)**: a second entry `lib/main_web.dart` wires the web implementations explicitly; `lib/main.dart` is untouched. Web implementations sit behind the interfaces that already exist
  (`ShareService`, `BackupFiles`, `LinkOpener`, the `AssetBundle` that the repositories and `PageFontLoader` already take). «مشاركة الصفحة كصورة» and «مشاركة السورة PDF» are **not built** for the web (FR-017): `main_web.dart`
  provides no renderer, no temp folder and no PDF job, `ayah_sheet.dart` already hides both entries when they are absent, and a bundle audit proves `lib/pdf/`, `lib/render/` and the picture action are not in the output.
  Reminders are not created; Settings shows one line. `package:web` and `dart:js_interop` are used, no new pub package.
- **Hosting (D1, D2)**: a separate built-site repository connected to Vercel through Git, no CLI upload, no build step (the site, 135 to 160 MB, exceeds the 100 MB CLI limit; WOFF2 reduces storage and transfer, not
  that). The first Vercel step is an **early gate (G4) that needs the owner's sign-in and «ارفع»**, even for a preview.
- **Data layout (D3, D4)**: the 604 fonts, the layout JSON and the ayah data move to `d/<dataVersion>/`, immutable for a year; a web `AssetBundle` maps today's asset keys to those URLs so `PageFontLoader`,
  `MushafRepository`, `AyahRepository` and `SearchService` are not edited. The font format (QUL's original WOFF2, byte for byte, or TTF) is decided by **gate G1**, because «Flutter cannot load WOFF2» is the
  repository's own recorded finding and the web path is unverified.
- **Storage (D5)**: cross-origin isolation **off**, IndexedDB through drift (`DriftWebOptions`), decided once before launch; a **Web Lock one-tab guard** replaces corrupt-able multi-tab use.
- **Build (D6, D7, D17)**: `tool/build_web.sh` validates the Quran data, builds with `--wasm --no-web-resources-cdn --pwa-strategy=none`, assembles and **audits** the site, never pushes. A strict CSP makes «zero requests to other
  hosts» enforceable and testable; the bundled Cairo, Amiri Quran and Reem Kufi replace Flutter's CDN fallback fonts (checked by a coverage script).
- **Offline (D9, D10, D11)**: our own `sw.js` (no `skipWaiting`, versioned caches, capture after first load so the first visit stays under 15 MB, an update button in Settings); a **Settings tile** downloads the whole
  Mushaf (size from a manifest, space check, progress, stop, resume, safe to press twice); `persist()` only in that flow.
- **Web input and layout (D13)**: mouse drag and keyboard page turning, optional on-screen arrows after a mouse event, right-click for the ayah menu, the existing landscape geometry as the desktop reading column.
- **Honesty and credits (D14, D15)**: one first-use bar about where the data lives, the reminders line, the private-window bar, About with the takedown line and the web-only links; every new Arabic string is a proposal in
  one file for the owner to confirm.
- **Tests (D16)**: test-first; VM tests with injected fakes for every policy class; `flutter test --platform chrome` for the `package:web` adapters where it runs; a headless-Chromium Playwright smoke script under
  `tool/web_smoke/` (zero third-party requests, reload keeps the data, offline reads, the whole-Mushaf download); the owner's real-browser check on a phone and a desktop (constitution 1.4.0 Principle IX).

## Technical Context

**Language/Version**: Dart 3.14 / Flutter 3.50 (Android and web); Python 3 with `uv` for the build tools; JavaScript only for `web/sw.js.in` (about 150 lines) and the bootstrap lines of `index.html`

**Primary Dependencies**: `material_ui`, `provider`, `drift`, `drift_flutter`, `file_picker` (already used); **`package:web`** becomes a direct dependency (already transitive; the blessed browser API); **no new pub package**. Dev
tools outside `pubspec.yaml`: Playwright (`uv run --with playwright`), `fonttools` (coverage script; and conversion only if the fallback of D3 is used). New binary artifacts in `web/`: `sqlite3.wasm`, `drift_worker.js` (D8)

**Storage**: the existing drift database in the browser (IndexedDB, OPFS off); the browser's Cache API for the shell and the data; one new `Settings` key `webDataNoticeSeen`; **no table, no backup change** (data-model.md)

**Testing**: `flutter test` (VM) with new files only under `test/web/` and `test/support/web_harness.dart`; `flutter test --platform chrome` for adapters; `tool/web_smoke/` Playwright (Chromium; Firefox and WebKit best
effort); the existing **2067 tests unchanged and green**; the owner's real-browser check

**Target Platform**: Web, current Chrome on an Android phone and a current desktop browser (the gate); Firefox and Safari best effort; Android app unchanged (owner's phone <phone> for the Android guard if needed)

**Project Type**: mobile app plus a static website built from the same code

**Performance Goals**: SC-001 first page 8 s first visit / 3 s later; SC-002 next page under 1 s in 95% of turns; SC-004 results within 1 s, search ready within 5 s; SC-008 at most 15 MB before the first page; SC-010 offline
start within 3 s (research D18 says which the spike supports and how each is measured)

**Constraints**: static files only, no server, account, analytics, cookies or request to another host (enforced by CSP and a smoke test); Quran text, order and page/line distribution never modified, the web serves the same
generated files (validation stops the build); a page is shown only when its own font and layout are ready; no reminders or notification prompt; the picture and PDF code not built; the Android app, its permissions
(no INTERNET) and the backup format unchanged, APK +<1 MB; the tree is shared with other sessions (explicit `git add`, one commit per task, no branches, `.specify/feature.json` stays on feature 003); nothing is
deployed, uploaded or signed in to before the owner's «ارفع» (FR-036, FR-037)

**Scale/Scope**: about 14 new files in `lib/web/` and `lib/web/js/` (about 1,400 lines) plus `lib/main_web.dart` (about 80); about 8 shared files edited by additive optional parameters (`app.dart`, `db.dart`, `links.dart`,
`share_service.dart`, `settings_screen.dart`, `about_screen.dart`, the tips gate, `reader_screen.dart`); `web/` (index, manifest, icons, `sw.js.in`, `sqlite3.wasm`, `drift_worker.js`); `tool/build_web.sh`,
`tool/web_font_coverage.py`, `tool/web_smoke/` (about 6 scripts); about 30 new test files; `docs/research/licenses.md`, `docs/release/WEB_PUBLISH.md`; the site is about 135 to 160 MB in about 1,700 files

## Constitution Check

*GATE: passed before research and again after the design (constitution 1.4.0).*

| Principle | Check |
|---|---|
| I Quran text integrity | The web serves **the same generated files** as the APK (layout JSON, word data, fonts), compared file by file and by sha256 in `tool/build_web.sh`; the existing validation (604 pages, line counts, every word once and in order) **runs first and stops the web build on failure** (FR-035). The font bytes are QUL's original WOFF2 or the app's TTF, never edited (the owner's converted copies, identical in cmap, hmtx, unitsPerEm and glyf for 604 of 604, are only a fallback). A page appears only when its font and layout were both read, online or offline, and a missing one is a typed error, never a fallback font (bundled Arabic fonts plus a coverage script remove the engine's CDN fallback). No Quran text code is edited. **Pass** |
| II Mushaf first | The site opens on a Mushaf page: no landing page, no consent banner, no install step; the data notice is a dismissible bar after the tips, not a screen before the Mushaf. The one-tab screen replaces the app only in a second tab. Position survives reloads. **Pass** |
| III Focus | No new feature: the same v1.0.0 set; no adhan, dua or hadith added; the khatm dua is the one that exists. Picture and PDF are removed from the web, not added. **Pass** |
| IV Offline, private, free (1.4.0 web rules) | Static files only, no server code, account, database outside the browser or sync (FR-027); zero requests to other hosts, enforced by a CSP, a request log in the smoke test and a bundle audit (FR-028); Vercel analytics stay off and are named in the publish checklist; reader data stays in the browser (the host sees ordinary file requests only, FR-029); after the first visit the app and every opened page work offline, and the whole Mushaf is fetched only on the reader's request, size told first (FR-031). `sw.js` runs in the browser and is not a server. **Pass** |
| V Licensing | The public site serves the fonts and data on the APK's stance (1.4.0); every new artifact (`sqlite3.wasm`, `drift_worker.js`, the Flutter engine, and web notes on the existing rows) is read and recorded in `docs/research/licenses.md` **before any deploy**, by a script that fails if a row is missing (SC-016); the web About shows every Android credit plus the takedown line and the links (FR-034); removal steps are written (FR-039). **Pass, with the records as tasks** |
| VI Arabic and RTL | `html lang="ar" dir="rtl"`; every new string Arabic in one file, marked as a proposal, none machine-translated, each confirmed by the owner before «ارفع» (SC-014); page turning keeps the paper direction on touch, mouse and keyboard (next page on the left). **Pass (confirmation is a gate)** |
| VII Reliability | No reminders and no notification prompt on the web, said in Settings (FR-020); the last page survives reload, browser and device restart; the data-loss notice is shown on first use and kept in Settings; storage `volatile` (private window) is announced at every start; `persist()` is requested in the download flow. **Pass** |
| VIII App size (1.4.0 web rules) | First visit at most 15 MB before the first page (the spike's figure is about 4 MB; the capture step of the service worker is designed not to double it, and G6 measures it); the whole set (about 110 MB with WOFF2, about 172 MB with TTF) is fetched only on request after the size is shown. **Pass if G6 confirms** |
| IX Quality gates | Test-first (every policy class has a VM test written red first; stage 0 records the Android baseline before any edit); pure logic apart from the browser adapters; `flutter analyze` clean and the whole suite at the end of each stage; the existing tests unchanged; the **real-browser check on a phone and a desktop is a stage of its own** and a condition of «done» (FR-042); Safari and Firefox are best effort. **Pass** |
| Scope and Distribution (1.4.0) | The web version is a supported target under the web rules of IV, V, VII, VIII and IX; checked on a current Chrome on an Android phone and on a desktop browser; Safari on iPhone is not a gate; the backup file is the only bridge; the Android app does not change behaviour, permissions or data format. The hosting fallbacks of D1 that name another host need an amendment (1.4.0 says Vercel) and are flagged as owner decisions. **Pass** |

**Coordination, not deviation**: `reader_screen.dart`, `app.dart`, `settings_screen.dart` and the tips gate are also edited by other sessions on features 005 to 011; the web edits are small additive optional
parameters each made in one window and re-checked against the existing baselines.

## Project Structure

### Documentation (this feature)

```text
specs/012-web-version/
├── spec.md
├── plan.md                # this file
├── research.md            # decisions D1-D18, the early gates G1-G7, the success criteria map
├── data-model.md          # no table; the settings key, the in-memory web state, the offline pack, the caches, the site files
├── quickstart.md          # automated checks, the browser run, the owner's checks, the questions
├── contracts/
│   ├── site.md            # the published tree, headers, CSP, the zero-third-party contract, sw.js, removal
│   ├── dart-interfaces.md # the seams, WebEnvironment, WebDataBundle, OfflinePack, InstanceGuard, adapters
│   └── ui.md              # the strings (proposals), the screens that differ, layout rules
├── checklists/
│   └── requirements.md    # spec quality (specify step)
└── (tasks.md and a plan checklist come in their own steps)
```

### Source code (repository root; all of it is created in the implementation steps, not now)

```text
lib/
├── main_web.dart                    # NEW: the web entry point (about 80 lines); lib/main.dart is NOT edited
├── web/                             # NEW, pure Dart, runs in the VM test suite
│   ├── web_environment.dart         # WebEnvironment, StorageStatus, InputKind, UpdateState
│   ├── web_data_bundle.dart         # WebDataBundle, DataUnavailable
│   ├── offline_pack.dart            # OfflinePack, PackState, PackManifest, the four small interfaces
│   ├── instance_guard.dart          # InstanceGuard (the one-tab guard)
│   ├── web_reader_controls.dart     # keyboard, on-screen arrows, right-click (pure Flutter)
│   ├── web_settings_sections.dart   # the data section, the pack tile, the update line, the reminders line
│   ├── web_about_extras.dart        # the takedown line and the links
│   ├── web_notice_bar.dart          # the first-use bar and the private-window bar
│   ├── web_tips.dart                # tips worded for a pointer device
│   ├── web_strings.dart             # every new Arabic string, proposals (contracts/ui.md)
│   └── js/                          # NEW, package:web adapters; imported by main_web.dart and browser tests only
│       ├── web_share_service.dart   web_backup_files.dart   web_link_opener.dart
│       ├── web_fetcher.dart   cache_pack_store.dart   web_lock_api.dart   web_storage_probe.dart
│       └── service_worker_bridge.dart   pointer_kind_listener.dart
├── app.dart                         # EDIT (optional parameters: webEnvironment, scrollBehavior, fontFallback)
├── wirds/db.dart                    # EDIT (the web: argument of driftDatabase, an optional storage callback)
├── links.dart                       # EDIT (conditional import and one kIsWeb branch)
├── ayah/share_service.dart          # EDIT (ShareOutcome.copied)
├── mushaf/reader_screen.dart        # EDIT (optional PageTurner hook), in one window
├── settings/settings_screen.dart    # EDIT (the web sections, chosen by the WebEnvironment provider)
├── settings/about_screen.dart       # EDIT (web extras, chosen by the provider)
└── onboarding/...                   # EDIT (tips wording for a pointer device, chosen by the provider)

web/                                 # NEW (not created by `flutter create`, which also edits analysis_options.yaml)
├── index.html  manifest.json  favicon.png  icons/
├── sw.js.in                         # the service worker template (contracts/site.md)
├── sqlite3.wasm  drift_worker.js    # pinned, sha256 recorded in docs/research/licenses.md
tool/
├── build_web.sh                     # NEW: validate, build, assemble, audit; never pushes
├── web_font_coverage.py             # NEW: every code point the web can show is in Cairo, Amiri Quran or Reem Kufi
└── web_smoke/                       # NEW: serve.py, smoke.py, gate_g1_woff2.py, gate_g2_storage.py, a README
test/
├── web/                             # NEW: one file per contract (VM), web/js/ for browser tests
└── support/web_harness.dart         # NEW: fakes for fetch, cache store, lock, storage probe, clock
docs/
├── research/licenses.md             # EDIT in stage G, test-first: rows for the new artifacts and the web distribution
└── release/WEB_PUBLISH.md           # NEW in stage G: the publish steps, the Vercel checklist, the takedown steps (FR-039)
pubspec.yaml                         # EDIT: package:web as a direct dependency
```

**Not touched**: `lib/main.dart`, `lib/pdf/`, `lib/render/`, the picture action, `lib/reminders/`, `assets/`, `android/`, `README.md` and `README.en.md` (a later requirement: FR-038), `.specify/feature.json`.

**Structure Decision**: web-only behaviour is a separate folder of pure Dart with every browser call behind a tiny injected interface, so each rule is a VM test and Android never imports any of it; the web entry point
replaces conditional imports almost everywhere; the few shared-code edits are optional parameters whose defaults are today's behaviour and each has a test that pins the Android path first.

## Stages

| Stage | What | Gate to the next |
|---|---|---|
| **0 Baseline** | record: `flutter analyze` and the 2067 tests green, the list of test files and hashes, the APK size and permissions, the pinned rectangles of the reader and the index at 360x800, 800x1280, 1920x1080, `lib/main.dart` hash | committed before any edit of `lib/`, `test/` or `web/` |
| **A Early gates** (no product code) | G1 WOFF2 in `FontLoader`; G7 font coverage; G2 drift storage and two tabs; G3 `--wasm` vs JS; a throwaway build in the scratch folder only | each verdict written in `research.md`; G1 fixes the font extension, G3 the build flag, G7 the fallback list |
| **B Pure core** | `WebDataBundle`, `OfflinePack`, `InstanceGuard`, `WebEnvironment`, strings, keyboard map: tests first, all over fakes | VM green; the Android suite unchanged |
| **C Seams and the entry point** | adapters in `lib/web/js/` (browser tests), `main_web.dart`, the additive edits to `db.dart`, `links.dart`, `share_service.dart`, `app.dart`; web-only keys kept out of the backup | the app starts in Chromium from a local build; Android baselines equal |
| **D The screens** | notice bars, Settings sections, About extras, tips for a pointer, the reader hook, mouse drag, keyboard, arrows, right-click; no reminders; no picture or PDF | widget tests per contract; pinned rectangles equal; the bundle has no `lib/pdf` |
| **E The site and the build** | `web/` files, `sw.js.in`, `tool/build_web.sh`, headers and CSP, the audit; the smoke test | the smoke run green on Chromium; SC-005, SC-008, SC-009, SC-010 measured |
| **F Real-browser gates** | the owner on a phone browser and a desktop browser (quickstart); G6 numbers on the phone | Principle IX for the web; SC-001, SC-002, SC-003 side-by-side |
| **G Release records** | licences rows, `WEB_PUBLISH.md`, the strings confirmed, SC-016 | all records present |
| **H Deploy test and publish (owner only)** | **G4** deploy test needs the owner's sign-in and «ارفع», then the real publish, then the README (FR-038) | the owner's words; none of this runs without them |

G4 is listed in stage H as an approval, but its question (does the host accept the site) blocks the choice of hosting, so the owner is asked for it **early, right after stage C produces a placeholder site** (research D1).

## Complexity Tracking

| Item | Why | Simpler alternative rejected |
|---|---|---|
| **A second entry point `lib/main_web.dart` that repeats the parts of `_bootApp` that apply** | The Android boot (`main.dart`: reminders, workmanager, temp folder, renderer, PDF) must not change (FR-040); a web boot has to differ in half its lines | Editing `main.dart` to branch on the platform (its tests and the Android path would change), or `kIsWeb` inside shared classes (web imports would reach Android's compile) |
| **Shared-code edits** (`app.dart`, `db.dart`, `links.dart`, `share_service.dart`, `settings_screen.dart`, `about_screen.dart`, tips, `reader_screen.dart`) | FR-040 allows no behaviour change on Android, not «no edit»; each is an optional parameter, a conditional import or a provider-guarded section with a test written first that pins the Android path | Forking the screens for the web (two copies of Settings and About that drift apart) |
| **`ShareOutcome.copied`** | The spec's copy fallback needs an outcome the UI can answer with «تم نسخ نص الآية» | A web-only callback in the share path (a second route for the same message) |
| **Principle IV's «every feature MUST work fully offline»** | On the web a page is fetched once; 1.4.0 already words the exception (offline after the first visit, whole Mushaf on request) | none: recorded for the compliance review |
| **Principle VIII, a first visit that includes the service worker's capture** | Precaching the engine variants would download about 38 MB; a capture of what the page already loaded stays within the 15 MB budget, UNVERIFIED until G6 | Precache everything (breaks SC-008); no worker (breaks FR-031) |
| **`navigator.storage.persist()` can show Firefox's own prompt** | The spec's table says the browser asks for nothing; the prompt is the only way to ask the browser not to evict a 100+ MB cache and the database. It is tied to the reader's own tap on the download button | Never asking (the offline copy can vanish); asking at first launch (a prompt before the Mushaf, against Principle II) |
| **The one-tab guard** | A rule the spec leaves to the plan («the simplest safe behaviour»); it does not depend on which store drift picks | Trusting drift's tab sync (unverified on Chrome Android) |
| **The label's size is computed, not «170»** | With WOFF2 the whole Mushaf is about 110 MB; saying 170 would be untrue; with TTF it stays 172 | Keeping the number the owner wrote (untrue if G1 passes) |
| **JavaScript in the project** (`web/sw.js.in`, a few bootstrap lines) | A service worker is a browser script; Dart can compile one but a 150-line plain file is simpler to read, test and audit, and has no runtime library | A Dart-compiled worker (build complexity); Workbox (an npm dependency, a CDN default) |
| **A second repository for the built site** | The site exceeds the CLI limit and the fonts are git-ignored on purpose; only a repository of the built files lets Vercel deploy with no CLI and no build | CLI upload (over 100 MB), build on Vercel (an unofficial Flutter image and no fonts), fonts on a second host (breaks FR-028) |
| **Playwright, `fonttools` outside `pubspec.yaml`** | The smoke test and the coverage check need a real browser engine and the font tables; both are dev tools like the existing Python tools | VM tests only (cannot prove reload, offline, zero requests) |
| **A hosting fallback that names another host** | Constitution 1.4.0 names Vercel; if gate G4 fails the plan must say what comes next | Silence: the owner would meet it at deploy time. Any such move needs an amendment first |

No other deviation from the constitution (1.4.0).

## Owner decisions needed (recommended default first; none blocks the early gates except G4)

1. **Hosting route**: a separate built-site repository connected to Vercel through Git (recommended); the alternative is moving the whole site to another free host (needs an amendment).
2. **Site repository visibility and the deploy test**: private repository (recommended) and a first deploy test of a small placeholder site, which needs the owner's sign-in and «ارفع» even for a preview.
3. **Traffic caps**: accept the free caps and watch the usage page (recommended); an identical mirror on a second host is the alternative.
4. **COOP/COEP off** and IndexedDB (recommended, decided once before launch); the alternative (on, OPFS) is rejected.
5. **One tab at a time** (recommended); the alternative allows two where the measured store is safe.
6. **`--wasm` build** (recommended) with the automatic fallback; the plain JS build if any glyph differs.
7. **The download label shows the real size** from the manifest (recommended, about 110 MB or 172 MB); keeping «170» is the alternative.
8. **`persist()` only in the download flow** (recommended); the alternative asks when the first wird or bookmark is saved.
9. **An «apply update» button in Settings** (recommended); the alternative applies updates only when all tabs close.
10. **An open-source licences line in the web About** (recommended); the alternative records them in `licenses.md` only.
11. **Every new Arabic string** (`contracts/ui.md`) is a proposal the owner confirms (Principle VI, SC-014).

## Post-design re-check

After the design, the Constitution Check above still passes: nothing in the design edits Quran text or its distribution (I), the first screen is the Mushaf (II), no feature was added (III), no host but the site's own is
reachable by construction (IV), every artifact has a licence task before deploy (V), the strings are in one file for the owner (VI), reminders are absent and the data-loss notice is permanent (VII), the first visit has a
measured budget and the bulk download needs a tap (VIII), and the real-browser gate is a stage of its own (IX). The open risks are the three unverified facts (G1 WOFF2 in `FontLoader`, G2 the storage chosen on Chrome Android,
G4 the Git deployment size on Hobby) and each has a fallback written in `research.md`.
