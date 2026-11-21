# UI Contract: Surah and Ayah Search (feature 011)

Every visible string is a **proposal** until the owner confirms it (Constitution VI, task T070); the strings are in `lib/search/search_strings.dart`
(contracts/dart-interfaces.md). Every size, weight and colour choice below is the plan's default (the look and feel is the owner's to change without
changing the rest). `N` is a number written with Western digits, like the page number the app draws.

## Where it is and how it is reached

| Item | Contract |
|---|---|
| Entry | an `IconButton` with `Icons.search` at the end of the **index screen's app bar** (`ValueKey('open-search')`, 48 x 48, tooltip and screen-reader label «بحث»), shown only when the app provides a `SearchService` (research D10). The three tabs, the title, the surah list, the juz list and the page field are unchanged (FR-030) |
| Route | a `MaterialPageRoute` pushed by the index; the framework's own transition (this feature adds no motion) |
| From the reader | 3 taps: the surah name, the search icon, a result (SC-006); search is never the first screen (FR-001) |
| Result | a surah row pops the **int** first page (the index's own value); an ayah row pops an **`AyahTarget`**; the index forwards either by popping itself with it; the reader treats an int as today and an `AyahTarget` as research D4 |
| Back | the system back and the app bar's back arrow close search after the keyboard (the platform closes the keyboard first); the reader and the index are exactly as they were (FR-003, FR-017) |

## The screen

```text
AppBar:   [back arrow]            بحث                      (the theme's heading style, like «الفهرس»)
Body:     ┌ field (full width, label «ابحث عن سورة أو آية», clear button «مسح» when not empty) ┐
          ├ list (scrolls under the field):                                                    ┤
          │  heading «السور · N»                       (only when the surah group has rows)     │
          │  surah rows: number · name · «ص N»                                                  │
          │  heading «الآيات · N»  or the ayah group's line                                      │
          │  ayah rows: «{name} · آية N» ... «ص N», then the snippet                            │
          │  the line «النتائج كثيرة، اكتب كلمات أكثر لتضييق البحث» (only when total > 100)       │
          └────────────────────────────────────────────────────────────────────────────────────┘
```

The field stays above the list and above the keyboard (`resizeToAvoidBottomInset`); only the list scrolls. It is a single-line `TextField`:
`autofocus: true`, `textInputAction: search` (the key only closes the keyboard), `autocorrect: false`, `enableSuggestions: false`,
`enableIMEPersonalizedLearning: false`, **no input formatter and no length limit** (what is typed is never altered, FR-008).

## States (what is shown; research D2 and spec FR-002, FR-009, User Story 5)

`letters` is the number of Arabic letters left after folding (research D2); the surah group is answered at once; the ayah group depends on the
service's phase.

| `letters` | Surah group | Ayah group |
|---|---|---|
| 0 (empty, spaces, marks only, digits or Latin only) | not shown | not shown; **one line** «اكتب اسم سورة، أو كلمات من آية» (no error, no red) |
| 1 | rows if any (a name from one letter: «ق», «ص») | its heading is not shown; **one line** «اكتب حرفين على الأقل للبحث في الآيات» (also when no surah matched) |
| >= 2, service `notStarted`/`preparing` | rows if any, at once | **one line** «جارٍ تجهيز البحث في الآيات»; the rows appear by themselves when ready, for the text in the field now |
| >= 2, service `failed` | rows if any | **one line** «تعذّر تجهيز البحث في الآيات» and a button «إعادة المحاولة» (48 px high); tapping it prepares again; nothing else is affected |
| >= 2, ready, ayat found | rows if any | heading «الآيات · total» then up to **100** rows in Mushaf order; when `total > 100` the line «النتائج كثيرة، اكتب كلمات أكثر لتضييق البحث» under the last |
| >= 2, ready, no ayah | rows if any | not shown |
| >= 2, ready, **nothing in either group** | not shown | not shown; **one line** «لا توجد نتائج» and under it «جرّب كلمة واحدة أو كلمات أقل» |

A group with no match is not shown at all; the surah heading shows the number of rows (at most 114, never cut); the ayah heading shows the true total, not 100.

## Rows

**Surah row** (as the index row): `ListTile`: leading `N` (the surah number), title the name **as the index writes it**, trailing «ص N» (its first
page); at least 56 px high, grows with the system font; a tap pops the first page. Colours of the index's list tiles.

**Ayah row**: a tappable block (`InkWell`, at least 56 px high plus its snippet), three parts in the start-to-end order of an RTL row:

1. the title «{name} · آية N» (system font, `look.text`, 16, w600) and, at the end, «ص N» (`look.textSecondary`, 14);
2. the **snippet**: a `Text.rich` of whole **stored** words, character for character, in `AmiriQuran`, 20 x the reading factor, line height 2.0, `look.text`,
   at most **three lines**; the matched words in `look.accent` **and underlined** (`decorationThickness: 2`, twice the font's own underline) so they differ by more than colour; «…» (`look.textSecondary`)
   before and/or after where words were left out; the snippet sits inside a `ReadingScope`, so size times system font is capped at 3x like the other reading
   texts, while the title, the headings and the lines follow the system font only (FR-026);
3. a hairline (`look.line`) between rows.

A tap pops `AyahTarget(ref, page)`. A second tap in the same frame is ignored (the page is shown once).

## Headings, lines and the more-line

Headings use `headingStyle(18, look.heading)` and are `Semantics(header: true)`; lines use `look.textSecondary` 15, centred in the width with 24 dp of padding;
nothing is red and nothing is an error dialog.

## Looks, sizes, targets (FR-024, FR-025, FR-026, SC-008)

| Item | Contract |
|---|---|
| Colours | only `context.look` tokens (Emerald & Gold, Night Reader); the screen is dark in both looks like the index; no colour is written in `lib/search/` |
| Contrast | text >= 4.5:1 (title, snippet, emphasised words `look.accent` on `look.background`, headings, lines, «…»), icons >= 3:1, in both looks and every state |
| Targets | the search icon, the clear button, a result row and «إعادة المحاولة» are at least 48 x 48 px |
| 320 x 640 with a 2x system font | nothing overflows; rows and the field grow; the field stays visible with the keyboard open; the list scrolls |
| Reading size 80 / 100 / 150% | the snippet's Quran words scale by the factor (cap 3x with the system font); the rest does not |
| Matrix | 2 looks x 3 reading sizes x 2 screens (412 x 915; 320 x 640 at 2x) x 3 states (results, «لا توجد نتائج», «جارٍ تجهيز البحث») = **36 combinations**, each without overflow, with the contrast and target checks |

## Semantics (FR-027)

| Element | What a screen reader gets |
|---|---|
| Field | label «ابحث عن سورة أو آية» (a text field) |
| Clear button | «مسح» (a button) |
| Group heading | a header: «السور، عدد النتائج N» / «الآيات، عدد النتائج N» (the visible «السور · N» is excluded) |
| Surah row | a button: «سورة {name}، صفحة N» |
| Ayah row | a button: «سورة {name}، آية N، صفحة N» followed (after a line break) by the snippet's words as shown, without «…» |
| Lines and the button | read as text; «إعادة المحاولة» is a button |
| A change of results | announced **once** after a quiet 700 ms (`SemanticsService.sendAnnouncement`): the two headings' labels, or «لا توجد نتائج»; never per letter |

## The reader after a result (research D4)

| Situation | What the reader does |
|---|---|
| Surah row (or the index) | `jumpTo(page)`: browse mode, no wird moves, last viewed page saved, «اجعلها موضعي» when a wird exists (today's behaviour) |
| Ayah row, another page | `jumpTo(page)`, then the ayah is highlighted with the long-press highlight and brought into view |
| Ayah row, the page already shown | the mode does not change (the go-to-page rule); only the highlight appears (the wird stays in wird mode) |
| Highlight | the words of the ayah **on that page** (an ayah that continues is highlighted on its first page only); the geometry of the page is identical with and without it |
| In view | `fits`: nothing to do; `scrollsVertically` (landscape, or 80-100% taller than the screen): the first word is scrolled to 30% from the top; `pansBothWays` (above 100%): the highlighted words are put inside the viewport with a 24 dp margin (the first word at the right edge when they are wider than the screen); the first line is always in view, all the highlighted part when the screen can hold it; a zoomed page is put back to scale 1 first |
| Cleared | by any touch on the reader, a turn to another page, a screen opening over it, or the long press (which replaces it) |

## Proposals that are the owner's (nothing waits on them)

The default of each is what this file says: the search icon in the index app bar (the owner decided this one), the title «بحث», the field as a full-width field
under the app bar, 20 x the reading factor for the snippet, the underline plus accent colour for matched words (bold is the alternative), the 700 ms announcement
quiet time, the three-line snippet, the 100-row cap (the owner decided this one), and every Arabic string in `search_strings.dart`.
