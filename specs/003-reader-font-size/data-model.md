# Data Model: Text Size

## TextSize (pure value, `lib/settings/text_size.dart`)

| Field | Type | Rule |
|---|---|---|
| `percent` | int | one of 80, 90, 100, 110, 120, 130, 140, 150; default 100 |
| `factor` | double | `percent / 100` |

`TextSize.parse(String? raw)`: null, empty or not an integer → 100; an integer outside 80..150 → 100; an integer
inside the range → the nearest step (ties go to the lower step). Never throws (FR-014).

## Stored setting

| Where | Key | Value | Notes |
|---|---|---|---|
| `Settings` table (drift, key/value) | `textSizePercent` | decimal string of a step, e.g. `"120"` | absent = default; written on every change; exported and imported with the other settings (FR-013) |

No new table, no schema version change, no backup format change.

## TextSizeSettings (state)

`percent` (int step), `factor`, `isDefault`; `Future<void> load()`, `Future<void> set(int percent)` (snaps with
`TextSize.parse`, saves, notifies), `Future<void> reset()` (= set 100), `Future<void> reload()` (after a backup
import). Notifies listeners only when the value changes.

## PageBox (pure, `lib/mushaf/page_scale.dart`)

| Field | Meaning |
|---|---|
| `viewport` | the space the reader gives one page |
| `base` | today's box: viewport (portrait) or `min(w,600) x 1.75*min(w,600)` (landscape) |
| `scaled` | `base x factor` |
| `content` | `max(viewport, scaled)` on each axis: the pannable area |
| `fit` | `fits`, `scrollsVertically`, `pansBothWays` (spec FR-008) |
| `startOffset` | where a panned view starts: top, right side (`viewport.width - content.width`, 0) |

## Page view state (per page item, not stored)

`TransformationController` of its `InteractiveViewer`; `locked` = (fit is `pansBothWays`) or (zoom > 1.01). Lost
when the page scrolls out of the pager, which restarts it at `startOffset`.

## Not changed

Wird, portion, bookmark, reading position, page JSON, fonts, the page picture and the PDF.
