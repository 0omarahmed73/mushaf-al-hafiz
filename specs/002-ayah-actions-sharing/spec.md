# Feature Specification: Ayah Actions and Sharing

**Feature Branch**: `002-ayah-actions-sharing`

**Created**: 2026-11-20

**Status**: Draft

**Input**: User description: "Long-press any ayah to open its menu: share it, read its tafsir
(al-Sa'di), read an English translation (Saheeh International), see the meanings of its difficult
(gharib) words. Also share the current page as an ordinary picture and a whole surah as a PDF.
Everything except handing a file or text to another app works offline."

## Clarifications

### Session 2026-11-20

- Q: Which tafsir? → A: Tafsir al-Sa'di (Arabic), bundled in the app.
- Q: Which translation language? → A: English only, Saheeh International, bundled in the app.
- Q: May the English translation be added although the constitution listed translations as out of
  scope? → A: Yes. The owner approved amending the constitution (1.1.0, 2026-11-20) to allow this one
  translation only.
- Q: Where do the gharib word meanings come from? → A: Not chosen yet. The planning research picks the
  best free, offline, traceable source and shows it to the owner before it is relied on (Constitution V).
- Q: How does the user open an ayah's menu without losing the tap that shows or hides the bars? → A: A
  long press on the ayah opens the menu; an ordinary tap keeps toggling the bars exactly as today.
- Q: When the user shares an ayah, what should the shared text contain? → A: The Arabic text and its
  reference only. The tafsir view and the translation view each have their own share button for their
  own text.
- Q: Should the page picture and the PDF look like the app or be made for printing? → A: ~~The
  picture looks exactly like the app's page (ivory paper, gold frame, green title banners). The PDF is
  white paper with black text and thin black frames and banner outlines, made for printing.~~
  **Changed by the owner on 2026-11-20, after seeing the first build on the phone:** both the picture
  and the PDF look like the app's Emerald and Gold page, in colour, «beautiful and cheerful»; the
  black-and-white print look is dropped. The owner also found the picture's colours faded and unlike
  the page in the app, so the picture MUST match the app's colours (FR-014, SC-010).
- Q: What page size should the PDF use? → A: A4 portrait, with the Mushaf page centred inside it,
  scaled to fit with even margins.
- Q: Should the shared file names be Arabic or Latin? → A: Arabic: «سورة البقرة.pdf» for a surah and
  «مصحف - صفحة 293.png» for a page.
- Q: What does the tafsir view show for an ayah that the bundled Tafsir al-Sa'di text does not comment on separately
  (59 ayahs, found while planning)? → A: The nearest earlier entry of the same surah, with a note that this ayah
  has no commentary of its own in this text (FR-009a). Approved with the plan fixes on 2026-11-20.
- Q: How should a shared ayah look? → A: The ayah's exact text inside ﴿ ﴾ on the first line, and on the
  next line the reference «[سورة <name>: <number>]» with the digits the app uses (0–9), for example
  «﴿ ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ ﴾» then «[سورة الفاتحة: 2]».

## User Scenarios & Testing *(mandatory)*

One person reads the Madinah Mushaf on their phone and wants to understand and share what they read
without leaving the page. Today the reader only shows pages. This feature adds, on top of the page
and never in front of it (Constitution II): a menu for any ayah (share, tafsir, translation, word
meanings) and two ways to share the Mushaf itself, as a picture of a page and as a PDF of a surah.

### User Story 1 - Open an ayah's menu and share the ayah (Priority: P1)

The user holds a finger on any ayah. The whole ayah is highlighted and a bottom sheet opens showing
which ayah it is («سورة البقرة · آية 255») and the actions. The first action, «مشاركة», hands the
ayah's exact text and its reference to another app through the phone's share sheet. Closing the
sheet returns to the same page with the highlight gone.

**Why this priority**: The menu is the doorway to everything else in this feature, and sharing the
ayah is the smallest complete use of it. It also proves the hardest interaction: telling a long
press on an ayah from a tap, a swipe and a zoom.

**Independent Test**: On any page, hold a finger on a word: the ayah is highlighted and the menu opens
with the right reference. Tap «مشاركة»: the share sheet offers the exact ayah text with its
reference. Close the sheet: nothing else has changed.

**Acceptance Scenarios**:

1. **Given** page 42 is shown, **When** the user holds a finger on any word of ayah 2:255, **Then** every
   word of that ayah on the page is highlighted and a sheet opens headed «سورة البقرة · آية 255».
2. **Given** the sheet is open, **When** the user taps «مشاركة», **Then** the share sheet offers two
   lines: the ayah's words exactly as in the Mushaf, in order, inside ﴿ ﴾, then the reference
   «[سورة البقرة: 255]», and nothing else (no app name, no user data).
3. **Given** the sheet is open, **When** the user closes it (swipe down or tap outside), **Then** the
   highlight disappears and the page, zoom and reading position are exactly as before.
4. **Given** any page, **When** the user taps (short press) a word, **Then** the top and bottom bars
   toggle as today and no menu opens.
5. **Given** any page, **When** the user swipes to turn the page or pinches to zoom, **Then** it
   works as today and no menu opens, even if the finger started on a word.
6. **Given** the user holds a finger on the surah title banner, the basmallah line, an empty area
   or the page number, **Then** no menu opens.
7. **Given** an ayah that starts on one page and ends on the next, **When** the user holds a finger
   on its part on the current page, **Then** the menu is for the whole ayah and the part on the
   current page is highlighted.

---

### User Story 2 - Understand the ayah: tafsir and translation (Priority: P2)

From the ayah's menu the user reads Tafsir al-Sa'di for that ayah and its English translation
(Saheeh International), each in its own clearly labelled view, and comes back to the menu or the page.

**Why this priority**: Understanding what is read is the reason the owner asked for the menu; it
needs the menu (Story 1) and bundled text.

**Independent Test**: Open the menu on ayah 2:255, open «التفسير» and «الترجمة»: the tafsir entry
for Ayat al-Kursi and its English translation appear, each labelled with its source.

**Acceptance Scenarios**:

1. **Given** the menu for an ayah, **When** the user taps «التفسير», **Then** Tafsir al-Sa'di for that
   ayah is shown, labelled «تفسير السعدي», scrollable when long.
2. **Given** an ayah whose tafsir is one shared entry for several ayahs, **When** the user opens
   «التفسير», **Then** that entry is shown with a line saying which ayahs it covers (for example
   «يشمل التفسير الآيات 6–7»).
3. **Given** the menu for an ayah, **When** the user taps «الترجمة», **Then** the English translation
   (Saheeh International) of that ayah is shown, labelled with its name, in left-to-right text.
4. **Given** any of the 6,236 ayahs, **Then** it has a translation and a tafsir (its own entry or, for the
   ayahs of FR-009a, the nearest earlier entry with its note), so these views never show «not found».
5. **Given** a tafsir or translation view, **Then** it is visibly set apart from the Quran text (its
   own panel and label) so a human explanation is never mistaken for the words of the Quran.
6. **Given** the tafsir view or the translation view, **When** the user taps its share button, **Then**
   the share sheet offers that text (the tafsir entry, or the English translation) with the ayah's
   reference and the source's name, and the Quran text is not mixed into it.

---

### User Story 3 - Share the page as a picture (Priority: P3)

The user shares the page they are reading as one ordinary picture, from the ayah menu, to send to
someone or keep.

**Why this priority**: A common wish ("send this page"), independent of tafsir data, and simple to
check.

**Independent Test**: Open the menu on page 293, choose «مشاركة الصفحة كصورة»: the share sheet offers one
picture file that shows page 293 as on paper, readable when zoomed.

**Acceptance Scenarios**:

1. **Given** the menu on page 293, **When** the user taps «مشاركة الصفحة كصورة», **Then** the share
   sheet offers one picture file of that page looking exactly like the app's page (ivory paper, gold
   frame, green title banners, the page number), without the app's top and bottom bars and without
   any ayah highlight.
