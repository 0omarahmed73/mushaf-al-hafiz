<!--
Sync Impact Report
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

Rationale: a memoriser learns the page; one wrong word or moved line breaks trust in the whole app.

### II. The Mushaf Comes First

- The app MUST open directly on a Mushaf page. No home screen, splash menu or list before it.
- Every feature (listening, memorising, review, tests) MUST start from the Mushaf page and MUST
  return to it.
- The app MUST NOT forget where the user stopped.

Rationale: the previous project («حفظ») was built the other way round (a hifz tool with a text
viewer attached) and was abandoned for that reason.

### III. Focus: Not an "Everything" App

- The app MUST NOT add adhan, qibla, duas, hadith or other non-Quran features, except the one supplication
  allowed by the exception below.
- Exception (1.2.0): exactly one supplication, «دعاء ختم القرآن», shown only after the last page of the
  Mushaf is finished. It MUST be a separate screen reached only from the Mushaf and returning to it
  (Principle II); it MUST be bundled in the app and work fully offline (Principle IV); its wording MUST come
  from a named source recorded in `docs/research/licenses.md` and credited in About (Principle V), and the
  owner MUST confirm it word by word before the feature is called done (Principle VI); and it MUST be set
  apart from the Quran text and labelled as a supplication that is not part of the Quran text (Principle I).
- No other dua, no section or list of duas, no adhkar and no hadith MAY be added under this exception; any
  further dua needs a new amendment.

Rationale: that is Muslim Pro's ground and would dilute the product (competitor research,
docs/research/2026-11-20-competitor-analysis.md).

### IV. Offline, Private, Free

- Every feature MUST work fully offline. The only allowed network use is the first download of
  recitation audio, started by the user.
- The app MUST NOT contain ads, analytics, tracking or paywalls. No user data MAY leave the device.
  There MUST be no accounts, no server and no sync.
- Backup MUST be by exporting/importing a file only.

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
  and release, itch.io, APKPure). Google Play is still not planned, so store-policy work is not needed.
  (user decision, 2026-11-21: «نشر عام وأنا مسؤول»)
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

Rationale: lost positions, audio that stops on lock, and missing reminders are the recurring
complaints about existing Quran apps.

### VIII. App Size

- Quran text, layout and data MUST be bundled in the app.
- Audio MUST be downloaded on demand and MUST be deletable by the user.

Rationale: reading must never wait for a download, while audio is too large to ship for every
reciter.

### IX. Quality Gates

- Test-first: a failing test MUST be written before the code that makes it pass.
- Pure logic (portion maths, position rules, reminder planning, review rules, question
  generation) MUST be separated from UI code and unit-tested.
- Static analysis MUST report no issues and all tests MUST pass before a feature is done.
- Behaviour that tests can't prove (rendering on a real phone, swipe direction, notifications with
  the screen locked, airplane mode) MUST be checked on a real Android device before a feature is
  called done.
- Commits MUST be small: one per completed task.

Rationale: a Quran app tolerates no silent regressions, and the riskiest behaviour only shows on a
real device.

## Scope and Distribution (v1)

- One user on one phone. Android first; iPhone and web are not tested in v1.
- Distribution (by amendment 1.3.0): a free, non-commercial APK that the owner MAY publish publicly
  (GitHub repository and release, itch.io, APKPure), by the owner's decision of 2026-11-21 and on the
  owner's responsibility for the third-party resources named in Principle V. Google Play is not planned.
  The non-commercial, ad-free, tracking-free and offline rules, the visible credits in About and the
  no-modification rule for the Quran text apply in full.
- In scope by amendment (1.1.0): exactly one translation, the English translation Saheeh
  International. It MUST be bundled in the app, shown only from an ayah's menu, set apart from and
  never replacing the Quran text (Principle I), and credited in About (Principle V).
- In scope by amendment (1.2.0): exactly one supplication, «دعاء ختم القرآن», shown once after the last page
  of the Mushaf, under the rules of Principle III. Any other dua, adhkar or hadith stays out of scope.
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
- A feature is done only when Principle IX's gates pass, including the real-device check.

## Governance

- This constitution supersedes all other practices, plans and specs in this repository. Where a
  spec or plan conflicts with it, the constitution wins until it is amended.
- Amendments MUST be made through `/speckit-constitution`, stating the change and its reason, and
  MUST be approved by the project owner before dependent specs and plans are updated.
- Versioning follows semantic versioning: MAJOR for removing or redefining a principle, MINOR for
  a new principle or section or materially expanded guidance, PATCH for clarifications and wording.
- Compliance review: `/speckit-analyze` and `/speckit-converge` MUST treat a violated MUST in this
  document as the highest-severity finding.

**Version**: 1.3.0 | **Ratified**: 2026-11-20 | **Last Amended**: 2026-11-21
