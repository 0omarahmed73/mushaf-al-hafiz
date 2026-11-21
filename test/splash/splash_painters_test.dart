import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/splash/splash_painters.dart';
import 'package:mushaf/splash/splash_palette.dart';

import 'support/pixels.dart';

const Size reference = Size(390, 844);

Future<Pixels> background(
  WidgetTester tester, {
  required double backdrop,
  required double stars,
  Size size = reference,
}) => paintToPixels(
  tester,
  SplashBackgroundPainter(backdrop: backdrop, stars: stars),
  size,
);

double luminance(Color c) => 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;

void main() {
  testWidgets(
    'the glow is lighter at its centre and fades to the flat night colour',
    (tester) async {
      final p = await background(tester, backdrop: 1, stars: 0);
      final centre = p.at(195, 253); // 50% across and 30% down
      expect(
        near(centre, SplashColors.backdropGlow, 6),
        isTrue,
        reason: 'glow centre',
      );
      expect(luminance(centre), greaterThan(luminance(p.at(5, 5))));
      // The far bottom corners are beyond 62% of the distance to the farthest corner: flat.
      expect(
        near(p.at(2, 841), SplashColors.background),
        isTrue,
        reason: 'bottom-left',
      );
      expect(
        near(p.at(387, 841), SplashColors.background),
        isTrue,
        reason: 'bottom-right',
      );
      // The glow has no visible edge: it only ever gets darker moving away from the centre, down the middle column.
      var previous = 2.0;
      for (var y = 253; y < 700; y += 20) {
        final l = luminance(p.at(195, y));
        expect(l, lessThanOrEqualTo(previous + 0.004), reason: 'y=$y');
        previous = l;
      }
    },
  );

  testWidgets(
    'with no backdrop and no stars the picture is the flat native colour',
    (tester) async {
      final p = await background(tester, backdrop: 0, stars: 0);
      for (final (x, y) in [
        (0, 0),
        (195, 253),
        (195, 330),
        (60, 90),
        (389, 843),
        (195, 420),
        (300, 640),
      ]) {
        expect(
          near(p.at(x, y), SplashColors.background, 1),
          isTrue,
          reason: '($x, $y)',
        );
      }
    },
  );

  testWidgets(
    'the rings fade in with the backdrop and sit where the design puts them',
    (tester) async {
      final on = await background(tester, backdrop: 1, stars: 0);
      final off = await background(tester, backdrop: 0, stars: 0);
      // The ring of radius 170 around (195, 330) passes through (25, 330): a bump in brightness along that row.
      double bump(Pixels p) {
        var ring = 0.0;
        for (var x = 24; x <= 26; x++) {
          ring = ring < luminance(p.at(x, 330))
              ? luminance(p.at(x, 330))
              : ring;
        }
        return ring - (luminance(p.at(19, 330)) + luminance(p.at(31, 330))) / 2;
      }

      expect(bump(on), greaterThan(0.01));
      expect(bump(off).abs(), lessThan(0.004));
    },
  );

  testWidgets(
    'the tiny stars appear with `stars` and keep their place at other sizes',
    (tester) async {
      final on = await background(tester, backdrop: 1, stars: 1);
      final off = await background(tester, backdrop: 1, stars: 0);
      expect(
        luminance(on.at(60, 90)),
        greaterThan(luminance(off.at(60, 90)) + 0.2),
      );
      // The teal one at (260, 64) and the gold one at (346, 260).
      expect(on.at(260, 64).g, greaterThan(off.at(260, 64).g + 0.2));
      expect(on.at(346, 260).r, greaterThan(off.at(346, 260).r + 0.2));

      const half = Size(195, 422);
      final small = await background(tester, backdrop: 1, stars: 1, size: half);
      final smallOff = await background(
        tester,
        backdrop: 1,
        stars: 0,
        size: half,
      );
      expect(
        luminance(small.at(30, 45)),
        greaterThan(luminance(smallOff.at(30, 45)) + 0.2),
      );
    },
  );

  testWidgets('the thin line is a 120 x 3 track with a filled part', (
    tester,
  ) async {
    const size = Size(120, 3);
    final p = await paintToPixels(
      tester,
      const ProgressLinePainter(progress: 0.45),
      size,
    );
    expect(
      near(p.at(20, 1), SplashColors.progressFill),
      isTrue,
      reason: 'filled',
    );
    expect(
      near(p.at(53, 1), SplashColors.progressFill),
      isTrue,
      reason: 'last filled column',
    );
    expect(
      near(p.at(60, 1), SplashColors.progressTrack),
      isTrue,
      reason: 'track',
    );
    expect(
      near(p.at(110, 1), SplashColors.progressTrack),
      isTrue,
      reason: 'track end',
    );
    final empty = await paintToPixels(
      tester,
      const ProgressLinePainter(progress: 0),
      size,
    );
    expect(near(empty.at(20, 1), SplashColors.progressTrack), isTrue);
    final full = await paintToPixels(
      tester,
      const ProgressLinePainter(progress: 1),
      size,
    );
    expect(near(full.at(110, 1), SplashColors.progressFill), isTrue);
  });

  test('they repaint only when an input changed', () {
    const a = SplashBackgroundPainter(backdrop: 0.5, stars: 0.5);
    expect(
      a.shouldRepaint(const SplashBackgroundPainter(backdrop: 0.5, stars: 0.5)),
      isFalse,
    );
    expect(
      a.shouldRepaint(const SplashBackgroundPainter(backdrop: 0.6, stars: 0.5)),
      isTrue,
    );
    expect(
      a.shouldRepaint(const SplashBackgroundPainter(backdrop: 0.5, stars: 0.6)),
      isTrue,
    );
    const b = ProgressLinePainter(progress: 0.2);
    expect(b.shouldRepaint(const ProgressLinePainter(progress: 0.2)), isFalse);
    expect(b.shouldRepaint(const ProgressLinePainter(progress: 0.3)), isTrue);
  });
}
