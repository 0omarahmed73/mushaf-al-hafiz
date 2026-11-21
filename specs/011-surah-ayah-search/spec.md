# Feature Specification: Surah and Ayah Search

**Feature Branch**: `011-surah-ayah-search` (work stays on `main`, as for features 001 to 010)

**Created**: 2026-11-21

**Status**: Draft

**Input**: User description (owner, Egyptian Arabic, translated into English here): "(1) search the names of the
surahs; (2) search for a specific ayah, or a phrase, inside the Quran text; and the search must be tolerant of hamza
spelling, because the user may not type the hamzas correctly: أ إ آ ٱ typed as ا, ة typed as ه, ى typed as ي, with or
without tashkeel or tatweel, and the match must still be found." It stays offline, with no new package, no permission
and no network.

## Clarifications (proposed, owner confirms)

The owner could not be asked while this was written. These are the decisions the author took from the request, from
reading the code and from running the matching rules over the real bundled text on 2026-11-21. Each is recorded so the
owner can overrule it. The three open questions were answered by the owner on 2026-11-21 (FR-001: from the index screen; FR-013: highlighted
until the next touch; FR-014: the first 100 ayat); the others have a recorded default.

- Q: One search or two? → A: One screen with one field and two labelled groups of results, «السور» first and «الآيات»
  below. A surah name typed there finds the surah and, below it, the ayat that contain the word (for example «الرحمن» is
  the surah and also 48 ayat).
- Q: What is searched? → A: The names of the 114 surahs and the Quran text of the 6,236 ayat, one ayah at a time (a
  phrase that ends one ayah and begins the next is not found). Not the tafsir, the English translation, the word meanings,
  the page numbers, the juz or the notes of a bookmark. The translation is shown only from an ayah's menu (Constitution,
  Scope and Distribution, 1.1.0), so it is never searched or shown in a result.
- Q: Which spellings must be found? → A: The owner's list (the four alef forms أ إ آ ٱ, ة and ه, ى and ي, tashkeel, tatweel)
  and one more that the data forces: the Mushaf spells many words in its own way (a small alef instead of a long one, a
  waw in «الصلوة», a small yeh in «إبراهيم»), and people type them the school way. «الصلاة», «الكتاب», «ابراهيم» must be
  found too, otherwise the search would miss the most common words (User Story 3 and its table).
- Q: When does it search, and from how many letters? → A: Result by result while typing. Surah names from 1 letter (there
  are surahs called «ق» and «ص»); ayat from 2 letters (one letter matches almost everything).
- Q: In what order are results listed? → A: Mushaf order (surah 1 to 114, ayah ascending) for ayat; for surahs the name that
  equals what was typed first, then names that start with it, then names that contain it. No relevance ranking for ayat.
- Q: What does tapping an ayah result do? → A: It shows the page where the ayah begins, in browse mode, exactly as the
  index, the bookmarks and the notification «page:N» do; the wird does not move. If the page is already the one shown, nothing but
  the highlight (if kept, FR-013) appears (the same as the go-to-page dialog, which does nothing when the page typed is the page shown).
- Q: Is the last search remembered? → A: No. Nothing typed is stored, logged or written to the backup; opening search
  again starts empty (Constitution IV: no user data leaves the phone, and none is kept that nobody asked for).
- Q: Are digits, Latin letters, alternative surah names («براءة» for «التوبة») and named ayat («آية الكرسي») understood?
  → A: No (out of scope, listed in Assumptions). The page-number tab of the index already takes digits.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Find a surah by its name, however I spell it (Priority: P1)

The reader opens the index from the reader, taps the search icon, and types part of a surah's name: «كهف», «الكهف»,
«سورة الكهف», «ابراهيم» or «سبا». Under the heading «السور» the matching surahs appear at once, each as in the index (its
number, its name and its page). Tapping one shows that surah's first page, in browse mode.

**Why this priority**: It is the first half of the request, it needs only the 114 names (no Quran text), and it is
useful on its own: today the index is a list of 114 rows to scroll.

**Independent Test**: With only the surah names loaded, type each of the 114 names in five careless ways (as shown, with
every hamza bare, with ة as ه and ى as ي, with «سورة» in front, without the leading «ال»): the right surah is among the
results every time, and the name that equals what was typed is the first row.

**Acceptance Scenarios**:

1. **Given** search is open and empty, **When** the reader types «كهف», **Then** «السور · 1» lists «18 الكهف ص 293».
2. **Given** the index writes surah 34 as «سبإ», **When** the reader types «سبأ» or «سبا» or «سبإ», **Then** surah 34 is
   listed, and its row shows the name the way the index shows it.
