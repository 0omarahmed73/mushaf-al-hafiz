# Feature Specification: Web Version of «مصحف الحافظ»

**Feature Branch**: `012-web-version` (work stays on `main`, as for features 001 to 011; no branch is created)

**Created**: 2026-11-21

**Status**: Draft

**Input**: User description (owner, Egyptian Arabic): «عايزك ترفع نسخة الويب على vercel وتعدل ال readme برضو». Asked which
kind of web version, the owner chose «نسخة ويب كاملة من التطبيق»: a full web version of the app, hosted as a static site
on Vercel and linked from the README of the public repository (github.com/0omarahmed73/mushaf-al-hafiz, where the Android
app is released as v1.0.0).

## Constitution dependency (read this first)

This feature cannot be planned under Constitution 1.3.0 as it stands. The Scope section says «Android first; iPhone and
web are not tested in v1», and its last line says a feature that needs something outside the scope MUST first amend the
constitution. So:

- **A MINOR amendment (1.4.0) is required, in a separate step after this spec** (through `/speckit-constitution`, approved
  by the owner). At the least it changes **Scope and Distribution** (the web becomes a supported target and a second
  distribution channel next to the APK) and **Principle IX** (the real-device check becomes, for the web, a real-browser
  check on a phone and on a desktop).
- The amendment step must also look at the other principles this spec touches, and say for each whether its wording
  changes or stays. This spec does not decide them; it lists them so none is missed:
  - **IV** «Every feature MUST work fully offline» and «no server»: a web page is fetched from a host at least once. The
    owner's answer (FR-031): on the web «offline» means that after the first visit everything already opened works with
    no connection, and the whole Mushaf can be downloaded on request.
  - **V** «Distribution is a free, non-commercial APK»: a public website is a new way of handing out the same resources.
    The owner's answer (FR-033): the fonts and the layout data are public files of the site, on the same stance as the
    APK («نشر عام وأنا مسؤول»), and the amendment must record this before the site is deployed.
  - **VII** «Reminders MUST be local notifications scheduled by the phone itself»: a browser cannot do this. The owner's
    answer (FR-020): the web version has no reminders, and says so in Settings.
  - **VIII** «Quran text, layout and data MUST be bundled in the app»: on the web the 604 page fonts cannot all arrive
    before the first page is readable (FR-007, SC-001, SC-008).
- Nothing in this spec loosens Principle I (the Quran text is never modified), the no-ads, no-tracking, no-account rules
  of Principle IV, the visible credits of Principle V, or Principle VI (Arabic, right to left, the owner confirms every
  Arabic string).

## Clarifications

### Session 2026-11-21

The owner answered the three questions that the first draft left open (FR-031, FR-020, FR-033).

- Q: Must the web version work without internet after the first visit, or is online-only enough? (FR-031) → A: It must
  work offline. After the first visit, what was opened works with no connection, and the site offers a button that
  downloads the whole Mushaf (the real size computed from the manifest (about 110 MB with WOFF2, about 172 MB with TTF, decided by gate G1)) on demand. Nothing is downloaded in bulk automatically. The button's Arabic
  label is a proposal the owner confirms later.
- Q: Is it acceptable that wird reminders and the Kahf reminder are absent on the web? (FR-020) → A: Yes. The web
  version has no reminders; Settings on the web shows one line saying reminders are in the Android app only (the wording
  is a proposal the owner confirms later).
- Q: May the 604 page fonts and the layout data be served as public files of the site? (FR-033) → A: Yes, on the same
  stance as the APK («نشر عام وأنا مسؤول»). They must be recorded in `docs/research/licenses.md` and in the constitution
  amendment before the site is deployed.

**Decisions taken while the spec was written (proposed, the owner can overrule them).** They were taken from the request
and from reading the repository on 2026-11-21.

- Q: What does «full web version» include? → A: Every screen the Android app v1.0.0 has: the Mushaf reader, the index
  and go-to-page, wirds with the day's summary and the khatma counter, bookmarks, search, the ayah menu (tafsir,
  translation, word meanings, sharing), the khatm dua, the two looks, reading size and text size, backup, the first-run
  tips, settings and About. The two buttons that are switched off on Android («استماع» and «اختبار», labelled «قريباً»)
  stay switched off on the web in the same way.
- Q: Is it a new product or the same app? → A: The same app shown in a browser: the same pages, the same wording, the
  same behaviour, except for the differences listed under «Differences on the web», which are stated to the user.
- Q: Is the web data shared with the phone app? → A: No. There is no account, no server and no sync (Principle IV). The
  only bridge is the backup file: export on one, import on the other.
- Q: One page or two side by side on a wide desktop screen? → A: One page, centred, in its Mushaf shape, as the Android
  app does in landscape. A two-page spread is out of scope.
- Q: Which browsers? → A: Checked before «done» on a current Chrome on an Android phone and on a current desktop browser
  (Principle IX as amended). Safari on iPhone and other browsers are expected to work but are not a gate, in line with
  the scope line about iPhone.
- Q: Who deploys, and when? → A: Nothing is put online until the owner says «ارفع». The owner signs in to Vercel
  themselves; no password, token or key of the owner's is typed or stored by anyone else (FR-037).

## Differences on the web (explicit degradations)

These are not defects to fix later; they are limits of a browser, and the web version must say them to the user in
plain Arabic (FR-021, FR-022) instead of hiding them.

