import 'dart:math' as math;
import 'dart:ui';

/// In landscape the page keeps the shape it has in portrait (about the proportion of a phone held upright), at
/// most this wide, and scrolls up and down.
const double kLandscapePageWidth = 600;
const double kPageAspect = 1.75;

/// How the page at the chosen size sits in the space the reader gives it (spec FR-007, FR-008).
enum PageFit {
  /// The whole page is on the screen: centred, nothing to scroll.
  fits,

  /// Taller than the screen but not wider: it scrolls up and down, and a horizontal swipe turns the page.
  scrollsVertically,

  /// Wider than the screen: it moves up, down and sideways, and a swipe from its side edge turns the page.
  pansBothWays,
}

/// The size of the page for a size setting and how it fits a [viewport]: today's box (the viewport in
/// portrait; in landscape the portrait-shaped page at most [kLandscapePageWidth] wide) times the factor. The
/// page widget is laid out in [scaled], so the page grows or shrinks as a whole and keeps its layout.
class PageBox {
  PageBox(this.viewport, this.factor) {
    final landscape = viewport.width > viewport.height;
    final width = landscape
        ? math.min(viewport.width, kLandscapePageWidth)
        : viewport.width;
    base = landscape ? Size(width, width * kPageAspect) : viewport;
    scaled = Size(base.width * factor, base.height * factor);
    content = Size(
      math.max(viewport.width, scaled.width),
      math.max(viewport.height, scaled.height),
    );
  }

  /// The space the reader gives one page.
  final Size viewport;
  final double factor;

  /// Today's page box.
  late final Size base;

  /// [base] times the factor: what the page card is laid out in.
  late final Size scaled;

  /// The area the page can be moved over: never smaller than the viewport.
  late final Size content;

  PageFit get fit {
    const slack = 0.5;
    if (scaled.width > viewport.width + slack) return PageFit.pansBothWays;
    if (scaled.height > viewport.height + slack) {
      return PageFit.scrollsVertically;
    }
    return PageFit.fits;
  }

  /// Where a panned page starts: its top and its right side, where reading starts. Zero for the other fits.
  Offset get startOffset => fit == PageFit.pansBothWays
      ? Offset(viewport.width - content.width, 0)
      : Offset.zero;
}

/// What a finished one-finger drag on a page that is wider than the screen means for the pager.
enum PageTurn { none, next, previous }

/// A swipe that **starts** with the page against a side edge and then moves outward turns the page; a drag that
/// merely runs into an edge stops there (spec FR-008). [startX] is the page's x offset when the drag began
/// (`maxX` = left edge shown, `minX` = right edge shown, [maxX] ≥ [minX] and a page that is not wider has
/// them equal). [dx] and [dy] are the finger's total travel, [vx] its speed at the end. A finger moving left to
/// right from the left edge brings the next page, right to left from the right edge the previous page, as in
/// the paper Mushaf (Constitution VI).
PageTurn edgeTurn({
  required double startX,
  required double minX,
  required double maxX,
  required double dx,
  required double dy,
  required double vx,
  double distance = 56,
  double flingVelocity = 700,
}) {
  const edgeSlack = 1.0;
  const flingMinTravel = 16.0;
  if (minX >= maxX) return PageTurn.none;
  if (dy.abs() >= dx.abs()) return PageTurn.none;
  bool far(double travel) => travel >= distance;
  if (startX >= maxX - edgeSlack) {
    if (far(dx) || (vx >= flingVelocity && dx >= flingMinTravel)) {
      return PageTurn.next;
    }
  } else if (startX <= minX + edgeSlack) {
    if (far(-dx) || (vx <= -flingVelocity && -dx >= flingMinTravel)) {
      return PageTurn.previous;
    }
  }
  return PageTurn.none;
}