3. **Given** the same for «الإسراء» (17), «الإنفطار» (82), «الانسان» (76) and «ابراهيم» (14), **When** any hamza spelling
   of them is typed, **Then** the right surah is listed.
4. **Given** «سورة الكهف» is typed, **When** the results appear, **Then** the leading word «سورة» was ignored for the
   surah names and surah 18 is listed.
5. **Given** «الحج» is typed, **When** the surah group appears, **Then** «الحج» (22) is its first row, followed by
   «الحجر» (15) and «الحجرات» (49).
6. **Given** a surah row is listed, **When** the reader taps it, **Then** search closes and the reader shows the surah's
   first page (the same page the index opens) in browse mode.
7. **Given** «ق» is typed (one letter), **When** the results appear, **Then** surah 50 «ق» is the first row of the surah
   group and the ayah group asks for at least two letters.

---

### User Story 2 - Find an ayah from a few of its words and open it on its page (Priority: P1)

The reader types a few words of an ayah, for example «قل هو الله احد». Under «الآيات» each ayah that contains the words
is one row: the surah's name, the ayah's number, its page, and a snippet of the ayah's own words with the matched words
emphasised. Tapping a row shows the page where that ayah begins, in browse mode.

**Why this priority**: It is the second half of the request and the reason a reader who half remembers an ayah has no way
today to find it.

**Independent Test**: Type «قل هو الله احد»: one row, «الإخلاص · آية 1 · ص 604». Type «بسم الله الرحمن الرحيم»: two
rows, «الفاتحة · آية 1 · ص 1» and «النمل · آية 30 · ص 379». Tap one: the page opens.

**Acceptance Scenarios**:

1. **Given** search is open, **When** the reader types «قل هو الله احد», **Then** the «الآيات» group holds exactly one row
   (112:1, page 604) and the words «قُلۡ هُوَ ٱللَّهُ أَحَدٌ» in the snippet are emphasised.
2. **Given** a phrase that occurs in several ayat, **When** it is typed («بسم الله الرحمن الرحيم»), **Then** every ayah
   that contains it is listed once, in Mushaf order, each with its own surah, number and page.
3. **Given** a word occurs three times in one ayah, **When** it is searched, **Then** that ayah is one row, not three.
4. **Given** an ayah row is shown, **When** its snippet is read, **Then** the words are the ayah's stored words
   character for character (tashkeel and Quranic marks included), never the spelling the reader typed and never a
   simplified form (Constitution I).
5. **Given** an ayah longer than the room for its snippet, **When** it is a result, **Then** the snippet is a run of
   whole, consecutive words of the ayah around the first match, with «…» where words were left out.
6. **Given** an ayah row, **When** the reader taps it, **Then** search closes and the reader shows the page where the
   ayah begins (for 2:282 that is page 48, although the ayah continues on page 49), in browse mode.
7. **Given** a part of a word is typed («رحم»), **When** the results appear, **Then** ayat with «الرحمن», «رحمة» and
   «يرحم» are included (a word is found by any part of it, because Arabic words carry prefixes and suffixes).
8. **Given** a phrase that matches nothing («ذو القرنين» does not occur; the Quran says «ذي القرنين»), **When** it is typed,
   **Then** the «لا توجد نتائج» state appears (User Story 5), not an empty screen.

---

### User Story 3 - Careless spelling still finds it (Priority: P1)

The reader does not type hamzas, shaddas or tashkeel, writes «ة» as «ه» and «ى» as «ي», and writes the words the way
they are written in everyday Arabic. The words are still found in the Mushaf's own spelling, and typing them exactly as
the Mushaf prints them (pasted, with every mark) is found too.

**Why this priority**: It is the condition the owner put on both searches: a search that only works when every hamza is
right is not usable from a phone keyboard.

**Independent Test**: Run every row of the table below (and its variants) through the search: each typed form must find
at least the ayat named, and the four phrases marked «exactly» must find exactly those ayat.

