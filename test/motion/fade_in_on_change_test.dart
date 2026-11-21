// Feature 010 T030: the bookmark icon and the wird name fade in when they change, one child at a time.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/motion/fade_in_on_change.dart';

Widget _host(String value, {double fromScale = 1}) => MediaQuery.fromView(
  view: TestWidgetsFlutterBinding.instance.platformDispatcher.views.first,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: FadeInOnChange(
        value: value,
        fromScale: fromScale,
        child: Text(value),
      ),
    ),
  ),
);

double _opacity(WidgetTester t) => t
    .widget<FadeTransition>(
      find.descendant(
        of: find.byType(FadeInOnChange),
        matching: find.byType(FadeTransition),
      ),
    )
    .opacity
    .value;

void main() {
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  testWidgets('the first build shows the child as it is', (t) async {
    await t.pumpWidget(_host('a'));
    expect(find.text('a'), findsOneWidget);
    expect(_opacity(t), 1);
  });

  testWidgets(
    'a new value shows the new child at once at opacity 0 and reaches 1 after 160 ms, one child at any time',
    (t) async {
      await t.pumpWidget(_host('a'));
      await t.pumpWidget(_host('b'));
      expect(find.text('b'), findsOneWidget);
      expect(find.text('a'), findsNothing);
      expect(_opacity(t), 0);
      await t.pump(const Duration(milliseconds: 80));
      expect(_opacity(t), allOf(greaterThan(0), lessThan(1)));
      expect(find.text('a'), findsNothing);
      await t.pump(const Duration(milliseconds: 100));
      expect(_opacity(t), 1);
    },
  );

  testWidgets('with fromScale 0.8 the child grows to full size', (t) async {
    // getSize does not see a Transform, the corners on the screen do.
    double width(String text) =>
        t.getBottomRight(find.text(text)).dx - t.getTopLeft(find.text(text)).dx;
    await t.pumpWidget(_host('a', fromScale: 0.8));
    final full = width('a');
    await t.pumpWidget(_host('b', fromScale: 0.8));
    expect(width('b'), closeTo(full * 0.8, full * 0.1));
    await t.pump(const Duration(milliseconds: 200));
    expect(width('b'), closeTo(full, 0.5));
  });

  testWidgets('a rebuild with the same value does not restart it', (t) async {
    await t.pumpWidget(_host('a'));
    await t.pumpWidget(_host('b'));
    await t.pump(const Duration(milliseconds: 200));
    await t.pumpWidget(_host('b'));
    expect(_opacity(t), 1);
  });

  testWidgets(
    'with «remove animations» on the new child is complete in the same frame',
    (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await t.pumpWidget(_host('a'));
      await t.pumpWidget(_host('b'));
      expect(_opacity(t), 1);
    },
  );
}
