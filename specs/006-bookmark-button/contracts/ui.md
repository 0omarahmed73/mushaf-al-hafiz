# Contract: the icon, its states and the message

## Place

```text
reader top bar (84 px, unchanged)
┌────────────────────────────────────────────┐
│ سورة …                    جزء ٧ · حزب ١٣ · ربع ٢ │  first row (unchanged)
│ [wird pill] [اليوم chip]  (اجعلها موضعي)   [🔖] │  second row; the icon is the far-left 48 x 48
└────────────────────────────────────────────┘
```

- The icon is at the end edge of the RTL layout (the left of the screen), 10 px from the edge, its centre on the
  second row's centre, directly under the juz text.
- The second row has 48 px of room reserved at its end, so «اجعلها موضعي», the pill and the chip never touch it.
- The top bar keeps 84 px and the page keeps its rectangle (research D1, D9).

## States

| State | Icon | Colour | Tooltip and label | Semantics value |
|---|---|---|---|---|
| Page has no bookmark of the scope | `Icons.bookmark_add_outlined` | `look.textSecondary` | «إضافة علامة للصفحة N» | «ليس عليها علامة» |
| Page has a bookmark of the scope | `Icons.bookmark_added` | `look.accent` | «إزالة العلامة من الصفحة N» | «عليها علامة» |

Semantics: a button with a tap action. Target ≥ 48 × 48. Contrast ≥ 4.5:1 against `look.background` in both looks.

## The tap

| Before | After the tap | Message (with «تراجع») |
|---|---|---|
| no bookmark of the scope | one bookmark, no note; icon filled | «تمت إضافة علامة للصفحة N» |
| bookmark(s) of the scope | all of them removed; icon outlined | «تمت إزالة العلامة من الصفحة N» |

Nothing else changes: the page does not turn, and the wird position, khatma count, today's portions, reminders,
last viewed page and settings stay as they were (FR-008).

## The message

A floating SnackBar, default length, above the bottom bar (bottom margin 68 + 8 when the bars are visible, 8 when
hidden), replaced by the next tap's message. «تراجع» undoes exactly that tap and only while the message is shown.