2. **Given** the picture is opened in another app and zoomed to twice its size on a phone screen,
   **Then** every word is still sharp.
3. **Given** pages 1 and 2 (8 lines) or any 15-line page, **Then** the picture shows the same line
   layout as the Mushaf.
4. **Given** the user shares a page in browse mode, **Then** the wird's position does not change.

---

### User Story 4 - Share a whole surah as a PDF (Priority: P4)

From the ayah's menu the user shares the surah that ayah belongs to as one PDF of the Mushaf pages
that hold it, to read on a screen, print or send.

**Why this priority**: Useful but heavier (many pages, progress, cancel); it builds on the same page
rendering as Story 3.

**Independent Test**: From an ayah of Al-Baqarah, choose «مشاركة السورة PDF»: after progress, the share
sheet offers one PDF of 48 pages (pages 2–49) in order; cancelling midway offers nothing.

**Acceptance Scenarios**:

1. **Given** the menu on an ayah of Al-Fatiha, **When** the user taps «مشاركة السورة PDF», **Then** a
   one-page PDF (page 1) is offered.
2. **Given** the menu on an ayah of Al-Baqarah, **When** the user taps it, **Then** the user sees
   progress (for example «صفحة 12 من 48»), the reader stays responsive, and when it finishes the
   share sheet offers one PDF of 48 pages in Mushaf order.
