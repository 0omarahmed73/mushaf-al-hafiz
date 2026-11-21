# Research: Ayah Actions and Sharing (feature 002)

Date: 2026-11-20. Every source below was read on its own site (quotes are short and attributed);
nothing has been downloaded into the project yet. Numbers marked **measured** come from a throwaway
probe run in `flutter test` on the development machine (not on the phone); numbers marked **estimate**
are replaced by real ones when the assets are built.

## Decisions at a glance

| # | Topic | Decision |
|---|---|---|
| D1 | Exact text of an ayah | Unicode words from QUL «KFGQPC Hafs – word by word» (resource 312), word-aligned with the Mushaf keys `s:a:w`; stored per surah as word lists. Cross-checked per ayah against Tanzil's Uthmani text already in the repo. |
| D2 | Tafsir al-Sa'di | QUL tafsir resource 24 «Tafseer Al Saadi – Arabic» (JSON, ayah-range groups). Alternative for the owner: Quranpedia book 3 (full bibliographic record, but its per-ayah format is not confirmed). |
| D3 | English translation | Tanzil `en.sahih` («Saheeh International»), plain text `sura|aya|text`. |
| D4 | Gharib word meanings | Quranpedia `meanings.json.gz`, **restricted to the two classical books** (Ibn al-Hā'im «التبيان في تفسير غريب القرآن», Ibn al-Jawzī «تذكرة الأريب في تفسير الغريب»). Word/phrase + meaning per ayah, no word index. |
| D5 | Data packaging | Per-surah JSON assets, one folder per kind (text, tafsir, translation, gharib); lazy load with a small cache; heavy decode off the UI isolate. About 3 MB compressed (estimate). |
| D6 | Page picture | One shared offscreen renderer of the real Mushaf page widget; PNG at 2000×3000 px; the look is the app's. |
| D7 | Surah PDF | **Raster pages in a hand-written PDF writer, no new package**: the same renderer in the app's own look (amended 2026-11-20: it was a gray print look), 256-colour indexed Flate on a green A4 sheet, 1600×2400 px (≈ 220 ppi). Budget 60 s and 40 MB for Al-Baqarah (see the amendment in D7). |
| D8 | Long press | The existing per-word `onLongPress` inside the pager's gesture arena; highlight by ayah key; one modal sheet. |
| D9 | Sheet UI | One modal bottom sheet with an internal menu → detail navigation; the translation is an LTR panel inside an RTL sheet. |
| D10 | Sharing | `ShareService` over `share_plus` (already a dependency); temp files in a dedicated folder, cleaned at the next start; cancel is not an error. |

**Needs the owner's approval before implementation** (nothing is downloaded or bundled until then):
the four downloads in D1–D4 (file, source, size in the table at the end), the tafsir source choice
(D2), the restriction of the gharib data to the two classical books (D4), and the licence readings in
`docs/research/licenses.md`. No new Dart package is required.

---

## D1. Exact Quran text of an ayah (Constitution I; spec FR-007, FR-008, SC-003)

**Facts established locally (measured on `assets/mushaf/pages`):**

- 6,236 ayahs, 83,668 words in the pages; every ayah's word keys are contiguous `1..n`; the last word
  of each ayah is the end-of-ayah marker, so the Mushaf has 77,432 Quranic words + 6,236 markers.
- **0 of 6,236 ayahs are split across two pages** (the Madinah Mushaf ends every page at an ayah
  end). FR-002's «part on the current page» rule is therefore never needed on real data; it stays
  as a safe rule and is tested with synthetic data.
- The `g` field of a word is a QCF V2 glyph code (Private Use Area), not Unicode text; it cannot be
  shared as text.
- `data-raw/quran-uthmani.txt` (Tanzil, CC BY 3.0, «changing the text is not allowed») is Unicode but is
  not word-aligned to the Mushaf (its word splitting differs), so it cannot prove word-for-word equality.

**Decision.** Use QUL resource 312, «KFGQPC Hafs script – Word by word»: «Hafs Quran script in word by word
format from King Fahad Glorious Quran Printing complex.» **The downloaded file** (`qpc-hafs-word-by-word.json`, 8.8 MB, zip 1.47 MB) is a flat map `"s:a:w"` →
`{id, surah, ayah, word, location, text}` of **83,668 entries whose locations and `id`s are identical to the
Mushaf's 83,668 words** (measured: same key set, 0 id differences). The end-of-ayah marker is an entry too (its text is
a numeral such as «١٠٥»; true for all 6,236 ayahs), so the Quranic words are the 77,432 entries before it.
A few word texts carry the hizb sign «۞» (199) or the sajda sign «۩» (15) inside the word, exactly as the Mushaf shows them.
It is the same provider and the same King Fahd Complex origin as the QCF V2 layout and fonts the app
already uses. Licence: the resource page says «We don't have copyright information for this resource.» (same
status already accepted for the QCF assets, see `docs/research/licenses.md`).
Stored text is the source's words, unchanged, per surah (see contracts/assets.md).

