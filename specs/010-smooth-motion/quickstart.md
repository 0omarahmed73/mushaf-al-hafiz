# Quickstart: validating feature 010 (smooth motion)

## Automated (no phone)

```bash
flutter analyze
flutter test test/motion --reporter expanded        # prints the MOTION numbers; compare with research.md D8
flutter test test/mushaf test/look test/bookmarks test/khatm test/wirds   # earlier features, unchanged
```

`test/motion/` already holds the measurements of this research (M1-M5, S1). New tests per tasks.md: the rebuild budget
(`reader_rebuild_budget_test.dart`), neighbours ready at rest, bars, today card, jump, icon, reduce motion, geometry during
motion, the look fade, and (Stage C) the position saver. Run the whole suite once at the end: `flutter test`.

Reading the numbers: counts (rebuilds, elements, reads) are the evidence; milliseconds come from a JIT test VM and only compare
two things measured in the same run (research, "How to read the numbers").

## On the phone (owner's <phone>; never unlock it, ask before sending input or installing)

Everything below needs the owner in that session. The script refuses to run without `--approved-by-owner`.

1. Build with the traces: `flutter build apk --release --dart-define=FRAME_TRACE=true --dart-define=PAGE_TURN_TRACE=true`;
   install with `adb -s <phone> install -r build/app/outputs/flutter-apk/app-release.apk` (data kept). **Baseline**: do this
   with the code before Stage A (task T003) so the «before» numbers exist.
2. The owner unlocks the phone, opens the reader, jumps to page 50 from the index (browse mode keeps the wird still).
3. `specs/010-smooth-motion/phone/measure.sh --approved-by-owner --label before --pace slow --swipes 50`, then `--pace normal`,
   then `--pace fast`; each prints the summary and saves it in `phone/results/<time>-<label>-<pace>/`.
4. Wird mode: the owner opens the reader on a wird, the same three runs with `--and-back` (50 forward, 50 back, so the position
   ends where it started; or the owner exports a backup first).
5. After Stage A (and again after the motion tasks): repeat with `--label after-A`, `--label after-motion`; compare the three
   `summary.txt` files: share within the budget, p99, max, `PAGETURN`, `PAGEWARM`.
6. Memory: `adb -s <phone> shell dumpsys meminfo app.hafiz.mushaf` before and after 200 swipes (font retention).
7. By hand: turn pages slowly and fast; tap to hide and show the bars; open and close the today card; go to a page from the
   index, from the page number and from a bookmark; change the wird; change the look in Settings; the edge turn at 150%; TalkBack
   on: swipe to the next page with the screen reader (neighbours are in its tree now); then the system setting «remove
   animations» on: every item above is instant and nothing is left half transparent.
8. Read the numbers against contracts/ui.md "Measured and accepted on the phone"; ask the owner the questions of the spec
   (does the lag feel gone; do the bars, the card and the jumps feel soft but not slow).

## What a failing number means

See research.md D9, "What a failed number points at".

## Questions for the owner (Egyptian Arabic, ready to ask; the plan has a proposed answer to each, nothing waits on them)

1. التعليق بتحسّه في **أول** السحبة ولا في **آخرها** ولا في النص؟ وبيحصل في كل الصفحات ولا في صفحات معينة (زي أول الجزء أو الصفحات الزحمة)؟ وبيحصل وانت ماشي على وردك ولا وانت بتتصفح بس؟ (بيساعدني أعرف السبب قبل ما أقيس.)
2. لما بتسحب الصفحة وتسيبها، الصفحة بتستقر بسرعة ولا بتحس إنها «تقيلة» وبطيئة شوية؟ (المقترح: أسيب سرعة الاستقرار زي ما هي، ولو لسه تقيلة بعد الإصلاح أخليها أسرع.)
3. لما تغيّر المظهر (زمردي ↔ ليلي) تحب الشاشة تتبدّل بتلاشي ناعم حوالي ربع ثانية، ولا تفضّل تتبدّل فوراً زي دلوقتي؟ (المقترح: تلاشي ناعم، وفوراً لو شغّلت «إزالة الحركات» في الموبايل.)
4. لما تروح لصفحة من الفهرس أو من «الانتقال لصفحة» أو من علامة أو من ورد تاني: تحب الصفحة تظهر بتلاشي خفيف (المقترح) ولا فوراً زي دلوقتي؟
5. ينفع أركّب على موبايلك نسخة للقياس (بتكتب أرقام الأداء في سجل الموبايل بس، مفيش أي حاجة بتخرج منه) وأعمل ٥٠ سحبة بالأمر؟ لازم تفتح الموبايل بنفسك وتسيب التطبيق على المصحف. وللقياس على ورد: هعمل ٥٠ سحبة لقدّام و٥٠ لورا عشان الورد يرجع لمكانه، ولا تفضّل تعمل نسخة احتياطية الأول؟
6. (بعد القياس بس، ولو احتجنا) ينفع نأخّر حفظ مكانك لحد ما توقّف تقليب الصفحات حوالي نص ثانية؟ هيتحفظ فوراً لو خرجت من التطبيق أو فتحت شاشة تانية.
