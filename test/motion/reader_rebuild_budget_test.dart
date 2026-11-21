// Feature 010 T010 (SC-003): a Mushaf page that is already drawn is not rebuilt for a reason that is not its own. A page
// turn builds the incoming page once at most; a bar tap, the today card and the database's answers build no page at all.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/motion_harness.dart';

String _pageNumber(WidgetTester t) =>
    t.widget<Text>(find.byKey(const ValueKey('page-number')).first).data!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final withWird in [false, true]) {
    final mode = withWird ? 'wird mode' : 'browse mode';
    testWidgets('a page turn builds MushafPage at most once in $mode', (
      t,
    ) async {
      final reader = await pumpMotionReader(
        t,
        startPage: 50,
        withWird: withWird,
      );
      for (var i = 1; i <= 3; i++) {
        await reader.swipeToNext(t, prefix: 'turn$i-');
        expect(
          reader.probe.countAll('turn$i-', 'MushafPage'),
          lessThanOrEqualTo(1),
          reason:
              'turn $i: only the incoming page (or the next neighbour) may be built, none that is drawn',
        );
      }
      expect(_pageNumber(t), '53');
    });
  }

  testWidgets(
    'four taps on the page (bars hide, show, hide, show) build MushafPage 0 times',
    (t) async {
      final reader = await pumpMotionReader(t, startPage: 50, withWird: false);
      final centre = t.getCenter(find.byType(PageView));
      for (var i = 1; i <= 4; i++) {
        reader.probe.phase = 'tap$i';
        await t.tapAt(centre);
        for (var f = 0; f < 20; f++) {
          await t.pump(const Duration(milliseconds: 16));
        }
      }
      reader.probe.phase = null;
      expect(reader.probe.countAll('tap', 'MushafPage'), 0);
    },
  );

  testWidgets('opening and closing the today card builds MushafPage 0 times', (
    t,
  ) async {
    final reader = await pumpMotionReader(t, startPage: 50, withWird: true);
    reader.probe.phase = 'card';
    await t.tap(find.byKey(const ValueKey('today-chip')));
    await settleMotion(t, rounds: 4);
    expect(find.byKey(const ValueKey('today-card')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('today-close')));
    await settleMotion(t, rounds: 4);
    expect(find.byKey(const ValueKey('today-card')), findsNothing);
    reader.probe.phase = null;
    expect(reader.probe.countAll('card', 'MushafPage'), 0);
  });
}
