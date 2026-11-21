import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/wirds/portion.dart';
import 'package:mushaf/wirds/wird_type.dart';

DateTime d(int y, int m, int day) => DateTime(y, m, day);

void main() {
  group('pagesPerDay', () {
    test('a fixed daily amount wins', () {
      expect(pagesPerDay(currentPage: 1, dailyPages: 20, today: d(2026, 11, 20)), 20);
      expect(
        pagesPerDay(currentPage: 1, dailyPages: 5, targetDate: d(2026, 12, 19), today: d(2026, 11, 20)),
        5,
        reason: 'pages per day wins over a target date',
      );
    });

    test('from a target date: ceil(remaining / days left), days inclusive', () {
      // 604 pages over the 30 days 2026-11-20 .. 2026-12-19 inclusive -> 21
      expect(pagesPerDay(currentPage: 1, targetDate: d(2026, 12, 19), today: d(2026, 11, 20)), 21);
      expect(pagesPerDay(currentPage: 1, targetDate: d(2026, 11, 20), today: d(2026, 11, 20)), 604);
    });

    test('a target date today or in the past means all remaining pages, never 0 or negative', () {
      expect(pagesPerDay(currentPage: 600, targetDate: d(2026, 11, 20), today: d(2026, 11, 20)), 5);
      expect(pagesPerDay(currentPage: 600, targetDate: d(2026, 11, 1), today: d(2026, 11, 20)), 5);
      expect(pagesPerDay(currentPage: 604, targetDate: d(2026, 11, 1), today: d(2026, 11, 20)), 1);
    });

    test('neither a goal nor a date means 20 pages', () {
      expect(pagesPerDay(currentPage: 1, today: d(2026, 11, 20)), 20);
    });

    test('time of day does not change the count of days left', () {
      expect(
        pagesPerDay(currentPage: 1, targetDate: d(2026, 12, 19), today: DateTime(2026, 11, 20, 23, 59)),
        21,
      );
    });
  });

  group('portionFor', () {
    test('adds the daily amount and clamps at page 604', () {
      expect(portionFor(startPage: 1, perDay: 20), (start: 1, end: 20));
      expect(portionFor(startPage: 600, perDay: 20), (start: 600, end: 604));
      expect(portionFor(startPage: 604, perDay: 20), (start: 604, end: 604));
    });
  });

  group('afterDone', () {
    test('moves to the page after the portion', () {
      expect(afterDone(20), (nextPage: 21, completedKhatma: false));
    });

    test('completing page 604 wraps to page 1 and finishes the khatma', () {
      expect(afterDone(604), (nextPage: 1, completedKhatma: true));
    });
  });

  group('wird day keys', () {
    test('dayKey is the local calendar date', () {
      expect(dayKey(DateTime(2026, 11, 20, 23, 59)), '2026-11-20');
      expect(dayKey(DateTime(2026, 1, 5, 0, 0)), '2026-01-05');
    });

    test('reading wirds change day at midnight', () {
      expect(wirdDayKey(WirdType.reading, DateTime(2026, 11, 21, 1, 0)), '2026-11-21');
    });

    test('qiyam wirds change day at 04:00', () {
      expect(wirdDayKey(WirdType.qiyam, DateTime(2026, 11, 21, 1, 0)), '2026-11-20');
      expect(wirdDayKey(WirdType.qiyam, DateTime(2026, 11, 21, 3, 59)), '2026-11-20');
      expect(wirdDayKey(WirdType.qiyam, DateTime(2026, 11, 21, 4, 0)), '2026-11-21');
      expect(wirdDayKey(WirdType.qiyam, DateTime(2026, 11, 20, 22, 30)), '2026-11-20');
    });

    test('the qiyam boundary works across a month and a year', () {
      expect(wirdDayKey(WirdType.qiyam, DateTime(2027, 1, 1, 2, 0)), '2026-12-31');
      expect(wirdDayKey(WirdType.qiyam, DateTime(2026, 3, 1, 0, 30)), '2026-02-28');
    });
  });

  group('nextWirdDayBoundary', () {
    test('before 04:00 the next boundary is 04:00 the same day', () {
      expect(nextWirdDayBoundary(DateTime(2026, 11, 21, 1, 0)), DateTime(2026, 11, 21, 4, 0));
    });

    test('from 04:00 on it is the coming midnight', () {
      expect(nextWirdDayBoundary(DateTime(2026, 11, 21, 4, 0)), DateTime(2026, 11, 22));
      expect(nextWirdDayBoundary(DateTime(2026, 11, 21, 23, 59)), DateTime(2026, 11, 22));
    });

    test('it crosses month and year ends', () {
      expect(nextWirdDayBoundary(DateTime(2026, 12, 31, 12, 0)), DateTime(2027, 1, 1));
    });
  });

  group('isDone', () {
    test('done by the tick or by paging past the end of the portion', () {
      expect(isDonePortion(done: false, endPage: 20, currentPage: 20), isFalse);
      expect(isDonePortion(done: false, endPage: 20, currentPage: 21), isTrue);
      expect(isDonePortion(done: true, endPage: 20, currentPage: 5), isTrue);
    });
  });
}