3. **Given** a short surah that shares its pages with neighbours (for example Al-Ikhlas on page 604),
   **Then** the PDF contains the full Mushaf pages that hold it, so a neighbouring surah's ayahs
   appear on those pages exactly as in the Mushaf.
4. **Given** the PDF is being prepared, **When** the user taps «إلغاء», **Then** preparation stops
   within a couple of seconds and no file is offered or left behind.
5. **Given** the PDF is opened in a standard PDF viewer, **Then** every page is an A4 portrait sheet
   in the app's own colours (the deep green background, the ivory page with its gold frame and the
   green title banners with gold text, as in the reader) with the Mushaf page centred and scaled to fit
   with even margins, readable on screen and at print size, and the file is named in Arabic after the
   surah («سورة البقرة.pdf»).

---

### User Story 5 - See the meanings of the difficult words (Priority: P5)

From the ayah's menu the user opens «معاني الكلمات» and sees the difficult words of that ayah with
their meanings, or a clear line that the ayah has none.

**Why this priority**: Wanted by the owner, but its data source is not chosen yet; it can ship after
the rest without blocking it.

**Independent Test**: Open the menu on an ayah that has difficult words, tap «معاني الكلمات»: each
word is listed with its meaning. Do the same on an ayah that has none: the screen says so.

**Acceptance Scenarios**:

1. **Given** an ayah that has difficult words, **When** the user taps «معاني الكلمات», **Then** each
   such word is listed with its meaning, labelled with the source.
2. **Given** an ayah that has none, **When** the user taps it, **Then** the screen says «لا توجد كلمات
   غريبة في هذه الآية» instead of an empty list.
3. **Given** the meanings, **Then** they are visibly set apart from the Quran text, like the tafsir.

---

### Edge Cases

- The user long-presses and drags: moving the finger far before the press completes cancels it (it is a
  swipe or a pan), and nothing opens.
- A long press while the page is zoomed in works the same and picks the ayah under the finger.
- A second long press while the sheet is open does not open a second sheet.
- The menu is opened while the reader is in browse mode: nothing about the wird's position changes.
- A very long tafsir entry (a few thousand characters) scrolls inside its view; the rest of the
  page and the menu stay usable.
- The phone has no room to write the picture or the PDF, or cannot hand the file to the share sheet:
  the user is told in Arabic what happened and the reader keeps working.
- The user closes the share sheet without sharing: nothing happens, no error is shown.
- The app is sent to the background or the screen locks while a PDF is being prepared: preparation
  is not lost silently; the user returns to a finished file, a clear failure, or can cancel.
- The user starts a second PDF while one is being prepared: only one is prepared at a time.
- A surah's pages include ayahs of other surahs (shared pages): both Story 3 and Story 4 keep them,
  as in the Mushaf.

## Requirements *(mandatory)*

### Functional Requirements

**Opening the menu**

- **FR-001**: A long press on any word of an ayah, including its end-of-ayah number, MUST open that
  ayah's menu. A short tap MUST keep toggling the bars; swiping, pinch-zoom and the position rules
  MUST be unchanged.
- **FR-002**: While the menu is open, the ayah MUST be highlighted on the page (every one of its
  words on the shown page); the highlight MUST disappear when the menu closes.
- **FR-003**: The menu MUST be a bottom sheet in Arabic, right-to-left, in the app's look, headed with
  the surah name and ayah number («سورة <name> · آية <n>»).
- **FR-004**: A long press on anything that is not a word of an ayah (surah title banner, basmallah
  line of a surah other than Al-Fatiha, empty areas, page number, bars) MUST NOT open a menu.
- **FR-005**: The menu MUST offer, each working independently: «مشاركة», «التفسير», «الترجمة»,
  «معاني الكلمات», «مشاركة الصفحة كصورة», «مشاركة السورة PDF». Closing the menu MUST return to the
  same page, zoom and position (Constitution II).