| Typed (any of the forms) | The Mushaf's text writes | Must be found |
|---|---|---|
| احمد · أحمد | أَحۡمَدُ | 61:6; and not the ayat of «ٱلۡحَمۡدُ» (1:2 is not a result) |
| ابراهيم · إبراهيم · ابراهيـم | إِبۡرَٰهِيمَ and إِبۡرَٰهِـۧمَ (two spellings of the name) | 14:35 and 2:124 |
| الرحمن · الرحمٰن | ٱلرَّحۡمَٰنِ | 1:1 and 55:1 |
| مؤمن · مومن | مُؤۡمِنٖ | 4:92 |
| رحمة · رحمه | رَحۡمَةٞ | 2:157 |
| موسى · موسي | مُوسَىٰ | 2:51 |
| الكتاب | ٱلۡكِتَٰبُ | 2:2 |
| الصلاة · الصلاه | ٱلصَّلَوٰةَ | 2:3 |
| الزكاة | ٱلزَّكَوٰةَ | 2:43 |
| السماوات · السموات | ٱلسَّمَٰوَٰتِ | 2:33 |
| شيئا · شيأ | شَيۡـٔٗا | 2:48 |
| يستهزئون · يستهزؤون · يستهزءون | يَسۡتَهۡزِءُونَ | 6:5 |
| النبيين | ٱلنَّبِيِّـۧنَ | 2:61 |
| اسماعيل · إسماعيل | إِسۡمَٰعِيلَ | 2:125 |
| يا ايها الذين امنوا · يأيها الذين آمنوا · ياأيها الذين امنوا | يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ | 2:104 and 2:153 (one word in the Mushaf, three in what was typed) |
| بسم الله الرحمن الرحيم | بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ | exactly 1:1 and 27:30 |
| ذلك الكتاب لا ريب فيه | ذَٰلِكَ ٱلۡكِتَٰبُ لَا رَيۡبَۛ فِيهِۛ | exactly 2:2 |
| قل هو الله احد | قُلۡ هُوَ ٱللَّهُ أَحَدٌ | exactly 112:1 |
| الله لا اله الا هو الحي القيوم | ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلۡحَيُّ ٱلۡقَيُّومُ | exactly 2:255 and 3:2 |

(Every row was checked on 2026-11-21 against the bundled text with a prototype of the rules; the counts of results for
the single words are not part of the requirement, only the ayat named and the four «exactly» rows.)

**Acceptance Scenarios**:

1. **Given** any row of the table, **When** any of its typed forms is searched, **Then** every ayah named is in the
   results.
2. **Given** the four rows marked «exactly», **When** they are searched, **Then** the results are those ayat and no
   others.
3. **Given** the text of an ayah copied exactly as the Mushaf prints it (with all its marks, for example the ayah shared
   from the ayah menu), **When** it is pasted into the field, **Then** that ayah is a result, for every one of the 6,236
   ayat.
4. **Given** the text of an ayah typed without tashkeel and tatweel, with ٱ أ إ آ as a bare ا, ة as ه and ى as ي (the small
   signs that stand for letters are left as the Mushaf has them), **When** it is searched, **Then** that ayah is a result, for
   every one of the 6,236 ayat.
5. **Given** the same query typed twice with different hamza spellings or with and without tashkeel or tatweel, **When**
   both are searched, **Then** the surah results and the ayah results are the same.

---

### User Story 4 - Searching never moves my wird or my place until I choose a result (Priority: P2)

The reader is following a wird at page 50. It opens search, types, scrolls the results, and leaves without choosing: the
reader is exactly as it was. It chooses an ayah on another page: the page is shown in browse mode, the wird's position,
khatma count, today's portions and reminders do not change, «اجعلها موضعي» appears as it does after a jump from the
index, and the reader can still make that page its position with it.

**Why this priority**: The reader's position is the app's promise (Constitution II and VII); search is only a way to
look somewhere else, like the index and the go-to-page dialog.

**Independent Test**: With a wird at page 50, open search and close it with back: page, zoom, bars, wird and last viewed
page are unchanged. Choose a result on page 300: page 300 is shown, the wird is still on 50, the banner «اجعلها موضعي»
is there; the saved last viewed page is 300 (as after the index).

**Acceptance Scenarios**:

1. **Given** the reader follows a wird, **When** search is opened and closed without a choice, **Then** nothing changed:
   the page, the zoom, whether the bars are shown, the wird's position and the last viewed page are as before.
2. **Given** a result on a page other than the one shown, **When** the reader taps it, **Then** that page is shown in
   browse mode, no wird moves, and the last viewed page becomes that page (the same as the index).
3. **Given** a result on the page already shown while the reader follows a wird, **When** it is tapped, **Then** the
   reader stays in wird mode and only the highlight appears.
4. **Given** the reader has no wird, **When** it chooses a result, **Then** the page is shown in browse mode (as it
   always is without a wird).