**The automated check (SC-003, FR-008), in two layers:**

1. *Build time, stops the build* (`tool/build_ayah_assets.py`): the source's location set and `id`s equal the Mushaf
   pages' exactly (83,668); for every ayah the last word is the numeral marker and is dropped, leaving positions
   `1..n-1`; totals are 6,236 ayahs and 77,432 words. Stored words are the source's `text` unchanged.
2. *Independent cross-check, stops the build*: per ayah, the letters-only form of our text (all marks,
   tatweel and presentation variants removed, alef forms unified) equals the same form of Tanzil's
   Uthmani verse, after dropping the basmalah that Tanzil's file puts in front of the first ayah of surahs 2–8 and
   10–114. **Measured: 6,235 of 6,236 ayahs match; one differs, 2:72** (QUL writes the hamza as the letter «ء», Tanzil as a
   combining mark). That one is listed with its reason in `tool/ayah_text_known_differences.json`; any other
   difference fails the build.
3. *In `flutter test`* (`ayah_text_integrity_test.dart`): for all 6,236 ayahs, the words the repository returns have
   the same count and positions as the Mushaf page assets minus the marker; the shared string is
   exactly `﴿ <words joined by one space> ﴾` and a reference line (nothing else).

*Honest limit:* glyph-by-glyph equality of a QCF V2 word and a Unicode word cannot be proven by data
alone (different encodings); the proof is word identity (same location keys, same count, same order)
plus the independent letter-level check, plus the owner's by-hand comparison of 10 ayahs (SC-002).

**Alternatives.** (a) Tanzil text split into words: rejected, no alignment. (b) Mapping QCF glyph codes to
letters: rejected, glyphs are shaped forms with no reliable inverse. (c) QUL Uthmani-simple text: rejected,
a different script than the Mushaf's.

## D2. Tafsir al-Sa'di (spec FR-009, FR-013, FR-020)

| | QUL tafsir 24 «Tafseer Al Saadi – Arabic» | Quranpedia book 3 «تيسير الكريم الرحمن» |
|---|---|---|
| Format | JSON / SQLite; `{"2:3": {"text", "ayah_keys": ["2:3","2:4"]}, "2:4": "2:3"}`; the text may contain `<b>`/`<i>` | `tafsir-book-3.json.gz`, 4,053,629 bytes; its per-ayah API call returned only the verse text for 2:255, so the commentary layout is not confirmed |
| Grouping | **Measured on the file: not as documented.** 6,236 keys, each `{"text": <HTML>}`; 205 ayahs repeat the previous ayah's text (a group), 59 ayahs have an empty `{}` | Not confirmed |
| Source named | No author or edition on the page | Yes: author السعدي (id 3444), edition «الأولى 1420هـ - 2000م», publisher مؤسسة الرسالة, verifier عبد الرحمن بن معلا اللويحق |
| Licence text | «We don't have copyright information for this resource.» | Quranpedia LICENSE (version 2026-11-20): classical works are «shared heritage» (تراث مشترك للأمة); the team owns the digitisation; free to use in apps, no attribution required (a link is appreciated); republishing as a dataset needs a credit and the dump version |
| Size | **measured: 7.0 MB JSON (zip 1.7 MB)**, 3.27 M characters of text | 3.9 MB gz |

