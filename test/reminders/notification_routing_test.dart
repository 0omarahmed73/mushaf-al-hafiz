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

  test('wird:<id> switches the reader to that wird at its position, not browsing', () async {
    final a = await repo.create(draft('A', start: 10));
    final b = await repo.create(draft('B', start: 212));
    await repo.setActive(a);
    await controller.init();
    await controller.openPayload('wird:$b');
    expect(controller.wird!.id, b);
    expect(controller.page, 212);
    expect(controller.browsing, isFalse);
    expect((await repo.activeWird())!.id, b);
  });

  test('wird:<deleted id> opens browse mode at the last viewed page', () async {
    final a = await repo.create(draft('A', start: 10));
    final gone = await repo.create(draft('Gone', start: 50));
    await repo.setActive(a);
    await repo.setLastViewedPage(77);
    await controller.init();
    await repo.delete(gone);
    await controller.openPayload('wird:$gone');
    expect(controller.page, 77);
    expect(controller.browsing, isTrue);
    expect(controller.wird!.id, a, reason: 'the active wird is not changed');
  });

  test('page:293 opens page 293 in browse mode and moves no wird', () async {
    final a = await repo.create(draft('A', start: 10));
    await repo.setActive(a);
    await controller.init();
    await controller.openPayload('page:293');
    expect(controller.page, 293);
    expect(controller.browsing, isTrue);
    expect((await repo.wirdById(a))!.currentPage, 10);
  });

  test('a payload it does not understand changes nothing', () async {
    final a = await repo.create(draft('A', start: 10));
    await repo.setActive(a);
    await controller.init();
    for (final junk in ['', 'x', 'wird:', 'wird:abc', 'page:', 'page:0', 'page:605', 'page:abc']) {
      await controller.openPayload(junk);
      expect(controller.page, 10, reason: junk);
      expect(controller.browsing, isFalse, reason: junk);
    }
  });
}