5. **Given** the reader chose a result, **When** it swipes to the next page in browse mode, **Then** no wird moves; **When**
   it taps «اجعلها موضعي», **Then** the wird's position becomes the shown page.
6. **Given** search is open, **When** the phone's back button is pressed (after the keyboard, if it is up), **Then**
   search closes and the reader (or the index it was opened from) is exactly as it was.

---

### User Story 5 - Quick while I type, and clear when there is nothing to show (Priority: P2)

Results change as the reader types, on a phone, without waiting. The first time search is used in a run of the app the
text is made ready in the background: the surah search works at once, and the ayah group says it is getting ready. When
nothing matches, or nothing is typed yet, or the text could not be made ready, a short Arabic line says so and what to do.

**Why this priority**: A search that stutters while typing, or that goes blank without a word, is not trusted, and the
Mushaf's smoothness (feature 010) must not be paid for by it.

**Independent Test**: On the owner's phone, type a common word letter by letter: each answer is on screen within 300 ms
of the last letter; the reader's page turns and fades (feature 010) are not slower after the first opening of search.

**Acceptance Scenarios**:

1. **Given** nothing is typed, **When** search opens, **Then** the field is focused with the keyboard up and one line
   explains what can be typed: «اكتب اسم سورة، أو كلمات من آية».
2. **Given** one letter is typed, **When** results appear, **Then** the surah group answers and the ayah group asks for
   at least two letters instead of showing thousands of rows.
3. **Given** this is the first search of the run and the text is still being made ready, **When** the reader types,
   **Then** the surah group answers at once, the ayah group says «جارٍ تجهيز البحث في الآيات», and the ayah results appear
   by themselves when it is ready, for the text now in the field.
4. **Given** nothing matches in either group, **When** the results are due, **Then** one line says «لا توجد نتائج» and
   suggests fewer words; a group that has no match is not shown at all.
5. **Given** the reader types quickly, **When** an older answer arrives after a newer one was asked, **Then** it is
   dropped: the list always shows the answer to what is in the field.
6. **Given** the bundled text cannot be read (a damaged install), **When** the ayah group is due, **Then** it shows
   «تعذّر تجهيز البحث في الآيات» with a «إعادة المحاولة» button; the surah group, the reader and everything else keep
   working.
7. **Given** a query that has no Arabic letter (digits, Latin letters, only marks or spaces), **When** it is typed,
   **Then** it counts as having nothing to search: the line of scenario 1 is shown, never an error.

---

### User Story 6 - Comfortable in both looks, at every size, for everyone (Priority: P2)

Search uses the colours of the look the reader chose (Emerald & Gold or Night Reader), shows the Quran words of a result
at the reading size chosen in Settings (feature 003), follows the phone's font size, stays usable on a 320 dp phone with a
2x font, has 48 px targets and is understood by a screen reader.

**Why this priority**: The quality bars of features 003, 004 and 006 to 008 apply to every new screen.

**Independent Test**: Pump the search in both looks, at 80, 100 and 150 percent, at 412 x 915 and at 320 x 640 with a 2x
system font, in the states «results», «لا توجد نتائج» and «جارٍ تجهيز البحث»: no overflow, every text at least 4.5:1, every
icon at least 3:1, every target at least 48 by 48 px, and the emphasised words are told apart by more than colour.

**Acceptance Scenarios**:

1. **Given** either look at 320 x 640 with a 2x font, **When** results are shown, **Then** nothing overflows, rows grow to
   hold their text, the field stays visible above the keyboard and the list scrolls.
2. **Given** either look, **When** a result is drawn, **Then** its text, its emphasised words (bold or underlined as well
   as coloured), the group headings, the hints and the icons meet the contrast of FR-023.
3. **Given** a reading size of 150 percent, **When** a result is drawn, **Then** the Quran words of its snippet are larger
   in the same proportion as the other reading texts, and the rest of the screen follows only the phone's font size.
4. **Given** a screen reader, **When** a row is reached, **Then** it hears «سورة البقرة، آية 255، صفحة 42» followed by the
   words of the ayah, the groups' headings are headings, and the result of each change of query is announced once.
5. **Given** the reader opens the ayah result on a page that is taller than the screen (a reading size above 100 percent,
   or landscape), **When** the page is shown, **Then** the ayah is in view without scrolling.

---

### Edge Cases

