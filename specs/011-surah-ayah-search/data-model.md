# Data Model: Surah and Ayah Search (feature 011)

**No stored data.** This feature adds no table, no column, no setting, no asset and nothing to the backup file. It reads the surah list of
`assets/mushaf/meta.json` (already loaded by the reader) and the 114 files `assets/ayah/text/NNN.json`, and it writes nothing. Everything below
lives in memory and is made again on every run. The reader's last viewed page is written when a result is chosen, exactly as the index writes it
(spec FR-015); no query, no result and no choice is stored, logged or backed up (FR-017).

## Query (the screen's own memory; never stored)

| Field | Meaning |
|---|---|
| `typed` | the text in the field, exactly as typed or pasted; never altered (FR-008); at least 1,500 characters accepted |
| `folded` | `ArabicFold.query(typed)`: letters, single spaces, the two seat markers (research D2) |
| `letters` | the number of characters of `folded` that are not a space |
| `generation` | an integer that grows with every change of the field; an answer is applied only if it is the current one (FR-023) |

Lives in a `TextEditingController` and a `SearchSession` owned by `SearchScreen`'s `State`; gone when the screen closes. Rotation and a trip
to the background keep them (FR-029). Rules: `letters == 0` is «nothing typed» (FR-009); `letters == 1` searches the surah names only; `letters >= 2`
searches both groups.

## Search form (derived, never shown)

For each stored word, `ArabicFold.word(word)`; for each ayah, the words' forms joined by one space (research D2). It exists only inside
`AyahIndex` and `SearchSession`'s matching and is never put on screen, in a share text, in the pages, the ayah menu or the PDF (FR-018).

## AyahIndex (in memory for the run; immutable once built)

| Field | Type | Rule |
|---|---|---|
| `chunks` | `List<String>`, 8 | chunk *c* = folded ayat `800c .. 800c+799`, each followed by `\n`; 413,093 characters in all (each ayah followed by a line break) |
| `ayahStart` | `Int32List`, 6,237 | offset of ayah *i* inside `chunks[i ~/ 800]`; the last entry closes the last chunk |
| `surahFirst` | `Int32List`, 115 | `surahFirst[s - 1]` = index of the first ayah of surah *s* (1..114); `surahFirst[114]` = 6,236 (the end), so 115 entries |
| `stored` | `List<String>`, 6,236 | ayah *i*'s stored words joined by `\n`, unchanged |
| `ayahCount` | 6,236 | |
| `estimatedBytes` | derived | `2 * 413,092 + 2 * sum(stored lengths) + tables`, about 2.6 MB; bounded in a test |

**Validation** (`AyahIndexBuilder.build(meta)`; run in `flutter test` over the real files and at every preparation): 114 surah files; per-surah
ayah counts equal `meta.surahs[s-1].ayahs`; 6,236 ayat; 77,432 words; no stored word folds to the empty string; for every ayah the folded text
equals its words' forms joined by one space; `ayahStart` is strictly increasing inside a chunk. A failure throws `SearchIndexError` and the service
goes to the `failed` phase (it never serves a partial index).

**Derived on demand, not stored**: the words of a row (`stored[i].split('\n')`), their folded forms and spans, the matched flags, the page
(`meta.pageOfAyah(surah, ayah)`, which equals the page of the ayah's first word for all 6,236 ayat: verified), the ref (`AyahRef` from
`surahFirst`).

## Service state (`SearchService`, one per run, provided to the app)

| Phase | Meaning | Moves to |
|---|---|---|
| `notStarted` | created at launch; nothing read | `preparing` on the first `prepare()` (search screen opened) |
| `preparing` | reading, decoding and folding the 114 files in slices | `ready`, or `failed` |
| `ready` | `AyahIndex` held for the rest of the run | stays |
| `failed` | an asset could not be read or the validation failed; `failure` holds the error | `preparing` on `retry()` |

`prepare()` while `preparing` or `ready` does nothing (a second opening shares the running work). The phase is a `Listenable`; listeners
(sessions) run their query again when it becomes `ready`. Nothing here is ever written.

## Search view (`SearchSession.view`, immutable, what the screen draws)

| Field | Meaning |
|---|---|
| `surahs` | `List<SurahInfo>` in row order (equal, starts with, contains, then number); at most 114; never cut |
| `ayah` | one of `AyahHint` (nothing typed), `AyahNeedsTwo` (one letter), `AyahPreparing`, `AyahFailed(error)`, `AyahSearching` (ready, the scan is under way and there is no earlier answer to keep: nothing is drawn), `AyahResults(total, hits)` |
| `AyahResults.total` | all ayat that match (the heading shows this, FR-014); may be 0 |
| `AyahResults.hits` | the first 100 in Mushaf order: `AyahHit(ref, page, words, matched)` |
| `AyahResults.tooMany` | `total > hits.length`: the line asking for more words is shown |
| `none` | derived: `letters >= 2`, `surahs` empty, and `ayah` is `AyahResults` with `total == 0` (one line says «لا توجد نتائج») |

`AyahHit`: `ref` (surah, ayah), `page` (where the ayah begins), `words` (the stored words, unchanged), `matched` (a flag per word). A row's snippet is
derived from these (research D6).

## AyahTarget (the value an ayah row hands back)

`AyahTarget(ref, page)`: the ayah and the page where it begins. A surah row hands back the surah's first page as an `int`, the index's own value.

## Found ayah (the reader's own state, in memory; cleared by a touch, a turn or an opened screen)

| Field | Meaning |
|---|---|
| `_highlightPage`, `_highlight` | the existing long-press highlight fields: the page and the ids of the ayah's words on it |
| `_reveal` | `PageReveal(wordIds, token)`: asks that page's `PageViewport` to bring the words into view once per token |
| cleared when | any pointer-down on the reader; a page change to another page; the long-press menu opens (it replaces it); a screen opens over the reader |

## Existing, unchanged

The surah list and names, the 114 text files, the 604 page files and fonts, `MushafMeta.pageOfAyah`, `ReaderController.jumpTo`, the position rules, the
look and text-size settings, the ayah menu and its share text.