| What | On Android (v1.0.0) | On the web |
|---|---|---|
| Wird reminders and the Kahf reminder | Local notifications scheduled by the phone, shown with the screen locked, rescheduled after a restart | Absent: a browser cannot run them in the background. Settings shows one line saying reminders are in the Android app only (FR-020) |
| Where the data lives | In the app's own storage on the phone | In this browser, on this device only. Another browser, another device or a private window starts empty |
| Losing the data | Uninstalling the app | Clearing the site's data or the browsing data erases wirds, bookmarks and settings, with no way back except a backup file |
| Phone and web together | One app | Two separate copies; only the backup file carries data between them |
| Sharing an ayah's text | The phone's share sheet | The browser's share sheet where the browser has one, otherwise «نسخ» (copy) |
| Sharing a page as a picture, a surah as PDF | Sent through the phone's share sheet | **Not on the web (owner's decision 2026-11-21).** Both entries are absent from the web menus, and nothing is shown in their place |
| Backup export and import | Share sheet, and the phone's file chooser | A browser download, and the browser's «choose a file» dialog |
| Opening a page | Instant: everything is inside the APK (about 180 MB) | Each page's font is fetched when first needed; a page can take a moment the first time (SC-001, SC-002) |
| Without internet | Everything works | After the first visit, the app and every page already opened work. A page never opened needs a connection once, unless the reader downloaded the whole Mushaf (the real size computed from the manifest (about 110 MB with WOFF2, about 172 MB with TTF, decided by gate G1)) with the button the site offers (FR-031) |
| Permissions | Notifications only; no internet permission | The browser asks for nothing (no notification, location, camera or storage prompt) |

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Read the Mushaf in a phone browser and a desktop browser, with the page as printed (Priority: P1)

Someone opens the site's address on their phone or their computer. With no account, no install and no question, a Mushaf
page appears: the same page, with the same words on the same lines, as in the Android app and the printed Madinah
Mushaf. They turn pages (by swiping on a phone; by the keyboard or on-screen arrows on a computer), open the index, jump
to a page by number, and when they come back tomorrow the site opens on the page where they stopped.

**Why this priority**: It is the product (Principle II: the Mushaf comes first), and everything else opens from it. A
site that only does this is already useful to someone who cannot install the APK (an iPhone, a work computer).

**Independent Test**: With only the reader delivered, open the site in a phone browser and in a desktop browser, compare
pages 1, 2, 50, 293 and 604 word by word and line by line with the Android app, turn 20 pages each way, reload, and
confirm the same page comes back.

**Acceptance Scenarios**:

1. **Given** a first visit, **When** the address is opened, **Then** a Mushaf page is the first screen (no home page,
   no sign-in, no consent banner), and nothing is asked of the visitor.
2. **Given** any of the 604 pages, **When** it is shown on a phone browser and on a desktop browser, **Then** it has the
   same lines and the same words on each line as the Android app shows (15 lines; 8 on pages 1 and 2).
3. **Given** a phone browser, **When** the finger swipes left to right, **Then** the next page comes in from the left, as
   in the paper Mushaf and the Android app.
4. **Given** a desktop browser with no touch screen, **When** the reader uses the keyboard arrows or the on-screen
   arrows, **Then** the page turns in the same direction sense (the next page is on the left).
5. **Given** a wide desktop window or a phone held sideways, **When** a page is shown, **Then** the page keeps its Mushaf
   shape (it is not stretched and its lines do not re-flow), centred, with the bars still reachable.
6. **Given** a page whose font has not arrived yet, **When** the reader turns to it, **Then** a calm waiting state is
   shown and then the page; at no moment is Quran text shown in the wrong font or as broken symbols.
7. **Given** the reader stopped on page 293 and closed the browser, **When** they open the site again in the same
   browser, **Then** page 293 is shown.
8. **Given** the connection drops while a page is being fetched, **When** the fetch fails, **Then** a short Arabic message
   with «إعادة المحاولة» is shown, and the pages already opened in this visit still turn.

---

### User Story 2 - Keep my wirds and count my khatmas in the browser (Priority: P1)

The reader creates a wird (a reading wird, a night-prayer wird), gives it a daily amount or an end date, sees «ملخص
اليوم» with today's range of pages, marks «تم», and after page 604 the wird returns to page 1 and the khatma counter
goes up, exactly as on the phone. Browsing far away does not move the wird until «اجعلها موضعي».

**Why this priority**: Wirds are what makes this app «مصحف الحافظ» and not a page viewer; without them the web version
is not the «full» version the owner chose.

**Independent Test**: In a browser, create two wirds, complete today's portion of one, close and reopen the browser, and
check that both wirds, their positions, today's «تم» and the khatma counts are as left; then repeat the Android app's
portion examples (20 pages a day by default; an end date) and get the same ranges.

**Acceptance Scenarios**:

1. **Given** no wird exists, **When** the reader creates one with a name, a colour and a daily amount, **Then** it appears
   in the wird list and in «ملخص اليوم» with the same range of pages the Android app would give.
2. **Given** a wird on page 600 with 20 pages a day, **When** the reader finishes page 604, **Then** the wird returns to
   page 1, the khatma counter increases by one, and the khatm dua can be opened as on Android.
3. **Given** a wird at page 50, **When** the reader jumps to page 400 from the index, a bookmark or a search result,
   **Then** the reader is in browse mode and the wird stays at page 50 until «اجعلها موضعي» is pressed.
4. **Given** a night-prayer wird, **When** the reader reads at 01:00, **Then** it counts for the night that began the
   evening before (the day turns at 04:00, as on Android), using the clock of the device the browser runs on.
5. **Given** wirds were created, **When** the browser is closed and opened again days later, **Then** every wird, its
   position, its history of days and its khatma count are still there.

---

### User Story 3 - Search surah names and ayat (Priority: P2)

The reader opens search from the index, types a surah's name or a few words of an ayah, carelessly spelled, and gets the
same two groups («السور» then «الآيات») with the same results as on Android; choosing one opens its page with the ayah
highlighted, without moving the wird.

**Why this priority**: Search is the newest feature (011) and the fastest way to reach a place on a desktop keyboard,
but the reader can already reach any page from the index.