- An empty query, only spaces, only tashkeel or only tatweel is the same as nothing typed.
- A query with no Arabic letter (digits only, Latin letters, punctuation) finds nothing and shows the explanation line;
  it is not read as a page number (the index's tab «صفحة» does that).
- A pasted ayah with the ornate brackets «﴿ ﴾», the end-of-ayah sign «۝» and its number: they are ignored; only the Arabic
  letters count. The longest ayah (2:282, about 1,200 characters with its marks) can be pasted whole.
- A query so common that it matches most of the Quran («ال» finds about 5,000 ayat): the screen stays responsive, the
  heading shows the count, and the end of the list can be reached.
- The refrain «فَبِأَيِّ ءَالَآءِ رَبِّكُمَا تُكَذِّبَانِ» (31 ayat of Ar-Rahman) and every other repeated text: each ayah is
  its own row with its own number; none are merged.
- An ayah that continues on the next page opens at the page where it begins; the highlight (if kept, FR-013) covers its
  part on that page and the reader swipes on for the rest.
- A result on the page already shown while following a wird: no browse mode, only the highlight.
- The index writes some names in a spelling of its own («سبإ», «النبإ», «الإنفطار», «الانسان», «ابراهيم»): any spelling
  typed finds them, and the row shows the name exactly as the index does (this feature does not re-spell the names).
- A word found only inside a longer word, or across a prefix («وبالله», «فاستقم»): it is found (FR-005); this means a
  short query also returns ayat the reader did not mean, and the count says how many.
- The keyboard is Latin (English) by mistake: the query has no Arabic letter, so the explanation line is shown.
- The phone is rotated, or the app goes to the background and returns, while search is open: the query, the results and
  their scroll position are still there.
- The reader taps a result twice quickly: the page is shown once and nothing is repeated.
- Search is opened while the preparing of the text is still running from an earlier closed search: it continues, it is
  not started again.
- The text cannot be made ready: the ayah group shows the failure line and the button; tapping the button tries again;
  nothing else is affected.
- Searching never writes: no table, setting, backup field, log line or file is created for a query or a result.
- The Quran text in the pages, the ayah menu, the share text and the PDF is not changed by this feature (Constitution I).

## Requirements *(mandatory)*

### Functional Requirements

**Opening and leaving**

- **FR-001**: Search MUST be reachable from the reader without replacing it as the first screen: the app still opens on a
  Mushaf page, and search is a screen reached from the reader that returns to it (Constitution II).
  Decided by the owner on 2026-11-21: search opens from a search icon in the top bar of the index screen (the screen the reader already opens by tapping the surah name), so the reader's own bars do not change; it takes three taps (the surah name, the icon, a result) from the reader to an ayah.
- **FR-002**: Search MUST be one screen with one text field, a clear button, and the results below in up to two labelled
  groups: «السور» then «الآيات», each heading showing its count. A group without a match MUST NOT be shown; the ayah group is shown with a line of its own
  instead of rows only when it must ask for a second letter (FR-009), is getting ready, or has failed (User Story 5). The field
  MUST be focused with the keyboard open when the screen opens.
- **FR-003**: The system back, and the screen's own back arrow, MUST close search first (after the keyboard, if it is up)
  and return to where it was opened from, with the reader exactly as it was (User Story 4).

**What is searched and how it is matched**

- **FR-004**: The surah group MUST match the 114 surah names from one typed letter. The word «سورة» at the start of the
  query and a leading «ال» on either side MUST be ignored. Order: the name that equals the query, then names that start
  with it, then names that contain it; ties in surah order.
- **FR-005**: The ayah group MUST match the Quran text of the 6,236 ayat from two typed letters. A query matches an ayah
  when it appears, as one run of letters, in the ayah's text, inside a word or across words, a space in the query matching
  a space in the text or none (so «يا ايها» finds the one word «يَٰٓأَيُّهَا»). Each ayah is matched on its own; the
  results are one row per ayah in Mushaf order (surah, then ayah).
- **FR-006**: The matching MUST ignore, in the query and in the text: tashkeel, the Quranic marks, tatweel, and the ornate
  signs and ayah numbers of a pasted ayah. It MUST treat as one letter: أ إ آ ٱ and ا; ة and ه; ى and ي; and a hamza written
  on a seat (ؤ ئ), on the line (ء) or not written at all (the table of User Story 3: «مؤمن / مومن», «شيئا / شيأ», «يستهزئون
  / يستهزءون»). Query text MUST also be accepted with any of these written exactly as the Mushaf writes them.
- **FR-007**: The matching MUST find a word typed the way everyday Arabic writes it even where the Mushaf writes it
  differently: a small alef where everyday Arabic has a long alef or none («الكتاب», «الرحمن», «هذا»), «ـوٰة» for «ـاة»
  («الصلاة», «الزكاة», «الحياة»), a small yeh for a long yeh («إبراهيم», «النبيين»). Every row of the table of User
  Story 3 is a requirement, and the rules MUST NOT be so loose that «احمد» finds the ayat of «الحمد» or that a distinctive
  phrase finds more than the ayat that contain it (the four rows marked «exactly»).
- **FR-008**: What the reader typed MUST NOT be altered in the field, and the field MUST accept at least 1,500 characters.
- **FR-009**: A query with no Arabic letter left after FR-006 MUST be treated as nothing typed. A query of one Arabic letter
  MUST search the surah names only and ask for a second letter in the ayah group.

**Results and where they lead**

- **FR-010**: A surah row MUST show what the index row shows (its number, its name as the index writes it, «ص» and its first
  page); tapping it MUST show the surah's first page as the index does.
- **FR-011**: An ayah row MUST show the surah's name, the ayah's number and the page where the ayah begins («ص N»), and a
  snippet of the ayah's own words with the matched words emphasised by more than colour. The ayah's page MUST be the page of
  its first word.
- **FR-012**: The snippet MUST be the stored words of the ayah, character for character, in the Quran font the app already
  contains (no new font), never the typed or the simplified form. It MUST show at most three lines at the reading size; an
  ayah too long for that MUST be cut between whole words around the first match, with «…» where words are left out.
- **FR-013**: Tapping an ayah row MUST close search (and the index it was opened from) and show the page of FR-011 in browse mode (User Story 4), with the found
  ayah in view on arrival at every reading size (80 to 150 percent, portrait and landscape), also when the page is taller
  than the screen.
  Decided by the owner on 2026-11-21: the found ayah is highlighted the way the long-press highlight is drawn, until the reader next touches the page, turns it or opens something.
- **FR-014**: Each group's heading MUST show its number of results (a number, not a sentence that needs plural forms). Every
  listed result MUST be reachable by scrolling.
  Decided by the owner on 2026-11-21: the ayah group lists only the first 100 matches, in Mushaf order, and under them a line that asks for more words to narrow the search (a string proposal, Constitution VI: «النتائج كثيرة، اكتب كلمات أكثر لتضييق البحث»). The surah group is never cut (at most 114 rows). The heading of the ayah group still shows the total number of matches, not 100, so a short query shows its true size (for example «ال» matches about 5,000).

**The wird and the position**

- **FR-015**: Choosing a result on a page other than the one shown MUST enter browse mode exactly as the index does: no wird's
  position, khatma count, today's portions or reminders change, bookmarks are untouched, the last viewed page becomes the
  chosen page, and «اجعلها موضعي» appears when a wird exists (feature 001 FR-016, FR-017).
- **FR-016**: Choosing a result on the page already shown MUST NOT change the mode (the go-to-page precedent); only what
  FR-013 says appears.
- **FR-017**: Opening search, typing, scrolling and leaving without a choice MUST change nothing in the reader (page, zoom,
  bars, wird, last viewed page, settings), and no query, result or choice MUST be stored, logged or added to a backup.

**The text, the data and the constitution**

- **FR-018**: The Quran text, its order and its page and line distribution MUST NOT be modified (Constitution I). Matching
  MUST read a derived copy of the text made for comparison only; the copy MUST NOT be shown, shared, used by the pages, the
  ayah menu, the share text or the PDF, and the stored text MUST stay the only text shown.
- **FR-019**: The derived copy MUST come from the stored text by fixed rules and MUST be checked automatically: 114 surahs and
  6,236 ayat, the same ayat per surah as the Mushaf's data, and one entry per ayah; a failed check MUST stop the build or fail
  a test that the build runs (Constitution I, generated Quran data). The existing text-integrity, layout and page tests MUST
  pass unchanged.
- **FR-020**: No result, snippet or search MUST involve the tafsir, the English translation or the word meanings.
- **FR-021**: The feature MUST work offline, add no package, no permission, no network call and no account, send nothing off the
  phone, and add at most 2 MB to the installed app (Constitution IV, VIII).

**Speed**

- **FR-022**: Nothing of the ayah search MUST be loaded or computed when the app starts or while the reader is used; the first
  time search is opened in a run, the text MUST be made ready without a frame of the reader or of search taking longer than
  100 ms, and without delaying the field, the keyboard or the surah group. Once ready it MUST stay ready for the run, holding
  at most 25 MB more than before search was opened.
- **FR-023**: Results MUST be on screen within 300 ms of the last typed letter, for every query up to 1,500 characters, on the
  owner's phone (SC-004); an answer to an older query MUST never replace the answer to the current one.

**Looks, sizes, accessibility, strings**

- **FR-024**: Colours and shapes MUST come from the chosen look (Emerald & Gold, Night Reader); text MUST reach 4.5:1 contrast
  (including the emphasised words, the hints and the heading) and icons 3:1, in both looks, in every state.
- **FR-025**: Every target (the search icon, the clear button, a result row, «إعادة المحاولة») MUST be at least 48 by 48 px. At
  320 dp wide with a 2x system font, in both looks and at the three reading sizes, nothing MUST overflow or be cut off; rows
  grow to fit; the field stays visible with the keyboard open.
- **FR-026**: The snippet's Quran words MUST follow the reading size of feature 003 (and the same cap on size times system font
  as the other reading texts); the rest of the screen MUST follow the system font size only.
