// Prayer times calculated on the phone (feature 014, FR-006..FR-010, SC-001, research D1, D2, D5).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/prayer/prayer_calc.dart';
import 'package:mushaf/prayer/prayer_settings.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Place _place(double lat, double lon, String zone, String cc) => Place(
  lat: lat,
  lon: lon,
  zone: zone,
  name: 'x',
  source: PlaceSource.list,
  country: cc,
);

String _hm(DateTime utc, String zone) {
  final l = tz.TZDateTime.from(utc, tz.getLocation(zone));
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

int _minutes(String hm) =>
    int.parse(hm.substring(0, 2)) * 60 + int.parse(hm.substring(3));

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('Egypt: every published time is within one minute (SC-001)', () {
    final f = jsonDecode(
      File('test/prayer/fixtures/egypt_2026.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final MapEntry(key: city, value: c)
        in (f['cities'] as Map<String, dynamic>).entries) {
      final place = _place(
        c['lat'] as double,
        c['lon'] as double,
        'Africa/Cairo',
        'EG',
      );
      for (final MapEntry(key: date, value: times)
          in (c['times'] as Map<String, dynamic>).entries) {
        final day = PrayerCalc.day(
          DateTime.parse(date),
          place,
          const PrayerSettings(),
        );
        for (final p in Prayer.values) {
          final got = _hm(day.utc[p]!, 'Africa/Cairo');
          final want = (times as List)[p.index] as String;
          expect(
            (_minutes(got) - _minutes(want)).abs(),
            lessThanOrEqualTo(1),
            reason: '$city $date ${p.name}: $got vs $want',
          );
        }
      }
    }
  });

  test('methodFor follows the country', () {
    expect(PrayerCalc.methodFor('EG'), 'egyptian');
    expect(PrayerCalc.methodFor('SA'), 'ummAlQura');
    expect(PrayerCalc.methodFor('AE'), 'dubai');
    expect(PrayerCalc.methodFor('KW'), 'kuwait');
    expect(PrayerCalc.methodFor('QA'), 'qatar');
    expect(PrayerCalc.methodFor('MA'), 'morocco');
    expect(PrayerCalc.methodFor('TR'), 'turkiye');
    for (final cc in ['PK', 'IN', 'BD', 'AF']) {
      expect(PrayerCalc.methodFor(cc), 'karachi');
    }
    expect(PrayerCalc.methodFor('US'), 'northAmerica');
    expect(PrayerCalc.methodFor('CA'), 'northAmerica');
    expect(PrayerCalc.methodFor('NG'), 'muslimWorldLeague');
  });

  final cairo = _place(30.063, 31.25, 'Africa/Cairo', 'EG');

  test('a chosen method changes the times', () {
    final auto = PrayerCalc.day(
      DateTime(2026, 3, 1),
      cairo,
      const PrayerSettings(),
    );
    final mwl = PrayerCalc.day(
      DateTime(2026, 3, 1),
      cairo,
      const PrayerSettings(method: 'muslimWorldLeague'),
    );
    expect(auto.utc[Prayer.fajr], isNot(mwl.utc[Prayer.fajr]));
  });

  test('Hanafi Asr is later than standard', () {
    final std = PrayerCalc.day(
      DateTime(2026, 3, 1),
      cairo,
      const PrayerSettings(),
    );
    final han = PrayerCalc.day(
      DateTime(2026, 3, 1),
      cairo,
      const PrayerSettings(asr: AsrRule.hanafi),
    );
    expect(han.utc[Prayer.asr]!.isAfter(std.utc[Prayer.asr]!), isTrue);
  });

  test('an offset moves only its own time', () {
    final a = PrayerCalc.day(
      DateTime(2026, 3, 1),
      cairo,
      const PrayerSettings(),
    );
    final b = PrayerCalc.day(
      DateTime(2026, 3, 1),
      cairo,
      const PrayerSettings(offsets: [0, 0, 0, 0, 2, 0]),
    );
    for (final p in Prayer.values) {
      expect(
        b.utc[p]!.difference(a.utc[p]!),
        p == Prayer.maghrib ? const Duration(minutes: 2) : Duration.zero,
        reason: p.name,
      );
    }
  });

  test('next: after Dhuhr comes Asr; at 23:00 comes tomorrow\'s Fajr; sunrise is never next', () {
    final day = PrayerCalc.day(
      DateTime(2026, 3, 1),
      cairo,
      const PrayerSettings(),
    );
    final afterDhuhr = day.utc[Prayer.dhuhr]!.add(const Duration(minutes: 1));
    expect(
      PrayerCalc.next(afterDhuhr, cairo, const PrayerSettings()).$1,
      Prayer.asr,
    );
    final afterFajr = day.utc[Prayer.fajr]!.add(const Duration(minutes: 1));
    expect(
      PrayerCalc.next(afterFajr, cairo, const PrayerSettings()).$1,
      Prayer.dhuhr,
    );
    final late = tz.TZDateTime(
      tz.getLocation('Africa/Cairo'),
      2026,
      3,
      1,
      23,
    ).toUtc();
    final (p, at) = PrayerCalc.next(late, cairo, const PrayerSettings());
    expect(p, Prayer.fajr);
    expect(
      at,
      PrayerCalc.day(
        DateTime(2026, 3, 2),
        cairo,
        const PrayerSettings(),
      ).utc[Prayer.fajr],
    );
  });

  test('high latitude: Oslo in June is flagged and still ordered', () {
    final oslo = _place(59.91, 10.75, 'Europe/Oslo', 'NO');
    final day = PrayerCalc.day(
      DateTime(2026, 6, 21),
      oslo,
      const PrayerSettings(),
    );
    expect(day.highLatitude, isTrue);
    final times = [for (final p in Prayer.values) day.utc[p]!];
    for (var i = 1; i < times.length; i++) {
      expect(
        times[i].isAfter(times[i - 1]),
        isTrue,
        reason: '${Prayer.values[i]}',
      );
    }
    expect(
      PrayerCalc.day(
        DateTime(2026, 6, 21),
        cairo,
        const PrayerSettings(),
      ).highLatitude,
      isFalse,
    );
  });

  test('daylight saving: New York Dhuhr is near 12 before and near 13 after 8 March 2026', () {
    final ny = _place(40.71, -74.01, 'America/New_York', 'US');
    String dhuhr(int day) => _hm(
      PrayerCalc.day(
        DateTime(2026, 3, day),
        ny,
        const PrayerSettings(),
      ).utc[Prayer.dhuhr]!,
      'America/New_York',
    );
    expect(dhuhr(7).startsWith('12:'), isTrue, reason: dhuhr(7));
    expect(dhuhr(9).startsWith('13:'), isTrue, reason: dhuhr(9));
  });

  test('a month is calculated in under 100 ms', () {
    final w = Stopwatch()..start();
    for (var d = 1; d <= 31; d++) {
      PrayerCalc.day(DateTime(2026, 7, d), cairo, const PrayerSettings());
    }
    expect(w.elapsedMilliseconds, lessThan(100));
  });
}
