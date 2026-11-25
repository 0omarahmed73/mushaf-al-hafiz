# UI Contract: Ayah Bookmark (feature 013)

Every visible string was proposed by the author and **confirmed by the owner** on 2026-11-25 (Constitution VI, task T048,
«كلها تمام»); they live in `lib/mushaf/ayah_bookmark_strings.dart`. «ملاحظة للآية» is the owner's own wording. `X` is the surah name as the index writes
it, `N` an ayah number, `P` a page, in Western digits. Sizes, weights and colours are the plan's defaults.

## 1. The ayah sheet (opened by the existing long press)

```text
┌ سورة X · آية N ───────────────────────────────┐
│ [مشاركة]                                       │  existing
│ [التفسير]  [الترجمة]  [معاني الكلمات]          │  existing, one row each
│ [🔖 إضافة علامة على الآية]                      │  NEW  key ayah-bookmark
│ [✎ ملاحظة للآية]                               │  NEW  key ayah-note
│ [🗒 عرض الملاحظة]                              │  NEW  key ayah-note-show, only when the ayah has a note (FR-028)
│ الصفحة والسورة  (only when the picture/PDF rows exist, unchanged)
└────────────────────────────────────────────────┘
```

Both rows are `SheetRow`s: full width, at least 52 px high (48 px target met), an ivory card, a button for a screen reader,
colours of the look. Shown only when the sheet was given a port (the reader always gives one). No gesture other than a tap.

| Row | State | Icon | Label (also tooltip text for assistive tech) | Value heard | Line under the label |
|---|---|---|---|---|---|
| bookmark | no bookmark in scope | `Icons.bookmark_add_outlined` | «إضافة علامة على الآية» | «ليس عليها علامة» | none |
| bookmark | has one | `Icons.bookmark_remove_outlined` | «إزالة العلامة من الآية» | «عليها علامة» | none |
| note | no note | `Icons.edit_note` | «ملاحظة للآية» | «ليس عليها ملاحظة» | none |
| note | has a note | `Icons.edit_note` | «ملاحظة للآية» | «عليها ملاحظة» | the start of the note, one line, ellipsis |
| show note (FR-028) | has a note (not empty after trimming) | `Icons.sticky_note_2_outlined` | «عرض الملاحظة» | none | none |

The state is read synchronously from the reader's in-memory rows when the sheet builds, so the first frame already shows it
(research D5, D8); every tap of the bookmark row and every save closes the sheet, so it is read again the next time.

**Bookmark tap**: the sheet closes; the reader shows the message of section 3. **Note tap**: the note field of section 2 opens
over the sheet. **Show-note tap**: the note view of section 2b opens over the sheet.

## 2. The note field

```text
┌ ملاحظة على سورة X · آية N ───────────────┐
│ الملاحظة                                  │  label; the field opens with the current note, focus in it
│ [ ........................ ]  (1 to 3 lines, 200 characters max, no counter)
│ ستُضاف علامة على الآية مع الملاحظة          │  OR  اترك الحقل فارغًا لإزالة الملاحظة وإبقاء العلامة
│                         [إلغاء]  [حفظ]     │  two text buttons, 48 px high
└────────────────────────────────────────────┘
```

| Action | Result |
|---|---|
| «حفظ» | the four cases of data-model.md; the dialog and the sheet close; the message of section 3 (none for case d) |
| «إلغاء», the back gesture, a tap outside | nothing is written; the dialog closes; the ayah sheet stays open |
| save fails | the dialog stays open with the typed text and a line «تعذّر الحفظ، حاول مرة أخرى» under the field |

The first line under the field is chosen by whether the ayah has a bookmark of the scope when the dialog opens. The dialog is
scrollable: on a narrow phone with a large system font the title scrolls with the field and the two buttons stay reachable
(T042).

## 2b. The note view (FR-028)

An `AlertDialog`, scrollable, titled «ملاحظة على سورة X · آية N», with the whole note (no line limit, key
`ayah-note-view-text`) and two text buttons of 48 px: «إغلاق» (and the back gesture, a tap outside) returns to the open
sheet; «تعديل» opens the note field of section 2, prefilled, and goes on as from the note row. Reading writes nothing.

## 3. The message (floating SnackBar, like feature 006's)

