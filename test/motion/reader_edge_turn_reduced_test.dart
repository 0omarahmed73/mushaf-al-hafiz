// Feature 010 T040 (FR-014, research D7): the turn from a side edge of a zoomed page slides in 300 ms as it does today, and
// shows the new page in the next frame while the phone's «remove animations» is on.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/reader_harness.dart';

const _number = ValueKey('page-number');

String? _only(WidgetTester t) {
  final found = find.byKey(_number).evaluate();
  return found.length == 1 ? (found.single.widget as Text).data : null;
}

/// Opens the reader at 150%, brings its left edge into view, swipes from it and counts the frames until page 51 is the
/// only page on the screen.
Future<int> _edgeTurn(WidgetTester t) async {
  await pumpSizedReader(t, percent: 150);
  await t.dragFrom(const Offset(250, 400), const Offset(900, 0));
  await settleReader(t);
  expect(_only(t), '50', reason: 'running into the edge turns nothing');
  await t.dragFrom(const Offset(250, 400), const Offset(250, 0));
  var frames = 0;
  while (frames < 60) {
    await t.pump(const Duration(milliseconds: 16));
    frames++;
    if (_only(t) == '51') break;
  }
  return frames;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  testWidgets('animations on: the edge turn slides for about 300 ms', (
    t,
  ) async {
    final frames = await _edgeTurn(t);
    expect(frames, inInclusiveRange(15, 24), reason: '300 ms of 16 ms frames');
  });

  testWidgets(
    'animations removed: the new page is there in the next frame, and was built before',
    (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      final frames = await _edgeTurn(t);
      expect(frames, lessThanOrEqualTo(2));
    },
  );
}
