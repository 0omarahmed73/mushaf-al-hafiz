// The bottom bar's «استماع / قريبًا» placeholder becomes «مواقيت» (feature 014, FR-002, research D11). The bar's
// height and the page rectangle stay as they were.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/prayer/prayer_screen.dart';

import '../support/reader_harness.dart';

/// Measured on the code before the edit (commit 0482e4e), 412 x 915 at 100%: the bottom bar and the page number (which
/// sits at the foot of the page box, so it moves if the page does).
const Rect kBarBefore = Rect.fromLTRB(0.0, 847.0, 412.0, 915.0);
const Rect kNumberBefore = Rect.fromLTRB(191.8, 804.0, 220.3, 824.0);

Rect _rect(WidgetTester t, Finder f) => t.getRect(f.first);

void main() {
  testWidgets('«مواقيت» replaces «استماع»; the bar and the page do not move', (
    t,
  ) async {
    await pumpSizedReader(t);
    expect(find.byKey(const ValueKey('bar-prayer')), findsOneWidget);
    expect(find.text('مواقيت'), findsOneWidget);
    expect(find.text('استماع'), findsNothing);
    expect(find.byTooltip('مواقيت الصلاة'), findsOneWidget);
    expect(_rect(t, find.byKey(const ValueKey('bottom-bar'))), kBarBefore);
    final number = _rect(t, find.byKey(const ValueKey('page-number')));
    expect(number.top, kNumberBefore.top);
    expect(number.bottom, kNumberBefore.bottom);
    expect((number.center.dx - kNumberBefore.center.dx).abs(), lessThan(0.1));
  });

  testWidgets('tapping it opens the prayer screen', (t) async {
    await pumpSizedReader(t);
    await t.tap(find.byKey(const ValueKey('bar-prayer')));
    await settleReader(t);
    expect(find.byType(PrayerScreen), findsOneWidget);
  });

  // Not checked here: the bar at 320 dp with a large system font (it overflowed before this feature, 298 px on the
  // right on commit 0482e4e) is covered by test/mushaf/bottom_bar_large_font_test.dart.
}
