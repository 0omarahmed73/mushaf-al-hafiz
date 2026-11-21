import '../wirds/db.dart';
import '../wirds/portion.dart';
import 'kahf_day.dart';
import 'kahf_strings.dart';

/// Page of surah al-Kahf, opened by the al-Kahf notification.
const int kKahfPage = 293;

/// Notification ids: a wird's are `wirdId * 100 + dayOffset`, al-Kahf's `900000 + dayOffset`
/// (contracts/notifications.md). Day offsets stay below 100, so wirds never clash.
const int kKahfIdBase = 900000;

const String kKahfTitle = 'سورة الكهف';
const String kKahfBody = 'ليلة الجمعة: لا تنسَ قراءة سورة الكهف';

/// One notification to schedule, in the phone's local time.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;

  /// `wird:<id>` or `page:<n>`; what a tap opens (see `ReaderController.openPayload`).
  final String payload;

  bool get isKahf => id >= kKahfIdBase;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.id == id &&
      other.at == at &&
      other.title == title &&
      other.body == body &&
      other.payload == payload;

  @override
  int get hashCode => Object.hash(id, at, title, body, payload);

  @override
  String toString() => 'PlannedReminder($id, $at, $title, $body, $payload)';
}

/// The notifications to have scheduled for the next [horizonDays] days, earliest first.
///
/// * A wird with its reminder on gets one per wird day at its time. Today's is skipped when its time
///   has passed or its portion is done ([doneToday]). A qiyam wird's day starts at 04:00, and a
///   reminder time before 04:00 falls in the small hours after its day.
/// * The body is today's portion ([todayPortions]) for today; for later days it is the portion that
///   would start from the wird's current position.
/// * al-Kahf gets one on every [kahfDay] (Thursday, the night of Friday, unless Friday is chosen) at [kahfMinutes]
///   when [kahfEnabled]; the Friday body differs from the Thursday one.
List<PlannedReminder> planReminders({
  required List<Wird> wirds,
  required Map<int, bool> doneToday,
  Map<int, ({int start, int end})> todayPortions = const {},
  required bool kahfEnabled,
  required int kahfMinutes,
  KahfDay kahfDay = KahfDay.thursday,
  required int kahfPage,
  required DateTime now,
  int horizonDays = 14,
}) {
  final plan = <PlannedReminder>[];

  for (final w in wirds) {
    final minutes = w.notifyMinutes;
    final remindable = w.type == WirdType.reading || w.type == WirdType.qiyam;
    if (!w.notifyEnabled || minutes == null || !remindable) continue;
    final today = wirdDayDate(w.type, now);
    final nextCalendarDay = w.type == WirdType.qiyam && minutes < 4 * 60
        ? 1
        : 0;
    for (var k = 0; k < horizonDays; k++) {
      final at = DateTime(
        today.year,
        today.month,
        today.day + k + nextCalendarDay,
        minutes ~/ 60,
        minutes % 60,
      );
      if (!at.isAfter(now)) continue;
      if (k == 0 && (doneToday[w.id] ?? false)) continue;
      final day = DateTime(today.year, today.month, today.day + k);
      final fixed = k == 0 ? todayPortions[w.id] : null;
      final ({int start, int end}) portion =
          fixed ??
          portionFor(
            startPage: w.currentPage,
            perDay: pagesPerDay(
              currentPage: w.currentPage,
              dailyPages: w.dailyPages,
              targetDate: w.targetDate,
              today: day,
            ),
          );
      plan.add(
        PlannedReminder(
          id: w.id * 100 + k,
          at: at,
          title: 'ورد: ${w.name}',
          body: 'من ص ${portion.start} إلى ص ${portion.end}',
          payload: 'wird:${w.id}',
        ),
      );
    }
  }

  if (kahfEnabled) {
    final today = DateTime(now.year, now.month, now.day);
    for (var k = 0; k < horizonDays; k++) {
      final day = DateTime(today.year, today.month, today.day + k);
      if (day.weekday != kahfDay.weekday) continue;
      final at = DateTime(
        day.year,
        day.month,
        day.day,
        kahfMinutes ~/ 60,
        kahfMinutes % 60,
      );
      if (!at.isAfter(now)) continue;
      plan.add(
        PlannedReminder(
          id: kKahfIdBase + k,
          at: at,
          title: kKahfTitle,
          body: kahfDay == KahfDay.friday ? kKahfBodyFriday : kKahfBody,
          payload: 'page:$kahfPage',
        ),
      );
    }
  }

  plan.sort((a, b) {
    final byTime = a.at.compareTo(b.at);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  });
  return plan;
}
