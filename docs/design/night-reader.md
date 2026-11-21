# Look: Night Reader (chosen as the second look on 2026-11-20)

Source: the design canvas with the three explored directions (A Ink & Paper, B Night Reader, C Emerald & Gold):
https://claude.ai/artifact/Bug9MVu2TbGWJtaKGhCSye (private), boards `B-Wirds` and `B-Reader`. The link is a source for
the values below, not a dependency of the build. Today's look, direction C, is in `docs/design/emerald-gold.md` and
stays the default; Night Reader is chosen in Settings (feature 004, `specs/004-night-reader-theme/`). The tokens are
`AppLook.night` in `lib/theme.dart` and `PageLook.night` in `lib/mushaf/page_look.dart`.

## Colours

| Token | Night | Emerald (today) | Used for |
|---|---|---|---|
| background | `#0D1014` | `#0E3B30` | scaffold, app bar, sheets, dialogs, the picture and PDF sheet |
| barFill | `#161B22` | `#0A2D25` | reader bottom bar |
| barBorder | `#232A33` | `#1E5646` | the bar's border |
| line | `#2B343D` | `#1E5646` | dividers, slider tracks |
| heading | `#ECE7DC` | `#E4C877` | titles |
| accent | `#6CC4B5` (teal) | `#E4C877` | icons, selected states, links, the page's surah title |
| accentAlt | `#E3B05A` (amber) | `#B8923A` | progress, emblem details |
| text | `#ECE7DC` | `#F3EBCB` | body text |
| textSecondary | `#9AA4AD` | `#E8DDB5` | captions, notes |
| textDim | `#85909B` | muted at 75% | page number, quiet lines |
| cardFill | `#161B22` | `#FBF5E3` | cards, rows, panels |
| cardInk | `#ECE7DC` | `#14231D` | text on cards |
| cardMuted | `#9AA4AD` | `#2C4A3F` | secondary text on cards |
| cardBorder | `#232A33` | `#CDBE8E` | a card's ordinary border |
| cardBorderStrong | `#232A33` | `#B8923A` | today panel, About, strip |
| cardBorderActive | `#6CC4B5` | `#E4C877` | the active wird's outline |
| cardDivider | `#232A33` | `#E2D6A9` | dividers inside a card |
| cardDisabled | `#6B7782` | `#8A8F86` | disabled content on a card |
| controlBorder | `#5F6B76` | `#B8923A` | add button, outlined buttons |
| primaryFill / onPrimary | `#6CC4B5` / `#08201C` | `#E4C877` / `#0E3B30` | filled buttons |
| doneFill / onDone | `#6CC4B5` / `#08201C` | `#0E3B30` / `#F3E3A6` | the «تم» pill |
| ring | `#46525E` | `#5E7F6F` | emblem ring |

## Two values lifted from the design (WCAG 2.x contrast, computed 2026-11-20)

| Design value | Where | Ratio | Night value | New ratio |
|---|---|---|---|---|
| `#6E7983` (dim) | page number, quiet captions | 4.29 on the background, 3.89 on a card | `#85909B` | 5.87 / 5.32 |
| `#2B343D` (hairline) as the border of the add button and the outlined «ورد جديد» | the border of a control (needs 3:1) | 1.51 | `#5F6B76` (`controlBorder`) | 3.50 on the background, 3.17 on a card |

Card hairlines (`#232A33`, `#2B343D`) and separators stay as designed: they carry no information.

## Shapes

| Token | Night | Emerald |
|---|---|---|
| card radius | 20 | 16 |
| strong border width (today panel, About) | 1 | 2 |
| buttons | stadium (pill) | 10 to 14 as today |
| add button | circle, 44 px, 1 px `controlBorder` | rounded square, radius 12, 1.5 px |
| tags | pill | rectangle, radius 8 |
| wird marker | 8 px dot | 10 px rotated square |
| bottom bar | floating pill, 56 px high inside the unchanged 68 px slot, 16 px side margins, radius 28 | full width, top border |

(The design's mock-up bar is 66 px high with a 22 px bottom margin, 88 px in all; the app keeps its 68 px slot so the
page does not change size when the look changes.)

## The Mushaf page in Night

No card and no frame: the card's paddings and border width stay, the frame is transparent, so the page keeps the
box and every line of Emerald. Ink `#ECE7DC`; the surah title in teal `#6CC4B5` between two 1 px `#2B343D`
hairlines (no fill, no box); ayah-end markers teal; page number `#85909B`; the long-pressed ayah gets a teal wash
`#6CC4B5` at 30% (`#2A4644` over the page: 1.87:1 against the page, ink 8.28:1 on it).

## Wird marker colours

The owner's palette is stored as chosen. On a Night card three colours are lightened (hue kept) to reach 3:1:
purple `#6A1B9A` (1.84:1) becomes about `#982DDA`, brown `#4E342E` (1.53:1) about `#8B5D52`, slate `#37474F`
(1.79:1) about `#526A76`; the other five already pass.

## Fonts (unchanged) and what is not copied

Cairo (interface), Reem Kufi (headings), Amiri Quran (basmallah): the same as in Emerald & Gold. The design canvas
used IBM Plex Sans Arabic and Amiri; they are NOT added (the owner replaced Plex with Cairo on 2026-11-20; no new
resource, `docs/research/licenses.md` and About unchanged).
