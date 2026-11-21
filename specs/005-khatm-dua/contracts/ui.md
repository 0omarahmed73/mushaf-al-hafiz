# Contract: what the reader sees (feature 005)

The owner confirmed the Arabic strings and the wording on 2026-11-21 (Constitution VI, task T011).

## The gesture

| Where | What | Result |
|---|---|---|
| Page 604, normal size | finger moves left to right, forward distance ≥ 48 px, or ≥ 16 px with release speed ≥ 300 px/s | the dua screen opens |
| Page 604, wide page (text size above what fits) | a swipe from the side edge that would turn the page (the existing edge turn) | the dua screen opens |
| Page 604, zoomed in | any drag | the page pans; nothing opens |
| Pages 1 to 603 | the same swipe | the next page, as today |
| Page 604 reached by index, go-to-page, bookmark, wird, notification, restart | nothing | nothing opens |
| Dua already open | any gesture | nothing opens a second one |

## The screen «دعاء ختم القرآن»

```text
┌──────────────────────────────┐
│ ←  دعاء ختم القرآن           │  AppBar: back arrow «رجوع», title (heading)
├──────────────────────────────┤
│ دعاء وليس من نص القرآن       │  label, 12 px, quiet colour, directly under the title
│ ┌──────────────────────────┐ │
│ │ اللَّهُمَّ ارْحَمْنِي …    │ │  the dua: interface font, the owner's reading size,
│ │ …                        │ │  panel in the look's card colours
│ └──────────────────────────┘ │
│        [   آمين   ]          │  last item of the scrolling content, ≥ 52 px high
└──────────────────────────────┘
```

| Action | Result |
|---|---|
| tap «آمين» | the screen closes, page 1 is shown at once, the saved position becomes 1 by the ordinary page-change rule |
| back arrow, system back | the screen closes, page 604 stays, position unchanged |
| rotate, app to background and back | the screen stays as it was |
| restart while open | the reader opens on the saved position (604); the dua is not restored |

Unreadable text: the panel is replaced by «تعذّر تحميل نص الدعاء» (key `khatm-unavailable`); «آمين» and back work.

Looks: every colour is a token of `context.look` (Emerald & Gold: ivory panel on the deep green; Night Reader:
charcoal panel on near-black). Text 4.5:1, large text and icons 3:1, targets ≥ 48 px, nothing overflows at 320 dp
with a 2x system font; the text scrolls and «آمين» is reached by scrolling.

Screen reader: the AppBar title is a heading, the back arrow a button «رجوع», «آمين» a button, the paragraphs are
read in order.

## «حول التطبيق»

One more credit row: «دعاء ختم القرآن» / «الدعاء المتعارف عليه في ختام المصاحف» / «لا يوجد نص ثابت عن النبي ﷺ؛
الصياغة متداولة» (the owner's shorter sentence, without the names of the sites).
