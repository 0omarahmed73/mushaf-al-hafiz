import 'dart:math' as math;

import 'splash_plan.dart';

/// What the splash looks like at one moment (data-model.md `SplashFrame`). Immutable, so the painter and the widgets only
/// read it.
class SplashFrame {
  const SplashFrame({
    required this.backdrop,
    required this.stars,
    required this.tileOpacity,
    required this.tileScale,
    required this.twinkle,
    required this.nameOpacity,
    required this.nameRise,
    required this.lineOpacity,
    required this.lineRise,
    required this.progress,
  });

  /// Strength of the radial glow over the flat #0D1014, 0..1.
  final double backdrop;

  /// Opacity of the tiny stars, 0..1.
  final double stars;

  /// The icon tile: opacity 0..1 and scale 0.92..1.
  final double tileOpacity;
  final double tileScale;

  /// The pulse of the icon's star, 0 at rest and 1 at the peak.
  final double twinkle;

  /// The name: opacity 0..1 and the distance it still has to rise, 14 to 0 logical pixels.
  final double nameOpacity;
  final double nameRise;

  /// The line under the name: opacity 0..1 and the distance it still has to rise, 10 to 0 logical pixels.
  final double lineOpacity;
  final double lineRise;

  /// The fill of the thin line at the bottom, 0..1.
  final double progress;

  @override
  bool operator ==(Object other) =>
      other is SplashFrame &&
      other.backdrop == backdrop &&
      other.stars == stars &&
      other.tileOpacity == tileOpacity &&
      other.tileScale == tileScale &&
      other.twinkle == twinkle &&
      other.nameOpacity == nameOpacity &&
      other.nameRise == nameRise &&
      other.lineOpacity == lineOpacity &&
      other.lineRise == lineRise &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(
    backdrop,
    stars,
    tileOpacity,
    tileScale,
    twinkle,
    nameOpacity,
    nameRise,
    lineOpacity,
    lineRise,
    progress,
  );
}

/// The choreography of the splash as a pure function of the time since its first frame (research D3). Every beat uses an
/// easing curve and none overshoots, so nothing bounces.
abstract final class SplashTimeline {
  /// Everything shown, the thin line full: what reduced motion paints and where the full timeline ends.
  static const SplashFrame finalFrame = SplashFrame(
    backdrop: 1,
    stars: 1,
    tileOpacity: 1,
    tileScale: 1,
    twinkle: 0,
    nameOpacity: 1,
    nameRise: 0,
    lineOpacity: 1,
    lineRise: 0,
    progress: 1,
  );

  static const double _tileFrom = 0.92;
  static const double _nameRise = 14;
  static const double _lineRise = 10;

  static SplashFrame at(Duration elapsed) {
    final ms = elapsed.inMicroseconds / 1000;
    if (elapsed >= SplashPlan.fullDuration) return finalFrame;
    final t = ms < 0 ? 0.0 : ms;
    final name = _easeOutCubic(_span(t, 350, 800));
    final line = _easeOutCubic(_span(t, 450, 900));
    final tile = _span(t, 0, 600);
    return SplashFrame(
      backdrop: _easeOut(_span(t, 0, 500)),
      stars: _easeOut(_span(t, 150, 650)),
      tileOpacity: _easeOut(tile),
      tileScale: _tileFrom + (1 - _tileFrom) * _easeOutCubic(tile),
      twinkle: t <= 400 || t >= 800 ? 0 : math.sin(math.pi * (t - 400) / 400),
      nameOpacity: _easeOut(_span(t, 350, 800)),
      nameRise: _nameRise * (1 - name),
      lineOpacity: _easeOut(_span(t, 450, 900)),
      lineRise: _lineRise * (1 - line),
      progress: _easeOutCubic(_span(t, 0, 1400)),
    );
  }

  /// Where [t] stands between [from] and [to], 0..1.
  static double _span(double t, double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  static double _easeOut(double u) => 1 - (1 - u) * (1 - u);

  static double _easeOutCubic(double u) => 1 - (1 - u) * (1 - u) * (1 - u);
}
