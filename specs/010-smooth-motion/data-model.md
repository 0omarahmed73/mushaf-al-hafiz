# Data Model: Smooth Motion (feature 010)

**No stored data.** This feature adds no table, no column, no setting, no asset and nothing to the backup file; the reading
position, today's portions, bookmarks and the chosen look are written exactly as before (Stage C may delay the position write
by at most 0.4 s, research D5). Everything below lives in memory and is rebuilt on every start.

## Motion tokens (`lib/motion/motion.dart`)

Constants, no state. Values are in contracts/ui.md and are the only place a duration or a curve is written.

| Name | Meaning | Rule |
|---|---|---|
| `barIn`, `barOut` | the top and bottom bars appearing and leaving | 200 ms, 160 ms |
| `cardIn`, `cardOut` | the «ملخص اليوم» card | 220 ms, 160 ms |
| `jump` | a page arriving after a jump | 180 ms |
| `swap` | the bookmark icon and the wird name changing | 160 ms |
| `look` | the look cross-fade | 220 ms |
| `edgeTurn` | the edge turn of a wide page (unchanged from today) | 300 ms |
| `enter`, `exit` | curves | `easeOutCubic`, `easeInCubic` |
| `barSlide`, `cardSlide` | slide distances | 24 dp, 12 dp |

**Reduced form**: every duration above is `Duration.zero` while `MediaQuery.disableAnimationsOf(context)` is true.

## Reduce-motion setting (read-only, system)

Source: the phone's «remove animations» through `MediaQuery.disableAnimationsOf`. Never stored, never copied; read when each
motion starts, so a change while the app is open applies to the next motion (FR-014).

## Prepared neighbour (in memory only)

The next and the previous page with data (in `MushafRepository`'s cache of 8 pages), font (in `PageFontLoader`) and built
widgets (in the pager's cache extent). States: *not ready* (page-number card), *data ready*, *ready* (built). At most two exist
besides the shown page; they are dropped by the pager as it moves and by the repository's cache as it fills. `PAGEWARM`
reports `ready` at the start of a swipe (FR-002).

## Reader state that changes narrowly (in memory only)

| State | Owner today | Who rebuilds when it changes (after D3) |
|---|---|---|
| shown page, wird name, browse mode | `ReaderController` | the top bar's page-dependent parts |
| bars shown (portrait / landscape) | `_ReaderScreenState` | the two bar slots only |
| today list, panel open | `_ReaderScreenState` | the chip in the top bar and the card layer |
| per-page lock, highlight | `_ReaderScreenState` | the pager's physics, and the highlighted page's card |
| look, text size | providers | every card (they change the page), unchanged |

## Frame trace line (log only)

`FRAMETRACE refresh=<hz>` once; `FRAMETRACE build=<ms> raster=<ms> total=<ms>` per frame; `PAGEWARM next=<true|false>
prev=<true|false>` at each swipe start. Printed only when built with `--dart-define=FRAME_TRACE=true` (and
`PAGE_TURN_TRACE=true` for `PAGEWARM`); no file, no network.
