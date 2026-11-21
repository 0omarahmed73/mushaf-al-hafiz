# Store listings (GitHub release, itch.io and APKPure)

Ready-to-paste texts. Replace the three `<...>` placeholders first: `https://github.com/0omarahmed73/mushaf-al-hafiz` (the public GitHub repository),
`https://github.com/0omarahmed73/mushaf-al-hafiz/issues` (its Issues page) and `<VERSION>` (1.0.0). The numbers and claims below were checked against the
repository on 2026-11-21 (see "Facts to keep true" at the end). Form labels on the sites change from time to time; the
field names here are the ones to look for, not a promise.

## Shared facts

| Field | Value |
|---|---|
| Name | مصحف الحافظ (Mushaf al-Hafiz) |
| Package name | `app.hafiz.mushaf` |
| Version | 1.0.0 (build 1) |
| Platform | Android 7.0 or newer (minSdk 24) |
| Size | about 180 MB (the real size and sha256 come from `tool/release.sh`) |
| Language | Arabic (the interface is Arabic only; the English translation of the Quran is Saheeh International) |
| Price | Free. No payments, no donations, no in-app purchases |
| Ads / tracking | None. No analytics, no accounts, no server |
| Internet permission | None (verified in the packaged release manifest; see "Content notes") |
| Source code | `https://github.com/0omarahmed73/mushaf-al-hafiz` |
| Support | `https://github.com/0omarahmed73/mushaf-al-hafiz/issues` |

## GitHub release

| Field | What to enter |
|---|---|
| Tag | `v1.0.0` |
| Release title | مصحف الحافظ 1.0.0 |
| Release notes | The whole of `docs/release/RELEASE_NOTES_v1.0.0.md` (Arabic first, then English), with its `<SIZE>`, `<SHA256>` and `<CERT_SHA256>` placeholders filled after the build |
| Files | `mushaf-hafiz-v1.0.0.apk` and `mushaf-hafiz-v1.0.0.apk.sha256` |
| Repository description ("About") | The English short description from the APKPure section below, or the Arabic one |
| Repository topics | Pick from the English tags of the itch.io section |

## itch.io

Dashboard, "Create new project".

| Field | What to enter |
|---|---|
| Title | مصحف الحافظ — Mushaf al-Hafiz |
| Project URL | `mushaf-al-hafiz` (the owner's pick; it cannot be changed lightly later) |
| Short description or tagline | Offline Madinah Mushaf with daily wirds and reminders. No ads, no tracking. |
| Classification | Tool (or Other if Tool is not offered). itch.io is mostly for games; this is an app |
| Kind of project | Downloadable |
| Release status | Released |
| Pricing | No payments. Do not turn on "donations" or "pay what you want": the app is non-commercial, and Tanzil's Saheeh International text is for non-commercial use only |
| Uploads | `mushaf-hafiz-v1.0.0.apk`, ticked as **Android**. Add `mushaf-hafiz-v1.0.0.apk.sha256` as an extra file if you want |
| Genre / tags | Pick from the tags below; the form takes a limited number |
| Community | Comments on, or link to the issues page; your choice |
| Visibility | Draft first, check the page as a visitor, then Public |

Tags (English): quran, mushaf, islam, arabic, offline, no-ads, tafsir, reading, android, free.

Tags (Arabic, if the form allows non-Latin tags): قرآن، مصحف، ورد، تفسير، بلا إنترنت.

If the form asks whether generative AI was used: the app's code was written with AI assistance (the commit messages say so
with a `Co-Authored-By: Claude` line); the Quran text and the sources are not AI-generated. Answer truthfully.

### Description (paste as the project's main text; itch.io takes Markdown-like formatting)

