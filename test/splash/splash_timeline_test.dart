import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/splash/splash_plan.dart';
import 'package:mushaf/splash/splash_timeline.dart';

SplashFrame at(int ms) => SplashTimeline.at(Duration(milliseconds: ms));

void main() {
  test('the first frame is flat, like the native launch screen', () {
    final f = at(0);
    expect(f.backdrop, 0);
    expect(f.stars, 0);
    expect(f.tileOpacity, 0);
    expect(f.nameOpacity, 0);
    expect(f.lineOpacity, 0);
    expect(f.progress, 0);
    expect(f.twinkle, 0);
    expect(f.tileScale, 0.92);
    expect(f.nameRise, 14);
    expect(f.lineRise, 10);
  });

  test('negative durations are clamped to the first frame', () {
    expect(SplashTimeline.at(const Duration(milliseconds: -50)), at(0));
  });

  test('every field stays in its range for 0 to 2000 ms', () {
    for (var ms = 0; ms <= 2000; ms++) {
      final f = at(ms);
      for (final v in [
        f.backdrop,
        f.stars,
        f.tileOpacity,
        f.twinkle,
        f.nameOpacity,
        f.lineOpacity,
        f.progress,
      ]) {
        expect(v, inInclusiveRange(0.0, 1.0), reason: '$ms ms');
      }
      expect(f.tileScale, inInclusiveRange(0.92, 1.0), reason: '$ms ms');
      expect(f.nameRise, inInclusiveRange(0.0, 14.0), reason: '$ms ms');
      expect(f.lineRise, inInclusiveRange(0.0, 10.0), reason: '$ms ms');
    }
  });

  test('one-way moves never go backwards', () {
    var prev = at(0);
    for (var ms = 1; ms <= 2000; ms++) {
      final f = at(ms);
      expect(f.backdrop, greaterThanOrEqualTo(prev.backdrop), reason: '$ms');
      expect(f.stars, greaterThanOrEqualTo(prev.stars), reason: '$ms');
      expect(
        f.tileOpacity,
        greaterThanOrEqualTo(prev.tileOpacity),
        reason: '$ms',
      );
      expect(f.tileScale, greaterThanOrEqualTo(prev.tileScale), reason: '$ms');
      expect(
        f.nameOpacity,
        greaterThanOrEqualTo(prev.nameOpacity),
        reason: '$ms',
      );
      expect(
        f.lineOpacity,
        greaterThanOrEqualTo(prev.lineOpacity),
        reason: '$ms',
      );
      expect(f.progress, greaterThanOrEqualTo(prev.progress), reason: '$ms');
      expect(f.nameRise, lessThanOrEqualTo(prev.nameRise), reason: '$ms');
      expect(f.lineRise, lessThanOrEqualTo(prev.lineRise), reason: '$ms');
      prev = f;
    }
  });

  test('the star twinkles once, between 400 and 800 ms', () {
    for (var ms = 0; ms <= 400; ms++) {
      expect(at(ms).twinkle, 0, reason: '$ms ms');
    }
    for (var ms = 800; ms <= 2000; ms++) {
      expect(at(ms).twinkle, 0, reason: '$ms ms');
    }
    var peaks = 0;
    var falling = false;
    var prev = 0.0;
    for (var ms = 401; ms < 800; ms++) {
      final v = at(ms).twinkle;
      if (v < prev) {
        if (!falling) peaks++;
        falling = true;
      } else if (v > prev && falling) {
        peaks++; // rose again: a second pulse
        falling = false;
      }
      prev = v;
    }
    expect(peaks, 1);
    expect(at(600).twinkle, closeTo(1, 0.001));
  });

  test('everything but the thin line has settled at the 900 ms minimum', () {
    final f = at(SplashPlan.minimum.inMilliseconds);
    final end = SplashTimeline.finalFrame;
    expect(f.backdrop, end.backdrop);
    expect(f.stars, end.stars);
    expect(f.tileOpacity, end.tileOpacity);
    expect(f.tileScale, end.tileScale);
    expect(f.twinkle, end.twinkle);
    expect(f.nameOpacity, end.nameOpacity);
    expect(f.nameRise, end.nameRise);
    expect(f.lineOpacity, end.lineOpacity);
    expect(f.lineRise, end.lineRise);
    expect(f.progress, lessThan(end.progress));
    expect(
      f.progress,
      greaterThan(0.9),
    ); // the line is nearly full when a ready app leaves
  });

  test('from 1400 ms the frame is the final frame', () {
    expect(
      SplashTimeline.at(SplashPlan.fullDuration),
      SplashTimeline.finalFrame,
    );
    expect(at(1400), SplashTimeline.finalFrame);
    expect(at(5000), SplashTimeline.finalFrame);
    expect(SplashTimeline.finalFrame.progress, 1);
    expect(SplashTimeline.finalFrame.tileOpacity, 1);
    expect(SplashTimeline.finalFrame.tileScale, 1);
    expect(SplashTimeline.finalFrame.nameRise, 0);
  });
}
