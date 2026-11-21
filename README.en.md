<div align="center">

[العربية](README.md) · **English**

# Mushaf al-Hafiz

**مصحف الحافظ**

The Madinah Mushaf on your phone, laid out as it is in print, with your daily wird, your bookmarks and a search that forgives your spelling.

Offline · No ads · No tracking · Free and non-commercial

Android 7.0 or newer · Version 1.0.0 · The interface is Arabic only

</div>

<!-- TODO screenshots: add a gallery here (the same list as docs/release/STORE_LISTINGS.md):
     1. A full 15-line Mushaf page (for example page 50) with the bars hidden, in the Emerald & Gold look.
     2. The same page with the bars shown (juz, hizb and surah on top; the bottom bar).
     3. Page 1 or 2 (the 8 centred lines) or page 293 (the al-Kahf banner).
     4. The wirds list with «ملخص اليوم» (today's summary) open (at least two wirds: reading and night prayer).
     5. The ayah menu after a long press, showing Tafsir al-Sa'di.
     6. The English translation, or the word-meanings view.
     7. The same page in the Night Reader look.
     8. Settings (reminders, text size, look, backup).
     9. About, showing the credits.
     10. The khatm dua screen.
     11. The search screen with results for a few words of an ayah typed without hamzas (the «السور» and «الآيات» groups).
     Also: the square app icon, and a cover image for the itch.io page (630 x 500).
     Never edit the Quran pages in a picture: crops and device frames only. -->

## Contents

- [What is Mushaf al-Hafiz?](#about)
- [Principles](#principles)
- [What it does](#features)
- [Download and install](#install)
- [Privacy and permissions](#privacy)
- [A quick tour](#guide)
- [Building from source](#build)
- [Project structure](#structure)
- [How it works inside](#architecture)
- [Testing](#testing)
- [Specs and the constitution](#specs)
- [Contributing](#contributing)
- [Licences and sources](#licences)
- [FAQ](#faq)
- [Author and dedication](#credits)

<a id="about"></a>

## 📖 What is Mushaf al-Hafiz?

An Android app for reading the **Madinah Mushaf** (1421H edition, riwayat Hafs 'an 'Asim): 604 pages of 15 lines each,
with the same words on the same lines as the printed Mushaf.

It opens straight on a Mushaf page, at the place where you stopped. There is no home screen and no menu in front of the
Mushaf: everything else opens from the page and returns to it.

It is made for someone who reads a daily wird and wants a quiet Mushaf that remembers their place and offers nothing else
to distract them.

| | |
|---|---|
| Platform | Android 7.0 or newer |
| Size | about 180 MB |
| Language | the interface is Arabic only, right to left |
| Price | free; no payments, no donations, no in-app purchases |
| Internet | not needed, and the permission is not even requested |
| Package name | `app.hafiz.mushaf` |

<a id="principles"></a>

## 🧭 Principles

These are written down in the [project constitution](.specify/memory/constitution.md), and every feature is checked
against them before it is built.

| Principle | What it means |
|---|---|
| **The Quran text is never modified** | The text, its order and its distribution over pages and lines are validated automatically when the data is generated; a failed check stops the build |
| **The Mushaf comes first** | The app opens on a Mushaf page and never forgets your place |
| **A focused app** | A Mushaf and a wird, nothing more. No adhan, no qibla, no adhkar. The one exception is the khatm dua after the last page |
| **Offline and private** | No ads, no analytics, no accounts, no server, no sync. Nothing leaves the phone |
| **Honest licensing** | Every source has its licence read and recorded, and is credited in the About screen |
| **Arabic, right to left** | Pages turn like the paper Mushaf, and the owner reviews the interface text word by word |
| **Test first** | The test is written before the code, and a feature is not done until every test passes |

<a id="features"></a>

## ✨ What it does

### Reading the Mushaf

- **The page as it is in print:** each of the 604 pages has its own font (the QCF V2 fonts of the King Fahd Complex), so every word and line sits where it does on paper.
- **Turns like the paper Mushaf:** swipe the page from left to right to go to the next one.
- **Remembers your place** between launches and after the phone restarts.
- **A top bar** with the juz, hizb, quarter, surah name and page number, and a bottom bar for bookmarks, wirds and the menu. A tap on the page hides and shows both.
- **An index** by surah, juz and page, and "go to page" by number.
- **Pinch to zoom** up to 3x.
- **Reading size:** eight steps from 80% to 150% make the Mushaf page itself bigger or smaller without changing its layout. A page bigger than the screen is moved with a finger.
- **Landscape:** the page keeps its shape, and both bars are shown there too.
- **The khatm dua:** swiping past page 604 opens the dua screen, then you are back at page 1.

### Wirds and the khatma

- **More than one wird:** a reading wird and a night-prayer (qiyam) wird, each with its own name, colour and position.
- **The daily portion:** a number of pages per day, or a finish date from which the app works out each day's share. With neither, the portion is 20 pages.
- **«ملخص اليوم» (today's summary):** a panel that shows what is due today in each wird (from page X to page Y), with a «تم» (done) button for when you finish.
- **A khatma counter:** after page 604 the wird returns to page 1 and the counter goes up.
- **Browsing does not move your wird:** if you jump to a distant page (from the index, the search or a bookmark) the reader enters «تصفح» (browse) mode, and the wird stays where it was until you press «اجعلها موضعي» (make this my position).
- **The qiyam day** starts at 4 a.m., so what you read after midnight counts for that night.

### Reminders

- **A daily reminder per wird,** at the time you choose.
- **A Surat al-Kahf reminder,** on the day you choose: Thursday (the eve of Friday) or Friday.
- **Entirely local:** the phone schedules them itself, they show with the screen locked, and they are rescheduled after a restart. No server sends them.

### Bookmarks

- **One tap:** an icon under the juz number bookmarks the page; another tap removes the bookmark.
- **Undo:** a message with «تراجع» (undo) follows every add and every removal.
- **An optional note** with each bookmark, which is kept under your wird or as a general bookmark.
- **All your bookmarks** are under «علامات» in the bottom bar.

### Search

- **Surah names and the Quran text** from one field, with the results in two groups: surahs, then ayat.
- **Forgiving of spelling:** type without hamzas or tashkeel, «ه» for «ة», «ي» for «ى», in everyday spelling, and the word is still found in the Mushaf's own spelling. Paste it exactly as the Mushaf writes it, with every mark, and it is found too.
- **Choosing a result** opens its page and highlights the ayah until you touch the screen. It does not move your wird.
- **Its limits:** it searches one ayah at a time (a phrase that ends one ayah and begins the next is not found), lists the first 100 ayat alongside the true total, and does not search the tafsir or the translation.

### The ayah menu

A long press on any word of an ayah opens its menu:

| Item | What it shows |
|---|---|
| التفسير (tafsir) | Tafsir al-Sa'di (Taysir al-Karim al-Rahman) |
| الترجمة (translation) | The English translation, Saheeh International |
| معاني الكلمات (word meanings) | Difficult words, from the books of Ibn al-Ha'im (al-Tibyan) and Ibn al-Jawzi (Tadhkirat al-Arib) |
| مشاركة (share) | The ayah as text, with the surah name and ayah number |
| مشاركة الصفحة كصورة | The page as a picture, as you see it |
| مشاركة السورة PDF | The whole surah as a PDF of A4 pages |

The tafsir, translation and meanings are shown in the interface font, set apart from the Quran text and labelled as a
human explanation that is not part of the Quran. Sharing goes through the phone's own share sheet, and you pick the app
it is sent with.

### Looks and comfort

- **Two looks:** «زمردي وذهبي» (Emerald & Gold) and «القارئ الليلي» (Night Reader). The look applies to the whole app and to the picture and PDF you share.
- **Text size** for the tafsir, translation and word meanings, on the same slider that sizes the page, with a live preview.
- **Smooth motion:** pages turn without stutter, and the bars, the today panel and a jump to a distant page move softly. If you have switched animations off in your phone's settings, nothing moves.
- **First-run tips:** six short steps shown once, which you can skip at any moment.
- **An icon and a splash:** the "open Mushaf" icon, and a short dark splash that ends by itself or at a tap.

### Backup

- **Export:** one file holding your wirds, bookmarks and settings, to keep or send wherever you like.
- **Import:** replaces everything in the app with what is in the file, after you confirm. A damaged or foreign file is refused and nothing changes.

### What it does not have

No recitation audio and no memorisation or review tools in this version. The «استماع» (listen) and «اختبار» (test) buttons in the bottom bar are labelled «قريباً» (soon) and are switched off.

<a id="install"></a>

## 📥 Download and install

The app is not on Google Play. You download an APK file from the releases page:

- Releases: [github.com/0omarahmed73/mushaf-al-hafiz/releases](https://github.com/0omarahmed73/mushaf-al-hafiz/releases)
- File: `mushaf-hafiz-v1.0.0.apk` (about 180 MB)

**Installing on Android:**

1. Download the APK to your phone.
2. Open the file from the notification or from your file manager.
3. If Android says installs from this source are not allowed, tap "Settings" in that message, allow it for the app you are opening the file from (your browser or file manager), and go back.
4. Tap "Install".
5. On the first launch the app asks once for permission to send notifications. Allow it if you want reminders; if you decline, the «السماح بالإشعارات» button in Settings asks again later.

**Why 180 MB?** Because the Mushaf's fonts and data are all inside the app: each of the 604 pages has its own font, alongside the text, the tafsir and the translation. That is why the app downloads nothing after it is installed.

<details>
<summary>Verify the file (optional)</summary>

The release page gives the file's SHA-256. On your computer:

```bash
sha256sum mushaf-hafiz-v1.0.0.apk
```

Compare the output with the published value. If they differ, do not install the file.

</details>

<details>
<summary>I have an older test build</summary>

If the older build was signed with a different key, Android will refuse to update it. Export a backup first, uninstall the old build, install the new one, then import the backup.

</details>

<a id="privacy"></a>

## 🔒 Privacy and permissions

**The app collects no data and does not request the Internet permission.** Your wirds, positions, bookmarks and settings are stored on your phone only.

The permissions declared in the app's manifest ([AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)):

| Permission | Why | Does anything leave the phone? |
|---|---|---|
| `POST_NOTIFICATIONS` | to show the wird reminders and the Surat al-Kahf reminder | No |
| `RECEIVE_BOOT_COMPLETED` | to reschedule the reminders after the phone restarts | No |

The notification and background-task libraries add a few more to the final APK. This is what a check of the release file showed on 2026-11-21:

| Permission | Where it comes from | What it allows |
|---|---|---|
| `VIBRATE` and `WAKE_LOCK` | the notification and background-task libraries | vibrating for a notification, and keeping the phone awake for the moment a task runs |
| `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_SHORT_SERVICE` | the notification and background-task libraries | running a short task that reschedules the reminders |
| `ACCESS_NETWORK_STATE` | a library (most likely the background-task one) | reading whether a network exists, nothing more. It cannot send anything |
| `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | the app's own internal permission | nothing that concerns the user |

- **No `INTERNET` permission** in the release build. It exists only in the two development manifests (`debug` and `profile`), which are not part of a release.
- **No exact-alarm permission:** reminders are scheduled in inexact mode, so one may arrive a few minutes late.
- **Sharing** (text, picture, PDF or a backup) is started by you and goes through the phone's share sheet.
- **The links in About** open in your phone's browser when you tap them.

You can check the permissions of any APK yourself:

```bash
aapt2 dump permissions mushaf-hafiz-v1.0.0.apk
```

<a id="guide"></a>

## 👆 A quick tour

These are the gestures, as the first-run tips explain them:

| To… | Do this |
|---|---|
| go to the next page | swipe the page from left to right, as in the paper Mushaf |
| open the index | tap the surah name at the top |
| go to a particular page | tap the page number at the top |
| search for a surah or an ayah | open the index, then tap the search icon |
| hide or show the two bars | tap the page once |
| zoom in | put two fingers on the page and move them apart |
| open the ayah menu | long-press any word of the ayah |
| see today's wird | tap «ملخص اليوم» at the top, then «تم» when you finish |
| add a wird | tap «أوراد» at the bottom |
| bookmark the page | tap the bookmark icon under the juz number; tap again to remove it |
| see all your bookmarks | tap «علامات» at the bottom |
| change the text size or the look | tap «القائمة» at the bottom to open Settings |
| make the shown page your wird's position | tap «اجعلها موضعي» |

<a id="build"></a>

## 🛠️ Building from source

> **This repository alone does not build a working app.** It contains neither the Mushaf fonts nor its data.

`data-raw/`, `assets/mushaf/`, `assets/ayah/` and `assets/fonts/qpc-v2/` are kept out of the repository on purpose (see
[.gitignore](.gitignore)), because their sources publish no explicit licence for redistribution. The released APK does
contain them, because the app's owner accepted that responsibility (see [Licences and sources](#licences)).

So you download the data from its sources yourself, and two scripts generate the files the app needs. **The scripts
download nothing themselves.**

### Requirements

| Tool | Version |
|---|---|
| Flutter | 3.50 (Dart 3.14) with the Android toolchain |
| Java | 17 |
| [uv](https://docs.astral.sh/uv/) | to run the Python scripts |

### Step 1: download the data into `data-raw/`

Read each source's terms first in [docs/research/licenses.md](docs/research/licenses.md).

| Source | What to download |
|---|---|
| [QUL](https://qul.tarteel.ai) | the QPC V2 15-line page layout (`qpc-v2-15-lines.db`), the QPC V2 script (`qpc-v2.json`), the per-page QCF V2 fonts (`p1.woff2` … `p604.woff2`), the word-by-word Quran text (resource 312) and Tafsir al-Sa'di (resource 24) |
| [Tanzil](https://tanzil.net) | `quran-data.js` (surah and juz data), `quran-uthmani.txt` (a cross-check only; never bundled) and the `en.sahih` translation |
| [Quranpedia](https://quranpedia.net/dumps) | `meanings.json.gz` |

The exact file names and folders are in the
[Mushaf assets contract](specs/001-mushaf-reader-wirds/contracts/assets.md) and the [ayah assets contract](specs/002-ayah-actions-sharing/contracts/assets.md).

### Step 2: generate the Mushaf data, then the ayah data

```bash
uv run --with 'fonttools[woff]' python tool/build_quran_assets.py
uv run python tool/build_ayah_assets.py
```

Each script validates the text before it writes any file, and stops if anything is off. The first writes
`assets/mushaf/` and `assets/fonts/qpc-v2/`; the second writes `assets/ayah/` and records each source file's name,
version and checksum in `assets/ayah/sources.json`.

### Step 3: build the app

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

<details>
<summary>Building and signing a release</summary>

`tool/release.sh` checks that the data and all 604 fonts are present, builds the APK, copies it to
`build/release/mushaf-hafiz-v1.0.0.apk` and prints its size and SHA-256.

```bash
tool/release.sh
```

It needs `android/key.properties` (see [docs/release/SIGNING.md](docs/release/SIGNING.md)). For a test build signed with the debug key, which must not be published:

```bash
ALLOW_DEBUG_SIGNED=1 tool/release.sh
```

</details>

<details>
<summary>Other scripts in <code>tool/</code></summary>

| Script | What it does |
|---|---|
| `tool/make_app_icons.dart` | draws the app icon and writes its files into `android/app/src/main/res/`. Run it with `flutter test tool/make_app_icons.dart` |
| `tool/make_cairo_instances.py` | cuts the four weights of the Cairo font out of its variable file, changing no glyph |
| `tool/make_public_tree.sh` | makes the public copy of the repository with a clean history |

</details>

<a id="structure"></a>

## 🗂️ Project structure

| Path | What is in it |
|---|---|
| `lib/mushaf/` | the reader: the Mushaf page and its layout, page turning and zoom, the index, the bookmark button |
| `lib/wirds/` | wirds, bookmarks, the database (Drift) and the daily-portion arithmetic |
| `lib/reminders/` | planning and scheduling the reminders, and the al-Kahf day |
| `lib/ayah/` | the ayah menu: tafsir, translation, meanings and sharing |
| `lib/search/` | search: Arabic folding, the ayah index, the results screen |
| `lib/render/` and `lib/pdf/` | drawing a page as a picture, and writing the PDF |
| `lib/look/` and `lib/theme.dart` | the two looks and their colours |
| `lib/settings/` | Settings, text size, About |
| `lib/backup/` | exporting and importing the backup |
| `lib/khatm/` | the khatm dua |
| `lib/onboarding/` | the first-run tips |
| `lib/splash/` | the icon and the splash |
| `lib/motion/` | the durations and curves of the motion |
| `test/` | the Dart tests, one folder per part of `lib/`, with `test/support/` for shared helpers |
| `tool/` | the data-generation scripts and their tests, and the release script |
| `specs/` | the spec of every feature, 001 to 011: spec, plan, tasks and contracts |
| `.specify/memory/constitution.md` | the project constitution |
| `docs/research/` | the licence record and the competitor research |
| `docs/release/` | release notes, signing, the publishing checklist, the store texts |
| `docs/design/` | the two looks described |
| `assets/fonts/` | the interface fonts (Amiri Quran, Reem Kufi and Cairo), each with its `OFL.txt` |
| `assets/khatm/` | the text of the khatm dua |
| `android/` | the Android project |

<a id="architecture"></a>

## ⚙️ How it works inside

| Aspect | Choice |
|---|---|
| Framework | Flutter (Dart), Android only |
| Database | [Drift](https://pub.dev/packages/drift) over SQLite: wirds, their days, bookmarks and settings |
| State | [provider](https://pub.dev/packages/provider) with `ChangeNotifier` |
| Reminders | `flutter_local_notifications` with `timezone`, and a daily `workmanager` background task that replans them |
| Sharing and files | `share_plus` and `file_picker` |
| PDF and pictures | the project's own code in `lib/pdf/` and `lib/render/`, with no outside library |

**How a page is drawn.** Each page has a JSON file with its lines and the words of each line, and a font of its own that
is loaded once, when it is needed. The font size is worked out from the page width, so the lines fill the page as they do
in print whatever the screen. Changing the reading size scales the whole page; it never re-flows the words.

**How the data is generated.** Two Python scripts in `tool/` read the raw files and copy the text and glyphs exactly as
they are, only re-arranging them into one file per page and per surah. Before writing anything they check: 604 pages, 15
lines on each (8 on the first two), 114 surahs, 6,236 ayat, and every word present exactly once and in order.

**How the search works.** The first search builds an in-memory index of the ayat from the stored text. The text and
what you type are folded by the same rules (hamzas, tashkeel, tatweel, the Mushaf's spelling) and then compared. The
folded text is only ever compared, never shown: what you see in the results is the Mushaf's own words.

**Logic kept apart from the interface.** The daily-portion arithmetic, the reminder planning, the Arabic folding and the
backup format are plain Dart, tested by themselves.

<a id="testing"></a>

## ✅ Testing

The project is built test first: a failing test is written, then the code that makes it pass.

- **2,067 tests** in `test/`, all passing, and `flutter analyze` reports nothing (as of 2026-11-21).
- Python tests for the two data-generation scripts, in `tool/`.

```bash
flutter analyze
flutter test
flutter test test/search
dart format --output=none --set-exit-if-changed lib test tool
uv run --with pytest --with 'fonttools[woff]' pytest tool/
```

**What is tested?** The logic (daily portions, reminders, folding and search, the backup), the interface (the reader,
the ayah menu, Settings, the tips), that the page's geometry is unchanged after every feature in both looks, contrast
and screen-reader names, and the Arabic interface strings, pinned letter by letter.

**What the automated tests do not cover.** The app has been tried on one phone only, and some on-phone checks are still
open: how long the page picture and the PDF of the longest surahs take, the large and small text sizes, the Night look
on every screen, and the khatm dua flow.

<a id="specs"></a>

## 📐 Specs and the constitution

The project is spec-driven, using [Spec Kit](https://github.com/github/spec-kit):

1. **The constitution,** in [.specify/memory/constitution.md](.specify/memory/constitution.md): nine principles that may not be broken. Changing it is a recorded amendment that the project owner approves.
2. **Each feature has a folder in `specs/`** with `spec.md` (user stories and acceptance criteria), then `plan.md` (the plan and its check against the constitution), then `tasks.md` (small ordered tasks), together with the interface and data contracts.
3. **Each task is one small commit,** and starts with a test.

| Feature | Folder |
|---|---|
| The reader, wirds, reminders and backup | [specs/001-mushaf-reader-wirds](specs/001-mushaf-reader-wirds/spec.md) |
| The ayah menu and sharing | [specs/002-ayah-actions-sharing](specs/002-ayah-actions-sharing/spec.md) |
| Text size | [specs/003-reader-font-size](specs/003-reader-font-size/spec.md) |
| The Night Reader look | [specs/004-night-reader-theme](specs/004-night-reader-theme/spec.md) |
| The khatm dua | [specs/005-khatm-dua](specs/005-khatm-dua/spec.md) |
| The bookmark button | [specs/006-bookmark-button](specs/006-bookmark-button/spec.md) |
| The al-Kahf reminder day | [specs/007-kahf-day](specs/007-kahf-day/spec.md) |
| First-run tips | [specs/008-first-run-tips](specs/008-first-run-tips/spec.md) |
| The icon and the splash | [specs/009-app-icon-splash](specs/009-app-icon-splash/spec.md) |
| Smooth motion | [specs/010-smooth-motion](specs/010-smooth-motion/spec.md) |
| Search of surahs and ayat | [specs/011-surah-ayah-search](specs/011-surah-ayah-search/spec.md) |

<a id="contributing"></a>

## 🤝 Contributing

Reports and suggestions are welcome: open an issue at [github.com/0omarahmed73/mushaf-al-hafiz/issues](https://github.com/0omarahmed73/mushaf-al-hafiz/issues).
If you found a mistake, say which page or ayah, what you saw, what you expected, and your Android version.

If you want to change the code, open an issue first so we can agree on the idea, then keep to these rules:

- **The Quran text is not touched.** Not the text, its order or its distribution; generated files are never edited by hand, only rebuilt from their sources by the two scripts.
- **Generated data is validated.** Any change to the generation scripts keeps their checks and adds a test.
- **No copyrighted material without a recorded licence.** Any new font, text or data has its licence read and recorded in [docs/research/licenses.md](docs/research/licenses.md) before it is used, and its owner is credited in About. The Mushaf's files and fonts are never added to the repository.
- **Offline and private.** No library that talks to the network or collects data.
- **Test first,** in small commits.
- **Arabic interface text** is written in Arabic directly, never machine-translated, and the project owner reviews it.

Before you send a change, run the checks:

```bash
flutter analyze
flutter test
uv run --with pytest --with 'fonttools[woff]' pytest tool/
```

<a id="licences"></a>

## 📜 Licences and sources

### The app's code: MIT

The app's own code is under the MIT licence (see [LICENSE](LICENSE)): you may use, change and redistribute it, as long as you keep the copyright notice and the licence text.

**What the licence covers:** what was written for this project: the Dart code in `lib/` and `test/`, the scripts in `tool/`, the Android project configuration, and the specs and documents.

**What it does not cover:** the Quran text, the page layout and the Mushaf fonts; the tafsir, the translation and the word meanings; the wording of the dua; and the interface fonts. Each keeps its owner's terms, as in the tables below.

### Fonts bundled in the repository: SIL OFL 1.1

| Font | Used for | Licence |
|---|---|---|
| Amiri Quran | the basmallah line | [SIL OFL 1.1](assets/fonts/amiri/OFL.txt) |
| Reem Kufi | headings and the surah title | [SIL OFL 1.1](assets/fonts/reemkufi/OFL.txt) |
| Cairo | the interface text | [SIL OFL 1.1](assets/fonts/cairo/OFL.txt) |

### Data sources

The full record, with each licence status as it was found and the conditions we use it under, is in [docs/research/licenses.md](docs/research/licenses.md). In short:

| Source | What we use from it | Licence status |
|---|---|---|
| [Tanzil](https://tanzil.net) | surah, juz and hizb-quarter data | free with attribution to Tanzil; the Quran text must not be modified |
| [QUL](https://qul.tarteel.ai) by Tarteel | the 15-line page layout and the glyph of each word | **no licence published** |
| King Fahd Glorious Quran Printing Complex (via QUL) | the per-page QCF V2 fonts (1421H edition) | **no licence published** |
| QUL, resource 312 | the Quran text word by word (KFGQPC Hafs) | **no copyright information published** |
| QUL, resource 24 | Tafsir al-Sa'di | **no copyright information published** |
| [Tanzil](https://tanzil.net/trans/en.sahih) | the Saheeh International translation | **non-commercial use only** |
| [Quranpedia](https://quranpedia.net) | word meanings from the books of Ibn al-Ha'im and Ibn al-Jawzi | free to use inside apps |
| The khatm dua | the text of the dua screen | the customary wording, with no named source. There is no fixed text from the Prophet ﷺ |

### Plainly

- Some of these sources **publish no licence**: the QUL layout, the Complex's fonts, the word text, and Tafsir al-Sa'di via QUL.
- The Saheeh International translation via Tanzil is **for non-commercial use only**, which is why the app stays free, with no donations and no payments.
- The app's owner decided to publish it free and non-commercially, and **accepts responsibility** for using these sources. The decision is recorded in the constitution (version 1.3.0) and in the licence record.
- The repository does not contain this data or these fonts. The released APK does.
- Every source is credited by name in the app's About screen.

**If you hold rights in any resource and object:** open an issue at [github.com/0omarahmed73/mushaf-al-hafiz/issues](https://github.com/0omarahmed73/mushaf-al-hafiz/issues), and the resource will be removed from the app or the app taken down.

<a id="faq"></a>

## ❓ FAQ

<details>
<summary>Does it work offline?</summary>

Yes, all of it: the Mushaf, the tafsir, the translation, the search and the reminders. The app does not even hold the Internet permission.

</details>

<details>
<summary>Why is it 180 MB?</summary>

Because each of the Mushaf's 604 pages has a font of its own, which is what makes the page match the printed one. The text, tafsir, translation and word meanings come with them. All of it is inside the app so that nothing has to be downloaded.

</details>

<details>
<summary>Why is there no iPhone version?</summary>

This release is for Android only. The app has not been tested on iPhone or on the web, and the repository holds an Android project only.

</details>

<details>
<summary>Are there ads or purchases?</summary>

No ads, no purchases, no donations, no accounts. The app is free and non-commercial and will stay that way.

</details>

<details>
<summary>Does it have recitation audio or memorisation tools?</summary>

Not in this version.

</details>

<details>
<summary>How do I back up my data?</summary>

Tap «القائمة» at the bottom, then under «النسخ الاحتياطي» tap «تصدير نسخة احتياطية». You get one file, named like `mushaf-backup-2026-11-21.json`, holding your wirds, bookmarks and settings. Keep it wherever you like.

</details>

<details>
<summary>How do I move to a new phone?</summary>

1. On the old phone: export a backup and send the file to the new phone any way you like.
2. On the new phone: install the app.
3. Tap «القائمة», then «استيراد نسخة احتياطية», and pick the file.

Importing replaces everything in the app with what is in the file, and asks you before it does.

</details>

<details>
<summary>A reminder came a few minutes late. Is that a bug?</summary>

No. The app does not request the exact-alarm permission, so it lets Android choose the moment within a few minutes.

</details>

<details>
<summary>Can the Mushaf text be trusted?</summary>

The text is taken as it is from the data of the Madinah Mushaf (QCF V2, 1421H edition) and is not modified. It is validated automatically when the data is generated, and compared against an independent text from Tanzil. Even so, if you ever see a mistake on a page, please report it at once at [github.com/0omarahmed73/mushaf-al-hafiz/issues](https://github.com/0omarahmed73/mushaf-al-hafiz/issues).

</details>

<a id="credits"></a>

## 🌿 Author and dedication

Written by **Omar A. Saeed** (عمر أ. سعيد) · [LinkedIn](https://linkedin.com/in/0omarahmed73) · [GitHub](https://github.com/0omarahmed73/)

With thanks to everyone who made these sources available: the King Fahd Glorious Quran Printing Complex, Tarteel (QUL), Tanzil, Quranpedia, and the designers of the Amiri Quran, Reem Kufi and Cairo fonts.

> **Dedication**
>
> This app is an ongoing charity (sadaqah jariyah) on behalf of my grandmother and my aunt.
>
> اللهم تقبّل منهما، واجعله في ميزان حسناتهما.
