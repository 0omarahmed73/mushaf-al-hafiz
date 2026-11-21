import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/splash/app_icon_painter.dart';
import 'package:mushaf/splash/icon_geometry.dart';
import 'package:mushaf/splash/splash_palette.dart';

import 'support/pixels.dart';

const double _px = 192; // pixels of the picture
const double _k = _px / 108; // pixels per canvas unit

/// The pixel of a point of the drawing, placed as the splash tile and the PNGs place it.
Offset where(double u, double v) {
  final p = AppIconGeometry.legacy.apply(Offset(u, v));
  return Offset(p.dx * _k, p.dy * _k);
}

Color at(Pixels pixels, Offset o) => pixels.at(o.dx.round(), o.dy.round());

int tealish(Pixels pixels) {
  var n = 0;
  for (var y = 0; y < pixels.height; y++) {
    for (var x = 0; x < pixels.width; x++) {
      final c = pixels.at(x, y);
      if (c.a > 0.5 && c.g > 0.62 && c.b > 0.55 && c.r < 0.5) n++;
    }
  }
  return n;
}

void main() {
  testWidgets('the icon is drawn as designed', (tester) async {
    final pixels = await paintToPixels(
      tester,
      const AppIconPainter(),
      const Size(_px, _px),
    );
    expect(
      near(at(pixels, where(28, 44)), SplashColors.pageLeft),
      isTrue,
      reason: 'left page',
    );
    expect(
      near(at(pixels, where(80, 44)), SplashColors.pageRight),
      isTrue,
      reason: 'right page',
    );
    expect(
      near(at(pixels, where(54, 20)), SplashColors.star),
      isTrue,
      reason: 'star',
    );
    expect(
      near(at(pixels, where(54, 25)), SplashColors.background),
      isTrue,
      reason: 'star hole',
    );
    expect(
      near(at(pixels, where(54, 79)), SplashColors.gold),
      isTrue,
      reason: 'gold line',
    );
    // The background: the gradient from #1A212A at the top to #0D1014 at the bottom.
    expect(
      near(at(pixels, const Offset(8, 8)), SplashColors.tileTop, 6),
      isTrue,
      reason: 'top',
    );
    expect(
      near(at(pixels, const Offset(8, _px - 8)), SplashColors.background, 6),
      isTrue,
      reason: 'bottom',
    );
    // The glow around (54, 30) lifts the colour toward teal; (72, 20) is clear of the art and 18 units from its centre.
    final glow = at(pixels, const Offset(72 * _k, 20 * _k));
    final away = at(pixels, const Offset(4 * _k, 20 * _k));
    expect(glow.g, greaterThan(away.g));
    // The whole square is painted: nothing transparent.
    expect(at(pixels, const Offset(0, 0)).a, 1);
    expect(at(pixels, const Offset(_px - 1, _px - 1)).a, 1);
  });

  testWidgets('a twinkle makes the star larger and brighter', (tester) async {
    final rest = await paintToPixels(
      tester,
      const AppIconPainter(),
      const Size(_px, _px),
    );
    final peak = await paintToPixels(
      tester,
      const AppIconPainter(twinkle: 1),
      const Size(_px, _px),
    );
    expect(tealish(peak), greaterThan(tealish(rest)));
  });

  testWidgets('without its background the corners are transparent', (
    tester,
  ) async {
    final pixels = await paintToPixels(
      tester,
      const AppIconPainter(withBackground: false),
      const Size(_px, _px),
    );
    expect(pixels.at(0, 0).a, 0);
    expect(pixels.at(_px.toInt() - 1, _px.toInt() - 1).a, 0);
    expect(near(at(pixels, where(28, 44)), SplashColors.pageLeft), isTrue);
  });

  testWidgets('it follows the size it is given', (tester) async {
    final small = await paintToPixels(
      tester,
      const AppIconPainter(),
      const Size(48, 48),
    );
    final p = AppIconGeometry.legacy.apply(const Offset(28, 44)) * (48 / 108);
    expect(
      near(small.at(p.dx.round(), p.dy.round()), SplashColors.pageLeft),
      isTrue,
    );
  });

  test('it repaints only when something changed', () {
    const a = AppIconPainter();
    expect(a.shouldRepaint(const AppIconPainter()), isFalse);
    expect(a.shouldRepaint(const AppIconPainter(twinkle: 0.5)), isTrue);
    expect(
      a.shouldRepaint(const AppIconPainter(withBackground: false)),
      isTrue,
    );
    expect(
      a.shouldRepaint(
        const AppIconPainter(placement: AppIconGeometry.adaptive),
      ),
      isTrue,
    );
  });
}
