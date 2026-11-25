# Quickstart: validating feature 012 (the web version)

Nothing here deploys, uploads or signs in anywhere. Steps marked **[OWNER]** need the owner in the session. Paths are relative to the repository root.

## Prerequisites

- Flutter 3.50.0 / Dart 3.14.0 on the PATH; Chrome or Chromium (`CHROME_EXECUTABLE`) for `flutter test --platform chrome`.
- The generated Mushaf data: `assets/mushaf/`, `assets/ayah/`, `assets/fonts/qpc-v2/` (604 TTFs) and `data-raw/qul/x-font-qpc-v2-woff2/` (604 original WOFF2). Missing: run the two commands that `tool/release.sh` prints.
- `uv` for the Python tools; the smoke test installs Playwright through `uv run --with playwright` and `python -m playwright install chromium firefox webkit` (a download the owner approves once, listed with its size
  before it runs; Firefox and WebKit are best effort).

## Automated, no browser of the owner's

```bash
# 0. The Android baseline BEFORE any edit (stage 0), recorded in specs/012-web-version/baseline.txt
flutter analyze && flutter test                       # 2067 tests green, no issues; keep the list of test files and their hashes
# 1. Early gates (research, "Early gates"): each prints a verdict and a measured number
uv run --with playwright python tool/web_smoke/gate_g1_woff2.py     # G1: does FontLoader accept WOFF2 (3 engines)
uv run --with playwright python tool/web_smoke/gate_g2_storage.py   # G2: which store drift picks; two tabs
uv run python tool/web_font_coverage.py                             # G7: every code point is covered by Cairo, Amiri Quran, Reem Kufi
# 2. Logic, written first (VM)
flutter test test/web --reporter expanded
flutter test --platform chrome test/web/js                          # package:web adapters in a real browser (if it runs here)
# 3. Everything earlier, unchanged
flutter test                                                        # the whole suite, once at the end of each stage; the 2067 stay green and unchanged
flutter analyze
# 4. Build the site, then audit it
tool/build_web.sh                                                   # validation, build, assemble, audit; prints size, file count, build id
# 5. The browser run against the built site (headless Chromium; Firefox and WebKit best effort)
uv run --with playwright python tool/web_smoke/smoke.py --site build/web-site
```

What the smoke run reports (and fails on): every request host (only `127.0.0.1` allowed), CSP violations, bytes transferred before the first page (SC-008), time to first page on a throttled 10 Mbit/s link (SC-001),
100 timed page turns (SC-002), the search table of feature 011 (SC-004), data surviving 20 reloads and a context restart (SC-009), backup export and import round trip (SC-006), offline reload and reading (SC-010), the
whole-Mushaf download then 20 never-opened pages offline (SC-010), widths 360/800/1920 with no horizontal scroll and a keyboard-only walk (SC-011), no reminder control and no notification request (SC-015), reduced
motion, the page screenshots of pages 1, 2, 50, 293, 604 in both looks under `build/web-smoke/` for the owner's side-by-side.

## Android guard (FR-040, SC-007), run at the end of each stage

```bash
git diff --stat -- test/ | grep -v '^ test/web\|^ test/support'   # nothing: existing tests are not edited
tool/release.sh   # ALLOW_DEBUG_SIGNED=1 for a test build; compare the APK size and permissions with the stage 0 record (under +1 MB, same permissions, still no INTERNET)
```

## The bundle audit (inside `tool/build_web.sh`, can be run alone)

Checks that: the moved data paths are gone from `assets/assets/`; no file is over 25 MiB; no `*.symbols`; `pack.json` lists every file under `d/<v>/` with the right bytes and sha256; `dataVersion` matches the directory
name; the loaded files contain no third-party URL (research D7); the `--dump-info` of the build has no library under `lib/pdf/`, `lib/render/` or the picture action (FR-017); the data files equal `assets/` byte for byte
(FR-035) and `tool/build_quran_assets.py`'s validation passed (604 pages, line counts, every word once and in order).

## By hand in a desktop browser **[OWNER]**

1. `python3 -m http.server --directory build/web-site 8080` is **not enough** (no headers, no wasm MIME); use `uv run python tool/web_smoke/serve.py build/web-site 8080`, which sets the headers of `vercel.json`.
2. Open `http://localhost:8080` in a current Chrome and in Firefox: a Mushaf page is first, no banner except the data notice after the tips. Turn pages with the mouse, with ← →, with the arrows; open the index, search «كهف»,
   «قل هو الله احد»; right-click a word: the sheet has tafsir, translation, meanings and **no** picture or PDF entry; share the text: the copy message appears when the browser has no share sheet.
