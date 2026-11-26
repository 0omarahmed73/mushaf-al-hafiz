<!--
Sync Impact Report
- Version change: 2.2.0 → 3.0.0 (MAJOR: a MUST NOT of Principle III is removed: the app may now ask for the approximate
  location permission for prayer times)
- Modified principles: III. In the prayer-times exception (2.0.0), the bullet "the city MUST be chosen from a list bundled
  in the app; the app MUST NOT ask for the location permission" is replaced by "Place (3.0.0)": the approximate location
  only, asked only on the reader's tap, never in the background, kept on the phone, used only for prayer times, with the
  bundled city list as the fallback; the permissions bullet names the approximate location. The network stays forbidden.
- Unchanged principles: I, II, IV (nothing leaves the phone), V, VI, VII, VIII and IX.
- Modified sections: Scope and Distribution (v1): new bullet "In scope by amendment (3.0.0)".
- Added sections: none
- Removed sections: none
- Reason: on 2026-11-26, in the clarify step of feature 014 (specs/014-prayer-times/spec.md), the owner asked «ليه
  منشغلهاش ب GPS عادي ونجيب المواقيت من النت ؟». After being told the times need no network and that the location needs
  this amendment, he chose "GPS, no internet", approved this wording («موافق»), and chose a city list for readers who refuse
  the permission.