```
## مصحف الحافظ

تطبيق أندرويد مجاني وغير تجاري لقراءة مصحف المدينة النبوية (طبعة 1421هـ، برواية حفص عن عاصم) بنفس توزيع الكلمات على الأسطر كما في المصحف المطبوع.
يفتح مباشرة على الصفحة التي توقفت عندها، ويعمل بلا إنترنت، وبلا إعلانات، وبلا تتبّع.

- 604 صفحات، تقليب كالمصحف الورقي، تكبير بالقرص، فهرس للسور والأجزاء والصفحات
- بحث في أسماء السور وفي نص القرآن، يجد الكلمات ولو كتبتها بلا همزات ولا تشكيل
- أوراد متعددة (قراءة وقيام الليل) بمقدار يومي وملخص لليوم وعدّاد للختمات
- تذكيرات محلية لكل ورد ولسورة الكهف ليلة الجمعة أو يوم الجمعة كما تختار، يجدولها الهاتف نفسه
- علامات على الصفحات مع ملاحظة، وزر في صفحة القراءة يضع العلامة بلمسة واحدة
- قائمة الآية بالضغط المطوّل: مشاركة الآية، تفسير السعدي، ترجمة Saheeh International، معاني الكلمات، مشاركة الصفحة صورةً وسورة كاملة PDF
- حجم الخط للتفسير والترجمة وللصفحة نفسها دون تغيير توزيعها
- مظهران: «زمردي وذهبي» و«القارئ الليلي»
- حركة سلسة عند تقليب الصفحات، وإرشادات قصيرة تظهر مرة واحدة عند أول تشغيل
- دعاء ختم القرآن بعد الصفحة الأخيرة
- نسخة احتياطية بتصدير ملف واستيراده، بلا حسابات ولا خادم

النص القرآني لا يُعدَّل أبدًا ويُتحقَّق منه آليًا. الواجهة عربية بالكامل. يتطلب أندرويد 7.0 فأعلى، والحجم نحو 180 ميغابايت.
لا صلاحية إنترنت. لا يوجد صوت (تلاوة) ولا أدوات حفظ في هذا الإصدار.

الشيفرة المصدرية وسجل الرخص: https://github.com/0omarahmed73/mushaf-al-hafiz
للإبلاغ عن مشكلة أو اعتراض صاحب حق: https://github.com/0omarahmed73/mushaf-al-hafiz/issues

---

## Mushaf al-Hafiz

A free, non-commercial Android app for reading the Madinah Mushaf (1421H edition, riwayat Hafs 'an 'Asim) with the same
word-to-line layout as the printed Mushaf. It opens straight on the page where you stopped and works offline, with no ads and no tracking.

- 604 pages, paper-like page turning, pinch to zoom, an index by surah, juz and page
- Search in the surah names and in the Quran text; it finds the words even when typed without hamzas or tashkeel
- Several wirds (reading and night prayer) with a daily portion, a daily summary and a khatma counter
- Local reminders for each wird and for Surat al-Kahf on Thursday evening or on Friday, as you choose, scheduled by the phone itself
- Bookmarks with notes, and a button on the reading page that bookmarks it with one tap
- Ayah menu on long press: share the ayah, tafsir al-Sa'di, the Saheeh International translation, word meanings, share the page as a picture or a whole surah as a PDF
- Text size for the tafsir and translation and for the page itself, without changing its layout
- Two looks: "Emerald and Gold" and "Night Reader"
- Smooth page turning, and short tips shown once on the first launch
- The khatm dua after the last page
- Backup by exporting and importing a file; no accounts and no server

The Quran text is never modified and is validated automatically. The interface is Arabic only. Needs Android 7.0 or newer;
about 180 MB. No Internet permission. No recitation audio and no memorisation tools in this version.

Source code and licence record: https://github.com/0omarahmed73/mushaf-al-hafiz
To report a problem or a rights objection: https://github.com/0omarahmed73/mushaf-al-hafiz/issues
```

## APKPure

Developer portal, "Upload app".

| Field | What to enter |
|---|---|
| App name | مصحف الحافظ |
| Package | `app.hafiz.mushaf` (read from the APK) |
| Category | Books & Reference (or the nearest "Books" category offered) |
| Content rating / audience | Everyone. No violence, no gambling, no user-generated content |
| Contains ads | No |
| In-app purchases | No |
| Website / support | `https://github.com/0omarahmed73/mushaf-al-hafiz/issues` |
| Contact email | an address the owner is happy to make public (decide in PUBLISH_CHECKLIST) |
| Privacy policy | If a URL is required: a short page or a file in the repository saying "the app collects no data and has no Internet permission" (the sentence in "Content notes" below) |

Short description, Arabic (80 characters or fewer):

```
مصحف المدينة النبوية بلا إنترنت، مع أوراد وتذكيرات. بلا إعلانات ولا تتبّع.
```

Short description, English (80 characters or fewer):

```
Offline Madinah Mushaf with wirds and reminders. No ads, no tracking.
```

Full description, Arabic:

