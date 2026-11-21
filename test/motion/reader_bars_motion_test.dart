// Feature 010 T021 (FR-008, SC-004): the bars fade and slide a little when they come and go, and the page never moves.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/settings/settings_screen.dart';

import '../support/motion_geometry.dart';
import '../support/motion_harness.dart';

const _top = ValueKey('top-bar');
const _bottom = ValueKey('bottom-bar');

double _opacity(WidgetTester t, Key key) => t
    .widget<FadeTransition>(
      find
          .ancestor(of: find.byKey(key), matching: find.byType(FadeTransition))
          .first,
    )
    .opacity
    .value;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  testWidgets(
    'a tap hides both bars with a fade (160 ms) and a second tap brings them back (200 ms)',
    (t) async {
      await pumpMotionReader(t, startPage: 50, withWird: false);
      final centre = t.getCenter(find.byType(PageView));
      expect(_opacity(t, _top), 1);

      await t.tapAt(centre);
      await t.pump();
      await t.pump(const Duration(milliseconds: 80));
      expect(find.byKey(_top), findsOneWidget, reason: 'still fading out');
      expect(find.byKey(_bottom), findsOneWidget);
      expect(_opacity(t, _top), allOf(greaterThan(0), lessThan(1)));
      await t.pump(const Duration(milliseconds: 170));
      expect(find.byKey(_top), findsNothing);
      expect(find.byKey(_bottom), findsNothing);

      await t.tapAt(centre);
      await t.pump();
      expect(find.byKey(_top), findsOneWidget);
      expect(_opacity(t, _top), lessThan(0.3));
      await t.pump(const Duration(milliseconds: 100));
      expect(_opacity(t, _top), allOf(greaterThan(0.3), lessThan(1)));
      await t.pump(const Duration(milliseconds: 120));
      expect(_opacity(t, _top), 1);
      expect(_opacity(t, _bottom), 1);
    },
  );

  testWidgets('a bar that is leaving does not catch taps', (t) async {
    await pumpMotionReader(t, startPage: 50, withWird: false);
    await t.tapAt(t.getCenter(find.byType(PageView)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 60));
    await t.tap(
      find.byKey(const ValueKey('open-settings')),
      warnIfMissed: false,
    );
    await settleMotion(t, rounds: 3);
    expect(
      find.byType(SettingsScreen),
      findsNothing,
      reason: 'the leaving bottom bar ignored the tap',
    );
  });

  testWidgets(
    'a tap in the middle of the fade reverses it and the bars end shown',
    (t) async {
      await pumpMotionReader(t, startPage: 50, withWird: false);
      final centre = t.getCenter(find.byType(PageView));
      await t.tapAt(centre);
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      final mid = _opacity(t, _top);
      await t.tapAt(centre);
      await t.pump(const Duration(milliseconds: 16));
      expect(find.byKey(_top), findsOneWidget);
      expect(_opacity(t, _top), greaterThan(mid * 0.5));
      await t.pump(const Duration(milliseconds: 400));
      expect(_opacity(t, _top), 1);
    },
  );

  testWidgets(
    'the page area and every line and word are exactly where they were in every frame',
    (t) async {
      await pumpMotionReader(t, startPage: 50, withWird: false);
      final before = pageRects(t);
      expect(
        before.length,
        greaterThan(100),
        reason: 'the lines and the words were read',
      );
      await t.tapAt(t.getCenter(find.byType(PageView)));
      await expectRectsStable(t, before, reason: 'bars leaving');
      await t.tapAt(t.getCenter(find.byType(PageView)));
      await expectRectsStable(t, before, reason: 'bars arriving');
    },
  );

  testWidgets('a rotation changes the bars at once, with no animation', (
    t,
  ) async {
    await pumpMotionReader(t, startPage: 50, withWird: false);
    expect(find.byKey(_top), findsOneWidget);
    t.view.physicalSize = const Size(915, 412);
    await t.pump();
    // Landscape shows the bars too (the owner's change of 2026-11-21), whole in the first frame: nothing fades on a rotation.
    expect(find.byKey(_top), findsOneWidget);
    expect(find.byKey(_bottom), findsOneWidget);
    expect(_opacity(t, _top), 1);
    expect(_opacity(t, _bottom), 1);
  });

  testWidgets(
    'with «remove animations» on a tap shows and hides the bars in the next frame',
    (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await pumpMotionReader(t, startPage: 50, withWird: false);
      final centre = t.getCenter(find.byType(PageView));
      await t.tapAt(centre);
      await t.pump();
      expect(find.byKey(_top), findsNothing);
      expect(find.byKey(_bottom), findsNothing);
      await t.tapAt(centre);
      await t.pump();
      expect(find.byKey(_top), findsOneWidget);
      expect(_opacity(t, _top), 1);
    },
  );
}
