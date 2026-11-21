// Feature 010 T031: the soft arrival of a page after a jump (contracts/ui.md: 0.35 to 1.0 over 180 ms, easeOut).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/motion/jump_fade.dart';

Widget _host(JumpFadeController c) => MediaQuery.fromView(
  view: TestWidgetsFlutterBinding.instance.platformDispatcher.views.first,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: JumpFade(
      controller: c,
      child: const SizedBox(width: 50, height: 50),
    ),
  ),
);

double _opacity(WidgetTester t) =>
    t.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value;

void main() {
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  testWidgets(
    'nothing plays by itself: the first frame of a start is fully opaque',
    (t) async {
      final c = JumpFadeController();
      addTearDown(c.dispose);
      await t.pumpWidget(_host(c));
      expect(_opacity(t), 1);
      await t.pump(const Duration(milliseconds: 300));
      expect(_opacity(t), 1);
    },
  );

  testWidgets(
    'play() makes the child 0.35 opaque in the first frame and 1.0 after 180 ms',
    (t) async {
      final c = JumpFadeController();
      addTearDown(c.dispose);
      await t.pumpWidget(_host(c));
      c.play();
      await t.pump();
      expect(_opacity(t), closeTo(0.35, 0.02));
      await t.pump(const Duration(milliseconds: 90));
      expect(_opacity(t), allOf(greaterThan(0.5), lessThan(1)));
      await t.pump(const Duration(milliseconds: 100));
      expect(_opacity(t), 1);
    },
  );

  testWidgets('a second play in the middle starts again', (t) async {
    final c = JumpFadeController();
    addTearDown(c.dispose);
    await t.pumpWidget(_host(c));
    c.play();
    await t.pump();
    await t.pump(const Duration(milliseconds: 120));
    c.play();
    await t.pump();
    expect(_opacity(t), closeTo(0.35, 0.02));
    await t.pump(const Duration(milliseconds: 200));
    expect(_opacity(t), 1);
  });

  testWidgets(
    'with «remove animations» on the page is opaque in the next frame',
    (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      final c = JumpFadeController();
      addTearDown(c.dispose);
      await t.pumpWidget(_host(c));
      c.play();
      await t.pump();
      expect(_opacity(t), 1);
    },
  );

  testWidgets('disposing in the middle of the fade is clean', (t) async {
    final c = JumpFadeController();
    addTearDown(c.dispose);
    await t.pumpWidget(_host(c));
    c.play();
    await t.pump(const Duration(milliseconds: 50));
    await t.pumpWidget(const SizedBox());
    c.play();
    await t.pump(const Duration(milliseconds: 300));
  });
}