```
مصحف الحافظ تطبيق أندرويد مجاني وغير تجاري لقراءة مصحف المدينة النبوية (طبعة 1421هـ، برواية حفص عن عاصم)، بنفس توزيع الكلمات على الأسطر كما في المصحف المطبوع. يفتح مباشرة على الصفحة التي توقفت عندها، ويعمل بلا إنترنت، وبلا إعلانات، وبلا تتبّع.

المصحف
• 604 صفحات، وتقليب بالسحب كالمصحف الورقي، وتكبير بالقرص
• فهرس للسور والأجزاء والصفحات، وشريط يبيّن الجزء والحزب والربع والسورة
• حركة سلسة عند تقليب الصفحات
• النص القرآني لا يُعدَّل أبدًا، ويُتحقَّق منه آليًا

البحث
• بحث في أسماء السور وفي نص القرآن
• يجد الكلمات ولو كتبتها بلا همزات ولا تشكيل وبالإملاء المعتاد، أو برسم المصحف
• اختيار نتيجة يفتح صفحتها دون أن يغيّر موضع وردك

الورد
• أوراد متعددة: قراءة وقيام الليل، لكل ورد موضعه ومقداره اليومي
• «ملخص اليوم» وعدّاد للختمات
• تذكيرات محلية يجدولها الهاتف نفسه: لكل ورد، ولسورة الكهف ليلة الجمعة أو يوم الجمعة كما تختار
• علامات على الصفحات مع ملاحظة، وزر في صفحة القراءة يضع العلامة بلمسة واحدة

الآية
• بالضغط المطوّل على الآية: مشاركتها، وتفسير السعدي، والترجمة الإنجليزية (Saheeh International)، ومعاني الكلمات
• مشاركة الصفحة صورةً، ومشاركة سورة كاملة بصيغة PDF

وأيضًا
• حجم الخط للتفسير والترجمة وللصفحة نفسها دون تغيير توزيعها
• مظهران: «زمردي وذهبي» و«القارئ الليلي»
• إرشادات قصيرة تظهر مرة واحدة عند أول تشغيل
• دعاء ختم القرآن بعد الصفحة الأخيرة
• نسخة احتياطية بتصدير ملف واستيراده، بلا حسابات ولا خادم

الخصوصية: التطبيق لا يجمع أي بيانات ولا يطلب صلاحية الإنترنت. يتطلب أندرويد 7.0 فأعلى، والحجم نحو 180 ميغابايت. لا يوجد في هذا الإصدار تلاوة صوتية ولا أدوات حفظ.

المصادر والرخص مذكورة في شاشة «عن التطبيق» وفي المستودع: https://github.com/0omarahmed73/mushaf-al-hafiz
```

Full description, English:

```
Mushaf al-Hafiz is a free, non-commercial Android app for reading the Madinah Mushaf (1421H edition, riwayat Hafs 'an 'Asim) with the same word-to-line layout as the printed Mushaf. It opens straight on the page where you stopped and works offline, with no ads and no tracking. The interface is Arabic only.

The Mushaf
• 604 pages, swipe to turn pages like the paper Mushaf, pinch to zoom
• An index by surah, juz and page, and a bar showing the juz, hizb, quarter and surah
• Smooth page turning
• The Quran text is never modified and is validated automatically

Search
• Search in the surah names and in the Quran text
• It finds the words even when typed without hamzas or tashkeel and in everyday spelling, or in the Mushaf's own spelling
• Choosing a result opens its page without moving your wird's position

Your wird
• Several wirds: reading and night prayer, each with its own position and daily portion
• A daily summary and a khatma counter
• Local reminders scheduled by the phone itself: one per wird, and one for Surat al-Kahf on Thursday evening or on Friday, as you choose
• Bookmarks with notes, and a button on the reading page that bookmarks it with one tap

The ayah
• Long press an ayah to share it, read tafsir al-Sa'di, the English translation (Saheeh International) and word meanings
• Share the page as a picture, or a whole surah as a PDF

Also
• Text size for the tafsir and translation and for the page itself, without changing its layout
• Two looks: "Emerald and Gold" and "Night Reader"
• Short tips shown once on the first launch
• The khatm dua after the last page
• Backup by exporting and importing a file; no accounts and no server

Privacy: the app collects no data and does not request the Internet permission. Needs Android 7.0 or newer; about 180 MB. This version has no recitation audio and no memorisation tools.

Sources and licences are credited in the About screen and in the repository: https://github.com/0omarahmed73/mushaf-al-hafiz
```

What's new (version 1.0.0), Arabic:

```
أول إصدار عام.
```

What's new, English:

```
First public release.
```

Tags / keywords: quran, mushaf, madinah mushaf, hafs, wird, tafsir, offline quran, no ads, arabic, islam.

## Content notes (for the rating and privacy forms)

- **Ads:** none. **Analytics, crash reporting, tracking SDKs:** none. **Accounts, server, sync:** none.
- **Internet permission: not requested.** Checked on 2026-11-21 in the release APK `app-release.apk` built that day with
  `aapt2 dump permissions`; the permissions it lists are `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED` (reminders),
  `VIBRATE`, `WAKE_LOCK`, `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_SHORT_SERVICE` (added by the notification and background
  task libraries), `ACCESS_NETWORK_STATE` (added by a library, most likely the background task one; it can only read whether a network
  exists and cannot send anything), and the app's own `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. The only `INTERNET` permission in the project is
  in the debug and profile manifests (`android/app/src/debug/` and `profile/`), which are not part of a release build.
  Re-run `aapt2 dump permissions build/release/mushaf-hafiz-v1.0.0.apk` on the final APK and keep this paragraph true.
