// Feature 011, T055: the search screen in both looks, at the three reading sizes, on the usual screen and on the
// narrowest one with a 2x system font, in the states «results», «nothing found» and «preparing»: the 36 combinations of
// SC-008 (spec FR-024, FR-025; contracts/ui.md "Looks, sizes, targets"). Each combination is one pump: nothing overflows,
// every text reaches 4.5:1 (the matched words and «…» inside the snippet included) and every icon 3:1, every target is
// 48 x 48, no fill is bright, and the field stays whole above the keyboard while the list scrolls.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/contrast.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/search/search_screen.dart';
import 'package:mushaf/search/search_service.dart';
import 'package:mushaf/search/search_strings.dart';
import 'package:mushaf/theme.dart';

import '../support/contrast_walk.dart';
import '../support/search_harness.dart';
import '../support/search_quality_harness.dart';

/// Surah 112, ayah 1, whole.
const _ikhlas = 'قل هو الله احد';

/// Found nowhere as typed.
const _nowhere = 'ذو القرنين';

/// A hundred rows and the line that asks for more words; many surah rows too.
const _many = 'ال';

/// Surah 18 by its name.
const _cave = 'كهف';

enum _State { results, none, preparing }

class _Screen {
  const _Screen(this.size, this.textScale);
  final Size size;
  final double textScale;

  @override
  String toString() =>
      '${size.width.toInt()} x ${size.height.toInt()}${textScale == 1 ? '' : ' with a ${textScale.toInt()}x system font'}';
}

const _screens = [_Screen(Size(412, 915), 1.0), _Screen(Size(320, 640), 2.0)];
const _percents = [80, 100, 150];

/// The height the keyboard takes in the last part of every combination.
const double _keyboard = 280;

/// Texts under 4.5:1 and icons under 3:1 on the search screen, the runs inside a rich text included.
List<String> contrastProblems(WidgetTester t) => [
  for (final issue in contrastIssues(
    t,
    within: find.byType(SearchScreen),
    largeMin: 4.5,
  ))
    if (issue.kind != 'icon' || issue.ratio < 3.0) '$issue',
  ...runContrastIssues(t),
];

/// Every result row and button now built is a target of 48 x 48 at least (an ayah row and a surah row 56 high).
void expectTargets(WidgetTester t, {String? reason}) {
  void atLeast(Finder target, double height) {
    final size = t.getSize(target);
    expect(size.width, greaterThanOrEqualTo(48), reason: '$target $reason');
    expect(
      size.height,
      greaterThanOrEqualTo(height),
      reason: '$target $reason',
    );
  }

  if (searchClear.evaluate().isNotEmpty) atLeast(searchClear, 48);
  if (searchRetry.evaluate().isNotEmpty) atLeast(searchRetry, 48);
  for (final key in ayahRowsBuilt(t)) {
    atLeast(skey('ayah-row-$key'), 56);
  }
  for (final surah in surahRowsBuilt(t)) {
    atLeast(surahRow(surah), 56);
  }
}

/// The checks every state of every combination must pass.
void expectQuality(
  WidgetTester t,
  List<FlutterErrorDetails> errors, {
  String? reason,
}) {
  expect(errors, isEmpty, reason: '${describeErrors(errors)} $reason');
  final contrast = contrastProblems(t);
  expect(contrast, isEmpty, reason: '${contrast.join('\n')} $reason');
  expectTargets(t, reason: reason);
  // under the Night look nothing keeps an ivory or bright fill (Emerald & Gold's own gold button is its look)
  if (Theme.of(t.element(find.byType(SearchScreen))).extension<AppLook>() ==
      LookChoice.night.look) {
    final bright = brightFillsOnScreen(t);
    expect(bright, isEmpty, reason: '${bright.join(', ')} $reason');
  }
  final red = redThings(t);
  expect(red, isEmpty, reason: '${red.join(', ')} $reason');
  // nothing is drawn outside the screen's width
  final width = t.view.physicalSize.width / t.view.devicePixelRatio;
  for (final key in ayahRowsBuilt(t)) {
    final rect = t.getRect(skey('ayah-row-$key'));
    expect(rect.left, greaterThanOrEqualTo(-0.01), reason: reason);
    expect(rect.right, lessThanOrEqualTo(width + 0.01), reason: reason);
    final snippet = t.getRect(snippetIn(skey('ayah-row-$key')));
    expect(snippet.left, greaterThanOrEqualTo(-0.01), reason: reason);
    expect(snippet.right, lessThanOrEqualTo(width + 0.01), reason: reason);
  }
}

