import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/splash/icon_geometry.dart';

void main() {
  group('parsePath', () {
    test('a rectangle has its bounds', () {
      final p = AppIconGeometry.parsePath('M48 19 L60 19 L60 31 L48 31 Z');
      expect(p.getBounds(), const Rect.fromLTRB(48, 19, 60, 31));
    });

    test('a curve passes through its middle point', () {
      final path = AppIconGeometry.parsePath('M0 0 C0 10 10 10 10 0');
      final metric = path.computeMetrics().single;
      final mid = metric.getTangentForOffset(metric.length / 2)!.position;
      expect(mid.dx, closeTo(5, 0.05));
      expect(
        mid.dy,
        closeTo(7.5, 0.05),
      ); // the cubic peaks at 3/4 of the control height
    });

    test('commas, negatives, decimals and several subpaths are read', () {
      final p = AppIconGeometry.parsePath('M-1.5,2 L3 .5 M10 10 L12 12');
      final b = p.getBounds();
      expect(b.left, -1.5);
      expect(b.right, 12);
      expect(b.top, 0.5);
      expect(b.bottom, 12);
    });

    test('anything else is refused', () {
      for (final bad in [
        'M0 0 A5 5 0 0 1 10 10',
        'm0 0 l5 5',
        'M10',
        'M10 20 L30',
        'M0 0 C1 2 3 4 5',
        'M0 0 # 5',
        'Q0 0 1 1',
      ]) {
        expect(
          () => AppIconGeometry.parsePath(bad),
          throwsFormatException,
          reason: bad,
        );
      }
    });
  });

  group('the drawing', () {
    test('the star diamond is the square turned 45 degrees about (54, 25)', () {
      final square = AppIconGeometry.parsePath(AppIconGeometry.starSquare);
      final diamond = AppIconGeometry.parsePath(AppIconGeometry.starDiamond);
      expect(square.getBounds(), const Rect.fromLTRB(48, 19, 60, 31));
      final r = 6 * math.sqrt2;
      final b = diamond.getBounds();
      expect(b.left, closeTo(54 - r, 0.001));
      expect(b.right, closeTo(54 + r, 0.001));
      expect(b.top, closeTo(25 - r, 0.001));
      expect(b.bottom, closeTo(25 + r, 0.001));
      expect(AppIconGeometry.starCentre, const Offset(54, 25));
    });

    test('the monochrome star is the outline of the two squares', () {
      final outline = AppIconGeometry.parsePath(AppIconGeometry.monochromeStar);
      final r = 6 * math.sqrt2;
      final b = outline.getBounds();
      expect(b.left, closeTo(54 - r, 0.001));
      expect(b.right, closeTo(54 + r, 0.001));
      expect(b.top, closeTo(25 - r, 0.001));
      expect(b.bottom, closeTo(25 + r, 0.001));
    });

    test('the page, line and stroke values are the design\'s', () {
      expect(AppIconGeometry.canvas, 108);
      expect(
        AppIconGeometry.pageLeft,
        'M54 74 C46 68 34 66 24 68 L24 40 C34 38 46 40 54 46 Z',
      );
      expect(
        AppIconGeometry.pageRight,
        'M54 74 C62 68 74 66 84 68 L84 40 C74 38 62 40 54 46 Z',
      );
      expect(AppIconGeometry.spine, 'M54 46 L54 74');
      expect(
        AppIconGeometry.goldLine,
        'M22 73 C34 71 46 73 54 79 C62 73 74 71 86 73',
      );
      expect(AppIconGeometry.spineWidth, 0.8);
      expect(AppIconGeometry.pageLinesWidth, 1);
      expect(AppIconGeometry.goldWidth, 2.2);
      expect(AppIconGeometry.starHoleRadius, 2);
      // Every string of the drawing parses.
      for (final d in [
        AppIconGeometry.starSquare,
        AppIconGeometry.starDiamond,
        AppIconGeometry.starHole,
        AppIconGeometry.pageLeft,
        AppIconGeometry.pageRight,
        AppIconGeometry.spine,
        AppIconGeometry.pagesLinesLeft,
        AppIconGeometry.pagesLinesRight,
        AppIconGeometry.goldLine,
        AppIconGeometry.monochromeStar,
        AppIconGeometry.monochromePageLeft,
        AppIconGeometry.monochromePageRight,
      ]) {
        expect(
          AppIconGeometry.parsePath(d).computeMetrics(),
          isNotEmpty,
          reason: d,
        );
      }
    });
  });

  group('placements', () {
    test(
      'legacy is the design\'s translate(54 56) scale(.9) translate(-54 -54)',
      () {
        const p = AppIconGeometry.legacy;
        expect(p.scale, 0.9);
        expect(p.apply(const Offset(54, 54)), const Offset(54, 56));
        final o = p.apply(const Offset(22, 73));
        expect(o.dx, closeTo(54 + 0.9 * (22 - 54), 1e-9));
        expect(o.dy, closeTo(56 + 0.9 * (73 - 54), 1e-9));
      },
    );

    test('the adaptive foreground lies inside the 66 dp safe circle', () {
      // Measured by hand while planning: 32.33 (research D5).
      final r = AppIconGeometry.farthestFromCentre(AppIconGeometry.adaptive);
      expect(r, lessThanOrEqualTo(33));
      expect(r, greaterThan(31)); // not shrunk for nothing
    });

    test('the legacy placement is bigger than the safe circle (so the two differ for a reason)', () {
      final r = AppIconGeometry.farthestFromCentre(AppIconGeometry.legacy);
      expect(r, greaterThan(33));
    });
  });
}
