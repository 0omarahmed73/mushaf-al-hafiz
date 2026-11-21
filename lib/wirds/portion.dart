import 'wird_type.dart';

/// The last page of the Mushaf.
const int kLastPage = 604;

/// Pages per day when a wird has neither a daily goal nor a target date.
const int kDefaultDailyPages = 20;

String _two(int n) => n.toString().padLeft(2, '0');

/// `yyyy-MM-dd` of the local calendar date.
String dayKey(DateTime localNow) =>
    '${localNow.year}-${_two(localNow.month)}-${_two(localNow.day)}';

/// The wird day a moment belongs to: the calendar date for reading wirds; for qiyam wirds the day
/// starts at 04:00, so 00:00–03:59 counts for the previous night (spec FR-028).
String wirdDayKey(WirdType type, DateTime localNow) =>
    dayKey(wirdDayDate(type, localNow));

/// The calendar date (at local midnight) of the wird day [localNow] falls in; see [wirdDayKey].
DateTime wirdDayDate(WirdType type, DateTime localNow) {
  if (type != WirdType.qiyam) {
    return DateTime(localNow.year, localNow.month, localNow.day);
  }
  // wall-clock arithmetic: DateTime() normalises a negative hour into the previous day
  final shifted = DateTime(
    localNow.year,
    localNow.month,
    localNow.day,
    localNow.hour - 4,
    localNow.minute,
  );
  return DateTime(shifted.year, shifted.month, shifted.day);
}

/// `HH:mm` of a time given as minutes after midnight (20:00 for 1200).
String formatMinutes(int minutes) =>
    '${_two(minutes ~/ 60)}:${_two(minutes % 60)}';

/// The next moment after [now] at which a wird day can change: local midnight (reading wirds) or
/// 04:00 (qiyam wirds), whichever comes first. The reader refreshes today's portions then.
DateTime nextWirdDayBoundary(DateTime now) {
  final midnight = DateTime(now.year, now.month, now.day + 1);
  var four = DateTime(now.year, now.month, now.day, 4);
  if (!four.isAfter(now)) four = DateTime(now.year, now.month, now.day + 1, 4);
  return four.isBefore(midnight) ? four : midnight;
}

/// Daily amount: pages per day if set (it wins); else ceil(remaining / days left) for a target date,
/// where remaining = 604 − currentPage + 1 and days left counts today and the target day, at least 1;
/// else 20. A target of today or in the past gives all remaining pages — never 0 or negative.
int pagesPerDay({
  required int currentPage,
  int? dailyPages,
  DateTime? targetDate,
  required DateTime today,
}) {
  if (dailyPages != null) return dailyPages < 1 ? 1 : dailyPages;
  if (targetDate == null) return kDefaultDailyPages;
  final remaining = kLastPage - currentPage + 1;
  final daysBetween = DateTime.utc(
    targetDate.year,
    targetDate.month,
    targetDate.day,
  ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
  final daysLeft = daysBetween + 1 < 1 ? 1 : daysBetween + 1;
  return (remaining + daysLeft - 1) ~/ daysLeft;
}

/// Pages A..B of a portion: B = min(A + perDay − 1, 604).
({int start, int end}) portionFor({
  required int startPage,
  required int perDay,
}) {
  final end = startPage + perDay - 1;
  return (start: startPage, end: end > kLastPage ? kLastPage : end);
}

/// A portion is done when «تم» was pressed or the wird's position is past its last page.
bool isDonePortion({
  required bool done,
  required int endPage,
  required int currentPage,
}) => done || currentPage > endPage;

/// Where a wird goes after finishing a portion ending at [endPage]: the next page, or page 1 with
/// the khatma completed after page 604.
({int nextPage, bool completedKhatma}) afterDone(int endPage) =>
    endPage >= kLastPage
    ? (nextPage: 1, completedKhatma: true)
    : (nextPage: endPage + 1, completedKhatma: false);
