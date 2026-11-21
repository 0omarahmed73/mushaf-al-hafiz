// Feature 010 T032 (FR-010): a jump (go-to-page, another wird) shows the new page at once and fades it in; the page
// between is never built; a jump to the page already shown and the first frame of a start play nothing.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/motion/jump_fade.dart';

import '../support/motion_geometry.dart';
import '../support/motion_harness.dart';

const _number = ValueKey('page-number');

String? _shownPage(WidgetTester t) {
  final found = find.byKey(_number).evaluate();
  if (found.length != 1) return null;
  return (found.single.widget as Text).data;
}

double _opacity(WidgetTester t) => t
    .widget<FadeTransition>(
      find
          .descendant(
            of: find.byType(JumpFade),
            matching: find.byType(FadeTransition),
          )
          .first,
    )
    .opacity
    .value;

Future<void> _askPage(WidgetTester t, String text) async {
  await t.tap(find.byKey(_number));
  await settleMotion(t, rounds: 4);
  await t.enterText(find.byKey(const ValueKey('goto-field')), text);
  await t.tap(find.byKey(const ValueKey('goto-go')));
}

/// Pumps frames of 16 ms until the page number says [page]; the opacity of that first frame is the result.
Future<double> _firstFrameOf(WidgetTester t, String page) async {
  for (var i = 0; i < 80; i++) {
    await t.pump(const Duration(milliseconds: 16));
    if (_shownPage(t) == page) return _opacity(t);
  }
  fail('page $page never appeared');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  testWidgets('a start plays nothing: the first frame is fully opaque', (
    t,
  ) async {
    await pumpMotionReader(t, startPage: 50, withWird: false);
    expect(_opacity(t), 1);
  });

  testWidgets(
    'go-to-page 50 to 300: the page is there in the first frame at about 0.35, opaque after 180 ms, no page built between',
    (t) async {
      final reader = await pumpMotionReader(t, startPage: 50, withWird: false);
      final juzBefore = t
          .widget<Text>(find.byKey(const ValueKey('juz-hizb')))
          .data;
      await _askPage(t, '300');
      reader.probe.phase = 'jump';
      final first = await _firstFrameOf(t, '300');
      expect(first, closeTo(0.35, 0.06), reason: 'first frame of the arrival');
      expect(
        t.widget<Text>(find.byKey(const ValueKey('juz-hizb'))).data,
        isNot(juzBefore),
        reason: 'the top line shows page 300 at once, the bar does not fade',
      );
      await t.pump(const Duration(milliseconds: 80));
      expect(_opacity(t), allOf(greaterThan(0.4), lessThan(1)));
      await t.pump(const Duration(milliseconds: 120));
      expect(_opacity(t), 1);
      await settleMotion(t, rounds: 6);
      reader.probe.phase = null;
      expect(
        reader.probe.count('jump', 'MushafPage'),
        lessThanOrEqualTo(3),
        reason: 'page 300 and its two neighbours, nothing between 50 and 300',
      );
      final saved = await t.runAsync(reader.repo.lastViewedPage);
      expect(saved, 300);
    },
  );

  testWidgets('the page area does not move while the new page fades in', (
    t,
  ) async {
    await pumpMotionReader(t, startPage: 50, withWird: false);
    final before = <String, Rect>{'pager': pageRects(t)['pager']!};
    await _askPage(t, '300');
    await _firstFrameOf(t, '300');
    await expectRectsStable(t, before, frames: 14, reason: 'jump fade');
  });

  testWidgets('a jump to the page already shown plays nothing', (t) async {
    await pumpMotionReader(t, startPage: 50, withWird: false);
    await _askPage(t, '50');
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 16));
      expect(_opacity(t), 1);
    }
    expect(_shownPage(t), '50');
  });

  testWidgets('a wird chosen in «أوراد» shows its page and fades it in', (
    t,
  ) async {
    await pumpMotionReader(t, startPage: 50, withWird: true, secondWird: true);
    await t.tap(find.text('أوراد').last);
    await settleMotion(t, rounds: 6);
    // The wirds screen shows the name twice (the today card above and the list below); the list row opens the wird.
    await t.tap(find.text('ورد الاختبار').last);
    final first = await _firstFrameOf(t, '120');
    expect(first, closeTo(0.35, 0.06));
    await t.pump(const Duration(milliseconds: 200));
    expect(_opacity(t), 1);
  });

  testWidgets(
    'with «remove animations» on the new page is opaque in the first frame',
    (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await pumpMotionReader(t, startPage: 50, withWird: false);
      await _askPage(t, '300');
      final first = await _firstFrameOf(t, '300');
      expect(first, 1);
    },
  );
}
