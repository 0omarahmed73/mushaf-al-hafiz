// The month table as design C «أيام تتفتح» (the owner's pick, 2026-11-26): month chips, a card per day with the Fajr and
// Maghrib times, today open with all six, a tap opens any day, and the Islamic days are named on their card.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/prayer/hijri.dart';
import 'package:mushaf/prayer/islamic_events.dart';
import 'package:mushaf/prayer/prayer_calc.dart';
import 'package:mushaf/prayer/prayer_settings.dart';
import 'package:mushaf/prayer/prayer_strings.dart';
import 'package:mushaf/theme.dart';
import 'package:timezone/timezone.dart' as tz;

import '../support/contrast_walk.dart';
import 'prayer_harness.dart';

Finder _k(String key) => find.byKey(ValueKey(key));

const PrayerSettings _on = PrayerSettings(enabled: true, place: kCairo);

String _shown(DateTime utc) {
  final l = tz.TZDateTime.from(utc, tz.getLocation('Africa/Cairo'));
  return prayerTime(l.hour, l.minute);
}

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
  for (final scale in [1.0, 2.0]) {
    testWidgets('the four chips sit in one row as in design C (font x$scale)', (
      t,
    ) async {
      await pumpPrayer(
        t,
        initial: _on,
        now: cairoTime(2026, 2, 10, 9),
        size: scale == 1 ? const Size(412, 915) : const Size(320, 700),
        textScale: scale,
      );
      await _open(t);
      final keys = ['month-prev', 'month-current', 'month-next', 'month-next2'];
      // The chips are 40 px pills as drawn; the outlined ones keep a 48 px tap area around theirs, so the row is
      // checked by centre line.
      final mids = [for (final k in keys) t.getRect(_k(k)).center.dy];
      for (final m in mids) {
        expect(m, closeTo(mids.first, 0.5), reason: 'one row');
      }
      if (scale == 1) {
        expect(t.getRect(_k('month-current')).width, lessThan(412 * 0.5));
        expect(t.getRect(_k('month-current')).height, closeTo(40, 1));
      }
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('the chip two months on moves two months', (t) async {
    await pumpPrayer(t, initial: _on, now: cairoTime(2026, 2, 10, 9));
    await _open(t);
    expect(
      find.descendant(of: _k('month-next2'), matching: find.text(monthName(4))),
      findsOneWidget,
    );
    // The chip row scrolls sideways when the chips are wider than the screen (the test font is wide).
    await t.ensureVisible(_k('month-next2'));
    await t.pumpAndSettle();
    await t.tap(_k('month-next2'));
    await t.pumpAndSettle();
    expect(
      find.descendant(
        of: _k('month-current'),
        matching: find.text(monthTitle(2026, 4)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the chips name the months around this one', (t) async {
    await pumpPrayer(t, initial: _on, now: cairoTime(2026, 2, 10, 9));
    await _open(t);
    expect(
      find.descendant(of: _k('month-prev'), matching: find.text(monthName(1))),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _k('month-current'),
        matching: find.text(monthTitle(2026, 2)),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _k('month-next'), matching: find.text(monthName(3))),
      findsOneWidget,
    );
  });

  testWidgets(
    'today is open with its six times and is on screen when the table opens',
    (t) async {
      await pumpPrayer(t, initial: _on, now: cairoTime(2026, 2, 25, 9));
      await _open(t);
      expect(_k('month-times-25'), findsOneWidget);
      expect(t.getRect(_k('month-day-25')).top, lessThan(700));
      final day = PrayerCalc.day(DateTime(2026, 2, 25), kCairo, _on);
      for (final p in Prayer.values) {
        final cell = _k('month-time-25-${p.name}');
        expect(
          find.descendant(of: cell, matching: find.text(kPrayerNames[p.index])),
          findsOneWidget,
        );
        expect(
          find.descendant(of: cell, matching: find.text(_shown(day.utc[p]!))),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: _k('month-day-25'),
          matching: find.textContaining(kToday),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a closed day shows Fajr and Maghrib; a tap opens it and a second tap closes it',
    (t) async {
      await pumpPrayer(t, initial: _on, now: cairoTime(2026, 2, 10, 9));
      await _open(t);
      await _reveal(t, _k('month-day-17'));
      final day = PrayerCalc.day(DateTime(2026, 2, 17), kCairo, _on);
      expect(
        find.descendant(
          of: _k('month-day-17'),
          matching: find.text(
            monthSummary(
              _shown(day.utc[Prayer.fajr]!),
              _shown(day.utc[Prayer.maghrib]!),
            ),
          ),
        ),
        findsOneWidget,
      );
      expect(_k('month-times-17'), findsNothing);
      await t.tap(_k('month-open-17'));
      await t.pumpAndSettle();
      expect(_k('month-times-17'), findsOneWidget);
      await t.tap(_k('month-open-17'));
      await t.pumpAndSettle();
      expect(_k('month-times-17'), findsNothing);
    },
  );

  testWidgets(
    'February 2026: the first of Ramadan is named on its card, and no other day is',
    (t) async {
      await pumpPrayer(t, initial: _on, now: cairoTime(2026, 2, 10, 9));
      await _open(t);
      final first = [
        for (var d = 1; d <= 28; d++)
          if (islamicEvent(HijriDate.fromGregorian(DateTime(2026, 2, d))) !=
              null)
            d,
      ];
      expect(first, hasLength(1));
      final d = first.single;
      await _reveal(t, _k('month-event-$d'));
      expect(
        find.descendant(
          of: _k('month-event-$d'),
          matching: find.text('أول رمضان'),
        ),
        findsOneWidget,
      );
      await _reveal(t, _k('month-day-${d + 1}'));
      expect(_k('month-event-${d + 1}'), findsNothing);
    },
  );

  for (final look in [AppLook.emerald, AppLook.night]) {
    final name = look == AppLook.night ? 'Night' : 'Emerald';
    testWidgets('$name: contrast', (t) async {
      await pumpPrayer(
        t,
        initial: _on,
        look: look,
        now: cairoTime(2026, 2, 18, 9),
      );
      await _open(t);
      expect(contrastIssues(t), isEmpty);
    });

    testWidgets('$name: 320 dp with a 2x font', (t) async {
      await pumpPrayer(
        t,
        initial: _on,
        look: look,
        size: const Size(320, 700),
        textScale: 2,
        now: cairoTime(2026, 2, 18, 9),
      );
      await _open(t);
      expect(t.takeException(), isNull);
    });
  }
}
