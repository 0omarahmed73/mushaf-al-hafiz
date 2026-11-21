# Data Model: App Icon and Animated Splash Screen (feature 009)

The feature stores nothing: no table, no setting key, nothing in the backup. It has one drawing kept as data, a few
constants and one immutable value per animation frame. Nothing is read from the user's data.

## Icon geometry (`lib/splash/icon_geometry.dart`)

The drawing of `Icon2.dc.html` on a 108 × 108 canvas, as constants. Paths use only the absolute commands `M L C Z`.

| Part | Content | Fill / stroke |
|---|---|---|
| star, square | `M48 19 L60 19 L60 31 L48 31 Z` | fill #6CC4B5 |
| star, diamond | the same square turned 45° about (54, 25): `M54 16.5147 L62.4853 25 L54 33.4853 L45.5147 25 Z` | fill #6CC4B5 |
| star, hole | circle r = 2 at (54, 25) | fill #0D1014 |
| left page | `M54 74 C46 68 34 66 24 68 L24 40 C34 38 46 40 54 46 Z` | fill #ECE7DC |
| right page | `M54 74 C62 68 74 66 84 68 L84 40 C74 38 62 40 54 46 Z` | fill #D6D0C1 |
| spine | `M54 46 L54 74` | stroke #8A939C, width 0.8 |
| page lines, left and right | three curves each (see the file) | stroke #8A939C, width 1, round caps |
| gold line | `M22 73 C34 71 46 73 54 79 C62 73 74 71 86 73` | stroke #E3B05A, width 2.2, round caps |
| background | vertical gradient #1A212A (y 0) to #0D1014 (y 108), plus a radial glow #6CC4B5 at 30% alpha fading to 0 at radius 48 around (54, 30) | |

Two placements of the same art on the canvas (a placement is `scale` about a `pivot`, then a `shift`):

| Placement | Scale | Pivot | Shift | Used by | Rule |
|---|---|---|---|---|---|
| legacy | 0.9 | (54, 54) | (0, +2) | splash tile, five PNGs | the design's own `translate(54 56) scale(.9) translate(-54 -54)` |
| adaptive | 0.85 | (54, 54.55) | (0, −0.55) | foreground and monochrome vectors | the farthest point of the art, strokes included, is 32.33 from the canvas centre (54, 54): inside the 33 of the 66 dp safe circle (research D5) |

The monochrome layer uses the adaptive placement and a single-colour silhouette: the star as one eight-point outline
(outer radius 8.4853, inner radius 6.4944, centre (54, 25), even-odd fill) with its hole, the two pages with a 1.2-unit gap at
the spine (the paths of `monochromePageLeft` and `monochromePageRight`), and the gold line at stroke width 2.6.

`AppIconGeometry.parsePath(String d)` turns one of the strings above into a `ui.Path`; it understands `M L C Z`, absolute,
numbers separated by spaces or commas, and throws `FormatException` on anything else.

## SplashPlan (`lib/splash/splash_plan.dart`, pure)

| Constant | Value | Meaning |
|---|---|---|
| `fullDuration` | 1400 ms | the whole choreography |
| `minimum` | 900 ms | the least time the splash stays with full motion |
| `reducedStay` | 300 ms | the least time with reduced motion |
| `fade` | 220 ms | the exit fade (none with reduced motion) |

`SplashPlan.mayLeave({elapsed, ready, skipped, reducedMotion})` is `ready && (skipped || elapsed >= minimum)` where
`minimum` is `reducedStay` when `reducedMotion`. A tap sets `skipped`; it never overrides `ready`.

## SplashFrame (`lib/splash/splash_timeline.dart`, pure, immutable)

| Field | Range | Meaning |
|---|---|---|
| `backdrop` | 0..1 | strength of the radial glow over the flat #0D1014 |
| `stars` | 0..1 | opacity of the tiny stars |
| `tileOpacity`, `tileScale` | 0..1, 0.92..1 | the icon tile |
| `twinkle` | 0..1 | the pulse of the star: 0 at rest, 1 at the peak; a single sine arch |
| `nameOpacity`, `nameRise` | 0..1, 14..0 px | the name |
| `lineOpacity`, `lineRise` | 0..1, 10..0 px | the tagline |
| `progress` | 0..1 | the fill of the thin line |

`SplashTimeline.at(elapsed)` is defined for every non-negative duration; `SplashTimeline.finalFrame` is `at(fullDuration)` and is
what reduced motion paints. Beats are in research D3.

## State of the overlay (in memory, per launch)

| State | Values | Transitions |
|---|---|---|
| phase | `playing` → `leaving` → `gone` | `playing → leaving` when `mayLeave` first holds (with reduced motion `playing → gone` at once); `leaving → gone` when the 220 ms fade ends |
| `skipped` | false → true | on the first tap |
| `ready` | false → true | when the app's loading completes (or fails) |
| `finished` | false → true | exactly once, at `gone`, after the overlay is removed |

Nothing is persisted: the next launch starts again at `playing`.

## Android resources

Described in [contracts/android-resources.md](contracts/android-resources.md): three generated vectors, one adaptive
icon, five PNGs, one colour, the launch drawables and the four style files.
