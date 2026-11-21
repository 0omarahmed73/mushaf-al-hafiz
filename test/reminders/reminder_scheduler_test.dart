import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/reminders/reminder_scheduler.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/fake_reminders.dart';

void main() {
  // A Friday at 10:00.
  final now = DateTime(2026, 11, 20, 10, 0);
  const pause = Duration(milliseconds: 120);

  late AppDatabase db;
  late WirdRepository repo;
  late FakeReminderService service;
  late ReminderScheduler scheduler;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    service = FakeReminderService();
    scheduler = ReminderScheduler(repo, service, clock: () => now, debounce: const Duration(milliseconds: 20));
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

  test('starting schedules the default wird for 14 days and the Thursday evenings', () async {
    await started();
    expect(service.schedules.length, 1);
    final plan = service.current;
    expect(plan.where((r) => r.payload == 'wird:1').length, 14);
    expect(plan.where((r) => r.payload == 'page:293').length, 2, reason: 'two Thursdays in the next 14 days');
    expect(plan.first.title, 'ورد: الورد اليومي');
  });

  test('a refresh that changes nothing schedules nothing; force schedules again', () async {
    await started();
    await scheduler.refresh();
    expect(service.schedules.length, 1);
    await scheduler.refresh(force: true);
    expect(service.schedules.length, 2);
  });

  test('pressing «تم» removes today\'s reminder', () async {
    await started();
    expect(service.current.any((r) => r.payload == 'wird:1' && r.at.day == 20), isTrue);
    await repo.markDone(1, now);
    await Future<void>.delayed(pause);
    expect(service.current.any((r) => r.payload == 'wird:1' && r.at.day == 20), isFalse);
    expect(service.current.where((r) => r.payload == 'wird:1').length, 13);
  });

  test('deleting a wird cancels its reminders at once', () async {
    await started();
    await repo.delete(1);
    await Future<void>.delayed(pause);
    expect(service.current.any((r) => r.payload == 'wird:1'), isFalse);
  });

  test('creating a wird and turning its reminder off both show up in the schedule', () async {
    await started();
    final id = await repo.create(const WirdDraft(
      name: 'قيام',
      type: WirdType.qiyam,
      dailyPages: 2,
      notifyEnabled: true,
      notifyMinutes: 22 * 60,
      color: 0xFF1565C0,
    ));
    await Future<void>.delayed(pause);
    expect(service.current.where((r) => r.payload == 'wird:$id').length, 14);
    await repo.update(id, const WirdDraft(name: 'قيام', type: WirdType.qiyam, dailyPages: 2, notifyEnabled: false, color: 0xFF1565C0), now: now);
    await Future<void>.delayed(pause);
    expect(service.current.any((r) => r.payload == 'wird:$id'), isFalse);
  });

  test('changing the al-Kahf time or switching it off changes the schedule', () async {
    await started();
    await repo.setKahf(enabled: true, minutes: 7 * 60 + 30);
    await Future<void>.delayed(pause);
    final kahf = service.current.where((r) => r.payload == 'page:293').first;
    expect((kahf.at.weekday, kahf.at.hour, kahf.at.minute), (DateTime.thursday, 7, 30));
    await repo.setKahf(enabled: false, minutes: 7 * 60 + 30);
    await Future<void>.delayed(pause);
    expect(service.current.any((r) => r.payload == 'page:293'), isFalse);
  });

  test('turning a page does not reschedule anything', () async {
    await started();
    final before = service.schedules.length;
    await repo.setLastViewedPage(50);
    await Future<void>.delayed(pause);
    expect(service.schedules.length, before);
  });

  test('a phone that refuses does not crash the app, and the next refresh tries again', () async {
    service.failNext = true;
    await scheduler.refresh(); // must not throw
    expect(service.schedules, isEmpty);
    await scheduler.refresh();
    expect(service.schedules.length, 1);
  });

  test('reminderInputs reads without creating a portion', () async {
    final before = await repo.reminderInputs(now);
    expect(before.todayPortions, isEmpty);
    expect(await db.select(db.wirdDays).get(), isEmpty);
    await repo.today(1, now);
    final after = await repo.reminderInputs(now);
    expect(after.todayPortions[1], (start: 1, end: 20));
    expect(after.doneToday[1], isFalse);
    await repo.markDone(1, now);
    expect((await repo.reminderInputs(now)).doneToday[1], isTrue);
  });
}
