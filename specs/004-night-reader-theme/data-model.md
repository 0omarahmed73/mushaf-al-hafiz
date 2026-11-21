# Data Model: Night Reader Look

No table or column is added. One new row in the existing `Settings` key/value table, and a set of constant look
definitions in code.

## Look setting (stored)

| Field | Type | Rule |
|---|---|---|
| key | `appLook` (string) | one row in `Settings` |
| value | `emerald` or `night` | anything else, a missing row or an empty string is read as `emerald` (FR-016) |

`LookChoice` is the pure enum `{ emerald, night }` with `LookChoice.parse(String?)` (lenient, never throws) and
`name` for storing. The default is `emerald`. The value is exported and imported with the other settings (the backup
format is unchanged: every settings row is a string).

State: `AppLookSettings` holds the current `LookChoice` in memory; `load()` reads it once at start, `set(choice)`
saves and notifies (only on a real change), `reload()` re-reads after a backup import.

## AppLook (constant, per look)

The semantic tokens every screen reads through `context.look`. The Emerald column is exactly today's value (the
existing `AppColors` constant or literal), so Emerald does not change. The Night column comes from the design canvas
(direction B), with the two lifts of research D7 marked ▲.

### Colours

| Token | Emerald (today) | Night | Used for |
|---|---|---|---|
| `background` | `green` `#0E3B30` | `#0D1014` | scaffold, app bar, bottom sheets, dialogs, picture/PDF sheet |
| `barFill` | `greenDeep` `#0A2D25` | `#161B22` | reader bottom bar, About cards on the page |
| `barBorder` | `greenLine` `#1E5646` | `#232A33` | the bar's border |
| `line` | `greenLine` `#1E5646` | `#2B343D` | dividers, slider tracks, tab divider, sheet handle |
| `heading` | `gold` `#E4C877` | `#ECE7DC` | screen titles, sheet titles (`headingStyle`) |
| `accent` | `gold` `#E4C877` | `#6CC4B5` | icons, selected states, links, accent text, the page's surah title |
| `accentAlt` | `goldDark` `#B8923A` | `#E3B05A` | progress bars, emblem details, second accent |
| `text` | `ivory` `#F3EBCB` | `#ECE7DC` | body text on the background |
| `textSecondary` | `muted` `#E8DDB5` | `#9AA4AD` | captions, notes, subtitles on the background |
| `textDim` | `muted` at 75% | `#85909B` ▲ (design `#6E7983` = 4.29:1) | page number, quiet lines |
| `cardFill` | `paper` `#FBF5E3` | `#161B22` | cards, ayah-menu rows, today panel, wird cards, reading panels |
| `cardInk` | `ink` `#14231D` | `#ECE7DC` | text on cards |
| `cardMuted` | `#2C4A3F` | `#9AA4AD` | secondary text on cards, tags |
| `cardBorder` | `#CDBE8E` | `#232A33` | a card's ordinary border (decorative) |
| `cardBorderStrong` | `goldDark` `#B8923A` | `#232A33` | the today panel, About and strip borders |
| `cardBorderActive` | `gold` `#E4C877` | `#6CC4B5` | the active wird's outline |
| `cardDivider` | `#E2D6A9` | `#232A33` | dividers inside a card |
| `cardDisabled` | `#8A8F86` | `#6B7782` | disabled content on a card (exempt) |
| `controlBorder` | `goldDark` `#B8923A` | `#5F6B76` ▲ (design `#2B343D` = 1.51:1; this is 3.50:1) | border of the add button, outlined buttons, unselected option |
| `primaryFill` | `gold` `#E4C877` | `#6CC4B5` | filled buttons, selected chips, slider thumb |
| `onPrimary` | `green` `#0E3B30` | `#08201C` | text and icons on `primaryFill` |
| `doneFill` | `green` `#0E3B30` | `#6CC4B5` | the «تم» button on a card |
| `onDone` | `#F3E3A6` | `#08201C` | its label |
| `ring` | `#5E7F6F` | `#46525E` | the About emblem ring, the page ring |

### Required pairs (the list `AppLook.night.requiredPairs`)

