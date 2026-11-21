# Contract: Ayah assets and their build tool

Produced by `uv run python tool/build_ayah_assets.py [--out assets]`; read by `AyahRepository`. Generated
files are git-ignored (same policy as `assets/mushaf/`) and are rebuilt, never hand-edited. Every file is
UTF-8 JSON with no insignificant whitespace.

## Inputs (git-ignored, `data-raw/ayah/`; downloaded only after the owner's approval)

| File | Source | Used for |
|---|---|---|
| `qul-312/qpc-hafs-word-by-word.json` (from `qul-312-hafs-words.json.zip`) | QUL resource 312, «KFGQPC Hafs script – Word by word» | `text/` |
| `qul-24/ar-tafseer-al-saddi.json` (from `qul-24-tafsir-saadi-ar.json.zip`) | QUL tafsir 24, «Tafseer Al Saadi – Arabic» | `tafsir/` |
| `tanzil-en.sahih.txt` | tanzil.net/trans/en.sahih (`sura|aya|text`, then `#` comment lines) | `translation/` |
| `quranpedia-meanings.json.gz` | quranpedia.net/dumps | `gharib/` (books 327, 208 only) |
| existing `assets/mushaf/pages/*.json`, `data-raw/quran-uthmani.txt` | feature 001 | alignment and cross-check only |

The tool reads the two QUL files straight from their `.zip` (it needs no unpacked copy). Real shapes, measured on the downloaded files (the tool's readers are written test-first against small samples of them):

- QUL 312: a flat map `"s:a:w"` → `{id, surah:"2", ayah:"255", word:"3", location, text}`, 83,668 entries; the last word of each
  ayah is the numeral marker.
- QUL tafsir 24: a map `"s:a"` → `{"text": "<HTML>"}` for 6,177 ayahs and `{}` for 59; 205 ayahs repeat the previous ayah's text.
  The HTML is only `<span class=…>…</span>` and `<br>`.
- Tanzil: lines `sura|aya|text` for 6,236 ayahs, then a `#` comment footer (name, translator, language, id, last update 2011-04-24,
  «Source: Tanzil.net»); lines starting with `#` and blank lines are ignored.
- Quranpedia: `{license:{…, version:"2026-11-14"}, schema, data:[{surah, ayah, meanings:[{book_info:{id,name,author,…},
  words:[{text, meaning}]}]}]}`, 4,799 ayahs with entries.

## `assets/ayah/text/NNN.json` (NNN = 001…114)

```json
{"surah": 2, "ayahs": [["الٓمٓ"], ["ذَٰلِكَ", "ٱلْكِتَٰبُ", "…"]]}
```
`ayahs[i]` is the word list of ayah `i+1`, in order, without the end marker, copied unchanged from the source.

## `assets/ayah/tafsir/NNN.json`

```json
{"surah": 2, "entries": [{"from": 106, "to": 106, "text": "…"}, {"from": 108, "to": 108, "text": "…"}], "without": [107]}
```
Consecutive, non-overlapping, within the surah. Plain text; a source line break becomes `\n`. Ayahs with no text of their own
(59 in the whole Mushaf) are not covered by any entry; they are listed in `"without"` and resolve to the nearest earlier
entry at read time (`inherited`).

## `assets/ayah/translation/NNN.json`

```json
{"surah": 1, "ayahs": ["In the name of Allah, …", "…"]}
```

## `assets/ayah/gharib/NNN.json`

```json
{"surah": 2, "ayahs": {"255": [{"w": "القيوم", "m": "…", "b": 327}]}}
```
Only ayahs that have entries appear. `b` is a source id from `sources.json`.

## `assets/ayah/sources.json`

```json
{"sources": [{"id": "qul-312", "kind": "text", "title": "…", "provider": "QUL (Tarteel)", "link": "https://qul.tarteel.ai/…",
              "version": "2026-11-xx", "sha256": "…"},
             {"id": 327, "kind": "gharib", "title": "التبيان في تفسير غريب القرآن", "author": "ابن الهائم", "provider": "Quranpedia", …}]}
```
Written from the inputs' real names, versions and hashes; read by the labels and the About credits.

Assets change only when the tool is run again on deliberately replaced inputs; the app never updates them. `sources.json`
keeps every input's file name, version (or file date) and sha256, so a set of assets can always be traced to its downloads.

## Build checks (any failure prints the reason and exits non-zero before writing anything)

1. Text: the source's location set and ids equal the Mushaf pages' exactly (83,668); 114 surahs, 6,236 ayahs, 77,432 words;
   each ayah's last word is a numeral marker and is dropped, leaving positions `1..n-1`.
2. Cross-check: letters-only text equals Tanzil's Uthmani verse (after dropping the basmalah Tanzil prepends to ayah 1 of surahs
   2–8 and 10–114), except entries listed with a reason in `tool/ayah_text_known_differences.json` (expected: 2:72 only).
3. Tafsir: tags stripped, no empty text; identical consecutive texts merged; every ayah of a surah is covered by an entry or
   is in the pinned list `tool/tafsir_without_own_entry.json` (59 ayahs; a different set fails the build); no entry or
   inherited ayah crosses a surah boundary; an inherited ayah always has an earlier entry in its surah.
4. Translation: 6,236 non-empty lines (comment footer ignored).
5. Gharib: ayah exists, `b` whitelisted, `w` and `m` non-empty; prints the share of ayahs covered.
6. Prints raw and gzip size per kind and the total (SC-009: ≤ 40 MB).
