// Feature 010 T041 (FR-013, FR-014, SC-005): with the phone's «remove animations» on, nothing this feature added moves: the
// bars and the card reach their end state in the first frame after they start; flipping the setting between two motions
// changes the next one; a rotation and a resume replay nothing; the framework's own route, sheet and snack bar
// transitions are left alone. (The jump, the bookmark icon, the wird name, the look change and the edge turn have their
// own «remove animations» tests; the last test here checks that they exist.)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/theme.dart';

import '../support/motion_harness.dart';

const _top = ValueKey('top-bar');
const _bottom = ValueKey('bottom-bar');
const _card = ValueKey('today-card');
const _barrier = ValueKey('today-barrier');

/// How opaque [key] is drawn: its nearest FadeTransition, or 1 when it has none.
double _opacity(WidgetTester t, Key key) {
  final fades = find.ancestor(
    of: find.byKey(key),
    matching: find.byType(FadeTransition),
  );
  if (fades.evaluate().isEmpty) return 1;
  return t.widget<FadeTransition>(fades.first).opacity.value;
}

void _reduceMotion(WidgetTester t, {required bool on}) {
  t.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: on);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  testWidgets('the bars go and come back in the first frame after a tap', (
    t,
  ) async {
    _reduceMotion(t, on: true);
    await pumpMotionReader(t, startPage: 50, withWird: false);
    final centre = t.getCenter(find.byType(PageView));

    await t.tapAt(centre);
    await t.pump();
    expect(find.byKey(_top), findsNothing);
    expect(find.byKey(_bottom), findsNothing);

    await t.tapAt(centre);
    await t.pump();
    expect(find.byKey(_top), findsOneWidget);
    expect(find.byKey(_bottom), findsOneWidget);
    expect(_opacity(t, _top), 1);
    expect(_opacity(t, _bottom), 1);
  });

  testWidgets('the «ملخص اليوم» card opens and closes in the first frame', (
    t,
  ) async {
    _reduceMotion(t, on: true);
    await pumpMotionReader(t, startPage: 50, withWird: true);

    await t.tap(find.byKey(const ValueKey('today-chip')));
    await t.pump();
    expect(find.byKey(_card), findsOneWidget);
    expect(_opacity(t, _card), 1);
    expect(find.byKey(_barrier), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('today-close')));
    await t.pump();
    expect(find.byKey(_card), findsNothing);
    expect(find.byKey(_barrier), findsNothing);
  });

  testWidgets('flipping the setting between two motions changes the next one', (
    t,
  ) async {
    await pumpMotionReader(t, startPage: 50, withWird: false);
    final centre = t.getCenter(find.byType(PageView));

    // Animations on: the bars are still there, half way, 16 ms after the tap.
    await t.tapAt(centre);
    await t.pump();
    await t.pump(const Duration(milliseconds: 16));
    expect(find.byKey(_top), findsOneWidget);
    expect(_opacity(t, _top), lessThan(1));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(_top), findsNothing);

    // The setting goes on: the next motion is one frame.
    _reduceMotion(t, on: true);
    await t.pump();
    await t.tapAt(centre);
    await t.pump();
    expect(find.byKey(_top), findsOneWidget);
    expect(_opacity(t, _top), 1);

    // And off again: the motion after that takes time again.
    _reduceMotion(t, on: false);
    await t.pump();
    await t.tapAt(centre);
    await t.pump();
    await t.pump(const Duration(milliseconds: 16));
    expect(find.byKey(_top), findsOneWidget, reason: 'fading out again');
    expect(_opacity(t, _top), lessThan(1));
    await t.pump(const Duration(milliseconds: 300));
  });

  testWidgets(
    'a rotation and a resume replay nothing: the bars are whole in the first frame',
    (t) async {
      await pumpMotionReader(t, startPage: 50, withWird: false);
      expect(_opacity(t, _top), 1);

      // Rotation.
      t.view.physicalSize = const Size(915, 412);
      await t.pump();
      for (final key in [_top, _bottom]) {
        if (find.byKey(key).evaluate().isNotEmpty) {
          expect(_opacity(t, key), 1, reason: '$key after the rotation');
        }
      }
      t.view.physicalSize = const Size(412, 915);
      await t.pump();
      expect(find.byKey(_top), findsOneWidget);
      expect(_opacity(t, _top), 1, reason: 'back in portrait');

      // A trip to the background and back.
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(find.byKey(_top), findsOneWidget);
      expect(_opacity(t, _top), 1);
      expect(_opacity(t, _bottom), 1);
    },
  );

  testWidgets(
    'hidden bars stay hidden through a rotation, with no fade of their own',
    (t) async {
      await pumpMotionReader(t, startPage: 50, withWird: false);
      await t.tapAt(t.getCenter(find.byType(PageView)));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byKey(_top), findsNothing);

      t.view.physicalSize = const Size(915, 412);
      await t.pump();
      // Whatever the other orientation's own setting is, it is in place in this frame: shown whole or not there.
      for (final key in [_top, _bottom]) {
        if (find.byKey(key).evaluate().isNotEmpty) {
          expect(_opacity(t, key), 1, reason: '$key in landscape');
        }
      }
    },
  );

  test('the theme\'s page transitions are the framework\'s, not replaced by this feature', () {
    final theme = buildAppTheme(look: AppLook.emerald);
    final builders = theme.pageTransitionsTheme.builders;
    final defaults = const PageTransitionsTheme().builders;
    expect(builders.keys.toSet(), defaults.keys.toSet());
    for (final platform in defaults.keys) {
      expect(
        builders[platform].runtimeType,
        defaults[platform].runtimeType,
        reason: '$platform',
      );
    }
    for (final f in Directory('lib/motion').listSync().whereType<File>()) {
      final text = f.readAsStringSync();
      expect(text, isNot(contains('PageTransitionsTheme')), reason: f.path);
      expect(text, isNot(contains('themeAnimationDuration')), reason: f.path);
    }
  });

  test('every motion has its own test with «remove animations» on', () {
    const files = [
      'test/motion/reader_jump_fade_test.dart',
      'test/motion/bookmark_icon_motion_test.dart',
      'test/motion/reader_wird_name_motion_test.dart',
      'test/motion/look_fade_test.dart',
      'test/motion/reader_edge_turn_reduced_test.dart',
    ];
    for (final path in files) {
      expect(
        File(path).readAsStringSync(),
        contains('remove animations'),
        reason: path,
      );
    }
  });
}
