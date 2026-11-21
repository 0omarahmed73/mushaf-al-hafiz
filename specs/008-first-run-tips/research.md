# Research: First-Run Tips

All decisions are the author's proposals recorded for the owner to overrule (spec "Clarifications"). Facts about the app
were read in the code on 2026-11-21 (`lib/mushaf/reader_screen.dart`, `lib/ayah/ui/*`, `lib/wirds/*`,
`lib/settings/*`, `lib/backup/backup_service.dart`, `lib/theme.dart`, `lib/app.dart`, `lib/main.dart`).

## D1 — A Material dialog over the reader, not a route, an overlay or a sheet

**Decision**: `showDialog` with a `Dialog`, `barrierDismissible: false`, content forced right-to-left.

**Rationale**: the owner asked for "a popup". A dialog is a route above the reader, so the reader keeps its state and
Constitution II holds; the system back closes it for free; the dialog's semantics (`namesRoute`, `scopesRoute`) and
the theme capture come with it; the app already styles dialogs for Night Reader (`dialogTheme`). A full-screen route
would hide the Mushaf the tips are about; an `OverlayEntry` would need its own back handling and focus scope; a bottom
sheet is what the ayah menu and the bookmarks use, and a sheet's swipe-down would fight the sideways swipe.

**Alternatives considered**: a bottom sheet (rejected, above); a coach-mark overlay that points at the real controls
(rejected: it would need the positions of widgets inside `reader_screen.dart`, which this feature may not edit, and it
breaks on every layout change).

## D2 — The flag is read once, with a one-shot read; no stream

**Decision**: `TipsStore.seen()` does one `readSetting('tipsSeen')`; the gate asks once, in a post-frame callback, and
never subscribes to anything.

**Rationale**: the lesson of features 005 and 006: earlier tests write the database inside `tester.runAsync` while
widgets are mounted, and a drift `watch*` stream listened to in the fake-async zone makes them hang. A first-run flag
changes at most once, by this very component, so a live view has no value.

## D3 — The stored value and what counts as "seen"

**Decision**: key `tipsSeen`, value `'true'`. Only exactly `'true'` means seen; a missing row, `'false'`, `''` or
anything else means not seen. A failed read means "do nothing" (no popup); a failed write is swallowed (printed in debug).

**Rationale**: the same convention as the other flags in `wird_repository.dart` (`== 'true'`); failing toward "no popup"
keeps the reader usable (Constitution II and VII), while the cost of showing the tips once more after a failed write is
trivial.

## D4 — When the flag is written: only when the reader chose to leave

