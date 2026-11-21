import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'splash_palette.dart';

/// The size of the design's reference screen (`Splash2.dc.html`), in which the decoration is placed; it is mapped to any real
/// size by `x * width / 390` and `y * height / 844`.
const Size kSplashReference = Size(390, 844);

/// The background of the splash: the flat night colour, the radial glow (the design's `radial-gradient(circle at 50% 30%,
/// #17313A 0%, #0D1014 62%)`), two faint rings and eight tiny stars (spec FR-008).
///
/// [backdrop] (0..1) fades the glow and the rings in from the flat colour of the native launch screen, [stars] (0..1) fades the
/// tiny stars in. Positions follow the screen proportionally; radii follow its width.
class SplashBackgroundPainter extends CustomPainter {
  const SplashBackgroundPainter({required this.backdrop, required this.stars});

  final double backdrop;
  final double stars;

  /// (x, y, radius, colour, opacity) in reference pixels.
  static const List<(double, double, double, Color, double)> _stars = [
    (60, 90, 1.6, SplashColors.name, 0.7),
    (318, 140, 1.2, SplashColors.name, 0.6),
    (260, 64, 1.8, SplashColors.star, 0.8),
    (120, 190, 1.1, SplashColors.name, 0.5),
    (346, 260, 1.5, SplashColors.gold, 0.7),
    (36, 300, 1.3, SplashColors.name, 0.5),
    (300, 640, 1.4, SplashColors.name, 0.45),
    (80, 700, 1.7, SplashColors.star, 0.6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / kSplashReference.width;
    final sy = size.height / kSplashReference.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = SplashColors.background,
    );

    if (backdrop > 0) {
      // CSS `circle` with the default size reaches the farthest corner; 62% of that is where the glow has gone.
      final centre = Offset(size.width * 0.5, size.height * 0.3);
      final corner = math.sqrt(
        math.pow(math.max(centre.dx, size.width - centre.dx), 2) +
            math.pow(math.max(centre.dy, size.height - centre.dy), 2),
      );
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.radial(centre, corner * 0.62, [
            Color.lerp(
              SplashColors.background,
              SplashColors.backdropGlow,
              backdrop,
            )!,
            SplashColors.background,
          ]),
      );
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sx;
      final ringCentre = Offset(195 * sx, 330 * sy);
      canvas.drawCircle(
        ringCentre,
        170 * sx,
        ring..color = SplashColors.ringNear.withValues(alpha: backdrop),
      );
      canvas.drawCircle(
        ringCentre,
        240 * sx,
        ring..color = SplashColors.ringFar.withValues(alpha: backdrop),
      );
    }

    if (stars > 0) {
      for (final (x, y, r, colour, opacity) in _stars) {
        canvas.drawCircle(
          Offset(x * sx, y * sy),
          r * sx,
          Paint()..color = colour.withValues(alpha: opacity * stars),
        );
      }
    }
  }

  @override
  bool shouldRepaint(SplashBackgroundPainter old) =>
      old.backdrop != backdrop || old.stars != stars;
}

/// The thin line at the bottom: a track (#232A33, radius 2) with a #6CC4B5 fill of [progress] of its width. It paints into
/// whatever size it is given; the splash gives it 120 x 3.
class ProgressLinePainter extends CustomPainter {
  const ProgressLinePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(2),
    );
    canvas.drawRRect(track, Paint()..color = SplashColors.progressTrack);
    if (progress <= 0) return;
    canvas.save();
    canvas.clipRRect(track);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * progress.clamp(0.0, 1.0), size.height),
      Paint()..color = SplashColors.progressFill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(ProgressLinePainter old) => old.progress != progress;
}
