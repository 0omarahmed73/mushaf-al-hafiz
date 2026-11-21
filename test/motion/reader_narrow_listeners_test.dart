// Feature 010 T011 (FR-004): the reader no longer rebuilds all its widgets on every change of its state. A page turn
// rebuilds the top line and nothing else; a bar tap or the answer of the database does not rebuild the pager.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/motion_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final withWird in [false, true]) {
    final mode = withWird ? 'wird mode' : 'browse mode';
    testWidgets(
      'a page turn in $mode rebuilds the top line, not the pager, the bottom bar or the screen',
      (t) async {
        final reader = await pumpMotionReader(
          t,
          startPage: 50,
          withWird: withWird,
        );
        await reader.swipeToNext(t, prefix: 'turn-');
        expect(
          reader.probe.countAll('turn-', '_TopBar'),
          greaterThanOrEqualTo(1),
          reason: 'the page number and the surah changed',
        );
        expect(reader.probe.countAll('turn-', 'PageView'), 0);
        expect(
          reader.probe.countAll('turn-', 'Scaffold'),
          withWird ? lessThanOrEqualTo(2) : 0,
        );
        if (!withWird) {
          expect(reader.probe.countAll('turn-', '_BottomBar'), 0);
        }
      },
    );
  }

  testWidgets('a tap on the page does not rebuild the pager', (t) async {
    final reader = await pumpMotionReader(t, startPage: 50, withWird: false);
    reader.probe.phase = 'tap';
    await t.tapAt(t.getCenter(find.byType(PageView)));
    for (var f = 0; f < 20; f++) {
      await t.pump(const Duration(milliseconds: 16));
    }
    reader.probe.phase = null;
    expect(reader.probe.count('tap', 'PageView'), 0);
    expect(reader.probe.count('tap', 'MushafPage'), 0);
  });

  testWidgets(
    'the answer of the database after a turn (the today list) does not rebuild the pager',
    (t) async {
      final reader = await pumpMotionReader(t, startPage: 50, withWird: true);
      await reader.swipeToNext(t, prefix: 'turn-');
      expect(reader.probe.countAll('turn-', 'PageView'), 0);
    },
  );
}
