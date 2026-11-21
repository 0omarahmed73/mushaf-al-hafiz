// The data rules behind the reader's bookmark icon (feature 006, task T003): one tap adds a bookmark with no note when
// the scope has none, otherwise removes the scope's bookmarks; «تراجع» undoes exactly that tap.
// Scope: a wird's id, or null for the general bookmarks (data-model.md «Scope»).
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  late int w1;
  late int w2;

  Future<int> newWird(String name) => repo.create(
    WirdDraft(
      name: name,
      type: WirdType.reading,
      startPage: 1,
      dailyPages: 5,
      color: 0xFF1565C0,
    ),
  );

  Future<List<Bookmark>> rows() async => [
    for (final e in await repo.watchBookmarks().first) e.bookmark,
  ];

  List<Bookmark> onPage(List<Bookmark> all, int page) => [
    for (final b in all)
      if (b.page == page) b,
  ];

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    w1 = await newWird('الأول');
    w2 = await newWird('الثاني');
  });

  tearDown(() => db.close());

  group('toggleBookmark', () {
    test(
      'a page with no bookmark of the scope gets one, with no note',
      () async {
        final result = await repo.toggleBookmark(10, wirdId: w1);
        expect(result.wasAdded, isTrue);
        expect(result.addedId, isNotNull);
        expect(result.removed, isEmpty);
        expect(result.page, 10);
        final all = await rows();
        expect(all, hasLength(1));
        expect(all.single.id, result.addedId);
        expect(all.single.page, 10);
        expect(all.single.wirdId, w1);
        expect(all.single.note, isNull);
      },
    );

    test('with no wird the bookmark is general', () async {
      await repo.toggleBookmark(10);
      expect((await rows()).single.wirdId, isNull);
    });

    test('a page that has one of the scope loses it, and the result holds the rows', () async {
      await repo.addBookmark(10, 'آية الكرسي', wirdId: w1);
      final before = (await rows()).single;
      final result = await repo.toggleBookmark(10, wirdId: w1);
      expect(result.wasAdded, isFalse);
      expect(result.addedId, isNull);
      expect(result.removed, hasLength(1));
      expect(result.removed.single.id, before.id);
      expect(result.removed.single.note, 'آية الكرسي');
      expect(await rows(), isEmpty);
    });

    test('a second tap after an add removes it', () async {
      await repo.toggleBookmark(7, wirdId: w1);
      final second = await repo.toggleBookmark(7, wirdId: w1);
      expect(second.wasAdded, isFalse);
      expect(await rows(), isEmpty);
    });

    test('only the scope is read and removed: a wird never touches another wird or the general ones', () async {
      await repo.addBookmark(10, 'عامة');
      await repo.addBookmark(10, 'الأول', wirdId: w1);
      await repo.addBookmark(10, 'الثاني', wirdId: w2);
      await repo.toggleBookmark(10, wirdId: w1);
      expect([for (final b in onPage(await rows(), 10)) b.note]..sort(), [
        'الثاني',
        'عامة',
      ]);
      await repo.toggleBookmark(10); // the general scope
      expect([for (final b in onPage(await rows(), 10)) b.note], ['الثاني']);
    });

    test('a page that has only another scope\'s bookmark gets a new one and keeps that one', () async {
      await repo.addBookmark(10, 'الثاني', wirdId: w2);
      final result = await repo.toggleBookmark(10, wirdId: w1);
      expect(result.wasAdded, isTrue);
      final here = onPage(await rows(), 10);
      expect(here, hasLength(2));
      expect({for (final b in here) b.wirdId}, {w1, w2});
    });

    test('two bookmarks of the scope on one page are both removed', () async {
      await repo.addBookmark(10, 'أ', wirdId: w1);
      await repo.addBookmark(10, 'ب', wirdId: w1);
      final result = await repo.toggleBookmark(10, wirdId: w1);
      expect(result.removed, hasLength(2));
      expect(await rows(), isEmpty);
    });

    test('bookmarks of other pages are never touched', () async {
      await repo.addBookmark(9, 'قبل', wirdId: w1);
      await repo.addBookmark(11, 'بعد', wirdId: w1);
      await repo.toggleBookmark(10, wirdId: w1);
      await repo.toggleBookmark(10, wirdId: w1);
      expect({for (final b in await rows()) b.page}, {9, 11});
    });

    test('a page outside 1 to 604 is refused', () async {
      await expectLater(repo.toggleBookmark(0), throwsArgumentError);
      await expectLater(
        repo.toggleBookmark(605, wirdId: w1),
        throwsArgumentError,
      );
      expect(await rows(), isEmpty);
    });
  });

  group('undoBookmarkToggle', () {
    test('after an add it deletes that bookmark only', () async {
      await repo.addBookmark(10, 'باقية', wirdId: w2);
      final result = await repo.toggleBookmark(10, wirdId: w1);
      await repo.undoBookmarkToggle(result);
      final all = await rows();
      expect(all, hasLength(1));
      expect(all.single.note, 'باقية');
    });

    test('after a removal it brings the rows back with the same id, page, owner, note and time', () async {
      await repo.addBookmark(10, 'ملاحظة', wirdId: w1);
      await repo.addBookmark(11, 'أخرى', wirdId: w1);
      final before = await rows();
      final removedRow = onPage(before, 10).single;
      final result = await repo.toggleBookmark(10, wirdId: w1);
      expect(await rows(), hasLength(1));
      await repo.undoBookmarkToggle(result);
      final after = await rows();
      expect(after, hasLength(2));
      final back = onPage(after, 10).single;
      expect(back.id, removedRow.id);
      expect(back.page, removedRow.page);
      expect(back.wirdId, removedRow.wirdId);
      expect(back.note, removedRow.note);
      expect(back.createdAt, removedRow.createdAt);
      expect(
        [for (final b in after) b.id],
        [for (final b in before) b.id],
        reason: 'the same order in the sheet',
      );
    });

    test('two removed rows both come back', () async {
      await repo.addBookmark(10, 'أ', wirdId: w1);
      await repo.addBookmark(10, 'ب', wirdId: w1);
      final result = await repo.toggleBookmark(10, wirdId: w1);
      await repo.undoBookmarkToggle(result);
      expect([for (final b in await rows()) b.note]..sort(), ['أ', 'ب']);
    });

    test(
      'a bookmark whose wird was deleted meanwhile comes back general',
      () async {
        await repo.addBookmark(10, 'ملاحظة', wirdId: w1);
        final result = await repo.toggleBookmark(10, wirdId: w1);
        await repo.delete(w1);
        await repo.undoBookmarkToggle(result);
        final back = (await rows()).single;
        expect(back.wirdId, isNull);
        expect(back.note, 'ملاحظة');
      },
    );

    test('undoing twice changes nothing the second time', () async {
      await repo.addBookmark(10, 'ملاحظة', wirdId: w1);
      final removed = await repo.toggleBookmark(10, wirdId: w1);
      await repo.undoBookmarkToggle(removed);
      await repo.undoBookmarkToggle(removed);
      expect(await rows(), hasLength(1));
      final added = await repo.toggleBookmark(20, wirdId: w1);
      await repo.undoBookmarkToggle(added);
      await repo.undoBookmarkToggle(added);
      expect(onPage(await rows(), 20), isEmpty);
    });

    test('undoing an add whose bookmark was already deleted in the sheet does not fail', () async {
      final added = await repo.toggleBookmark(10, wirdId: w1);
      await repo.removeBookmark(added.addedId!);
      await repo.undoBookmarkToggle(added);
      expect(await rows(), isEmpty);
    });
  });
}
