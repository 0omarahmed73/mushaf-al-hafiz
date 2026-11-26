// The month's timetable (feature 014, US4, FR-012, contracts/ui.md).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/prayer/prayer_calc.dart';
import 'package:mushaf/prayer/prayer_settings.dart';
import 'package:mushaf/prayer/prayer_strings.dart';
import 'package:mushaf/theme.dart';
import 'package:timezone/timezone.dart' as tz;

import 'prayer_harness.dart';

Finder _k(String key) => find.byKey(ValueKey(key));

const PrayerSettings _on = PrayerSettings(enabled: true, place: kCairo);

String _shown(DateTime utc) {
  final l = tz.TZDateTime.from(utc, tz.getLocation('Africa/Cairo'));
  return prayerTime(l.hour, l.minute);
}

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
  await _reveal(t, _k('prayer-month'));
  await t.tap(_k('prayer-month'));
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'February 2026: 28 rows, today marked, each row equal to the day calculation',
    (t) async {
      await pumpPrayer(t, initial: _on, now: cairoTime(2026, 2, 10, 9));
      await _open(t);
      expect(_k('prayer-month-screen'), findsOneWidget);
      await _reveal(t, _k('month-day-10'));
      expect(
        find.descendant(of: _k('month-day-10'), matching: _k('month-today')),
        findsOneWidget,
      );
      for (var d = 1; d <= 28; d++) {
        await _reveal(t, _k('month-day-$d'));
      }
      expect(_k('month-day-29'), findsNothing);
      // Design C (2026-11-26): a day's six times show when it is opened.
      await _reveal(t, _k('month-open-17'));
      await t.tap(_k('month-open-17'));
      await t.pumpAndSettle();
      final day = PrayerCalc.day(DateTime(2026, 2, 17), kCairo, _on);
      for (final p in Prayer.values) {
        expect(
          find.descendant(
            of: _k('month-time-17-${p.name}'),
            matching: find.text(_shown(day.utc[p]!)),
          ),
          findsOneWidget,
          reason: p.name,
        );
      }
    },
  );

  testWidgets('next and previous months', (t) async {
    await pumpPrayer(t, initial: _on, now: cairoTime(2026, 2, 10, 9));
    await _open(t);
    await t.tap(_k('month-next'));
    await t.pumpAndSettle();
    await _reveal(t, _k('month-day-31'));
    expect(_k('month-today'), findsNothing, reason: 'March has no today');
    await t.tap(_k('month-prev'));
    await t.tap(_k('month-prev'));
    await t.pumpAndSettle();
    await _reveal(t, _k('month-day-31'));
    expect(_k('month-day-31'), findsOneWidget, reason: 'January');
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
