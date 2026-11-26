// The prayer notifications for the next 48 hours (feature 014, US2, FR-015..FR-021, data-model.md).
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/prayer/prayer_calc.dart';
import 'package:mushaf/prayer/prayer_planner.dart';
import 'package:mushaf/prayer/prayer_settings.dart';
import 'package:mushaf/prayer/prayer_strings.dart';
import 'package:mushaf/reminders/reminder_planner.dart';

import 'prayer_harness.dart';

const PrayerSettings _on = PrayerSettings(enabled: true, place: kCairo);

void main() {
  final now = cairoTime(2026, 3, 1, 13); // after Dhuhr, before Asr

  test('off, or no place, plans nothing', () {
    expect(
      planPrayers(
        s: const PrayerSettings(place: kCairo),
        now: now,
        exact: true,
      ),
      isEmpty,
    );
    expect(
      planPrayers(
        s: const PrayerSettings(enabled: true),
        now: now,
        exact: true,
      ),
      isEmpty,
    );
  });

  test(
    'defaults: the five prayers for 48 hours from now, none past, no sunrise',
    () {
      final plan = planPrayers(s: _on, now: now, exact: true);
      final end = now.add(const Duration(hours: 48));
      expect(
        plan.length,
        10,
        reason: 'Asr, Maghrib, Isha today; five tomorrow; Fajr and Dhuhr the day after',
      );
      for (final r in plan) {
        expect(r.at.toUtc().isAfter(now), isTrue);
        expect(r.at.toUtc().isAfter(end), isFalse);
        expect(r.kind, ReminderKind.prayerSound);
        expect(r.exact, isTrue);
        expect(r.payload, 'prayer');
        expect(r.body, 'القاهرة');
        expect(r.id, greaterThanOrEqualTo(kPrayerIdBase));
      }
      expect(plan.map((r) => r.id).toSet().length, plan.length);
      final day = PrayerCalc.day(DateTime(2026, 3, 1), kCairo, _on);
      expect(plan.first.at.toUtc(), day.utc[Prayer.asr]);
      expect(plan.first.title, atPrayer('العصر'));
      expect(
        plan.first.id,
        kPrayerIdBase + 0 * 10 + 2,
        reason: 'day 0, slot 2 (Asr)',
      );
    },
  );

  test('silent and off per prayer; a reminder before; exactness follows the argument', () {
    final s = _on.copyWith(
      notify: const [
        PrayerNotify(NotifyMode.off, 0),
        PrayerNotify(NotifyMode.sound, 0),
        PrayerNotify(NotifyMode.silent, 10),
        PrayerNotify(NotifyMode.sound, 0),
        PrayerNotify(NotifyMode.off, 15),
      ],
    );
    final plan = planPrayers(s: s, now: now, exact: false);
    expect(plan.every((r) => !r.exact), isTrue);
    expect(plan.where((r) => r.title == atPrayer('الفجر')), isEmpty);
    expect(plan.where((r) => r.title == atPrayer('العشاء')), isEmpty);
    final asr = plan.firstWhere((r) => r.title == atPrayer('العصر'));
    expect(asr.kind, ReminderKind.prayerSilent);
    final before = plan.firstWhere((r) => r.title == beforePrayer('العصر', 10));
    expect(before.kind, ReminderKind.prayerBefore);
    expect(asr.at.difference(before.at), const Duration(minutes: 10));
    expect(before.id, kPrayerIdBase + 0 * 10 + 5 + 2);
    final ishaBefore = plan.where((r) => r.title == beforePrayer('العشاء', 15));
    expect(
      ishaBefore,
      isNotEmpty,
      reason: 'a reminder may be on while the prayer itself is off',
    );
    expect(plan.map((r) => r.id).toSet().length, plan.length);
    for (var i = 1; i < plan.length; i++) {
      expect(
        plan[i].at.isBefore(plan[i - 1].at),
        isFalse,
        reason: 'earliest first',
      );
    }
  });

  test(
    'a reminder whose moment has passed is skipped while its prayer stays',
    () {
      final s = _on.copyWith(
        notify: [..._on.notify]..[2] = const PrayerNotify(NotifyMode.sound, 30),
      );
      final asr = PrayerCalc.day(
        DateTime(2026, 3, 1),
        kCairo,
        _on,
      ).utc[Prayer.asr]!;
      final plan = planPrayers(
        s: s,
        now: asr.subtract(const Duration(minutes: 10)),
        exact: true,
      );
      expect(
        plan.where(
          (r) =>
              r.title == beforePrayer('العصر', 30) &&
              r.at.toUtc().isBefore(asr.add(const Duration(hours: 1))),
        ),
        isEmpty,
      );
      expect(plan.first.title, atPrayer('العصر'));
    },
  );
}
