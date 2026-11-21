// PageViewport.reveal: bring the words of a found ayah into view, once per token (feature 011, T040; spec FR-013, US6 scenario 5;
// research D4, D11). The parameter is optional and acts only when given: the layout, zoom and edge-turn tests of features 003, 004,
// 006 and 010 (test/mushaf/page_viewport_test.dart and the rest) are not edited and must stay green.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/page_scale.dart';
import 'package:mushaf/mushaf/page_viewport.dart';

const Size kPortrait = Size(412, 915);
const Size kLandscape = Size(915, 412);

/// The margin the reveal keeps around the words when it has to move the page (research D4).
const double kMargin = 24;

/// A word of the test page is `w<line * 10 + k>`: line 1 to 15 from the top, k 1 to 6 from the right (the page is right to
/// left, so word 1 of a line is its first word).
int id(int line, int k) => line * 10 + k;

Set<int> words(int line, Iterable<int> ks) => {for (final k in ks) id(line, k)};
Set<int> lines(int from, int to) => {
  for (var l = from; l <= to; l++) ...words(l, [1, 2, 3, 4, 5, 6]),
};

/// Two words in the middle of the page, at the right of their line (in view when the page is opened).
final Set<int> kRight = words(8, [1, 2]);

/// Two words far to the left of their line (out of view on a page wider than the screen).
final Set<int> kLeft = words(8, [5, 6]);

/// Three whole lines: wider than the screen at 150%.
final Set<int> kThree = lines(4, 6);

/// Lines at the bottom of the page: below the screen when the page is opened, short enough to fit above its bottom.
final Set<int> kDeep = lines(12, 14);

/// The same lines at the right only: narrower than the screen, so every side can be checked.
final Set<int> kDeepNarrow = {
  for (var l = 12; l <= 14; l++) ...words(l, [1, 2]),
};

/// Eleven whole lines from the middle of the page: taller than the screen at 150% (a word is shorter than its line).
final Set<int> kDeepLong = lines(5, 15);

/// Most of the page: taller than the screen at every size of a landscape.
final Set<int> kLong = lines(2, 14);

/// The words of the first line.
final Set<int> kTop = words(1, [1, 2]);

/// A page with the proportions of the real one: 15 lines of 6 words, laid out right to left to the width it is given.
class _TestPage extends StatelessWidget {
  const _TestPage({required this.showWords});

  final ValueNotifier<bool> showWords;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: const Color(0xFFFBF5E3),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final lineHeight = constraints.maxHeight / 15;
            final fontSize = constraints.maxWidth / 22;
            return ValueListenableBuilder<bool>(
              valueListenable: showWords,
              builder: (context, shown, _) => Column(
                children: [
                  for (var line = 1; line <= 15; line++)
                    SizedBox(
                      key: ValueKey('line-$line'),
                      height: lineHeight,
                      child: !shown
                          ? null
                          : Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: constraints.maxWidth * 0.065,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  for (var k = 1; k <= 6; k++)
                                    Text(
                                      'كلم',
                                      key: ValueKey('w${id(line, k)}'),
                                      softWrap: false,
                                      style: TextStyle(fontSize: fontSize),
                                    ),
                                ],
                              ),
                            ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget host({
  required double factor,
  required Size viewport,
  required ValueNotifier<bool> showWords,
  PageReveal? reveal,
  bool reducedMotion = false,
  bool passReveal = true,
}) {
  final page = _TestPage(showWords: showWords);
  final viewer = passReveal
      ? PageViewport(
          page: 7,
          factor: factor,
          onLockChanged: (_, _) {},
          onEdgeTurn: (_) {},
          reveal: reveal,
          child: page,
        )
      : PageViewport(
          page: 7,
          factor: factor,
          onLockChanged: (_, _) {},
          onEdgeTurn: (_) {},
          child: page,
        );
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
      child: child!,
    ),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: viewport.width,
          height: viewport.height,
          child: viewer,
        ),
      ),
    ),
  );
}

Finder wordKey(int id) => find.byKey(ValueKey('w$id'));

Rect wordRect(WidgetTester t, int id) => t.getRect(wordKey(id));

/// The union of the rectangles of [ids].
Rect unionOf(WidgetTester t, Iterable<int> ids) =>
    ids.map((i) => wordRect(t, i)).reduce((a, b) => a.expandToInclude(b));

