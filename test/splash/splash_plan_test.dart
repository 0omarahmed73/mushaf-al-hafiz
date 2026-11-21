import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/splash/splash_plan.dart';

bool leave(
  int ms, {
  bool ready = true,
  bool skipped = false,
  bool reduced = false,
}) => SplashPlan.mayLeave(
  elapsed: Duration(milliseconds: ms),
  ready: ready,
  skipped: skipped,
  reducedMotion: reduced,
);

void main() {
  test('the constants are the spec\'s', () {
    expect(SplashPlan.fullDuration, const Duration(milliseconds: 1400));
    expect(SplashPlan.minimum, const Duration(milliseconds: 900));
    expect(SplashPlan.reducedStay, const Duration(milliseconds: 300));
    expect(SplashPlan.fade, const Duration(milliseconds: 220));
  });

  test('a splash that is not ready never leaves', () {
    for (final ms in [0, 899, 900, 1400, 60000]) {
      expect(leave(ms, ready: false), isFalse, reason: '$ms ms');
      expect(
        leave(ms, ready: false, skipped: true),
        isFalse,
        reason: '$ms ms skipped',
      );
      expect(
        leave(ms, ready: false, reduced: true),
        isFalse,
        reason: '$ms ms reduced',
      );
    }
  });

  test('a ready splash leaves at the minimum and not before', () {
    expect(leave(0), isFalse);
    expect(leave(899), isFalse);
    expect(leave(900), isTrue);
    expect(leave(1400), isTrue);
  });

  test('a tap leaves at once, but only when ready', () {
    expect(leave(0, skipped: true), isTrue);
    expect(leave(1, skipped: true), isTrue);
    expect(leave(0, skipped: true, ready: false), isFalse);
  });

  test('reduced motion leaves at 300 ms and not at 299 ms', () {
    expect(leave(0, reduced: true), isFalse);
    expect(leave(299, reduced: true), isFalse);
    expect(leave(300, reduced: true), isTrue);
    expect(leave(0, reduced: true, skipped: true), isTrue);
  });
}