Above the bottom bar (bottom margin 68 + 8 when the bars are visible, 8 when hidden), the usual 4 s, action «تراجع», replaced
by the next message. «تراجع» undoes exactly that tap or save and only while the message is shown.

| After | Message |
|---|---|
| bookmark added | «تمت إضافة علامة على سورة X · آية N» |
| bookmark removed (its note goes with it) | «تمت إزالة العلامة من سورة X · آية N» |
| note creates the bookmark | «تمت إضافة علامة مع ملاحظة على سورة X · آية N» |
| note replaces another | «تم حفظ الملاحظة على سورة X · آية N» |
| note cleared | «تمت إزالة الملاحظة من سورة X · آية N» |
| note save with no bookmark and an empty note, a cancel | no message |

## 4. The list «علامات»

```text
page row (as today):   ص P                          [wird or عامة]
                       note (3 lines max)
ayah row (new):  [📖]  سورة X · آية N                 [wird or عامة]
                       ص P
                       note (3 lines max, same style as a page note)
```

- The ayah row has the leading `Icons.auto_stories_outlined` (22 px) that a page row does not have, and the word «آية» in its
  title and semantics label «علامة على سورة X آية N، صفحة P، ثم اسم الورد أو عامة». Page rows are unchanged (no icon).
- Same list, same order (newest first), same swipe to delete, same card colours, same tag, rows at least 56 px and growing
  with the system font; a long surah name wraps or shrinks, it never pushes «ص P» out; the owner tag of an ayah row may
  shrink, and the tag of a page row takes at most half the row (T042), so a long wird name cannot hide «ص P» either.
- A tap on an ayah row closes the sheet and shows the page where the ayah begins with its words highlighted (feature 011's
  highlight) and brought into view; the first touch clears the highlight. A tap on a page row does what it does today.
- The «إضافة علامة للصفحة N» button and its note dialog are unchanged.

## 5. The tint on the Mushaf page

- A background wash behind the words (and the end marker) of each ayah that has an ayah bookmark of the current scope, drawn by
  the same word decoration the highlight uses (radius 4). It adds no size: every rectangle is identical with and without it.
- Colours (tokens of `PageLook`, measured in research D6): Emerald & Gold `0x290F766E` (a light green-teal on the ivory
  paper); Night Reader `0x24E4C877` (a soft gold on the dark page). Each differs in hue by more than 40 degrees from the
  highlight of its look; the page text on it keeps 11.7:1 or more.
- While an ayah is highlighted (long press, search result, opened from the list) its words show the highlight in place of the
  tint, unchanged from before this feature; the tint returns when the highlight ends.
- Each page tints the bookmarked ayah's words drawn on it (no ayah crosses a page in this edition). A page bookmark tints nothing. Another scope's
  bookmarks tint nothing. The setting off tints nothing.
- It appears in the first frame after the write's answer and goes in the first frame after a removal, an undo, a restore, a
  wird switch or a wird deletion, and after a delete in «علامات» in the first frame after that sheet closes (the page behind
  keeps it while the sheet is open; research D5). It is not in the shared page picture or the surah PDF.

## 6. Settings

One `SwitchListTile` (key `ayah-tint-switch`) after the text-size tile, in the look's colours, 48 px target, no overflow at 320
dp with a 2x font:

| | |
|---|---|
| Title | «تظليل الآيات التي عليها علامة» |
| Line under it | «ظلّ خفيف خلف كل آية عليها علامة في صفحة المصحف» |
| Default | on; saved at once; the reader follows live; restored with a backup |

## 7. The top-bar icon of feature 006 (unchanged look, fixed meaning)

Same place, glyphs, colours, tooltip, messages and 48 px target. Its state and its tap concern page bookmarks only; an ayah
bookmark on the page does not fill it and is never removed by it (FR-011).

## Accessibility summary

Every new control is a button with a label that names the action and the ayah where there is one, a value for its state, and a
48 px target; the note field is a labelled text field; the list row announces «آية»; nothing relies on colour alone except the
tint itself, whose meaning is also in the ayah sheet's state and in the list. Contrast at least 4.5:1 for text and icons in
both looks; everything follows a look change at once and fits at 80, 100 and 150 percent and at 320 dp with a 2x font.
