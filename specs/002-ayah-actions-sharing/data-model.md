# Data Model: Ayah Actions and Sharing

Nothing here is stored for the user: the feature adds **no database table and no setting**. All data is
read-only bundled assets (contracts/assets.md) or short-lived in-memory state. Names are Dart-side;
the spec's Key Entities map to them one to one.

## Read-only entities

### AyahRef
`(surah: 1..114, ayah: 1..surah.ayahs)`. Built from a pressed `MushafWord` (`word.surah`, `word.ayah`) or from
a surah/ayah pair. Value equality; `key` = `"s:a"`. The page of an ayah is `MushafMeta.pageOfAyah`.

### AyahWords (spec: Ayah, as text)
`words: List<String>` in order, the source's Unicode words without the end marker.
- `words.length` equals the Mushaf ayah's last word index minus 1 (checked for all 6,236).
- `text = words.join(' ')`; never trimmed, normalised or re-encoded.

### TafsirEntry (spec: Tafsir entry)
`from`, `to` (ayahs of one surah, `from <= to`), `text` (plain text, paragraphs separated by `\n\n`).
- Entries of a surah are consecutive and cover `1..ayahs` exactly once (no gap, no overlap).
- Lookup of an ayah = the entry with `from <= ayah <= to`. `covers` = `from..to`; the view shows the
  covers line only when `from != to`.
- 59 ayahs have no text of their own in the source (pinned in `tool/tafsir_without_own_entry.json`). For them the
  lookup returns the nearest earlier entry of the same surah with `inherited = true` (`TafsirResult(entry, inherited)`);
  the view then shows the «no commentary of its own» note above the text. A valid ayah always resolves.

### TafsirResult
`entry` (a `TafsirEntry`) and `inherited` (`bool`). `inherited` is true only for an ayah on the build's pinned list of ayahs
without commentary of their own, and then `entry` is the nearest earlier entry of that surah (spec FR-009a).

### TranslationEntry (spec: Translation entry)
`text` for one ayah (English, Saheeh International), non-empty for every ayah, stored unchanged.

### GharibEntry (spec: Difficult word)
`word` (a word or short phrase as the book gives it), `meaning` (Arabic prose), `book` (id of a source in
`sources.json`). An ayah has zero or more entries; zero is valid and means «no difficult words».
Entries keep the source's order. Only whitelisted books (327, 208) appear.

### Source
`id`, `kind` (`text|tafsir|translation|gharib`), `title`, `author`, `provider`, `link`, `version` (dump
date or download date), `sha256` of the input file. Read by the sheet (labels) and by About (credits).

## In-memory entities

### ShareText
A formatted string built by `ShareTextBuilder` from an `AyahRef` and the wanted part
(contracts/share-formats.md). Three forms: ayah, tafsir, translation. Pure; no I/O.

### PageRender (spec: Page picture)
`page` (1..604), `pixelRatio`, result = PNG bytes (picture, ratio 5) or an
`IndexedPage {width, height, palette, flateBytes}` (PDF page, ratio 4); both in the app's look (`PageLook.screen`). Never contains a highlight or any user data.

### SurahPdf (spec: Surah PDF) and PdfJob
`surah`, `firstPage = pageOfAyah(surah, 1)`, `lastPage = pageOfAyah(surah, ayahs)`, `pageCount = last - first + 1`
(Al-Baqarah 2..49 = 48; Al-Fatiha 1..1; Al-Ikhlas 604..604 with its neighbours' ayahs on the same pages),
`fileName` (contracts/share-formats.md).

`PdfJob.state` holds exactly one of `idle`, `preparing(done, total)`, `ready(file)` or `failed(kind)`; the state machine
(one job at a time, owned by the reader) is:

```text
idle ──start──▶ preparing(done, total) ──▶ ready(file)  ──share──▶ idle
                    │  ▲                       │
                    │  └─ resume after pause   └─ discard ──▶ idle
                    ├──cancel──▶ idle (file deleted)
                    └──error──▶ failed(kind) ──dismiss──▶ idle (file deleted)
```

- `start` while `preparing` is refused (FR-016: one at a time); from `ready` or `failed` it replaces the old result
  (the previous file is removed with the folder clean-up that precedes every job).
- Progress `done` counts finished pages; the strip shows «صفحة done+1 من total» while rendering page `done+1`.
- `ready` keeps the file path until shared or discarded; leaving `ready` never deletes a file the share sheet
  may still be reading (cleanup is at the next start, research D10).

### ShareOutcome / ShareFailure
`ShareOutcome`: `shared` or `dismissed` (a dismissal is silent). `ShareFailure.kind`: `noSpace`,
`couldNotPrepare`, `couldNotShare` → one Arabic message each (contracts/ui.md).

## Validation rules (where each is enforced)

| Rule | Enforced by |
|---|---|
| 6,236 ayahs, 77,432 words; positions `1..n-1` match the Mushaf; verse text = words joined | `tool/build_ayah_assets.py` (stops the build) |
| Letters-only text equals Tanzil's Uthmani text, except reviewed exceptions | tool (stops the build) |
| Tafsir entries consecutive and within one surah; every ayah is covered by an entry or listed in the pinned 59 | tool |
| Translation has 6,236 non-empty lines | tool |
| Gharib entries: existing ayah, whitelisted book, non-empty word and meaning | tool |
| Same word-count / position / shared-string checks over all 6,236 ayahs | `test/ayah/ayah_text_integrity_test.dart` |
| One PDF job at a time; cancel leaves no file | `test/pdf/pdf_job_test.dart` |
| PDF structure: header, object offsets, xref, page count, A4 MediaBox | `test/pdf/pdf_writer_test.dart` |