- **FR-027**: A screen reader MUST hear the field's name, each group's heading as a heading with its count, each row as «سورة
  {name}، آية {n}، صفحة {p}» followed by the ayah's words (a surah row as «سورة {name}، صفحة {p}»), and the clear button by its
  name; a change of results MUST be announced once, not per letter.
- **FR-028**: Every Arabic string MUST live in one file, each marked as a proposal until the owner confirms it (Constitution VI);
  none is machine-translated; numbers are written with Western digits like the page number the app already draws. The
  proposals are in Assumptions.
- **FR-029**: Rotating the phone, or sending the app to the background and back, MUST keep the query, the results and their
  scroll position while search is open.
- **FR-030**: The index's three tabs, the go-to-page dialog, the bookmarks, the reader's bars, the wirds screens, the tips and
  the splash MUST behave as before, and every earlier test MUST pass without change (a test that counts the buttons of the index's app
  bar, if one is found, is the only change allowed).

### Key Entities *(include if feature involves data)*

- **Query**: the text in the field. Kept only while search is open; never stored, logged or backed up.
- **Search form**: for each surah name and each ayah, a copy of its text with the spellings of FR-006 and FR-007 folded
  together, used only to compare. It is derived from the stored text, never edited by hand, never shown, and never replaces it.
- **Surah result**: a surah (number 1 to 114, name as the index writes it, first page).
- **Ayah result**: an ayah (surah, number), the page where it begins, its stored words, and which of them matched.
- **Existing, unchanged**: the surah list, the 114 files of ayah text, the 604 Mushaf pages, the reader's jump rules.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Each of the 114 surah names, typed in the five careless ways of User Story 1, is found with its surah among the
  results, and the name equal to the query is the first row (570 of 570 queries, in an automated test over the real names).
