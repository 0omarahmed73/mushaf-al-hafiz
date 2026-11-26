// The sun-arc day view the owner chose on 2026-11-26 (design A «قوس الشمس», research D13): the next prayer in a hero
// card under an arc that shows where the sun is between sunrise and maghrib; three equal icon tiles for the month,
// the settings and the test (the owner's pick, 2026-11-26); the battery help and the off switch are quiet text buttons.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/prayer/prayer_calc.dart';
import 'package:mushaf/prayer/prayer_settings.dart';
import 'package:mushaf/prayer/prayer_strings.dart';
import 'package:mushaf/prayer/sun_arc.dart';
import 'package:mushaf/theme.dart';
import 'package:timezone/timezone.dart' as tz;

import '../support/contrast_walk.dart';
import 'prayer_harness.dart';

Finder _k(String key) => find.byKey(ValueKey(key));

const PrayerSettings _on = PrayerSettings(enabled: true, place: kCairo);

SunArcPainter _painter(WidgetTester t) {
  final paint = t.widget<CustomPaint>(
    find.descendant(of: _k('prayer-arc'), matching: find.byType(CustomPaint)),
  );
  return paint.painter! as SunArcPainter;
}

void main() {
  test('the sun fraction: 0 at sunrise, 1 at maghrib, null at night', () {
    final day = PrayerCalc.day(DateTime(2026, 3, 1), kCairo, _on);
    final rise = day.utc[Prayer.sunrise]!, set = day.utc[Prayer.maghrib]!;
    expect(sunFraction(day, rise), 0);
    expect(sunFraction(day, set), 1);
    final mid = rise.add(set.difference(rise) ~/ 2);
    expect(sunFraction(day, mid), closeTo(0.5, 0.001));
    expect(sunFraction(day, rise.subtract(const Duration(minutes: 1))), isNull);
    expect(sunFraction(day, set.add(const Duration(minutes: 1))), isNull);
  });

  testWidgets(
    'the hero shows the next prayer, its countdown and its time under the arc',
    (t) async {
      final rig = await pumpPrayer(
        t,
        initial: _on,
        now: cairoTime(2026, 3, 1, 13),
      );
      final day = PrayerCalc.day(DateTime(2026, 3, 1), kCairo, _on);
      final asr = day.utc[Prayer.asr]!;
      final local = tz.TZDateTime.from(asr, tz.getLocation('Africa/Cairo'));
      final hero = _k('prayer-next');
      for (final text in [
        kNextPrayer,
        'العصر',
        countdown(asr.difference(rig.now)),
        atClock(prayerTime(local.hour, local.minute)),
      ]) {
        expect(
          find.descendant(of: hero, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
      expect(
        find.descendant(of: hero, matching: _k('prayer-arc')),
        findsOneWidget,
      );
      final p = _painter(t);
      expect(p.next, Prayer.asr);
      expect(p.sun, sunFraction(day, rig.now));
      expect(p.sun, greaterThan(p.marks[Prayer.dhuhr]!));
      expect(p.sun, lessThan(p.marks[Prayer.asr]!));
    },
  );

  testWidgets(
    'after maghrib the sun is not drawn; the next mark is tomorrow\'s Fajr',
    (t) async {
      await pumpPrayer(t, initial: _on, now: cairoTime(2026, 3, 1, 23, 50));
      final p = _painter(t);
      expect(p.sun, isNull);
      expect(p.next, Prayer.fajr);
    },
  );

  test('right to left: the morning is on the right', () {
    const size = Size(340, 160);
    SunArcPainter arc(TextDirection d) => SunArcPainter(
      marks: const {Prayer.sunrise: 0, Prayer.maghrib: 1},
      sun: null,
      next: Prayer.asr,
      nextLabel: 'العصر',
      direction: d,
      line: const Color(0xFF000000),
      dot: const Color(0xFF000000),
      accent: const Color(0xFF000000),
    );
    expect(
      arc(TextDirection.rtl).point(0, size).dx,
      greaterThan(arc(TextDirection.rtl).point(1, size).dx),
    );
    expect(
      arc(TextDirection.ltr).point(0, size).dx,
      lessThan(arc(TextDirection.ltr).point(1, size).dx),
    );
    expect(
      arc(TextDirection.rtl).point(0.5, size).dy,
      lessThan(arc(TextDirection.rtl).point(0, size).dy),
    );
  });

  testWidgets(
    'three equal icon tiles in one row; battery help and the off switch are text buttons',
    (t) async {
      await pumpPrayer(t, initial: _on);
      final tiles = ['prayer-month', 'prayer-settings', 'prayer-test'];
      final rects = [for (final k in tiles) t.getRect(_k(k))];
      for (final k in tiles) {
        expect(t.widget(_k(k)), isA<OutlinedButton>(), reason: k);
        expect(
          find.descendant(of: _k(k), matching: find.byType(Icon)),
          findsOneWidget,
          reason: k,
        );
      }
      for (final r in rects.skip(1)) {
        expect(r.top, rects.first.top);
        expect(r.width, closeTo(rects.first.width, 0.5));
        expect(r.height, rects.first.height);
      }
      expect(t.widget(_k('prayer-battery')), isA<TextButton>());
      expect(t.widget(_k('prayer-disable')), isA<TextButton>());
    },
  );

  testWidgets('the next prayer\'s name is in the heading font, Cairo, bold', (
    t,
  ) async {
    await pumpPrayer(t, initial: _on, now: cairoTime(2026, 3, 1, 13));
    final name = t.widget<Text>(
      find.descendant(of: _k('prayer-next'), matching: find.text('العصر')),
    );
    expect(name.style!.fontFamily, 'Cairo');
    expect(name.style!.fontWeight, FontWeight.w700);
  });

  testWidgets('at 320 dp with a 2x font the tiles fit', (t) async {
    await pumpPrayer(t, initial: _on, size: const Size(320, 700), textScale: 2);
    expect(t.takeException(), isNull);
  });

  for (final look in [AppLook.emerald, AppLook.night]) {
    testWidgets(
      '${look == AppLook.night ? 'Night' : 'Emerald'}: the next row is outlined in the accent',
      (t) async {
        await pumpPrayer(
          t,
          initial: _on,
          look: look,
          now: cairoTime(2026, 3, 1, 13),
        );
        BoxDecoration deco(String p) =>
            t
                    .widget<Container>(
                      find
                          .descendant(
                            of: _k('prayer-row-$p'),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration!
                as BoxDecoration;
        expect((deco('asr').border! as Border).top.color, look.accent);
        expect((deco('dhuhr').border! as Border).top.color, isNot(look.accent));
        expect(contrastIssues(t), isEmpty);
      },
    );
  }

  testWidgets('the arc labels its prayer in Cairo, like the rest of the app', (
    t,
  ) async {
    await pumpPrayer(t, initial: _on, now: cairoTime(2026, 3, 1, 13));
    expect(_painter(t).labelStyle.fontFamily, 'Cairo');
  });

  testWidgets('the hero is set tight, as in the design: lines close together', (
    t,
  ) async {
    await pumpPrayer(t, initial: _on, now: cairoTime(2026, 3, 1, 13));
    final hero = _k('prayer-next');
    Rect box(String text) =>
        t.getRect(find.descendant(of: hero, matching: find.text(text)));
    final day = PrayerCalc.day(DateTime(2026, 3, 1), kCairo, _on);
    final asr = day.utc[Prayer.asr]!;
    final local = tz.TZDateTime.from(asr, tz.getLocation('Africa/Cairo'));
    final label = box(kNextPrayer);
    final name = box('العصر');
    final clock = box(atClock(prayerTime(local.hour, local.minute)));
    // Design A: 14 px label, 40 px name at line height 1.1, 6 px between lines.
    expect(name.height, lessThanOrEqualTo(40 * 1.2 + 1));
    expect(label.height, lessThanOrEqualTo(14 * 1.35 + 1));
    expect(name.top - label.bottom, inInclusiveRange(4, 8));
    expect(clock.height, lessThanOrEqualTo(15 * 1.35 + 1));
  });

  testWidgets(
    '«تقريبًا» is small and quiet next to the city name, as in design A',
    (t) async {
      await pumpPrayer(
        t,
        initial: const PrayerSettings(
          enabled: true,
          place: Place(
            lat: 30.04,
            lon: 31.24,
            zone: 'Africa/Cairo',
            name: 'القاهرة',
            source: PlaceSource.location,
            country: 'EG',
          ),
        ),
      );
      final name = t.widget<Text>(find.text('القاهرة'));
      final approx = t.widget<Text>(find.text(kApprox));
      expect(name.style!.fontSize, 18);
      expect(approx.style!.fontSize, 13);
      expect(approx.style!.color, AppLook.emerald.textSecondary);
    },
  );
}
