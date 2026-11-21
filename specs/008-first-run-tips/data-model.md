# Data Model: First-Run Tips

No table, column or migration is added. The feature has one stored fact, one fixed list, and a little state while the
dialog is open.

## The flag: `tipsSeen`

| | |
|---|---|
| Where | the existing `settings` table (`key`, `value`), through `WirdRepository.readSetting` / `writeSetting` |
| Key | `tipsSeen` (`kTipsSeenKey`) |
| Value | `'true'` when the tips were finished or skipped; the row is absent otherwise |
| Meaning of any other value | not seen (`'false'`, `''`, junk) |
| Written by | `showTips`, when the dialog closes with a result (`finished` or `skipped`); nothing else |
| Read by | `TipsGate`, once, after the first frame (a single query, no stream) |

State transitions: absent → `'true'` (finish, skip or back); `'true'` stays `'true'` (a re-run through `showTips` writes
the same value again). There is no transition back to absent inside the app.

### In the backup

- `BackupService.exportJson` writes every `settings` row, so a phone that has seen the tips writes
  `"settings": {..., "tipsSeen": "true"}`. No change.
- `BackupService.importJson` replaces the settings with the file's. The file's `tipsSeen` (`"true"`) is therefore restored
  on a new phone: the tips do not show again. No change.
- A file written before this feature has no `tipsSeen`; it still parses (the settings map is read generically).
- New rule: `kKeptOnImport = {'tipsSeen'}`. Before the delete, `importJson` reads this phone's value for each key in the set
  that has one; after the file's settings are inserted, it writes back the phone's value for each key the file did not
  carry. All inside the existing transaction. A file that carries the key wins (it can only say `"true"`).

| This phone | File | After the import |
|---|---|---|
| seen (`'true'`) | has `tipsSeen: 'true'` | `'true'` |
| seen | no `tipsSeen` (old file) | `'true'` (kept) |
| not seen | has `tipsSeen: 'true'` | `'true'` |
| not seen | no `tipsSeen` | absent: the tips show at the next launch |
| any | import fails halfway | unchanged (the transaction rolls back) |

## The steps (fixed, not stored)

`TipStep`:

| Field | Type | Rule |
|---|---|---|
| `picture` | `TipPicture` | one of `longPress`, `turnPages`, `barsAndZoom`, `wird`, `bookmarks`, `sizeAndLook`; all different |
| `title` | `String` | from `tips_strings.dart`, one line at 1x, no digits, not empty |
| `body` | `String` | from `tips_strings.dart`, at most two sentences (two full stops), no Quran text |

`kTipSteps` is a `const` list of exactly six, in the order of the spec. The words of the Quran never appear in a step.

## Dialog state (in memory only)

| Field | Meaning |
|---|---|
| `index` | the step shown, 0 to 5; changes with a swipe or «التالي»; never leaves 0..5 |
| `animating` | true while «التالي» slides; a second «التالي» is ignored meanwhile |
| `reduceMotion` | `MediaQuery.disableAnimationsOf(context)`; read each build |
| the result | `TipsOutcome.finished` (the last step's «ابدأ») or `TipsOutcome.skipped` («تخطي», back); null for any other close |

The "a dialog is open" mark (`Expando<bool>` on the root navigator) lives only as long as the navigator.
