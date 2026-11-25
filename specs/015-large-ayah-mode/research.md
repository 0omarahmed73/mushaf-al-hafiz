# Research: Large Ayah Mode

Feature 015, plan phase 0, 2026-11-25. Each decision: what is chosen, why, and what else was weighed. Facts measured in the
repository are marked "Measured".

## Measured

- No ayah crosses a page in this edition (feature 013, research "Correction 2026-11-26"); 2:282 fills page 48 alone.
- 6,236 ayat; 1 to 128 words; 534 over 25 words, 99 over 40 words (count over `assets/ayah/text`).
- The Mushaf page's font size is `min(width / 16.2, lineHeight / 1.8)` (`lib/mushaf/mushaf_page.dart`, `kMaxLineEm`,
  `kLineBoxEm`). On a 360 dp phone the width is 348 dp, so about 21.5 px at 100 %.
- A page's words are `MushafWord`s with their glyph in the page font `qpc_p<page>` (`PageFontLoader`), and the end marker
  of each ayah is its last word (`PageData.endMarkerIds`). The surah title (Reem Kufi) and the basmala (Amiri Quran, the
  fixed string `kBasmallah`) are line types of the page, not words.
- The ayah sheet is opened by `_openAyahMenu(PageData data, MushafWord word)` in `lib/mushaf/reader_screen.dart`; it needs
  only the page data and the pressed word, so the mode can call it unchanged.
- Settings are a key/value table (`Settings`); the backup writes and restores every key (`lib/backup/backup_service.dart`
  lines 79-170), so new keys travel with no format change.
- The position rules live in `ReaderController.onPageShown(page)` and `jumpTo(page)`; both take a page.

## D1. Glyphs and line wrapping

**Decision**: each word is drawn as a `Text` of its glyph in its page font (`qpc_p<page>`), as the Mushaf page does, laid
out right to left on lines of the screen's width with a fixed gap between words; lines are right-aligned, not justified.
Each ayah begins on a new line. A word is never broken (a glyph is one word).

**Rationale**: owner's choice (Madinah glyphs) and constitution 2.2.0 Principle I. Justifying short lines of 5 or 6 large
words leaves wide uneven gaps; right alignment reads more calmly. Starting each ayah on its own line makes "1, 2 or 3 ayat"
visible as such and makes the screen fit test (D3) a matter of whole lines.

**Alternatives**: justified lines (rejected, gaps); ayat running on in one paragraph as in the Mushaf (rejected: the reader
asked for ayat per screen, and a split ayah would start mid-line).

## D2. Size

**Decision**: the mode's font size is `factor × (shortest side − 2 × 16 dp) / 16.2`, so it does not change with rotation,
with three steps: 2.0 (default), 2.5 and 3.0. A box too short for 3 lines at that size (a phone on its side at the largest
step) gets the size that holds 3 lines, so a title, a basmala and a line of words always fit (T014). On a 360 dp phone that is about 40, 50 and 60 px, about 5 to 7, 4 to 5 and 3
to 4 words a line. The line height is 1.8 em (`kLineBoxEm`). The phone's text scale is switched off for the screen
(`MediaQuery.withNoTextScaling`), as on the Mushaf page; the feature 003 setting is not read.

**Rationale**: SC-002 asks for at least twice the Mushaf's letter height at 100 %; 2.0 gives it on every phone width
because both are proportional to the width. Three steps are enough for a weak eye and keep the setting simple. Using the
shortest side keeps the cut of a long ayah stable when the phone turns (only the number of lines a screen holds changes).

**Alternatives**: reuse the feature 003 slider (rejected: its top step, 150 %, is far too small); a free slider (rejected:
harder for an elderly reader; three named steps are easier).

## D3. Making the screens (pure logic)

**Decision**: a pure function in `lib/large_ayah/screen_layout.dart` takes one page's ayat (each a list of word widths in
px at the chosen size), the line width, the number of lines a screen holds (height of the text area / line height, after
the surah title and basmala lines when the screen opens a surah), and N (1, 2 or 3), and returns that page's screens:

1. Wrap each ayah greedily into lines (a word goes to the next line when it does not fit; a word wider than the line,
   which no QCF glyph is at these sizes, gets a line of its own and is scaled down to fit, so no word is ever off screen).
2. Fill screens in order: a screen takes up to N whole ayat while their lines fit. A screen always takes at least one ayah.
3. An ayah whose lines alone exceed one screen is split into parts of whole lines, each part a screen of its own; no other
   ayah shares them (FR-019).
4. The opening lines of a surah (its title, and the basmala when the page data has one) belong to the screen of the first
   ayah after them and count as lines.
5. Measured at implementation (T008): 18 pages end with the next surah's title on their last line (76, 207, 331, 341, 349,
   366, 376, 414, 417, 445, 452, 498, 506, 525, 548, 555, 557, 584). That title stays on its own page, at the end of the
   page's last screen, as on paper; when there is no room, the page's last ayah (or the last line of a split one) moves to
   a screen of its own with the title.

The result is a list of `LargeScreen` values (data-model.md). The function knows nothing about fonts or widgets; the widths
come from a measuring step (D4). Tests feed it plain numbers.

**Rationale**: Principle IX (pure logic apart from UI, unit-tested); SC-001 can then be checked over the whole Mushaf with
stand-in widths in a plain test, and with real widths for chosen pages.

**Alternatives**: let a scroll view lay text out and cut it by pixels (rejected: cannot be tested without widgets, and a
cut could fall inside a line).

## D4. Measuring the words