**Decision.** QUL 24: the data shape matches the feature (ayah groups, one entry for several ayahs)
and the provider and status are the ones the owner already accepted for the QCF assets. Its weakness
is traceability: the page names no edition. **Risk R2** (owner decides): Sa'di died in 1376H (1956); that
the text is free of rights is the owner's judgement, not a legal opinion; the Quranpedia copy is the
Resalah 1420H edition with a verifier's work, whose rights its LICENSE does not cover. Both routes
stay inside what the owner already accepted (a private, non-commercial APK) but neither is a stated
permission to bundle; QUL is simpler to use. If the owner prefers Quranpedia, the first task reads its
real format before anything else.

*What the real file contains (measured).* HTML only of the kinds `<span class=…>` (quoted Quran text in `{ … }`, remarks
and colours) and `<br>` (167); no group pointers or `ayah_keys`. 205 ayahs carry the same text as the ayah before them and
are merged into one entry with a range (the «يشمل التفسير الآيات…» line). **59 ayahs have no text at all**
(for example 2:107, 2:286, 109:4; the full list is pinned in `tool/tafsir_without_own_entry.json`). For these the
view shows the nearest earlier entry of the same surah, with a note that this ayah has no commentary of its own in
this text (a new proposed string, see contracts/ui.md); so no ayah shows «not found» (spec FR-013, AS 2.4) and nothing
is invented. The owner may prefer another treatment; it only changes that note.

*Build rules:* tags stripped to plain text (`<br>` becomes a line break, spans keep their text and the `{ }` quote marks);
identical consecutive texts merged into one range; every ayah of each surah covered by an entry or listed in the pinned
list; a merged range or an inherited ayah never crosses a surah boundary (checked: none do).

## D3. English translation, Saheeh International (FR-010, FR-013, FR-020)

Source: `https://tanzil.net/trans/en.sahih` (plain text `sura|aya|text`; Browse and Changelog pages exist;
translator column «Saheeh International», biography link saheehinternational.com).
Tanzil's terms for translations (tanzil.net/trans/): «for non-commercial purposes only», otherwise permission
is needed «from the translator or the publisher»; a link back to tanzil.net/trans/ is required only for
more than three translations in an application (we use one, we credit and link anyway); «We cannot
guarantee their authenticity and/or accuracy.»; no named licence, no modification rule is stated.
Our use (private, non-commercial APK, shown unchanged, credited) fits those terms. **Risk R3**: the
translation is the copyrighted work of Saheeh International; Tanzil's page gives its own non-commercial
terms but not the translator's; the owner approves relying on them.
We read the first ~40,000 characters of the file; the rest is read by the build tool, which also checks
for any licence or credit text inside it and shows it to the owner.

*Build rules:* exactly 6,236 lines, one per ayah, non-empty; text stored unchanged (no HTML).

## D4. Gharib (difficult words) meanings (FR-011, spec Assumptions)

**What exists and how it was checked.** Quranpedia publishes `meanings.json.gz` (748,521 bytes = 731 KB,
sha256 `b46ca5ae…d0699`, built 2026-11-14; manifest version 2026-11-16, LICENSE 2026-11-20). Its public API
returns the same data per ayah (read for 2:255, 2:10, 1:7): a JSON array with one record per source book, each
with `book_info` and `words: [{text, meaning}]`.

- **Granularity.** *Word-or-phrase level inside an ayah*: `text` is a word or a short phrase as the book
  gives it (for example «القيوم»; «لا تأخذه سنة ونوم»), `meaning` is Arabic prose. There is **no word index**:
  an entry is tied to the ayah, not to a position in it. This is enough for FR-011 (list difficult
  words with meanings and source); it is not enough to colour a word on the page (not required).
- **Books** seen for 2:255: ids 491 «السراج في بيان غريب القرآن» (محمد الخضيري, contemporary),
  327 «التبيان في تفسير غريب القرآن» (ابن الهائم, d. 815H), 208 «تذكرة الأريب في تفسير الغريب» (ابن الجوزي,
  d. 597H), 1424 «كلمات القرآن» (حسنين مخلوف, d. 1990). 1:7 has 491, 327, 1424.
