import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/reminders/kahf_day.dart';
import 'package:mushaf/reminders/kahf_strings.dart';
import 'package:mushaf/reminders/reminder_planner.dart';
import 'package:mushaf/reminders/reminder_scheduler.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/fake_reminders.dart';

void main() {
  // A Friday at 09:00: Friday's default hour, 10:00, is still ahead.
  final now = DateTime(2026, 11, 20, 9, 0);
  const pause = Duration(milliseconds: 120);

  late AppDatabase db;
  late WirdRepository repo;
  late FakeReminderService service;
  late ReminderScheduler scheduler;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    service = FakeReminderService();
    scheduler = ReminderScheduler(
      repo,
      service,
      clock: () => now,
      debounce: const Duration(milliseconds: 20),
    );
    await repo.ensureDefaults();
  });
  tearDown(() async {
    scheduler.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await db.close();
  });

  Future<void> started() async {
    scheduler.start();
    await Future<void>.delayed(pause);
  }

  List<PlannedReminder> kahf() =>
      service.current.where((r) => r.payload == 'page:293').toList();

  test('the default plan is today\'s: the two Thursdays at 21:00', () async {
    await started();
    expect(kahf().map((r) => r.at), [
      DateTime(2026, 11, 26, 21, 0),
      DateTime(2026, 12, 3, 21, 0),
    ]);
    expect(kahf().every((r) => r.body == kKahfBody), isTrue);
  });

  test('choosing Friday replaces the schedule with the two Fridays at 10:00 and leaves the wirds alone', () async {
    await started();
    final wirdsBefore = service.current
        .where((r) => r.payload == 'wird:1')
        .toList();
    final schedulesBefore = service.schedules.length;
    await repo.setKahfDay(KahfDay.friday);
    await Future<void>.delayed(pause);
    expect(service.schedules.length, schedulesBefore + 1);
    expect(kahf().map((r) => r.at), [
      DateTime(2026, 11, 20, 10, 0),
      DateTime(2026, 11, 27, 10, 0),
    ]);
    expect(kahf().every((r) => r.body == kKahfBodyFriday), isTrue);
    expect(kahf().every((r) => r.title == kKahfTitle), isTrue);
    expect(
      service.current.where((r) => r.payload == 'wird:1').toList(),
      wirdsBefore,
    );
  });

  test('choosing Thursday again brings the Thursdays back', () async {
    await started();
    await repo.setKahfDay(KahfDay.friday);
    await Future<void>.delayed(pause);
    await repo.setKahfDay(KahfDay.thursday);
    await Future<void>.delayed(pause);
    expect(kahf().map((r) => r.at.weekday).toSet(), {DateTime.thursday});
    expect(kahf().length, 2);
  });

  test('with the switch off nothing is planned and the day is kept', () async {
    await started();
    await repo.setKahfDay(KahfDay.friday);
    await repo.setKahf(enabled: false, minutes: 21 * 60);
    await Future<void>.delayed(pause);
    expect(kahf(), isEmpty);
    expect(await repo.kahfDay(), KahfDay.friday);
    await repo.setKahf(enabled: true, minutes: 21 * 60);
    await Future<void>.delayed(pause);
    expect(kahf().map((r) => r.at.weekday).toSet(), {DateTime.friday});
  });

  test('changing the hour keeps the day', () async {
    await started();
    await repo.setKahfDay(KahfDay.friday);
    await repo.setKahf(enabled: true, minutes: 7 * 60 + 30);
    await Future<void>.delayed(pause);
    final first = kahf().first;
    expect(
      (first.at.weekday, first.at.hour, first.at.minute),
      (DateTime.friday, 7, 30),
    );
  });

  test(
    'buildReminderPlan equals planReminders with the stored values',
    () async {
      await repo.setKahfDay(KahfDay.friday);
      final inputs = await repo.reminderInputs(now);
      final expected = planReminders(
        wirds: inputs.wirds,
        doneToday: inputs.doneToday,
        todayPortions: inputs.todayPortions,
        kahfEnabled: inputs.kahfEnabled,
        kahfMinutes: inputs.kahfMinutes,
        kahfDay: KahfDay.friday,
        kahfPage: kKahfPage,
        now: now,
      );
      expect(await buildReminderPlan(repo, now), expected);
      expect(
        expected.any((r) => r.isKahf && r.at.weekday == DateTime.friday),
        isTrue,
      );
    },
  );
}