**Independent Test**: Run the spelling table and the acceptance scenarios of feature 011 in the browser; every one gives
the same rows, counts and target pages as the Android app.

**Acceptance Scenarios**:

1. **Given** search is open, **When** «كهف» is typed, **Then** «السور» lists surah 18 with its page, as on Android.
2. **Given** search is opened for the first time in a visit, **When** ayah search needs a moment to get ready, **Then** a
   visible waiting state is shown, surah-name results are not held back by it, and the typing is not lost.
3. **Given** «قل هو الله احد» is typed, **When** the result is chosen, **Then** the page of the ayah opens in browse mode
   with the ayah highlighted until the next touch or key press.
4. **Given** any query of feature 011's table, **When** it is typed on the web and on Android, **Then** the number of
   results and the first 100 rows are identical.
5. **Given** a search was made, **When** search is opened again, **Then** it starts empty: nothing typed is stored or
   sent anywhere.

---

### User Story 4 - Mark pages and come back to them (Priority: P2)

The reader taps the bookmark icon on a page, optionally adds a note, and later finds all bookmarks in «علامات» and jumps
to one. Removing or adding shows «تراجع», as on Android.

**Why this priority**: Small and self-contained; it depends only on the reader and on storage that Story 2 already needs.

**Independent Test**: Add three bookmarks (one with a note, one tied to a wird), undo one removal, reload the browser,
and find the same list; tap one and land on its page in browse mode.

**Acceptance Scenarios**:

1. **Given** page 77 has no bookmark, **When** the icon is tapped, **Then** the page is marked and a message with
   «تراجع» appears; «تراجع» removes it again.
2. **Given** bookmarks exist, **When** «علامات» is opened, **Then** they are listed as on Android (general or within a
   wird, with their notes), and choosing one shows its page.
3. **Given** bookmarks exist, **When** the browser is closed and reopened, **Then** they are all still there.

---

### User Story 5 - Carry my data between the phone and the browser with a backup file (Priority: P2)

The reader presses «تصدير نسخة احتياطية» in the browser and a file is downloaded. Later, on the phone, they import that
file and find their wirds, bookmarks and settings; and the other way round: a file exported from the Android app is
chosen in the browser with «استيراد نسخة احتياطية», confirmed, and replaces what the browser had.

**Why this priority**: On the web the backup file has two jobs: it is the only bridge to the phone and the only
protection against «clear site data». It is ranked after the data it protects.

**Independent Test**: Export on Android v1.0.0, import in the browser, compare every wird, wird day, bookmark and
setting; change something, export in the browser, import on Android, compare again.

**Acceptance Scenarios**:

1. **Given** data exists in the browser, **When** export is pressed, **Then** one file is saved by the browser's normal
   download, in the same format the Android app writes, and nothing is uploaded anywhere.
2. **Given** a backup file made by the Android app, **When** it is chosen in the browser and the reader confirms
   «سيُستبدل كل ما في التطبيق. متابعة؟», **Then** the browser's data is replaced by the file's content.
3. **Given** a file that is not a backup, is damaged, or was made by a newer version, **When** it is chosen, **Then** it is
   refused with the same three messages the Android app uses and nothing changes.
4. **Given** a backup from the phone that contains reminder times, **When** it is imported in the browser and exported
   again, **Then** the reminder settings are still in the exported file (they are carried, even if the web does not act
   on them), so a round trip back to the phone loses nothing.
5. **Given** the reader cancels the file dialog or the confirmation, **When** they return, **Then** nothing changed.

---

### User Story 6 - Know whose work this is, and what the web version cannot do (Priority: P2)

The reader opens «عن التطبيق» and finds every source credited as in the Android app, the line «النص القرآني لم يُعدَّل»,
the dedication, the developer's links, and one thing more: where a rights holder can object. In Settings and on the first
visit they are told plainly that their data lives in this browser only and that reminders are not available here.

**Why this priority**: Principle V makes visible credit a condition of using these resources at all, and a public site
reaches more people than an APK; honesty about the limits prevents a reader losing a year of wird history by clearing
their browser.

**Independent Test**: Open About on the web and tick every row of `docs/research/licenses.md` and of the Android About
screen against it; find the takedown contact; find the two notices (data in this browser, no reminders) without
searching.

**Acceptance Scenarios**:

1. **Given** the web About screen, **When** it is compared with the Android About screen, **Then** no credit, source,
   version or link is missing.
2. **Given** a rights holder reads About, **When** they look for how to object, **Then** they find a line with the
   project's Issues address and the promise that the resource will be removed or the site taken down.
3. **Given** a first visit, **When** the reader starts using wirds or bookmarks (or sees the first-run tips), **Then**
   they are told once, in one or two short sentences, that the data is kept in this browser only and how to back it up.
4. **Given** Settings on the web, **When** the reader looks for reminders, **Then** they find no control that pretends to
   work: they find one sentence saying reminders are in the Android app only (FR-020).
5. **Given** a link in About, **When** it is pressed, **Then** it opens in a new tab and the reader's place in the Mushaf
   is not lost.

---

### User Story 7 - The same looks, sizes, ayah menu, dua and first-run tips (Priority: P3)

The reader switches between «زمردي وذهبي» and «القارئ الليلي», changes the reading size (eight steps, 80% to 150%) and the
text size of the tafsir, long-presses (or right-clicks, on a desktop) a word to open the ayah menu with tafsir,
translation, word meanings and sharing, reaches the khatm dua after page 604, and on a first visit sees the short tips
once, worded for the device they are on.

**Why this priority**: These complete the «full» version but each is an addition on top of a reader that already works.

**Independent Test**: Walk the README's feature list section by section in a phone browser and a desktop browser; each
item behaves as described there, except the rows of «Differences on the web».

