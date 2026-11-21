# Quickstart: validating feature 005 (khatm dua)

## Automated

```bash
flutter analyze
flutter test test/khatm test/mushaf test/settings
```

The new tests are `test/khatm/last_page_swipe_test.dart`, `dua_text_test.dart` (it pins the bytes the owner confirmed),
`khatm_dua_screen_test.dart`, `reader_khatm_test.dart`, `reader_khatm_back_test.dart`, `khatm_dua_look_test.dart` and
`khatm_about_test.dart`; the helpers they share are in `test/support/khatm_harness.dart`. The earlier mushaf and
settings tests must pass unchanged (FR-018, SC-007). Run the whole suite once at the end: `flutter test`. If
`dua_text_test.dart` fails on the checksum, the wording was changed: the owner must confirm it again (FR-016).

## On the phone (owner's <phone>; never unlock it, ask before sending any input)

1. Open the reader, go to page 604 from the index. The dua must NOT open (SC-001).
2. Swipe forward (finger left to right): the dua opens in under a second (SC-003). Try a slow drag, a quick flick
   and a tiny brush: only the first two open it. Tune `LastPageSwipe` constants if the feel is wrong.
3. Tap back: you are on 604. Swipe again: it opens again. Tap «آمين»: page 1 is shown; close and reopen the app:
   it opens on page 1 (SC-002).
4. Repeat in the other look (Settings → المظهر). Rotate the phone with the dua open. Raise the system font size.
5. With a wird that has a portion: «أوراد» shows the same «ختمات» and the same today portions before and after
   (SC-004).
6. Read the dua word by word against the confirmed wording (SC-006, FR-016); it is eleven paragraphs, so scroll: «آمين»
   is the last item. Look at the sign ۞ at the end of each paragraph: Cairo has no glyph for it, so it comes from a
   system font; it must not show as an empty box. Open «حول التطبيق» and read the credit.
