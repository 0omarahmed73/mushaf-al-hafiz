# Contract: What leaves the app (text, file names, picture, PDF)

## Shared texts (FR-007, FR-010a)

Digits are always `0–9`. `<name>` is the surah name as the Mushaf shows it after «سورة» (`SurahInfo.name`).

**Ayah** (menu «مشاركة»), two lines, no trailing newline, nothing else:

```text
﴿ <the ayah's words joined by single spaces> ﴾
[سورة <name>: <number>]
```
Example: `﴿ ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ ﴾` then `[سورة الفاتحة: 2]`. There is one space inside each bracket pair.
No app name, no link, no tafsir, no translation. The words are exactly the source's, so the hizb sign «۞» and the
sajda sign «۩» that the source writes inside a few words stay where they are (the Mushaf shows them too); nothing is
added, removed, trimmed or normalised.

**Tafsir** (share button of the tafsir view) and **Translation** (its share button): the view's text, a blank
line, the reference line (same format as above), then the source's name on its own line:

```text
<tafsir entry text, or English translation>

[سورة <name>: <number>]
تفسير السعدي            ← or:  Saheeh International
```
The Quran text is not included. For a tafsir entry that covers several ayahs the reference line is for the ayah
that was opened.

## File names (FR-014, FR-015)

| Share | Name | MIME type |
|---|---|---|
| Page picture | `مصحف - صفحة <page>.png` (page 1..604, digits 0–9) | `image/png` |
| Surah PDF | `سورة <name>.pdf` | `application/pdf` |

Characters not allowed in file names (`/ \ : * ? " < > |` and control characters) are replaced by a space and
repeated spaces collapsed; no Mushaf surah name contains one, the rule only guards the builder.

## Page picture (FR-014)

PNG, **2000 × 3000 px** (logical 400 × 600 at pixel ratio 5; at least 1,600 px wide as FR-014 asks, and about 1.08× upscaling at 2× zoom on a
1080-px-wide phone screen, so it stays sharp for SC-004), the app's look: green background, the thin ring, ivory paper,
gold frame, green title banners with gold text, page number in Cairo. No highlight, no bars. Pages 1–2 keep their
8-line layout. Produced only from the page's own data and font.

## Surah PDF (FR-015, FR-016, FR-017)

- One PDF, one page per Mushaf page from `pageOfAyah(surah,1)` to `pageOfAyah(surah, ayahs)`, in order.
- Each PDF page is **A4 portrait, 595.28 × 841.89 pt**, filled edge to edge with the app's green (`AppColors.green`, drawn as a
  vector rectangle). The page image is the app's own page (`PageLook.screen`: green ring, ivory paper, gold frame, green banners with
  gold text; amended 2026-11-20, it used to be a black-and-white print look). It is centred and scaled to fit inside a 10 mm margin
  on every side, keeping its 2 : 3 proportion (so it touches the top and bottom margins and has equal side margins); the image's own
  background is the same green, so the join is invisible.
- The image is 1600 × 2400 px, 8-bit `[/Indexed /DeviceRGB 255 <palette>]` with a 256-colour palette chosen for that page, FlateDecode
  (full RGB would be about 1.5 MB per page, over the 40 MB budget for Al-Baqarah; the indexed size is measured in research D7). Placed
  184.7 mm wide it is about 220 pixels per inch, never below the 200 that FR-015 asks for.
- The PDF holds page images only: no text objects, annotations, attachments or scripts.
- Structure: header, catalog, page tree, per page a page object, a content stream (`q r g b rg 0 0 595.28 841.89 re f Q q W 0 0 H x y cm /Im0 Do Q`) and an
  image XObject, cross-reference table, trailer. Document title = «سورة <name>». No author, no producer, no
  dates, no wirds, positions, bookmarks or notes.

## Temporary files

Written to `<temp>/share/` (created if missing). The folder is emptied when the app starts and before a new
job starts; a file is never deleted right after the share call returns.
