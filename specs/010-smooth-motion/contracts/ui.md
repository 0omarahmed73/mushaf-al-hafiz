# UI Contract: Smooth Motion (feature 010)

No visible text is added. All values are the proposal of the plan; the owner may change a number without changing the rest.

## Tokens

| Token | Value |
|---|---|
| Duration, bars in / out | 200 ms / 160 ms |
| Duration, today card in / out | 220 ms / 160 ms |
| Duration, jump arrival | 180 ms |
| Duration, icon and wird-name swap | 160 ms |
| Duration, look cross-fade | 220 ms |
| Duration, edge turn (unchanged) | 300 ms |
| Curve in (appearing) | `easeOutCubic` |
| Curve out (leaving) | `easeInCubic` |
| Slide distance, bars / card | 24 dp / 12 dp |
| Ceiling | no motion longer than 300 ms, no bounce, no spring, no scale below 0.9 (icon) or 0.96 (anything else), nothing that loops |

## Which widget moves how

| Widget | Motion | Layout rule | Reduced |
|---|---|---|---|
| Top bar (84 dp slot) | fade + slides up 24 dp when it leaves, down from -24 dp when it comes | The slot keeps its 84 dp; the page area never changes size or place | removed or present in the next frame |
| Bottom bar (68 dp slot) | fade + slides down 24 dp when it leaves, up from +24 dp when it comes | The slot keeps its 68 dp; the surah PDF strip above it moves with an `AnimatedPositioned` of the same duration, so it does not jump while the bar slides | same |
| «ملخص اليوم» card | fade + slides down from -12 dp when it opens, fade + -12 dp when it closes | Card position unchanged (`top: 84 + 6`); its modal barrier exists exactly while the panel is open and does not animate | same |
| Page after a jump | fades in from 0.35 to 1.0 over the page area (no slide, no pages between) | Page box unchanged; the top line shows the new surah at once | the new page in the next frame |
| Bookmark icon (48 x 48) | the new icon (outline or filled) is shown at once and grows from 0.8 to 1.0 while its colour fades from the old one, 160 ms; **one icon at any time** (the feature 006 tests look for exactly one) | The 48 x 48 target, tooltip and the one merged semantics node stay as feature 006 set them (the node sits outside the motion) | the new icon in one frame |
| Wird name in the pill | the new name fades in from 0 over 160 ms; **one text at any time** | The pill's width and ellipsis stay | the new name in one frame |
| Whole app on a look change | the old look's snapshot fades out over the new look | Theme changes at once under the snapshot; no interpolation of the theme | no snapshot, instant switch |
| Edge turn of a wide page | `animateToPage`, 300 ms `easeOutCubic` (as today) | none | `jumpToPage` |
| Pager drag and spring | the framework's (follows the finger; settles on a page) | none | unchanged: it is the reader's own movement |
| Sheets, dialogs, routes, snack bars | the framework's own | none | the framework's own (1 frame, measured) |

## Rules

1. **Reduce motion**: a motion starts by reading `MediaQuery.disableAnimationsOf(context)`; when true its duration is
   `Duration.zero` and it ends in the same frame. A custom `AnimationController` is created with `Duration.zero` in that case
   (the framework's own 5% shortening is not relied on). A change of the setting applies to the next motion.
2. **End state**: every motion ends in the state it would have had without it; a motion interrupted by another reverses from
   where it is and never leaves a widget half transparent.
3. **Input**: a bar or card that is leaving ignores taps (`IgnorePointer`), is excluded from semantics and focus once its
   state is hidden, and is removed from the tree when its fade ends (the existing test pumps 300 ms and expects it gone).
4. **Geometry**: the Mushaf page's line and word rectangles are equal in every frame of every motion (SC-004). Slots are
   fixed; only paint and transform change.
5. **Pages**: a motion never rebuilds a page. Bars, card, icon and name are separate subtrees; the pager is not their
   ancestor's child list.
6. **No new text, colour, icon or sound.** Motion uses the look's colours as they are.

## Measured and accepted on the phone (research D9)

| Number | Target |
|---|---|
| Frames within the refresh-rate budget during 50 swipes | >= 95% |
| Longest frame during 50 swipes | < 100 ms |
| p99 frame | <= 2 x the budget |
| `PAGETURN` | <= 300 ms in 100% of turns |
| `PAGEWARM ready=true` at the start of a swipe, normal pace | >= 98% |
| Frame during a bar or card animation | none over 33 ms |
