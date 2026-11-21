# Licences of bundled and used resources

Required by Constitution Principle V before any feature depends on a resource. Distribution: on 2026-11-20
the app was a private, non-commercial APK; on 2026-11-21 the owner decided to release it publicly and
non-commercially (GitHub repository and release, itch.io, APKPure; not Google Play) and said «نشر عام وأنا مسؤول»
(public, and I take responsibility); Constitution 1.3.0 records that decision. The owner therefore accepts the
risk of every resource below whose licence is unpublished or restricted: this file records each status as found
and invents no licence text, and if a rights holder objects the owner takes that resource out of the app or the
app down. The conditions that do not change: non-commercial, no ads, no tracking, offline, the Quran text never
modified, and every resource credited in the About screen (spec FR-041). The repository holds none of the
git-ignored Quran fonts and data; the released APK does contain them.

| Resource | What we use it for | Source | Licence status | Our conditions |
|---|---|---|---|---|
| Tanzil metadata (`quran-data.js`: surah list, juz and hizb-quarter starts) | surah names, ayah counts, juz and hizb data in `assets/mushaf/meta.json` | tanzil.net | Tanzil's terms: free to use with attribution to Tanzil; the Quran text itself must not be modified | Credit Tanzil; we only read the metadata arrays and never alter Quran text |
| QUL (Quranic Universal Library, Tarteel): QCF V2 15-line layout (`qpc-v2-15-lines.db`) and word script (`qpc-v2.json`) | page/line layout and the glyph of each word | qul.tarteel.ai | **No licence published.** QUL shows "no copyright information" for these resources; they originate from the King Fahd Complex | Used in a free, non-commercial APK with visible attribution and no modification (owner decision, spec FR-042); public release on GitHub, itch.io and APKPure is the owner's decision of 2026-11-21, on the owner's responsibility. Generated assets are git-ignored (not in the public repository) and rebuilt by `tool/build_quran_assets.py`. Remaining risk: no licence is published, so the King Fahd Complex or Tarteel could object to the public APK; the owner then takes the resource out or the app down. Google Play is not planned |
| KFGQPC QCF V2 (1421H) per-page fonts (`p1.woff2`…`p604.woff2`, converted to TTF at build time) | rendering the Mushaf pages exactly as printed | King Fahd Glorious Quran Printing Complex, via QUL | **No licence published** (same status as above) | Same conditions as above. The fonts are git-ignored (not in the public repository) but are inside the released APK, which is the owner's decision of 2026-11-21. Remaining risk: redistributing the fonts has no published permission; the owner then takes them out or the app down if the Complex objects |
| Amiri Quran font | the basmallah line | github.com/aliftype/amiri | SIL Open Font License 1.1 | Committed with its `OFL.txt`; credit in About |
| Reem Kufi font (variable) | headings, the surah title in its banner | github.com/google/fonts `ofl/reemkufi` (The Reem Kufi Project Authors) | SIL Open Font License 1.1 | Downloaded 2026-11-20 with the owner's approval; committed with its `OFL.txt`; credit in About |
| Cairo (static 400/500/600/700) | the interface text, Arabic and Latin | github.com/google/fonts `ofl/cairo` (The Cairo Project Authors) | SIL Open Font License 1.1 | Downloaded 2026-11-20 at the owner's request (chosen over Almarai and IBM Plex Sans Arabic for its Arabic and Latin digits); the four weights are cut from the variable file by `tool/make_cairo_instances.py` (weight axis pinned, no glyph changed); committed with its `OFL.txt`; credit in About |

## Feature 002 (ayah actions and sharing): four sources, downloaded 2026-11-20 and bundled

