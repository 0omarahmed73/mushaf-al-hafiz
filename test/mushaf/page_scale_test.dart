// The pure rules of the page size: how big the page box is for a size, how it fits the viewport, and when a
// swipe from the side edge turns the page (spec FR-007, FR-008; research D2, D3).
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/mushaf/page_scale.dart';

void main() {
  const portrait = Size(412, 763);
  const landscape = Size(915, 340);

  test('the landscape numbers are the ones the reader had', () {
    expect(kLandscapePageWidth, 600);
    expect(kPageAspect, 1.75);
  });

  group('PageBox', () {
    test('portrait at 100%: the page is the viewport and fits', () {
      final box = PageBox(portrait, 1.0);
      expect(box.base, portrait);
      expect(box.scaled, portrait);
      expect(box.content, portrait);
      expect(box.fit, PageFit.fits);
    });

    test('portrait below 100% is smaller than the viewport and fits', () {
      final box = PageBox(portrait, 0.8);
      expect(box.scaled.width, closeTo(329.6, 1e-9));
      expect(box.scaled.height, closeTo(610.4, 1e-9));
      expect(
        box.content,
        portrait,
        reason: 'the pannable area is never smaller than the viewport',
      );
      expect(box.fit, PageFit.fits);
    });

    test('portrait above 100% is wider than the screen: it pans both ways', () {
      for (final f in [1.1, 1.2, 1.3, 1.4, 1.5]) {
        final box = PageBox(portrait, f);
        expect(box.fit, PageFit.pansBothWays, reason: '$f');
        expect(box.scaled.width, closeTo(412 * f, 1e-9));
        expect(box.content.width, closeTo(412 * f, 1e-9));
        expect(box.content.height, closeTo(763 * f, 1e-9));
      }
    });

    test('landscape at 100% is the portrait-shaped page, at most 600 wide, scrolling up and down', () {
      final box = PageBox(landscape, 1.0);
      expect(box.base, const Size(600, 1050));
      expect(box.fit, PageFit.scrollsVertically);
      expect(box.content, const Size(915, 1050));
    });

    test('landscape narrower than 600 uses the whole width', () {
      final box = PageBox(const Size(560, 340), 1.0);
      expect(box.base, const Size(560, 980));
      expect(box.fit, PageFit.scrollsVertically);
    });

    test('landscape above 100% grows with the width: up and down while it fits, both ways when it does not', () {
      final fits = PageBox(landscape, 1.5);
      expect(fits.scaled, const Size(900, 1575));
      expect(
        fits.fit,
        PageFit.scrollsVertically,
        reason: '900 is not wider than 915',
      );
      final wider = PageBox(const Size(800, 340), 1.5);
      expect(wider.fit, PageFit.pansBothWays, reason: '900 is wider than 800');
    });

    test('landscape below 100% that fits the height needs no scrolling', () {
      final box = PageBox(const Size(915, 900), 0.8);
      expect(box.base, const Size(600, 1050));
      expect(box.scaled, const Size(480, 840));
      expect(box.fit, PageFit.fits);
    });

    test('a page that is exactly as wide as the screen does not pan', () {
      expect(PageBox(portrait, 1.0).fit, PageFit.fits);
      expect(PageBox(const Size(900, 340), 1.5).fit, PageFit.scrollsVertically);
    });

    test('a page that starts panned shows its top and its right side (where reading starts)', () {
      final box = PageBox(portrait, 1.5);
      expect(box.startOffset, Offset(412 - 412 * 1.5, 0));
      expect(PageBox(portrait, 1.0).startOffset, Offset.zero);
      expect(PageBox(landscape, 1.0).startOffset, Offset.zero);
    });
  });

  group('edgeTurn', () {
    // A 618 px wide page in a 412 px viewport: x runs from minX = -206 (right edge shown) to maxX = 0 (left).
    const minX = -206.0, maxX = 0.0;

    PageTurn turn({
      required double startX,
      double dx = 0,
      double dy = 0,
      double vx = 0,
    }) => edgeTurn(
      startX: startX,
      minX: minX,
      maxX: maxX,
      dx: dx,
      dy: dy,
      vx: vx,
    );

    test('from the left edge, a finger moving left to right at least 56 px brings the next page', () {
      expect(turn(startX: 0, dx: 56), PageTurn.next);
      expect(turn(startX: 0, dx: 200), PageTurn.next);
    });

    test('from the right edge, a finger moving right to left at least 56 px brings the previous page', () {
      expect(turn(startX: -206, dx: -56), PageTurn.previous);
      expect(turn(startX: -206, dx: -200), PageTurn.previous);
    });

    test('a short drag does nothing', () {
      expect(turn(startX: 0, dx: 55), PageTurn.none);
      expect(turn(startX: -206, dx: -55), PageTurn.none);
    });

    test('a fast flick turns even when it is short', () {
      expect(turn(startX: 0, dx: 20, vx: 900), PageTurn.next);
      expect(turn(startX: -206, dx: -20, vx: -900), PageTurn.previous);
      expect(
        turn(startX: 0, dx: 5, vx: 900),
        PageTurn.none,
        reason: 'a touch, not a swipe',
      );
    });

    test('a drag that started in the middle never turns the page, however far it went', () {
      expect(turn(startX: -100, dx: 400), PageTurn.none);
      expect(turn(startX: -100, dx: -400), PageTurn.none);
      expect(turn(startX: -100, dx: 20, vx: 2000), PageTurn.none);
    });

    test('a drag away from the page edge it started at does nothing', () {
      expect(
        turn(startX: 0, dx: -200),
        PageTurn.none,
        reason: 'at the left edge, moving left pans the page',
      );
      expect(
        turn(startX: -206, dx: 200),
        PageTurn.none,
        reason: 'at the right edge, moving right pans the page',
      );
    });

    test('a mostly vertical drag at an edge does nothing', () {
      expect(turn(startX: 0, dx: 80, dy: 90), PageTurn.none);
      expect(turn(startX: 0, dx: 80, dy: 79), PageTurn.next);
    });

    test('a start within a pixel of the edge counts as at the edge', () {
      expect(turn(startX: -0.4, dx: 60), PageTurn.next);
      expect(turn(startX: -205.6, dx: -60), PageTurn.previous);
      expect(turn(startX: -1.5, dx: 60), PageTurn.none);
    });

    test(
      'a page that is not wider than the viewport never turns by this rule',
      () {
        final none = edgeTurn(
          startX: 0,
          minX: 0,
          maxX: 0,
          dx: 300,
          dy: 0,
          vx: 2000,
        );
        expect(none, PageTurn.none);
        final inverted = edgeTurn(
          startX: 0,
          minX: 10,
          maxX: 0,
          dx: -300,
          dy: 0,
          vx: -2000,
        );
        expect(inverted, PageTurn.none);
      },
    );

    test('the distance and the fling speed can be changed', () {
      expect(
        edgeTurn(
          startX: 0,
          minX: minX,
          maxX: maxX,
          dx: 30,
          dy: 0,
          vx: 0,
          distance: 30,
        ),
        PageTurn.next,
      );
      expect(
        edgeTurn(
          startX: 0,
          minX: minX,
          maxX: maxX,
          dx: 30,
          dy: 0,
          vx: 300,
          flingVelocity: 250,
        ),
        PageTurn.next,
      );
    });
  });
}
