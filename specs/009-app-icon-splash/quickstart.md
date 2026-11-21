# Quickstart: validating feature 009 (app icon and splash)

## Automated

```bash
flutter analyze lib/splash lib/main.dart tool test/splash
flutter test test/splash
```

The new tests are in `test/splash/`: `splash_plan_test.dart` and `splash_timeline_test.dart` (pure rules),
`icon_geometry_test.dart`, `splash_screen_test.dart`, `splash_reduce_motion_test.dart`, `splash_layout_test.dart`,
`splash_gate_test.dart`, `splash_timing_test.dart`, `splash_finished_test.dart`, `splash_wiring_test.dart`,
`app_when_ready_test.dart`, `splash_strings_test.dart`, `android_icon_resources_test.dart` and
`android_launch_resources_test.dart` (the Android files exist, are well formed, refer to existing layers; the five PNG sizes
and palette; the vectors equal what the tool writes). The earlier tests pump `MushafApp(home: ...)` and never see the splash;
this session ran only `test/splash`, `test/app_test.dart` and `test/look`, so the coordinator runs `flutter test` once at the
end to check the whole suite.

If `android_resources_test.dart` says a vector or PNG is out of date, regenerate:

```bash
flutter test tool/make_app_icons.dart     # writes the 5 PNGs and the 3 vector layers under android/app/src/main/res/
```

## Resource check without building the app (optional, needs the Android SDK)

```bash
S=$(mktemp -d); A=~/Android/Sdk/build-tools/36.0.0/aapt2
printf '<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="app.hafiz.mushaf"><application android:icon="@mipmap/ic_launcher" android:label="x" android:theme="@style/LaunchTheme"/></manifest>' > $S/AndroidManifest.xml
mkdir $S/flat && $A compile --dir android/app/src/main/res -o $S/flat
$A link -I ~/Android/Sdk/platforms/android-36/android.jar --manifest $S/AndroidManifest.xml --min-sdk-version 24 \
  --target-sdk-version 36 -o $S/res.ap_ $S/flat/*.flat && echo resources OK
```

It checks every XML and reference against the platform; it writes only to the temporary folder.

## On the phone (owner's device; the coordinator builds and installs the release APK; never unlock the phone, ask before sending any input)

1. Home screen and app list: the icon shows the teal star above the open Mushaf with the gold line, on the dark background,
   not the Flutter bird. Long-press it: the app shortcut shows the same icon. Try a round, a squircle and a square mask if the
   launcher offers them (nothing cut off, SC-006).
2. Turn on themed icons (Settings → Wallpaper and style, Android 13+): the icon becomes a one-colour silhouette that is still
   recognisable.
3. Cold start in day mode, then in night mode (swipe the app away first): no white or light frame at any moment between the tap
   and the Mushaf (SC-001). Screen-record and step through the frames if in doubt.
4. The splash: tile eases in, the star twinkles once, name and line fade up, the thin line fills, then it fades to the Mushaf
   page where you stopped; about a second on a normal start (SC-002). A tap during it ends it at once. Look at the hand-over from
   the system screen to the first splash frame: it must not flash. Before Android 12 the native screen shows the icon and the
   first splash frames are the flat night colour, so the icon disappears for an instant and fades back in; on Android 12 and later
   the system icon is replaced the same way. If that blink is not acceptable, tell the coordinator: the cure is one constant of
   `SplashTimeline` (start the tile at a visible opacity).
5. Turn on «إزالة الرسوم المتحركة» (Settings → Accessibility): the splash is still, about a third of a second, no fade.
6. Raise the system font size to the largest and rotate the phone during the splash: nothing is cut off or overlaps.
7. Open the app from the recents list (warm start): no splash. Kill it and open again: the splash shows again.
8. The first frame is no later than before: compare the time the first splash frame appears with the old white launch screen
   (it should be earlier or equal). Check that the reader's page appears with no second wait after the splash.
9. Read the line under the name and tell the coordinator whether to keep it (Open question 2 of the spec).
