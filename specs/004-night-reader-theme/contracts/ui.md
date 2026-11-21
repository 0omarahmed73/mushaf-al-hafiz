# UI contract (feature 004)

Arabic strings below are **proposed**; the owner confirms them (Constitution VI). All other strings of the app are
unchanged.

## Settings row «المظهر» (first section of Settings)

```
┌───────────────────────────────────────────────┐
│ المظهر                                         │  section label
│ ┌──────────────────┐ ┌──────────────────┐     │
│ │ ▣▣▣  ✓           │ │ ▣▣▣               │     │  two option cards (a 3-colour swatch of the look,
│ │ زمردي وذهبي      │ │ القارئ الليلي    │     │  its name, a check and a 2 px accent outline when chosen)
│ └──────────────────┘ └──────────────────┘     │
│ يُطبَّق على التطبيق كله وعلى الصورة وملف PDF   │  note
│ اللذين تشاركهما                               │
└───────────────────────────────────────────────┘
```

| Element | String | Notes |
|---|---|---|
| Section label | «المظهر» | key `look-title` |
| Option 1 | «زمردي وذهبي» | key `look-emerald`; default; Semantics: button, selected, label as shown |
| Option 2 | «القارئ الليلي» | key `look-night`; same |
| Note | «يُطبَّق على التطبيق كله وعلى الصورة وملف PDF اللذين تشاركهما» | key `look-note` |

Each option is at least 56 px high and 48 px wide (full width of its half), stacks under the other when the row is
narrower than 320 dp or the system font is large, never overflows. A tap saves and applies at once, including to the
Settings screen itself.

## Per screen: what changes in Night (content, order and actions never change)

| Screen / sheet | Night look |
|---|---|
| Reader: top line | background; heading colour `heading`; surah name `textSecondary`; part/hizb line `textSecondary`; the active-wird pill: pill outline `controlBorder`, 6 px teal dot |
| Reader: Mushaf page | `PageLook.night` (no card, no frame, light ink, teal surah title between hairlines, teal ayah-end markers, `#85909B` page number); highlight teal wash |
| Reader: bottom bar | floating pill in the same 68 px slot (D5); same five items; «استماع» and «اختبار» disabled and labelled «قريباً» at 50% opacity |
| Reader: «ملخص اليوم» panel and browse banner | `cardFill` card, `cardBorder` hairline, radius 20, dots, «تم» in `doneFill` pill |
| Index (surahs and parts) | background, `cardFill` rows with hairlines, `accent` selection, pill tabs |
| «أوراد» | round 44 px add button, «ملخص اليوم» card with dots and a «تم» pill or «✓ تم», wird cards (active one outlined `cardBorderActive` and tagged «النشط»), pill tags, outlined «ورد جديد» pill with `controlBorder` |
| Wird form | `background`, outlined fields with `controlBorder`, pill choices, `primaryFill` pill «حفظ», palette swatches with `markerColor` |
| Bookmarks sheet | `background` sheet, `cardFill` rows, `accent` icons |
| Ayah menu and its tafsir, translation, meanings views | `background` sheet; rows `cardFill` with `cardBorder` and radius 20; reading panels `cardFill` with `cardInk` text (feature 003 sizes unchanged) |
| PDF progress strip | `cardFill` pill, `accent` progress, `controlBorder` buttons |
| Go-to-page dialog | dialog on `cardFill`, outlined field, pill buttons |
| Settings | sections on `background`; switches, slider (feature 003 tile), buttons take the scheme (`primaryFill`) |
| About | same content; emblem and cards in the Night palette (cards `cardFill`, emblem `accent`) |

## Acceptance (per screen, both looks)

- No overflow on a 320 dp wide window with the largest system font; every control at least 48 px.
- Every text and icon pair meets `AppLook.requiredPairs` (Night) and no ivory or bright block remains in Night.
- Emerald: the same widget tree and colours as before this feature (the existing tests pass unchanged).
