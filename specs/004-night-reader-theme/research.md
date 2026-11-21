# Research: Night Reader Look

Decisions for [plan.md](plan.md). Source of the look: the owner's design canvas, direction B (boards B-Wirds and
B-Reader) compared with direction C (today's look, `docs/design/emerald-gold.md`). Contrast figures below were
computed on 2026-11-20 with the WCAG formula.

## D1. Where the choice lives

**Decision**: `LookChoice { emerald, night }` (pure enum with a lenient `parse`: null, empty or unknown text means
`emerald`), and `AppLookSettings extends ChangeNotifier` over `WirdRepository` (`load`, `reload`, `set`), the same
shape as `TextSizeSettings` of feature 003. One settings key `appLook` with the values `emerald` / `night`
(`WirdRepository.appLookRaw()` / `setAppLook(String)` next to `textSizeRaw`). `main.dart` loads it before
`runApp`; `MushafApp` gets `appLook:` and provides it with `ListenableProvider<AppLookSettings?>.value`.

**Rationale**: the pattern is already proven in feature 003 (provider, load before the first frame, backup for free
because `BackupService` exports every settings row as a string and its import accepts any string value). A bad
value is cured at read time, not at import time, so an old or edited backup cannot fail.

**Alternatives**: follow the phone's dark mode (rejected by the owner: both looks are dark); a bool
`nightEnabled` (not extensible, and a wrong value would silently mean "false"); per-screen choice (not asked).

## D2. How screens read the look

**Decision**: `AppLook` is a `ThemeExtension<AppLook>` with semantic tokens (see data-model.md) and two constant
instances, `AppLook.emerald` (built from the existing `AppColors` constants, so the values are literally today's)
and `AppLook.night`. `buildAppTheme({AppLook look = AppLook.emerald})` builds the `ThemeData` (colour scheme, app
bar, tab bar, list tile, divider, input, filled and text buttons, plus switch, slider, snack bar, dialog and bottom
sheet themes from the look) and attaches the extension. `extension LookContext on BuildContext { AppLook get look
=> Theme.of(this).extension<AppLook>() ?? AppLook.emerald; }`. `MushafApp` wraps `MaterialApp` in a
`ListenableBuilder` on the look settings and passes `theme: buildAppTheme(look: ...)`, with
`themeAnimationDuration: Duration.zero` (an instant, exact switch: no half-faded paper card, nothing to lerp).
`AppColors` stays as the Emerald tokens, unchanged.

Each of the 13 files is migrated in its own task: `AppColors.x` becomes `context.look.x` (or a local `final look =
context.look;`), `const` is dropped where a colour was inside a constant expression, and the file's existing tests
must stay green with Emerald untouched. Because `context.look` falls back to Emerald when the theme has no
extension, every existing test (which pumps a plain `MaterialApp` or `buildAppTheme()`) sees today's colours and
needs no change.

**Rationale**: a `ThemeExtension` is the framework's own mechanism: it rebuilds dependants when the theme changes,
works inside routes, dialogs, sheets and overlays (they are built under the same `Theme`), is testable by pumping
a `Theme`, and needs no global state. The fallback keeps the migration safe in small steps.

**Alternatives**: (a) make `AppColors` mutable/static-switched: global mutable state, nothing rebuilds on change,
tests leak between cases; (b) a second set of widgets per look: doubles every screen; (c) pass the look down by
constructor: 40 widgets to change and every call site in tests.

## D3. The Mushaf page in Night, and why no line can move

**Decision**: `PageLook` keeps its fields and constructor (so `PageLook.screen` and the test `PageLook(...)`
literals still compile), gains optional fields with Emerald defaults: `bannerStyle` (`framed` / `rules`),
`numberColor`, `highlight`, `endMarker` (colour or null), and a second instance `PageLook.night`; `PageLook.emerald`
is an alias of `screen`. For Night: `paper` = the background colour, `ring` = null, `frame` = transparent with the
same `frameWidth` (2), so the card's decorations are laid out exactly as in Emerald but nothing is drawn; `ink` =
`#ECE7DC`; banner `rules`: no fill and no box, the title in teal between two 1 px hairlines inside the same line
box and the same height; page number `#85909B`; highlight a teal wash (`#6CC4B5` at 30% over the page = `#2A4644`: 1.87:1 against the page, spec needs
1.5:1, and the ink on it 8.28:1, spec needs 4.5:1).

`MushafPageCard` and `MushafPage` change only what they paint: they read `look` fields; paddings (12/4/3/10/6), the
border width and every `SizedBox` stay. **Ayah-end markers**: the data lists the marker as the last word of each
ayah (checked on 2026-11-20 over all 604 pages: 6,236 ayahs, the last word of each has a one-character glyph); a
word is a marker when the next word in Mushaf order belongs to another ayah (for the last word of a page, the first
word of the next page, which `MushafRepository` already loads for page turns). `MushafRepository.loadPage` adds
`endMarkerIds` to the loaded `PageData` (derived, not stored, no data file touched); `MushafPage` colours those
words with `look.endMarker` (teal in Night, none in Emerald). Test over all 604 pages: exactly 6,236 markers, one per
ayah, each the last word of its ayah.

**Proof of invariance**: a new test (`page_layout_both_looks_test.dart`, not editing feature 003's invariance
test) pumps every sampled page in both looks and compares the `line-N` boxes, the word order and the word boxes
(default: sampled pages, a `FULL_LAYOUT_CHECK` flag for all 604 as in feature 003). The existing tests of
`mushaf_page_card_test.dart` and `mushaf_page_test.dart` stay green unchanged.

**Fallback** (recorded, not expected): if the marker derivation proves unreliable on the phone, markers keep the ink
colour in Night; the spec's «teal rings» then becomes «light rings»; the owner is told.

**Rationale**: only colours move, and the box is built from the same widgets with a transparent frame; the proof
is measured, not argued. **Alternatives**: remove the paddings and frame in Night (would change the page box and
risk line widths); draw a ring with a canvas behind the glyph (needs positions, brittle); change the font glyphs
(forbidden, Constitution I).

## D4. Picture and PDF follow the look

**Decision**: `PageRenderer.picture(int page, {PageLook look = PageLook.screen})` and `pdfPage(int page, {PageLook
look = PageLook.screen})` (the off-screen renderer already has `renderRgba(page, look, pixelRatio)` and `_paint`
takes a look). (The look is read when the sheet opens; the sheet is a modal route, so the look cannot change between opening it and sharing, which makes this equal to «the look in force when the owner starts the share» of FR-010.) `PagePictureAction` is created by `showAyahSheet` with `look: context.read<AppLookSettings?>()?.
choice.pageLook`; the look is read when the sheet opens and passed on every `run`. `PdfJob.start(int surah, {PageLook
look = PageLook.screen})` stores the look for the job (`_jobLook`), passes it to every `renderer.pdfPage`, and its
default writer factory builds `PdfWriter(sheet: _jobLook.background)`; a custom `writerFactory` (tests) is called
as today. A look change after `start` cannot reach a running job (it only reads `_jobLook`). `showAyahSheet` and the
reader pass `AppLookSettings.pageLook` into `pdfJob.start`.

**Quantisation**: `indexedFlatePage` already builds a 256-colour palette from the page's own pixels (feature 002,
colours checked after the owner's complaint about faded colours). A dark page has fewer distinct colours than the
ivory one (light text anti-aliased on near-black), so 256 is enough; a new test counts the dominant colours of a
Night render (background, ink, teal, hairline) exactly as `page_renderer_test.dart` does for Emerald, and the
phone check re-measures time and size (picture 0.5-0.8 s and Al-Baqarah 10.2 s, 15.1 MB in Emerald).

**Interface cost**: the two fakes (`test/support/fake_renderer.dart` and any fake of `PageRenderer` in a test) must
accept the optional parameter, a behaviour-preserving edit of test support recorded in Complexity Tracking.
**Alternatives**: a global current look (a change corrupts a running job); a `LookAwareRenderer` sub-interface
(old fakes untouched but two code paths forever).

## D5. The reader's bars and the page box

**Decision**: the reader keeps `_topBarHeight` (84) and `_bottomBarHeight` (68) slots, so the page area and
feature 003's `PageBox` base are identical in both looks. In Night the bottom bar is drawn inside its 68 px slot
as a floating pill: 56 px high, 6 px above and below, 16 px at the sides, radius 28, fill `cardFill`, border
`cardBorder`; its items keep their 48 px targets and their actions («استماع» and «اختبار» stay disabled with
«قريباً»). In Emerald the bar is today's full-width bar. The top bar keeps its content; Night changes its colours
(title `heading`, the surah name `textMuted`, the active-wird pill as a pill with a teal dot). The `Scaffold`
background and the browse banner take their colours from the look.

**Rationale**: the page must not change size when the look changes (Constitution II, spec FR-009). **Alternatives**:
a taller bar with a 22 px margin as in the mock-up (88 px, would shrink the page by 20 px).

## D6. Wird marker colours

The owner's 8 palette colours are stored as chosen (`wird_palette.dart`). On the Night card (`#161B22`) three of
them miss 3:1: purple `#6A1B9A` 1.84, brown `#4E342E` 1.53, slate `#37474F` 1.79 (the other five pass: green 3.37,
blue 3.01, red 3.08, orange 5.61, teal 3.82). **Decision**: `markerColor(look, paletteColor)` returns the colour
unchanged in Emerald, and in Night raises its HSL lightness in 1% steps until the contrast with `cardFill` reaches
3.0 (purple becomes about `#982DDA`, brown `#8B5D52`, slate `#526A76`). Only the drawn marker changes; the stored
value does not. The marker shape follows the look (diamond in Emerald, 8 px dot in Night). Test: all 8 colours at
or above 3:1 on Night, unchanged on Emerald, and pairwise still different.

## D7. Contrast of the Night look

`contrastRatio(a, b)` is a pure function (WCAG relative luminance); `AppLook.night.textPairs` and `.graphicPairs`
list every (foreground, background) pair the look uses and one test walks them (SC-005). Findings from the design's
values: text `#ECE7DC` 15.46 on the background and 14.03 on cards, secondary `#C9D1D9` 11.21, muted `#9AA4AD` 6.83,
teal `#6CC4B5` 8.40, amber `#E3B05A` 8.75, on-accent `#08201C` on teal 8.27: all pass. Failures lifted:

| Design value | Where | Ratio | Night value | New ratio |
|---|---|---|---|---|
| dim `#6E7983` | page number, quiet captions | 4.29 on background, 3.89 on card | `#85909B` | 5.87 / 5.32 |
| hairline `#2B343D` used as the border of the add button and the outlined «ورد جديد» | a control's border (FR-012 needs 3:1) | 1.51 | `controlBorder` `#5F6B76` | 3.50 on background, 3.17 on card |

Card hairlines (`#232A33`) and separators carry no information (every card is also set apart by its fill, its
spacing and its content) and are decorative; they are listed as such in the test so the exemption is explicit. The
chosen state is shown by more than colour: the active wird has a teal outline and a «النشط» tag; the chosen look
has a check mark and an outline. Emerald is not re-audited (it must not change).

## D8. The Settings row

**Decision**: a new `LookTile` (`lib/settings/look_tile.dart`), placed first in the settings list under a
«المظهر» section label (`SettingsScreen` gets one added line and the colour migration; the feature 003 tile is not
touched in this task). Two option cards side by side (stacked when narrower than 320 dp or with a large system
font), each at least 56 px high with a swatch strip of that look (background, card, accent), the name, and a check
mark and a 2 px accent outline when chosen; tapping saves at once (`AppLookSettings.set`). Semantics: a radio-like
group, each option `button`, `selected`, label «زمردي وذهبي» / «القارئ الليلي». A note under the options.

## D9. System UI, first frame, changing the look while things are open

Both looks are dark, so status bar and navigation bar icons stay light; no per-look system style is needed (a test
documents it). The saved look is loaded in `main()` before `runApp` (like the text size), and `MushafApp` builds
the theme from it, so the first frame is already right. A change from Settings rebuilds the `MaterialApp` theme:
open routes (Settings itself, the reader behind it, a bottom sheet, a dialog, a snack bar, the PDF strip) read
`context.look` from the same `Theme`, so they update in the same frame. The overlay renderer (picture, PDF) does not
read the theme; it is given the look explicitly (D4).

## D10. Backup

Key `appLook`. Export needs no code (all settings rows). Import accepts any string; `LookChoice.parse` cures a bad
value, so no import error. After a successful import `SettingsScreen` calls `AppLookSettings.reload()` (one line in
its import success path) so the imported look applies at once, even before returning to the reader. Tests: export
contains `appLook`, import of a backup without it keeps Emerald, import of `"purple"` gives Emerald without error,
import of `night` switches the open Settings screen.

## D11. Coordination in the shared folder

Feature 003's session is still wiring the reader (T014-T022) and owns `reader_screen.dart`, `page_scale.dart`,
`page_viewport.dart`, `text_size_tile.dart` and `reading_text.dart`. This feature touches in them only colours, in
its last phase after that session has committed (check `git status` and `git log` first). In `reader_screen.dart`
the colour spots are: the `Scaffold` background (line 161), the shadow (424), the top bar (606-677), the bottom bar
(734-797) and passing the page look to the page card. Feature 002's files (`lib/render`, `lib/pdf`, `page_look.dart`,
`test/support/fake_*`) are edited only when `git status` shows them clean. `.specify/feature.json` stays as it is
(it points at feature 003); the speckit scripts for this feature run with `SPECIFY_FEATURE_DIRECTORY` and
`SPECIFY_FEATURE_NO_PERSIST=1`.

## D12. Performance and the phone check

`AppLook` and `PageLook` are constant objects; reading the extension is a map lookup; the page is rebuilt only
when the look changes. The Mushaf page paints the same widgets with other colours, so a page turn costs the same;
SC-008 is measured on the phone (page text visible under 300 ms) and the picture and PDF times are re-measured
(D4). Phone checklist (the owner's phone <phone>; never unlock it, ask before sending input): every screen
of FR-004 in both looks (screenshots), cold start in Night without a flash, switching looks with Settings open,
a long press and the highlight in Night, the picture and the PDF in Night opened in the share target, a page turn,
pinch zoom, rotation, the largest system font on a small window.

### D11 gate record (T028, 2026-11-21)

Checked before the first edit of the shared files. `git status` showed `reader_screen.dart`, `page_scale.dart`,
`page_viewport.dart`, `text_size_tile.dart` and `reading_text.dart` clean.

- Feature 003 (session `local_c86870f7…`): its reader tasks are committed (T014 `17afca7`, T017 `2bab280`) and it
  answered by `SendMessage` that no edit is pending in `text_size_tile.dart` or `reading_text.dart` (all its files are
  committed; it will tell this session before touching `page_viewport.dart` or `reader_screen.dart` again). T032 was
  done on that answer (`b59bbf8`, colours only).
- Feature 005 (the khatm dua, session `local_baa2b8ed…`) also edits `reader_screen.dart`: its T007 is committed
  (`2cf5510`) and its `tasks.md` states the file is edited once. The question to that session was queued while it was
  busy; the reader work (T030, T031) starts on that written plan and on the clean `git status`, checked again right
  before each edit, and each edit is committed at once. `reading_text.dart` had been migrated in T012 (`7ec2795`).
- Reading of the contract: for the reader's top line the surah name takes `heading` (gold in Emerald, light ink in
  Night) and the juz line `textSecondary`; the contract's "surah name `textSecondary`" would turn Emerald's gold name
  muted. The bar items take `heading`, the wird pill outline `controlBorder`, its dot `accent`, its text `text`.

### D12 phone check status (2026-11-21)

Done: a release build (`--dart-define=AYAH_MENU_TRACE=true --dart-define=PAGE_TURN_TRACE=true`, 178.7 MB) was installed
with `adb install -r` on the owner's phone <phone> (data kept) at the owner's request, and the app was started
without any input. It opened in Night (the saved choice) and one screenshot of the reader was checked: the Mushaf
page on the dark background with no card and no frame, teal ayah-end markers, the title line (surah name in the
light heading colour, juz line grey), the wird pill with its teal dot, and the bottom bar as a pill with all five
items and the two «قريباً» labels inside it.

Not done: the owner answered "لأ، كفاية" to the question about tapping through the phone, so no input was sent. The
other screens in both looks, the cold start without a flash, switching with Settings open, the page turn time, the
share picture (under 3 s) and the Al-Baqarah PDF (under 60 s) are NOT measured. T017, T034 and T035 stay open until
the owner asks for them or runs the quickstart steps by hand.
