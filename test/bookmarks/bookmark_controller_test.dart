// The state behind the reader's bookmark icon (feature 006, task T004): `pageBookmarked` follows the page, the scope
// (the active wird's bookmarks while following a wird, the general ones while browsing) and every change made to the
// bookmarks, and a tap writes once. No widgets here.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/mushaf/reader_controller.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  late ReaderController c;
  late int w1; // the default wird, active, followed
  late int w2;

  Future<void> settle() => pumpEventQueue(times: 60);

  Future<int> newWird(String name) => repo.create(
    WirdDraft(
      name: name,
      type: WirdType.reading,
      startPage: 1,
      dailyPages: 5,
      color: 0xFF1565C0,
    ),
  );

  Future<void> start() async {
    c = ReaderController(repo);
    await c.init();
    await settle();
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    await repo.ensureDefaults();
    w1 = (await repo.activeWird())!.id;
    w2 = await newWird('الثاني');
  });

  tearDown(() async {
    c.dispose();
    await pumpEventQueue();
    await db.close();
  });

  test('it starts false and stays false on a page with no bookmark', () async {
    await start();
    expect(c.pageBookmarked.value, isFalse);
  });

  test(
    'a bookmark of the followed wird on the page shown makes it true',
    () async {
      await repo.addBookmark(1, null, wirdId: w1);
      await start();
      expect(c.pageBookmarked.value, isTrue);
    },
  );

  test('it follows the page: onPageShown and jumpTo', () async {
    await repo.addBookmark(5, null, wirdId: w1);
    await repo.addBookmark(9, 'عامة');
    await start();
    expect(c.pageBookmarked.value, isFalse);
    await c.onPageShown(5);
    expect(c.pageBookmarked.value, isTrue);
    await c.onPageShown(6);
    expect(c.pageBookmarked.value, isFalse);
    await c.jumpTo(9); // browsing: the general bookmark counts
    expect(c.pageBookmarked.value, isTrue);
  });

  test('the scope: general bookmarks do not count while following a wird, and a wird\'s do not count while browsing', () async {
    await repo.addBookmark(5, 'عامة');
    await repo.addBookmark(7, null, wirdId: w1);
    await start();
    await c.onPageShown(5);
    expect(c.browsing, isFalse);
    expect(
      c.pageBookmarked.value,
      isFalse,
      reason: 'a general bookmark, while following a wird',
    );
    await c.jumpTo(5);
    expect(c.browsing, isTrue);
    expect(
      c.pageBookmarked.value,
      isTrue,
      reason: 'the general bookmark, while browsing',
    );
    await c.jumpTo(7);
    expect(
      c.pageBookmarked.value,
      isFalse,
      reason: 'the wird\'s bookmark, while browsing',
    );
  });

  test('«اجعلها موضعي» changes the scope back to the wird', () async {
    await repo.addBookmark(7, null, wirdId: w1);
    await start();
    await c.jumpTo(7);
    expect(c.pageBookmarked.value, isFalse);
    await c.makeThisMyPosition();
    expect(c.browsing, isFalse);
    expect(c.pageBookmarked.value, isTrue);
  });

  test('another wird\'s bookmark never counts, and switching wird changes the scope', () async {
    await repo.addBookmark(1, null, wirdId: w2);
    await start();
    expect(c.pageBookmarked.value, isFalse);
    await c.switchWird(w2);
    expect(
      c.pageBookmarked.value,
      isTrue,
      reason: 'the wird now followed has it on its page',
    );
    await c.switchWird(w1);
    expect(c.pageBookmarked.value, isFalse);
  });

  test('it follows changes made straight on the repository once refreshBookmarks runs, as after the sheet closes', () async {
    await start();
    final id = await repo.addBookmark(1, 'ملاحظة', wirdId: w1);
    expect(
      c.pageBookmarked.value,
      isFalse,
      reason: 'the controller holds no stream: nothing told it',
    );
    await c.refreshBookmarks();
    expect(c.pageBookmarked.value, isTrue);
    await repo.removeBookmark(id);
    await c.refreshBookmarks();
    expect(c.pageBookmarked.value, isFalse);
  });

  test('a bookmark added through the controller (the sheet\'s add button) fills the icon at once', () async {
    await start();
    await c.addBookmark(note: 'من القائمة');
    expect(c.pageBookmarked.value, isTrue);
  });

  test('a restore reloads the controller and the icon with it', () async {
    await start();
    await repo.addBookmark(1, null, wirdId: w1);
    expect(c.pageBookmarked.value, isFalse);
    await c.reload();
    expect(c.pageBookmarked.value, isTrue);
  });

  test('deleting the followed wird turns its bookmarks general and the controller browses', () async {
    await repo.addBookmark(1, null, wirdId: w1);
    await start();
    expect(c.pageBookmarked.value, isTrue);
    await repo.delete(w1);
    await settle();
    // The other wird becomes active or the reader browses; either way the answer comes from the new scope.
    final scope = c.browsing || c.wird == null ? null : c.wird!.id;
    final expected = (await repo.watchBookmarks().first).any(
      (e) => e.bookmark.page == c.page && e.bookmark.wirdId == scope,
    );
    expect(c.pageBookmarked.value, expected);
  });

  test('a tap adds, the next removes, and the state follows', () async {
    await start();
    final added = await c.toggleBookmark();
    expect(added, isNotNull);
    expect(added!.wasAdded, isTrue);
    await settle();
    expect(c.pageBookmarked.value, isTrue);
    final removed = await c.toggleBookmark();
    expect(removed!.wasAdded, isFalse);
    await settle();
    expect(c.pageBookmarked.value, isFalse);
  });

  test('a tap while the previous one is being written is ignored: one bookmark, never two', () async {
    await start();
    final first = c.toggleBookmark();
    final second = c.toggleBookmark();
    expect(await second, isNull);
    expect(await first, isNotNull);
    await settle();
    final all = await repo.watchBookmarks().first;
    expect(all, hasLength(1));
    // and the busy flag is released afterwards
    expect(await c.toggleBookmark(), isNotNull);
  });

  test('undoBookmarkToggle brings the state back', () async {
    await repo.addBookmark(1, 'ملاحظة', wirdId: w1);
    await start();
    final removed = await c.toggleBookmark();
    await settle();
    expect(c.pageBookmarked.value, isFalse);
    await c.undoBookmarkToggle(removed!);
    await settle();
    expect(c.pageBookmarked.value, isTrue);
  });

  test('a bookmark change does not notify the controller\'s listeners (the page is not rebuilt)', () async {
    await start();
    var notifications = 0;
    c.addListener(() => notifications++);
    await repo.addBookmark(1, null, wirdId: w1);
    await settle();
    await c.toggleBookmark();
    await settle();
    expect(
      c.pageBookmarked.value,
      isFalse,
      reason: 'added by the repository, removed by the toggle',
    );
    expect(notifications, 0);
  });

  test(
    'after dispose a bookmark change does nothing and does not throw',
    () async {
      await start();
      c.dispose();
      await repo.addBookmark(1, null, wirdId: w1);
      await settle();
      // tearDown disposes again: replace the controller by a fresh one so that it stays valid
      c = ReaderController(repo);
    },
  );
}
