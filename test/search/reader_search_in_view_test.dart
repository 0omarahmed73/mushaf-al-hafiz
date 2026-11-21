// Feature 011 T043 (window [R4]): the found ayah is brought into view when the reader shows it, at every reading size and in both
// orientations, also when the page is taller or wider than the screen (spec FR-013, US6 scenario 5, SC-008; research D4). The reader
// hands `PageReveal(ids, token)` to the `PageViewport` of the highlighted page only; what `PageViewport` does with it is T040's.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/index_screen.dart';
import 'package:mushaf/search/ayah_target.dart';

import '../support/motion_geometry.dart';
import '../support/reader_harness.dart';
import '../support/reader_search_harness.dart';

const Size _portrait = Size(412, 915);
const Size _landscape = Size(915, 412);

/// A landscape narrow enough that the page at 150% is wider than the screen (900 dp of page, 700 dp of screen): the only
/// landscape in which the page moves sideways as well as up and down.
const Size _narrowLandscape = Size(700, 360);

/// The ayahs of the task: Ayat al-Kursi in the middle of page 42, the second ayah of the page with the longest ayah (2:282 fills page
/// 48), and 18:10, which is on page 294 (page 293 is where al-Kahf begins, with 18:1 to 18:4).
const _targets = [
  (AyahRef(2, 255), 42),
  (AyahRef(18, 10), 294),
  (AyahRef(2, 282), 48),
];

Rect _rect(WidgetTester t, int id) => t.getRect(find.byKey(ValueKey('w$id')));

bool _inside(Rect outer, Rect inner) =>
    inner.left >= outer.left - 0.5 &&
    inner.top >= outer.top - 0.5 &&
    inner.right <= outer.right + 0.5 &&
    inner.bottom <= outer.bottom + 0.5;

/// A pointer goes down on [at] and is cancelled: only the pointer-down, which ends the highlight.
Future<void> _touch(WidgetTester t, Offset at) async {
  final gesture = await t.startGesture(at);
  await t.pump(const Duration(milliseconds: 20));
  await gesture.cancel();
  await t.pump(const Duration(milliseconds: 20));
}

double _zoom(WidgetTester t) => t
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!
    .value
    .getMaxScaleOnAxis();

