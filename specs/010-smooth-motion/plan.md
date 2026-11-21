# Implementation Plan: Smooth Motion

**Branch**: `010-smooth-motion` (work stays on `main`) | **Date**: 2026-11-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/010-smooth-motion/spec.md`

## Summary

The owner sees a hitch when turning pages. Reading the code and measuring on the development machine (research D1, D8) shows
three things the reader does in the middle of a slide: it builds the incoming page (about 900 elements, about 130 paragraphs
in a never-used font) when the finger first moves; it rebuilds both visible pages again when the pager passes half way (the
whole screen is one `ListenableBuilder`), and in wird mode it rebuilds them a third time when the database answers the two
position writes. The plan fixes those in **Stage A**: the pager prepares both neighbours at rest (`allowImplicitScrolling`
with a 1 px cache, research D2), a page keeps its widget unless its own inputs change and the screen's listeners are
narrowed (D3), and loading moves to the background after the slide (D4). **Stage B** is the phone gate: measure 50 swipes
before and after with the app's own frame trace (D9) and decide what else is needed. **Stage C** (position saving
delayed, a stiffer spring, a thinner page, the font memory) is built only for what the phone still shows. The soft motion of
the owner's request (bars, today card, jumps, bookmark icon, wird name, look switch) is added in small implicit-animation
widgets under `lib/motion/` with one token file, all shortened to one frame by the phone's «remove animations» setting
(D6, D7, contracts/ui.md). No Mushaf page, line, font or text code changes; no new package; no new string.

## Technical Context

**Language/Version**: Dart 3.14 / Flutter 3.50 (Android first)

**Primary Dependencies**: `package:material_ui`, `provider`, `drift` (already used); nothing new, not even a dev package

**Storage**: none new (no table, no setting, nothing in the backup); the reading position is written as today (Stage C may
delay it by at most 0.4 s, D5)

**Testing**: `flutter test` with new files only (`test/motion/`); helpers in `test/support/motion_probe.dart` and
`motion_harness.dart` (new files; `reader_harness.dart` stays as it is); the earlier features' tests unchanged; the phone
check with `specs/010-smooth-motion/phone/measure.sh` on the owner's phone only with approval

**Target Platform**: Android phone, portrait and landscape, RTL; the owner's phone <phone> (1080 x 2340)

**Project Type**: mobile app

**Performance Goals**: SC-001 (95% of frames within the refresh-rate budget over 50 swipes, none over 100 ms, p99 at most 2x
the budget), SC-002 (neighbours ready in 98% of normal-pace swipes; text within 300 ms always), SC-003 (rebuild budget per
turn), SC-004 (bars and card never over 33 ms)

**Constraints**: offline, no tracking; Quran text, 15-line layout and page geometry untouched; earlier tests unchanged;
nothing overflows at 320 dp with a 2x system font (known: the bottom bar at 320 dp, feature 006 T020); targets >= 48 dp;
contrast as the earlier features; «remove animations» honoured; the tree is shared with other sessions (explicit `git add`,
one commit per task)

**Scale/Scope**: 4 small new widgets, one frame-trace file and one token file in `lib/motion/`, 3 additive methods in the repository, loader and
controller, and edits in `reader_screen.dart` in three windows (R1, R2, R3), `bookmark_button.dart`, `app.dart`, `main.dart`

## Constitution Check

*GATE: passed before research and again after the design (constitution 1.2.0).*

| Principle | Check |
|---|---|
| I Quran text integrity | No page data, font, card, line or word code changes in Stages A and B; motion never moves or resizes the page (bars keep their 84 and 68 dp slots, FR-008, SC-004); the geometry baselines of 003, 004 and 006 and the 604-page layout tests must be equal before and after (FR-016, SC-006). The only change that would touch `mushaf_page.dart` (D12) is conditional and needs those baselines green. **Pass** |
| II Mushaf first | No new screen, no new route; the reader is still the first and only home; the look cross-fade is an overlay on the same screen. **Pass** |
| III Focus | Nothing but motion and speed. **Pass** |
| IV Offline, private | No network, no analytics; FRAME_TRACE and PAGE_TURN_TRACE print to the local log only, in builds made with an explicit option, and cost nothing otherwise (FR-018). **Pass** |
| V Licensing | No external resource, no font, no package. **Pass** |
| VI Arabic, RTL | No visible string added (FR-017); page turning direction unchanged (the next page from the left); the bars slide in the vertical axis, so RTL does not mirror them; the wird-name swap is fade only. **Pass** |
| VII Reliability | Stage A does not change when the position is written. Stage C, if built, writes within 0.4 s and flushes on pause, on route push, on dispose and on a jump (D5, FR-007, SC-007). **Pass (Stage C conditional, with its own test)** |
| VIII App size | No asset, no code of size; three pages alive at rest instead of one (D2 risk) and font memory watched (H4). **Pass** |
| IX Quality gates | Test-first (the rebuild budget tests are written red against today's code, T010), pure logic separated (`Motion` tokens, `FrameSummary`, `PositionSaver`), analyze clean, whole suite once at the end, real-device check with numbers (T050, T073). **Pass** |

No deviation, so no Complexity Tracking entry. Coordination, not deviation: `reader_screen.dart` is also edited by features 005,
006, 007 and 008/009 sessions; the tasks that touch it are marked `[R1]`, `[R2]`, `[R3]` and are scheduled in three windows
(research D13).

## Project Structure

### Documentation (this feature)

```text
specs/010-smooth-motion/
├── spec.md
├── plan.md
├── research.md            # hypotheses H1-H8, measurements, decisions D1-D13
├── data-model.md          # no stored data; the in-memory state and tokens
├── quickstart.md          # automated checks and the phone procedure
├── contracts/
│   ├── ui.md              # durations, curves, which widgets move, the reduce-motion rule, the phone numbers
│   └── dart-interfaces.md # Motion, FadeSlideSwitcher, JumpFade, LookFade, FrameTrace, PositionSaver, additions
├── checklists/
│   ├── requirements.md    # spec quality (specify step)
│   └── motion.md          # requirements-quality checklist (checklist step)
├── phone/
│   ├── measure.sh         # adb swipes + collection; refuses to run without the owner's approval
│   └── summarise.py       # percentiles and PASS/FAIL from the frame trace or gfxinfo
└── tasks.md
```

### Source code (repository root)

```text
lib/
├── motion/                     # NEW
│   ├── motion.dart             # tokens (durations, curves, offsets) and the reduce-motion rule
│   ├── fade_slide_switcher.dart# AnimatedSwitcher with fade + slide, outgoing child ignores taps
│   ├── fade_in_on_change.dart  # the new icon / name fades in, one child at a time (bookmark icon, wird name)
│   ├── jump_fade.dart          # soft arrival of a page after a jump
│   ├── look_fade.dart          # snapshot cross-fade over the app when the look changes (last task)
│   └── frame_trace.dart        # FRAME_TRACE: FrameTiming lines in the log (compile-time flag)
├── mushaf/
│   ├── reader_screen.dart      # EDITED in three windows R1, R2, R3 (tasks.md)
│   ├── reader_controller.dart  # + pageSeen(), savePosition()  (onPageShown keeps doing both)
│   ├── mushaf_repository.dart  # + peek(), prefetch(); one read per page
│   ├── page_font_loader.dart   # prefetch order and timing
│   ├── bookmark_button.dart    # icon swap motion
│   └── position_saver.dart     # NEW, Stage C only
├── app.dart                    # look cross-fade host (last task of US3)
├── look/look_settings.dart     # asks the host for a snapshot before the switch (last task)
└── main.dart                   # FrameTrace.install() before runApp