Read on 2026-11-20 from each site's own pages while planning (specs/002-ayah-actions-sharing/research.md).
The owner approved the four downloads and the choice of sources («Yes, approve all», 2026-11-20): Quran words
(QUL 312), Tafsir al-Sa'di (QUL 24), Saheeh International (Tanzil) and the two classical word-meaning books
(Quranpedia 327 and 208). They were downloaded the same day into the git-ignored `data-raw/ayah/` and are turned
into `assets/ayah/` by `tool/build_ayah_assets.py`, which records each file's name, version and sha256 in
`assets/ayah/sources.json` (the values below were checked against it). Each is credited in About (Constitution V,
spec FR-020); the credits are in `lib/settings/about_screen.dart` and a test compares them with `sources.json`.

| File as downloaded | Version (file's own date) | Size in bytes | sha256 (first 12) |
|---|---|---|---|
| `qul-312-hafs-words.json.zip` (QUL 312) | 2025-05-28 | 1,467,797 | `ef5d389e8e1f` |
| `qul-24-tafsir-saadi-ar.json.zip` (QUL 24) | 2025-05-26 | 1,741,654 | `b1f7be503e33` |
| `tanzil-en.sahih.txt` (Tanzil) | 2011-04-24 | 898,049 | `a1778a1a5669` |
| `quranpedia-meanings.json.gz` (Quranpedia) | 2026-11-14 | 748,521 | `b46ca5ae7baa` |

The bundled assets are 9,382,857 bytes (8.95 MiB) raw and 2.64 MB gzipped (research.md D5), far below the 40 MB limit (SC-009).

| Resource | What it is used for | Source | Licence status (quoted briefly) | Our conditions |
|---|---|---|---|---|
| QUL resource 312, «KFGQPC Hafs script – Word by word» | the ayah's exact Unicode words, aligned to the Mushaf word keys | qul.tarteel.ai/resources/translation/312 | «We don't have copyright information for this resource.» Origin: King Fahd Glorious Quran Printing Complex | Same status and conditions as the QCF resources above (free, non-commercial APK, public release by the owner's decision of 2026-11-21, visible attribution, no modification), with the same remaining risk: no licence is published. Stored words are unchanged. Downloaded 2026-11-20 by the owner's login: `qpc-hafs-word-by-word.json.zip` (1,467,797 bytes, sha256 `ef5d389e…8af2`; file dated 2025-05-28) |
| QUL tafsir 24, «Tafseer Al Saadi – Arabic» (تيسير الكريم الرحمن, السعدي d. 1376H) | Tafsir al-Sa'di, grouped by ayah ranges | qul.tarteel.ai/resources/tafsir/24 | «We don't have copyright information for this resource.» No author or edition on the page. QUL FAQ: resources vary in copyright status, some need attribution | Same conditions; shown unchanged as a human work, labelled «تفسير السعدي», set apart from the Quran text. The missing licence was the owner's call (R1/R2) and is now accepted for the public release (2026-11-21). Remaining risk: QUL gives no licence information, author or edition for this text, so whoever holds its rights could object; the owner then takes it out. Downloaded 2026-11-20 by the owner's login: `ar-tafseer-al-saddi.json.zip` (1,741,654 bytes, sha256 `b1f7be50…e9e33b`; file dated 2025-05-26) |
| Tanzil `en.sahih`, «Saheeh International» | English translation of each ayah | tanzil.net/trans/en.sahih | Tanzil's terms: «for non-commercial purposes only»; otherwise permission from the translator or publisher; link back to tanzil.net/trans/ required only for more than three translations; no named licence; «We cannot guarantee their authenticity and/or accuracy.» | Free, non-commercial APK (the one Tanzil term that is clear: non-commercial use only); text unchanged; credit Saheeh International and Tanzil with the link back to tanzil.net (kept in About even though it is only required for more than three translations). Downloaded 2026-11-20: `en.sahih` (898,049 bytes, sha256 `a1778a1a…0883`; file footer: Saheeh International, last update 2011-04-24, source Tanzil.net, no licence text). The translator's own rights were the owner's call (R3), now accepted for the public release (2026-11-21). Remaining risk: Tanzil sends anyone who needs more than non-commercial use to the translator or publisher, whose permission we do not hold, so the publisher could object to the public APK; the app stays free and the owner then takes the translation out |
| Quranpedia `meanings.json.gz` (file's own `license.version` 2026-11-14; manifest 2026-11-16; LICENSE.md dated 2026-11-20; downloaded 2026-11-20, sha256 `b46ca5ae…d0699`, 748,521 bytes), only books 327 (ابن الهائم, d. 815H) and 208 (ابن الجوزي, d. 597H) | difficult-word meanings per ayah | quranpedia.net/dumps | LICENSE: «Free to use inside apps, websites, bots, and research tools — no attribution required (a visible link to https://quranpedia.net is appreciated).» Republishing as a dataset needs a credit and the dump version. Classical works are «shared heritage»; translations and contemporary works stay with their owners; as-is, no warranty | We use only the two classical books (the contemporary books 491 and 1424 are left out on purpose), credit Quranpedia with the link and the dump version and keep the file's sha256 in `sources.json`. Word/phrase + meaning per ayah, no word position. Public release needs nothing more than that credit (its LICENSE allows use inside apps); remaining risk: none recorded beyond the dump's «as-is, no warranty» terms and the owners of translations and contemporary works, which we do not use |
| Tanzil Uthmani text (`quran-uthmani.txt`, already in `data-raw/`) | only as an independent per-ayah cross-check of the text in the build tool; never bundled | tanzil.net | CC BY 3.0 per tanzil.net/docs/Text_License: verbatim copies only, source and link required | Not shipped, so no credit is needed for it beyond the metadata credit already given |

Not used: Quranpedia's morphology (GPL) and syntax (MIT) files, and its other 13 services.


## Feature 005 (khatm dua): one supplication, customary wording with no fixed source

Constitution 1.2.0 (2026-11-20) allows exactly one dua, «دعاء ختم القرآن», shown after the last page of the Mushaf.
The wording is bundled in `assets/khatm/dua.txt` (about 4 KB) and shown on the screen of
`lib/khatm/khatm_dua_screen.dart`; the credit is in `lib/settings/about_screen.dart` (`kDuaCredit*` in
`lib/khatm/dua_strings.dart`).

| Resource | What it is used for | Source | Licence status | Our conditions |
|---|---|---|---|---|
| The supplication said at the completion of the Quran, in the wording the owner confirmed on 2026-11-21 (eleven short paragraphs, from «اللهم ارحمني بالقرآن» to «وسلم تسليماً كثيراً»), kept exactly as the owner wrote it, with its diacritics and the sign ۞ at the end of each paragraph but the last | the text of the dua screen (`assets/khatm/dua.txt`) | Supplied by the owner of the app on 2026-11-21 without a named book or site. Its first two paragraphs are the customary opening found, unattributed, on mawdoo3.com «دعاء ختم القرآن» (page updated 2024-08-06) and albayan.ae (page dated 2024-04-08), both read on 2026-11-20; the other paragraphs were not traced to a source by the developer | Short traditional supplications, no known author or edition, so no copyright of a text is claimed or known. **No book, narrator or grading is given for this wording; the developer did not verify any grading, and neither page ties it to the Madinah Mushaf of the King Fahd Complex.** The pages say there is no fixed text from the Prophet ﷺ for the dua at the end of the Quran. The last paragraph begins with the verse 2:201, and the second paragraph uses words that also occur in 20:130; they are shown inside the dua in the interface font, never in the Quran font and never in the page. | Only the supplication itself is used; none of those sites' own explanations. About says that the wording is the customary one and that there is no fixed text from the Prophet ﷺ (the sentence the owner chose, without the names of the sites). **Status: confirmed by the owner word by word on 2026-11-21 (tasks T011). Open: the owner has not named where the added paragraphs were taken from; when they do, the source is added here (Constitution III asks for a named source).** |

Not used: the explanations and the other du'as on those pages. The owner chose the longer composition as the one khatm dua (2026-11-21); the app still holds exactly one dua, with no list, section or other supplication (Constitution III).