/// The first word of [ids] is inside the pager, so is the first line of the ayah, and all the words are when they can all be.
void _expectInView(WidgetTester t, Set<int> ids, String reason) {
  final pager = t.getRect(find.byType(PageView));
  final first = _rect(t, ids.first);
  expect(
    _inside(pager, first),
    isTrue,
    reason: '$reason: the first word $first is not inside the pager $pager',
  );
  // The first line of the ayah: the words that share the first word's line.
  final firstLine = [
    for (final id in ids)
      if ((_rect(t, id).center.dy - first.center.dy).abs() < first.height / 2)
        _rect(t, id),
  ];
  final top = firstLine.map((r) => r.top).reduce((a, b) => a < b ? a : b);
  final bottom = firstLine.map((r) => r.bottom).reduce((a, b) => a > b ? a : b);
  expect(
    top >= pager.top - 0.5 && bottom <= pager.bottom + 0.5,
    isTrue,
    reason: '$reason: the first line ($top..$bottom) is not inside $pager',
  );
  // All of it, when the screen can hold it with the margin that is kept around it.
  final all = [for (final id in ids) _rect(t, id)]
      .reduce((a, b) => a.expandToInclude(b));
  if (all.width <= pager.width - 48 && all.height <= pager.height - 48) {
    expect(
      _inside(pager, all),
      isTrue,
      reason: '$reason: all of it $all fits $pager but is not inside',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(preloadReaderPages);

  final screens = <(String, Size, List<int>)>[
    ('portrait', _portrait, [80, 100, 150]),
    ('landscape', _landscape, [80, 100, 150]),
    ('narrow landscape', _narrowLandscape, [150]),
  ];
  for (final (screenName, screen, percents) in screens) {
    for (final percent in percents) {
      for (final (ref, page) in _targets) {
        testWidgets(
          '${ref.key} (page $page) is in view at $percent% in $screenName',
          (t) async {
            await pumpSizedReader(
              t,
              startPage: 50,
              percent: percent,
              screen: screen,
            );
            final ids = await idsOn(t, page, ref);
            expect(ids, isNotEmpty);

            await popIndexWith(t, AyahTarget(ref, page));

            expect(shownPage(t), '$page');
            expect(cardHighlight(t, page), ids);
            _expectInView(t, ids, '${ref.key} at $percent% in $screenName');
          },
        );
      }
    }
  }

  group('the page and its geometry', () {
    for (final (screenName, screen, percent) in [
      ('portrait', _portrait, 100),
      ('portrait', _portrait, 150),
      ('landscape', _landscape, 100),
    ]) {
      testWidgets(
        'the highlight changes no line and no word: they are where they were, shifted together by the reveal ($percent%, $screenName)',
        (t) async {
          await pumpSizedReader(
            t,
            startPage: 50,
            percent: percent,
            screen: screen,
          );
          const ref = AyahRef(2, 255);
          await popIndexWith(t, 42); // a plain jump: no highlight, no reveal
          final plain = pageRects(t);
          expect(plain.keys.where((k) => k.startsWith('line-')), hasLength(15));

          await popIndexWith(t, const AyahTarget(ref, 42)); // the page shown
          final found = pageRects(t);
          expect(highlightedBoxes(t), greaterThan(0));

          expect(found.keys.toSet(), plain.keys.toSet());
          final shift = found['line-1']!.topLeft - plain['line-1']!.topLeft;
          for (final key in plain.keys) {
            final want = key == 'pager'
                ? plain[key]!
                : plain[key]!.shift(shift);
            final got = found[key]!;
            expect(got.left, closeTo(want.left, 0.01), reason: '$key left');
            expect(got.top, closeTo(want.top, 0.01), reason: '$key top');
            expect(got.width, closeTo(want.width, 0.01), reason: '$key width');
            expect(
              got.height,
              closeTo(want.height, 0.01),
              reason: '$key height',
            );
          }

          // The touch that ends the highlight moves nothing.
          await _touch(t, t.getCenter(find.byType(PageView)));
          expect(highlightedBoxes(t), 0);
          final cleared = pageRects(t);
          for (final key in found.keys) {
            expect(cleared[key], found[key], reason: '$key moved on clearing');
          }
        },
      );
    }
  });

  group('a result on the page already shown', () {
    // Only where a drag can really take the ayah out of view: the page is much taller than the screen (the portrait page at 150% is
    // not: whatever its position, the middle of the page is on the screen).
    for (final (screenName, screen, percent) in [
      ('landscape', _landscape, 100),
      ('narrow landscape', _narrowLandscape, 150),
    ]) {
      testWidgets(
        'brings the ayah into view again when the page was moved away ($percent%, $screenName)',
        (t) async {
          await pumpSizedReader(
            t,
            startPage: 42,
            percent: percent,
            screen: screen,
          );
          const ref = AyahRef(2, 255);
          final ids = await idsOn(t, 42, ref);
          await popIndexWith(t, const AyahTarget(ref, 42));
          _expectInView(t, ids, 'first arrival');

          // To the bottom of the page: the ayah is out of view.
          final pager = t.getRect(find.byType(PageView));
          await t.dragFrom(
            pager.center,
            const Offset(0, -2500),
          ); // vertical only: no edge turn
          await settleReader(t);
          expect(shownPage(t), '42');
          expect(
            _inside(pager, _rect(t, ids.first)),
            isFalse,
            reason: 'the page was moved away from the ayah',
          );

          await popIndexWith(t, const AyahTarget(ref, 42));

          expect(shownPage(t), '42');
          _expectInView(t, ids, 'again');
        },
      );
    }

    testWidgets('puts a zoomed page back to scale 1 and shows the ayah', (
      t,
    ) async {
      await pumpSizedReader(t, startPage: 42, percent: 100);
      const ref = AyahRef(2, 255);
      final ids = await idsOn(t, 42, ref);
      final centre = t.getCenter(find.byType(PageView));
      final a = await t.startGesture(centre - const Offset(20, 0));
      final b = await t.startGesture(centre + const Offset(20, 0));
      await a.moveBy(const Offset(-80, 0));
      await b.moveBy(const Offset(80, 0));
      await t.pump(const Duration(milliseconds: 50));
      await a.up();
      await b.up();
      await settleReader(t);
      expect(_zoom(t), greaterThan(1));

      await popIndexWith(t, const AyahTarget(ref, 42));

      expect(_zoom(t), closeTo(1, 0.001));
      _expectInView(t, ids, 'after zoom');
    });
  });

  group('a page that is not ready', () {
    testWidgets(
      'is shown with its loading card first and the reveal waits for the words',
      (t) async {
        await pumpSizedReader(t, startPage: 50, percent: 150);
        const ref = AyahRef(18, 10);
        final ids = await idsOn(t, 294, ref);

        // The page is far from the shown one: its text and its font were not warmed, so its card begins as the loading card.
        await t.tap(keyed('open-index'));
        await settleReader(t);
        Navigator.of(t.element(find.byType(IndexScreen)))
            .pop(const AyahTarget(ref, 294));
        await t.pump();
        await t.pump(const Duration(milliseconds: 16));
        await settleReader(t);

        expect(cardHighlight(t, 294), ids);
        _expectInView(t, ids, 'a page that was loading');
      },
    );
  });
}
