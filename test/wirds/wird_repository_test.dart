import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

WirdDraft draft(String name, {WirdType type = WirdType.reading, int start = 1, int? daily = 20}) => WirdDraft(
      name: name,
      type: type,
      startPage: start,
      dailyPages: daily,
      notifyEnabled: false,
      color: 0xFF2E7D32,
    );

void main() {
  late AppDatabase db;
  late WirdRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
  });
  tearDown(() => db.close());

  test('first launch creates one active reading wird; running setup twice adds no second one', () async {
    await repo.ensureDefaults();
    await repo.ensureDefaults();
    final wirds = await repo.watchWirds().first;
    expect(wirds.length, 1);
    final w = wirds.single;
    expect(w.name, 'الورد اليومي');
    expect(w.type, WirdType.reading);
    expect(w.currentPage, 1);
    expect(w.dailyPages, 20);
    expect(w.notifyEnabled, isTrue);
    expect(w.notifyMinutes, 20 * 60);
    expect(w.khatmaCount, 0);
    expect((await repo.activeWird())!.id, w.id);
    expect(await repo.kahfEnabled(), isTrue);
    expect(await repo.kahfMinutes(), 21 * 60);
    expect(await repo.lastViewedPage(), 1);
  });

  test('defaults are not recreated after the user deleted every wird', () async {
    await repo.ensureDefaults();
    final id = (await repo.activeWird())!.id;
    await repo.delete(id);
    await repo.ensureDefaults();
    expect(await repo.watchWirds().first, isEmpty);
    expect(await repo.activeWird(), isNull);
  });

  test('positions are per wird', () async {
    final a = await repo.create(draft('A'));
    final b = await repo.create(draft('B', start: 100));
    await repo.setPage(a, 50);
    final wirds = await repo.watchWirds().first;
    expect(wirds.firstWhere((w) => w.id == a).currentPage, 50);
    expect(wirds.firstWhere((w) => w.id == b).currentPage, 100);
  });

  test('setPage rejects 0 and 605 and accepts 1 and 604', () async {
    final id = await repo.create(draft('A'));
    expect(() => repo.setPage(id, 0), throwsArgumentError);
    expect(() => repo.setPage(id, 605), throwsArgumentError);
    await repo.setPage(id, 604);
    await repo.setPage(id, 1);
  });

  test('create rejects a start page outside 1..604, an empty name and a goal below 1', () async {
    expect(() => repo.create(draft('A', start: 0)), throwsArgumentError);
    expect(() => repo.create(draft('A', start: 605)), throwsArgumentError);
    expect(() => repo.create(draft('  ')), throwsArgumentError);
    expect(() => repo.create(draft('A', daily: 0)), throwsArgumentError);
  });

  test('wirds keep list order (sortOrder) and update changes fields', () async {
    final a = await repo.create(draft('A'));
    final b = await repo.create(draft('B'));
    var wirds = await repo.watchWirds().first;
    expect(wirds.map((w) => w.id), [a, b]);
    await repo.update(a, draft('A2', type: WirdType.qiyam, daily: 2));
    wirds = await repo.watchWirds().first;
    expect(wirds.first.name, 'A2');
    expect(wirds.first.type, WirdType.qiyam);
    expect(wirds.first.dailyPages, 2);
  });

  test('setActive and deleting the active wird makes the first remaining wird active', () async {
    final a = await repo.create(draft('A'));
    final b = await repo.create(draft('B'));
    final c = await repo.create(draft('C'));
    await repo.setActive(b);
    expect((await repo.activeWird())!.id, b);
    await repo.delete(b);
    expect((await repo.activeWird())!.id, a);
    await repo.delete(a);
    await repo.delete(c);
    expect(await repo.activeWird(), isNull);
  });

  test('last viewed page persists and rejects values outside 1..604', () async {
    await repo.setLastViewedPage(77);
    expect(await repo.lastViewedPage(), 77);
    expect(() => repo.setLastViewedPage(0), throwsArgumentError);
    expect(() => repo.setLastViewedPage(605), throwsArgumentError);
  });

  test('kahf settings round trip', () async {
    await repo.setKahf(enabled: false, minutes: 8 * 60 + 30);
    expect(await repo.kahfEnabled(), isFalse);
    expect(await repo.kahfMinutes(), 510);
  });

  group('today\'s portion', () {
    final morning = DateTime(2026, 11, 20, 8, 0);
    final night = DateTime(2026, 11, 20, 23, 0);
    final nextDay = DateTime(2026, 11, 21, 6, 0);

    Future<int> reading({int start = 1, int? daily = 20}) => repo.create(draft('R', start: start, daily: daily));
    Future<Wird> wirdOf(int id) async => (await repo.wirdById(id))!;

    test('is created once per wird day and stays the same all day', () async {
      final id = await reading();
      final a = await repo.today(id, morning);
      final b = await repo.today(id, night);
      expect((a.startPage, a.endPage), (1, 20));
      expect((b.startPage, b.endPage), (1, 20));
      expect(a.day, '2026-11-20');
      expect(a.done, isFalse);
    });

    test('the next day starts from the wird position then', () async {
      final id = await reading();
      final a = await repo.today(id, morning);
      await repo.setPage(id, a.endPage + 1);
      final c = await repo.today(id, nextDay);
      expect(c.day, '2026-11-21');
      expect((c.startPage, c.endPage), (21, 40));
    });

    test('a qiyam wird counts 01:00 for the previous night', () async {
      final id = await repo.create(draft('Q', type: WirdType.qiyam, daily: 2));
      final a = await repo.today(id, DateTime(2026, 11, 20, 22, 0));
      final b = await repo.today(id, DateTime(2026, 11, 21, 1, 0));
      expect(b.day, '2026-11-20');
      expect((b.startPage, b.endPage), (a.startPage, a.endPage));
      final c = await repo.today(id, DateTime(2026, 11, 21, 4, 0));
      expect(c.day, '2026-11-21');
    });

    test('«تم» marks the day done and moves the position to the page after the portion', () async {
      final id = await reading();
      await repo.today(id, morning);
      await repo.markDone(id, morning);
      final w = await wirdOf(id);
      expect(w.currentPage, 21);
      expect(w.khatmaCount, 0);
      expect((await repo.today(id, night)).done, isTrue);
    });

    test('«تم» on the last portion finishes the khatma and restarts at page 1', () async {
      final id = await reading(start: 600);
      final a = await repo.today(id, morning);
      expect((a.startPage, a.endPage), (600, 604));
      await repo.markDone(id, morning);
      final w = await wirdOf(id);
      expect(w.currentPage, 1);
      expect(w.khatmaCount, 1);
    });

    test('«تم» when already past the end leaves the position where it is', () async {
      final id = await reading();
      await repo.today(id, morning);
      await repo.setPage(id, 25);
      await repo.markDone(id, morning);
      expect((await wirdOf(id)).currentPage, 25);
      expect((await repo.today(id, morning)).done, isTrue);
    });

    test('editing the goal while today is open recalculates the end and keeps the start', () async {
      final id = await reading();
      await repo.today(id, morning);
      await repo.update(id, draft('R', start: 1, daily: 10), now: morning);
      final a = await repo.today(id, night);
      expect((a.startPage, a.endPage), (1, 10));
    });

    test('editing the goal after today is done leaves today unchanged, tomorrow uses the new goal', () async {
      final id = await reading();
      await repo.today(id, morning);
      await repo.markDone(id, morning); // position 21
      await repo.update(id, draft('R', start: 21, daily: 5), now: morning);
      final a = await repo.today(id, night);
      expect((a.startPage, a.endPage, a.done), (1, 20, true));
      final c = await repo.today(id, nextDay);
      expect((c.startPage, c.endPage), (21, 25));
    });

    test('editing the start page moves the position now and recreates an open portion from it', () async {
      final id = await reading();
      await repo.today(id, morning);
      await repo.update(id, draft('R', start: 100, daily: 20), now: morning);
      expect((await wirdOf(id)).currentPage, 100);
      final a = await repo.today(id, night);
      expect((a.startPage, a.endPage), (100, 119));
    });

    test('a target date gives the daily amount', () async {
      final id = await repo.create(WirdDraft(
        name: 'T',
        type: WirdType.reading,
        targetDate: DateTime(2026, 12, 19),
        color: 0xFF2E7D32,
      ));
      final a = await repo.today(id, morning);
      expect((a.startPage, a.endPage), (1, 21));
    });

    test('deleting the wird deletes its portions', () async {
      final id = await reading();
      await repo.today(id, morning);
      await repo.delete(id);
      expect(await repo.todayEntries(morning), isEmpty);
    });

    test('the today panel setting is closed until the user opens it and is remembered', () async {
      expect(await repo.todayPanelExpanded(), isFalse);
      await repo.setTodayPanelExpanded(true);
      expect(await repo.todayPanelExpanded(), isTrue);
      await repo.setTodayPanelExpanded(false);
      expect(await repo.todayPanelExpanded(), isFalse);
    });

    test('todayEntries lists reading and qiyam wirds in list order with their portions', () async {
      final a = await reading();
      final b = await repo.create(draft('Q', type: WirdType.qiyam, start: 100, daily: 2));
      final entries = await repo.todayEntries(morning);
      expect(entries.map((e) => e.wird.id), [a, b]);
      expect((entries[1].day.startPage, entries[1].day.endPage), (100, 101));
      expect(entries.every((e) => !e.done), isTrue);
      await repo.setPage(a, 21);
      expect((await repo.todayEntries(morning)).first.done, isTrue);
    });
  });
}
