// The Hijri date of the prayer screen (feature 014, research D9): the tabular Islamic calendar (30-year cycle, leap
// years 2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29). It can differ by a day from the month as announced.
import 'package:flutter/foundation.dart';

import 'prayer_strings.dart';

const List<String> kHijriMonths = [
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الآخر',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];

@immutable
class HijriDate {
  const HijriDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  /// The Julian day number of a Gregorian date (at noon).
  static int _jdn(int y, int m, int d) {
    final a = (14 - m) ~/ 12;
    final yy = y + 4800 - a;
    final mm = m + 12 * a - 3;
    return d +
        (153 * mm + 2) ~/ 5 +
        365 * yy +
        yy ~/ 4 -
        yy ~/ 100 +
        yy ~/ 400 -
        32045;
  }

  /// The tabular Hijri date of the Gregorian [date] (only its year, month and day count).
  static HijriDate fromGregorian(DateTime date) {
    // Days since 1 Muharram 1 AH (Julian day 1948440, civil epoch).
    final days = _jdn(date.year, date.month, date.day) - 1948440;
    final cycle = days ~/ 10631; // 30 years
    var rest = days % 10631;
    var year = cycle * 30;
    var y = 0;
    while (true) {
      final len = _isLeap(y + 1) ? 355 : 354;
      if (rest < len) break;
      rest -= len;
      y++;
    }
    year += y + 1;
    var month = 1;
    while (true) {
      final len = month.isOdd || (month == 12 && _isLeap(year)) ? 30 : 29;
      if (rest < len) break;
      rest -= len;
      month++;
    }
    return HijriDate(year, month, rest + 1);
  }

  static bool _isLeap(int year) => (14 + 11 * year) % 30 < 11;

  /// «١ رمضان ١٤٤٧ هـ».
  String format() =>
      '${indic(day)} ${kHijriMonths[month - 1]} ${indic(year)} $kHijriSuffix';

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$year-$month-$day';
}