3. Settings: the reminders line, the data notice, export a backup (a download), import it, import an Android v1.0.0 export (a file from the phone): wirds, bookmarks and settings equal; export again and import on the phone.
4. Compare pages 1, 2, 50, 293, 604 side by side with the phone app, in both looks. Use the screenshots of the smoke run to speed it up.
5. DevTools, Network: only the site's own host. Application, Storage: IndexedDB and Cache Storage, no cookies.
6. Press the download tile: the size is shown first; stop it half way; press again; let it finish; switch DevTools to Offline; reload; read pages never opened.
7. Open a second tab: the one-tab screen. Close the first, press «حاول مرة أخرى».

## By hand on the owner's Android phone, current Chrome **[OWNER]**

Run against a **local** address first (the phone and the computer on one network, `serve.py` bound to the network address, only with the owner's approval), and against the real site only after «ارفع».

1. First visit on mobile data: stopwatch from pressing the address to the first readable page (target 8 s; 3 s on the next visit). Note it.
2. Swipe left to right: the next page comes from the left. Turn 20 pages each way. Rotate to landscape. Read at 150% (the page moves by finger).
3. Long-press a word: the sheet. Share the ayah text: the phone's share sheet where Chrome has one, else the copy message.
4. Create two wirds and a bookmark, mark «تم», close Chrome completely, open again: everything is there; restart the phone, open again.
5. Airplane mode after reading ten pages: close and reopen: the last page opens and the ten pages turn; a page never opened shows «هذه الصفحة تحتاج اتصالًا بالإنترنت مرة واحدة.». With a connection press the download tile,
   read the size, stop and resume, finish, airplane mode again: 20 pages never opened.
6. Private tab: the private-window bar shows and nothing is remembered.
7. Chrome menu, «Add to Home screen» is allowed; the app opens full screen; note whether it shows the same wirds as the browser tab.
8. Read every new Arabic string aloud and confirm or correct it (the strings file has a confirmation column).

Safari on iPhone and Firefox: open the site, read, reload, note anything that breaks (not a gate).

## The deploy test and the publish **[OWNER]**, only after their words

1. **G4** (the first moment the owner is needed): the owner signs in to Vercel, creates a project from the site repository, deploys once. Before, with the owner's «ارفع» for this test: check headers
   (`curl -sI` the site's files), `.wasm` MIME, compression, that the 100 MB source limit is not applied to a Git deployment, and that Vercel's analytics are off. The test address is not published anywhere.
2. The real publish: `docs/release/WEB_PUBLISH.md` (written in stage G): licences recorded (SC-016), strings confirmed (SC-014), real-browser checks signed, **«ارفع»**; then the README links (a later step).

## What a failing number means

Read research D3 (G1), D5 (G2), D6 (G3), D9 (G5), D18 before changing anything. A number from the spike is a ceiling the plan believes; the real number comes from the gate.

## Questions for the owner (Egyptian Arabic, ready to ask; each has a proposed answer and nothing waits on them except G4)

1. الاستضافة: نعمل مستودع منفصل للموقع المبني ونربطه بـ Vercel من Git (المقترح)، ولا تفضّل موقعًا بديلًا بالكامل؟ والمستودع خاص (المقترح) ولا عام؟
2. تجربة النشر الأولى محتاجة تدخل بحسابك وتقول «ارفع» حتى لو معاينة، ننفّذها بنسخة تجريبية صغيرة الأول (المقترح)؟
3. COOP/COEP مقفولين (المقترح، التخزين IndexedDB، وبيتحدد مرة واحدة قبل الإطلاق).
4. نسمح بتبويب واحد بس مفتوح من التطبيق (المقترح)؟
5. نبني بـ `--wasm` (المقترح) ونرجع للنسخة العادية لو ظهر أي فرق في الرسم؟
6. زر تنزيل المصحف: نكتب الحجم الحقيقي بدل «نحو 170» (المقترح، حوالي 110 ميجا لو الخط WOFF2، و172 لو TTF)؟
7. نطلب «تخزين دائم» من المتصفح لحظة ضغط زر التنزيل بس (المقترح)؟ فايرفوكس هيظهر رسالة.
8. نضيف زر «تطبيق التحديث» في الإعدادات (المقترح)؟
9. نضيف سطر «مكوّنات برمجية مفتوحة المصدر» في «عن التطبيق» على الويب (المقترح)؟
10. كل النصوص الجديدة في `contracts/ui.md` مقترحات: تراجعها واحدة واحدة.
