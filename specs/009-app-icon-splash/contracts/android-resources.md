# Contract: Android resources of feature 009

Everything is under `android/app/src/main/res/`. `AndroidManifest.xml` is not edited (`android:icon="@mipmap/ic_launcher"`
and `android:label="مصحف الحافظ"` already do the right thing). `android/app/build.gradle.kts` is owned by another session
and is not touched. Checked by `test/splash/android_resources_test.dart` unless said otherwise.

| File | Kind | Required content |
|---|---|---|
| `drawable/ic_launcher_background.xml` | generated vector, 108 dp, viewport 108 | full-canvas rectangle with the vertical gradient #1A212A → #0D1014 and a second with the radial teal glow (30% alpha → 0, radius 48 at (54, 30)) |
| `drawable/ic_launcher_foreground.xml` | generated vector | one group with the adaptive placement (pivot 54, 54.55, scale 0.85, translateY −0.55) holding the star, the hole, the two pages, the spine, the page lines and the gold line; every `pathData` equals a constant of `AppIconGeometry` |
| `drawable/ic_launcher_monochrome.xml` | generated vector | the same placement; the silhouette in one colour (#FFFFFF), the star as one even-odd outline with its hole, the two pages, the gold line |
| `mipmap-anydpi-v26/ic_launcher.xml` | `<adaptive-icon>` | `<background android:drawable="@drawable/ic_launcher_background"/>`, `<foreground …/ic_launcher_foreground"/>`, `<monochrome …/ic_launcher_monochrome"/>`; each drawable exists |
| `mipmap-mdpi/ic_launcher.png` | PNG 48 × 48 | the legacy icon: rounded square (corners transparent), dark background, ivory pages, teal star, gold line |
| `mipmap-hdpi/ic_launcher.png` | PNG 72 × 72 | same |
| `mipmap-xhdpi/ic_launcher.png` | PNG 96 × 96 | same |
| `mipmap-xxhdpi/ic_launcher.png` | PNG 144 × 144 | same |
| `mipmap-xxxhdpi/ic_launcher.png` | PNG 192 × 192 | same |
| `values/colors.xml` | colours | `splash_background` = #0D1014 |
| `drawable/launch_background.xml`, `drawable-v21/launch_background.xml` | `layer-list` | an item with `@color/splash_background` and an item with `@drawable/ic_launcher_foreground`, `gravity="center"`, width and height 140 dp; no white, no `?android:colorBackground` |
| `values/styles.xml`, `values-night/styles.xml` | styles | `LaunchTheme` with a `Theme.Black.NoTitleBar` parent and `windowBackground` = `@drawable/launch_background`; `NormalTheme` with `windowBackground` = `@color/splash_background`; both files define the same two names |
| `values-v31/styles.xml`, `values-night-v31/styles.xml` | styles | `LaunchTheme` with `windowSplashScreenBackground` = `@color/splash_background`, `windowSplashScreenAnimatedIcon` = `@drawable/ic_launcher_foreground`, `windowSplashScreenAnimationDuration`, the dark parent and `windowBackground`; `NormalTheme` as above; the two files are identical |

## Invariants the resource test checks

1. Every file above exists and every XML is well formed (balanced tags, quoted attributes, one root).
2. Every `@drawable/…`, `@color/…` and `@mipmap/…` reference inside these files resolves to a file or colour that exists.
3. The adaptive icon names background, foreground and monochrome; all three exist.
4. Each PNG has the PNG signature and the exact size of its density; its corner pixel is transparent and its centre area holds
   ivory, its top area holds teal and its lower area holds gold (so the Flutter default icon fails the test).
5. No resource of the launch screen contains `white` or `colorBackground` (no white flash), in the day and the night sets.
6. The three vector files equal what `AppIconResources` computes from the geometry now (so the XML cannot drift from the
   painter); the foreground's farthest point is at most 33 from the centre.
7. The manifest label equals `kSplashName`.

## Checked on the machine but not by a test

`aapt2 compile` + `aapt2 link` with `android.jar` of platform 36 accept the whole `res/` directory with a scratch manifest
(see the quickstart). This proves the XML is valid for the platform; the look is checked on the phone.
