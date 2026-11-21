import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/mushaf/reader_controller.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

WirdDraft draft(String name, {int start = 1}) => WirdDraft(
      name: name,
      type: WirdType.reading,
      startPage: start,
      dailyPages: 20,
      color: 0xFF2E7D32,
    );

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  late ReaderController controller;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    controller = ReaderController(repo);
  });
  tearDown(() async {
    controller.dispose();
    await db.close();
  });

  Future<int> position(int id) async => (await repo.wirdById(id))!.currentPage;

  test('opens at the active wird position', () async {
    final id = await repo.create(draft('A', start: 212));
    await repo.setActive(id);
    await controller.init();
    expect(controller.page, 212);
    expect(controller.wird!.id, id);
    expect(controller.browsing, isFalse);
  });

  test('swiping moves the wird and remembers the last viewed page', () async {
    final id = await repo.create(draft('A', start: 212));
    await repo.setActive(id);
    await controller.init();
    await controller.onPageShown(213);
    expect(controller.page, 213);
    expect(await position(id), 213);
    expect(await repo.lastViewedPage(), 213);
  });

  test('a jump enters browse mode and does not move the wird', () async {
    final id = await repo.create(draft('A', start: 212));
    await repo.setActive(id);
    await controller.init();
    await controller.onPageShown(213);
    await controller.jumpTo(400);
    expect(controller.page, 400);
    expect(controller.browsing, isTrue);
    expect(await position(id), 213);
    expect(await repo.lastViewedPage(), 400);
  });

  test('paging in browse mode moves no wird but is remembered', () async {
    final a = await repo.create(draft('A', start: 100));
    final b = await repo.create(draft('B', start: 200));
    await repo.setActive(a);
    await controller.init();
    await controller.jumpTo(400);
    await controller.onPageShown(401);
    expect(controller.browsing, isTrue);
    expect(await position(a), 100);
    expect(await position(b), 200);
    expect(await repo.lastViewedPage(), 401);
  });

  test('«اجعلها موضعي» moves the wird to the shown page and leaves browse mode', () async {
    final id = await repo.create(draft('A', start: 212));
    await repo.setActive(id);
    await controller.init();
    await controller.jumpTo(400);
    await controller.makeThisMyPosition();
    expect(await position(id), 400);
    expect(controller.browsing, isFalse);
    expect(controller.page, 400);
  });

  test('switching wird shows its position and ends browse mode', () async {
    final a = await repo.create(draft('A', start: 100));
    final b = await repo.create(draft('B', start: 300));
    await repo.setActive(a);
    await controller.init();
    await controller.jumpTo(5);
    await controller.switchWird(b);
    expect(controller.wird!.id, b);
    expect(controller.page, 300);
    expect(controller.browsing, isFalse);
    expect((await repo.activeWird())!.id, b);
    expect(await position(a), 100); // positions are per wird
  });

  test('deleting the active wird switches to the first remaining wird in list order', () async {
    final a = await repo.create(draft('A', start: 10));
    final b = await repo.create(draft('B', start: 20));
    final c = await repo.create(draft('C', start: 30));
    await repo.setActive(b);
    await controller.init();
    await repo.delete(b);
    await pumpEventQueue();
    expect(controller.wird!.id, a);
    expect(controller.page, 10);
    expect(controller.browsing, isFalse);
    expect(await position(c), 30);
  });

  test('deleting every wird opens browse mode at the last viewed page without throwing', () async {
    final id = await repo.create(draft('A', start: 50));
    await repo.setActive(id);
    await controller.init();
    await controller.onPageShown(77);
    await repo.delete(id);
    await pumpEventQueue();
    expect(controller.wird, isNull);
    expect(controller.browsing, isTrue);
    expect(controller.page, 77);
    await controller.onPageShown(78); // paging still works with no wird
    expect(await repo.lastViewedPage(), 78);
  });

  test('with no wird at all the reader starts in browse mode on the last viewed page', () async {
    await repo.setLastViewedPage(293);
    await controller.init();
    expect(controller.wird, isNull);
    expect(controller.browsing, isTrue);
    expect(controller.page, 293);
  });

  test('pages outside 1..604 are rejected', () async {
    await controller.init();
    expect(() => controller.jumpTo(0), throwsArgumentError);
    expect(() => controller.jumpTo(605), throwsArgumentError);
    expect(() => controller.onPageShown(605), throwsArgumentError);
  });
}
