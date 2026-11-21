# Data Model: Khatm Dua After the Last Page (feature 005)

The feature stores nothing new: no table, no setting key, nothing in the backup. It has one bundled text and two
small in-memory objects.

## Dua text (bundled asset)

`assets/khatm/dua.txt`, UTF-8.

| Field | Rule |
|---|---|
| Content | The wording the owner confirmed (research D8). Paragraphs separated by exactly one blank line; no title, no markup, no numbering; one final newline. |
| Size | A few KB (4,479 bytes for the wording the owner confirmed on 2026-11-21), under 16 KB. Constitution VIII (app size) is not affected. |
| Integrity | `DuaText.parse` splits at blank lines and removes the final newline only. The paragraphs joined by a blank line equal the file's text (FR-015, SC-006). |
| Only one | The file is the app's only dua. No list, no second file, no key per dua (Constitution III, FR-015). |

## DuaText (in memory)

| Field | Type | Rule |
|---|---|---|
| `paragraphs` | list of text | at least one paragraph, none empty; set once, never edited |

`DuaText.load(AssetBundle)` throws `DuaUnavailable` when the asset is missing, unreadable or empty after parsing
(FR-019).

## LastPageSwipe (in memory, one per reader)

| Field | Type | Rule |
|---|---|---|
| forward distance | number, ≥ 0 | sum of positive overscroll of the gesture being tracked; reset by `start()` and by `end()` |
| constants | `minDistance` 48, `minFlingDistance` 16, `minFlingVelocity` 300 | logical pixels and pixels per second; tuned in the phone check (research D2) |

State transitions: `start()` → distance 0 → `overscroll(d)` any number of times → `end(velocity)` → opens or not →
distance 0. `end()` without `start()` is allowed and answers from the distance so far (0 after a reset).

## Reader state added

| Field | Type | Rule |
|---|---|---|
| `_duaOpen` | bool | true from just before the dua route is pushed until it returns; while true no gesture opens another (FR-003). Not stored; a restart starts false. |

## Existing data this feature reads or changes

- **Reading position** (`ReaderController.onPageShown`, `WirdRepository.setPage`, `setLastViewedPage`): changed only
  by «آمين» through the ordinary page change (FR-006). Back changes nothing.
- **Wirds' khatma count, portions, done marks, bookmarks, reminders, settings**: never read, never written (FR-008).