**Acceptance Scenarios**:

1. **Given** either look is chosen, **When** the browser is reopened, **Then** the same look is applied to every screen,
   (there is no shared page picture or surah PDF on the web).
2. **Given** reading size 150%, **When** a page is larger than the window, **Then** it can be moved by finger or by
   scrolling, and its word-to-line distribution is unchanged.
3. **Given** a desktop with a mouse, **When** the reader opens an ayah's menu, **Then** there is a way to do it without a
   long press, and tafsir, translation and meanings are shown apart from the Quran text with the same labels as on
   Android.
4. **Given** the last page, **When** the reader goes past page 604, **Then** the khatm dua screen opens, labelled as a
   supplication that is not part of the Quran text, and returns to page 1.
5. **Given** a first visit, **When** the Mushaf is shown, **Then** the tips appear once, can be skipped at any moment, do
   not reappear on later visits in the same browser, and do not describe a gesture the device does not have.
6. **Given** the reader's system asks for reduced motion, **When** pages turn and panels open, **Then** nothing animates,
   as on Android.

---

### User Story 8 - The owner publishes the site and links it from the README (Priority: P3)

When the web version has passed its checks, the owner says «ارفع». The owner signs in to Vercel on their own; the site
goes online as static files; the owner opens it on their phone and their computer; then the README (Arabic and English)
gets a link near the top and a short section about the web version and its differences.

**Why this priority**: It is the request itself, but it is the last step: there is nothing to publish until Stories 1 to
7 pass, and it must not happen without the owner's word.

**Independent Test**: Before «ارفع», confirm nothing is online and the README is unchanged. After it, open the README on
GitHub, press the link, and reach the working site in one click from a device that never visited it.

**Acceptance Scenarios**:

1. **Given** the work is finished and checked locally, **When** the owner has not yet said «ارفع», **Then** no deployment,
   preview or public address exists, and the README does not mention a web version.
2. **Given** the owner said «ارفع», **When** a sign-in to the host is needed, **Then** the owner does it themselves, and no
   password, token or key of theirs is asked for, typed or stored by anyone else.
3. **Given** the site is online, **When** the owner checks it in a phone browser and a desktop browser, **Then** the README
   in both languages gets the link and the short section, and not before.
4. **Given** a rights holder objects later, **When** the owner decides, **Then** the site (or the affected resource) can
   be taken offline the same day, and the README link is removed or marked.

---

### User Story 9 - Open the site with no internet after the first visit (Priority: P3)

A reader who already used the site opens it again in a place with no connection (a mosque, a plane) and still reads the
Mushaf and sees their wirds. The owner decided (FR-031) that this is required: everything already opened works with no
connection, and a button downloads the whole Mushaf (the real size computed from the manifest (about 110 MB with WOFF2, about 172 MB with TTF, decided by gate G1)) when the reader asks for it. Nothing is downloaded
in bulk without that request.

**Why this priority**: «بلا إنترنت» is the first promise of this app (Principle IV) and the owner requires it on the
web, but it is the most expensive part of a web version and it builds on the reader of Story 1; the story is written so
that Stories 1 to 8 can be built and checked before it.

**Independent Test**: Visit the site, read ten pages, switch the device to airplane mode, close and reopen the browser,
open the address: the Mushaf opens on the last page and the ten pages turn.

**Acceptance Scenarios**:

1. **Given** a previous visit, **When** the address is opened with no connection, **Then** the app starts and shows the
   last page read, with wirds, bookmarks, search and settings working.
2. **Given** no connection, **When** the reader turns to a page never opened and never fetched, **Then** a plain message
   says this page needs a connection once; nothing breaks.
3. **Given** a connection, **When** the reader presses the button that downloads the whole Mushaf, **Then** they are told
   its size (the real size computed from the manifest (about 110 MB with WOFF2, about 172 MB with TTF, decided by gate G1)) before it starts, see its progress, can stop it, and afterwards all 604 pages open with no
   connection.
4. **Given** a reader who never pressed that button, **When** they read normally, **Then** only what they open (and the
   little that is fetched ahead to keep page turns quick) is downloaded; the whole Mushaf is never fetched on its own.
5. **Given** the download was stopped or the connection dropped half way, **When** the reader presses the button again,
   **Then** it continues or starts again without harm, and the pages already kept still open offline.

---

### Edge Cases

- **A font arrives late or not at all**: the page is never shown in a fallback font (it would be wrong symbols, a
  Principle I failure); the reader sees the waiting state, then the retry message.
- **Fast flicking through many pages**: pages that were skipped do not block the page the reader stopped on.
- **Two tabs of the site open in the same browser**: a change in one (a wird marked «تم», a bookmark) must not be lost or
  corrupt the data when the other tab is used; the simplest safe behaviour is chosen in the plan.
- **Private / incognito window, or a browser that refuses to keep data**: the site still reads; the reader is told that
  nothing will be remembered after the window closes.
- **The browser clears the site's data on its own** (low storage, long disuse): the app opens as on a first visit; this is
  why the notice of FR-021 points at the backup.
- **A new version of the site is published while a reader has it open or kept offline**: their wirds, bookmarks and
  settings survive the update, and they are never left with a mix of old and new files that shows a page wrongly.
- **Importing a phone backup made by a newer version than the site**: refused with the «أحدث» message, nothing changes.
- **A very small window (360 px wide) or a very large one (4K)**: no screen needs sideways scrolling except a
  deliberately enlarged Mushaf page; text and touch targets stay usable.
- **Keyboard only, on a desktop**: the reader, the index, search and the dialogs can be used without a mouse.
- **Browser zoom or a large system font**: the Mushaf page's line distribution does not change.
- **The device clock or time zone changes**: the wird day follows the device's local clock, as on Android.
- **The reader opens the site in a second browser and expects their wirds**: the first-visit notice (FR-021) already
  said why they are not there, and names the backup file as the way.
