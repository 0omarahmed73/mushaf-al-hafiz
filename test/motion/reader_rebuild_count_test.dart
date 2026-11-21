// Feature 010 measurement M4: how often the reader rebuilds its widgets for one page turn, and how long the frames of a
// swipe take in the test VM (research.md H1, H4). Counts come from the framework's `debugOnRebuildDirtyWidget`; they do
// not depend on the machine. Frame times do (JIT, asserts on): read them as relative. Only generous bounds are asserted.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/motion_harness.dart';
import '../support/motion_probe.dart';

const _watch = [
  'ReaderScreen',
  'Scaffold',
  'PageView',
  'ListenableBuilder',
  '_PageItem',
  'MushafPageCard',
  'MushafPage',
  'Text',
  '_TopBar',
  '_BottomBar',
];

String _pageNumber(WidgetTester t) =>
    t.widget<Text>(find.byKey(const ValueKey('page-number')).first).data!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final withWird in [false, true]) {
    final mode = withWird ? 'wird mode' : 'browse mode';
    testWidgets(
      'M4a: three swipes to the next page in $mode (database answers after 8 ms)',
      (t) async {
        final reader = await pumpMotionReader(
          t,
          startPage: 50,
          withWird: withWird,
        );
        expect(_pageNumber(t), '50');
        final turns = <SwipeTrace>[];
        for (var i = 0; i < 3; i++) {
          turns.add(await reader.swipeToNext(t, prefix: 'turn${i + 1}-'));
        }
        expect(_pageNumber(t), '53', reason: 'three swipes, three pages');
        reader.probe.log('M4a $mode', _watch);

        for (var i = 0; i < turns.length; i++) {
          final trace = turns[i];
          motionLog(
            'M4a $mode turn ${i + 1}: whole-screen rebuilds=${trace.screenTotal} in ${trace.framesWithScreenRebuild} different frames, '
            'MushafPage rebuilds=${trace.pagesTotal}, Text rebuilds=${reader.probe.countAll('turn${i + 1}-', 'Text')}',
          );
          motionLog(
            'M4a $mode turn ${i + 1}: frames with a MushafPage rebuild (frame index:count) '
            '${[for (var f = 0; f < trace.pageRebuilds.length; f++)
              if (trace.pageRebuilds[f] > 0) '$f:${trace.pageRebuilds[f]}'].join(' ')}; '
            'frames pumped ${MotionStats(trace.frameMs)}; slowest three (frame:ms) ${(List.generate(trace.frameMs.length, (f) => f)..sort((a, b) => trace.frameMs[b].compareTo(trace.frameMs[a]))).take(3).map((f) => '$f:${trace.frameMs[f].toStringAsFixed(1)}').join(' ')}',
          );
        }
        if (withWird) {
          final active = await t.runAsync(() => reader.repo.activeWird());
          expect(
            active!.currentPage,
            53,
            reason: 'the wird moved with the swipes, so the database path ran',
          );
        }
        // After feature 010 (T010, T011, T012): a page turn builds at most the one new neighbour that appears at its end,
        // never the pager, and the screen only when the database answers (before: 3 and 5 page builds, 1 and 2 screens).
        for (var i = 0; i < turns.length; i++) {
          final prefix = 'turn${i + 1}-';
          expect(
            turns[i].pagesTotal,
            lessThanOrEqualTo(1),
            reason: 'turn ${i + 1}: MushafPage builds',
          );
          expect(reader.probe.countAll(prefix, 'PageView'), 0);
          expect(
            turns[i].screenTotal,
            withWird ? lessThanOrEqualTo(2) : 0,
            reason: 'turn ${i + 1}: Scaffold rebuilds',
          );
          expect(reader.probe.countAll(prefix, '_BottomBar'), 0);
        }
      },
    );
  }

  testWidgets('M4b: showing and hiding the bars with a tap (browse mode)', (
    t,
  ) async {
    final reader = await pumpMotionReader(t, startPage: 50, withWird: false);
    final centre = t.getCenter(find.byType(PageView));
    final frames = <double>[];
    for (var i = 0; i < 4; i++) {
      reader.probe.phase = 'tap${i + 1}';
      await t.tapAt(centre);
      for (var f = 0; f < 6; f++) {
        final s = Stopwatch()..start();
        await t.pump(const Duration(milliseconds: 16));
        s.stop();
        frames.add(ms(s));
      }
    }
    reader.probe.phase = null;
    reader.probe.log('M4b bars toggle', _watch);
    motionLog('M4b bars toggle frames pumped: ${MotionStats(frames)}');
    final pageRebuilds = reader.probe.countAll('tap', 'MushafPage');
    motionLog(
      'M4b MushafPage rebuilds for 4 taps on the page (bars hide, show, hide, show): $pageRebuilds',
    );
    expect(
      find.byKey(const ValueKey('top-bar')),
      findsOneWidget,
      reason: 'the bars start shown; four taps hide, show, hide, show',
    );
    expect(
      pageRebuilds,
      0,
      reason: 'a bar tap rebuilds no page (before: 1 build and 500 to 650 elements)',
    );
    expect(reader.probe.countAll('tap', 'PageView'), 0);
  });
}