/// The word that comes first in reading order: the smallest id.
int firstOf(Set<int> ids) => ids.reduce((a, b) => a < b ? a : b);

TransformationController controllerOf(WidgetTester t) => t
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!;

Offset translationOf(WidgetTester t) {
  final v = controllerOf(t).value.getTranslation();
  return Offset(v.x, v.y);
}

double scaleOf(WidgetTester t) => controllerOf(t).value.getMaxScaleOnAxis();

double scrollOf(WidgetTester t) => t
    .state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('landscape-scroll')),
        matching: find.byType(Scrollable),
      ),
    )
    .position
    .pixels;

/// A few frames, enough for a reveal that first has to put a zoomed page back.
Future<void> frames(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

class Setup {
  Setup(this.t, this.viewport, this.factor, this.showWords);
  final WidgetTester t;
  final Size viewport;
  final double factor;
  final ValueNotifier<bool> showWords;

  Rect get screen => Offset.zero & viewport;

  Future<void> show({
    PageReveal? reveal,
    bool reducedMotion = false,
    bool passReveal = true,
  }) async {
    await t.pumpWidget(
      host(
        factor: factor,
        viewport: viewport,
        showWords: showWords,
        reveal: reveal,
        reducedMotion: reducedMotion,
        passReveal: passReveal,
      ),
    );
    await frames(t);
  }
}

Future<Setup> setup(
  WidgetTester t,
  Size viewport,
  double factor, {
  bool wordsShown = true,
}) async {
  t.view.physicalSize = const Size(1000, 1600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final showWords = ValueNotifier<bool>(wordsShown);
  addTearDown(showWords.dispose);
  return Setup(t, viewport, factor, showWords);
}

void expectInside(Rect inner, Rect outer, {double margin = 0, String? reason}) {
  expect(
    inner.left,
    greaterThanOrEqualTo(outer.left + margin - 0.01),
    reason: 'left: $reason $inner in $outer',
  );
  expect(
    inner.top,
    greaterThanOrEqualTo(outer.top + margin - 0.01),
    reason: 'top: $reason $inner in $outer',
  );
  expect(
    inner.right,
    lessThanOrEqualTo(outer.right - margin + 0.01),
    reason: 'right: $reason $inner in $outer',
  );
  expect(
    inner.bottom,
    lessThanOrEqualTo(outer.bottom - margin + 0.01),
    reason: 'bottom: $reason $inner in $outer',
  );
}

void main() {
  group('no reveal changes nothing', () {
    for (final (viewport, label) in [
      (kPortrait, 'portrait'),
      (kLandscape, 'landscape'),
    ]) {
      for (final factor in [0.8, 1.0, 1.5]) {
        testWidgets(
          '$label at ${(factor * 100).round()}%: the page is where it was without the parameter, and no frame is asked for',
          (t) async {
            final s = await setup(t, viewport, factor);
            await s.show(passReveal: false);
            final before = {
              for (final w in [...kRight, ...kLeft, ...kDeep])
                w: wordRect(t, w),
            };
            final translation = translationOf(t);
            await s.show(reveal: null);
            for (final e in before.entries) {
              expect(wordRect(t, e.key), e.value, reason: 'w${e.key}');
            }
            expect(translationOf(t), translation);
            expect(scaleOf(t), 1.0);
            expect(t.binding.hasScheduledFrame, isFalse);
          },
        );
      }
    }

    testWidgets(
      'a reveal given as null after a reveal leaves the page where it is',
      (t) async {
        final s = await setup(t, kPortrait, 1.5);
        await s.show(reveal: PageReveal(kLeft, 1));
        final moved = translationOf(t);
        await s.show(reveal: null);
        expect(translationOf(t), moved);
      },
    );
  });

  group('fits (portrait at 80% and 100%)', () {
    for (final factor in [0.8, 1.0]) {
      for (final (name, ids) in [
        ('two words', kLeft),
        ('three lines', kThree),
        ('most of the page', kLong),
        ('the deep lines', kDeep),
      ]) {
        testWidgets(
          '${(factor * 100).round()}% $name: nothing moves and the words are inside the viewport',
          (t) async {
            final s = await setup(t, kPortrait, factor);
            await s.show(passReveal: false);
            final before = {for (final w in ids) w: wordRect(t, w)};
            await s.show(reveal: PageReveal(ids, 1));
            for (final e in before.entries) {
              expect(
                wordRect(t, e.key),
                e.value,
                reason: 'w${e.key} did not move',
              );
            }
            expectInside(unionOf(t, ids), s.screen, reason: name);
            expect(scaleOf(t), 1.0);
            expect(controllerOf(t).value.getTranslation().x, 0);
            expect(controllerOf(t).value.getTranslation().y, 0);
          },
        );
      }
    }
  });

  group('scrollsVertically (landscape 915 x 412)', () {
    for (final factor in [0.8, 1.0, 1.5]) {
      final p = (factor * 100).round();

      testWidgets(
        '$p%: the first word comes to about 30% from the top, at once, and the scroll position changed',
        (t) async {
          final s = await setup(t, kLandscape, factor);
          await s.show(passReveal: false);
          expect(scrollOf(t), 0);
          await t.pumpWidget(
            host(
              factor: factor,
              viewport: kLandscape,
              showWords: s.showWords,
              reveal: PageReveal(kRight, 1),
            ),
          );
          // One frame builds, the next one draws the new position: no animation runs in between.
          await t.pump();
          await t.pump();
          final first = wordRect(t, firstOf(kRight));
          final settled = scrollOf(t);
          expect(settled, greaterThan(0));
          expect(
            first.top,
            closeTo(0.3 * kLandscape.height, 0.05 * kLandscape.height),
            reason: 'first word at about 30%',
          );
          expectInside(unionOf(t, kRight), s.screen);
          await frames(t, 10);
          expect(
            scrollOf(t),
            settled,
            reason: 'it jumped: nothing keeps moving',
          );
          expect(wordRect(t, firstOf(kRight)), first);
          expect(scaleOf(t), 1.0);
        },
      );

      testWidgets('$p%: three lines that the screen can hold are inside it', (
        t,
      ) async {
        final s = await setup(t, kLandscape, factor);
        await s.show(reveal: PageReveal(kThree, 1));
        final union = unionOf(t, kThree);
        final lineHeight = union.height / 3;
        if (union.height <= kLandscape.height - 2 * kMargin) {
          expectInside(union, s.screen, reason: 'all of it');
        } else {
          // At 150% a line is 105 px: three lines do not fit above the margin, so the first line is what is in view.
          expectInside(
            wordRect(t, firstOf(kThree)),
            s.screen,
            reason: 'the first line ($lineHeight px)',
          );
        }
      });

      testWidgets(
        '$p%: five lines that fit with their margin are all inside, even though 30% from the top would cut them',
        (t) async {
          final s = await setup(t, kLandscape, factor);
          final five = lines(3, 7);
          await s.show(passReveal: false);
          final height = unionOf(t, five).height;
          await s.show(reveal: PageReveal(five, 1));
          if (height <= kLandscape.height - 2 * kMargin) {
            expectInside(
              unionOf(t, five),
              s.screen,
              margin: kMargin,
              reason: 'all of it, with the margin',
            );
          }
          expectInside(
            wordRect(t, firstOf(five)),
            s.screen,
            reason: 'the first word',
          );
        },
      );

      testWidgets(
        '$p%: an ayah taller than the screen has its first line in view',
        (t) async {
          final s = await setup(t, kLandscape, factor);
          await s.show(reveal: PageReveal(kLong, 1));
          final first = wordRect(t, firstOf(kLong));
          expectInside(first, s.screen, reason: 'the first word');
          expect(first.top, lessThanOrEqualTo(0.3 * kLandscape.height + 1));
        },
      );

      testWidgets('$p%: words on the first line need no scroll', (t) async {
        final s = await setup(t, kLandscape, factor);
        await s.show(reveal: PageReveal(kTop, 1));
        expectInside(unionOf(t, kTop), s.screen);
        expect(scrollOf(t), lessThanOrEqualTo(1));
      });

      testWidgets(
        '$p%: a page scrolled down brings the ayah back on a new token',
        (t) async {
          final s = await setup(t, kLandscape, factor);
          await s.show(reveal: PageReveal(kRight, 1));
          final position = t
              .state<ScrollableState>(
                find.descendant(
                  of: find.byKey(const ValueKey('landscape-scroll')),
                  matching: find.byType(Scrollable),
                ),
              )
              .position;
          position.jumpTo(position.maxScrollExtent);
          await frames(t, 2);
          expect(
            wordRect(t, firstOf(kRight)).top,
            isNot(closeTo(0.3 * kLandscape.height, 0.05 * kLandscape.height)),
          );
          await s.show(reveal: PageReveal(kRight, 2));
          expect(
            wordRect(t, firstOf(kRight)).top,
            closeTo(0.3 * kLandscape.height, 0.05 * kLandscape.height),
          );
        },
      );
    }
  });

  group('pansBothWays (portrait at 150%)', () {
    const factor = 1.5;
    final content = PageBox(kPortrait, factor).content;

    void expectClamped(WidgetTester t) {
      final tr = translationOf(t);
      expect(
        tr.dx,
        inInclusiveRange(kPortrait.width - content.width - 0.01, 0.01),
      );
      expect(
        tr.dy,
        inInclusiveRange(kPortrait.height - content.height - 0.01, 0.01),
      );
    }

    testWidgets(
      'the page opens at its top and right side, which the other tests build on',
      (t) async {
        final s = await setup(t, kPortrait, factor);
        await s.show();
        expect(translationOf(t), Offset(kPortrait.width - content.width, 0));
        expect(
          wordRect(t, id(8, 5)).left,
          lessThan(0),
          reason: 'the left of the page is out of view',
        );
      },
    );

    testWidgets('words in view already do not move the page', (t) async {
      final s = await setup(t, kPortrait, factor);
      await s.show();
      final start = translationOf(t);
      final union = unionOf(t, kRight);
      expectInside(
        union,
        s.screen,
        margin: kMargin,
        reason: 'in view at arrival',
      );
      await s.show(reveal: PageReveal(kRight, 1));
      expect(translationOf(t), start);
    });

    testWidgets('words far to the left come into view with the margin', (
      t,
    ) async {
      final s = await setup(t, kPortrait, factor);
      await s.show(reveal: PageReveal(kLeft, 1));
      expectInside(
        unionOf(t, kLeft),
        s.screen,
        margin: kMargin,
        reason: 'the union with a 24 dp margin',
      );
      expectClamped(t);
      expect(scaleOf(t), 1.0);
    });

    testWidgets('lines below the screen come into view with the margin', (
      t,
    ) async {
      final s = await setup(t, kPortrait, factor);
      await s.show();
      expect(
        unionOf(t, kDeepNarrow).bottom,
        greaterThan(kPortrait.height),
        reason: 'out of view at arrival',
      );
      await s.show(reveal: PageReveal(kDeepNarrow, 1));
      expectInside(
        unionOf(t, kDeepNarrow),
        s.screen,
        margin: kMargin,
        reason: 'the union with a 24 dp margin',
      );
      expectClamped(t);
    });

    testWidgets(
      'three whole lines are wider than the screen: the first word is at the right edge',
      (t) async {
        final s = await setup(t, kPortrait, factor);
        await s.show(reveal: PageReveal(kThree, 1));
        final union = unionOf(t, kThree);
        expect(
          union.width,
          greaterThan(kPortrait.width),
          reason: 'wider than the screen',
        );
        final first = wordRect(t, firstOf(kThree));
        expect(first.right, closeTo(kPortrait.width - kMargin, 0.5));
        expectInside(first, s.screen, reason: 'the first word');
        expectClamped(t);
      },
    );

    testWidgets(
      'an ayah taller than the screen has its first line in view at the top',
      (t) async {
        final s = await setup(t, kPortrait, factor);
        await s.show();
        final atArrival = wordRect(t, firstOf(kDeepLong)).top;
        await s.show(reveal: PageReveal(kDeepLong, 1));
        final first = wordRect(t, firstOf(kDeepLong));
        expect(
          unionOf(t, kDeepLong).height,
          greaterThan(kPortrait.height - 2 * kMargin),
        );
        expectInside(
          first,
          s.screen,
          margin: kMargin,
          reason: 'the first word of the first line',
        );
        expect(first.top, closeTo(kMargin, 0.5));
        expect(first.top, isNot(closeTo(atArrival, 1)), reason: 'it moved');
        expect(first.right, closeTo(kPortrait.width - kMargin, 0.5));
        expectClamped(t);
      },
    );

    testWidgets('the whole page as an ayah: the first line is in view', (
      t,
    ) async {
      final s = await setup(t, kPortrait, factor);
      await s.show(reveal: PageReveal(lines(1, 15), 1));
      expectInside(wordRect(t, id(1, 1)), s.screen, reason: 'the first word');
      expectClamped(t);
    });

    testWidgets('it jumps: no frame after the reveal moves anything', (
      t,
    ) async {
      final s = await setup(t, kPortrait, factor);
      await s.show();
      await t.pumpWidget(
        host(
          factor: factor,
          viewport: kPortrait,
          showWords: s.showWords,
          reveal: PageReveal(kLeft, 1),
        ),
      );
      await t.pump();
      await t.pump();
      final settled = translationOf(t);
      expect(settled, isNot(Offset(kPortrait.width - content.width, 0)));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 16));
        expect(translationOf(t), settled, reason: 'frame $i');
      }
      expect(
        t.binding.hasScheduledFrame,
        isFalse,
        reason: 'nothing is pending after a reveal',
      );
    });
  });

  group('tokens', () {
    testWidgets('a new token acts again, the same token does not', (t) async {
      final s = await setup(t, kPortrait, 1.5);
      await s.show(reveal: PageReveal(kLeft, 1));
      // The reader moves the page by hand.
      controllerOf(t).value = Matrix4.translationValues(-100, -200, 0);
      await frames(t, 2);
      final moved = translationOf(t);
      expect(
        moved,
        isNot(
          Offset(kPortrait.width - PageBox(kPortrait, 1.5).content.width, 0),
        ),
      );
      // The same token with a new object (the reader rebuilds): nothing.
      await s.show(reveal: PageReveal(kLeft, 1));
      expect(translationOf(t), moved);
      await s.show(reveal: PageReveal({...kLeft, ...kRight}, 1));
      expect(
        translationOf(t),
        moved,
        reason: 'the token decides, not the words',
      );
      // A new token acts.
      await s.show(reveal: PageReveal(kLeft, 2));
      expect(translationOf(t), isNot(moved));
      expectInside(unionOf(t, kLeft), s.screen, margin: kMargin);
    });

    testWidgets(
      'a reveal that is given with the first build acts on that build',
      (t) async {
        final s = await setup(t, kPortrait, 1.5);
        await s.show(reveal: PageReveal(kLeft, 1));
        expectInside(unionOf(t, kLeft), s.screen, margin: kMargin);
      },
    );

    testWidgets(
      'a reveal in the landscape scroll acts again on a new token after a first one',
      (t) async {
        final s = await setup(t, kLandscape, 1.0);
        await s.show(reveal: PageReveal(kRight, 1));
        final first = wordRect(t, firstOf(kRight));
        await s.show(reveal: PageReveal(words(9, [1, 2]), 2));
        expect(
          wordRect(t, firstOf(words(9, [1, 2]))).top,
          closeTo(0.3 * kLandscape.height, 0.05 * kLandscape.height),
        );
        expect(wordRect(t, firstOf(kRight)), isNot(first));
      },
    );
  });

  group('a page that is zoomed in', () {
    testWidgets(
      'on a page wider than the screen it is put back to scale 1 first, then the words come into view',
      (t) async {
        final s = await setup(t, kPortrait, 1.5);
        await s.show();
        controllerOf(t).value = Matrix4.diagonal3Values(2, 2, 1)
          ..setTranslationRaw(-300, -300, 0);
        await frames(t, 2);
        expect(scaleOf(t), closeTo(2.0, 0.001));
        await s.show(reveal: PageReveal(kLeft, 1));
        expect(scaleOf(t), closeTo(1.0, 0.001));
        expectInside(unionOf(t, kLeft), s.screen, margin: kMargin);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'on a page that fits it is put back to scale 1 and shows the page whole',
      (t) async {
        final s = await setup(t, kPortrait, 1.0);
        await s.show();
        controllerOf(t).value = Matrix4.diagonal3Values(2.5, 2.5, 1);
        await frames(t, 2);
        expect(scaleOf(t), closeTo(2.5, 0.001));
        await s.show(reveal: PageReveal(kDeep, 1));
        expect(scaleOf(t), closeTo(1.0, 0.001));
        expectInside(unionOf(t, kDeep), s.screen);
      },
    );
  });

  group('words that come late', () {
    testWidgets(
      'they appear a few frames after the page: the reveal waits for them and then acts',
      (t) async {
        final s = await setup(t, kPortrait, 1.5, wordsShown: false);
        await s.show(reveal: PageReveal(kLeft, 1));
        expect(wordKey(firstOf(kLeft)), findsNothing);
        final start = translationOf(t);
        await frames(t, 5);
        expect(translationOf(t), start, reason: 'nothing to reveal yet');
        s.showWords.value = true;
        await frames(t, 6);
        expectInside(unionOf(t, kLeft), s.screen, margin: kMargin);
        expect(t.takeException(), isNull);
        expect(t.binding.hasScheduledFrame, isFalse);
      },
    );

    testWidgets(
      'they appear after 40 frames: still in time (the retry lasts up to 60 frames)',
      (t) async {
        final s = await setup(t, kPortrait, 1.5, wordsShown: false);
        await s.show(reveal: PageReveal(kLeft, 1));
        await frames(t, 34);
        s.showWords.value = true;
        await frames(t, 8);
        expectInside(unionOf(t, kLeft), s.screen, margin: kMargin);
      },
    );

    testWidgets(
      'a reveal whose words never appear gives up silently, without error, and stops asking for frames',
      (t) async {
        final s = await setup(t, kPortrait, 1.5, wordsShown: false);
        await s.show(reveal: PageReveal(kLeft, 1));
        final start = translationOf(t);
        await frames(t, 80);
        expect(t.takeException(), isNull);
        expect(
          t.binding.hasScheduledFrame,
          isFalse,
          reason: 'the retry stopped',
        );
        // A page that arrives after it gave up is not revealed (the token is spent).
        s.showWords.value = true;
        await frames(t, 6);
        expect(translationOf(t), start);
      },
    );

    testWidgets(
      'words of another page (ids that are not on this one) never appear: silent too',
      (t) async {
        final s = await setup(t, kPortrait, 1.5);
        await s.show(reveal: PageReveal({99999, 99998}, 1));
        await frames(t, 80);
        expect(t.takeException(), isNull);
        expect(t.binding.hasScheduledFrame, isFalse);
        expect(
          translationOf(t),
          Offset(kPortrait.width - PageBox(kPortrait, 1.5).content.width, 0),
        );
      },
    );

    testWidgets('an empty set of words does nothing', (t) async {
      final s = await setup(t, kPortrait, 1.5);
      await s.show(reveal: PageReveal(const <int>{}, 1));
      await frames(t, 70);
      expect(t.takeException(), isNull);
      expect(t.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('the page is taken away while a reveal waits: nothing throws', (
      t,
    ) async {
      final s = await setup(t, kPortrait, 1.5, wordsShown: false);
      await s.show(reveal: PageReveal(kLeft, 1));
      await frames(t, 3);
      await t.pumpWidget(const SizedBox());
      await frames(t, 70);
      expect(t.takeException(), isNull);
    });
  });

  group('reduced motion makes no difference (nothing animates)', () {
    for (final (viewport, factor) in [(kPortrait, 1.5), (kLandscape, 1.0)]) {
      testWidgets(
        '${viewport.width.round()} x ${viewport.height.round()} at ${(factor * 100).round()}%',
        (t) async {
          final ids = viewport == kPortrait ? kLeft : kRight;
          final s = await setup(t, viewport, factor);
          await s.show(reveal: PageReveal(ids, 1));
          final normal = wordRect(t, firstOf(ids));
          await t.pumpWidget(const SizedBox());
          await s.show(reveal: PageReveal(ids, 1), reducedMotion: true);
          expect(wordRect(t, firstOf(ids)), normal);
          await t.pumpWidget(const SizedBox());
          // One frame after the build is enough in both cases: no animation has to run.
          await t.pumpWidget(
            host(
              factor: factor,
              viewport: viewport,
              showWords: s.showWords,
              reveal: PageReveal(ids, 1),
              reducedMotion: true,
            ),
          );
          await t.pump();
          await t.pump();
          expect(wordRect(t, firstOf(ids)), normal);
        },
      );
    }
  });
}