**Decision**: a `WordMeasurer` lays each glyph out with a `TextPainter` in its page font at the size and returns its width;
results are kept per (page, size) in a small cache (the last 8 pages). Measuring a page needs its font loaded
(`PageFontLoader.ensure`), the same wait as the Mushaf page; until then the screen shows the same loading look the Mushaf
uses (Constitution VIII: a page is shown only when its own font is ready).

**Rationale**: about 140 words a page; laying out 140 single glyphs takes a few milliseconds, once per page and size.

**Alternatives**: precomputed widths in an asset (rejected: depends on the size and adds data; not needed for speed).

## D5. The pager

**Decision** (as built): an anchored pager. While a change of the box, the count or the size is being laid out again, the
old screens are not drawn in the new box (blank paper for that moment), and if the reader has not moved since the last
anchoring, the pager comes back to the ayah it was anchored at (so 1 → 2 → 1 ayat returns to the same screen). The design:
an anchored pager. The mode keeps a `ScreenRef` (page, index of the screen in its page) for the screen shown;
a `PageView` with a virtual index (`reverse: true` in an LTR box, as the Mushaf pager, so the next screen comes in from the
left) maps an index relative to the anchor to a `ScreenRef` by walking screen by screen through `ScreenNavigator`
(next/previous: the next screen of the same page, or the first screen of the next page, or the last of the previous). A
jump, a change of N or of the size, or a rotation re-anchors the pager at the screen that holds the first ayah of the screen
shown before (FR-007). The start is bounded by a page physics that stops at the screen of 1:1 once it is known, and the end
by the last screen of page 604, where a forward swipe goes to the khatm supplication through the existing `LastPageSwipe`.

**Rationale**: the number of screens of the whole Mushaf is not known without measuring all 604 pages (and loading their
fonts, 153 MB); the pager only ever needs the screens next to the one shown.

**Alternatives**: measure everything at start (rejected: seconds of work and every font loaded); one pager of pages with an
inner pager of screens (rejected: two nested swipes in the same direction fight each other).

## D6. Position, wirds and the remembered screen

**Decision**: whenever a screen settles, the mode calls `ReaderController.onPageShown(screen.page)`, so the wird and
browse rules are those of the Mushaf with no new rule. The first ayah of the shown screen is also stored as the setting
`largeAyahAt` (`"surah:ayah"`). On start with the mode on, the mode opens at that ayah's screen if that ayah is on the
controller's page, otherwise at the first screen of the controller's page (the wird or a jump moved the position).

**Rationale**: FR-012 with no change to the position data; the extra setting only keeps the reader in the middle of a page
across a restart (an elderly reader would otherwise go back to the top of a page with many ayat).

**Alternatives**: an ayah-level position in the wird tables (rejected: changes the data model of features 001 and 006 for a
view).

## D7. Where the mode lives in the reader

**Decision**: new code in `lib/large_ayah/` (layout, navigator, measurer, settings, the screen widget, the pager). The reader
screen shows either its Mushaf pager or the large-ayah pager in the same place, with the same top bar, bottom bar, today
panel, ayah sheet, highlight and tint. The page item, `PageViewport` and `MushafPage` are not touched
(`lib/mushaf/mushaf_page.dart` is not edited). Turning the mode on and off: a switch tile at the top of the Settings list
(«الآيات الكبيرة», with its count and size choices under it), and in the mode a button in the top bar that returns to the
Mushaf («المصحف»). From the Mushaf that is 2 taps (the menu, the switch), back is 1 (SC-003).

**Rationale**: keeps the 1,335-line reader screen from growing much; the mode reuses everything that already works.

**Alternatives**: a separate route on top of the reader (rejected: the bars, the today panel and the controller would have
to be duplicated, and Principle II wants the app to open on the mode when left on, which a pushed route makes awkward).

## D8. Settings and backup

**Decision**: four keys in the `Settings` table: `largeAyah` (`'true'`/`'false'`, off when absent), `largeAyahCount`
(`'1'`, `'2'`, `'3'`; 1 when absent or unusable), `largeAyahSize` (`'1'`, `'2'`, `'3'`; 1 when absent or unusable),
`largeAyahAt` (`"surah:ayah"`, ignored when unusable). One `LargeAyahSettings` notifier, in the pattern of
`TextSizeSettings` and `AyahTintSettings` (parse never throws, saved at once, `reload` after a restored backup). The backup
needs no change (it carries every key).

**Rationale**: FR-006; same pattern as features 003 and 013.

## D9. What a screen shows besides the ayat

**Decision**: a header line in the UI font: the surah name, the ayah numbers (one, a range, or one with «تتبع» for a part
that goes on), and the page number, e.g. «البقرة ٢٥٥ · صفحة ٤٢». The proposed strings are in contracts/ui.md and stay
proposals until the owner confirms them.

## D10. Tests and checks

**Decision**:

- Pure: `screen_layout_test.dart` (wrapping, N = 1..3, fit, split, surah openings, page bounds),
  `screen_navigator_test.dart` (next/previous across pages, the ends), `large_ayah_settings_test.dart` (parse rules).
- Whole Mushaf (SC-001): a test reads the 604 page files and, with a stand-in width per word (1 unit, and a second run with
  widths from the glyph's character count), checks for N = 1, 2, 3 and two screen heights that the screens hold every word
  of every ayah exactly once and in order, never two pages, and every part of a split ayah in order.
- Widgets, with the real QCF fonts loaded as `test/render/` and `test/ayah_bookmarks/` already do: mode on/off and its
  start screen, swipe direction, regrouping, the sheet on long press, the tint, both looks, the restart anchor, a jump and a
  search target, the khatm swipe, 2:282 at 320 dp with no overflow and no scrolling (SC-005), the letter size (SC-002).
- The backup round-trip of the four keys.
- Real phone: quickstart.md (Principle IX), including the owner's own comfort check (SC-006).