- Templates: .specify/templates/*.md not modified (they read this file at runtime).
- Follow-up TODOs: PRIVACY.md (public) must name the approximate location before feature 014 ships, pushed only after the
  owner's «ارفع»; Play's Data safety answer stays "no data collected" (processed on the phone only) and is checked again at
  release.

Previous report (2.2.0):
- Version change: 2.1.0 → 2.2.0 (MINOR: materially expanded guidance in Principles I and II and in Scope and
  Distribution)
- Modified principles: I. Quran Text Integrity gains one bullet, "Large-ayah view (2.2.0)": a separate view MAY show 1 to
  3 ayat per screen at a large size on new lines, and split a too-long ayah between words, under rules that keep the
  Madinah glyphs, every word once and in order, the stored data and the Mushaf page untouched. II. The Mushaf Comes First
  gains one exception (2.2.0): the app MAY open on that view when the reader left it on. The existing bullets of I and II
  keep their words.
- Unchanged principles: III, IV, V, VI, VII, VIII and IX.
- Modified sections: Scope and Distribution (v1): new bullet "In scope by amendment (2.2.0)".
- Added sections: none
- Removed sections: none
- Reason: on 2026-11-25 the owner asked for a mode for elderly readers, «يبقى في مود لكبار السن بحيث ان الاية تبقى حجمها
  كبير وكل اية في صفحة او كل ايتين» (feature 015, specs/015-large-ayah-mode/spec.md), and in its clarify step chose «تعديل
  صغير للدستور» over a statement in the spec alone, the Madinah glyphs («خط مصحف المدينة»), 1, 2 or 3 ayat per screen, and
  long ayat split over screens («تتقسم على كذا صفحة»); he approved this amendment's wording with «طبّقه».
- Templates: .specify/templates/*.md not modified (they read this file at runtime).
- Follow-up TODOs: none for this file. Feature 015's spec records the amendment as done (FR-001); its plan passes the
  Constitution Check against the new bullets. The Arabic strings of the view stay proposals until the owner confirms them
  (Principle VI).

Previous report (2.1.0):
- Version change: 2.0.0 → 2.1.0 (MINOR: materially changed guidance in Principle V and in Scope and Distribution)
- Modified principles: V. Licensing and Attribution. The distribution bullet no longer says "Google Play is still not
  planned"; Google Play is now an allowed channel for the same free, non-commercial app, with the Play rules it brings:
  an Android App Bundle signed by Google (Play App Signing with a key Google makes), a privacy policy page, a Data safety
  form that declares no data collected or shared, the content rating questionnaire and the closed test Google asks of the
  account. The owner's responsibility for the third-party resources, the credits in About and the take-down rule apply to
  the Play listing in full.
- Unchanged principles: I, II, III, IV, VI, VII, VIII and IX.
- Modified sections: Scope and Distribution (v1): the distribution bullet names Google Play.
- Added sections: none
- Removed sections: none
- Reason: on 2026-11-25 the owner asked «help me publish it to google play», answered "Yes, amend it" to this amendment,
  said he has a personal Play developer account, and chose "Let Google make a new one" for the app signing key.
- Consequence recorded on purpose: the Play build is signed by Google's key, the GitHub APK by the owner's key, so one
  cannot be installed over the other; moving from one to the other needs an uninstall after a backup export.
- Templates: .specify/templates/*.md not modified (they read this file at runtime).
- Follow-up TODOs: a privacy policy page and the store texts (Arabic strings: proposals until the owner confirms them,
  Principle VI); docs/research/licenses.md gains a line for Play distribution; README names the Play listing only after the
  app is live there.

Previous report (2.0.0):
- Version change: 1.4.0 → 2.0.0 (MAJOR: Principle III is redefined: its ban on adhan no longer covers prayer
  times and prayer-time notifications)
- Modified principles: III. Focus: Not an "Everything" App. The first bullet now bans the full adhan
  recording, qibla, duas, hadith and other non-Quran features, with two exceptions: the 1.2.0 supplication
  (unchanged, word for word) and a new exception (2.0.0) for prayer times and their notifications, under
  rules that tie it to Principles II, IV, V, VII and IX.
- Unchanged principles: I, II, IV, V, VI, VII, VIII and IX. None of their words change.
- Modified sections: Scope and Distribution (v1): new bullet "In scope by amendment (2.0.0)".
- Added sections: none
- Removed sections: none
- Reason: on 2026-11-25 the owner asked for prayer times and adhan "with full control". After the study
  docs/research/2026-11-25-prayer-times-study.md the owner chose scope B (times plus notification, not the
  full adhan) and approved this amendment's wording with «طبّقه». Principle III forbade adhan and the Scope
  section requires an amendment before such a feature is planned.
- Templates: .specify/templates/*.md not modified (they read this file at runtime).
- Follow-up TODOs: the feature's spec (014) must decide whether the times screen (without notifications,
  which Principle VII already keeps off the web) appears in the web version; docs/research/licenses.md needs
  rows for the calculation library (adhan_dart, MIT), the city list and the notification sound before the
  feature depends on them (Principle V); the Arabic strings need the owner's confirmation (Principle VI);
  README.md and the store texts say nothing about prayer times until the feature ships.

Previous report (1.4.0):
- Version change: 1.3.0 → 1.4.0 (MINOR: materially expanded guidance in Principles IV, V, VII, VIII and IX, in
  Scope and Distribution and in Development Workflow)
- Modified principles: each one keeps its existing bullets word for word, except the one reworded bullet in IX
  named below, and gains web rules marked "(1.4.0)".
  IV. Offline, Private, Free: the website is static files only (no server code, account, database outside the
  browser or sync); reader data stays in the browser; nothing is requested from any other host; no analytics;
  it works offline after the first visit, with the whole Mushaf fetched only on request.
  V. Licensing and Attribution: distribution now also includes the static website; the Mushaf fonts and layout
  data are public files of the site under the same stance as the APK; the site's About shows every credit and
  a takedown contact.
  VII. Reliability Where Competitors Fail: reminders are an Android-only capability and the web version says
  so; the reading position survives in the same browser.
  VIII. App Size: on the web, "bundled" means served from the site's own address; first-page budget of 15 MB;
  the full download (about 170 MB) only when the reader asks.
  IX. Quality Gates: the real-device bullet now names features that ship on Android; a new bullet adds the
  real-browser check (a phone browser and a desktop browser) for the web.
- Unchanged principles: I, II, III and VI. None of their words change and all of them apply to the web version
  in full.
- Modified sections: Scope and Distribution (v1): the first bullet no longer says web is not tested (iPhone
  stays untested); new bullet "Web version (by amendment 1.4.0)". Development Workflow: the last bullet names
  the real-browser check.
- Added sections: none
- Removed sections: none
- Reason: on 2026-11-21 the owner asked for a full web version of the app on Vercel (feature 012,
  specs/012-web-version/spec.md) and decided: a static site with no server, no account and no analytics;
  offline after the first visit with an optional «download the whole Mushaf» button (about 170 MB); no
  reminders on the web (Android only); the 604 Mushaf fonts and the layout data served as public files of the
  site on the same stance as the APK («نشر عام وأنا مسؤول»); the Android app does not change behaviour. The
  Scope section requires an amendment before such a feature is planned.
- Templates: .specify/templates/*.md not modified (they read this file at runtime).
- Follow-up TODOs: docs/research/licenses.md needs a row or note for web distribution of each resource before
  anything is deployed (Principle V). specs/012-web-version/spec.md still carries three [NEEDS CLARIFICATION]
  marks (FR-020, FR-031, FR-033) that the owner's decisions above answer; they are closed in the clarify
  step, not here. The 15 MB first-page budget comes from that spec's SC-008, where it is a proposal: the plan
  must confirm it or come back for a PATCH. README.md and README.en.md are reworded only after the owner says
  «ارفع» (FR-038). The takedown line is added to the web About only; the Android About screen is unchanged
  (FR-040).

Previous report (1.3.0):
- Version change: 1.2.0 → 1.3.0 (MINOR: materially changed guidance in Principle V and in Scope and
  Distribution)
- Modified principles: V. Licensing and Attribution. The last bullet no longer says the app is a private APK
  for the user and the people around them, "NOT on Google Play for now". It now says the APK is free and
  non-commercial, the owner MAY publish it publicly (a GitHub repository and release, itch.io, APKPure),
  Google Play is still not planned, and the owner accepts responsibility for the third-party resources whose
  licences are unpublished or restricted. Every MUST that protects users and rights holders stays: non-
  commercial, ad-free, tracking-free, offline (Principle IV); attribution visible in About; the Quran text
  never modified (Principle I); the affected resource or the app is taken out if a rights holder objects.
- Modified sections: Scope and Distribution (v1): new bullet "Distribution (by amendment 1.3.0)"; the other
  bullets are unchanged.
- Added sections: none
- Removed sections: none
- Reason: on 2026-11-21 the owner answered a question that explained the conflict between public release and
  Principle V / docs/research/licenses.md with «نشر عام وأنا مسؤول» (public, and I take responsibility), and
  decided to release the app publicly and non-commercially on GitHub, itch.io and APKPure.
- Templates: .specify/templates/*.md not modified (they read this file at runtime).
- Follow-up TODOs: docs/research/licenses.md (header and the rows that said "private APK only") and README.md
  are updated in the same change set. The About screen (lib/settings/about_screen.dart) still says
  «تطبيق شخصي غير تجاري» and its KFGQPC credit says «تُستعمل في تطبيق شخصي غير تجاري»: both say "personal"
  and need a small follow-up feature edit (not part of this amendment).

Previous report (1.2.0):
- Version change: 1.1.0 → 1.2.0 (MINOR: materially expanded guidance in Principle III and in Scope and
  Distribution)
- Modified principles: III. Focus: Not an "Everything" App. The ban on duas keeps its words and gains one
  narrow exception: «دعاء ختم القرآن», one supplication shown only after the last page of the Mushaf, under
  rules that tie it to Principles I, II, IV, V and VI.
- Modified sections: Scope and Distribution (v1): the exception is listed as in scope by amendment (1.2.0).
- Added sections: none
- Removed sections: none
- Reason: the owner asked for «دعاء ختم القرآن» after the last page (feature 005); Principle III forbade duas
  and the Scope section requires an amendment first. Approved by the owner on 2026-11-20.
- Templates: .specify/templates/*.md not modified (they read this file at runtime).
- Follow-up TODOs: none for this file. Feature 005 must record the source of the dua's wording in
  docs/research/licenses.md and credit it in About (Principle V, Development Workflow), and the owner must
  confirm the wording word by word before the feature is done (Principle VI).
-->

# مصحف الحافظ (Mushaf al-Hafiz) Constitution

«مصحف الحافظ» is an Android-first Quran app for one person who reads a daily wird, memorises and
reviews, alone (no teacher). The Mushaf page is the centre; everything else opens from it and
returns to it.

## Core Principles

### I. Quran Text Integrity (NON-NEGOTIABLE)

- The Quran text, its order, and its distribution on pages and lines MUST never be modified. Any
  error in text, order or page/line distribution is a failure even if everything else works.
- The edition is fixed: Madinah Mushaf 1421H (QPC V2 / QCF V2), riwayat Hafs, 604 pages, 15 lines
  per page (pages 1–2 have 8 lines), with the same word-to-line distribution as the printed
  Mushaf. Page layout MUST come from QUL data for this exact edition, and every page/line
  reference in stored data MUST be based on it. (user decision)
- Generated Quran data MUST be validated automatically before it is used or shipped: 604 pages,
  correct line count per page, every word present exactly once and in order. A failed validation
  MUST stop the build.
- Large-ayah view (2.2.0): a separate view MAY show the ayat at a large size, 1 to 3 ayat per screen, with an ayah's
  words on new lines that are not the Mushaf's lines, and with an ayah too long for one screen split between two words
  onto consecutive screens. Under these rules:
  - Each word MUST be drawn as its own glyph in its page's QCF V2 font, the font the Mushaf page draws it with. No other
    font or text MAY stand in for a word.
  - Every word MUST appear exactly once and in order, with its ayah's end marker. No word, mark or ayah MAY be dropped,
    repeated or reordered, and this MUST be checked automatically over the whole Mushaf before the view ships.
  - The view MUST NOT change any stored Quran data, nor the Mushaf page, its lines or its geometry. A screen MUST NOT
    hold ayat of two pages and MUST show the Mushaf page number of what it shows; the position, the wirds and the
    bookmarks stay based on that page.
  - The view MUST NOT be presented as the Mushaf page.

Rationale: a memoriser learns the page; one wrong word or moved line breaks trust in the whole app.

### II. The Mushaf Comes First

- The app MUST open directly on a Mushaf page. No home screen, splash menu or list before it.
- Every feature (listening, memorising, review, tests) MUST start from the Mushaf page and MUST
  return to it.
- The app MUST NOT forget where the user stopped.
- Exception (2.2.0): when the reader left the large-ayah view of Principle I on, the app MAY open on it, at the ayat of
  the reader's position. A first install, and a reader who never turned it on, MUST open on the Mushaf page. The view
  MUST be turned on and off from the Mushaf, MUST return to the Mushaf page of the ayat it shows, and the features that
  start from the Mushaf page (the ayah sheet, bookmarks, wirds) MUST work from it as they do from the page.

Rationale: the previous project («حفظ») was built the other way round (a hifz tool with a text
viewer attached) and was abandoned for that reason.

### III. Focus: Not an "Everything" App

- The app MUST NOT add the full adhan recording, qibla, duas, hadith or other non-Quran features, except
  the one supplication and the prayer times allowed by the exceptions below.
- Exception (1.2.0): exactly one supplication, «دعاء ختم القرآن», shown only after the last page of the
  Mushaf is finished. It MUST be a separate screen reached only from the Mushaf and returning to it
  (Principle II); it MUST be bundled in the app and work fully offline (Principle IV); its wording MUST come
  from a named source recorded in `docs/research/licenses.md` and credited in About (Principle V), and the
  owner MUST confirm it word by word before the feature is called done (Principle VI); and it MUST be set
  apart from the Quran text and labelled as a supplication that is not part of the Quran text (Principle I).
- No other dua, no section or list of duas, no adhkar and no hadith MAY be added under this exception; any
  further dua needs a new amendment.
- Exception (2.0.0): prayer times and their notifications, and nothing more: today's times, a countdown to
  the next prayer, the choice of city, calculation method and Asr rule, a minute offset per prayer, a monthly
  table, and for each prayer a notification with a short sound and an optional reminder before it. Under
  these rules:
  - The Mushaf stays the first screen (Principle II). Prayer times MUST be a separate screen, and the
    feature MUST stay off until the reader turns it on.
  - Every time MUST be calculated on the phone with no network use (Principle IV).
  - Place (3.0.0): the place MAY come from the phone's location, under these rules: only the approximate
    (coarse) location permission, never the precise one; asked only when the reader taps the button that finds
    the place, never at start and never in the background; the coordinates are kept on the phone only, are never
    sent anywhere, and are used for nothing but prayer times. If the reader refuses or the phone cannot find the
    place, the city MUST be choosable from a list bundled in the app. No network is used either way.
  - The only new permissions MAY be the approximate location permission (above) and the exact-alarm permission. If the reader refuses it, the notifications
    MUST still work in inexact mode and the app MUST say that they may be a few minutes late.
  - The calculation library, the city list and the sound MUST each be recorded with its licence in
    `docs/research/licenses.md` and credited in About (Principle V).
  - The notifications MUST be checked on a real Samsung phone, with the screen locked and the app closed,
    before the feature is called done (Principles VII and IX).
- The full adhan recording, qibla, a prayer log or qada counter, home-screen widgets, adhkar and hadith stay
  out; each needs a new amendment.

Rationale: that is Muslim Pro's ground and would dilute the product (competitor research,
docs/research/2026-11-20-competitor-analysis.md). Prayer times are allowed because the owner asked for them
and they can be kept offline, permission-light and out of the Mushaf's way (study,
docs/research/2026-11-25-prayer-times-study.md).

### IV. Offline, Private, Free

- Every feature MUST work fully offline. The only allowed network use is the first download of
  recitation audio, started by the user.
- The app MUST NOT contain ads, analytics, tracking or paywalls. No user data MAY leave the device.
  There MUST be no accounts, no server and no sync.
- Backup MUST be by exporting/importing a file only.
- Web version (1.4.0): the website MUST be static files only, with no server code, no account, no database
  outside the browser and no sync. Fetching the site's own files from its own address is the only network
  use added; the site MUST NOT request anything from any other host and MUST NOT use analytics, including
  any visitor statistics the host offers. Reader data (position, wirds, bookmarks, notes, settings, search
  text) MUST stay in the browser. After the first visit, the app and every page already opened MUST work
  with no connection, and the reader MUST be able to fetch the whole Mushaf for offline use on request.

Rationale: offline use and no ads/tracking are the main reasons users pick a Quran app, and
ads/paywalls are the main complaints about competitors.

### V. Licensing and Attribution

- Every external resource (Mushaf fonts, page layout data, metadata, mutashabihat data, gharib
  al-Quran data, audio files) MUST have its licence read and recorded in
  `docs/research/licenses.md` before any feature depends on it.
- If a resource's licence does not allow our use, work MUST stop and the question MUST go back to
  the user. A licence MUST NOT be worked around silently.
- Every resource MUST be credited visibly in the About screen.
- Distribution is a free, non-commercial APK that the owner MAY publish publicly (a GitHub repository
  and release, itch.io, APKPure). (user decision, 2026-11-21: «نشر عام وأنا مسؤول»)
- Google Play (2.1.0): the owner MAY publish the same free, non-commercial app on Google Play from his personal developer
  account, as an Android App Bundle under Play App Signing with a key Google makes. The listing MUST have a privacy policy
  page that says no data is collected, a Data safety form that declares no data collected or shared, no ads, and the
  credits the About screen shows. Play's own rules (target API level, the closed test of a personal account, size limits)
  are met as Play states them at the time of upload, never worked around. The bullets on responsibility and take-down below
  apply to the Play listing in full. (user decision, 2026-11-25)
- The owner accepts responsibility for the third-party resources whose licences are unpublished or
  restricted: the KFGQPC/QUL layout, fonts and word data (no licence published); Tanzil's Saheeh
  International (non-commercial only, with attribution and a link back to tanzil.net); the tafsir
  of al-Sa'di via QUL (no licence information); Quranpedia (free to use in apps, a link is appreciated);
  and the fonts under the SIL Open Font License. Each one's status stays recorded in
  `docs/research/licenses.md` without invented licence texts.
- Public release does not loosen any other rule: the app MUST stay non-commercial, ad-free,
  tracking-free and offline (Principle IV); every resource MUST stay credited visibly in the About
  screen; the Quran text MUST NOT be modified (Principle I). If any rights holder objects, the owner
  MUST take the affected resource out of the app or take the app down.
- Web version (1.4.0): distribution also includes a free, non-commercial static website, hosted on Vercel
  by the owner's decision of 2026-11-21. The 604 Mushaf fonts and the layout data are served as public
  files of the site, on the same stance and the same owner's responsibility as the APK, and the bullet
  above applies to the site in full. The site's About screen MUST show every credit the Android About
  screen shows and MUST tell a rights holder where to object. If a rights holder objects, the owner MUST
  take the affected resource out of the site or take the site down.

Rationale: the app is built on others' scholarly and technical work; using it honestly is part of
the product's integrity.

### VI. Arabic and Right-to-Left

- The whole UI MUST be Arabic and right-to-left.
- Page turning MUST follow the paper Mushaf: the next page comes in from the left (the finger
  swipes left→right), as in Quran Android.
- Arabic UI strings MUST be written as specified in each feature and MUST NOT be machine-translated
  from English.

Rationale: the user reads and thinks in Arabic, and the Mushaf on screen must behave like the one
in their hands.

### VII. Reliability Where Competitors Fail

- Audio MUST keep playing when the screen is locked.
- The reading position MUST survive app restarts, device restarts and day changes.
- Reminders MUST be local notifications scheduled by the phone itself, never sent from a server.
- Web version (1.4.0): reminders are an Android-only capability. The web version MUST NOT offer reminders
  or ask for notification permission, and MUST say in its settings that reminders are in the Android app
  only; it MUST NOT show a control that looks as if it works and does not. On the web the reading position
  MUST survive reloads, browser restarts and device restarts in the same browser, and the reader MUST be
  told that clearing the site's data erases it.

Rationale: lost positions, audio that stops on lock, and missing reminders are the recurring
complaints about existing Quran apps.

### VIII. App Size

- Quran text, layout and data MUST be bundled in the app.
- Audio MUST be downloaded on demand and MUST be deletable by the user.
- Web version (1.4.0): "bundled" means served from the site's own address and kept by the browser. A first
  visit MUST NOT download more than 15 MB before the first page is readable, and the whole set of Mushaf
  resources (about 170 MB) MUST NOT be downloaded unless the reader asks for it, after being told its size.
  A page MUST be shown only when its own font and layout are ready (Principle I).

Rationale: reading must never wait for a download, while audio is too large to ship for every
reciter.

### IX. Quality Gates

- Test-first: a failing test MUST be written before the code that makes it pass.
- Pure logic (portion maths, position rules, reminder planning, review rules, question
  generation) MUST be separated from UI code and unit-tested.
- Static analysis MUST report no issues and all tests MUST pass before a feature is done.
- Behaviour that tests can't prove (rendering on a real phone, swipe direction, notifications with
  the screen locked, airplane mode) MUST be checked on a real Android device before a feature that
  ships on Android is called done.
- Web version (1.4.0): a feature that ships on the web MUST be checked in a real browser on a phone and in
  a real browser on a desktop before it is called done (rendering, turning direction, reload and return,
  airplane mode after a first visit), in addition to the automated gates above. A feature that ships on
  both targets needs both checks.
- Commits MUST be small: one per completed task.

Rationale: a Quran app tolerates no silent regressions, and the riskiest behaviour only shows on a
real device.

## Scope and Distribution (v1)

- One user on one phone. Android first; iPhone is not tested in v1.
- Web version (by amendment 1.4.0): the same app as a static website is a supported target, under the web
  rules of Principles IV, V, VII, VIII and IX. It is checked on a current Chrome on an Android phone and on
  a current desktop browser; Safari on iPhone is not a gate. The backup file is the only bridge between the
  browser and the phone. The Android app MUST NOT change behaviour, permissions or data format because of
  the web version.
- Distribution (by amendment 1.3.0): a free, non-commercial APK that the owner MAY publish publicly
  (GitHub repository and release, itch.io, APKPure), by the owner's decision of 2026-11-21 and on the
  owner's responsibility for the third-party resources named in Principle V. Google Play (by amendment 2.1.0) is an
  allowed channel under the Play bullet of Principle V.
  The non-commercial, ad-free, tracking-free and offline rules, the visible credits in About and the
  no-modification rule for the Quran text apply in full.
- In scope by amendment (1.1.0): exactly one translation, the English translation Saheeh
  International. It MUST be bundled in the app, shown only from an ayah's menu, set apart from and
  never replacing the Quran text (Principle I), and credited in About (Principle V).
- In scope by amendment (1.2.0): exactly one supplication, «دعاء ختم القرآن», shown once after the last page
  of the Mushaf, under the rules of Principle III. Any other dua, adhkar or hadith stays out of scope.
- In scope by amendment (2.0.0): prayer times and their notifications with a short sound, under the rules
  of Principle III. The full adhan recording, qibla, a prayer log, a qada counter and home-screen widgets
  stay out of scope.
- In scope by amendment (3.0.0): the approximate location, for prayer times only, under the place rule of Principle III.
- In scope by amendment (2.2.0): the large-ayah view (1 to 3 ayat per screen at a large size, long ayat split over
  screens), under the rules of Principles I and II. It is a separate view, never a replacement for the Mushaf page.
- Out of scope for now: voice recitation with automatic mistake detection, teacher/halaqa mode,
  accounts, sync, server, other reciters beyond those a feature specifies, live streaming,
  any translation other than the one named above (any other translation or language), family
  profiles.
- Any feature that needs something on this list MUST first amend this constitution.

## Development Workflow

- Each feature goes through the Spec Kit full path: specify → clarify → plan → checklist → tasks →
  analyze → implement → converge (repeat implement/converge until converged).
- Every plan MUST pass the Constitution Check against Principles I–IX before tasks are generated;
  any deviation MUST be justified in the plan's Complexity Tracking or the plan is rejected.
- A feature that adds an external resource MUST add its entry to `docs/research/licenses.md` and
  to the About screen in the same feature.
- A feature is done only when Principle IX's gates pass, including the real-device check (Android) and the
  real-browser check (web) for the targets it ships on.

## Governance

- This constitution supersedes all other practices, plans and specs in this repository. Where a
  spec or plan conflicts with it, the constitution wins until it is amended.
- Amendments MUST be made through `/speckit-constitution`, stating the change and its reason, and
  MUST be approved by the project owner before dependent specs and plans are updated.
- Versioning follows semantic versioning: MAJOR for removing or redefining a principle, MINOR for
  a new principle or section or materially expanded guidance, PATCH for clarifications and wording.
- Compliance review: `/speckit-analyze` and `/speckit-converge` MUST treat a violated MUST in this
  document as the highest-severity finding.

**Version**: 3.0.0 | **Ratified**: 2026-11-20 | **Last Amended**: 2026-11-26