- **A link into the site** (for example the README's link): it always lands on the app's start; deep links to a page or
  ayah are out of scope.
- **The host is unreachable or the site was taken down**: a reader with the site kept offline keeps reading
  (FR-031); a new visitor gets the browser's own error. The README names the APK as the other way.

## Requirements *(mandatory)*

### Functional Requirements

**Reading the Mushaf**

- **FR-001**: The web version MUST be reachable at one public address and MUST open directly on a Mushaf page, with no
  account, sign-in, install step, consent banner or landing page before it (Principle II).
- **FR-002**: Each of the 604 pages MUST show the same words on the same lines as the Android app v1.0.0 and the printed
  Madinah Mushaf 1421H (15 lines; 8 on pages 1 and 2), in the page's own Mushaf font, in both looks.
- **FR-003**: The page MUST keep its shape in a phone browser (upright and sideways) and in a desktop browser of any
  window size: never stretched, never re-flowed; one page at a time, centred.
- **FR-004**: Page turning MUST follow the paper Mushaf: on touch screens the same swipe as on Android (the next page
  comes in from the left); with a keyboard and with on-screen controls the next page is on the left. Every turn MUST be
  possible without a touch screen.
- **FR-005**: The reader MUST offer what the Android reader offers: the top bar (juz, hizb, quarter, surah, page number),
  the bottom bar, hiding and showing both with a tap, the index of surahs, juz and pages, go-to-page by number, zoom,
  and the eight reading-size steps from 80% to 150%.
- **FR-006**: The last page read MUST be remembered in the same browser across reloads, closing the browser and
  restarting the device.
- **FR-007**: A page MUST be shown only when its own font and layout are ready. Until then a waiting state is shown.
  Quran text MUST never appear, even for an instant, in another font or as placeholder symbols.
- **FR-008**: When a page cannot be fetched, the reader MUST see a short Arabic message with a way to try again, and the
  pages already available MUST keep working.
- **FR-009**: The web version MUST NOT make the visitor wait for the whole Mushaf before the first page is readable
  (SC-001, SC-008).

**Wirds, khatma, bookmarks, search, ayah menu**

- **FR-010**: Wirds MUST behave as on Android: several wirds with name, colour and type; a daily amount or an end date
  (default 20 pages); «ملخص اليوم» and «تم»; browse mode and «اجعلها موضعي»; the night-prayer day turning at 04:00;
  the history of days. The same inputs MUST give the same portions as the Android app.
- **FR-011**: The khatma counter MUST increase when a wird passes page 604 and returns to page 1, and the khatm dua
  screen MUST be reachable only after the last page, labelled as a supplication that is not part of the Quran text, with
  the same wording as on Android (Principle III exception).
- **FR-012**: Bookmarks MUST behave as on Android: one-tap add and remove with «تراجع», an optional note, general or
  within a wird, and the «علامات» list that jumps to a page in browse mode.
- **FR-013**: Search MUST give the same results as feature 011 on Android for the same typing (the same tolerance of
  hamza, ة/ه, ى/ي, tashkeel, tatweel and Mushaf spelling; the same two groups, order, count and limit of 100 ayat), and
  choosing a result MUST open its page with the ayah highlighted and the wird unmoved. Nothing typed is stored or sent.
- **FR-014**: When search needs time to get ready on first use, the reader MUST see that it is preparing; surah-name
  results MUST NOT wait for it; and the reader MUST NOT be able to mistake «still preparing» for «no results».
- **FR-015**: The ayah menu MUST offer the tafsir, the English translation and the word meanings, set apart from the
  Quran text and labelled as on Android, and MUST be openable both by a long press and by a way that suits a mouse and a
  keyboard.
- **FR-016**: Sharing an ayah's text MUST produce the same text as on Android, through the browser's share sheet where
  one exists and otherwise by copying, with a confirmation message.
- **FR-017**: «مشاركة الصفحة كصورة» and «مشاركة السورة PDF» are NOT part of the web version (owner's decision of
  2026-11-21: removed, not deferred). The web menus MUST NOT show them or any disabled placeholder; the PDF and picture
  code is not built for the web. Android keeps both unchanged (FR-040).

**Looks, sizes, tips**

- **FR-018**: The two looks, the reading size and the text size of the tafsir, translation and meanings MUST work and be
  remembered as on Android; reduced-motion preferences of the device MUST be respected.
- **FR-019**: The first-run tips MUST appear once per browser, be skippable at any moment, and describe only gestures
  that exist on the device in use (touch wording on a phone, mouse and keyboard wording on a desktop).

**Reminders and honesty about the differences**

- **FR-020**: The web version MUST NOT have wird reminders or the Kahf reminder, and MUST NOT ask for notification
  permission. Where the Android settings show «التذكيرات», Settings on the web MUST show one line saying that reminders
  are in the Android app only, and no reminder control (the wording is a proposal the owner confirms, FR-041).
  Reminders that fire only while the site is open in a tab are not built.
- **FR-021**: The reader MUST be told, once on first use and permanently in Settings, in one or two short sentences:
  that wirds, bookmarks and settings are kept in this browser on this device only; that clearing the site's data erases
  them; and that a backup file is the way to keep them and to move them to the phone.
- **FR-022**: Every row of «Differences on the web» that a reader can run into MUST be stated where they would run into
  it (Settings for reminders and data; the share actions for downloads), and listed in the README's web section. No
  control may be shown that looks as if it works and does not.
- **FR-023**: Reminder settings found in an imported backup MUST be kept and written back unchanged on export, so a
  phone → web → phone round trip loses nothing.

**Backup**

- **FR-024**: «تصدير نسخة احتياطية» MUST save one file through the browser's download, in the same format as the Android
  app, containing the wirds, wird days, bookmarks and settings. Nothing is uploaded.
- **FR-025**: «استيراد نسخة احتياطية» MUST let the reader choose a file with the browser's file dialog, ask for the same
  confirmation, replace all data on «متابعة», and refuse a foreign, damaged or newer file with the same messages as on
  Android, changing nothing.
- **FR-026**: A backup made by the Android app v1.0.0 MUST import on the web, and a backup made on the web MUST import in
  the Android app v1.0.0, with every wird, wird day, bookmark and setting preserved.

**Privacy, hosting, licences**

- **FR-027**: The site MUST be static files only: no server code written for it, no account, no database outside the
  browser, no sync, no form that sends anything.
- **FR-028**: The site MUST contain no ads, analytics, tracking, cookies for tracking, or error-reporting service, and
  MUST NOT request anything (fonts, scripts, images, data) from any host other than its own address. Any visitor
  statistics feature the host offers MUST stay off.
- **FR-029**: No reader data (position, wirds, bookmarks, notes, settings, search text) MAY leave the browser. The
  README's web section MUST say honestly what a web host unavoidably sees: ordinary requests for the site's files (which
  include which page fonts were fetched), and nothing else.
- **FR-030**: The site MUST be free and non-commercial: no payments, donations, paid hosting features that add tracking,
  or sponsorship (Principle V; the Saheeh International translation is non-commercial only).
- **FR-031**: The web version MUST work without internet after the first visit: the app itself, the wirds, bookmarks,
  search, settings and every Mushaf page already opened MUST work with no connection (User Story 9). The site MUST
  offer a button that downloads the whole Mushaf for offline use; it MUST state the size (the real size computed from the manifest (about 110 MB with WOFF2, about 172 MB with TTF, decided by gate G1)) before it
  starts, show progress, be stoppable, and be safe to press again after a stop or a failure. The whole Mushaf MUST
  NOT be downloaded in bulk automatically: without that button only what the reader opens, plus the little fetched
  ahead to keep page turns quick (SC-008), is fetched. The button's Arabic label is a proposal the owner confirms
  (FR-041).
- **FR-032**: The reader MUST always be able to tell whether a page is unavailable because there is no connection, and
  MUST never see a blank or broken Mushaf page.
- **FR-033**: The 604 page fonts (QCF V2) and the layout and word data MAY be served as public files of the site,
  fetchable by anyone, on the same stance as the APK («نشر عام وأنا مسؤول»: the owner publishes them publicly and takes
  responsibility). Before the site is deployed, this web distribution MUST be recorded in `docs/research/licenses.md`
  (for each resource) and in the constitution amendment (Principle V); a deployment without both records is not allowed
  (FR-036). Note kept for the record: these files stay out of the public repository; a public site makes each of them a
  directly downloadable file, a wider exposure than an APK, which the owner accepted. FR-039 (removal on objection)
  applies to them.
- **FR-034**: «عن التطبيق» on the web MUST show every credit, source, version and link that the Android About screen
  shows, the line «النص القرآني لم يُعدَّل», the dedication and the developer's links, and in addition: a line telling a
  rights holder where to object (the project's Issues address) and that the resource will be removed or the site taken
  down; and a link to the repository and to the Android release. Links open without losing the reader's place.
- **FR-035**: The Quran text, its order and its distribution on pages and lines MUST NOT be modified for the web. The
  web version MUST be built from the same generated and validated data as the APK, and the automatic validation
  (604 pages, line counts, every word once and in order) MUST stop a web build that fails it (Principle I).

**Publishing and the README**

- **FR-036**: Nothing (no deployment, preview address or public copy) MAY be put online before the owner says «ارفع»
  for this feature. Passing the checks is not that permission.
  The deployment of the early gate G4 is a **private, unlisted trial** with a synthetic site and none of the app's data, put
  up only after the owner's explicit approval for that test. It is **not** the public address of FR-036 and SC-013, and it
  MUST be deleted, or kept private and unlisted, after the test.
- **FR-037**: The owner signs in to the host (Vercel) themselves. No password, token or key of the owner's MAY be asked
  for, typed or stored in the repository, in the specs or in a commit.
- **FR-038**: After the site is online and checked by the owner, `README.md` and `README.en.md` MUST get a link to the web
  version near the top and a short section that says what it is, that the data stays in the browser, how to move data
  with a backup file, and the differences from the Android app. The README's statements that are Android-only («تطبيق
  أندرويد», «بلا إنترنت», the permissions section) MUST be reworded where they would otherwise become untrue. The Arabic
  text is confirmed by the owner (FR-041). The README is written in a later step, not in this one.
- **FR-039**: The site MUST be removable: the owner can take the whole site, or one affected resource, offline on the day
  a rights holder objects, and the steps are written down with the release documents.

**Android stays as it is**

- **FR-040**: The Android app MUST NOT change behaviour, wording, permissions (still no internet permission) or data
  format because of this feature. Every existing test MUST still pass and static analysis MUST report no issues. Code
  that the two targets share MUST be covered by the existing tests or by new ones written first (Principle IX).

**Language and checks**

- **FR-041**: The whole web interface MUST be Arabic and right to left, including the browser tab's title, the waiting
  and error states, and the page shown when the site cannot start. Every new Arabic string is a proposal until the owner
  confirms it (Principle VI); none is machine-translated from English. Existing strings are reused unchanged.
- **FR-042**: Before the feature is called done, the behaviour tests cannot prove MUST be checked by the owner in a real
  browser on a phone and a real browser on a desktop: how pages render, the turning direction, landscape, a slow
  connection, reload and return, backup export and import, airplane mode after a visit, and the whole-Mushaf download (FR-031). This is the
  web form of Principle IX's real-device gate and depends on the amendment.
- **FR-043**: The site MUST be usable from a window 360 px wide up to a large desktop window, by touch, by mouse and by
  keyboard alone.

### Proposed Arabic strings (proposals only; the owner confirms each one, Principle VI)

| Where | Proposal |
|---|---|
| Notice about where data lives (first use, and Settings) | «بياناتك محفوظة في هذا المتصفح على هذا الجهاز فقط. إن مسحت بيانات المتصفح ضاعت أورادك وعلاماتك، فاحتفظ بنسخة احتياطية.» |
| Settings, in place of «التذكيرات» | «التذكيرات متاحة في تطبيق أندرويد فقط. المتصفح لا يستطيع تنبيهك وهو مغلق.» |
| Waiting for a page | «جارٍ تحميل الصفحة…» |
| A page could not be fetched | «تعذّر تحميل الصفحة. تحقّق من الاتصال.» with the button «إعادة المحاولة» |
| A page not available offline | «هذه الصفحة تحتاج اتصالًا بالإنترنت مرة واحدة.» |
| Search getting ready | «جارٍ تجهيز البحث…» |
| Button that downloads the whole Mushaf (FR-031) | «تنزيل المصحف كاملًا للقراءة بلا إنترنت (نحو {N} ميجابايت)» |
| Stop the whole-Mushaf download | «إيقاف التنزيل» |
| The whole Mushaf is now kept offline | «المصحف كاملًا متاح الآن بلا إنترنت» |
| Private window | «أنت في نافذة خاصة: لن يُحفظ شيء بعد إغلاقها.» |
| Share falls back to copy | «تم نسخ نص الآية» |
| File saved by download | «تم تنزيل الملف» |
| About, for rights holders | «إن كنت صاحب حق في أي مورد واعترضت، افتح بلاغًا في صفحة المشروع على GitHub، وسيُزال المورد أو يُسحب الموقع.» |
| About, link to the app | «تطبيق أندرويد» |
| README link (Arabic) | «جرّب نسخة الويب» |
| Browser tab title | «مصحف الحافظ» |

### Key Entities

- **Web copy of the app**: the same screens and behaviour as Android v1.0.0, delivered as static files from one address.
- **Reader data in the browser**: wirds, wird days (history and «تم»), bookmarks with notes, settings (look, reading
  size, text size, tips seen, last page), and reminder settings carried but not acted on. It belongs to one browser on
  one device and is never sent anywhere.
- **Backup file**: one file in the existing format, the only thing that moves data between a browser and the phone, in
  both directions.
- **Mushaf resources**: 604 per-page fonts, the page layout data, the per-ayah words, tafsir, translation and word
  meanings, the dua text. Generated and validated by the existing tools; not in the public repository; on the web they
  are public files of the site (FR-033), fetched as needed and kept in the browser for offline use.
- **Offline copy**: what the browser keeps so the site works with no connection: the app itself and every page already
  opened, or all 604 pages after the reader pressed the whole-Mushaf download button (FR-031).
- **Differences notice**: the short statements of what the web version cannot do, shown in the app and in the README.
- **Deployment**: the published copy of the site; it exists only after «ارفع», belongs to the owner's own host account,
  and can be withdrawn.

## Success Criteria *(mandatory)*

The numbers are proposals (assumptions) for the owner and the plan to confirm or correct; they are measured on a
mid-range Android phone on a typical mobile connection (about 10 Mbit/s) unless said otherwise.

### Measurable Outcomes

- **SC-001**: On a first visit, a readable Mushaf page is on screen within 8 seconds of opening the address; on a later
  visit in the same browser, within 3 seconds.
- **SC-002**: Turning to the next or previous page shows it within 1 second in at least 95% of turns during normal
  reading; a jump to a far page shows it within 3 seconds.
- **SC-003**: For all 604 pages, the words on each line are identical to the Android app's (checked automatically, zero
  differences), and the owner finds no visible difference on pages 1, 2, 50, 293 and 604 compared side by side with the
  phone app, in a phone browser and in a desktop browser, in both looks.
