// Feature 010 T020: the fade and slide of a bar or a card that appears or goes (contracts/ui.md).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/motion/fade_slide_switcher.dart';

const _key = ValueKey('content');

Widget _host(Widget? child, {bool animate = true, double slide = -24}) =>
    MediaQuery.fromView(
      view: TestWidgetsFlutterBinding.instance.platformDispatcher.views.first,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 80,
            child: FadeSlideSwitcher(
              slide: slide,
              animate: animate,
              child: child,
            ),
          ),
        ),
      ),
    );

const Widget _content = SizedBox(key: _key, width: 100, height: 40);

double _opacity(WidgetTester t) {
  final fade = t.widget<FadeTransition>(
    find.descendant(
      of: find.byType(FadeSlideSwitcher),
      matching: find.byType(FadeTransition),
    ),
  );
  return fade.opacity.value;
}

double _dy(WidgetTester t) => t.getTopLeft(find.byKey(_key)).dy;

void main() {
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  testWidgets('a child present from the start is shown at once, with no fade', (
    t,
  ) async {
    await t.pumpWidget(_host(_content));
    expect(find.byKey(_key), findsOneWidget);
    expect(_opacity(t), 1);
  });

  testWidgets(
    'a child that appears is transparent and above its place in the first frame, and arrives in 200 ms',
    (t) async {
      await t.pumpWidget(_host(null));
      expect(find.byKey(_key), findsNothing);
      await t.pumpWidget(_host(_content));
      await t.pump();
      // The slot is 80 dp high in a 600 dp screen: its top is at 260 dp, and the child starts 24 dp above it.
      expect(_dy(t), closeTo(260 - 24, 0.5));
      expect(_opacity(t), lessThan(0.2));
      await t.pump(const Duration(milliseconds: 100));
      expect(_opacity(t), allOf(greaterThan(0.2), lessThan(1)));
      expect(
        _dy(t),
        allOf(greaterThan(236), lessThan(260)),
        reason: 'it is still on its way',
      );
      await t.pump(const Duration(milliseconds: 120));
      expect(_opacity(t), 1);
      expect(
        _dy(t),
        closeTo(260, 0.01),
        reason: 'the slot is 80 dp high, its top is at 260 dp: no offset left',
      );
    },
  );

  testWidgets(
    'a child that goes ignores taps and is hidden from readers while it leaves, and is gone after 160 ms',
    (t) async {
      var taps = 0;
      final tappable = GestureDetector(
        key: _key,
        onTap: () => taps++,
        child: const SizedBox(width: 100, height: 40),
      );
      await t.pumpWidget(_host(tappable));
      await t.pumpWidget(_host(null));
      await t.pump(const Duration(milliseconds: 80));
      expect(find.byKey(_key), findsOneWidget, reason: 'still fading out');
      expect(_opacity(t), allOf(greaterThan(0), lessThan(1)));
      await t.tap(find.byKey(_key), warnIfMissed: false);
      expect(taps, 0, reason: 'a leaving child does not catch taps');
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byKey(_key), findsNothing);
    },
  );

  testWidgets(
    'a reversal in the middle starts from where it is and the child stays',
    (t) async {
      await t.pumpWidget(_host(null));
      await t.pumpWidget(_host(_content));
      await t.pump();
      await t.pump(const Duration(milliseconds: 80));
      final before = _opacity(t);
      await t.pumpWidget(_host(null));
      await t.pump(const Duration(milliseconds: 16));
      expect(find.byKey(_key), findsOneWidget);
      expect(_opacity(t), lessThan(before));
      await t.pumpWidget(_host(_content));
      await t.pump(const Duration(milliseconds: 400));
      expect(_opacity(t), 1);
      expect(find.byKey(_key), findsOneWidget);
    },
  );

  testWidgets(
    'a change that is not animated (a rotation, a resume) happens at once',
    (t) async {
      await t.pumpWidget(_host(_content));
      await t.pumpWidget(_host(null, animate: false));
      expect(find.byKey(_key), findsNothing);
      await t.pumpWidget(_host(_content, animate: false));
      expect(find.byKey(_key), findsOneWidget);
      expect(_opacity(t), 1);
    },
  );

  testWidgets(
    'with «remove animations» on both directions finish in the next frame',
    (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await t.pumpWidget(_host(null));
      await t.pumpWidget(_host(_content));
      expect(find.byKey(_key), findsOneWidget);
      expect(_opacity(t), 1);
      await t.pumpWidget(_host(null));
      expect(find.byKey(_key), findsNothing);
    },
  );
}
