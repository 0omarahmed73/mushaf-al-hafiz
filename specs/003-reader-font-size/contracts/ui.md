# UI contract (feature 003)

Arabic strings below were **confirmed by the owner on 2026-11-20** (Constitution VI): the row title, the value, the note, «معاينة», «الحجم الافتراضي» and the two samples, as written. Digits 0–9.

## Settings row (between the reminders and the backup sections)

```
┌───────────────────────────────────────────────┐
│ حجم الخط                                120%  │   title (heading font) and the value
│ ○────────────●───────○ (marks at 80..150)     │   Slider, 8 stops, 100% marked
│ ┌ معاينة ──────────────────────────────────┐ │
│ │ نص عربي تجريبي بحجم التفسير …             │ │   preview: Arabic then English,
│ │ Sample English text at the translation …  │ │   same styles as the ayah views
│ └──────────────────────────────────────────┘ │
│ يُطبَّق على التفسير والترجمة ومعاني الكلمات    │   note
│ وعلى صفحة المصحف                              │
│ [ الحجم الافتراضي ]                           │   reset (48 px, off at 100%)
└───────────────────────────────────────────────┘
```

| Element | String | Notes |
|---|---|---|
| Row title | «حجم الخط» | key `text-size-title` |
| Value | «120%» | key `text-size-value`; Slider semantics label «حجم الخط، 120%» |
| Slider | — | key `text-size-slider`; min 80, max 150, 7 divisions |
| Preview label | «معاينة» | key `text-size-preview` |
| Arabic sample | «هذه فقرة تجريبية تُعرض بحجم نص التفسير، لترى الحجم قبل أن تعود إلى القراءة.» | not Quran text |
| English sample | «This is a sample sentence shown at the size of the translation.» | LTR |
| Note | «يُطبَّق على التفسير والترجمة ومعاني الكلمات وعلى صفحة المصحف» | |
| Reset | «الحجم الافتراضي» | key `text-size-reset`, disabled at 100% |

## Reader and ayah menu (no new text)

- The Mushaf page at a size above the viewport: one finger moves it up, down and sideways; a swipe from the
  left edge to the right brings the next page, from the right edge to the left the previous page. The page that
  comes in starts at its top and right side.
- The ayah views show their panel text at the chosen size; their titles, source lines under the titles and the
  menu rows keep today's size.
