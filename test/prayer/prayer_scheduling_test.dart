// One scheduler owns every notification (feature 014, US2, research D6): the plan is the wird and Kahf reminders
// followed by the prayer notifications; a change of the prayer settings reschedules; turning off keeps the wird items.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/prayer/prayer_planner.dart';
import 'package:mushaf/prayer/prayer_settings.dart';
import 'package:mushaf/reminders/reminder_planner.dart';
import 'package:mushaf/reminders/reminder_scheduler.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/fake_reminders.dart';
import 'prayer_harness.dart';

const PrayerSettings _on = PrayerSettings(enabled: true, place: kCairo);

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  late FakeReminderService service;
  late ReminderScheduler scheduler;
  final now = cairoTime(2026, 3, 1, 13);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    await repo.ensureDefaults();
    service = FakeReminderService();
    scheduler = ReminderScheduler(
      repo,
      service,
      clock: () => now,
      debounce: const Duration(milliseconds: 10),
    );
  });
  tearDown(() async {
    scheduler.dispose();
    await db.close();
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 120));

  test(
    'buildReminderPlan is the wird and Kahf plan followed by the prayer plan',
    () async {
      final before = await buildReminderPlan(repo, now);
      await repo.setPrayerSettings(_on);
      final plan = await buildReminderPlan(repo, now, exact: true);
      final prayers = planPrayers(s: _on, now: now, exact: true);
      expect(plan, [...before, ...prayers]);
      expect(prayers, isNotEmpty);
    },
  );

  test('a change of a prayer setting reschedules; turning off removes the prayer items and keeps the rest', () async {
    scheduler.start();
    await settle();
    final wirdOnly = service.current;
    await repo.setPrayerSettings(_on);
    await settle();
    expect(service.current.where((r) => r.payload == 'prayer'), isNotEmpty);
    expect(service.current.where((r) => r.payload != 'prayer'), wirdOnly);
    await repo.setPrayerSettings(_on.copyWith(enabled: false));
    await settle();
    expect(service.current.where((r) => r.payload == 'prayer'), isEmpty);
    expect(service.current, wirdOnly);
  });

  test('prayer items are exact only when the phone allows exact alarms; wird items never are', () async {
    await repo.setPrayerSettings(_on);
    service.exact = false;
    await scheduler.refresh(force: true);
    expect(
      service.current
          .where((r) => r.payload == 'prayer')
          .every((r) => !r.exact),
      isTrue,
    );
    service.exact = true;
    await scheduler.refresh(force: true);
    expect(
      service.current.where((r) => r.payload == 'prayer').every((r) => r.exact),
      isTrue,
    );
    expect(
      service.current
          .where((r) => r.payload != 'prayer')
          .every((r) => !r.exact),
      isTrue,
    );
  });

  test('a wird reminder and a prayer at the same minute both stay', () async {
    await repo.setPrayerSettings(_on);
    final plan = await buildReminderPlan(repo, now, exact: true);
    final ids = plan.map((r) => r.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(plan.where((r) => r.kind == ReminderKind.prayerSound), isNotEmpty);
  });
}
