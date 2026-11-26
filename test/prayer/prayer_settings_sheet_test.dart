// Adjusting the calculation (feature 014, US3, FR-007..FR-009, FR-015, FR-017, contracts/ui.md).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/prayer/prayer_settings.dart';
import 'package:mushaf/theme.dart';

import 'prayer_harness.dart';

Finder _k(String key) => find.byKey(ValueKey(key));

const PrayerSettings _on = PrayerSettings(enabled: true, place: kCairo);

/// Scrolls the list on screen (down, else up) until [f] is built, then brings it fully into view.
Future<void> _reveal(WidgetTester t, Finder f) async {
  final list = find.byType(Scrollable).last;
  try {
    await t.scrollUntilVisible(f, 120, scrollable: list, maxScrolls: 200);
  } on StateError {
    await t.scrollUntilVisible(f, -120, scrollable: list, maxScrolls: 200);
  }
  await t.ensureVisible(f);
  await t.pumpAndSettle();
}

Future<void> _open(WidgetTester t) async {
  await _reveal(t, _k('prayer-settings'));
  await t.tap(_k('prayer-settings'));
  await t.pumpAndSettle();
  expect(_k('prayer-settings-sheet'), findsOneWidget);
}

Future<void> _tapIn(WidgetTester t, String key) async {
  await _reveal(t, _k(key));
  await t.tap(_k(key));
  await settlePrayer(t);
}

void main() {
  testWidgets('the method list starts with auto; a choice is saved', (t) async {
    final rig = await pumpPrayer(t, initial: _on);
    await _open(t);
    await _tapIn(t, 'set-method');
    await t.pumpAndSettle();
    final first = find.byKey(const ValueKey('method-auto'));
    expect(first, findsOneWidget);
    expect(find.text('تلقائي (حسب البلد)'), findsWidgets);
    await t.tap(find.byKey(const ValueKey('method-muslimWorldLeague')));
    await settlePrayer(t);
    await t.pumpAndSettle();
    expect((await rig.settings(t)).method, 'muslimWorldLeague');
  });

  testWidgets('the Asr rule switches', (t) async {
    final rig = await pumpPrayer(t, initial: _on);
    await _open(t);
    await _tapIn(t, 'set-asr-hanafi');
    expect((await rig.settings(t)).asr, AsrRule.hanafi);
    await _tapIn(t, 'set-asr-standard');
    expect((await rig.settings(t)).asr, AsrRule.standard);
  });

  testWidgets('offset steppers clamp at −30..+30', (t) async {
    final rig = await pumpPrayer(
      t,
      initial: _on.copyWith(offsets: const [0, 0, 0, 0, 29, 0]),
    );
    await _open(t);
    await _tapIn(t, 'set-offset-maghrib-plus');
    await _tapIn(t, 'set-offset-maghrib-plus');
    expect((await rig.settings(t)).offsets[4], 30);
    await _tapIn(t, 'set-offset-maghrib-minus');
    expect((await rig.settings(t)).offsets[4], 29);
    await _reveal(t, _k('set-offset-sunrise-plus'));
    expect(
      _k('set-offset-sunrise-plus'),
      findsOneWidget,
      reason: 'sunrise has an offset too',
    );
  });

  testWidgets('per prayer: the mode and the reminder before', (t) async {
    final rig = await pumpPrayer(t, initial: _on);
    await _open(t);
    await _tapIn(t, 'set-notify-isha-silent');
    expect((await rig.settings(t)).notify[4].mode, NotifyMode.silent);
    await _tapIn(t, 'set-before-isha');
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('before-15')).last);
    await settlePrayer(t);
    await t.pumpAndSettle();
    expect(
      (await rig.settings(t)).notify[4],
      const PrayerNotify(NotifyMode.silent, 15),
    );
  });

  for (final look in [AppLook.emerald, AppLook.night]) {
    testWidgets(
      '${look == AppLook.night ? 'Night' : 'Emerald'}: 320 dp with a 2x font',
      (t) async {
        await pumpPrayer(
          t,
          initial: _on,
          look: look,
          size: const Size(320, 700),
          textScale: 2,
        );
        await _open(t);
        expect(t.takeException(), isNull);
      },
    );
  }
}
