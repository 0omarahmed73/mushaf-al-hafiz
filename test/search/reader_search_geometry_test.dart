// Feature 011 T047, the geometry after the feature (test-only): with the search wired in, the reader's top bar, pager, lines
// and words on pages 42 and 293 at 412 x 915 are where T001 recorded them on the unchanged code (the literals of
// test/search/search_baseline_test.dart, a tolerance of 0.01): as the reader opens, with a found ayah highlighted (chosen
// through the index and the search screen) and after the highlight is cleared, in both looks (spec FR-018, FR-030, SC-008;
// Constitution I).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/mushaf/index_screen.dart';
import 'package:mushaf/search/ayah_target.dart';
import 'package:mushaf/search/search_screen.dart';

import '../support/motion_geometry.dart';
import '../support/reader_harness.dart';
import '../support/reader_search_harness.dart';
import '../support/search_harness.dart';
import 'search_baseline_test.dart' show kBaseline, kTolerance;

/// The page, an ayah on it and what is typed to find it.
const _cases = [
  (42, AyahRef(2, 255), 'الله لا اله الا هو الحي القيوم'),
  (293, AyahRef(18, 1), 'الحمد لله الذي انزل على عبده الكتاب'),
];

List<double> _box(Rect r) => [r.left, r.top, r.width, r.height];

/// What T001 measured in the reader: the top bar, the pager, every line and every word of the page shown.
Map<String, List<double>> _readerBoxes(WidgetTester t) => {
  'top-bar': _box(t.getRect(find.byKey(const ValueKey('top-bar')))),
  for (final e in pageRects(t).entries) e.key: _box(e.value),
};

void _expectBaseline(WidgetTester t, int page, String when) {
  final name = 'reader/412x915/page-$page';
  final was = kBaseline[name]!;
  final now = _readerBoxes(t);
  expect(now.keys.toSet(), was.keys.toSet(), reason: '$name $when: the set');
  const parts = ['left', 'top', 'width', 'height'];
  for (final key in was.keys) {
    for (var i = 0; i < 4; i++) {
      expect(
        now[key]![i],
        closeTo(was[key]![i], kTolerance),
        reason: '$name $when / $key / ${parts[i]}',
      );
    }
  }
}

/// A pointer goes down on the page and is cancelled: the touch that ends the found ayah's highlight, and nothing else.
Future<void> _touchPage(WidgetTester t) async {
  final gesture = await t.startGesture(t.getCenter(find.byType(PageView)));
  await t.pump(const Duration(milliseconds: 20));
  await gesture.cancel();
  await settleReader(t);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await preloadReaderPages();
    await realIndex();
  });

  for (final look in [LookChoice.emerald, LookChoice.night]) {
    for (final (page, ref, query) in _cases) {
      group('${look.name}, page $page', () {
        testWidgets(
          'with the feature present the reader is where T001 saw it',
          (t) async {
            await pumpSearchReader(t, startPage: page, look: look);
            expect(cardHighlight(t, page), isEmpty);
            _expectBaseline(t, page, 'as opened');
          },
        );

        testWidgets(
          '${ref.key} found through the search: highlighted, then cleared, nothing moved',
          (t) async {
            await pumpSearchReader(t, startPage: page, look: look);
            final ids = await idsOn(t, page, ref);
            expect(ids, isNotEmpty);

            await t.tap(keyed('open-index'));
            await settleReader(t);
            await t.tap(find.byKey(const ValueKey('open-search')));
            await settleReader(t);
            await typeQuery(t, query);
            await t.tap(find.byKey(ValueKey('ayah-row-${ref.key}')));
            await settleReader(t);

            expect(find.byType(SearchScreen), findsNothing);
            expect(find.byType(IndexScreen), findsNothing);
            expect(shownPage(t), '$page');
            expect(cardHighlight(t, page), ids, reason: 'highlighted');
            _expectBaseline(t, page, 'with ${ref.key} highlighted');

            await _touchPage(t);
            expect(cardHighlight(t, page), isEmpty, reason: 'cleared');
            _expectBaseline(t, page, 'after the highlight is cleared');
          },
        );

        testWidgets('the search opened and closed with back: nothing moved', (
          t,
        ) async {
          await pumpSearchReader(t, startPage: page, look: look);
          await t.tap(keyed('open-index'));
          await settleReader(t);
          await t.tap(find.byKey(const ValueKey('open-search')));
          await settleReader(t);
          await typeQuery(t, query);
          await t.binding.handlePopRoute();
          await settleReader(t);
          await t.binding.handlePopRoute();
          await settleReader(t);
          expect(find.byType(IndexScreen), findsNothing);
          _expectBaseline(t, page, 'after search was left with back');
        });
      });
    }
  }

  testWidgets(
    'a target handed over by the index route itself leaves page 42 where T001 saw it (emerald)',
    (t) async {
      await pumpSearchReader(t, startPage: 42);
      await popIndexWith(t, const AyahTarget(AyahRef(2, 255), 42));
      expect(highlightedBoxes(t), greaterThan(0));
      _expectBaseline(t, 42, 'with the found ayah highlighted');
    },
  );
}