- **SC-002**: Every row of the table of User Story 3, in every typed form, finds the ayat it names, and the four «exactly» rows
  find exactly those ayat (every form of every row passes: 100 percent).
- **SC-003**: For all 6,236 ayat, the ayah's own text pasted exactly as the Mushaf prints it, and the same text with the
  tashkeel and tatweel removed, ٱ أ إ آ as ا, ة as ه and ى as ي (scenario 4 of User Story 3), each returns that ayah
  (12,472 of 12,472 queries, in an automated test over the real text).
- **SC-004**: On the owner's phone, results are on screen within 300 ms of the last letter for 100 percent of 20 queries (ten
  one-word, five phrases, «ال», the longest ayah pasted, and three that match nothing), with the median within 100 ms
  (measured with a timing line the app can log in a measurement build, like its other measurements). An automated test fails if a search of the whole text on the
  development machine takes more than 1 second, so a slow rule cannot slip in.
- **SC-005**: The first opening of search in a run has the ayah text ready within 2 seconds on the owner's phone; the surah
  search answers from the first letter; no frame of the reader or of search takes longer than 100 ms during it (the frame trace of
  feature 010), search holds at most 25 MB more than before it was opened, and the time from launch to the first Mushaf page is not longer
  than before the feature (5 launches, same phone).
