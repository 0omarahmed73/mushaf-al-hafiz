// The bookmark icon in both looks, at the three reading sizes and on the narrowest screen with a 2x system font
// (feature 006, tasks T013/T014; spec FR-010..FR-013, SC-003): it stays in the bar, 48 px, readable (4.5:1) in both
// states, nothing overflows because of it, and a hidden bar takes it along.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/mushaf/bookmark_strings.dart';

import '../support/bookmark_harness.dart';
import '../support/contrast_walk.dart';
import '../support/reader_harness.dart' show settleReader;

Finder get button => key('bookmark-button');

void expectInBar(WidgetTester t) {
  final icon = t.getRect(button);
  final bar = t.getRect(key('top-bar'));
  final juz = t.getRect(key('juz-hizb'));
  expect(icon.width, greaterThanOrEqualTo(48));
  expect(icon.height, greaterThanOrEqualTo(48));
  expect(
    icon.left >= bar.left - 0.01 &&
        icon.top >= bar.top - 0.01 &&
        icon.right <= bar.right + 0.01 &&
        icon.bottom <= bar.bottom + 0.01,
    isTrue,
    reason: 'the icon stays inside the 84 px bar: $icon in $bar',
  );
  expect(icon.top, greaterThanOrEqualTo(juz.bottom - 0.01));
  expect(icon.left, greaterThanOrEqualTo(0));
}

void expectReadable(WidgetTester t) {
  final issues = contrastIssues(t, within: button, largeMin: 4.5);
  expect(issues, isEmpty, reason: issues.join('\n'));
}

void main() {
  for (final look in LookChoice.values) {
    group(look.name, () {
      for (final percent in const [80, 100, 150]) {
        testWidgets(
          'reading size $percent %: in the bar, 48 px, readable in both states',
          (t) async {
            final reader = await pumpBookmarkReader(
              t,
              look: look,
              percent: percent,
            );
            expect(button, findsOneWidget);
            expectInBar(t);
            expectReadable(t); // outlined
            await t.tap(button);
            await settleReader(t);
            expectReadable(t); // filled
            expectInBar(t);
            expect(reader.unexpectedErrors, isEmpty);
          },
        );
      }

      testWidgets(
        '320 dp with a 2x system font: no overflow, still 48 px, still beside «اجعلها موضعي»',
        (t) async {
          final reader = await pumpBookmarkReader(
            t,
            look: look,
            screen: const Size(320, 640),
            textScale: 2.0,
            browseWithWird: true,
          );
          expect(reader.topBarErrors, isEmpty);
          expectInBar(t);
          expect(find.text('اجعلها موضعي'), findsOneWidget);
          expect(
            t.getRect(button).overlaps(t.getRect(find.text('اجعلها موضعي'))),
            isFalse,
          );
          await t.tap(button);
          await settleReader(t);
          expect(reader.topBarErrors, isEmpty);
          expectReadable(t);
        },
      );

      testWidgets(
        'a long press shows the tooltip, a screen reader hears action and state',
        (t) async {
          final handle = t.ensureSemantics();
          await pumpBookmarkReader(t, look: look, startPage: 50);
          final node = t.getSemantics(button);
          expect(node.label, kBookmarkAdd(50));
          expect(node.value, kBookmarkStateOff);
          await t.longPress(button);
          await settleReader(t);
          expect(find.text(kBookmarkAdd(50)), findsWidgets);
          await t.tap(button);
          await settleReader(t);
          final after = t.getSemantics(button);
          expect(after.label, kBookmarkRemove(50));
          expect(after.value, kBookmarkStateOn);
          handle.dispose();
        },
      );
    });
  }

  testWidgets('a hidden top bar takes the icon along, and brings it back', (
    t,
  ) async {
    await pumpBookmarkReader(t);
    expect(button, findsOneWidget);
    await t.tapAt(t.getCenter(find.byType(PageView)));
    await settleReader(t);
    expect(button, findsNothing);
    await t.tapAt(t.getCenter(find.byType(PageView)));
    await settleReader(t);
    expect(button, findsOneWidget);
  });
}