**Decision**: the dialog pops with a result (`TipsOutcome.finished` from «ابدأ», `TipsOutcome.skipped` from «تخطي» or
back). `showTips` writes the flag when the result is not null. A close without a result (the reader's notification-tap
handler calls `popUntil(route.isFirst)`, a test's teardown, the app being killed) writes nothing.

**Rationale**: spec FR-006. Back is intercepted with `PopScope(canPop: false)` so that it pops with `skipped` rather
than with null; `Navigator.pop` and `popUntil` ignore `PopScope`, so a programmatic close still has no result.

**Alternative considered**: write the flag when the dialog opens. Rejected: a person who is interrupted on the first
second (a phone call, a notification) would never see the tips.

## D5 — Backup: the flag travels, and a restore never makes the phone forget it

**Decision**: nothing to add for the export: `BackupService.exportJson` already writes every row of `settings`, so
`tipsSeen` is in the file, and `importJson` already restores every setting, so a backup made on a phone that has seen
the tips brings that fact to a new phone. An old file (no `tipsSeen`) already imports: the settings map is read
generically and a missing key is not an error. One additive rule is needed: `importJson` deletes the whole `settings`
table before inserting the file's, so importing an **old** file on a phone that has seen the tips would erase the flag and
show the tips again at the next launch. A constant `kKeptOnImport = {'tipsSeen'}` (settings that describe this phone, not
the user's data) is read before the delete and written back after the inserts when the file has no value for it, all in
the same transaction (a failed import rolls it back with everything else).

**Rationale**: the owner's wish that restoring on a new phone does not show the tips again. The edit is eight lines
in one file, additive, and `kKeptOnImport` is a set so a later "this phone only" setting needs no new rule. The literal
`'tipsSeen'` is repeated there on purpose (the backup does not import `lib/onboarding/`); a test pins that the set holds
`kTipsSeenKey`.

**Alternatives considered**: do nothing (a restore of an old file shows the tips once more: acceptable but needlessly
surprising); keep the flag out of the backup entirely by skipping it in the export (then restoring a new-format backup
on a new phone shows the tips, against the owner's wish); put the rule in the gate (the gate does not know about
imports).

## D6 — The six steps, trimmed and checked against the code

| # | Step | What the code does (checked) |
|---|---|---|
| 1 | Long press on an ayah | `_PageItem` passes `onWordLongPress` to `MushafPageCard`; `_openAyahMenu` highlights the ayah, then `showAyahSheet` shows rows `ayah-share` «مشاركة», `ayah-tafsir` «التفسير» (view titled «تفسير السعدي»), `ayah-translation` «الترجمة» («Saheeh International»), `ayah-meanings` «معاني الكلمات», `ayah-page-picture` «مشاركة الصفحة كصورة», `ayah-surah-pdf` «مشاركة السورة PDF». The press is on a **word**, so the tip says "any word of the ayah". |
| 2 | Turning and jumping | the pager is `reverse: true` in an LTR box: the next page comes in from the left (finger left to right); `open-index` is the `InkWell` over the surah-name row (index tabs «السور» «الأجزاء» «صفحة»); the page number is a button whose tap calls `_askPage` (dialog «الانتقال إلى صفحة»). |
| 3 | Hide the bars, zoom | each page is wrapped in a `GestureDetector(onTap: _toggleBars)`; `_toggleBars` flips the bars of the current orientation (both bars); `PageViewport` uses an `InteractiveViewer` with `minScale: 1, maxScale: 3`. |
| 4 | The daily wird | the pill `wird-pill` (the active wird's name, «تصفح» in browse mode) opens the wirds list; `today-chip` «ملخص اليوم» (done/total) opens `TodayCard` whose rows show «من ص A إلى ص B» and a «تم» button; the bottom item «أوراد» opens the wirds list, which has «ورد جديد». `ensureDefaults` creates «الورد اليومي» on the first launch, so the chip is there for a new reader. |
| 5 | Bookmarks | the bookmark icon (`bookmark-button`, feature 006) is in the top bar's second row at the left edge; it toggles a bookmark on the page; the bottom item «علامات» opens `BookmarksSheet` (list, add with a note, delete). |
| 6 | Size and look | the bottom `IconButton` with tooltip «القائمة» (`open-settings`) opens `SettingsScreen`, which holds `TextSizeTile` («حجم الخط», 80 to 150 percent) and `LookTile` («المظهر»: «زمردي وذهبي», «القارئ الليلي»). |

**Last verified** on 2026-11-21 by `test/onboarding/tips_reader_truth_test.dart` (commit a7ea839): all six steps were
done on the real reader and every name the texts quote («ملخص اليوم», «تم», «أوراد», «علامات», «القائمة», «زمردي وذهبي»,
«القارئ الليلي») was found; no sentence needed a change.

**Left out on purpose**: the khatm dua (the reader meets it by itself, and it is a surprise that does not need
teaching, Constitution III), «استماع» and «اختبار» (disabled, «قريباً»), reminders (Settings explains itself), backup
(a rare action), the surah PDF details (named in step 1).

## D7 — The slider: a `PageView` in right-to-left

**Decision**: a plain `PageView` with `reverse: false` under `Directionality(rtl)`. In right-to-left the first page is on the
right and the next one comes in from the left, so a finger moving from left to right moves forward: the paper-Mushaf
direction (Constitution VI) without any flag. The pager does not wrap: beyond the last step the swipe does nothing.
«التالي» uses `animateToPage` (250 ms, ease-out-cubic) and, while that runs, ignores a second tap (so two quick taps never
skip the last step); under reduced motion it uses `jumpToPage`.

## D8 — Layout that survives a 2x font on a 320 dp phone

**Decision**: the card height is `min(available height, 520)`, inside it a `Column`: `Expanded` the `PageView` whose every
page is its own `SingleChildScrollView` (the drawing, the title, the text), then a pinned footer (the dots and the buttons).
The buttons are a `Wrap` (they go on two lines instead of overflowing) with a minimum height of 48. The drawings sit in a
`FittedBox(fit: BoxFit.scaleDown)` on a fixed design size, so they shrink on a narrow screen and never overflow.

**Rationale**: the text is the only thing that grows with the system font; letting it scroll while the controls stay in
view is the rule that already holds for the khatm dua («آمين» is the last item of its scrolling content: here it is the
opposite on purpose, because the buttons are how one leaves). A `PageView` cannot size itself to its content, hence the
fixed card height.

**Alternative considered**: the buttons inside the scrolling content. Rejected: at 2x the reader would have to scroll to
find «تخطي».

## D9 — Colours: the bottom bar's surface

**Decision**: the card is `look.barFill` with a `look.barBorder` hairline and the look's `cardRadius`; text is `look.text`,
the sentence `look.text`, the dots `look.accent` (current) and `look.textSecondary` (the others), the titles `headingStyle(20, look.heading)`, the primary button
`primaryFill`/`onPrimary` (the theme's `FilledButton`), «تخطي» `look.accent`, the drawings' panel `look.background` with a
`look.line` hairline.

**Rationale**: the app's required pairs (`AppLook.requiredPairs`) already prove `text/barFill`, `accent/barFill` and
`onPrimary/primaryFill` at 4.5:1 in both looks, and `heading`, `textSecondary` and `controlBorder` are far above 3:1 on it;
the card therefore needs no new colour. One correction made by `tips_look_size_test.dart` (T014, T015): the filled bookmark of
step 5 was drawn in `accentAlt`, 2.67:1 on the ivory page in Emerald & Gold; it is `cardInk` now (the outlined and the
filled icon differ by shape, not by colour), and every icon drawn on a page uses `cardInk`. (Emerald & Gold's default dialog would be the theme's dark surface, Night's is
`cardFill`: using `barFill` for both keeps the tokens one set).

## D10 — The drawings: shapes and icons, text-free, on a fixed design size

**Decision**: each `TipPicture` is built from `Container`s (bars for lines of text, rounded rectangles for pages, pills) and
`Icon`s from the app's icon font (`touch_app`, `east`, `pinch`, `menu_book`, `translate`, `share`, `bookmark_border`,
`bookmark`, `check_circle_outline`, `expand_more`, `menu`, `format_size`, `dark_mode`), on a 240 x 112 design box. The
pictures hold no Arabic, no Latin text and no Quran word, are excluded from the semantics, and only the long-press one
animates: a ring that grows and fades, 1.4 s, repeating, started only while its step is current and the phone has not
asked for reduced motion.

**Rationale**: spec FR-003 and FR-013: no asset, no package, no text to translate or to contrast-check.

## D11 — A second `showTips` while one is open does nothing

**Decision**: an `Expando<bool>` keyed by the root `NavigatorState` marks "a tips dialog is open on this navigator"; set
before the push, cleared in a `finally`.

**Rationale**: the gate can be re-created (the app rebuilt) while the first dialog is open, and a Settings row could be
tapped twice. A static flag would survive a test's teardown (the unmounted navigator never completes the dialog's
future); a per-navigator mark does not.

## D12 — `TipsGate({required child, bool enabled = true})`

**Decision**: `enabled` is an addition to the requested signature. While `false` the gate only shows `child`; when it turns
`true` the check runs once.

**Rationale**: the splash (feature 009) is built elsewhere. Checked in `lib/splash/splash_gate.dart` on 2026-11-21: it is an
**overlay**, a `Stack` above the whole `MaterialApp` whose child is built from the first frame, and its `onFinished` is
called once, after the splash is gone. So the gate is created while the splash is still on screen and must wait: without
`enabled` the dialog would open (and play its opening) under the splash, and a person who finishes loading at the same
moment would see it appear on the splash's last frame. The wiring therefore passes `enabled` from a notifier that the
splash's `onFinished` sets (contracts/ui.md "Wiring"). Costs six lines and one test.

## D13 — Tests prove the tips are true: they do what each step says on the real reader

**Decision**: `tips_reader_truth_test.dart` pumps the gate over the real `ReaderScreen` (the harness of the reader tests'
style: a real page, the ayah repository and a fake share) and, for each step, performs what the step says and checks the
control it names: the six ayah rows, `open-index`, the go-to-page dialog, the bars, `wird-pill`, `today-chip` and «تم»,
`bookmark-button` and «علامات», `open-settings` with «حجم الخط» and «المظهر». If someone removes or renames one of them the
test fails and the sentence must be revisited.

**Rationale**: the owner's rule ("do not describe anything that does not exist") made executable.

## D14 — Test technique

- The gate and the dialog are pumped in `MushafApp` (its theme, locale, providers), so the wiring is the app's own; the
  dialog alone is also pumped in a bare `MaterialApp` with `buildAppTheme(look:)`.
- Drift and the post-frame check run outside the fake clock: tests call the harness's `settleTips` (a few
  `runAsync(delay)` + `pump` rounds) and never `pumpAndSettle` while the pulse animation runs.
- The restart test uses a temporary file database opened twice (the first closed before the second opens), so the flag
  really goes through SQLite.
- Reduced motion: `MediaQuery(disableAnimations: true)` around the app; "no animation" is `binding.transientCallbackCount == 0`
  after the step has settled.
- Contrast: `contrastIssues(t, within: find.byType(TipsDialog))`; targets: `t.getSize` of the buttons.