- **Data the app stores:** the wirds, positions, bookmarks and settings, on the phone only. Sharing goes through the system
  share sheet, started by the user.
- **User-generated content:** none visible to others. **Violence, sexual content, gambling:** none.
- **Religious content:** the Quran, its tafsir and a supplication.

## Screenshots to take (the owner or the coordinator takes them on the phone)

Portrait, phone resolution, no status-bar clutter (full battery, no personal notifications). Each store takes a limited number;
the first two or three matter most. Do not edit the Quran pages: crops and device frames are fine.

1. A Mushaf page with the bars hidden, a full 15-line page (for example page 50), in the default look.
2. The same page with the bars shown (juz, hizb, surah on top; the bottom bar).
3. Page 1 or 2 (the 8 centred lines) or page 293 (al-Kahf banner).
4. The wirds list with «ملخص اليوم» open (at least two wirds, one reading and one «قيام الليل»).
5. The ayah menu opened by a long press, showing the tafsir of al-Sa'di.
6. The English translation, or the word-meanings view.
7. The same page in the «القارئ الليلي» look.
8. Settings (reminders, text size, look, backup).
9. About, showing the credits.
10. The khatm dua screen.
11. The search screen with results for a few words of an ayah typed without hamzas (the «السور» and «الآيات» groups).

Other images: a square app icon (the launcher icon of feature 009) and, for itch.io, a cover image
(630 x 500 px is the size it asks for) built from screenshot 1 or 7.

## Licensing statement (short, for the bottom of both pages)

English:

```
Free and non-commercial: no ads, no tracking, offline. The Quran text is the Madinah Mushaf of the King Fahd Glorious Quran Printing Complex (QCF V2, 1421H) via QUL by Tarteel, unmodified. Surah data and the English translation (Saheeh International, non-commercial use) come from Tanzil (https://tanzil.net/trans/en.sahih). Tafsir al-Sa'di is via QUL. Word meanings are from Quranpedia (https://quranpedia.net). Fonts: Amiri Quran, Reem Kufi and Cairo under the SIL Open Font License 1.1. Some of these sources publish no licence; the publisher takes responsibility for using them here. If you hold rights in any resource and object, please tell us at https://github.com/0omarahmed73/mushaf-al-hafiz/issues and it will be removed.
```

Arabic:

```
مجاني وغير تجاري: بلا إعلانات وبلا تتبّع ويعمل بلا إنترنت. النص القرآني هو مصحف المدينة النبوية لمجمع الملك فهد لطباعة المصحف الشريف (QCF V2، 1421هـ) عبر QUL من Tarteel دون تعديل. بيانات السور والترجمة الإنجليزية (Saheeh International، للاستعمال غير التجاري) من Tanzil (https://tanzil.net/trans/en.sahih)، وتفسير السعدي عبر QUL، ومعاني الكلمات من Quranpedia (https://quranpedia.net)، والخطوط Amiri Quran وReem Kufi وCairo برخصة SIL OFL 1.1. بعض هذه المصادر لا ينشر رخصة، وناشر التطبيق يتحمّل مسؤولية استعمالها. إن كنت صاحب حق في أي مورد واعترضت فأخبرنا في https://github.com/0omarahmed73/mushaf-al-hafiz/issues وسيُزال.
```

## Facts to keep true

Checked against the repository on 2026-11-21; change the texts above if any of these changes before publishing.

- Features listed exist in specs 001 to 005 (reader and wirds, ayah actions and sharing, text size, Night look, khatm dua)
  and, since the update of 2026-11-21, in specs 006 to 011: the one-tap bookmark button in the reader (006), the choice of
  the al-Kahf reminder day, Thursday or Friday (007), the six first-run tips shown once (008), the app icon and the splash
  (009), smooth motion and the page-turn fix (010), and the search of surah names and of the Quran text (011). Landscape
  shows the top and bottom bars by default. Each line was written from the user stories of that feature's `spec.md`.
- No audio and no memorisation or review tools exist in the app.
- Every public text says "free and non-commercial" («مجاني وغير تجاري»), never "personal". The owner chose «تطبيق مجاني
  غير تجاري» for the About screen. When this file was updated on 2026-11-21, `lib/settings/about_screen.dart` still said
  «تطبيق شخصي غير تجاري» and its KFGQPC credit «تُستعمل في تطبيق شخصي غير تجاري»; that edit belongs to the coordinator.
  Check that no "شخصي" is left there before building the APK that goes public (PUBLISH_CHECKLIST, Step 1.1).
- The licence statements here are unchanged in substance: `docs/research/licenses.md` is the record, some sources publish no
  licence and the owner takes responsibility for using them, and Saheeh International via Tanzil is for non-commercial use only.
