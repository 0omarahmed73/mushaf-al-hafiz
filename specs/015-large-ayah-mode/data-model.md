# Data Model: Large Ayah Mode

Nothing is added to the database schema and no Quran data is stored or changed. Four keys are added to the existing
key/value `Settings` table; everything else is derived in memory.

## Stored: settings keys (table `Settings`)

| Key | Values | Absent or unusable | Meaning |
|-----|--------|--------------------|---------|
| `largeAyah` | `'true'`, `'false'` | off | the mode is on; when on, the app opens on it (constitution 2.2.0, Principle II) |
| `largeAyahCount` | `'1'`, `'2'`, `'3'` | 1 | ayat per screen (FR-006) |
| `largeAyahSize` | `'1'`, `'2'`, `'3'` | 1 | size step: factor 2.0, 2.5, 3.0 (research D2) |
| `largeAyahAt` | `"surah:ayah"` of a real ayah | ignored | first ayah of the last screen shown (research D6) |

Rules: parsing never throws; a value outside its set is the default; writes happen at once; the backup carries the keys
with no format change; after a restored backup the notifier reloads (as `TextSizeSettings.reload`).

## Derived (never stored)

### ScreenRef

- `page` (1..604), `index` (0-based screen of that page). Identity of a screen for a given (count, size, screen box).

### LargeScreen

- `page` (1..604)
- `items` (as built): what the screen draws, top to bottom: `OpeningItem` (a surah title of surah S, or the basmala) and
  `AyahItem` (an ayah and its lines of `MushafWord`s). A surah can open in the middle of a screen (page 604), and a page's
  last screen can end with the next surah's title (18 pages, research D3).
- derived getters: `ayat` (1 to 3 `AyahRef`s of `page`, consecutive, in order; exactly one when `part` is set), `opening`
  (every opening line of the screen), `lines` and `words` (in order), `continues`
- `part`: null for whole ayat; otherwise `(number, of)` for a split ayah (1-based)
- Validation (tested over the whole Mushaf): concatenating `lines` of all screens of a page gives exactly the words of the
  page's ayat in order; every ayah's words are all in its own screens; a split ayah's parts are consecutive screens with
  `number` 1..`of`; no screen mixes pages.

### Layout input (pure function, research D3)

- `PageAyat`: per ayah of the page, `ref`, `words` (`MushafWord`), `widths` (px at the chosen size), and the opening lines
  that precede it (title, basmala) with their heights in lines
- `lineWidth` (px), `linesPerScreen` (whole lines), `count` (1..3)

### Mode state (in the reader, not stored except `largeAyahAt`)

- `on` (from `largeAyah`), `anchor` (`ScreenRef` the pager is built around), `startKnown` (pager index of the screen of
  1:1 once walked to), highlight and tint word ids (the same sets the Mushaf page uses).

## State transitions

- Mushaf → mode (switch on): anchor = screen holding the long-pressed or found ayah if any, else the first screen of the
  controller's page; `largeAyah` = true.
- Mode → Mushaf (button «المصحف» or switch off): the Mushaf opens on the page of the screen shown; `largeAyah` = false.
- Screen settles: `onPageShown(screen.page)`; `largeAyahAt` = first ayah of the screen.
- Count, size or screen box changes: re-anchor at the screen that holds the previous first ayah (for a split ayah: its
  first part); if the reader has not swiped since the last anchoring, at the ayah anchored then (FR-007).
- Jump to page P: anchor = first screen of P. Search target ayah A: anchor = the screen holding A (first part if split).
- App start with mode on: anchor = screen of `largeAyahAt` if that ayah is on the controller's page, else the first screen
  of the controller's page.
