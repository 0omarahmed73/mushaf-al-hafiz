# Contract: Generated Quran assets

Produced by `python tool/build_quran_assets.py [--out assets] [--skip-fonts]`; consumed by
`MushafRepository` and `PageFontLoader`. Generated files are git-ignored and must be regenerated, never
hand-edited.

## Inputs (git-ignored, in `data-raw/`)

| File | Content used |
|---|---|
| `qul/x-layout-qpc-v2-15-lines.db/qpc-v2-15-lines.db` | table `pages(page_number, line_number, line_type, is_centered, first_word_id, last_word_id, surah_number)` |
| `qul/x-script-qpc-v2.json/qpc-v2.json` | map `"s:a:w" → {id, surah, ayah, word, location, text}` (`text` = QCF V2 glyph) |
| `qul/x-font-qpc-v2-woff2/p{1..604}.woff2` | per-page fonts |
| `quran-data.js` | Tanzil `QuranData.Sura`, `QuranData.Juz`, `QuranData.HizbQaurter` (regex parse only) |

## `assets/mushaf/pages/pNNN.json` (NNN = 001…604)

```json
{
  "page": 2,
  "juz": 1,
  "hizbQuarter": 1,
  "lines": [
    {"n": 1, "type": "surah_name", "centered": true, "surah": 2, "words": []},
    {"n": 2, "type": "basmallah", "centered": true, "surah": null, "words": []},
    {"n": 3, "type": "ayah", "centered": true, "surah": null,
     "words": [{"id": 37, "k": "2:1:1", "g": "<glyph>"}]}
  ]
}
```

## `assets/mushaf/meta.json`

```json
{
  "edition": "QCF V2 (1421H)",
  "pages": 604,
  "surahs": [{"n": 1, "name": "الفاتحة", "ayahs": 7, "startPage": 1}],
  "pageJuz": [1, 1, 1],
  "pageHizbQuarter": [1, 1, 1],
  "pageSurahs": [[1], [2], [2]],
  "ayahPage": {"1:1": 1, "2:255": 42}
}
```

(arrays shortened; real lengths: surahs 114, page arrays 604, ayahPage 6,236 keys)

- `surahs[].startPage` = page of the surah's **first ayah** (matches the printed index). In the 1421H print
  18 surah title lines sit at the bottom of the previous page (e.g. an-Nisa: title on p76, text from p77;
  startPage 77). `pageSurahs` lists every surah that has a title line or a word on the page, so p76 lists [3, 4].

## `assets/fonts/qpc-v2/p{N}.ttf`

TTF decompressed from the matching WOFF2; loaded as font family `qpc_p{N}`.

## Validation (build fails with `ValueError`, nothing written)

- 604 pages; pages 1–2 have 8 lines; every other page has 15.
- Word ids across all pages, in order, equal `1…83668`.
- 114 surahs; `surahs[17].startPage == 293`; `ayahPage` has 6,236 keys and `"2:255" == 42`.
- Page 1 line 1 is `surah_name` for surah 1; page 2 line 2 is `basmallah`; page 1 juz 1, page 604 juz 30.
- 240 hizb quarters parsed from Tanzil.

Successful run prints: `604 pages, 83668 words, 604 fonts`.
