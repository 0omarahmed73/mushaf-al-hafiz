# Quickstart: validating feature 011 (surah and ayah search)

## Automated (no phone)

```bash
python3 -I specs/011-surah-ayah-search/prototype/match_rules.py        # the reference: table, self-match, narrowing, 570 names (about 25 s)
python3 -I specs/011-surah-ayah-search/prototype/match_rules.py --full # adds the 15,122-word sweep (about 100 s)
flutter analyze
flutter test test/search --reporter expanded                            # this feature
flutter test test/mushaf test/look test/bookmarks test/onboarding test/motion test/ayah test/settings   # earlier features, unchanged
flutter test                                                            # the whole suite, once, at the end
```

Run `python3 -I specs/011-surah-ayah-search/prototype/match_rules.py` from the repository root first: the Dart tests of `test/search/` must agree with the
numbers it prints (the narrowing table of research D2, the 34 forms, the 570 names). The real-data tests read the bundled assets through `rootBundle`; the first
one builds the index once (about 0.3 s in the test VM) and the others share it through `test/support/search_harness.dart`.

Reading the numbers: counts (ayat found, rows, words) are the evidence; milliseconds from the test VM only compare two things measured in the same run. The
bound of SC-004 in the tests is 1 s for a whole-text search, which takes about 10 ms.

## By hand on a computer (optional, `flutter run -d linux` or the emulator)

1. Reader, tap the surah name, tap the search icon: the field has the focus and the line «اكتب اسم سورة، أو كلمات من آية» is shown.
2. Type «كهف»: «السور · 1» with «18 الكهف ص 293». Type «سبا»: surah 34. Type «ق»: surah 50 first, and the ayah group asks for a second letter.
3. Type «قل هو الله احد»: one ayah row «الإخلاص · آية 1 · ص 604» with the words emphasised; tap it: the page opens, the ayah is highlighted.
4. Type «ال»: the heading shows the true total (5,182), 100 rows, and the line asking for more words.
5. Type «لؤلؤ»: 8 rows, not thousands. Type «ذو القرنين»: «لا توجد نتائج». Type «ذي القرنين»: 18:83.
6. Back: the index, back again: the reader exactly as it was. Open a result on the page already shown while following a wird: the wird stays on, the ayah is highlighted.
7. Touch the page: the highlight goes. Set the reading size to 150% and open 2:282 from search: its first line is in view.

## On the phone (owner's <phone>; never unlock it, ask before sending input or installing)

Everything below needs the owner in that session.

1. Build with the traces: `flutter build apk --release --dart-define=SEARCH_TRACE=true --dart-define=SEARCH_BENCH=true --dart-define=FRAME_TRACE=true`;
   install with `adb -s <phone> install -r build/app/outputs/flutter-apk/app-release.apk` (data kept). **Baseline for the launch time**: 5 launches to the first
   Mushaf page with the build made before this feature (the owner's installed release build), and 5 with the new one.
2. The owner unlocks the phone, opens the reader, taps the surah name and the search icon. In `adb logcat -s flutter`: one `SEARCH prepare ms=...` line (target
   under 2,000), the 20 `SEARCHBENCH` lines (each under 300, the median under 100), and the frame trace lines around the preparation (none over 100 ms).
3. `adb -s <phone> shell dumpsys meminfo app.hafiz.mushaf` before opening search and after the first result: the difference is at most 25 MB.
4. The reader's page turns and fades are not slower after search was opened once (the frame trace of feature 010, a few swipes).
5. By hand: type five surahs and five ayat of the owner's choice the quick way (SC-011), with the phone in airplane mode; rotate with a query typed; choose
   a result on another page, on the same page, in wird mode and in browse mode; read at 150% and landscape; Night Reader and Emerald & Gold; TalkBack on:
   the rows are read as «سورة البقرة، آية 255، صفحة 42» and a change of results is announced once.
6. Read the numbers against research D9 (the decision rule) and ask the owner the questions below.

## What a failing number means

See research.md D9, "Decision rule", and D5 (slices) before changing anything.

## Questions for the owner (Egyptian Arabic, ready to ask; the plan has a proposed answer to each, nothing waits on them)

1. كل النصوص العربية في الشاشة (العناوين، سطر «اكتب اسم سورة، أو كلمات من آية»، «لا توجد نتائج»، «النتائج كثيرة، اكتب كلمات أكثر لتضييق البحث»، وباقيها) مقترحات، تراجعها واحدة واحدة وتقول لي أيها تغيّر.
2. الكلمات اللي بتطابق كتابتك تتميّز بلون مميّز مع خط تحتها (المقترح)، ولا تفضّلها بخط عريض؟
3. لو كتبت «مئة» (الإملاء المعتاد) وعايزها تلاقي «مائة» في المصحف، أعدّل القاعدة (سطر واحد) عشان الألف الساكنة تتجاوز؟ دلوقتي «مئة» بتطلع نتايج قليلة مش مظبوطة، و«مائة» بتلاقيها صح.
4. لما تضغط على آية موجودة في الصفحة اللي قدامك وإنت ماشي على وردك: الصفحة تفضل في وضع الورد ويتلوّن بس الآية (المقترح، زي «الانتقال لصفحة»)، ولا تفضّل تدخل وضع التصفح؟
5. ينفع أركّب على موبايلك نسخة للقياس (بتكتب أرقام الأداء في سجل الموبايل بس) وأفتح البحث وأقرا الأرقام؟ لازم تفتح الموبايل بنفسك.
