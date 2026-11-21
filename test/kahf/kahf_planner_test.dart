import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/reminders/kahf_day.dart';
import 'package:mushaf/reminders/kahf_strings.dart';
import 'package:mushaf/reminders/reminder_planner.dart';
import 'package:mushaf/wirds/db.dart';

Wird wird({int id = 1, int? minutes = 21 * 60}) => Wird(
  id: id,
  name: 'الورد اليومي',
  type: WirdType.reading,
  currentPage: 1,
  dailyPages: 20,
  targetDate: null,
  khatmaCount: 0,
  notifyEnabled: true,
  notifyMinutes: minutes,
  color: 0xFF2E7D32,
  sortOrder: 0,
  createdAt: DateTime(2026, 1, 1),
);

/// The al-Kahf part of a plan (the wird notifications are left out).
List<PlannedReminder> kahfPlan({
  required DateTime now,
  KahfDay? day,
  int minutes = 21 * 60,
  bool enabled = true,
  List<Wird> wirds = const [],
}) {
  final all = day == null
      ? planReminders(
          wirds: wirds,
          doneToday: const {},
          kahfEnabled: enabled,
          kahfMinutes: minutes,
          kahfPage: 293,
          now: now,
        )
      : planReminders(
          wirds: wirds,
          doneToday: const {},
          kahfEnabled: enabled,
          kahfMinutes: minutes,
          kahfDay: day,
          kahfPage: 293,
          now: now,
        );
  return all.where((r) => r.isKahf).toList();
}

void main() {
  /// Every date of 2026 at 10:00, the phone's local time.
  final dates = [
    for (
      var d = DateTime(2026, 1, 1, 10);
      d.year == 2026;
      d = DateTime(d.year, d.month, d.day + 1, 10)
    )
      d,
  ];

  for (final entry in {
    KahfDay.thursday: kKahfBody,
    KahfDay.friday: kKahfBodyFriday,
  }.entries) {
    final day = entry.key;
    final body = entry.value;

    group('${day.name}: every date of 2026', () {
      test('only the chosen weekday, at the hour, with that day\'s body, title and payload', () {
        for (final now in dates) {
          for (final minutes in [21 * 60, 7 * 60 + 30]) {
            final plan = kahfPlan(now: now, day: day, minutes: minutes);
            final aheadToday =
                now.weekday != day.weekday ||
                minutes > now.hour * 60 + now.minute;
            expect(plan.length, aheadToday ? 2 : 1, reason: '$now at $minutes');
            for (final r in plan) {
              expect(r.at.weekday, day.weekday, reason: '$now');
              expect(r.at.hour, minutes ~/ 60);
              expect(r.at.minute, minutes % 60);
              expect(r.at.isAfter(now), isTrue, reason: '$now');
              expect(r.at.difference(now).inDays, lessThan(14));
              expect(r.title, kKahfTitle);
              expect(r.body, body);
              expect(r.payload, 'page:293');
              expect(r.isKahf, isTrue);
            }
          }
        }
      });

      test('ids are all different and equal 900000 + the days from today', () {
        for (final now in dates) {
          final plan = kahfPlan(now: now, day: day);
          expect(
            plan.map((r) => r.id).toSet().length,
            plan.length,
            reason: '$now',
          );
          for (final r in plan) {
            // Whole calendar days through UTC dates: a local day can be 23 or 25 hours long around DST.
            final offset = DateTime.utc(
              r.at.year,
              r.at.month,
              r.at.day,
            ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
            expect(r.id, kKahfIdBase + offset, reason: '$now');
            expect(r.id, inInclusiveRange(kKahfIdBase, kKahfIdBase + 13));
          }
        }
      });

      test('switched off, nothing for al-Kahf', () {
        for (final now in dates) {
          expect(kahfPlan(now: now, day: day, enabled: false), isEmpty);
        }
      });
    });
  }

  group('the day decides which weekday', () {
    test('a plan never holds a notification on the other weekday', () {
      for (final now in dates) {
        expect(
          kahfPlan(
            now: now,
            day: KahfDay.thursday,
          ).any((r) => r.at.weekday == DateTime.friday),
          isFalse,
        );
        expect(
          kahfPlan(
            now: now,
            day: KahfDay.friday,
          ).any((r) => r.at.weekday == DateTime.thursday),
          isFalse,
        );
      }
    });

    test('a plan without the day equals the Thursday plan, on every date', () {
      for (final now in dates) {
        expect(
          kahfPlan(now: now),
          kahfPlan(now: now, day: KahfDay.thursday),
          reason: '$now',
        );
      }
    });

    test('Friday at 22:00 with Friday chosen: only next Friday, id 900007', () {
      final plan = kahfPlan(
        now: DateTime(2026, 11, 20, 22, 0),
        day: KahfDay.friday,
      );
      expect(plan.length, 1);
      expect(plan.single.id, kKahfIdBase + 7);
      expect(plan.single.at, DateTime(2026, 11, 27, 21, 0));
    });

    test(
      'Friday at 10:00 with Friday chosen: today at 21:00 and next week',
      () {
        final plan = kahfPlan(
          now: DateTime(2026, 11, 20, 10, 0),
          day: KahfDay.friday,
        );
        expect(plan.map((r) => r.id), [kKahfIdBase, kKahfIdBase + 7]);
        expect(plan.first.at, DateTime(2026, 11, 20, 21, 0));
      },
    );

    test(
      'Thursday at 10:00 with Friday chosen: the first is tomorrow, id 900001',
      () {
        final plan = kahfPlan(
          now: DateTime(2026, 11, 19, 10, 0),
          day: KahfDay.friday,
        );
        expect(plan.first.id, kKahfIdBase + 1);
        expect(plan.first.at, DateTime(2026, 11, 20, 21, 0));
      },
    );

    test('Thursday at 10:00 with Thursday chosen is today\'s behaviour: today at 21:00, id 900000', () {
      final plan = kahfPlan(
        now: DateTime(2026, 11, 19, 10, 0),
        day: KahfDay.thursday,
      );
      expect(plan.first.id, kKahfIdBase);
      expect(plan.first.at, DateTime(2026, 11, 19, 21, 0));
      expect(plan.first.body, 'ليلة الجمعة: لا تنسَ قراءة سورة الكهف');
    });

    test('a wird reminder at the same minute coexists with both days', () {
      final now = DateTime(2026, 11, 19, 10, 0); // a Thursday
      for (final day in KahfDay.values) {
        final all = planReminders(
          wirds: [wird()],
          doneToday: const {},
          kahfEnabled: true,
          kahfMinutes: 21 * 60,
          kahfDay: day,
          kahfPage: 293,
          now: now,
        );
        final kahf = all.where((r) => r.isKahf).toList();
        final wirdOnes = all.where((r) => !r.isKahf).toList();
        expect(wirdOnes.length, 14);
        expect(kahf.length, 2);
        final ids = all.map((r) => r.id).toList();
        expect(ids.toSet().length, ids.length, reason: 'no id clash');
        // Same minute on the day of an al-Kahf notification: both are in the plan.
        final k = kahf.first;
        expect(all.where((r) => r.at == k.at).length, 2);
      }
    });
  });
}