| Foreground | Background | Minimum | Used for |
|---|---|---|---|
| `text` `#ECE7DC` | `background` `#0D1014` | 4.5 | body text |
| `textSecondary` `#9AA4AD` | `background` | 4.5 | captions, notes, subtitles |
| `textDim` `#85909B` | `background` | 4.5 | page number, quiet lines |
| `heading` `#ECE7DC` | `background` | 3.0 (large) | titles |
| `accent` `#6CC4B5` | `background` | 4.5 | links, accent text, icons (3.0) |
| `cardInk` `#ECE7DC` | `cardFill` `#161B22` | 4.5 | text on cards |
| `cardMuted` `#9AA4AD` | `cardFill` | 4.5 | secondary text on cards, tags |
| `accent` `#6CC4B5` | `cardFill` | 4.5 | tags, links on cards |
| `onPrimary` `#08201C` | `primaryFill` `#6CC4B5` | 4.5 | filled buttons |
| `onDone` `#08201C` | `doneFill` `#6CC4B5` | 4.5 | the «تم» pill |
| `text` `#ECE7DC` | `barFill` `#161B22` | 4.5 | bar labels and icons |
| `controlBorder` `#5F6B76` | `background` | 3.0 | add button, outlined buttons, unselected option |
| `controlBorder` `#5F6B76` | `cardFill` | 3.0 | the same on a card |
| `cardBorderActive` `#6CC4B5` | `cardFill` | 3.0 | the active wird's outline |
| `PageLook.night.ink` `#ECE7DC` | `PageLook.night.background` | 4.5 | Quran text |
| `PageLook.night.bannerText` `#6CC4B5` | `PageLook.night.background` | 3.0 (large) | surah title |
| `PageLook.night.endMarker` `#6CC4B5` | `PageLook.night.background` | 3.0 | ayah-end markers |
| `PageLook.night.numberColor` `#85909B` | `PageLook.night.background` | 4.5 | page number |
| `ink` on the highlight wash `#2A4644` | (the wash) | 4.5 | long-pressed ayah (and the wash against the page at 1.5) |

Exempt (listed in `AppLook.night.decorative`): `cardBorder`, `cardDivider`, `cardBorderStrong`, `barBorder` and `line`
(hairlines `#232A33` and `#2B343D`), `ring`, and disabled content (`cardDisabled`, the 50% disabled bar items). The
contrast walk helper checks the painted colours of every screen against the same minimums, so a pair the list forgets
is still found.

### Shapes

| Token | Emerald (today) | Night |
|---|---|---|
| `cardRadius` | 16 | 20 |
| `strongBorderWidth` (today panel, About) | 2 | 1 |
| `buttonRadius` (filled, outlined, the «تم» button) | 10 to 14 as today | stadium (999) |
| `addButton` | rounded square, radius 12, 1.5 px `controlBorder` | circle, 44 px, 1 px `controlBorder` |
| `tag` | rectangle radius 8 | pill |
| `wirdMarker` | rotated square (diamond), 10 px | circle, 8 px |
| `bottomBar` | full width, top border, edge to edge | floating pill 56 px high inside the 68 px slot, 16 px side margins, radius 28 |

Every constant is an instance of `AppLook`; there is no mutable state in it. A test asserts that every Emerald token
equals the corresponding `AppColors` constant or the literal quoted above.

## PageLook (constant, per look)

Existing fields (kept, with their types): `paper`, `ink`, `frame`, `frameWidth`, `bannerText`, `background`,
`ring?`, `bannerFill?`. New optional fields (defaults reproduce Emerald exactly): `bannerStyle` (`framed` or
`rules`), `numberColor`, `highlight`, `endMarker?`.

| Field | Emerald (`PageLook.screen`) | Night (`PageLook.night`) |
|---|---|---|
| `background` | `#0E3B30` | `#0D1014` |
| `paper` | `#FBF5E3` | `#0D1014` (same as the background: no card) |
| `ring` | `#5E7F6F` | none |
| `frame`, `frameWidth` | `#B8923A`, 2 | transparent, 2 (the same box, nothing drawn) |
| `ink` | `#14231D` | `#ECE7DC` |
| `bannerStyle` | `framed` (green fill, gold outline, stars) | `rules` (title between two 1 px `#2B343D` hairlines, no fill, no box) |
| `bannerText` | `#E4C877` | `#6CC4B5` |
| `numberColor` (page number) | `ink` as today | `#85909B` |
| `highlight` (long-pressed ayah) | `#55FFC107` (today) | `#4D6CC4B5` (teal at 30%) |
| `endMarker` | none (ink) | `#6CC4B5` |

Invariant (Constitution I): a `PageLook` carries colours and the banner style only; no size, padding or text.

## Derived page data: ayah-end markers

`PageData.endMarkerIds`: the ids of the words of the page that are the end marker of their ayah, derived when the
page is loaded (a word is a marker when the next word in Mushaf order belongs to another ayah; for the last word of
a page the first word of the next page decides). Not stored, no asset changed. Over all 604 pages there are exactly
6,236 markers, one per ayah, each the last word of its ayah.

## Wird marker colour (derived)

`markerColor(AppLook look, Color palette)`: Emerald returns `palette`; Night raises the HSL lightness of `palette`
in 1% steps until its contrast with `cardFill` is at least 3.0 (research D6). The stored `Wirds.color` is never
changed.
