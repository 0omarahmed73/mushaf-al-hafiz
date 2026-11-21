// «حول التطبيق» tells where the khatm dua's wording comes from, honestly (spec FR-016; research D6; Constitution V).
// A new test file: the About tests of earlier features stay as they are.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/khatm/dua_strings.dart';
import 'package:mushaf/settings/about_screen.dart';

import '../support/harness.dart';

Future<void> show(WidgetTester t, String text) async {
  await t.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await t.ensureVisible(find.text(text));
  await t.pump();
}

void main() {
  testWidgets(
    'one credit row names the dua, its use and the honest source note',
    (t) async {
      await pumpAppWith(t, home: const AboutScreen(), defaults: false);
      await show(t, kDuaCreditName);
      expect(find.text(kDuaCreditName), findsOneWidget);
      expect(find.text(kDuaCreditUse), findsOneWidget);
      expect(find.text(kDuaCreditNote), findsOneWidget);
      expect(
        AboutScreen.credits.where((c) => c.$1 == kDuaCreditName),
        hasLength(1),
        reason: 'one row, no second dua',
      );
    },
  );

  testWidgets('the note says there is no fixed text from the Prophet ﷺ', (
    t,
  ) async {
    expect(kDuaCreditNote, contains('لا يوجد نص ثابت عن النبي ﷺ'));
    expect(kDuaCreditNote, contains('متداولة'));
  });

  testWidgets('the row fits a 320 dp phone with a 2x system font', (t) async {
    await pumpAppWith(t, home: const AboutScreen(), defaults: false);
    t.view.physicalSize = const Size(320, 640);
    t.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await t.pump();
    await show(t, kDuaCreditNote);
    expect(t.takeException(), isNull);
  });
}
