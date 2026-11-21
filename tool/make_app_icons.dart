// Writes the launcher icon resources of feature 009 from the drawing in lib/splash/icon_geometry.dart.
//
// Run from the repository root, no network and no package needed:
//
//     flutter test tool/make_app_icons.dart
//
// It writes only inside android/app/src/main/res/: the three vector layers of the adaptive icon (drawable/ic_launcher_*.xml,
// Android 8 and later) and the five old-style PNGs (mipmap-*/ic_launcher.png, Android 7) drawn by the same AppIconPainter as
// the splash tile, as a rounded square with transparent corners. `test/splash/android_icon_resources_test.dart` fails when a
// committed file differs from what this writes (the vectors) or is not the design (the PNGs).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/splash/app_icon_painter.dart';

import 'app_icon_resources.dart';

const String res = 'android/app/src/main/res';

/// Density folder and picture size in pixels of the old-style launcher icon.
const Map<String, int> densities = {
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

/// The corner radius of the old-style icon as a share of its size (the design's large preview: 64 of 256).
const double cornerShare = 0.25;

void main() {
  testWidgets('writes the launcher icon resources', (tester) async {
    File('$res/drawable/ic_launcher_background.xml')
        .writeAsStringSync(AppIconResources.background());
    File('$res/drawable/ic_launcher_foreground.xml')
        .writeAsStringSync(AppIconResources.foreground());
    File('$res/drawable/ic_launcher_monochrome.xml')
        .writeAsStringSync(AppIconResources.monochrome());

    await tester.runAsync(() async {
      for (final MapEntry(key: density, value: size) in densities.entries) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final box = Size(size.toDouble(), size.toDouble());
        canvas.clipRRect(
          RRect.fromRectAndRadius(
            Offset.zero & box,
            Radius.circular(size * cornerShare),
          ),
        );
        const AppIconPainter().paint(canvas, box);
        final image = await recorder.endRecording().toImage(size, size);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$res/mipmap-$density/ic_launcher.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      }
    });
  });
}