- **SC-004**: After search is ready, results appear within 1 second of typing; getting ready on first use takes no more
  than 5 seconds on the phone and is shown while it lasts. For every query in feature 011's spelling table, the web and
  Android results are identical.
- **SC-005**: During a session that visits every screen and uses every action, the browser makes zero requests to any
  host other than the site's own address, and stores no tracking cookie.
- **SC-006**: A backup exported from Android v1.0.0 and imported on the web, then exported on the web and imported on
  Android, preserves 100% of wirds, wird days, bookmarks and settings (including reminder settings).
- **SC-007**: The Android app is untouched: every existing test passes (196 test files at the time of this spec), static
  analysis reports no issues, the APK's permissions are the same, and its size changes by less than 1 MB.
- **SC-008**: Before the first page is readable, a first visit downloads no more than 15 MB; the whole set of Mushaf
  resources (the real size computed from the manifest (about 110 MB with WOFF2, about 172 MB with TTF, decided by gate G1)) is never downloaded without the reader asking.
- **SC-009**: Data survives: after 20 reloads, a browser restart and a device restart, every wird, bookmark and setting is
  as it was, and the site opens on the last page read.
- **SC-010**: With no connection, after a previous visit, the site starts and shows the last page within 3 seconds, and
  every page opened before still opens. After the whole-Mushaf download finished, all 604 pages open with no
  connection (checked on pages 1, 2, 50, 293 and 604 and on 20 pages never opened before).
