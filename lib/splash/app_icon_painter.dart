import 'dart:ui' as ui show Gradient;

import 'package:flutter/rendering.dart';

import 'icon_geometry.dart';
import 'splash_palette.dart';

/// Draws icon 2 «المصحف المفتوح» on a square of any size (the 108-unit canvas scaled to fit): the night background with its
/// teal glow when [withBackground] is true, then the star, the pages, the lines and the gold line, placed by [placement]. It
/// is the splash tile and, drawn into pictures by `tool/make_app_icons.dart`, the launcher PNGs (spec FR-004).
class AppIconPainter extends CustomPainter {
  const AppIconPainter({
    this.twinkle = 0,
    this.withBackground = true,
    this.placement = AppIconGeometry.legacy,
    super.repaint,
  });

  /// 0 at rest, 1 at the peak of the star's pulse: the star grows to 1.3 times its size and a teal halo shows behind it.
  final double twinkle;
  final bool withBackground;
  final IconPlacement placement;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / AppIconGeometry.canvas;
    canvas.save();
    canvas.scale(unit);
    if (withBackground) _paintBackground(canvas);
    canvas.translate(
      placement.pivot.dx + placement.shift.dx,
      placement.pivot.dy + placement.shift.dy,
    );
    canvas.scale(placement.scale);
    canvas.translate(-placement.pivot.dx, -placement.pivot.dy);
    _paintArt(canvas);
    canvas.restore();
  }

  void _paintBackground(Canvas canvas) {
    const rect = Rect.fromLTWH(
      0,
      0,
      AppIconGeometry.canvas,
      AppIconGeometry.canvas,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(0, AppIconGeometry.canvas),
          const [SplashColors.tileTop, SplashColors.background],
        ),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(54, 30), 48, [
          SplashColors.star.withValues(alpha: 0.30),
          SplashColors.star.withValues(alpha: 0),
        ]),
    );
  }

  void _paintArt(Canvas canvas) {
    final fill = Paint()..style = PaintingStyle.fill;
    Paint stroke(Color color, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    // The star, with the twinkle's halo behind it.
    const centre = AppIconGeometry.starCentre;
    if (twinkle > 0) {
      canvas.drawCircle(
        centre,
        14 + 6 * twinkle,
        Paint()
          ..shader = ui.Gradient.radial(centre, 14 + 6 * twinkle, [
            SplashColors.star.withValues(alpha: 0.45 * twinkle),
            SplashColors.star.withValues(alpha: 0),
          ]),
      );
    }
    canvas.save();
    final grow = 1 + 0.3 * twinkle;
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(grow);
    canvas.translate(-centre.dx, -centre.dy);
    fill.color = SplashColors.star;
    canvas.drawPath(
      AppIconGeometry.parsePath(AppIconGeometry.starSquare),
      fill,
    );
    canvas.drawPath(
      AppIconGeometry.parsePath(AppIconGeometry.starDiamond),
      fill,
    );
    fill.color = SplashColors.background;
    canvas.drawCircle(centre, AppIconGeometry.starHoleRadius, fill);
    canvas.restore();

    // The book.
    fill.color = SplashColors.pageLeft;
    canvas.drawPath(AppIconGeometry.parsePath(AppIconGeometry.pageLeft), fill);
    fill.color = SplashColors.pageRight;
    canvas.drawPath(AppIconGeometry.parsePath(AppIconGeometry.pageRight), fill);
    canvas.drawPath(
      AppIconGeometry.parsePath(AppIconGeometry.spine),
      stroke(SplashColors.pageInk, AppIconGeometry.spineWidth)
        ..strokeCap = StrokeCap.butt,
    );
    final lines = stroke(SplashColors.pageInk, AppIconGeometry.pageLinesWidth);
    canvas.drawPath(
      AppIconGeometry.parsePath(AppIconGeometry.pagesLinesLeft),
      lines,
    );
    canvas.drawPath(
      AppIconGeometry.parsePath(AppIconGeometry.pagesLinesRight),
      lines,
    );

    // The gold line under it.
    canvas.drawPath(
      AppIconGeometry.parsePath(AppIconGeometry.goldLine),
      stroke(SplashColors.gold, AppIconGeometry.goldWidth),
    );
  }

  @override
  bool shouldRepaint(AppIconPainter old) =>
      old.twinkle != twinkle ||
      old.withBackground != withBackground ||
      old.placement != placement;
}