/// With the keyboard up the field is whole between the app bar and the keyboard, and the list still scrolls to its end.
Future<void> expectUsableWithKeyboard(
  WidgetTester t,
  List<FlutterErrorDetails> errors,
) async {
  final screen = t.view.physicalSize / t.view.devicePixelRatio;
  t.view.viewInsets = const FakeViewPadding(bottom: _keyboard);
  addTearDown(t.view.resetViewInsets);
  await t.pump();
  await t.pump();
  expect(errors, isEmpty, reason: 'keyboard up: ${describeErrors(errors)}');
  final top = t.getRect(find.byType(AppBar)).bottom;
  final bottom = screen.height - _keyboard;
  final field = t.getRect(searchField);
  expect(
    field.top,
    greaterThanOrEqualTo(top - 0.01),
    reason: 'the field is under the app bar',
  );
  expect(
    field.bottom,
    lessThanOrEqualTo(bottom + 0.01),
    reason: 'the field is above the keyboard',
  );
  expect(field.left, greaterThanOrEqualTo(-0.01));
  expect(field.right, lessThanOrEqualTo(screen.width + 0.01));
  expect(field.height, greaterThanOrEqualTo(48));
  if (searchClear.evaluate().isNotEmpty) {
    final clear = t.getRect(searchClear);
    expect(
      clear.bottom,
      lessThanOrEqualTo(bottom + 0.01),
      reason: 'the clear button is above the keyboard',
    );
    expect(clear.top, greaterThanOrEqualTo(top - 0.01));
  }
  final list = t.getRect(searchList);
  expect(
    list.top,
    greaterThanOrEqualTo(field.bottom - 0.01),
    reason: 'the list is under the field',
  );
  expect(
    list.bottom,
    lessThanOrEqualTo(bottom + 0.01),
    reason: 'the list ends above the keyboard',
  );
  expect(
    list.height,
    greaterThan(0),
    reason: 'some of the list is left to see',
  );
  // the list scrolls: everything in it can be brought above the keyboard
  final position = searchPosition(t);
  if (position.maxScrollExtent > 0) {
    await t.drag(searchList, Offset(0, -list.height / 2), warnIfMissed: false);
    await t.pump();
    expect(
      position.pixels,
      greaterThan(0),
      reason: 'the list scrolls under the field',
    );
    position.jumpTo(position.maxScrollExtent);
    await t.pump();
    position.jumpTo(position.maxScrollExtent);
    await t.pump();
    expect(field, t.getRect(searchField), reason: 'only the list scrolls');
  }
  expect(errors, isEmpty, reason: 'after scrolling: ${describeErrors(errors)}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await realMeta();
    await realIndex();
  });

  var combinations = 0;
  for (final look in LookChoice.values) {
    for (final percent in _percents) {
      for (final screen in _screens) {
        for (final state in _State.values) {
          combinations++;
          testWidgets('${look.name}, $percent %, $screen, ${state.name}', (
            t,
          ) async {
            final errors = collectErrors();
            await pumpSearch(
              t,
              look: look,
              screen: screen.size,
              textScale: screen.textScale,
              readingPercent: percent,
              service: state == _State.preparing
                  ? ScriptedSearchService(phase: IndexPhase.preparing)
                  : null,
            );
            expect(
              Theme.of(t.element(find.byType(SearchScreen)))
                  .extension<AppLook>(),
              look.look,
            );
            await typeQuery(t, state == _State.none ? _nowhere : _ikhlas);

            // the state is the one this combination is about
            switch (state) {
              case _State.results:
                expect(ayatHeading, findsOneWidget);
                expect(ayahRow(112, 1), findsOneWidget);
                final accent = look.look.accent;
                final emphasised = [
                  for (final run in runsOf(
                    t.widget<RichText>(snippetIn(ayahRow(112, 1))),
                  ))
                    if (run.style.color == accent) run,
                ];
                expect(
                  emphasised,
                  isNotEmpty,
                  reason: 'the matched words are in the accent colour',
                );
                expect(
                  emphasised.map((r) => r.style.decoration),
                  everyElement(TextDecoration.underline),
                );
                expect(
                  contrastRatio(accent, look.look.background),
                  greaterThanOrEqualTo(4.5),
                );
              case _State.none:
                expect(find.text(kSearchNone), findsOneWidget);
                expect(find.text(kSearchNoneAdvice), findsOneWidget);
              case _State.preparing:
                expect(find.text(kSearchPreparing), findsOneWidget);
            }
            expect(searchClear, findsOneWidget);

            expectQuality(t, errors);
            await expectUsableWithKeyboard(t, errors);
            expectQuality(
              t,
              errors,
              reason: '(keyboard up, scrolled to the end)',
            );
          });
        }
      }
    }
  }

  test('the matrix is the 36 combinations of SC-008', () {
    expect(LookChoice.values, hasLength(2));
    expect(combinations, 36);
  });

  // The other states, on the hardest screen (320 x 640, 2x system font, 150 %) and on the usual one, in both looks.
  for (final look in LookChoice.values) {
    for (final screen in _screens) {
      final percent = screen.textScale == 1 ? 100 : 150;
      group('${look.name}, $percent %, $screen', () {
        testWidgets('nothing typed, one letter, a surah row', (t) async {
          final errors = collectErrors();
          await pumpSearch(
            t,
            look: look,
            screen: screen.size,
            textScale: screen.textScale,
            readingPercent: percent,
          );
          expect(find.text(kSearchHint), findsOneWidget);
          expectQuality(t, errors, reason: '(nothing typed)');
          await typeQuery(t, 'ق');
          expect(surahRow(50), findsOneWidget);
          expectQuality(t, errors, reason: '(one letter)');
          await typeQuery(t, _cave);
          expect(surahRow(18), findsOneWidget);
          expectQuality(t, errors, reason: '(a surah row)');
          await expectUsableWithKeyboard(t, errors);
        });

        testWidgets('the preparation failed: the line and the 48 px button', (
          t,
        ) async {
          final errors = collectErrors();
          await pumpSearch(
            t,
            look: look,
            screen: screen.size,
            textScale: screen.textScale,
            readingPercent: percent,
            service: ScriptedSearchService(phase: IndexPhase.failed),
          );
          await typeQuery(t, _cave);
          expect(find.text(kSearchFailed), findsOneWidget);
          // on the narrow screen the button may be under the fold of the list
          await t.scrollUntilVisible(searchRetry, 80, scrollable: searchList);
          await t.pump();
          expect(
            t.getRect(searchRetry).bottom,
            lessThanOrEqualTo(t.getRect(searchList).bottom + 0.01),
            reason: 'the whole button can be brought into view',
          );
          expect(t.getSize(searchRetry).height, greaterThanOrEqualTo(48));
          expect(t.getSize(searchRetry).width, greaterThanOrEqualTo(48));
          expectQuality(t, errors, reason: '(failed)');
          await expectUsableWithKeyboard(t, errors);
          expectQuality(t, errors, reason: '(failed, keyboard up)');
        });

        testWidgets(
          'a hundred rows, from the first to the line that asks for more words',
          (t) async {
            final errors = collectErrors();
            await pumpSearch(
              t,
              look: look,
              screen: screen.size,
              textScale: screen.textScale,
              readingPercent: percent,
            );
            await typeQuery(t, _many);
            expectQuality(t, errors, reason: '(the top of the list)');
            final position = searchPosition(t);
            // through the whole list: every row that is ever built passes
            var steps = 0;
            while (searchMoreLine.evaluate().isEmpty && steps < 600) {
              position.jumpTo(
                (position.pixels + screen.size.height / 2).clamp(
                  0,
                  position.maxScrollExtent,
                ),
              );
              await t.pump();
              steps++;
              if (steps % 12 == 0) {
                expectQuality(
                  t,
                  errors,
                  reason: '(at ${position.pixels.round()} px)',
                );
              }
            }
            expect(
              searchMoreLine,
              findsOneWidget,
              reason:
                  'the last row and the more-line are reachable by scrolling',
            );
            await t.ensureVisible(searchMoreLine);
            await t.pump();
            expect(
              find.descendant(
                of: searchMoreLine,
                matching: find.text(kSearchTooMany),
                matchRoot: true,
              ),
              findsOneWidget,
            );
            expectQuality(t, errors, reason: '(the end of the list)');
          },
        );
      });
    }
  }

  test('no colour is written in lib/search/ (only the tokens of the look)', () {
    final literal = RegExp(
      r'Color\s*\(\s*0x|Colors\.|Color\.from(ARGB|RGBO)\s*\(|HSLColor|HSVColor',
    );
    final files = Directory('lib/search')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    expect(files.map((f) => f.path), contains('lib/search/search_screen.dart'));
    expect(files.map((f) => f.path), contains('lib/search/search_rows.dart'));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].split('//').first;
        expect(
          literal.hasMatch(code),
          isFalse,
          reason: '${file.path}:${i + 1}: ${lines[i].trim()}',
        );
      }
    }
  });
}
