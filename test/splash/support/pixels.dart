import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pixels of a picture, for tests that look at what a painter drew.
class Pixels {
  Pixels(this.width, this.height, this._data);

  final int width;
  final int height;
  final ByteData _data;

  /// The colour at pixel ([x], [y]); alpha is kept (straight, not premultiplied).
  ui.Color at(int x, int y) {
    final o = (y * width + x) * 4;
    return ui.Color.fromARGB(
      _data.getUint8(o + 3),
      _data.getUint8(o),
      _data.getUint8(o + 1),
      _data.getUint8(o + 2),
    );
  }
}

/// Draws [painter] at [size] (one logical pixel is one device pixel) and returns the pixels. Runs the real engine, so it
/// needs `tester.runAsync`.
Future<Pixels> paintToPixels(
  WidgetTester tester,
  CustomPainter painter,
  Size size,
) async {
  final pixels = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    painter.paint(ui.Canvas(recorder), size);
    final image = await recorder.endRecording().toImage(
      size.width.round(),
      size.height.round(),
    );
    final data = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    return Pixels(image.width, image.height, data!);
  });
  return pixels!;
}

/// Decodes PNG [bytes] into pixels.
Future<Pixels> decodePng(WidgetTester tester, Uint8List bytes) async {
  final pixels = await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    return Pixels(image.width, image.height, data!);
  });
  return pixels!;
}

/// Whether two colours differ by at most [tolerance] in each of red, green and blue.
bool near(ui.Color a, ui.Color b, [int tolerance = 3]) =>
    ((a.r - b.r).abs() * 255).round() <= tolerance &&
    ((a.g - b.g).abs() * 255).round() <= tolerance &&
    ((a.b - b.b).abs() * 255).round() <= tolerance;
