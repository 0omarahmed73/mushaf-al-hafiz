# Quickstart: First-Run Tips

How to prove the feature works. Contracts: [contracts/dart-interfaces.md](contracts/dart-interfaces.md),
[contracts/ui.md](contracts/ui.md); stored fact and backup rule: [data-model.md](data-model.md).

## 1. Automated (no phone)

Prerequisites: the repository as it is; nothing to install.

```sh
timeout 600 flutter test test/onboarding --reporter expanded > /tmp/tips_tests.txt 2>&1
flutter analyze lib/onboarding lib/backup/backup_service.dart test/onboarding test/support/tips_harness.dart
dart format --set-exit-if-changed lib/onboarding test/onboarding test/support/tips_harness.dart lib/backup/backup_service.dart
```

Expected: every test passes; the analyzer reports no issue; the formatter changes nothing. Never run the whole suite from
this feature's session (other sessions edit the tree); the existing backup tests run with
`flutter test test/backup` once after the one edit of `backup_service.dart`.

What the tests cover (spec scenario → file):

| Scenario | File |
|---|---|
| shows once, after the first frame; not when seen; the same screen rebuilt; a real restart on a file database | `tips_gate_test.dart` |
| finish, skip and back store the flag; an outside touch and a programmatic close do not | `tips_gate_test.dart`, `tips_dialog_test.dart` |
| dots, next, back, RTL swipe, no swipe beyond the ends, double tap on «التالي» | `tips_dialog_test.dart` |
| both looks, 412 x 915 and 320 x 640 with a 2x font, no overflow, contrast, 48 px | `tips_look_size_test.dart` |
| semantics: «الخطوة N من 6», headings, buttons | `tips_dialog_test.dart` |
| reduced motion, the pulse | `tips_motion_test.dart`, `tip_picture_test.dart` |
| the tips reopened by a function, never twice at once | `tips_show_again_test.dart` |
| backup round trip, old file, kept flag, failed import | `tips_backup_test.dart` |
| each step's claim done on the real reader | `tips_reader_truth_test.dart` |
| every Arabic string pinned; six steps, at most two sentences, no Quran text | `tips_strings_test.dart`, `tip_steps_test.dart` |

## 2. On the owner's phone (Constitution IX; ask before installing or touching the phone)

1. Install a build with the gate wired (section 3) on a phone with the app's data cleared (or a fresh install).
2. Open the app: the splash (009) shows, then the Mushaf page, and the tips card opens over it within a second.
3. Swipe the card from left to right: step 2 comes in from the left, like turning a page; swipe back; tap «التالي» through to
   step 6; the last button is «ابدأ»; tap it. The Mushaf is as it was.
4. Close the app completely and open it again: no tips. Open it a third time: no tips.
5. Clear the data again, open the app, tap «تخطي» on step 1; reopen: no tips. Repeat with the system back on step 3.
6. With the tips open, turn the phone sideways, then switch to a large system font (Settings of the phone, 2x if offered):
   the text scrolls, «التالي» and «تخطي» stay in view and are easy to hit.
7. The card in «القارئ الليلي»: proved by the automated tests (`tips_look_size_test.dart`); on the phone it can be seen only
   when a Settings row that calls `showTips` exists (the owner's decision, see the report), or by choosing Night first and
   then clearing only the tips flag in a debug build.
8. Turn on «إزالة الرسوم المتحركة» (remove animations) in the phone's accessibility settings: the ring on step 1 is still
   and the steps change without a slide.
9. Read all six steps and confirm each Arabic sentence word by word (the owner's confirmation, Constitution VI).

## 3. Wiring (for the coordinator)

See "Wiring" in [contracts/ui.md](contracts/ui.md): in `lib/main.dart` the splash is an overlay, so `TipsGate` is enabled by
the splash's `onFinished` (a `ValueNotifier<bool>` read by a `ValueListenableBuilder` that builds
`TipsGate(enabled: gone, child: ReaderScreen())` as the `home:` of the `MushafApp` returned by `_bootApp`). Do not change the
default `home` inside `lib/app.dart`: many existing tests pump `MushafApp` without a `home` and must not get a popup.

## 4. Removing or changing a step

Every step has one `TipStep` in `lib/onboarding/tip_steps.dart` and two strings in `tips_strings.dart`; the strings are
pinned by `tips_strings_test.dart` (changing one needs the owner's confirmation again) and the claim of each step is
pinned by `tips_reader_truth_test.dart`. If a control a step names is renamed or removed, that test fails: change the
sentence, the picture and the test together.
