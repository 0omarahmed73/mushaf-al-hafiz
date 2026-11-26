// The day view (feature 014, US1, FR-010, FR-011, FR-013, FR-014, contracts/ui.md): six times, the next prayer and its
// countdown, the Hijri date, the lines that appear only when they apply; both looks; 320 dp with a 2x font.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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

void main() {
  testWidgets(
    'six rows with the right times; Asr is next at 13:00; its row is marked',
    (t) async {
      await pumpPrayer(t, initial: _on, now: cairoTime(2026, 3, 1, 13));
      final day = PrayerCalc.day(DateTime(2026, 3, 1), kCairo, _on);
      for (final p in Prayer.values) {
        final row = _k('prayer-row-${p.name}');
        expect(row, findsOneWidget);
        expect(
          find.descendant(of: row, matching: find.text(_shown(day.utc[p]!))),
          findsOneWidget,
          reason: p.name,
        );
        expect(
          find.descendant(of: row, matching: find.text(kPrayerNames[p.index])),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: _k('prayer-next'),
          matching: find.text('العصر'),
        ),
        findsOneWidget,
      );
      expect(t.getSemantics(_k('prayer-row-asr')).value, kNextMark);
      expect(_k('prayer-bell-sunrise'), findsNothing);
      for (final p in kFivePrayers) {
        expect(_k('prayer-bell-${p.name}'), findsOneWidget);
      }
    },
  );

  testWidgets('the countdown ticks each second', (t) async {
    final rig = await pumpPrayer(
      t,
      initial: _on,
      now: cairoTime(2026, 3, 1, 13),
    );
    final asr = PrayerCalc.day(
      DateTime(2026, 3, 1),
      kCairo,
      _on,
    ).utc[Prayer.asr]!;
    expect(find.text(countdown(asr.difference(rig.now))), findsOneWidget);
    rig.now = rig.now.add(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    expect(find.text(countdown(asr.difference(rig.now))), findsOneWidget);
  });

  testWidgets(
    'after Isha the next prayer is tomorrow\'s Fajr; the date moves after midnight',
    (t) async {
      final rig = await pumpPrayer(
        t,
        initial: _on,
        now: cairoTime(2026, 3, 1, 23, 50),
      );
      expect(
        find.descendant(
          of: _k('prayer-next'),
          matching: find.text('الفجر'),
        ),
        findsOneWidget,
      );
      final before = (t.widget(
        find.descendant(of: _k('prayer-hijri'), matching: find.byType(Text)),
      ) as Text).data;
      rig.now = cairoTime(2026, 3, 2, 0, 5);
      await t.pump(const Duration(seconds: 1));
      final tomorrow = PrayerCalc.day(DateTime(2026, 3, 2), kCairo, _on);
      expect(
        find.descendant(
          of: _k('prayer-row-fajr'),
          matching: find.text(_shown(tomorrow.utc[Prayer.fajr]!)),
        ),
        findsOneWidget,
      );
      final after = (t.widget(
        find.descendant(of: _k('prayer-hijri'), matching: find.byType(Text)),
      ) as Text).data;
      expect(after, isNot(before));
    },
  );

  testWidgets(
    'the zone line shows only when the phone zone differs; the high-latitude line only up north',
    (t) async {
      await pumpPrayer(t, initial: _on, phoneZone: 'Africa/Cairo');
      expect(_k('zone-differs'), findsNothing);
      expect(_k('high-lat'), findsNothing);
    },
  );

  testWidgets('a different phone zone shows its line', (t) async {
    await pumpPrayer(t, initial: _on, phoneZone: 'Europe/London');
    expect(_k('zone-differs'), findsOneWidget);
  });

  testWidgets('a high-latitude place shows its line', (t) async {
    await pumpPrayer(
      t,
      initial: const PrayerSettings(
        enabled: true,
        place: Place(
          lat: 59.9,
          lon: 10.7,
          zone: 'Europe/Oslo',
          name: 'Oslo',
          source: PlaceSource.list,
          country: 'NO',
        ),
      ),
      phoneZone: 'Europe/Oslo',
    );
    expect(_k('high-lat'), findsOneWidget);
  });

  for (final look in [AppLook.emerald, AppLook.night]) {
    testWidgets(
      '${look == AppLook.night ? 'Night' : 'Emerald'}: contrast and 320 dp with a 2x font',
      (t) async {
        await pumpPrayer(t, initial: _on, look: look);
        expect(contrastIssues(t), isEmpty);
        await pumpPrayer(
          t,
          initial: _on,
          look: look,
          size: const Size(320, 700),
          textScale: 2,
        );
        expect(t.takeException(), isNull);
        expect(_k('prayer-day'), findsOneWidget);
      },
    );
  }
}
