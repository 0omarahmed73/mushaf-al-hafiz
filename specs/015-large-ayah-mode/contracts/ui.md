# Contract: UI (feature 015)

Every Arabic string here is a proposal until the owner confirms it (Principle VI).

## Settings (top of the list)

- Switch tile: title «الآيات الكبيرة», subtitle «آية أو آيتان أو ثلاث في الصفحة، بخط كبير».
- Under it, shown only while the switch is on:
  - «عدد الآيات في الصفحة»: three choices «آية واحدة»، «آيتان»، «ثلاث آيات» (default «آية واحدة»).
  - «حجم الخط»: three choices «كبير»، «أكبر»، «أكبر جدًا» (default «كبير»), with a preview of the basmala at the chosen
    size (Amiri Quran, the basmala's own font in the app).
- Turning the switch on returns to the reader in the mode.

## A screen in the mode

- Header line (UI font, the look's ink colour, 48 px high): surah name, ayah numbers, page number:
  «البقرة ٢٥٥ · صفحة ٤٢»، «البقرة ٥–٦ · صفحة ٣»، and for a split ayah «البقرة ٢٨٢ (١ من ٣) · صفحة ٤٨».
- Body: the opening of a surah (its title banner and basmala, in the look's banner style) when the screen opens one; then
  the ayat, each from a new line, right-aligned, in the page's QCF glyphs at the chosen size.
- A part that goes on ends with «تتبع ←» under its last line (the arrow shows the swipe direction).
- Tap: shows or hides the bars, as in the Mushaf. Long press on any word: the ayah is highlighted and the ayah sheet opens.
- Tinted ayat (feature 013) as on the Mushaf page, with the same switch.

## Bars in the mode

- The same top and bottom bars and today panel. The button «المصحف» (icon `menu_book`, tooltip «الرجوع إلى المصحف»),
  48 px high, sits at the end (left) of the view's own header line, which keeps 112 px free for it, so it is always on
  screen even with the bars hidden (changed at implementation, T018: the top bar had no room for it). It turns the view
  off and shows the Mushaf page of the screen.
- The page bookmark icon and «علامات» act on the screen's page.

## Looks

- Emerald & Gold and Night colours from `PageLook`; contrast at least 4.5:1 for the header and the «تتبع» line (feature 004
  walk). Nothing overflows at 320 dp portrait or in landscape.