- **FR-006**: At most one menu MUST be open at a time.

**Share the ayah**

- **FR-007**: «مشاركة» MUST offer, through the phone's share sheet, two lines: the ayah's text exactly as
  in the Mushaf (same words, same order, never altered) inside ﴿ ﴾, then the reference
  «[سورة <name>: <number>]» with the digits the app uses (0–9). It MUST NOT include the app name,
  links or any user data. The tafsir and translation share buttons (FR-010a) use the same reference
  line.
- **FR-008**: The shared text of every one of the 6,236 ayahs MUST be verified automatically against the
  words the Mushaf shows for that ayah (Constitution I).

**Tafsir, translation, word meanings**

- **FR-009**: «التفسير» MUST show Tafsir al-Sa'di for the ayah, labelled with its name, scrollable. When
  one tafsir entry covers several ayahs, it MUST show that entry and say which ayahs it covers.
- **FR-009a**: For an ayah that the bundled Tafsir al-Sa'di text has no commentary of its own for, the tafsir
  view MUST show the nearest earlier entry of the same surah and, above it, a note saying that this ayah has no
  commentary of its own in this text and that the entry shown is the one for the neighbouring ayahs it names. Such
  ayahs MUST be listed explicitly in the build (a different list stops the build); no ayah may show «not found».
- **FR-010**: «الترجمة» MUST show the English translation (Saheeh International) of the ayah, labelled with
  its name, laid out left-to-right.
- **FR-010a**: The tafsir view and the translation view MUST each have their own share button that
  offers, through the share sheet, that view's text followed by the ayah's reference and the source's
  name («تفسير السعدي» or «Saheeh International»). «مشاركة» in the menu MUST NOT add the tafsir or the
  translation to the shared ayah text.
- **FR-011**: «معاني الكلمات» MUST list the difficult words of the ayah, each with its meaning and the
  source, or say clearly that the ayah has none.
- **FR-012**: Tafsir, translation and word meanings MUST be shown set apart from the Quran text and
  labelled as human works, never inside or in place of the Quran text (Constitution I).
