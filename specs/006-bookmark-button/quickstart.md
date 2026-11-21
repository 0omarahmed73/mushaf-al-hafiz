# Quickstart: validating feature 006 (bookmark button)

## Automated

```bash
flutter analyze
flutter test test/bookmarks test/wirds test/mushaf test/khatm
```

New tests: `test/bookmarks/bookmark_toggle_repository_test.dart`, `bookmark_controller_test.dart`,
`reader_bookmark_geometry_test.dart` (the rectangles are literals recorded on the code before this feature),
`reader_bookmark_button_test.dart`, `reader_bookmark_look_test.dart`. The earlier mushaf, wirds, ayah, khatm and
settings tests must pass unchanged (FR-015, SC-007). Run the whole suite once at the end: `flutter test`.

## On the phone (owner's <phone>; never unlock it, ask before sending any input or installing)

1. Open the reader. The icon is at the far left, under «جزء · حزب · ربع», in Emerald & Gold and in Night Reader.
2. Tap it: the icon fills, a message «تمت إضافة علامة للصفحة N» with «تراجع» shows above the bottom bar; open
   «علامات»: one new entry for that page, no note.
3. Tap the icon again: it empties, the removal message shows; tap «تراجع»: the bookmark is back.
4. Turn pages: the icon follows. Delete the bookmark from the sheet: the icon empties.
5. Jump to a page (browse mode, «اجعلها موضعي» visible): the icon and the button do not touch; tap each.
6. Rotate the phone and raise the system font size: nothing overlaps or is cut.
7. Before and after a tap: the wird's position and today's portions on «أوراد» are the same.
8. Read the strings of `bookmark_strings.dart` with the owner (Constitution VI).