- **SC-011**: From a window 360 px wide to 1920 px wide, no screen needs sideways scrolling (except an enlarged Mushaf
  page), and every action can be done by keyboard alone on a desktop.
- **SC-012**: From the README on GitHub, one click reaches the working site; a person who has never seen the app reads
  their first page with no instruction, account or install.
- **SC-013**: Before «ارفع», a search of the public internet side finds nothing: no deployment exists. After it, exactly
  one public address exists and it is the one in the README.
  (The private, unlisted G4 trial deployment is not that address and is deleted or kept private after its test.)
- **SC-014**: Every Arabic string that is new for the web has the owner's confirmation recorded before the site is
  published; zero unconfirmed strings ship.
- **SC-015**: On the web, zero reminder controls and zero notification prompts appear in a session that visits every
  screen; Settings shows the one line about reminders.
- **SC-016**: On the day of «ارفع», `docs/research/licenses.md` has the web distribution recorded for every Mushaf
  resource and the constitution is at 1.4.0 with the same record; if either is missing, nothing is deployed.

## Assumptions

Facts read in the repository on 2026-11-21 (not invented):

- There is no web target today: the project has `android/` only and no `web/` folder; `pubspec.yaml` names the app
  `mushaf`, version 1.0.0+1.
- The app keeps wirds, wird days, bookmarks and settings in a local SQL database (`lib/wirds/db.dart`); reminders use a
  background worker and local notifications (`lib/reminders/`); backup and sharing go through the phone's share sheet,
  file chooser and file system (`lib/backup/backup_files.dart`, `lib/ayah/share_service.dart`,
  `lib/ayah/page_picture_action.dart`, `lib/pdf/`); links open through a small Android-only channel (`lib/links.dart`).
  Seven source files use the device file system directly. All of these need a browser counterpart; which one is the
  plan's decision, not this spec's.
