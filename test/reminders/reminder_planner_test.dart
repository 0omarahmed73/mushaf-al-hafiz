import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/reminders/reminder_planner.dart';
import 'package:mushaf/wirds/db.dart';

Wird wird({
  int id = 1,
  String name = 'الورد اليومي',
  WirdType type = WirdType.reading,
  int page = 1,
  int? daily = 20,
  DateTime? target,
  bool notify = true,
  int? minutes = 20 * 60,
}) => Wird(
  id: id,
  name: name,
  type: type,
  currentPage: page,
  dailyPages: daily,
  targetDate: target,
  khatmaCount: 0,
  notifyEnabled: notify,
  notifyMinutes: minutes,
  color: 0xFF2E7D32,
  sortOrder: 0,
  createdAt: DateTime(2026, 1, 1),
);

List<PlannedReminder> plan(
  List<Wird> wirds, {
  required DateTime now,
  Map<int, bool> done = const {},
  Map<int, ({int start, int end})> portions = const {},
  bool kahf = false,
  int kahfMinutes = 21 * 60,
}) => planReminders(
  wirds: wirds,
  doneToday: done,
  todayPortions: portions,
  kahfEnabled: kahf,
  kahfMinutes: kahfMinutes,
  kahfPage: 293,
  now: now,
);

