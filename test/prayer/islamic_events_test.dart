// The Islamic days the month table names (the owner, 2026-11-26): fixed Hijri dates on the app's tabular calendar,
// which can be a day off the announced month. Their names are proposals until the owner confirms them (Principle VI).
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/prayer/hijri.dart';
import 'package:mushaf/prayer/islamic_events.dart';

void main() {
  test('each event is on its Hijri day', () {
    const cases = {
      (1, 1): 'رأس السنة الهجرية',
      (1, 10): 'يوم عاشوراء',
      (3, 12): 'المولد النبوي',
      (9, 1): 'أول رمضان',
      (9, 21): 'العشر الأواخر من رمضان',
      (10, 1): 'عيد الفطر',
      (12, 9): 'يوم عرفة',
      (12, 10): 'عيد الأضحى',
      (12, 11): 'أيام التشريق',
      (12, 12): 'أيام التشريق',
      (12, 13): 'أيام التشريق',
    };
    for (final e in cases.entries) {
      final (m, d) = e.key;
      expect(islamicEvent(HijriDate(1447, m, d)), e.value, reason: '$m/$d');
    }
  });

  test('an ordinary day has no event', () {
    expect(islamicEvent(const HijriDate(1448, 6, 16)), isNull);
    expect(islamicEvent(const HijriDate(1447, 9, 2)), isNull);
    expect(islamicEvent(const HijriDate(1447, 12, 14)), isNull);
  });

  test('Ramadan 1447 begins in February 2026 on the tabular calendar', () {
    final firsts = [
      for (var d = 1; d <= 28; d++)
        if (islamicEvent(HijriDate.fromGregorian(DateTime(2026, 2, d))) ==
            'أول رمضان')
          d,
    ];
    expect(firsts, hasLength(1));
    expect(firsts.single, inInclusiveRange(17, 19));
  });
}
