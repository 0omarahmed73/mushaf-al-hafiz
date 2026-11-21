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

  Future<List<BookmarkEntry>> list() => repo.watchBookmarks().first;

  group('which wird a bookmark belongs to', () {
    test('added outside browse mode it belongs to the active wird', () async {
      final id = await repo.create(draft('A', start: 77));
      await repo.setActive(id);
      await controller.init();
      expect(controller.browsing, isFalse);
      await controller.addBookmark(note: 'مراجعة');
      final entry = (await list()).single;
      expect(entry.bookmark.wirdId, id);
      expect(entry.bookmark.page, 77);
      expect(entry.wirdName, 'A');
    });

    test('added in browse mode it is general («عامة»)', () async {
      final id = await repo.create(draft('A', start: 10));
      await repo.setActive(id);
      await controller.init();
      await controller.jumpTo(77);
      expect(controller.browsing, isTrue);
      await controller.addBookmark();
      final entry = (await list()).single;
      expect(entry.bookmark.wirdId, isNull);
      expect(entry.wirdName, isNull);
      expect(entry.bookmark.page, 77);
    });

    test('with no wird at all it is general', () async {
      await controller.init();
      await controller.jumpTo(5);
      await controller.addBookmark(note: 'x');
      expect((await list()).single.bookmark.wirdId, isNull);
    });
  });

  group('the list', () {
    test('is every bookmark, newest first, each with page, note and wird name or none', () async {
      final a = await repo.create(draft('A'));
      final b = await repo.create(draft('B'));
      await repo.addBookmark(10, 'first', wirdId: a);
      await repo.addBookmark(20, null);
      await repo.addBookmark(30, 'third', wirdId: b);
      final entries = await list();
      expect(entries.map((e) => e.bookmark.page), [30, 20, 10]);
      expect(entries.map((e) => e.bookmark.note), ['third', null, 'first']);
      expect(entries.map((e) => e.wirdName), ['B', null, 'A']);
    });

    test('a note is trimmed and a blank note is no note', () async {
      await repo.addBookmark(1, '  hello  ');
      await repo.addBookmark(2, '   ');
      final entries = await list();
      expect(entries[1].bookmark.note, 'hello');
      expect(entries[0].bookmark.note, isNull);
    });

    test('pages outside 1–604 are refused', () async {
      expect(() => repo.addBookmark(0, null), throwsArgumentError);
      expect(() => repo.addBookmark(605, null), throwsArgumentError);
      expect(await list(), isEmpty);
    });

    test('removing deletes just that bookmark', () async {
      final keep = await repo.addBookmark(1, 'keep');
      final drop = await repo.addBookmark(2, 'drop');
      await repo.removeBookmark(drop);
      expect((await list()).map((e) => e.bookmark.id), [keep]);
    });

    test('the list updates by itself when a bookmark is added', () async {
      final stream = repo.watchBookmarks();
      final seen = <int>[];
      final sub = stream.listen((e) => seen.add(e.length));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.addBookmark(3, null);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(seen.first, 0);
      expect(seen.last, 1);
    });
  });

  group('wirds and their bookmarks', () {
    test('deleting a wird keeps its bookmarks, now general', () async {
      final a = await repo.create(draft('A'));
      await repo.addBookmark(40, 'stays', wirdId: a);
      await repo.delete(a);
      final entry = (await list()).single;
      expect(entry.bookmark.note, 'stays');
      expect(entry.bookmark.wirdId, isNull);
      expect(entry.wirdName, isNull);
    });

    test('a wird\'s count is only its own bookmarks', () async {
      final a = await repo.create(draft('A'));
      final b = await repo.create(draft('B'));
      await repo.addBookmark(1, null, wirdId: a);
      await repo.addBookmark(2, null, wirdId: a);
      await repo.addBookmark(3, null, wirdId: b);
      await repo.addBookmark(4, null);
      expect(await repo.bookmarkCount(a), 2);
      expect(await repo.bookmarkCount(b), 1);
    });

    test('opening a bookmark\'s page is browse mode and moves no wird', () async {
      final a = await repo.create(draft('A', start: 10));
      await repo.setActive(a);
      await repo.addBookmark(77, 'x');
      await controller.init();
      await controller.jumpTo((await list()).single.bookmark.page);
      expect(controller.page, 77);
      expect(controller.browsing, isTrue);
      expect((await repo.wirdById(a))!.currentPage, 10);
    });
  });
}
