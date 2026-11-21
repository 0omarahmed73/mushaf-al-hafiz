// The rule that decides whether one drag at the last page opens the khatm dua (spec FR-001; research D1, D2;
// data-model.md LastPageSwipe.forward distance and LastPageSwipe.constants).
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/khatm/last_page_swipe.dart';

void main() {
  late LastPageSwipe swipe;
  setUp(() => swipe = LastPageSwipe());

  /// One gesture: forward travel [px] in one go, released at [velocity].
  bool gesture(double px, {double velocity = 0}) {
    swipe
      ..start()
      ..overscroll(px);
    return swipe.end(velocity: velocity);
  }

  test('the constants are the ones the plan names', () {
    expect(LastPageSwipe.minDistance, 48);
    expect(LastPageSwipe.minFlingDistance, 16);
    expect(LastPageSwipe.minFlingVelocity, 300);
  });

  group('a slow drag', () {
    test('47.9 px is too little', () => expect(gesture(47.9), isFalse));
    test('48 px opens', () => expect(gesture(48), isTrue));
    test('120 px opens', () => expect(gesture(120), isTrue));
    test('a drag in many small steps adds up', () {
      swipe.start();
      for (var i = 0; i < 12; i++) {
        swipe.overscroll(10);
      }
      expect(swipe.distance, 120);
      expect(swipe.end(velocity: 0), isTrue);
    });
  });

  group('a flick', () {
    test(
      '16 px at 300 px/s opens',
      () => expect(gesture(16, velocity: 300), isTrue),
    );
    test(
      '16 px at 299 px/s does not',
      () => expect(gesture(16, velocity: 299), isFalse),
    );
    test(
      '15.9 px at 5000 px/s does not',
      () => expect(gesture(15.9, velocity: 5000), isFalse),
    );
    test(
      '200 px at 1500 px/s opens',
      () => expect(gesture(200, velocity: 1500), isTrue),
    );
    test('a backward release speed does not count as a flick', () {
      expect(gesture(20, velocity: -1500), isFalse);
    });
  });

  group('what is ignored', () {
    test('negative overscroll (the other end, page 1) never adds', () {
      swipe
        ..start()
        ..overscroll(-500)
        ..overscroll(-30);
      expect(swipe.distance, 0);
      expect(swipe.end(velocity: 5000), isFalse);
    });

    test('zero overscroll adds nothing', () {
      swipe
        ..start()
        ..overscroll(0);
      expect(swipe.distance, 0);
    });

    test('forward and backward in one gesture count only the forward part', () {
      swipe
        ..start()
        ..overscroll(30)
        ..overscroll(-100)
        ..overscroll(30);
      expect(swipe.distance, 60);
      expect(swipe.end(velocity: 0), isTrue);
    });
  });

  group('state between gestures', () {
    test('two gestures never add together', () {
      expect(gesture(30), isFalse);
      expect(gesture(30), isFalse);
    });

    test('start() clears the distance', () {
      swipe
        ..start()
        ..overscroll(40)
        ..start();
      expect(swipe.distance, 0);
    });

    test('end() resets, so a second end() answers false', () {
      swipe
        ..start()
        ..overscroll(100);
      expect(swipe.end(velocity: 0), isTrue);
      expect(swipe.distance, 0);
      expect(swipe.end(velocity: 5000), isFalse);
    });

    test('end() without start() answers from what is there (nothing)', () {
      expect(swipe.end(velocity: 5000), isFalse);
    });
  });
}
