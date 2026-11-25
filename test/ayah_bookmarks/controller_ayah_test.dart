// The reader controller and ayah bookmarks (feature 013, task T016; spec FR-002, FR-003, FR-005, FR-011, FR-022, SC-002;
// data-model.md Scope, Controller state; research D5): `ayahMarks` holds the scope's bookmarked ayat and follows every change
// of scope and of rows, `pageBookmarked` counts page bookmarks only, and the ayah actions write once, on the page where the
// ayah begins, without notifying the controller's listeners. A real controller over an in-memory repository, real meta.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/reader_controller.dart';
import 'package:mushaf/wirds/ayah_bookmark_change.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/ayah_bookmark_harness.dart';

void main() {
  late MushafMeta meta;
  late AppDatabase db;
  late WirdRepository repo;
  late ReaderController c;
  late int w1; // the default wird, active, followed
  late int w2;
  late List<Set<AyahRef>> marks; // every value ayahMarks was given
  const baqarah282 = AyahRef(2, 282);
  const kursi = AyahRef(2, 255);

  Future<void> settle() => pumpEventQueue(times: 60);

  Future<void> start({int page = 48}) async {
    await repo.setPage(w1, page);
    c = ReaderController(repo)..attachMeta(meta);
    marks = [];
    c.ayahMarks.addListener(() => marks.add(c.ayahMarks.value));
    await c.init();
    await settle();
  }

  setUpAll(() async => meta = await realMeta());

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    await repo.ensureDefaults();
    w1 = (await repo.activeWird())!.id;
    w2 = await repo.create(
      const WirdDraft(
        name: 'الثاني',
        type: WirdType.reading,
        startPage: 300,
        dailyPages: 5,
        color: 0xFF1565C0,
      ),
    );
    c = ReaderController(repo);
  });

  tearDown(() async {
    c.dispose();
    await pumpEventQueue();
    await db.close();
  });

  test(
    'ayahMarks is empty before init ends, then holds the scope\'s ayat only',
    () async {
      await seedAyahBookmark(db, meta, baqarah282, wirdId: w1);
      await seedAyahBookmark(db, meta, kursi, wirdId: w2);
      await seedAyahBookmark(db, meta, const AyahRef(1, 1));
      await repo.addBookmark(48, null, wirdId: w1);
      await repo.setPage(w1, 48);
      c = ReaderController(repo)..attachMeta(meta);
      final init = c.init();
      expect(c.ayahMarks.value, isEmpty);
      await init;
      expect(c.ayahMarks.value, {baqarah282});
    },
  );

  test('it follows the scope: jumpTo (browse: the general ones), makeThisMyPosition, switchWird', () async {
    await seedAyahBookmark(db, meta, baqarah282, wirdId: w1);
    await seedAyahBookmark(db, meta, kursi, wirdId: w2);
    await seedAyahBookmark(db, meta, const AyahRef(1, 1));
    await start();
    expect(c.ayahMarks.value, {baqarah282});
    await c.jumpTo(1);
    expect(c.ayahMarks.value, {const AyahRef(1, 1)});
    await c.makeThisMyPosition();
    expect(c.ayahMarks.value, {baqarah282});
    await c.switchWird(w2);
    expect(c.ayahMarks.value, {kursi});
  });

  test('deleting the followed wird: its bookmarks become general and the scope follows', () async {
    await seedAyahBookmark(db, meta, baqarah282, wirdId: w1);
    await start();
    expect(c.ayahMarks.value, {baqarah282});
    await repo.delete(w1);
    await settle();
    final scope = c.browsing || c.wird == null ? null : c.wird!.id;
    expect(c.ayahMarks.value, scope == null ? {baqarah282} : isEmpty);
  });

  test('an add, a removal and a restore made straight on the repository show after refreshBookmarks (the list sheet)', () async {
    await start();
    final id = await seedAyahBookmark(db, meta, baqarah282, wirdId: w1);
    expect(
      c.ayahMarks.value,
      isEmpty,
      reason: 'no stream: nothing told it yet',
    );
    await c.refreshBookmarks();
    expect(c.ayahMarks.value, {baqarah282});
    await repo.removeBookmark(id);
    await c.refreshBookmarks();
    expect(c.ayahMarks.value, isEmpty);
    await seedAyahBookmark(db, meta, kursi, wirdId: w1);
    await c.reload();
    expect(c.ayahMarks.value, {kursi});
  });

  test('it is replaced only on a real change', () async {
    await seedAyahBookmark(db, meta, baqarah282, wirdId: w1);
    await start();
    expect(marks, [
      {baqarah282},
    ]);
    await repo.addBookmark(48, null, wirdId: w1); // a page bookmark
    await seedAyahBookmark(db, meta, kursi, wirdId: w2); // another scope
    await c.refreshBookmarks();
    await c.onPageShown(49);
    await c.onPageShown(48);
    expect(
      marks,
      hasLength(1),
      reason: 'nothing changed for the scope\'s ayat',
    );
    await c.toggleAyahBookmark(kursi);
    expect(marks, [
      {baqarah282},
      {baqarah282, kursi},
    ]);
  });

  test('pageBookmarked is false with only an ayah bookmark and true with a page bookmark', () async {
    await seedAyahBookmark(db, meta, baqarah282, wirdId: w1);
    await start();
    expect(c.pageBookmarked.value, isFalse);
    await repo.addBookmark(48, null, wirdId: w1);
    await c.refreshBookmarks();
    expect(c.pageBookmarked.value, isTrue);
  });

  test(
    'ayahState is answered from memory: bookmarked and the note of the scope',
    () async {
      await seedAyahBookmark(
        db,
        meta,
        baqarah282,
        wirdId: w1,
        note: 'أراجع هنا',
      );
      await seedAyahBookmark(db, meta, kursi, wirdId: w2, note: 'للثاني');
      await start();
      expect(c.ayahState(baqarah282), (bookmarked: true, note: 'أراجع هنا'));
      expect(c.ayahState(kursi), (bookmarked: false, note: null));
      await c.jumpTo(10);
      expect(c.ayahState(baqarah282), (bookmarked: false, note: null));
    },
  );

  test('toggleAyahBookmark stores the page where the ayah begins and owns it by the scope', () async {
    await start(page: 49); // the page shown is not where 2:282 begins
    final added = await c.toggleAyahBookmark(baqarah282);
    expect(added!.kind, AyahChangeKind.added);
    expect(added.page, meta.pageOfAyah(2, 282));
    var b = (await allBookmarks(db)).single;
    expect((b.surah, b.ayah, b.page, b.wirdId, b.note), (2, 282, 48, w1, null));
    expect(c.ayahMarks.value, {baqarah282});
    expect(c.ayahState(baqarah282).bookmarked, isTrue);

    await c.jumpTo(300); // browse: general
    final general = await c.toggleAyahBookmark(const AyahRef(114, 6));
    b = (await allBookmarks(db)).last;
    expect((b.surah, b.ayah, b.page, b.wirdId), (114, 6, 604, null));
    expect(general!.page, 604);

    final removed = await c.toggleAyahBookmark(const AyahRef(114, 6));
    expect(removed!.kind, AyahChangeKind.removed);
    await c.undoAyahBookmarkChange(removed);
    expect(c.ayahMarks.value, {const AyahRef(114, 6)});
  });

  test('saveAyahNote stores the page of the ayah and the scope, and case (d) returns null', () async {
    await start();
    expect(await c.saveAyahNote(kursi, ''), isNull);
    final created = await c.saveAyahNote(kursi, 'آية الكرسي');
    expect(created!.kind, AyahChangeKind.createdWithNote);
    final b = (await allBookmarks(db)).single;
    expect(
      (b.surah, b.ayah, b.page, b.wirdId, b.note),
      (2, 255, meta.pageOfAyah(2, 255), w1, 'آية الكرسي'),
    );
    expect(c.ayahState(kursi), (bookmarked: true, note: 'آية الكرسي'));
    final cleared = await c.saveAyahNote(kursi, '  ');
    expect(cleared!.kind, AyahChangeKind.noteCleared);
    expect(c.ayahState(kursi), (bookmarked: true, note: null));
    await c.undoAyahBookmarkChange(cleared);
    expect(c.ayahState(kursi).note, 'آية الكرسي');
  });

  test('a call while another write is in progress returns null and writes nothing (the shared busy guard)', () async {
    await start();
    final first = c.toggleAyahBookmark(baqarah282);
    expect(await c.toggleAyahBookmark(baqarah282), isNull);
    expect(await c.saveAyahNote(baqarah282, 'x'), isNull);
    expect(await c.toggleBookmark(), isNull);
    expect(await first, isNotNull);
    expect(await allBookmarks(db), hasLength(1));
    final page = c.toggleBookmark();
    expect(await c.toggleAyahBookmark(kursi), isNull);
    expect(await page, isNotNull);
    expect(
      await c.toggleAyahBookmark(kursi),
      isNotNull,
      reason: 'released afterwards',
    );
  });

  test('no ayah action notifies the controller\'s listeners (the page is not rebuilt by the controller)', () async {
    await start();
    var notifications = 0;
    c.addListener(() => notifications++);
    final added = await c.toggleAyahBookmark(baqarah282);
    await c.undoAyahBookmarkChange(added!);
    final note = await c.saveAyahNote(baqarah282, 'ملاحظة');
    await c.saveAyahNote(baqarah282, 'أخرى');
    await c.undoAyahBookmarkChange(note!);
    await c.refreshBookmarks();
    await settle();
    expect(notifications, 0);
  });
}