- The Mushaf resources are git-ignored (`assets/mushaf/`, `assets/ayah/`, `assets/fonts/qpc-v2/`) and generated by
  `tool/build_quran_assets.py` and `tool/build_ayah_assets.py`. On this machine they are about 169 MB in 1,676 files (a count of the **source files** in those three folders, not of the files the site serves nor of the requests of a download; the pack's own count is written by the build, see data-model.md and research.md):
  604 page fonts (about 153 MB), 604 page layout files plus metadata (about 5 MB), and the ayah data (about 10 MB). The
  released APK is about 180 MB.
- Search (feature 011) builds its index in memory at first use from the bundled ayah words.
- The takedown contact exists today in the README (the Issues address); the Android About screen shows the credits, the
  «text not modified» line, the dedication and the developer's links, and has no takedown line. FR-034 adds that line on
  the web only; adding it to the Android About screen would be a separate small feature (FR-040 keeps Android unchanged).
- The README (`README.md`, `README.en.md`) describes an Android app throughout («تطبيق أندرويد», «بلا إنترنت»,
  «لا صلاحية إنترنت»); FR-038 covers the rewording.

Decisions taken as defaults:

- The web version shows the same v1.0.0 feature set; features added to Android later reach the web by their own specs.
- One page at a time on every screen size; no two-page spread; no deep links to a page or an ayah; no «install» prompt
  pushed at the reader (the browser's own «add to home screen» is allowed but not advertised inside the Mushaf).
- The whole-Mushaf download button (FR-031) is reached from Settings, not shown over the Mushaf page; the plan may
  propose a second place, and the owner decides.
- The Android splash screen and app icon (feature 009) have a web counterpart only as far as needed: a short start
  screen in the same dark look while the app loads, and the same icon for the browser tab; no new artwork.
- The address is the free one the host gives (for example a name under the host's domain); a custom domain is out of
  scope. The exact name is the owner's choice at «ارفع».
- Tests are measured on the owner's Android phone with a current Chrome, and on a desktop with a current Chrome or
  Firefox. iPhone Safari is not a gate (the scope line about iPhone stays).
- The backup format does not change. If the plan finds a web need that would change it, that comes back to the owner.
- Recitation audio and hifz tools are not part of this feature (they do not exist on Android either).

Dependencies:

- **Constitution amendment 1.4.0 (MINOR), a prerequisite of the plan**: `/speckit-plan` does not start before it. Scope
  and Distribution, and Principle IX, at the least; and a recorded decision on Principles IV, V, VII and VIII as listed
  at the top, written from the owner's three answers (Clarifications, Session 2026-11-21): offline after the first
  visit with the whole Mushaf on request (IV, VIII), no reminders on the web (VII), the fonts and layout data as public
  files of the site on the APK's stance (V). Approved by the owner.
- **`docs/research/licenses.md`**: web distribution recorded for each resource (the 604 page fonts, the layout and word
  data, and the rest), before the site is deployed (Principle V, FR-033, SC-016). It is not edited in the clarify step.
- **The owner's Vercel account and the owner's «ارفع»** (FR-036, FR-037).
- **The owner's confirmation of every new Arabic string** (FR-041, SC-014).
- **The generated Mushaf resources** on the building machine (they are not in the repository).

Open technical questions for the plan (recorded, not requirements):

- Whether the host's free static hosting accepts this site: its limits on total size, on the number of files (about
  1,700 resource files plus the app), on the size of one file, and on monthly traffic are not known here and must be
  read from the host's current documentation before the design is fixed. If they do not fit, the plan returns to the
  owner with the options; the spec's requirements do not change.
- How the app and the 604 fonts are delivered so that SC-001, SC-002 and SC-008 hold (what is fetched first, what is
  fetched ahead of the reader).
- Where the browser keeps the reader's data and how much the browser allows, including for an offline copy of the whole
  Mushaf (the real size computed from the manifest (about 110 MB with WOFF2, about 172 MB with TTF, decided by gate G1), FR-031), and what the reader is told if the browser refuses that much.
- How the web build is kept from changing the Android build (FR-040), and how the 604-page comparison of SC-003 is run.
- How an update of the site reaches a reader who has it kept offline without mixing old and new files.
