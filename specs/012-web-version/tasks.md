---

description: "Task list for feature 012: the web version of «مصحف الحافظ»"
---

# Tasks: Web Version of «مصحف الحافظ»

**Input**: Design documents from `/specs/012-web-version/` (spec.md, plan.md, research.md, data-model.md, contracts/site.md, contracts/dart-interfaces.md, contracts/ui.md, quickstart.md). Plan commit bf52438; constitution 1.4.0 in force.

**Prerequisites**: plan.md, spec.md (both read). Owner decisions: all eleven plan decisions approved with the recommended option on 2026-11-21 (hosting = a separate private GitHub repository holding the built site, connected to Vercel through Git; IndexedDB with COOP/COEP off; `--wasm` build falling back to the normal build on any rendering difference; one app tab at a time; the download button shows the real size from `pack.json`; an «تطبيق التحديث» button in Settings; `persist()` only when the download button is pressed; an open-source components line in the web About; every new Arabic string in `contracts/ui.md` stays a **proposal** until the owner confirms it word by word).

**Tests**: REQUESTED (plan D16, Principle IX): test-first. Every implementation task is preceded by its failing test task. Existing 2067 Android tests stay unchanged and green.

**Organization**: Phase 1 is the early gates, Phase 2 setup, Phase 3 foundational, then one phase per user story (spec priority order; US9 is built before US8 because the publish needs it), a polish phase, and the publish phase whose last task is the README.

## Format: `- [ ] T### [P?] [Story?] Description with file paths`

- **[P]**: can run in parallel with its neighbours because it touches **different files** and depends on no incomplete task. A task that edits a **shared file** (a file other sessions or other tasks also edit) is never `[P]` and says **SHARED FILE**.
- **[USn]**: the user story of spec.md. **OWNER ACTION**: needs the owner in the session (sign-in, approval, real device, wording). **OWNER APPROVAL**: a download or an install the owner approves first (name, source and size are stated to the owner).
- A task marked **TEST (red)** must be run and seen to FAIL for the stated reason before the matching implementation task starts; the implementation task makes it green.

## Rules that apply to EVERY task (shared folder and safety)

1. **One commit per task**, with explicit paths only: `git add <the files the task names>` then `git commit -m "<type>: 012 T### <short>" -- <the same paths>`, ending with the harness attribution trailer. Never `git add -A`, `git add .`, `git commit -a`; no branches; never push, deploy, upload or sign in anywhere (the owner does, FR-036, FR-037).
2. `.specify/feature.json` stays pointing to `specs/003-reader-font-size`; speckit scripts run with `SPECIFY_FEATURE_DIRECTORY=specs/012-web-version SPECIFY_FEATURE_NO_PERSIST=1`.
3. `lib/main.dart` is **never edited** (the web uses `lib/main_web.dart`); `lib/pdf/`, `lib/render/`, `lib/reminders/`, `assets/`, `android/`, existing files under `test/`, `README.md` and `README.en.md` are not edited by any task except where a task names them (README only in the last task).
4. Quran text, order and page/line distribution are never edited (Principle I): data is copied byte for byte and compared by sha256.
5. Evidence of every gate and owner check is written as a small file under `specs/012-web-version/gates/` or `specs/012-web-version/evidence/` and committed with its task. A verdict is `PASS` or `FAIL` plus the measured number and the consequence.
6. Constrained fields are cited as `data-model.md` + `Entity.field`; the constraint text lives only there.
7. Nothing goes online before the owner's explicit «ارفع». Any task that would push, deploy or create a public address is an **OWNER ACTION** and does not run without it.
8. **Probe apps never live in the repository tree** (`analysis_options.yaml` excludes only `build/**` and `android/**`, so a probe `pubspec.yaml` or `lib/` under the repository would make `flutter analyze` fail). Every probe app is written and built under the scratchpad folder `/tmp/claude-1000/-home-omar-Projects/594a7d94-d936-4527-b032-30937d92ae18/scratchpad/gates/` (called `$GATES` below); only the small verdict files `specs/012-web-version/gates/*.md` and the Python runners under `tool/web_smoke/` (which take the probe folder as an argument) are committed. If the scratchpad was cleared, the task that needs a probe rewrites it there.

## Path Conventions

Flutter project at the repository root: `lib/`, `test/`, `web/`, `tool/`, `docs/`, `specs/012-web-version/`. Python tool tests are `tool/test_*.py` (house style). New VM tests live only under `test/web/` and `test/support/`.

---

## Phase 1: Early gates (no product code; plan stage A)

**Purpose**: settle the three unverified facts and the font coverage before anything is built. No file under `lib/`, `test/`, `web/` or `pubspec.yaml` changes in this phase. Throwaway builds happen in the scratchpad folder only. Each gate writes `specs/012-web-version/gates/G<n>.md` with a PASS/FAIL result.

**Checkpoint**: G1, G2, G3, G7 have written verdicts; G4 is prepared and waits for the owner; the decisions of fonts (G1), build flag (G3) and fallback list (G7) are recorded in research.md.