- **FR-013**: The bundled tafsir and translation MUST cover all 6,236 ayahs (an ayah without a tafsir entry of its
  own is allowed only if it is on the build's explicit list, FR-009a); this MUST be validated automatically and a
  failed validation MUST stop the build.

**Share the page and the surah**

- **FR-014**: «مشاركة الصفحة كصورة» MUST offer one ordinary picture file of the shown page looking
  exactly like the app's page (ivory paper, gold frame, green title banners, page number), in the
  app's own colours, with no fading, dimming or added decoration, without the app's bars and without
  any highlight, at least 1,600 pixels wide, named in Arabic with the page number (for example
  «مصحف - صفحة 293.png»).
- **FR-015**: «مشاركة السورة PDF» MUST offer one PDF containing, in Mushaf order, every Mushaf page that
  holds the surah, each laid out as in the Mushaf and drawn in colour exactly as the app draws it
  (Emerald and Gold: the deep green background, ivory paper, gold frame, green title banners with gold
  text), on A4 portrait sheets whose background is the app's green, with the Mushaf page centred and
  scaled to fit with even margins, readable on screen and at print size (at least 200 pixels per inch
  on the sheet), named in Arabic after the surah (for example «سورة البقرة.pdf»). (Amended 2026-11-20 by
  the owner: it was white paper with black text; see Clarifications.)
- **FR-016**: While a PDF is being prepared the user MUST see progress («صفحة N من M»), MUST be able to
  cancel, and the reader MUST stay responsive. Cancelling MUST leave no file offered or left behind.
  Only one PDF is prepared at a time.
- **FR-017**: A page picture and a PDF MUST contain only the Mushaf pages; they MUST NOT contain any of
  the user's wirds, positions, bookmarks or notes.

**Failures, offline, privacy**

- **FR-018**: If a picture or PDF cannot be written, or sharing fails, the user MUST be told in Arabic
  what happened and the reader MUST keep working; a share the user cancels MUST NOT be reported as
  an error.
- **FR-019**: Everything in this feature MUST work fully offline; the app MUST NOT send anything
  anywhere. The only thing that leaves the app is what the user chooses to hand to the share sheet.

**Licences and credits**

- **FR-020**: Before this feature ships, the licence of each bundled text (Tafsir al-Sa'di, the Saheeh
  International translation, the gharib word meanings) MUST be read and recorded in
  `docs/research/licenses.md`, and each MUST be credited on the About screen (Constitution V). If a
  licence does not allow our use, work MUST stop and the question go back to the owner.

### Key Entities

- **Ayah**: one of the 6,236 ayahs, identified by surah and number, made of words shown on one or two
  pages.
- **Tafsir entry**: al-Sa'di's explanation text covering one or more consecutive ayahs of one surah.
- **Translation entry**: the English (Saheeh International) text of one ayah.
- **Difficult word**: a word of an ayah with its meaning and its source.
- **Page picture**: one picture of one Mushaf page.
- **Surah PDF**: one PDF of the Mushaf pages that hold a surah.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On any page, holding a finger on an ayah opens its menu, with the ayah highlighted, in under
  half a second after the hold registers, and a tap, swipe or zoom never opens a menu by mistake in a
  check of 50 mixed gestures.
- **SC-002**: All 6,236 ayahs have a tafsir shown for them (their own entry, or the nearest earlier entry with the
  note of FR-009a) and an English translation: 100%,
  verified automatically; 10 ayahs spread across the Mushaf (including 1:1, 2:255 and 114:6) show the
  right reference, tafsir and translation when checked by hand.
- **SC-003**: The text shared for each of the 6,236 ayahs matches the Mushaf's own words for that ayah:
  100%, verified automatically.
- **SC-004**: A page picture is offered in under 3 seconds for any of the 604 pages and stays sharp
  when zoomed to twice its size on the phone's screen.
- **SC-005**: A 48-page PDF (Al-Baqarah) is ready in under 60 seconds on the owner's phone, the reader
  stays usable while it is prepared, the file is under 40 MB, and it opens in a standard PDF viewer
  with 48 pages in Mushaf order; cancelling stops it within 2 seconds with no file left behind.
- **SC-006**: No network access happens at any point in this feature; airplane mode changes nothing
  in the app.
- **SC-007**: Each failure case (no room to write, share failed) shows a clear Arabic message and ends
  with a usable reader; none crashes the app, and cancelling a share shows no error.
- **SC-008**: Every bundled text of this feature is recorded in `docs/research/licenses.md` and
  credited on the About screen: all of them, before the feature is called done.
- **SC-009**: The added data (tafsir, translation, word meanings) adds no more than 40 MB to the app.
- **SC-010**: The colours of a page picture and of a PDF page are those of the reader's page: measured
  on the produced images, the page background, ring, paper, frame, banner fill and text colours match
  the app's colours within a small rounding tolerance, no word is drawn faded or hollow, and nothing is
  added over the page (no underline, dimming or watermark); the owner confirms by eye on the phone that
  the picture and the PDF look like the app's page (amended 2026-11-20).

## Assumptions

- The owner's choices are fixed: Tafsir al-Sa'di, English only (Saheeh International), long press
  opens the menu, page picture and surah PDF are reached from the ayah menu (no new permanent buttons
  in the reader).
- **Constitution**: its Scope section listed «translations into other languages» as out of scope. The
  owner approved a MINOR amendment on 2026-11-20 (constitution 1.1.0) that brings exactly one
  translation into scope, the English Saheeh International, bundled, shown only from an ayah's menu,
  set apart from the Quran text and credited in About. Any other translation stays out of scope.
- The gharib word meanings come from a source chosen in the planning research (free to bundle,
  offline, traceable). If no suitable word-level source exists, the closest acceptable alternative
  (for example ayah-level glossary notes) is proposed to the owner before it is used; Story 5 may ship
  after the other stories without blocking them.
- The page picture and the PDF are of the page(s) as drawn by the app's own Mushaf layout (the same
  words and lines as the printed 1421H Mushaf), not scans of a printed book.
- «The page» for the page picture is the page on which the menu was opened; «the surah» for the PDF is
  the surah of the ayah on which it was opened.
- The destination of a share (another app, a messaging service) is outside the app: what it does with
  the content, and whether it needs a network, is not this feature's concern.
- Portrait use only on one phone; landscape and other platforms are not tested.
- The added data budget (SC-009) is a planning target; the plan measures the real sizes and proposes
  a smaller tafsir form or a different split if it is exceeded.
- Audio, memorisation and tests are separate features; the ayah menu is built so they can add their
  own actions later without changing how it opens.
