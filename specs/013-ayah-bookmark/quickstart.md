# Quickstart: validating feature 013 (ayah bookmark)

## Automated

```bash
flutter analyze
flutter test test/migration test/ayah_bookmarks test/bookmarks test/backup test/ayah test/wirds test/search test/motion test/look
flutter test            # the whole suite, once, at the end
```

New tests are in `test/migration/` and `test/ayah_bookmarks/` (plan.md lists every file). The earlier tests of features 001,
002, 006, 010 and 011 pass unchanged, except one number in each of `test/backup/backup_service_test.dart` (`version 2 is a
newer backup`) and `test/settings/backup_ui_test.dart` (the newer-backup case): 2 becomes 3 (research D13).

### The real version-1 file (do this first, on the unchanged code)

```bash
flutter test test/migration/make_v1_fixture_test.dart --dart-define=MAKE_DB_V1=true
git add test/migration/fixtures && git commit      # BEFORE any edit of lib/wirds/db.dart
```

The file `test/migration/fixtures/mushaf_v1.sqlite` and its `mushaf_v1_expected.json` are what proves SC-003. Never regenerate
them after the schema change.

### Measurements that print numbers (kept in research notes when they are taken)

`flutter test test/ayah_bookmarks/tint_contrast_test.dart --reporter expanded` prints the contrast of the page ink on the tint,
the hue distance between tint and highlight, and the tint against the paper, in both looks (the values of research D6).
`reader_tint_rebuild_test.dart` prints nothing: it asserts the `MushafPage` build counts of a page turn with 200 bookmarks
(the values are in research "Measured").

## On the phone (the owner's <phone>)

**Rules**: the agent never unlocks the phone, sends no input and installs nothing without the owner's OK in chat for that
step; the owner exports a backup first («تصدير نسخة احتياطية» in Settings) and keeps the file.

1. Install the build over the existing release build (the owner's OK). Open the app: every wird, position, bookmark and the
   text size and look are as before (the real migration of real data). Open «علامات»: the old bookmarks are all there, as page
   rows.
2. Long press a word: the sheet shows «إضافة علامة على الآية» and «ملاحظة للآية», both as full rows. Tap the first: the sheet
   closes, the message «تمت إضافة علامة على سورة X · آية N» shows above the bottom bar, and a light tint is behind the ayah.
   Tap «تراجع»: the tint is gone.
3. Long press the same ayah again: the row says «إزالة العلامة من الآية». Long press shows the usual highlight, not the tint;
   close the sheet: the tint is back. Tell the two washes apart in both looks (SC-015).
4. Tap «ملاحظة للآية» on another ayah, write a note, save: the bookmark exists with the note, the message shows, the tint is
   behind it; open the sheet again: the row shows the start of the note; open the note field: the note is in it. Empty it and
   save: the note is gone, the bookmark stays. Cancel: nothing changes. With a note, the sheet also shows «عرض الملاحظة»: it
   shows the whole note; «تعديل» opens the field, «إغلاق» returns to the sheet (FR-028).
5. Open «علامات»: the ayah rows look different from page rows, show the note, and tapping one shows the page with the ayah
   highlighted (a row deleted here keeps its tint on the page behind until the sheet closes); touch the screen: the highlight goes, the tint stays. Swipe a row: deleted.
6. On a page with a page bookmark and an ayah bookmark: tap the top-bar icon: only the page bookmark goes; the ayah bookmark
   and its tint stay.
7. Bookmark 2:282 (page 48): the tint is on page 48 only (the ayah fills it; no ayah crosses a page). Turn pages quickly with many bookmarks: no new lag (the frame
   numbers of `specs/010-smooth-motion/phone/measure.sh` before and after, if the owner wants numbers).
8. Settings: switch the tint off: no tint anywhere, bookmarks still there; on: it returns without a restart. Rotate the phone,
   raise the system font: nothing overlaps or is cut.
9. Switch the wird (or browse): the tint follows the scope. Export a backup, import it: bookmarks, notes and the switch are as
   they were.
10. Read the strings of `ayah_bookmark_strings.dart` with the owner, word by word (Constitution VI): the feature is not done
    before he confirms them. (Done 2026-11-25, T048: «كلها تمام».)

**State at convergence (T049, 2026-11-25)**: step 1 done (T044: installed over the release build, «كله موجود»); step 10
done (T048); the «عرض الملاحظة» row checked (T051, «تمام»). Steps 2 to 9 were not walked one by one with the owner (T045
open): he tried the feature, but the steps, the tint against the highlight by eye (SC-015) and the frame numbers with 200
bookmarks (SC-016) are not recorded.