- [X] T001 Create the verdict template `specs/012-web-version/gates/README.md` (fields: gate, date, command, engines, measured numbers, PASS/FAIL, consequence for the plan) and the folder `specs/012-web-version/evidence/README.md`
- [X] T002 **OWNER APPROVAL** Ask the owner to approve, once, the dev-tool downloads the gates and the smoke test need: `uv run --with playwright` (Python package) and `python -m playwright install chromium firefox webkit` (browser engines; state the size before running). Record the answer in `specs/012-web-version/evidence/downloads-approved.md`. Without a yes, gates run on a locally installed Chrome only and Firefox/WebKit are recorded «not run»
- [X] T003 [P] G1 probe: write the small Flutter probe app under `$GATES`g1_fontloader/ (pubspec.yaml, lib/main.dart; **outside the repository tree**, rule 8) that loads pages 1, 2 and 50 through `FontLoader` from (a) QUL's original WOFF2 in `data-raw/qul/x-font-qpc-v2-woff2/` and (b) the app's TTF in `assets/fonts/qpc-v2/`, drawing the first lines from `assets/mushaf/pages/*.json`; no change to the main project and no file of the probe is committed
- [X] T004 [P] G1 script: write `tool/web_smoke/gate_g1_woff2.py` that takes the probe folder (`$GATES`g1_fontloader/) as an argument, copies it into a build folder under `$GATES`, builds it for CanvasKit and for skwasm, screenshots pages 1, 2 and 50 per format and engine (Chromium gate; Firefox and WebKit best effort), and prints PASS only if WOFF2 pixels equal TTF pixels
- [X] T005 Run **G1** (research «Early gates» G1): does Flutter's `FontLoader`/CanvasKit accept the 604 WOFF2 originals; write `specs/012-web-version/gates/G1.md`. PASS fixes `fontExtension = woff2` and the manifest sizes; FAIL fixes `ttf` and the label size (about 172 MB, plan decision 7) and notes the sizes. Either way the QUL fonts are used byte for byte, never converted
- [X] T005a Record the size-wording change in `specs/012-web-version/evidence/size-wording.md`: spec.md FR-031, SC-008, SC-010, User Story 9, the «Differences on the web» table and the Clarifications no longer say «about 170 MB» but «the real size computed from the manifest (about 110 MB with WOFF2, about 172 MB with TTF, decided by gate G1)», and the Arabic button label of FR-031 carries `{N}` (owner decision of 2026-11-21: the button shows the real size from `pack.json`). State which of the two numbers G1 picked. Note that the constitution 1.4.0 line that still says «about 170 MB» is **not** edited here; it is corrected by the PATCH amendment 1.4.1 of task T145a at the end of the feature
- [X] T006 [P] G2 probe and script: write the probe app under `$GATES`g2_storage/ (outside the repository tree, rule 8) and the runner `tool/web_smoke/gate_g2_storage.py` (takes the probe folder as an argument) that report which store drift picks (IndexedDB or inMemory) with `DriftWebOptions` and COOP/COEP off, on Chromium (Firefox and WebKit best effort), and whether two tabs corrupt or block each other
- [X] T007 Run **G2** and write `specs/012-web-version/gates/G2.md`: store chosen per engine, two-tab behaviour; confirms the Web Lock one-tab guard is needed (plan decision 5) and what `StorageStatus` each case maps to (data-model.md `StorageStatus`)
- [X] T008 [P] G3 script: write `tool/web_smoke/gate_g3_wasm_vs_js.py` that builds the G1 probe (from `$GATES`g1_fontloader/) with `--wasm` and with the normal JS build, compares screenshots pixel for pixel, measures first paint and 20 page-turn times
- [X] T009 Run **G3** and write `specs/012-web-version/gates/G3.md`: equal pixels and not slower = `--wasm` stays; any glyph or pixel difference = the normal JS build (plan decision 6). Re-run later on the real app (Phase 11)
- [X] T010 [P] G7 TEST (red): write `tool/test_web_font_coverage.py` with small synthetic font files: the checker must fail on a code point missing from Cairo ∪ Amiri Quran ∪ Reem Kufi and pass when covered; run it and see it fail (the script does not exist)
- [X] T011 [P] G7 implement `tool/web_font_coverage.py` (fonttools via `uv run --with fonttools`; every code point the web build can show, taken from the app's own strings, Settings, About, the dua and the UI files, is in the three bundled fonts), make the test green, run it on the real fonts and write `specs/012-web-version/gates/G7.md` (zero gaps = PASS; any gap lists the code points and goes back to the owner with a licence need)
- [X] T012 [P] G4 prep script: write `tool/web_smoke/make_placeholder_site.py` that generates a **synthetic** site of 135 to 160 MB in about 1,700 files (`index.html` saying it is a test, one `.wasm` file, many `.woff2`-named random files under `d/<12 hex>/`, `vercel.json` with the headers and CSP of `contracts/site.md`) into a scratch folder, and contains none of the app's real data
- [X] T013 G4 prep: generate the placeholder site, create the **second repository locally only** in a scratch folder outside `quran-app` (`git init`, one commit, **no remote**, no push), measure size and file count, and write `specs/012-web-version/gates/G4-prep.md` listing exactly what the owner will be asked to do (create a private GitHub repository, push, sign in to Vercel, import, deploy once, analytics off)
- [ ] T014 **OWNER ACTION** G4 approval: show the owner the G4-prep summary and ask for the explicit «ارفع» for the deploy test only (a preview-sized synthetic site, not published anywhere). Record the owner's exact words and date in `specs/012-web-version/gates/G4-approval.md`. **Never schedule a push or deploy before this file exists with a yes.** If the owner answers «not now», G4 stays open, nothing is pushed or deployed, and nothing blocks Phases 2 to 12; the publish path (T155a to T159) stays **blocked** because `tool/check_publish_ready.py` (T153) needs the G4 verdict to be PASS. The G4 test deployment is a private, unlisted trial with synthetic content: it is not the public address of FR-036/SC-013 and the owner deletes it or keeps it private after the test (spec FR-036)
- [ ] T015 **OWNER ACTION** G4 deploy test (only after the approval file exists): the owner creates the private GitHub repository for the built site, pushes the placeholder from the scratch repository, signs in to Vercel themselves, imports the repository (no build step, Hobby plan), deploys once, and confirms Web Analytics, Speed Insights and any toolbar are off. No password, token or key is typed or stored by anyone else (FR-037). After T016 the owner deletes this trial deployment or keeps it private and unlisted, and says which in `specs/012-web-version/gates/G4.md`
- [ ] T016 G4 verify (after the owner action): with the test address the owner supplies, check `curl -sI` of the sample files for the `Content-Type: application/wasm`, compression, `Cache-Control`, the CSP and the absence of COOP/COEP, and that a Git deployment of 135 to 160 MB was accepted; write `specs/012-web-version/gates/G4.md` PASS/FAIL. FAIL goes back to the owner with the fallbacks of research D1 (they need a constitution amendment)
- [X] T017 Record in `specs/012-web-version/research.md` (SHARED FILE) the verdicts of G1, G2, G3, G7 (and G4 when it exists), the font extension, the build flag, the fallback-font result, and that the owner approved all eleven decisions on 2026-11-21
- [ ] T018 Phase check: `flutter analyze` and `flutter test` (2067 tests) unchanged and green, and `git status` shows no change under `lib/`, `test/`, `web/`, `pubspec.yaml`; write `specs/012-web-version/gates/phase1-check.md`; also confirm that `git ls-files --others --exclude-standard` lists no `pubspec.yaml` or probe `lib/` folder inside the repository (the probes are under `$GATES`) so `flutter analyze` sees no stray project

---

## Phase 2: Setup (shared infrastructure; plan stage 0 and the first tests)

**Purpose**: record the Android baseline before any edit of `lib/`, `test/` or `web/`, add the one dependency, the strings file and the test harness.

- [ ] T019 Stage 0 baseline: record in `specs/012-web-version/baseline.txt` the `flutter analyze` result, the 2067 passing tests, the **baseline commit id** (`git rev-parse HEAD`), the list of existing test files with sha256 (informational), the sha256 of `lib/main.dart`, the existence of the generated data (`assets/mushaf/`, `assets/ayah/`, 604 TTF, 604 WOFF2), and the APK size and permissions from a debug-signed local build (`ALLOW_DEBUG_SIGNED=1 tool/release.sh`, **no install, no upload**)
- [ ] T020 [P] Write `tool/web_smoke/check_android_guard.sh`. It compares against the **baseline commit id** recorded in `baseline.txt` (T019) and looks only at what **this feature** changed, so other sessions' legitimate edits of tests or of `lib/main.dart` do not fail it: it fails if any commit whose message matches `012 T` after the baseline commit (`git log <baseline>..HEAD --grep='012 T' --name-only`) touches `test/` outside `test/web/` and `test/support/` (the test files this feature owns) or touches `lib/main.dart`; if an uncommitted change in the working tree touches those same paths; or if the APK size grows by 1 MB or more or gains the INTERNET permission (SC-007, FR-040). The count of existing tests is a minimum (the baseline count may grow through other sessions), and the existing tests must pass
- [ ] T021 [P] TEST (pass-first guard) Write `test/web/android_rects_baseline_test.dart` that pins the rectangles of the reader and of the index at 360x800, 800x1280 and 1920x1080 against the **unchanged** code (green now; it guards every later shared edit)
- [ ] T022 [P] TEST (red) Write `test/web/pubspec_deps_test.dart`: `package:web` is a direct dependency and no other pub package was added compared with `baseline.txt`; run and see it fail
- [ ] T023 SHARED FILE Edit `pubspec.yaml` and `pubspec.lock`: add `package:web` as a direct dependency only (no new package); the test goes green
- [ ] T024 [P] TEST (red) Write `test/web/web_strings_test.dart`: every key of `contracts/ui.md` «Strings» exists exactly once in `lib/web/web_strings.dart`, is non-empty Arabic (no Latin letters except the `{N}`, `{done}`, `{total}` placeholders), is marked as a proposal with `confirmed = false`, and the pack label has the `{N}` placeholder (not 170); run and see it fail
- [ ] T025 [P] Create `lib/web/web_strings.dart` with every proposal of `contracts/ui.md` (words exactly as written, none machine-translated, `tipsPointer*` drafted for mouse and keyboard, `noscript`/`cannotStart` as constants for `index.html`); test green
- [ ] T026 [P] Write `specs/012-web-version/strings-confirmation.md`: one row per string (key, proposal, where shown, owner verdict, corrected text) for the owner to confirm word by word (SC-014, FR-041)
- [ ] T027 Phase check: whole suite and `flutter analyze` green; run `tool/web_smoke/check_android_guard.sh`; result in `specs/012-web-version/evidence/phase2-check.md`; `flutter analyze` must still show no probe project in the tree (rule 8)

---

## Phase 3: Foundational (blocking prerequisites; plan stages B, C and E up to a first readable page)

**Purpose**: the pure core, the browser adapters it needs, the second entry point, the site shell, the build script with its audit, and the smoke skeleton. No user story can run in a browser before this is done.

**CRITICAL**: no user-story phase starts before this phase ends.

### Pure core (tests first, all over fakes)

- [ ] T028 Create `test/support/web_harness.dart`: fakes for fetch (with offline, 504, thrown and slow modes), a lock (held-elsewhere mode), and a clock
- [ ] T029 [P] TEST (red) `test/web/web_environment_test.dart`: `WebEnvironment` fields, `StorageStatus` values and the mapping from drift's result (data-model.md `WebEnvironment.storage`, `StorageStatus`), `InputKind`, `UpdateState` transitions `none` to `waiting` to `applying` (data-model.md `WebEnvironment.update`), `applyUpdate` calls only the injected function
- [ ] T030 [P] TEST (red) `test/web/web_data_bundle_test.dart`: key mapping `assets/fonts/qpc-v2/p<N>.ttf` to `d/<v>/fonts/p<N>.<fontExtension>` (1 to 604, else the same `FlutterError` as `rootBundle`), `assets/mushaf/**` and `assets/ayah/**` mapped, any other key goes to the fallback, a refusal throws `DataUnavailable(offline|failed)` and never returns empty or partial bytes, a page is ready only when font **and** layout were read (Principle I, FR-007, data-model.md section 4)
- [ ] T031 [P] TEST (red) `test/web/instance_guard_test.dart`: `acquire` gives `owner` or `blocked`, `retry` moves `blocked` to `owner` only when the lock is free, with no lock API it is `owner` (data-model.md `InstanceState`), the lock is taken before the database is opened
- [ ] T032 [P] Implement `lib/web/web_environment.dart` (`WebEnvironment`, `StorageStatus`, `InputKind`, `UpdateState`); constrained values and transitions are exactly `data-model.md` + `WebEnvironment.storage`, `StorageStatus`, `InputKind`, `UpdateState`, `WebEnvironment.update`, `WebEnvironment.buildId`, `WebEnvironment.dataVersion`
- [ ] T033 [P] Implement `lib/web/web_data_bundle.dart` (`WebDataBundle`, `DataUnavailable`, `DataUnavailableKind`) using the G1 font extension
- [ ] T034 [P] Implement `lib/web/instance_guard.dart` (`InstanceGuard`, `InstanceState`) over the injected lock interface; values and transitions are exactly `data-model.md` + `InstanceState`

### Browser adapters (browser tests first)

- [ ] T035 [P] TEST (red) `test/web/js/web_fetcher_lock_test.dart` (`@TestOn('browser')`, `flutter test --platform chrome`): `WebFetcher` returns only 200 bytes and abort works; `WebLockApi` `ifAvailable` returns null when held. If Chrome does not run here, record that in the task evidence and move the case to the smoke script (no silent skip)
- [ ] T036 [P] Implement `lib/web/js/web_fetcher.dart` and `lib/web/js/web_lock_api.dart` (`package:web`, thin over `fetch`, `AbortController`, `navigator.locks`; no policy inside)

### Shared-code seams (each guarded by a test that pins the Android path first)

- [ ] T037 TEST (red) `test/web/app_web_params_test.dart`: `MushafApp` accepts the three **optional** parameters (`webEnvironment`, `scrollBehavior`, `fontFallback`), with them left at defaults the tree and the rectangles of `android_rects_baseline_test.dart` equal today's, and `Provider<WebEnvironment?>` is null on Android
- [ ] T038 SHARED FILE Edit `lib/app.dart`: add the three optional parameters and the provider; every default reproduces today; run the baselines
- [ ] T039 TEST (red) `test/web/main_web_wiring_test.dart`: `lib/main_web.dart` provides `Reminders`, `PageRenderer`, `TempShareFiles` and `PdfJob` as null; takes the lock before opening the database; `lib/main.dart` imports nothing under `lib/web/` (static check of the file text) and no commit of this feature touches it (the guard of T020; its sha256 is compared with `baseline.txt` only as information)
- [ ] T040 Create `lib/main_web.dart` (about 80 lines): explicit wiring of the web implementations behind the existing interfaces, `WebDataBundle` as the `AssetBundle`, `InstanceGuard` before the database, Reminders/renderer/temp folder/PDF job absent (FR-017, FR-020); `lib/main.dart` not edited

### The site shell and the build

- [ ] T041 [P] TEST (red) `tool/test_web_static_files.py`: `web/index.html` has `lang="ar" dir="rtl"`, the Arabic title «مصحف الحافظ», a dark start screen, Arabic noscript and failure text from the strings file, no URL of another host; `web/manifest.json` has name, icons, `display: standalone`, the Night theme colour, `lang: ar`, `dir: rtl`; run and see it fail
- [ ] T042 [P] Create `web/index.html`, `web/manifest.json`, `web/favicon.png`, `web/icons/` (derived from the app's existing icon, no new design, no copyright issue); the test goes green. Service worker registration is added in Phase 11
- [ ] T043 [P] TEST (red) `tool/test_web_vendor_pins.py`: `tool/web_vendor_pins.txt` lists `web/sqlite3.wasm` and `web/drift_worker.js` with the pinned versions (sqlite3 3.9.1, drift 2.35.4) and sha256, and the files in `web/` match; run and see it fail
- [ ] T044 **OWNER APPROVAL** Obtain `web/sqlite3.wasm` and `web/drift_worker.js` at the pinned versions: first record both licences in `docs/research/licenses.md` terms (read-only note in `specs/012-web-version/evidence/vendor-licences.md`), then try the local pub cache (copy if present at the pinned versions); otherwise ask the owner to approve the download (file names, source repository, size) before it runs. **If the owner declines the download** the fallback is to copy `sqlite3.wasm` and `drift_worker.js` from the existing spike copy at `/tmp/claude-1000/-home-omar-Projects/594a7d94-d936-4527-b032-30937d92ae18/scratchpad/web-spike/app/web/` (only after the licence note exists and only if their versions match the pins; the sha256 is verified against the pins), and if that copy is missing or does not match, the task is **blocked** with a note in `specs/012-web-version/evidence/vendor-blocked.md` and Phases 3 (from T056) onward wait for the owner. Then write the sha256 into `tool/web_vendor_pins.txt` and add both files under `web/` (the pins test goes green)
- [ ] T045 [P] TEST (red) `tool/test_web_pack_manifest.py`: `tool/web_pack_manifest.py` computes `dataVersion` as 12 hex of sha256 over the sorted `path:sha256` lines of `d/<v>/` without `pack.json`, equal data gives equal version, and `pack.json` lists every file with its exact length and sha256 (data-model.md `PackManifest.files`, `PackFile.path`, `PackFile.bytes`, `PackFile.sha256`, `dataVersion`)
- [ ] T046 [P] TEST (red) `tool/test_web_audit.py`: the audit fails on a moved path left under `assets/assets/`, a file over 25 MiB, a `*.symbols` file, a `pack.json` mismatch, a `dataVersion` that differs from the directory name, a third-party URL in a loaded file, a library under `lib/pdf/` or `lib/render/` in the `--dump-info`, a source map or analytics file, and when a data file differs from `assets/` by even one byte (FR-017, FR-028, FR-035)
- [ ] T047 [P] Implement `tool/web_pack_manifest.py` (makes both tests it serves green); `dataVersion`, `files`, `path`, `bytes`, `sha256` follow `data-model.md` + `PackManifest.dataVersion`, `PackManifest.files`, `PackFile.path`, `PackFile.bytes`, `PackFile.sha256` (section 5 `dataVersion`)
- [ ] T048 [P] Implement `tool/web_audit.py` (makes `test_web_audit.py` green)
- [ ] T049 [P] TEST (red) `tool/test_vercel_json.py`: the generated `vercel.json` has the headers and the exact CSP of `contracts/site.md`, `immutable` for `/d/**`, `no-cache` for the shell files, the wasm `Content-Type`, `Referrer-Policy`, `Permissions-Policy`, and **no** `Cross-Origin-Opener-Policy` or `Cross-Origin-Embedder-Policy` (plan decision 4)
- [ ] T050 [P] Implement `tool/web_vercel_json.py` (headers only, no rewrites); test green
- [ ] T051 [P] TEST (red) `tool/test_build_web_sh.py`: `tool/build_web.sh` has `set -euo pipefail`, refuses with a clear message when the generated assets are missing or the font count is not 604, runs the Quran data validation of `tool/build_quran_assets.py` and the sha256 comparison **before** building, passes `--wasm` (or not, per the G3 verdict) with `--no-web-resources-cdn --pwa-strategy=none`, `--dart-define=DATA_VERSION` and `--dart-define=BUILD_ID`, runs `tool/web_font_coverage.py` and the audit, and contains no `git push`, no `vercel`, no upload
- [ ] T052 Create `tool/build_web.sh`: validate, build, assemble `build/web-site/` (moved data into `d/<dataVersion>/` with the G1 extension, delete the moved paths from `assets/assets/`, delete `*.symbols`, `pack.json`, `vercel.json`, `version.json`), audit, print size, file count and build id (`buildId` and `dataVersion` as in `data-model.md` + `buildId`, `PackManifest.dataVersion`); it **never** pushes or uploads. The printed file count and the number of `pack.json` entries are the authority for the counts quoted in the spec, research and data model (see T056)
- [ ] T053 [P] TEST (red) `tool/test_serve_headers.py`: `tool/web_smoke/serve.py` serves a folder on 127.0.0.1 with the headers of its `vercel.json` and the `.wasm` MIME
- [ ] T054 [P] Implement `tool/web_smoke/serve.py`; test green
- [ ] T055 [P] Write `tool/web_smoke/smoke.py` core and `tool/web_smoke/README.md`: request log (fail on any host other than `127.0.0.1:<port>`), CSP violation and console error failure, and the check «a Mushaf page is the first screen, nothing asked of the visitor» (FR-001); run it against an empty `build/web-site` and see it fail (red)
- [ ] T056 Run the first full build (`tool/build_web.sh`) and the smoke core; the first Mushaf page appears with zero third-party requests and no CSP violation. Write `specs/012-web-version/evidence/phase3-smoke.md` (size, file count, request hosts, and three separate counts: the files of the three source asset folders, the entries of `pack.json`, the requests of a whole-Mushaf download; if any differs from the figures quoted in spec.md, data-model.md or research.md, amend that text in the same task so each statement says what it counts). Fix defects in the files that own them, one commit each
- [ ] T057 Phase check: whole suite and `flutter analyze` green; `tool/web_smoke/check_android_guard.sh`; the rectangle baselines equal; result in `specs/012-web-version/evidence/phase3-check.md`

**Checkpoint**: the app starts in Chromium from a local build and reads a page; user stories can now proceed (US1 and US2 first; later phases touch several shared files, so they run one after the other, not in parallel).

---

## Phase 4: User Story 1 - Read the Mushaf in a phone browser and a desktop browser, with the page as printed (Priority: P1) MVP

**Goal**: the reader opens on a Mushaf page, turns pages by touch, mouse, keyboard and arrows, shows waiting and failure states honestly, keeps the page's shape from 360 px to 1920 px.

**Independent Test**: build the site, run the smoke, open pages 1, 2, 50, 293 and 604, turn 20 pages each way, check no horizontal scroll at 360, 800 and 1920, compare the generated page data with the app's for all 604 pages.

### Tests for User Story 1 (write first, see them fail)

- [ ] T058 [P] [US1] TEST (red) `test/web/web_reader_controls_test.dart`: ← is next page and → previous (paper direction), `PageDown`/`Space`/`PageUp`, `Home`/`End`, `Enter` on a focused word opens the ayah menu, on-screen arrows (at least 48 px) appear only after a mouse event and hide with the bars, reachable by `Tab`, `Esc` closes dialogs (FR-004, contracts/ui.md «Reader»)
- [ ] T059 [P] [US1] TEST (red) `test/web/reader_page_states_test.dart`: the waiting state `pageLoading`, `pageFailed` with `retry` on a failed fetch, `pageNeedsConnection` when offline, already opened pages still turn, and no page is ever drawn without its font and layout (FR-007, FR-008, FR-032; `DataUnavailableKind.offline|failed` mapping)
- [ ] T060 [P] [US1] TEST (red) `test/web/pointer_input_test.dart`: mouse drag turns pages through the supplied `scrollBehavior`, right-click opens the ayah menu, the browser context menu is off over the page only, `InputKind` flips on pointer events and is kept in memory only
- [ ] T061 [P] [US1] TEST (red) `test/web/reader_layout_web_test.dart`: at 360x800, 800x1280 and 1920x1080 the page keeps the existing landscape geometry as a centred reading column and nothing scrolls sideways (FR-003, FR-043); the Android rectangles of `android_rects_baseline_test.dart` stay equal
- [ ] T062 [P] [US1] TEST (red) `test/web/page_turner_hook_test.dart`: `ReaderScreen` accepts an optional `PageTurner? turner` (`next`, `previous`, `first`, `last`, `openAyahMenuAtFocus`); with it null the pager behaves as today; read the pager first and fix the exact shape in this test

### Implementation for User Story 1

- [ ] T063 [US1] SHARED FILE Edit `lib/mushaf/reader_screen.dart` in one window: the optional `PageTurner? turner` hook only; re-run the baselines and `page_turner_hook_test.dart`
- [ ] T064 [P] [US1] Implement `lib/web/web_reader_controls.dart` (`WebReaderControls`: Shortcuts, Actions, the arrows after a mouse event, focus ring, pure Flutter)
- [ ] T065 [P] [US1] TEST (red) `test/web/js/pointer_kind_listener_test.dart` (`@TestOn('browser')`): `PointerKindListener` feeds `InputKind` from pointer events, in memory only
- [ ] T066 [P] [US1] Implement `lib/web/js/pointer_kind_listener.dart` feeding `InputKind`; the browser test goes green
- [ ] T067 [US1] SHARED FILE Edit the page-load error path in `lib/mushaf/` (the file found by reading `mushaf_page_card.dart` and `page_font_loader.dart`; one minimal edit): map `DataUnavailable` to the two Arabic messages and `retry`; the Android path stays equal
- [ ] T068 [US1] SHARED FILE Edit `lib/main_web.dart`: pass the mouse-drag `scrollBehavior`, the bundled Arabic `fontFallback` list (the G7 result) and the `WebReaderControls` wrapper; `main_web_wiring_test.dart` stays green
- [ ] T069 [US1] **Acceptance run** (written after the implementation, not red-first; the red-first tests are T058 to T062) Extend `tool/web_smoke/smoke.py`: 20 page turns with the keyboard and 20 with a mouse drag, the index and go-to-page, widths 360/800/1920 with no horizontal scroll, a keyboard-only walk of the reader (SC-011, SC-002 timing of 100 turns); run it against the previous phase's build first to show it detects the missing controls, then against the new build until it passes
- [ ] T070 [US1] Run the all-604 page parity check on the real build: the data files under `build/web-site/d/<v>/mushaf/` and the fonts equal `assets/` and `data-raw/` byte for byte (zero differences, SC-003, FR-002, FR-035); write `specs/012-web-version/evidence/us1-parity.md`
- [ ] T071 [US1] Phase check: whole suite, `flutter analyze`, Android guard script, rebuild and smoke; `specs/012-web-version/evidence/us1-check.md`

**Checkpoint**: US1 works alone and is the MVP.

---

## Phase 5: User Story 2 - Keep my wirds and count my khatmas in the browser (Priority: P1)

**Goal**: wirds, wird days, khatma and the dua behave as on Android and survive reloads, browser restarts and device restarts; the reader is told where the data lives; one tab at a time; no reminders.

**Independent Test**: create two wirds, mark «تم», reload 20 times, restart the browser context, everything is there; open a second tab and see the one-tab screen.

### Tests for User Story 2 (write first)

- [ ] T072 [US2] TEST (red) `test/web/db_web_options_test.dart`: `AppDatabase.open()` passes the `web:` options (`sqlite3.wasm`, `drift_worker.js`) and an optional `onWebStorage` callback that maps drift's result to `StorageStatus` (data-model.md `StorageStatus`); the Android call is byte-for-byte as today
- [ ] T073 [P] [US2] TEST (red) `test/web/web_notice_bar_test.dart`: the first-use bar with `dataNotice` shows once after the tips, is dismissible (not a modal), writes `1` to `Settings.webDataNoticeSeen` (data-model.md `Settings.webDataNoticeSeen`) and never shows again; the private-window bar `privateWindow` shows at every start while `StorageStatus.volatile`
- [ ] T074 [P] [US2] TEST (red) `test/web/tab_blocked_screen_test.dart`: when `InstanceState.blocked` the screen shows only `tabBlocked` and `tabRetry` in the app's look, the database is not opened in that tab, retry moves to the app when the lock frees (data-model.md `InstanceState`)
- [ ] T075 [P] [US2] TEST (red) `test/web/web_settings_sections_test.dart` (data section and reminders line only; the pack tile and update line come in Phase 11): «التذكيرات» replaced by `remindersAndroidOnly` with no switch, no time and no permission card (FR-020, SC-015); a «بياناتك» section with `dataNotice`, export and import buttons, the storage line, the build id; the Android Settings stays equal when the provider is null

### Implementation for User Story 2

- [ ] T075a [P] [US2] TEST (red) `test/web/khatma_dua_web_test.dart` (FR-011): a wird passing page 604 and returning to page 1 increases the khatma counter by one over the web database options, the khatm dua screen is reachable only after the last page, is labelled as a supplication that is not part of the Quran text, and its wording equals the Android asset byte for byte; run on the unchanged Android code path first where it passes (a pass-first guard) and with the web providers where it must fail if the dua is missing from the web bundle's fallback
- [ ] T076 [US2] SHARED FILE Edit `lib/wirds/db.dart`: the `web:` argument of `driftDatabase` and the optional `onWebStorage` callback, ignored on Android
- [ ] T077 [P] [US2] Implement `lib/web/web_notice_bar.dart` (first-use bar and private-window bar)
- [ ] T078 [P] [US2] Implement `lib/web/tab_blocked_screen.dart` (the one-tab screen)
- [ ] T079 [US2] SHARED FILE Implement `lib/web/web_settings_sections.dart` (data section, storage line, reminders line) and edit `lib/settings/settings_screen.dart` to show them only when `Provider<WebEnvironment?>` is non-null
- [ ] T080 [US2] SHARED FILE Edit the tips gate (`lib/onboarding/tips_gate.dart`) so the notice bar is shown after the tips and not before; Android path pinned by a baseline test written first inside `test/web/web_notice_bar_test.dart`
- [ ] T081 [US2] SHARED FILE Edit `lib/main_web.dart`: take the lock first, show `tab_blocked_screen` when blocked, open the database with `onWebStorage`, provide `WebEnvironment`
- [ ] T082 [US2] **Acceptance run** (after the implementation, not red-first) Extend `tool/web_smoke/smoke.py`: create two wirds and mark «تم», reload 20 times and restart the context, data and last page are the same (SC-009, FR-006); open a second tab and see the one-tab screen, close the first and retry; no reminder control and no `Notification.requestPermission` call (SC-015); a private context shows the private-window bar; pass a page-604 wird through to page 1 and see the khatma counter increase and the khatm dua reachable only after the last page with the same text as Android (FR-011). Run it against the previous build first (it must fail), then against the new one
- [ ] T083 [US2] Phase check: whole suite, `flutter analyze`, Android guard, baselines equal, rebuild and smoke; `specs/012-web-version/evidence/us2-check.md`

---

## Phase 6: User Story 3 - Search surah names and ayat (Priority: P2)

**Goal**: search gives the same results as feature 011 and says it is preparing.

**Independent Test**: type each query of feature 011's spelling table in the web app and compare with the Android results; results appear within 1 s, ready within 5 s.

- [ ] T084 [US3] TEST (red) `test/web/search_web_parity_test.dart`: `SearchService` over `WebDataBundle` with a fake fetch serving the files of `assets/ayah/` returns exactly the results `rootBundle` gives for every query in feature 011's spelling table (hamza, ta marbuta, ya, diacritics; read the table from the feature 011 test file, do not copy it) (FR-013, SC-004)
- [ ] T085 [US3] TEST (red) `test/web/search_preparing_test.dart`: while search prepares on first use the screen shows `searchPreparing`, surah-name results are immediate; the existing Android search tests stay unchanged
- [ ] T086 [US3] SHARED FILE Edit the search screen (`lib/search/search_screen.dart`, minimal) to show `searchPreparing` from the web strings, only when the provider is non-null
- [ ] T087 [US3] **Acceptance run** (after the implementation, not red-first) Extend `tool/web_smoke/smoke.py`: run the feature 011 search table in the browser, measure first result time and readiness time
- [ ] T088 [US3] Run **G6 (search part)** and write `specs/012-web-version/gates/G6-search.md`: `compute()` jank on web, readiness time against SC-004; if over, add «slice the ayah data parsing» as a new TEST plus implementation pair in this phase before continuing
- [ ] T089 [US3] Phase check: whole suite, `flutter analyze`, Android guard; `specs/012-web-version/evidence/us3-check.md`

---

## Phase 7: User Story 4 - Mark pages and come back to them (Priority: P2)

**Goal**: bookmarks work as on Android in the browser and survive reloads.

**Independent Test**: add a bookmark with a note, remove it, undo, reload: the state is as left.

- [ ] T090 [P] [US4] TEST (red) `test/web/bookmarks_keyboard_test.dart`: the bookmark button and the bookmarks list are reachable and operable by keyboard and mouse, controls at least 48 px in both looks, undo works (FR-012, FR-043)
- [ ] T091 [US4] **Acceptance run** (not red-first; T090 is the red test) Extend `tool/web_smoke/smoke.py`: add a bookmark with a note, remove and undo, open the list, jump to it, reload and check
- [ ] T092 [US4] Fix whatever the two tests above show in the file that owns it (a task per file, each a commit with its own explicit path); if nothing fails, record «no change needed» in `specs/012-web-version/evidence/us4-result.md`
- [ ] T093 [US4] Phase check: whole suite, `flutter analyze`, Android guard; `specs/012-web-version/evidence/us4-check.md`

---

## Phase 8: User Story 5 - Carry my data between the phone and the browser with a backup file (Priority: P2)

**Goal**: export is a browser download and import is a file chooser, in the Android v1.0.0 format; reminder settings in a phone file survive a web round trip.

**Independent Test**: import a v1.0.0 phone file on the web, export it, import that on the phone side (test): wirds, wird days, bookmarks and settings equal, reminder keys included.

### Tests for User Story 5 (write first)

- [ ] T094 [P] [US5] TEST (red) `test/web/web_backup_files_test.dart`: file name from `backupFileName(now)`, the bytes equal exactly the JSON `Backup` produced (FR-024)
- [ ] T095 [P] [US5] TEST (red) `test/web/backup_web_keys_test.dart`: `Settings.webDataNoticeSeen` is exported like every setting, is in `kKeptOnImport` so importing a phone file does not bring the notice back (data-model.md `Settings.webDataNoticeSeen`), Android ignores the unknown key; a file with the reminder keys (`kahfEnabled`, `kahfDay`, `kahfMinutes`, `notifyEnabled`, `notifyMinutes`, data-model.md section 1) imports and exports again unchanged (FR-023, FR-026); an Android v1.0.0 export fixture imports completely
- [ ] T096 [P] [US5] TEST (red) `test/web/js/web_backup_files_browser_test.dart` (`@TestOn('browser')`): `Blob`, `URL.createObjectURL`, a hidden `<a download>` click, revoke after the click
- [ ] T096a [P] [US5] TEST (red) `test/web/web_import_refusals_test.dart` (FR-025): over `WebBackupFiles` fakes, (a) cancelling the file dialog returns no file and changes nothing and shows no error, (b) a damaged file (truncated or invalid JSON) is refused with the same message as Android, (c) a foreign JSON file is refused the same way, (d) a file of a newer version is refused with the Android «newer version» message, (e) after each refusal the wirds, wird days, bookmarks and settings are unchanged, and the confirmation «متابعة» is asked before any replace on a good file; the messages are read from the existing Android backup strings, not retyped

### Implementation for User Story 5

- [ ] T097 [US5] SHARED FILE Edit `lib/backup/backup_service.dart`: add `webDataNoticeSeen` to `kKeptOnImport` (the existing set that keeps the device's own value); the existing backup tests stay unchanged
- [ ] T098 [P] [US5] Implement `lib/web/js/web_backup_files.dart` (`BackupFiles` over Blob and download; `pick` through `file_picker`)
- [ ] T099 [US5] SHARED FILE Edit `lib/main_web.dart`: provide `WebBackupFiles`; show `fileSaved` after export
- [ ] T100 [US5] Create the fixture `tool/web_smoke/fixtures/android_v1_backup.json` from an existing test export fixture (read only, a copy, no personal data) and extend `tool/web_smoke/smoke.py`: export (the download event), import it, import the Android fixture, export again and compare (SC-006); then the FR-025 refusals in the browser: cancel the file dialog, a damaged file, a foreign file and a newer-version file each show the Android message and change nothing (this is an **acceptance run** after T099, not red-first)
- [ ] T101 [US5] Phase check: whole suite, `flutter analyze`, Android guard; `specs/012-web-version/evidence/us5-check.md`

---

## Phase 9: User Story 6 - Know whose work this is, and what the web version cannot do (Priority: P2)

**Goal**: the web About shows every Android credit plus the takedown line and the web links; licences are recorded; honesty about differences; nothing hidden.

**Independent Test**: open About in the web app and compare with Android's; run the licences script (SC-016).

### Tests for User Story 6 (write first)

- [ ] T102 [P] [US6] TEST (red) `test/web/web_about_extras_test.dart`: every Android credit, source, version and link remains, `النص القرآني لم يُعدَّل` and the dedication remain, `rightsHolder` shows with the Issues address, links to the repository and `androidApp`, `openSourceLine` shows only when the owner confirmed it, links open in a new tab through `LinkOpener`, Android About stays equal when the provider is null (FR-034)
- [ ] T103 [P] [US6] TEST (red) `test/web/web_link_opener_test.dart`: the `window.open` call is the first thing `open` does (no `await` before it), https only, returns false when the window is null; and a pin of the Android `PlatformLinkOpener` channel path
- [ ] T104 [P] [US6] TEST (red) `tool/test_check_web_licenses.py`: `tool/check_web_licenses.py` fails when `docs/research/licenses.md` lacks a web row for any of: `sqlite3.wasm`, `drift_worker.js`, the Flutter engine and CanvasKit, the QPC V2 page fonts (web distribution), the layout and word data, the tafsir, translation and gharib data, Cairo, Amiri Quran, Reem Kufi (SC-016, FR-033)
- [ ] T105 [P] [US6] TEST (red) `tool/test_web_publish_doc.py`: `docs/release/WEB_PUBLISH.md` has the sections: publish steps, the Vercel checklist naming Web Analytics, Speed Insights and toolbar off, the licences and strings gates, the takedown steps of FR-039 (delete a path under `d/<dataVersion>/` and bump the version, or delete the project and then the README link), the changelog, the README rewording list (D17)

### Implementation for User Story 6

- [ ] T106 [P] [US6] Implement `lib/web/web_about_extras.dart` (takedown line, links, optional open-source line)
- [ ] T107 [US6] SHARED FILE Edit `lib/settings/about_screen.dart` to show the extras only when `Provider<WebEnvironment?>` is non-null
- [ ] T108 [US6] SHARED FILE Edit `lib/links.dart`: a conditional import and one `kIsWeb` branch in `PlatformLinkOpener.open`; the Android channel test stays green
- [ ] T109 [P] [US6] Implement `lib/web/js/web_link_opener.dart` (`window.open(url, '_blank', 'noopener,noreferrer')`)
- [ ] T110 [US6] SHARED FILE Read each new artifact's licence (sqlite3.wasm, drift_worker.js, Flutter engine and CanvasKit, and the web distribution note for the existing rows) and edit `docs/research/licenses.md` with the rows and the sha256 pins; implement `tool/check_web_licenses.py` until its test is green
- [ ] T111 [P] [US6] Write `docs/release/WEB_PUBLISH.md` (the sections above; no step is executed, none runs a push); its test goes green
- [ ] T112 [P] [US6] Constitution and spec check, read only: confirm in `.specify/memory/constitution.md` 1.4.0 the web rules of Principles IV, V, VII, VIII, IX and Scope exist, then map FR-032 to FR-039 to the task that implements each (FR-032 offline vs unavailable message: Phase 4 and Phase 11; FR-033 licences: this phase; FR-034 About: this phase; FR-035 text unmodified: Phase 3 audit; FR-036 and FR-037: Phase 1 and Phase 13; FR-038 README: last task; FR-039 removal: `WEB_PUBLISH.md`); write `specs/012-web-version/evidence/fr032-039-map.md`. The constitution is **not** edited
- [ ] T113 [US6] Phase check: whole suite, `flutter analyze`, Android guard, `uv run python tool/check_web_licenses.py`; `specs/012-web-version/evidence/us6-check.md`

---

## Phase 10: User Story 7 - The same looks, sizes, ayah menu, dua and first-run tips (Priority: P3)

**Goal**: both looks, reading and text sizes, the ayah menu without the picture and PDF entries, the share fallback, the khatm dua and tips worded for a pointer device.

**Independent Test**: open the ayah menu with a right-click, share the text, change the look and sizes, read the tips with a mouse; screenshots of pages 1, 2, 50, 293, 604 in both looks exist for the owner.

### Tests for User Story 7 (write first)

- [ ] T114 [P] [US7] TEST (red) `test/web/ayah_sheet_web_test.dart`: with no renderer and no PDF job provided the sheet has no «الصفحة والسورة» heading, no picture entry, no PDF entry and nothing in their place; tafsir, translation, meanings and copy remain (FR-017)
- [ ] T115 [P] [US7] TEST (red) `test/web/share_outcome_test.dart`: `ShareOutcome.copied` exists, the callers answer it with `shareCopied`, Android's `PlatformShareService` never returns it (existing share tests unchanged)
- [ ] T116 [P] [US7] TEST (red) `test/web/web_share_service_test.dart`: the decision table (canShare yes and no, `AbortError` is `dismissed`, other failure, no `share` then copy then `copied`); the text equals Android's (FR-016)
- [ ] T117 [P] [US7] TEST (red) `test/web/web_tips_test.dart`: on `InputKind.pointer` the tips use the `tipsPointer*` texts, on touch the feature 008 tips are unchanged, skippable at any moment, once per browser (`tipsSeen`)

### Implementation for User Story 7

- [ ] T118 [US7] SHARED FILE Edit `lib/ayah/share_service.dart`: add `ShareOutcome.copied` and handle it in the callers (the file or files found by searching for `ShareOutcome`)
- [ ] T119 [P] [US7] Implement `lib/web/js/web_share_service.dart` (`navigator.canShare/share`, clipboard fallback)
- [ ] T120 [P] [US7] Implement `lib/web/web_tips.dart` and, as a SHARED FILE edit, wire it through `lib/onboarding/tips_gate.dart` only when the provider is non-null
- [ ] T121 [US7] SHARED FILE Edit `lib/main_web.dart`: provide `WebShareService`
- [ ] T122 [US7] **Acceptance run** (after the implementation, not red-first) Extend `tool/web_smoke/smoke.py`: both looks, reading size and text size, `reducedMotion`, screenshots of pages 1, 2, 50, 293, 604 in both looks into `build/web-smoke/` for the owner's side-by-side, ayah menu content
- [ ] T123 [US7] Verify that the build's `--dump-info` has no library under `lib/pdf/`, `lib/render/` or the picture action (the audit of Phase 3 on the real build); write `specs/012-web-version/evidence/us7-no-pdf.md`
- [ ] T124 [US7] Phase check: whole suite, `flutter analyze`, Android guard, baselines; `specs/012-web-version/evidence/us7-check.md`

---

## Phase 11: User Story 9 - Open the site with no internet after the first visit (Priority: P3)

**Goal**: first visit stays under 15 MB, pages already opened work offline, one button downloads the whole Mushaf after telling the real size; stop, resume and double press are safe; updates are applied by the reader.

**Independent Test**: visit, read ten pages, go offline, reload: last page and the ten pages work; press the download button, stop, resume, finish, read 20 never-opened pages offline.

### Tests for User Story 9 (write first)

- [ ] T125 [US9] SHARED FILE Extend `test/support/web_harness.dart` with fakes for `PackStore`, `PackFetcher`, `PackLock` and `StorageProbe` (quota and persist modes)
- [ ] T126 [US9] TEST (red) `test/web/offline_pack_test.dart`: the whole state machine of data-model.md section 3: `PackManifest.files`, `PackFile.path`, `PackFile.bytes`, `PackFile.sha256`; `idle.missingBytes` from the cache vs manifest and never `complete` without `recheck()`; the size is known before `start()`; skip cached files; a length or sha256 mismatch counts as `failed(integrity)` and is never cached; `start()` while running is a no-op; stop mid-file keeps cached files; resume; quota gives `failed(quota)` and removes nothing; `complete` returns to `idle` when files are missing; fetch order pages 1 to 604 with font and layout together then the ayah data; a second tab cannot start it (lock `mushaf-al-hafiz-pack`); `persist()` is called only from `start()`
- [ ] T127 [P] [US9] TEST (red) `tool/test_sw_contract.py`: `web/sw.js.in` follows `contracts/site.md` «sw.js contract»: scope `/`, cache names `shell-<BUILD_ID>` and `data-<DATA_VERSION>`, stale caches deleted at `activate`, no `skipWaiting()` at install, `clients.claim()` only without a previous controller, same-origin GET only, `d/<DATA_VERSION>/**` cache-first with the Content-Length check, `504` on failure with no cache, no answer for another data version, messages `capture`, `skipWaiting`, `update-waiting`, and none of background sync, push, notifications, periodic sync, analytics
- [ ] T128 [P] [US9] TEST (red) `test/web/js/offline_adapters_test.dart` (`@TestOn('browser')`): `CachePackStore` (cache `data-<v>`, length of a stored entry), `WebStorageProbe` (`estimate`, `persist`, `persisted`), `ServiceWorkerBridge` (absent or failed registration gives `UpdateState.none`, `capture` after first paint, `skipWaiting` only after the button)
- [ ] T129 [P] [US9] TEST (red) `test/web/pack_tile_update_test.dart`: the tile label `packButton` with `{N}` computed from `pack.json`, the size sheet (`packConfirmTitle`, size, `packStart`, `packCancel`, `packNoSpace`), progress `packProgress` and `packStop`, `packDone`, `packFailed`, the progress announced at most once per 5%, the persist lines `persistGranted`/`persistDenied`, the update line `updateReady` with the button `updateApply` (`UpdateState.waiting`)
- [ ] T130 [US9] TEST (red) SHARED FILE `tool/test_web_static_files.py` additions (extends the Phase 3 file): `web/index.html` registers `sw.js` before Flutter bootstraps and the app still runs if registration fails

### Implementation for User Story 9

- [ ] T131 [P] [US9] Implement `lib/web/offline_pack.dart` (`OfflinePack`, `PackState`, `PackManifest`, `PackFile`, the four interfaces); states, transitions and rules are exactly `data-model.md` + `PackState`, `PackManifest.files`, `PackFile.path`, `PackFile.bytes`, `PackFile.sha256` (section 3 rules); test green
- [ ] T132 [P] [US9] Implement `web/sw.js.in` (about 150 lines of plain JavaScript); test green
- [ ] T133 [P] [US9] Implement `lib/web/js/cache_pack_store.dart`, `lib/web/js/web_storage_probe.dart`, `lib/web/js/service_worker_bridge.dart`; the values they report are exactly `data-model.md` + `PersistState` (storage probe) and `UpdateState` (bridge)
- [ ] T134 [US9] SHARED FILE Edit `web/index.html`: register `sw.js` before Flutter starts; and edit `tool/build_web.sh` to generate `sw.js` (build id, data version, core list) and verify the core list files exist
- [ ] T135 [US9] SHARED FILE Extend `lib/web/web_settings_sections.dart` with the pack tile, the persist and update lines, and wire `ServiceWorkerBridge` and the pack into `lib/main_web.dart` (SHARED FILE); `pack_tile_update_test.dart` green
- [ ] T136 [US9] **Acceptance run** (after the implementation, not red-first; T126 to T130 are the red tests) Extend `tool/web_smoke/smoke.py`: bytes before the first page at most 15 MB on a first visit with the capture step (SC-008), offline reload shows the last page within 3 s and the ten pages turn (SC-010), a never-opened page shows `pageNeedsConnection`, the whole-Mushaf download against the local server (size first, stop, resume, press twice, finish) then 20 never-opened pages offline, an update flow
- [ ] T137 [US9] Run **G5** (service worker offline start, runtime caching, update, pack, quota on Chromium; Firefox and WebKit best effort) and **G6** (first visit bytes, search preparation, page-turn times on the built site); write `specs/012-web-version/gates/G5.md` and `specs/012-web-version/gates/G6.md`; a failing number returns to the file that owns it
- [ ] T138 Re-run **G3** on the real built app (`--wasm` vs the JS build, same pixels, first paint, 20 turns) and update `specs/012-web-version/gates/G3.md`; on any difference switch `tool/build_web.sh` to the JS build (one commit)
- [ ] T139 [US9] Phase check: whole suite, `flutter analyze`, Android guard, baselines, rebuild and smoke; `specs/012-web-version/evidence/us9-check.md`

---

## Phase 12: Polish and cross-cutting concerns (before any publish step)

**Purpose**: prove the whole, with no owner needed.

- [ ] T140 Run `flutter analyze` (no issues) and the whole suite: the 2067 existing tests unchanged and green plus the new ones; `tool/web_smoke/check_android_guard.sh`: existing test files unchanged by hash, `lib/main.dart` unchanged, APK size under +1 MB, permissions the same, still no INTERNET (SC-007, FR-040); `specs/012-web-version/evidence/final-suite.md`
- [ ] T141 Run `tool/build_web.sh` end to end and the full smoke on Chromium: zero requests to other hosts, no CSP violation, no cookie, SC-001 to SC-011 and SC-015 numbers written in `specs/012-web-version/evidence/final-smoke.md`
- [ ] T142 [P] Run the smoke on Firefox and WebKit as best effort and record the results (not a gate) in `specs/012-web-version/evidence/best-effort-engines.md`
- [ ] T143 [P] Check every `data-model.md` constrained field (`Settings.webDataNoticeSeen`, `PackManifest.files`, `PackManifest.dataVersion`, `PackFile.path`, `PackFile.bytes`, `PackFile.sha256`, `StorageStatus`, `InstanceState`, `UpdateState`, `PackState`, `PersistState`, `InputKind`, `WebEnvironment.buildId`, `dataVersion`) is cited by an implementing task and by a test; list gaps in `specs/012-web-version/evidence/citations.md` and fix any by amending the task text
- [ ] T143a [P] Explicit check of FR-030 (free, non-commercial, no payments): search `lib/web/`, `web/`, `build/web-site/` and the strings for payment, donation, sponsor, advert and paid-feature terms and for any third-party payment or analytics script, and confirm the host plan is the free Hobby plan with no paid add-on enabled (checklist of `WEB_PUBLISH.md`); write `specs/012-web-version/evidence/fr030-no-payments.md` with PASS or FAIL
- [ ] T144 [P] Run `quickstart.md` «Automated» section top to bottom and note any command that no longer matches the files; fix the wording of `specs/012-web-version/quickstart.md` if needed
- [ ] T145 Confirm `.specify/feature.json` still points to `specs/003-reader-font-size`, nothing is pushed, nothing is deployed, and write `specs/012-web-version/evidence/final-safety.md`
- [ ] T145a **OWNER CONFIRMATION required** Constitution PATCH amendment 1.4.1: the constitution 1.4.0 still says «about 170 MB» for the whole-Mushaf download while the spec now says «the real size computed from the manifest (about 110 MB with WOFF2, about 172 MB with TTF, decided by gate G1)» (T005a). Prepare the one-line wording correction and the sync-impact note, show it to the owner and apply it with the constitution skill **only after the owner confirms**; until then the line stays as is and this task is open. No other part of the constitution changes

---

## Phase 13: User Story 8 - The owner publishes the site and links it from the README (Priority: P3, last)

**Goal**: the owner checks the site in real browsers, confirms every string, says «ارفع», signs in to Vercel themselves, the site goes online, and only then the README links to it.

**Independent Test**: before «ارفع» nothing is online and the README is unchanged; after it, one click from the README reaches the working site on a device that never visited it.

**Nothing in this phase runs without the owner. No task here pushes, deploys or uploads on its own.**

### Owner checks (real browsers, Principle IX, FR-042)

- [ ] T146 [US8] **OWNER ACTION** Desktop browser check: the owner follows `quickstart.md` «By hand in a desktop browser» against a **local** address with `tool/web_smoke/serve.py` in current Chrome, then Firefox (best effort) and Safari if available; record results and any defect in `specs/012-web-version/evidence/owner-desktop.md`
- [ ] T147 [US8] **OWNER ACTION** Phone browser check: the owner follows `quickstart.md` «By hand on the owner's Android phone» on current Chrome against a local address (serving to the phone's network address only with the owner's approval); stopwatch for the first page, swipe direction, landscape, 150% zoom, long-press, share, wirds and bookmark across closing Chrome and a phone restart, airplane mode, the download button, private tab, Add to Home screen; record in `specs/012-web-version/evidence/owner-phone.md`
- [ ] T148 [US8] **OWNER ACTION** Side-by-side check of pages 1, 2, 50, 293, 604 with the phone app in both looks, in a phone browser and a desktop browser, using the screenshots of the smoke run (SC-003); record in `specs/012-web-version/evidence/owner-side-by-side.md`
- [ ] T149 [US8] **OWNER ACTION** Import a real Android v1.0.0 backup file from the owner's phone on the web, export, and import on the phone (SC-006 on real data); record in `specs/012-web-version/evidence/owner-backup.md`
- [ ] T150 [US8] Fix defects the owner found, one task per defect added here with its test first and one commit per file, until the owner signs the three evidence files above

### Release records (plan stage G)

- [ ] T151 [US8] **OWNER ACTION** The owner confirms or corrects every new Arabic string word by word in `specs/012-web-version/strings-confirmation.md` (and answers whether the open-source line stays); no string is changed by anyone else (SC-014)
- [ ] T152 [US8] SHARED FILE Apply the owner's corrections to `lib/web/web_strings.dart` and set every confirmed flag; update `test/web/web_strings_test.dart` expectations only in new test files (existing tests untouched) so the test now requires `confirmed = true` for every shipped string
- [ ] T153 [US8] TEST (red) `tool/test_check_publish_ready.py`: `tool/check_publish_ready.py` fails unless the licences rows are present, all strings are confirmed, the three owner evidence files are signed, the audit passed, constitution is 1.4.0, and the G4 verdict is PASS (SC-014, SC-016)
- [ ] T154 [US8] Implement `tool/check_publish_ready.py` and run it; `specs/012-web-version/evidence/publish-ready.md` with its output (it only reads files; it deploys nothing)

### Publish (owner only)

- [ ] T155 [US8] **OWNER ACTION** The owner says «ارفع» for the real publish; record the exact words and date in `specs/012-web-version/evidence/publish-approval.md`. **Without this file, none of the next three tasks runs**
- [ ] T155a [US8] **OWNER ACTION for the repository, local steps only** Create or clone the **local clone of the private site repository** (the second repository of gate G4; created by the owner on GitHub, T015) in a folder outside `quran-app`, for example `~/Projects/quran-app-site`: if the owner already has the remote, `git clone` it (reading only; the owner signs in, nothing of the owner's secrets is typed by anyone else, FR-037); if not, `git init` it locally with **no remote**. Record the path and its remote state (none or the address the owner gave) in `specs/012-web-version/evidence/site-repo.md`. **T156 to T159 depend on T014 and T015** (the owner's approval file `gates/G4-approval.md` with a yes, and the G4 deploy test done); if the owner answered «not now» to T014, the publish path stays blocked here, no clone with a remote is made, nothing is pushed or deployed, and the feature ends at T154 with the site build ready locally
- [ ] T156 [US8] After the approval (and after T155a): run the final `tool/build_web.sh`, copy `build/web-site/` into the local clone of the private site repository and make its commit locally; **do not push** (write the commit id in `specs/012-web-version/evidence/site-commit.md`)
- [ ] T157 [US8] **OWNER ACTION** The owner pushes the site repository and signs in to Vercel themselves; the project is connected through Git; Web Analytics, Speed Insights and toolbar are confirmed off per the `WEB_PUBLISH.md` checklist; the owner gives the one public address (SC-013)
- [ ] T158 [US8] Verify the live address read-only: run the smoke against it (zero third-party hosts, headers of `contracts/site.md`, `.wasm` MIME), and record `specs/012-web-version/evidence/live-check.md`; a failure goes to the owner, with the takedown steps of `WEB_PUBLISH.md` ready
- [ ] T159 [US8] **OWNER ACTION** The owner opens the live address on their phone and on a desktop browser and says the site is good; record in `specs/012-web-version/evidence/owner-live.md`
- [ ] T160 [US8] **LAST TASK, waits for the site to be deployed and for the owner to say so** SHARED FILE Edit `README.md` and `README.en.md` (the only task allowed to): the link near the top and a short section about the web version and its differences, with the rewording list of research D17 (the «تطبيق أندرويد» header, offline after the first visit on the web, the permissions section, the size lines, what a web host sees, the differences table, the backup instructions) (FR-038, SC-012). Never before the live address and the owner's word exist

---

## Dependencies & Execution Order

### Phase dependencies

- **Phase 1 (Early gates)**: first; no product code. G4 steps wait for the owner and never block Phases 2 to 12 (the plan only needs G4's verdict before the publish).
- **Phase 2 (Setup)**: after Phase 1 (needs the font extension and build flag).
- **Phase 3 (Foundational)**: after Phase 2; blocks every story.
- **Phase 4 (US1)** then **Phase 5 (US2)**: both P1; US2 needs the Phase 3 entry point and US1's reader hook to be merged first because they edit `lib/main_web.dart` and `lib/mushaf/reader_screen.dart`.
- **Phases 6 to 8 (US3, US4, US5)**: after Phase 5 (they use the durable database and the settings sections); they touch different feature files but all edit `lib/main_web.dart` or `smoke.py`, so they run one after the other.
- **Phase 9 (US6) and Phase 10 (US7)**: after Phase 8; US7 follows US6 (both edit `lib/main_web.dart` and settings or tips files).
- **Phase 11 (US9)**: after Phase 10; it adds the service worker, the pack and the Settings tile, and it is built before the publish phase.
- **Phase 12 (Polish)**: after Phase 11.
- **Phase 13 (US8 publish)**: after Phase 12 and after the owner; T155a to T159 also depend on the owner's G4 approval and deploy test (T014, T015); if the owner said «not now» they stay blocked and nothing is pushed; the README task is the last task of the feature.

### Within every phase

- A **TEST (red)** task precedes the implementation task it serves and must be seen failing.
- Models and pure classes before adapters, adapters before wiring in `lib/main_web.dart`, wiring before the smoke extension turns green.
- The phase-end check (whole suite, `flutter analyze`, Android guard) closes every phase.

### Shared files (never `[P]` between tasks that name them)

`lib/main_web.dart`, `tool/web_smoke/smoke.py`, `tool/build_web.sh`, `lib/web/web_settings_sections.dart`, `test/support/web_harness.dart`, `tool/test_web_static_files.py`, `web/index.html`, `lib/app.dart`, `lib/wirds/db.dart`, `lib/links.dart`, `lib/ayah/share_service.dart`, `lib/mushaf/reader_screen.dart`, `lib/settings/settings_screen.dart`, `lib/settings/about_screen.dart`, `lib/onboarding/tips_gate.dart`, `lib/backup/backup_service.dart`, `lib/search/search_screen.dart`, `docs/research/licenses.md`, `specs/012-web-version/research.md`, `pubspec.yaml`, `pubspec.lock`, `README.md`, `README.en.md`.

## Parallel Execution Examples

- **Phase 1**: `T003 T004 T006 T008 T010 T012` (different probe, script and tool files) can be written together; each run task (G1, G2, G3) comes after its own script. The G4 owner tasks are strictly sequential.
- **Phase 3 pure core**: the three red tests `T029 T030 T031` together, then `T032 T033 T034` together.
- **US1 tests**: `T058 T059 T060 T061 T062` together (five different test files); then the reader-hook edit `T063` alone, then `T064 T065` together.
- **US5 tests**: `T094 T095 T096` together. **US6 tests**: `T102 T103 T104 T105` together. **US7 tests**: `T114 T115 T116 T117` together. **US9 tests**: `T127 T128 T129` together (the harness and `offline_pack_test.dart` come first and alone).
- Any task that names a SHARED FILE in this list runs alone.


## Implementation Strategy

### MVP first (User Story 1)

1. Phase 1 gates (G1, G2, G3, G7; G4 prepared and waiting for the owner).
2. Phase 2 baseline and Phase 3 foundational.
3. Phase 4 (US1): a readable Mushaf in Chromium with zero third-party requests. **Stop and validate**: smoke, parity of the 604 pages.
4. Add US2 (data survives, one tab, no reminders), then US3 to US7 in order, then US9 (offline), then polish.

### Incremental delivery and the owner

- Everything up to the end of Phase 12 runs without the owner except the approvals marked **OWNER APPROVAL** (downloads) and the optional early G4.
- The publish phase is the owner's: real-browser checks, string confirmation, «ارفع», sign-in, push; the README link is last.

### Notes

- If G1 fails the font extension is `ttf` and the label size follows `pack.json` (about 172 MB); if G3 fails the build is the plain JS build; if G7 shows a gap the owner is asked before any font is added.
- If Chrome cannot run `flutter test --platform chrome` here, browser-adapter cases move to the Playwright smoke script and the task evidence says so.
- A task that finds the design wrong stops and reports to the owner instead of changing the plan silently.