test/
├── motion/                     # already: measurements M1-M5 and spike S1 (this research); NEW tests per tasks.md
└── support/motion_probe.dart, motion_harness.dart   # already written; later tasks add helpers in new files
```

**Structure Decision**: keep the reader's widgets where they are; put everything new about motion in one folder with one
token file so a duration or a curve is changed in one place; the only reader-level changes are the ones that stop rebuilds
and hand the bars, the card and the pager to the new widgets.

## Stages

| Stage | What | Gate to the next |
|---|---|---|
| **0 Baseline** | T002 adds the traces, T003 is the owner-approved «before» run on the phone. If he declines, the test numbers of D8 are the only before-numbers | none (optional) |
| **A Fix the known causes** | Foundations T005 (repository: peek, prefetch, one read), T006 (fonts: order), T007 (controller: pageSeen); window R1: T010 page cache and the red budget tests, T011 narrow listeners, T012 neighbours at rest, T013 loading after the slide and the `PAGEWARM` trace; T014 tighten the bounds, T015 earlier suites, T016 phone gate A | the budget tests are green and the earlier tests unchanged; phone gate A (T016) when the owner is there |
| **Motion** | US2 bars and card (T020-T022), US3 jumps, icon, wird name, look (T030-T035), US4 edge turn and sweep (T040, T041); window R2 | each motion test green; geometry rectangles equal in every frame |
| **B Phone gate** | T050 «after» run, compare with «before», decide Stage C | SC-001 and SC-002 met, or the list of what Stage C must fix |
| **C Only what B shows** | T060 delayed position saving (H3, window R3), T061 stiffer spring (H8), T062 font memory (H4), T063 thinner page (H6, D12) | the numbers of B again |

## Complexity Tracking

| Addition | Why | Simpler alternative rejected |
|---|---|---|
| Three pages alive at rest (`allowImplicitScrolling`) | The only way to have the incoming page laid out before the finger moves (D2, spike S1) | Preparing only data and fonts leaves the 900-element build inside the slide (H2) |
| A snapshot cross-fade for the look (T035) | `AppLook.lerp` is a hard switch by feature 004's rule; interpolating the theme shows neither look | Leaving the look switch instant (a one-line decision for the owner, question 3) |
| `PositionSaver` (Stage C) | Fewer writes and fewer database answers per turn | Not built unless the phone shows H3 is real (D5) |