- **SC-006**: From the reader to the found ayah shown on its page: 3 taps and the typing (the surah name, the search icon, a
  result), with the default of FR-001 (owner's check).
- **SC-007**: After a result is chosen, the wird position, khatma count, today's portions, other bookmarks, reminders and settings
  are the same as before (checked on a wird and in browse mode); the last viewed page is the chosen page; after back without a
  choice, 6 of 6 (page, zoom, bars, wird position, last viewed page, settings) are unchanged.
- **SC-008**: In both looks, at 80, 100 and 150 percent, at 412 x 915 and at 320 x 640 with a 2x system font, in the states «results»,
  «لا توجد نتائج» and «جارٍ تجهيز البحث»: 36 of 36 combinations without overflow, every text at least 4.5:1, every icon at least 3:1,
  every target at least 48 by 48 px.
- **SC-009**: The snippet of a result is, for every one of the 6,236 ayat, a run of consecutive words of the stored ayah, character
  for character; the existing Quran text, layout and ayah-text tests pass unchanged; the build's check of the derived copy (FR-019)
  passes.
- **SC-010**: The permissions of the app, its dependencies, its network calls and its database tables are the same as before; search
  works with the phone in airplane mode (owner's check); the installed app grows by at most 2 MB.
- **SC-011**: On the owner's phone the owner finds five surahs and five ayat of their own choosing, typed the quick way they would
  type them (owner's own check; the wording of every string is theirs to confirm).

## Assumptions

- **What was read in the code on 2026-11-21**: the index (tapped from the surah name in the reader's top bar), the go-to-page
  dialog (tapped on the page number), the bookmarks sheet and a notification of kind «page:N» all end in the reader's jump, which
  sets browse mode, moves no wird and saves the page as the last viewed (`lib/mushaf/reader_controller.dart`,
  `lib/mushaf/reader_screen.dart`); only «اجعلها موضعي» moves the wird again. The index jumps even when the page is the one shown;
  the go-to-page dialog does nothing in that case, and search follows the dialog.
- The search depends on: the surah names and the page of every ayah (`assets/mushaf/meta.json`), and the Quran words of every ayah
  in 114 surah files (`assets/ayah/text/`, Uthmani script with its marks, 6,236 ayat, 77,432 words, about 1.7 MB), both already
  bundled. The Mushaf pages themselves hold only the glyphs of the page fonts, not searchable text, so the page data cannot be
  searched. The Unicode words are today used only for sharing an ayah as text; showing them in a snippet is a new use on screen,
  in the Quran font the app already ships for the basmala line.
- The surah names are the ones in the app's metadata, spelled as the index spells them. Alternative names, named ayat and other
  languages are out of scope, as is a jump by «2:255» or by a bare page number.
- Out of scope for this version: search inside the tafsir, the translation or the word meanings; a history or favourites of
  searches; voice input; ranking by relevance; matching a phrase across two ayat; a tip about search in the first-run tips (the
  owner decides if one is wanted, with the truth test that feature 008 has for every tip); correcting how the index spells some
  surah names.
- **Arabic strings** (the owner confirmed all of them on 2026-11-21, task T070). **Proposed Arabic strings** (Constitution VI: the owner confirms every one before the feature is done; they live in one strings
  file with a doc comment each; N is a number, written with Western digits):
  - the search icon, its tooltip and its label: «بحث»; the field's label: «ابحث عن سورة أو آية»; the clear button: «مسح»;
  - the groups' headings: «السور · N» and «الآيات · N» (for a screen reader: «السور، عدد النتائج N»);
  - nothing typed (and no Arabic letter typed): «اكتب اسم سورة، أو كلمات من آية»;
  - one letter, in the ayah group: «اكتب حرفين على الأقل للبحث في الآيات»;
  - the first time: «جارٍ تجهيز البحث في الآيات»;
  - nothing matched: «لا توجد نتائج» and, under it, «جرّب كلمة واحدة أو كلمات أقل»;
  - the failure: «تعذّر تجهيز البحث في الآيات» with the button «إعادة المحاولة»;
  - a surah row: the number, the name and «ص N» as in the index (for a screen reader «سورة {name}، صفحة N»); an ayah row: «{name} ·
    آية N» and «ص N» (for a screen reader «سورة {name}، آية N، صفحة N»);
  - the mark for left-out words in a snippet: «…».
- "Browse mode" has the meaning of feature 001 (FR-016, FR-017); "the reading size" is feature 003's 80 to 150 percent; "the looks" are
  Emerald & Gold and Night Reader (feature 004).
- The index screen's own app bar gets the search icon (FR-001, proposed default); its three tabs and the rest of the screen stay as they
  are. If the owner chooses another place, only FR-001, SC-006 and the geometry tests of the place chosen change.
- The phone check follows Constitution IX; the owner is asked before any install or input on the phone.