- **Licence** (LICENSE.md, quoted briefly): «Free to use inside apps, websites, bots, and research tools —
  no attribution required (a visible link to https://quranpedia.net is appreciated).»; republishing as a
  downloadable dataset requires crediting Quranpedia.net with a link and stating the dump version; «Translations and
  contemporary works remain owned by their authors and publishers»; classical works are shared heritage;
  «Provided as-is, without warranty»; the content is continuously corrected. Third-party sections
  (morphology GPL, syntax MIT) are not used.

**Decision.** Use only records of the two **classical** books, 327 and 208, so that every shown meaning
is from a work whose author died centuries ago and whose rights Quranpedia's LICENSE does not hand to a
modern owner. The contemporary books (491, 1424) are left out on purpose. Each entry shows its book
and author. We credit Quranpedia with a link and the dump version used, in About and in
`docs/research/licenses.md`, even though an app does not require it.

*Coverage is not 100% by design:* an ayah with no difficult word has no entry and the sheet says
«لا توجد كلمات غريبة في هذه الآية». **Measured on the downloaded file** (dump `license.version` 2026-11-14, 4,799 ayahs with any
entry): book 327 covers 1,955 ayahs (2,746 entries), book 208 covers 3,167 (5,491), together **3,689 of 6,236 ayahs
(59%)**; the two contemporary books would raise that to 4,799 (77%) (491: 3,644 ayahs, 1424: 3,628). So about 4 ayahs in 10 will say
«لا توجد كلمات غريبة في هذه الآية». The owner approved the classical-only choice before this number was known; adding
book 491 or 1424 later is a one-line whitelist change plus the rights question above, and is the owner's call.
The build checks that every entry names an existing ayah and a whitelisted book and prints the coverage.

**Risk R4**: the entry text is as printed in the old books (their wording, not modern Arabic);
the dump is «continuously corrected», so the build records the dump version and sha256 it used.
**Alternatives rejected:** QUL word-by-word translation resources (English or other languages, not Arabic gharib); Quran.com word
data (translation, not gharib); modern contemporary gharib books (rights stay with their authors).
**If the owner dislikes D4**, the fallback is ayah-level notes from the same two books shown as one text; the data
already is that shape, so no change of design is needed.

## D5. Data packaging and size (FR-013, SC-009, Constitution VIII)

**Options.** (a) One SQLite asset (copied to the phone on first run: the data is stored twice and the
open takes work), (b) compressed shards with a custom reader, (c) **per-surah JSON assets** read through
`rootBundle`, the same pattern as `assets/mushaf/pages`.

**Decision (c).** 114 files per kind × 4 kinds (text, tafsir, translation, gharib). A lookup loads one
surah file of one kind and keeps the last 3 per kind (Al-Baqarah's files are the largest). Files over
~50 KB are decoded with `compute` so the reader never stutters; the APK already deflates assets.
**Measured with the real inputs** (`tool/build_ayah_assets.py`, 2026-11-20; raw JSON / gzip): text 1.43 / 0.33 MB, tafsir 5.63 / 1.65 MB,
translation 0.84 / 0.32 MB, gharib 1.04 / 0.34 MB, **total 8.95 MB raw and 2.64 MB gzip**, far below the 40 MB limit (SC-009; the APK deflates
assets about like gzip). The tafsir has 5,972 entries covering 6,177 ayahs (205 merged into ranges) and 59 ayahs without text of their own.
Generated assets are git-ignored like `assets/mushaf/`, rebuilt by the tool.

## D6. The page picture (FR-014, SC-004)

**Decision.** `MushafPageCard`, extracted from `_PageItem` (ring, ivory paper, gold frame, page text), is the single widget
for the reader, the picture and the print pages; it takes a `PageLook` (screen / print). `PageRenderer`
paints it into a `RepaintBoundary` of a fixed logical size 400×600 (the Mushaf's own 1:1.5 proportion;
line height is then limited by the width, as in the app) and reads it with `toImage(pixelRatio: 5)` =
**2000×3000 px**, encoded to PNG by the engine (no package). Ratio 5 and not 4 because SC-004 asks for sharpness at 2× zoom: on the
owner's 1080-px-wide screen a 1600-px picture would be upscaled about 1.35× at 2× (soft), a 2000-px one about 1.08×. The PDF pages stay
1600×2400 (see D7). The page fonts come from `PageFontLoader.ensure`;
the picture is green around the ring (the app's background), no highlight, no bars; the page number is drawn
in Cairo.

**Measured** (dev machine, `flutter test`, throwaway probe): render + read 70–140 ms per page at 1600–2000 px;
PNG of a dense page 750 KB at 1600 px (≈1 MB at 2000 px). The picture of page 293 was opened and the text, banner and
frame were sharp. The phone is checked on a real device (SC-004: < 3 s).

**On the phone (Samsung, release build, 2026-11-20).** Page 14: 785 ms with 675 ms of rendering, page 16: 508–590 ms (render 494–573 ms,
PNG of about 1.1–1.3 MB), all far inside the 3 s of SC-004. Pages 1, 2, 293 and 604 were not timed individually on the phone yet.

**Colour fidelity (owner feedback 2026-11-20, SC-010).** The first build's picture was striped and faded. Cause: the offscreen overlay had no `Material`
above the page, so `MaterialApp`'s fallback `DefaultTextStyle` (red, monospace, extra-bold, **yellow double underline**; it is used in release
builds too) leaked into every word; the underline made the letters look hollow. Fix: the page is drawn on a transparent `Material`
(T049), with a renderer test that finds no yellow and checks the ring, frame, banner, paper and ink colours. Checked on the phone with a trace
build that keeps a copy of the picture: the picture pulled from the phone has exactly the app's colours (corner `0E3B30`, paper `FBF5E3`,
frame `B8923A`, ring `5E7F6F`) and looks like the page in the reader.

**Offscreen mechanics (decided in T031).** `RenderObjectToWidgetAdapter`, the usual way to build a detached render tree, no longer exists
in Flutter 3.50 (its replacement needs a real `FlutterView`), so the renderer uses the planned fallback: a short-lived `Overlay` entry placed far to
the left of the screen, wrapped in a `RepaintBoundary`, read with `toImage`, then removed. It works with public APIs, inherits the theme, switches the
system text scale off, and leaves nothing in the tree (tests: 2000×3000 PNGs of pages 1, 2, 293 and 604, screen and print looks, font failure).
Because it needs frames, a job in the background waits until the app is shown again (risk R6).

## D7. Surah PDF (FR-015, FR-016, SC-005)

| Option | Quality | Size (48 pages) | Cost / risk |
|---|---|---|---|
| (a) Vector with the `pdf` package (3.13.1, Apache-2.0, pure Dart, 160/160 pub points) and the per-page QCF TTFs | best: crisp at any zoom | ≈ 1–3 MB (estimate) | new dependency (owner approval); a **second layout engine** (justified lines, banners) that can drift from the Mushaf page; Arabic shaping needed for the surah title and the basmallah line; embedding 48 PUA-glyph fonts and PdfGraphics.drawString not verified |
| (b) **Raster pages written by our own small PDF writer** | sharp at print and normal zoom (1600 px over ≈ 185 mm ≈ 220 dpi) | **≈ 15 MB** (measured below) | none: no dependency, the pages are the same render as the picture, so the look cannot drift |
| (c) Vector page content plus raster only for banners | best of both | small | two code paths; most work |

**Decision (b)** (the gray print look in this paragraph was replaced on 2026-11-20: see the amendment below). The PDF is the print look of the same `MushafPageCard`, rendered at 1600×2400 px, converted
to 8-bit gray (white paper, black text, thin black frames and banner outlines, FR-015), deflated, and written as
image XObjects on A4 portrait sheets (595.28 × 841.89 pt) with the page centred and scaled to fit with even
margins. About 150 lines of Dart; structure and offsets are unit-tested and the file is opened in a standard viewer on the
phone.

**Measured** (dev machine; dense page 293 / lighter pages 2 and 604, 1600×2400, gray 8-bit):
Flate 315 KB / 106 KB / 188 KB, 65 / 39 / 47 ms to compress; at 2000×3000 up to 414 KB.
48 dense pages ≈ 15 MB at 1600 px (≈ 20 MB at 2000 px), render + compress ≈ 0.16 s per page ≈ 8 s total
(SC-005 allows 60 s and 40 MB). Packing gray to 4 bits cuts it to about 60% of that if ever needed.

**Responsiveness and cancel.** One page at a time: render (async on the raster thread) → read RGBA → convert to gray and
deflate inside `Isolate.run` → write to a temporary file; a `CancelToken` is checked between every step (a step
is about 0.2 s, far inside the 2 s limit); cancel or failure deletes the partial file. The state is a small
`ChangeNotifier` read by a **non-modal** progress strip above the bottom bar («صفحة 12 من 48» + «إلغاء»), so the reader
stays usable; only one job runs. When the job ends in the foreground the share sheet opens by itself; if the app
was in the background the strip offers «مشاركة». If Android kills the process, the partial file is removed at the next
start (no half-finished file is ever offered).

**Decision gate.** If the phone check shows the print quality is not good enough when zoomed, the next step is
option (a) as a separate approved change (needs the dependency approval); raising `pixelRatio` to 5 (≈ 20 MB) comes first.

**Amendment, 2026-11-20 (owner, after the first phone build).** The first build produced the gray print look. On the phone
(Samsung, release build, `AYAH_MENU_TRACE`) Al-Baqarah took **13.6 s and 16.2 MB** for 48 pages, and a page picture took 0.5–0.8 s
(page 14: 785 ms with 675 ms of rendering; page 16: 508–530 ms). The owner then asked for a PDF in colour, like the app («beautiful
and cheerful»), which replaces the print-look decision above (spec FR-015 amended; `PageLook.print`, `GrayPage` and `gray_flate`
are retired). Full RGB is too big, so the sheet is the app's green drawn as a vector rectangle and the page image is
reduced to a 256-colour palette (the page uses a handful of base colours plus the anti-aliasing blends between them, so 256
entries are almost lossless).

Size of one dense page at 1600×2400 before implementing (Pillow on the 2000×3000 picture of page 14 / 293, zlib level 6):
gray 649 / 668 KB, **full RGB 1.50 / 1.51 MB (about 72 MB for 48 pages: over the 40 MB budget)**, 256-colour indexed 360–640 KB
depending on the quantiser (about 17–31 MB). Result of the implementation:

**Implemented (T050, T051): colour PDF, results.** Weighted median cut over the page's distinct colours, the dominant colour of each group kept
exact. Per page at 1600×2400 (dev machine, pages 1, 2, 14, 293, 604): **96–301 KB** of Flate indices, mean colour error 0.01 of 255, worst pixel 26,
about 120–170 ms to reduce and deflate (in an isolate). Al-Baqarah, 48 pages: **dev machine 13.7 s and 14.8 MB**; **phone 10.2 s and 15.1 MB**
(the gray first build took 13.6 s and 16.2 MB), so both budgets of SC-005 hold with a wide margin and the pixel ratio stays 4 (≈ 220 ppi). The file
opens in `pdfinfo` (title, 48 pages, A4, no metadata, no JavaScript) and `pdftoppm` draws the green sheet, ivory page and gold frame.
On the phone: the strip showed «صفحة 19 من 48» while the reader stayed usable, the share sheet opened by itself when the job ended, a second
start was refused (the row said «يتم تجهيز ملف الآن»), and «إلغاء» stopped the job within 1.5 s with no file finished. Second phone run (2026-11-20, 22:48–22:53, same trace build): page pictures 351 ms (page 1) and 339 ms (page 2); PDFs Al-Fatiha 1 page 160 ms and 98,516 bytes, Al-Baqarah 48 pages **9.0 s and 15,127,100 bytes**, Al-Kahf 12 pages 2.6–2.9 s and 3,966,418 bytes; the Al-Fatiha file showed in WhatsApp as «1 page · 99 kB». **Not yet checked on the phone:** page 293 and 604 pictures, Al-Ikhlas, a locked screen during a job, the PDF in a viewer and print preview (the owner's eye, T053). Someone else was also touching the phone during this run (PDF jobs and share targets I did not start), so the owner finished the rest by hand.
**Decision gate:** pixel ratio 4 with a 256-colour palette is enough; neither a ratio of 5 nor a vector PDF is needed.

## D8. Long press (FR-001, FR-002, FR-004, FR-006, SC-001)

`MushafPage` already wraps every word in a `GestureDetector(onLongPress)`, and the page sits inside
`GestureDetector(onTap)` → `InteractiveViewer` → `PageView`. In the gesture arena a long press is accepted only
after the finger rests for 500 ms within the touch slop; a swipe (horizontal drag), a pan or a pinch claims the arena
first, and the tap loses when the long press wins. So no change to swipe, zoom or tap is needed, only wiring:
`_PageItem` gets `onWordLongPress` and `highlightedWordIds`.

- *Which ayah.* The pressed word's `surah`/`ayah`; the highlighted ids are all words (including the marker) of
  that ayah in the shown `PageData` (pure function, unit-tested; empty ayah on page → nothing).
- *What does not open it.* Banner, basmallah (not words), empty areas, page number, bars and the loading state have
  no word handler, so nothing happens (FR-004). Al-Fatiha's basmallah is ayah 1:1 and opens its menu.
- *Feel.* `HapticFeedback.mediumImpact()` when the sheet opens; the highlight appears in the same frame.
- *One sheet.* The sheet is modal, so a second long press cannot arrive; the reader also ignores a press while one is open.
- *Checks.* Widget tests: long press opens, tap toggles bars, drag/fling never opens, two-finger zoom never opens,
  a long press on the banner does nothing; on the phone: 50 mixed gestures (SC-001).

## D9. Sheet UI (FR-003, FR-005, FR-009, FR-010, FR-010a, FR-012)

One `showModalBottomSheet` (scroll-controlled, rounded top, the bookmarks sheet's look: green sheet, ivory cards).
Header «سورة البقرة · آية 255» in Reem Kufi. The menu has two groups: the ayah (مشاركة، التفسير، الترجمة، معاني الكلمات) and the
Mushaf (مشاركة الصفحة كصورة، مشاركة السورة PDF), rows at least 48 px high. Tafsir, translation and meanings open **inside
the same sheet** with a back arrow (system back returns to the menu), so the sheet count stays one. Each detail view is
an ivory panel labelled with its source as a human work and sets the Quran text apart (the Quran text is not repeated
inside it); tafsir and translation have a share button in the header. The English text is in an LTR `Directionality`; the
labels around it stay RTL. Long tafsir scrolls inside the panel. Exact strings are in contracts/ui.md.

## D10. Sharing mechanics (FR-007, FR-010a, FR-018, SC-007)

`ShareService` (interface) with `PlatformShareService` over `SharePlus.instance.share(ShareParams(...))`, the call the
backup export already uses. Text shares use the formats in contracts/share-formats.md. Files are written to
`<temp>/share/<Arabic name>` (the folder the backup export pattern uses via `path_provider`), never deleted right after the
share call (the receiving app may still be reading), and cleaned when the app starts and before a new job.
Outcomes: shared / dismissed (no message). Failures: not enough space (`FileSystemException` with the no-space
error) → «لا توجد مساحة كافية على الهاتف»; any other write or render failure → «تعذّر تجهيز الملف»; the share call failing →
«تعذّرت المشاركة». The reader keeps working in every case.

---

## Resources to download (needs the owner's approval; each file named, with its source and size)

| # | File (will be saved in the git-ignored `data-raw/ayah/`) | Source | Size | Feeds |
|---|---|---|---|---|
| 1 | QUL «KFGQPC Hafs script – Word by word», JSON | qul.tarteel.ai/resources/translation/312 | not shown on the page; estimate 5–10 MB | D1 text |
| 2 | QUL «Tafseer Al Saadi – Arabic», JSON | qul.tarteel.ai/resources/tafsir/24 | not shown; estimate 3–5 MB | D2 tafsir |
| 3 | Tanzil `en.sahih`, text | tanzil.net/trans/en.sahih | ≈ 0.9 MB (≈ 898 k characters) | D3 translation |
| 4 | Quranpedia `meanings.json.gz` | quranpedia.net/dumps | 748,521 bytes, sha256 `b46ca5ae…d0699` | D4 gharib |

(If the owner chooses Quranpedia for the tafsir instead: `tafsir-book-3.json.gz`, 4,053,629 bytes, in place of #2.)
No new Dart package is needed: `share_plus`, `path_provider`, `provider` are already dependencies.

## Risks and open items

- **R1** The licence of QUL resources 312 and 24 is «no copyright information». Same status the owner already accepted for the
  QCF assets; extending it to these two is the owner's call.
- **R2** Tafsir source traceability (D2). **R3** The translator's own rights (D3). **R4** Old-book wording and a moving dump (D4).
- **R5** The detached render tree may not compile on Flutter 3.50; the overlay fallback exists (D6).
- **R6** A PDF job in the background: frames may stop; the job resumes or the file is discarded, never half-offered (D7).
- **R7** `reader_screen.dart` was being edited by the polish session; it committed (588381a) on 2026-11-20, so the long-press wiring can start from a clean tree.
