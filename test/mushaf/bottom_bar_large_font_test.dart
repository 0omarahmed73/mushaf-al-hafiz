// The reader's bottom bar with the phone's font made large (testers on a Samsung A52 and an S26 Ultra, 2026-11-26).
// At 320 dp wide with a 2x system text scale the Row of «مواقيت», «علامات», «أوراد», «اختبار» and the menu overflowed
// on the right, and the «اختبار / قريباً» column at the bottom. The bar must fit in both looks, every item stays a
// tappable 48 px target, and the 68 px slot and the page keep the place they have at a 1x font. The Mushaf page itself
// already ignores the system font (commit 50f0f11).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/prayer/prayer_screen.dart';

import '../support/reader_harness.dart' show settleReader;
import 'reader_night_test.dart' show pumpLookReader;

const Size kSmall = Size(320, 700);

/// Measured at 320 x 700 with a 1x font before the fix: the 68 px slot and the page number at the page's foot.
const Rect kSmallBar = Rect.fromLTRB(0, 632, 320, 700);
const Rect kSmallNumber = Rect.fromLTRB(145.8, 589, 174.3, 609);

/// Measured at 412 x 915 with a 1x font before the fix (commit 3124689): each item's tap box, from «مواقيت» to the
/// menu button. The fix must not move them.
const Map<LookChoice, List<Rect>> kItemsAt412 = {
  LookChoice.emerald: [
    Rect.fromLTRB(325.3, 857, 407.3, 905),
    Rect.fromLTRB(233.9, 857, 315.9, 905),
    Rect.fromLTRB(153.5, 857, 224.5, 905),
    Rect.fromLTRB(62.1, 850.5, 144.1, 911.5),
    Rect.fromLTRB(4.7, 857, 52.7, 905),
  ],
  LookChoice.night: [
    Rect.fromLTRB(312.5, 853, 394.5, 909),
    Rect.fromLTRB(227.5, 853, 309.5, 909),
    Rect.fromLTRB(153.5, 853, 224.5, 909),
    Rect.fromLTRB(68.5, 853, 150.5, 909),
    Rect.fromLTRB(17.5, 857, 65.5, 905),
  ],
};

Finder _inBar(Finder f) =>
    find.descendant(of: find.byKey(const ValueKey('bottom-bar')), matching: f);

Finder _itemOf(String label) =>
    find.ancestor(of: _inBar(find.text(label)), matching: find.byType(InkWell));

/// The five tap targets, from «مواقيت» to the menu button.
List<Finder> _targets() => [
  _itemOf('مواقيت'),
  _itemOf('علامات'),
  _itemOf('أوراد'),
  _itemOf('اختبار'),
  find.byKey(const ValueKey('open-settings')),
];

void _expectClose(Rect actual, Rect expected, String what) {
  for (final (a, e) in [
    (actual.left, expected.left),
    (actual.top, expected.top),
    (actual.right, expected.right),
    (actual.bottom, expected.bottom),
  ]) {
    expect(a, closeTo(e, 0.1), reason: '$what: $actual, expected $expected');
  }
}

Future<void> _pump(
  WidgetTester t,
  LookChoice choice, {
  double scale = 1,
  Size screen = kSmall,
}) async {
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  await pumpLookReader(t, choice: choice, screen: screen);
}

void main() {
  for (final choice in [LookChoice.emerald, LookChoice.night]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('$choice, 320 dp, system font x$scale: the bar fits', (
        t,
      ) async {
        await _pump(t, choice, scale: scale);
        expect(t.takeException(), isNull, reason: 'the bar overflowed');
        _expectClose(
          t.getRect(find.byKey(const ValueKey('bottom-bar'))),
          kSmallBar,
          'bar',
        );
        _expectClose(
          t.getRect(find.byKey(const ValueKey('page-number'))),
          kSmallNumber,
          'page number',
        );
        for (final target in _targets()) {
          expect(target, findsOneWidget);
          final r = t.getRect(target);
          expect(r.width, greaterThanOrEqualTo(48), reason: '$target: $r');
          expect(r.height, greaterThanOrEqualTo(48), reason: '$target: $r');
          expect(r.left, greaterThanOrEqualTo(0), reason: '$target: $r');
          expect(
            r.right,
            lessThanOrEqualTo(kSmall.width),
            reason: '$target: $r',
          );
          expect(r.top, greaterThanOrEqualTo(kSmallBar.top), reason: '$target');
          expect(
            r.bottom,
            lessThanOrEqualTo(kSmallBar.bottom),
            reason: '$target',
          );
          expect(target.hitTestable(), findsOneWidget, reason: '$target');
        }
        // Each label is shown whole inside its own item.
        for (final label in ['مواقيت', 'علامات', 'أوراد', 'اختبار', 'قريباً']) {
          final text = t.getRect(_inBar(find.text(label)));
          final item = t.getRect(_itemOf(label));
          expect(item.contains(text.topLeft), isTrue, reason: label);
          expect(
            item.contains(text.bottomRight - const Offset(0.01, 0.01)),
            isTrue,
            reason: label,
          );
        }
      });
    }

    testWidgets('$choice, 320 dp, system font x2: «مواقيت» opens', (t) async {
      await _pump(t, choice, scale: 2);
      await t.tap(find.byKey(const ValueKey('bar-prayer')));
      await settleReader(t);
      expect(find.byType(PrayerScreen), findsOneWidget);
    });

    testWidgets('$choice, 412 dp, 1x font: the items do not move', (t) async {
      await _pump(t, choice, screen: const Size(412, 915));
      final targets = _targets();
      for (var i = 0; i < targets.length; i++) {
        _expectClose(t.getRect(targets[i]), kItemsAt412[choice]![i], 'item $i');
      }
    });
  }
}