void main() {
  final fridayMorning = DateTime(2026, 11, 20, 10, 0); // a Friday

  group('wird reminders', () {
    test('a reading wird at 20:00 gets 14 reminders, the first today', () {
      final p = plan([wird()], now: fridayMorning);
      expect(p.length, 14);
      final first = p.first;
      expect(first.at, DateTime(2026, 11, 20, 20, 0));
      expect(first.title, 'ورد: الورد اليومي');
      expect(first.body, 'من ص 1 إلى ص 20');
      expect(first.payload, 'wird:1');
      expect(first.id, 100);
      expect(p.last.id, 113);
      expect(p.last.at, DateTime(2026, 12, 3, 20, 0));
    });

    test('a portion already done today leaves the first reminder for tomorrow', () {
      final p = plan([wird()], now: fridayMorning, done: {1: true});
      expect(p.length, 13);
      expect(p.first.at, DateTime(2026, 11, 21, 20, 0));
      expect(p.first.id, 101);
    });

    test('a time that has already passed today is skipped', () {
      final p = plan([wird()], now: DateTime(2026, 11, 20, 21, 0));
      expect(p.first.at, DateTime(2026, 11, 21, 20, 0));
      expect(p.first.id, 101);
    });

    test('today uses the portion already created; later days start from the current position', () {
      final p = plan(
        [wird(page: 25)],
        now: fridayMorning,
        portions: {1: (start: 5, end: 24)},
      );
      expect(p[0].body, 'من ص 5 إلى ص 24');
      expect(p[1].body, 'من ص 25 إلى ص 44');
    });

    test('the last page of the Mushaf ends a portion', () {
      final p = plan([wird(page: 600)], now: fridayMorning);
      expect(p.first.body, 'من ص 600 إلى ص 604');
    });

    test('with a target date the amount comes from the days left on each day', () {
      final p = plan([wird(daily: null, target: DateTime(2026, 11, 29))], now: fridayMorning);
      expect(p[0].body, 'من ص 1 إلى ص 61'); // 604 pages over 10 days
      expect(p[1].body, 'من ص 1 إلى ص 68'); // 604 pages over 9 days
    });

    test('a qiyam wird follows the 04:00 wird day', () {
      // 02:00 on the 21st still belongs to the night of the 20th.
      final night = DateTime(2026, 11, 21, 2, 0);
      final evening = plan([wird(type: WirdType.qiyam, minutes: 22 * 60)], now: night);
      expect(evening.first.at, DateTime(2026, 11, 21, 22, 0), reason: 'the 20th 22:00 has passed');
      expect(evening.first.id, 101);

      // A reminder before 04:00 falls in the small hours after its wird day.
      final small = plan([wird(type: WirdType.qiyam, minutes: 3 * 60)], now: night);
      expect(small.first.at, DateTime(2026, 11, 21, 3, 0));
      expect(small.first.id, 100);

      final done = plan([wird(type: WirdType.qiyam, minutes: 3 * 60)], now: night, done: {1: true});
      expect(done.first.at, DateTime(2026, 11, 22, 3, 0));
      expect(done.first.id, 101);
    });

    test('a qiyam wird in the evening starts today', () {
      final p = plan([wird(type: WirdType.qiyam, minutes: 22 * 60)], now: fridayMorning);
      expect(p.first.at, DateTime(2026, 11, 20, 22, 0));
      expect(p.first.id, 100);
    });

    test('wirds with the reminder off, no time, or a type without reminders produce nothing', () {
      expect(plan([wird(notify: false)], now: fridayMorning), isEmpty);
      expect(plan([wird(minutes: null)], now: fridayMorning), isEmpty);
      expect(plan([wird(type: WirdType.hifz)], now: fridayMorning), isEmpty);
    });

    test('ids keep wirds apart and the plan is in time order', () {
      final p = plan([wird(id: 1), wird(id: 2, minutes: 8 * 60)], now: DateTime(2026, 11, 20, 6, 0));
      expect(p.map((r) => r.id).toSet().length, p.length);
      expect(p.first.id, 200);
      expect(p.first.at, DateTime(2026, 11, 20, 8, 0));
      final times = p.map((r) => r.at).toList();
      expect(times, [...times]..sort());
    });
  });

  group('al-Kahf reminders', () {
    test('from a Wednesday the first one is Thursday 21:00 with the fixed text and page 293', () {
      final p = plan([], now: DateTime(2026, 11, 18, 10, 0), kahf: true);
      final first = p.first;
      expect(first.at, DateTime(2026, 11, 19, 21, 0));
      expect(first.title, 'سورة الكهف');
      expect(first.body, 'ليلة الجمعة: لا تنسَ قراءة سورة الكهف');
      expect(first.payload, 'page:293');
      expect(first.id, 900001);
      expect(p.length, 2, reason: 'two Thursdays in 14 days');
      expect(p.every((r) => r.at.weekday == DateTime.thursday), isTrue);
    });

    test('on a Thursday before 21:00 it is today; after 21:00 the next one is a week later', () {
      final before = plan([], now: DateTime(2026, 11, 19, 10, 0), kahf: true);
      expect(before.first.at, DateTime(2026, 11, 19, 21, 0));
      expect(before.first.id, 900000);
      final after = plan([], now: DateTime(2026, 11, 19, 22, 0), kahf: true);
      expect(after.first.at, DateTime(2026, 11, 26, 21, 0));
      expect(after.first.id, 900007);
    });

    test('on Friday the next one is the coming Thursday', () {
      final p = plan([], now: fridayMorning, kahf: true);
      expect(p.first.at, DateTime(2026, 11, 26, 21, 0));
      expect(p.first.id, 900006);
    });

    test('the time can be changed, and off means none', () {
      final p = plan([], now: DateTime(2026, 11, 18, 10, 0), kahf: true, kahfMinutes: 20 * 60 + 30);
      expect(p.first.at, DateTime(2026, 11, 19, 20, 30));
      expect(plan([], now: DateTime(2026, 11, 18, 10, 0)), isEmpty);
    });

    test('wird and Kahf reminders share one plan without clashing ids', () {
      final p = plan([wird()], now: DateTime(2026, 11, 19, 10, 0), kahf: true);
      expect(p.map((r) => r.id).toSet().length, p.length);
      expect(p.where((r) => r.payload == 'page:293').length, 2);
    });
  });

  test('reminders compare by value', () {
    final a = PlannedReminder(id: 1, at: DateTime(2026, 1, 1), title: 't', body: 'b', payload: 'p');
    final b = PlannedReminder(id: 1, at: DateTime(2026, 1, 1), title: 't', body: 'b', payload: 'p');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
