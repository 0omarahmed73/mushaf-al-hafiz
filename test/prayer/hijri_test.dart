// The Hijri date of the prayer screen: the tabular (arithmetic) calendar, which may differ by a day from the announced
// month (feature 014, research D9).
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/prayer/hijri.dart';

/// The Gregorian day, within [from]..[to], whose Hijri date is [y]/[m]/1.
DateTime? _first(int y, int m, DateTime from, DateTime to) {
  for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
    final h = HijriDate.fromGregorian(d);
    if (h.year == y && h.month == m && h.day == 1) return d;
  }
  return null;
}

void main() {
  test('1 Ramadan 1447 is within a day of 18 February 2026', () {
    final d = _first(1447, 9, DateTime(2026, 2, 10), DateTime(2026, 2, 28));
    expect(d, isNotNull);
    expect(
      d!.difference(DateTime(2026, 2, 18)).inDays.abs(),
      lessThanOrEqualTo(1),
    );
  });

  test('1 Muharram 1448 is within a day of 16 June 2026', () {
    final d = _first(1448, 1, DateTime(2026, 6, 5), DateTime(2026, 6, 25));
    expect(d, isNotNull);
    expect(
      d!.difference(DateTime(2026, 6, 16)).inDays.abs(),
      lessThanOrEqualTo(1),
    );
  });

  test('days run 1..29 or 30 and months 1..12 for two years without a gap', () {
    var prev = HijriDate.fromGregorian(DateTime(2026, 1, 1));
    for (var i = 1; i < 730; i++) {
      final h = HijriDate.fromGregorian(
        DateTime(2026, 1, 1).add(Duration(days: i)),
      );
      if (h.day == 1) {
        expect(prev.day, anyOf(29, 30));
        expect(h.month, prev.month == 12 ? 1 : prev.month + 1);
      } else {
        expect(h.day, prev.day + 1);
        expect(h.month, prev.month);
      }
      prev = h;
    }
  });

  test('format: «١ رمضان ١٤٤٧ هـ»', () {
    expect(const HijriDate(1447, 9, 1).format(), '١ رمضان ١٤٤٧ هـ');
    expect(const HijriDate(1448, 1, 10).format(), '١٠ محرم ١٤٤٨ هـ');
    expect(const HijriDate(1447, 12, 9).format(), '٩ ذو الحجة ١٤٤٧ هـ');
  });
}
