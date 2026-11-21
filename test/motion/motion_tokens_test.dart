// Feature 010 T004: the motion tokens equal specs/010-smooth-motion/contracts/ui.md, and the phone's «remove animations»
// setting turns every duration into zero.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/motion/motion.dart';

void main() {
  test('the numbers of contracts/ui.md', () {
    expect(Motion.barIn, const Duration(milliseconds: 200));
    expect(Motion.barOut, const Duration(milliseconds: 160));
    expect(Motion.cardIn, const Duration(milliseconds: 220));
    expect(Motion.cardOut, const Duration(milliseconds: 160));
    expect(Motion.jump, const Duration(milliseconds: 180));
    expect(Motion.swap, const Duration(milliseconds: 160));
    expect(Motion.look, const Duration(milliseconds: 220));
    expect(Motion.edgeTurn, const Duration(milliseconds: 300));
    expect(Motion.enter, Curves.easeOutCubic);
    expect(Motion.exit, Curves.easeInCubic);
    expect(Motion.barSlide, 24);
    expect(Motion.cardSlide, 12);
  });

  test(
    'nothing is longer than 300 ms and nothing slides further than 24 dp',
    () {
      for (final d in [
        Motion.barIn,
        Motion.barOut,
        Motion.cardIn,
        Motion.cardOut,
        Motion.jump,
        Motion.swap,
        Motion.look,
        Motion.edgeTurn,
      ]) {
        expect(d, lessThanOrEqualTo(const Duration(milliseconds: 300)));
      }
      expect(Motion.barSlide, lessThanOrEqualTo(24));
      expect(Motion.cardSlide, lessThanOrEqualTo(24));
    },
  );

  testWidgets(
    'Motion.of is zero while «remove animations» is on, and follows a change of the setting',
    (t) async {
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      late BuildContext context;
      Future<void> pump() => t.pumpWidget(
        MediaQuery.fromView(
          view: t.view,
          child: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );

      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await pump();
      expect(Motion.reduced(context), isFalse);
      expect(Motion.of(context, Motion.barIn), Motion.barIn);

      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await t.pump();
      expect(Motion.reduced(context), isTrue);
      expect(Motion.of(context, Motion.barIn), Duration.zero);
      expect(Motion.of(context, Motion.edgeTurn), Duration.zero);

      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await t.pump();
      expect(Motion.of(context, Motion.jump), Motion.jump);
    },
  );
}
