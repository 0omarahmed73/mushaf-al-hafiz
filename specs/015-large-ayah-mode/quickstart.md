# Quickstart: checking the Large Ayah Mode

## Automated (Principle IX)

```bash
flutter analyze
flutter test test/large_ayah/
flutter test
```

Expected: no analyzer issue; every test passes, including the whole-Mushaf check (SC-001) and the 2:282 at 320 dp test
(SC-005).

## On the owner's phone (release build, only after his «سطّب»)

1. Open the app on any page; «القائمة» → turn on «الآيات الكبيرة». The reader shows the first ayah of that page alone, large.
2. Swipe left to right: the next ayah comes in from the left. Swipe through the end of the page: the next page's first ayah
   follows, and the header's page number changes.
3. Settings → «عدد الآيات في الصفحة» → «آيتان», then «ثلاث آيات»: the screens regroup and start with the same ayah.
4. Go to page 48 (2:282): it is split over several screens, each but the last ending with «تتبع», all read by swiping only.
5. Long-press an ayah: it is highlighted and the ayah sheet opens; add an ayah bookmark; the ayah is tinted.
6. Inside the active wird, read into the next page; close the app from recents and open it again: it opens in the mode on
   the same screen, and the wird's position is that page.
7. Tap «المصحف»: the Mushaf opens on the page of that screen. Close and open the app: it opens on the Mushaf.
8. Switch to the Night look and repeat steps 1 and 5. Turn the phone sideways once.
9. Airplane mode for the whole walk (Principle IV).
10. The owner (or an elderly reader he chooses) reads a few screens at each size and says which is comfortable (SC-006).

## Run (T028, 2026-11-26)

- `flutter analyze`: no issues.
- `flutter test`: 2,451 passed, 1 skipped (the existing skipped fixture maker), 0 failed; of them 108 in `test/large_ayah/`.
- The phone walk above is not done yet (needs the owner's «سطّب», task T030).

## Phone walk (T030, 2026-11-26, the owner on <phone>, release build versionCode 2)

The owner did each step himself and answered the question of each one:

| Step | Result |
|------|--------|
| 1. Turn the view on from «القائمة» | «أيوه»: the first ayah of the page alone, large |
| 2. Swipe through the end of a page | «أيوه»: in order, the header's page number changed |
| 3. «آيتان», then «ثلاث آيات» | «أيوه»: regrouped with the same ayah on screen |
| 4. Page 48, 2:282 at one ayah a screen | «أيوه»: split over several screens with «تتبع», read by swiping only |
| 5. Long press, bookmark, tint | «أيوه» |
| 6. Read into the next page of the wird, close from recents, open | «أيوه»: opened in the view on the same screen |
| 7. «المصحف», then close and open | «أيوه»: the Mushaf on the screen's page, and the app opened on the Mushaf |
| 8. Night look, phone on its side | «أيوه»: nothing off screen |
| 9. Airplane mode | «أيوه» |
| 10. Comfort of the three sizes (SC-006) | «التلاتة كويسين»: all three are comfortable; the default stays «كبير» |
