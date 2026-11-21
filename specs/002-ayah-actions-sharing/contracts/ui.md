# Contract: Gestures, sheet layout and Arabic strings

Strings marked **spec** are written in the spec by the owner. Strings marked **proposed** are mine, written in
plain Arabic (not translated); the owner confirms or rewrites them when reviewing this file (Constitution VI).

## Gestures (FR-001, FR-002, FR-004, FR-006)

| Gesture | Result |
|---|---|
| Hold ≥ 500 ms on a word of an ayah (including its end number), finger within the touch slop | highlight the ayah's words on the page, medium haptic tick, open the sheet |
| Short tap anywhere on the page | toggles the bars (unchanged) |
| Horizontal swipe, pan while zoomed, two-finger pinch | as today; never opens a sheet, even if it started on a word |
| Hold on banner, basmallah line (except Al-Fatiha's, which is ayah 1:1), empty area, page number, bar, loading page | nothing |
| Second hold while the sheet is open | nothing (the sheet is modal) |
| Close: swipe down, tap outside, system back at the menu | highlight cleared; same page, zoom and position |

Numbers: the hold time is Flutter's `kLongPressTimeout` (500 ms) and the movement tolerance its `kTouchSlop` (18 logical px), the
platform defaults the rest of the app already uses; the tick is `HapticFeedback.mediumImpact()`.

Highlight colour is the existing `MushafPage.highlightColor` (translucent amber). It is shown only while the sheet is open.

## Sheet (FR-003, FR-005, FR-009, FR-010, FR-010a, FR-012)

```text
┌──────────────────────────────┐
│            ───                │  drag handle
│  سورة البقرة · آية 255        │  header, Reem Kufi            (spec)
├──────────────────────────────┤
│ مشاركة                        │  share icon        rows ≥ 48 px, ivory cards
│ التفسير                       │                                   (spec)
│ الترجمة                       │
│ معاني الكلمات                 │
│ ── الصفحة والسورة ──          │  proposed group label
│ مشاركة الصفحة كصورة           │                                   (spec)
│ مشاركة السورة PDF             │                                   (spec)
└──────────────────────────────┘
```

Detail views replace the menu inside the same sheet: a back arrow (system back also returns to the menu), the title,
and for tafsir and translation a share button at the end of the header. The body is an ivory panel that carries
its own label; the Quran words are not repeated inside it. Long text scrolls inside the panel. A very long
tafsir stays smooth (a single `Text` per paragraph in a `ListView`).

| View | Title / label | Body |
|---|---|---|
| Tafsir | «تفسير السعدي» (spec) with the small line «شرح بشري وليس من نص القرآن» (proposed) | entry text; if `from != to` a line «يشمل التفسير الآيات 6–7» (spec example; digits 0–9, en dash); if `inherited`, above the text the note «لا يوجد في هذا النص تعليق مستقل على هذه الآية، وهذا تفسير الآيات 106» (proposed; the number is the entry's `from`–`to`) |
| Translation | «الترجمة» with «Saheeh International» (spec) and the same small line | English text, `Directionality.ltr`, left aligned |
| Meanings | «معاني الكلمات» (spec) with the source of each entry, e.g. «ابن الهائم · التبيان في تفسير غريب القرآن» (proposed form) | one row per entry: the word in bold, its meaning below; if none: «لا توجد كلمات غريبة في هذه الآية» (spec) |

## PDF progress strip (FR-016)

Non-modal strip above the bottom bar, ivory with gold border, 56 px high, the reader stays usable:

| State | Content |
|---|---|
| preparing | «جارٍ تجهيز سورة البقرة» (proposed) · «صفحة 12 من 48» (spec) · button «إلغاء» (spec) |
| ready, app in background when it finished | «تم تجهيز الملف» (proposed) · button «مشاركة» |
| failed | the failure message below · button «إغلاق» (proposed) |

While a job runs, the menu's «مشاركة السورة PDF» is disabled and its subtitle says «يتم تجهيز ملف الآن» (proposed).

## Messages (FR-018, SC-007; shown in a snackbar, the reader keeps working)

| Case | Message (proposed) |
|---|---|
| Not enough space | «لا توجد مساحة كافية على الهاتف لتجهيز الملف» |
| Render or write failed | «تعذّر تجهيز الملف» |
| Share failed | «تعذّرت المشاركة» |
| Share cancelled by the user | no message |
| Picture while preparing (over ~0.5 s) | «جارٍ تجهيز الصورة» in a snackbar, replaced by the share sheet |

## About credits (FR-020, SC-008)

A «مصادر» entry for each source in `sources.json`, with name, provider, link and version (proposed wording; the About screen keeps its
existing statement «النص القرآني لم يُعدَّل»):

| Credit line | Provider and link | Version shown |
|---|---|---|
| «تفسير السعدي — تيسير الكريم الرحمن» | QUL (Tarteel), qul.tarteel.ai | file date 2025-05-26 |
| «ترجمة Saheeh International» | Tanzil Project, tanzil.net/trans | 2011-04-24 |
| «معاني الكلمات — ابن الهائم (التبيان) وابن الجوزي (تذكرة الأريب)» | الموسوعة القرآنية Quranpedia, quranpedia.net | 2026-11-14 |
| «كلمات النص القرآني» | QUL (Tarteel), KFGQPC Hafs, qul.tarteel.ai | file date 2025-05-28 |

A detail view that cannot load its data (a build bug) shows «تعذّر تحميل هذا القسم» (proposed) and the reader keeps working.

## Accessibility

Touch targets ≥ 44 px; each row and button has a semantic label equal to its text; the highlighted state is also
announced («تم تحديد الآية 255») (proposed); contrast of text on ivory is the existing app palette.
