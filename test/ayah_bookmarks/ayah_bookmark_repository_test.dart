// The data rules of the ayah bookmark (feature 013, task T008): the toggle of the sheet's bookmark row, the four saves of
// the note, «تراجع» for every kind of change, and the scope rule of feature 006 (a wird's id, or null for the general
// ones). Each test has its own in-memory database (spec FR-003 to FR-006, FR-021, SC-001, SC-009, SC-013; data-model.md).
import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/wirds/ayah_bookmark_change.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  late int w1;
  late int w2;
  const baqarah282 = AyahRef(2, 282);
  const kursi = AyahRef(2, 255);

  Future<int> newWird(String name) => repo.create(
    WirdDraft(
      name: name,
      type: WirdType.reading,
      startPage: 1,
      dailyPages: 5,
      color: 0xFF1565C0,
    ),
  );

  Future<List<Bookmark>> all() =>
      (db.select(db.bookmarks)..orderBy([(b) => OrderingTerm.asc(b.id)])).get();

  /// An ayah bookmark written straight to the table, as a restored backup may hold them.
  Future<int> seedAyah(
    AyahRef ref,
    int page, {
    int? wirdId,
    String? note,
    DateTime? at,
  }) => db
      .into(db.bookmarks)
      .insert(
        BookmarksCompanion.insert(
          page: page,
          wirdId: Value(wirdId),
          note: Value(note),
          surah: Value(ref.surah),
          ayah: Value(ref.ayah),
          createdAt: at == null ? const Value.absent() : Value(at),
        ),
      );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    w1 = await newWird('الأول');
    w2 = await newWird('الثاني');
  });

  tearDown(() => db.close());

  group('toggleAyahBookmark', () {
    test('an ayah with no bookmark of the scope gets one, with no note and the given page', () async {
      final change = await repo.toggleAyahBookmark(
        baqarah282,
        page: 48,
        wirdId: w1,
      );
      expect(change.kind, AyahChangeKind.added);
      expect(change.ref, baqarah282);
      expect(change.page, 48);
      expect(change.removed, isEmpty);
      expect(change.before, isEmpty);
      final rows = await all();
      expect(rows, hasLength(1));
      final b = rows.single;
      expect(b.id, change.addedId);
      expect(
        (b.surah, b.ayah, b.page, b.wirdId, b.note),
        (2, 282, 48, w1, null),
      );
    });

    test('a general add when the scope is null', () async {
      final change = await repo.toggleAyahBookmark(baqarah282, page: 48);
      expect(change.kind, AyahChangeKind.added);
      expect((await all()).single.wirdId, isNull);
    });

    test('an ayah with a bookmark of the scope loses all of its rows, note included', () async {
      final a = await seedAyah(baqarah282, 48, wirdId: w1, note: 'أراجع هنا');
      final b = await seedAyah(
        baqarah282,
        48,
        wirdId: w1,
      ); // two rows: only a restore can make them
      final before = await all();
      final change = await repo.toggleAyahBookmark(
        baqarah282,
        page: 48,
        wirdId: w1,
      );
      expect(change.kind, AyahChangeKind.removed);
      expect(change.addedId, isNull);
      expect([for (final r in change.removed) r.id], unorderedEquals([a, b]));
      expect(change.removed.toSet(), before.toSet());
      expect(await all(), isEmpty);
    });

    test('never reads or touches a page bookmark, another wird\'s, or a general one', () async {
      final page = await repo.addBookmark(48, 'صفحة', wirdId: w1);
      final other = await seedAyah(baqarah282, 48, wirdId: w2, note: 'للثاني');
      final general = await seedAyah(baqarah282, 48);
      final untouched = await all();

      final added = await repo.toggleAyahBookmark(
        baqarah282,
        page: 48,
        wirdId: w1,
      );
      expect(
        added.kind,
        AyahChangeKind.added,
        reason: 'the other rows are not this scope\'s',
      );
      final removed = await repo.toggleAyahBookmark(
        baqarah282,
        page: 48,
        wirdId: w1,
      );
      expect(removed.kind, AyahChangeKind.removed);
      expect([for (final r in removed.removed) r.id], [added.addedId]);
      expect(await all(), untouched);
      expect([page, other, general], everyElement(isPositive));
    });

    test(
      'the general scope never touches a wird\'s ayah bookmark (the reverse)',
      () async {
        await seedAyah(baqarah282, 48, wirdId: w1);
        final untouched = await all();
        final added = await repo.toggleAyahBookmark(baqarah282, page: 48);
        expect(added.kind, AyahChangeKind.added);
        await repo.toggleAyahBookmark(baqarah282, page: 48);
        expect(await all(), untouched);
      },
    );

    test('another ayah on the same page is not the same bookmark', () async {
      await seedAyah(const AyahRef(2, 281), 48, wirdId: w1);
      final change = await repo.toggleAyahBookmark(
        baqarah282,
        page: 48,
        wirdId: w1,
      );
      expect(change.kind, AyahChangeKind.added);
      expect(await all(), hasLength(2));
    });

    test(
      'a page outside 1..604 is an ArgumentError and writes nothing',
      () async {
        await expectLater(
          repo.toggleAyahBookmark(baqarah282, page: 0),
          throwsArgumentError,
        );
        await expectLater(
          repo.toggleAyahBookmark(baqarah282, page: 605),
          throwsArgumentError,
        );
        await expectLater(
          repo.saveAyahNote(baqarah282, page: 0, note: 'x'),
          throwsArgumentError,
        );
        await expectLater(
          repo.saveAyahNote(baqarah282, page: 605, note: 'x'),
          throwsArgumentError,
        );
        expect(await all(), isEmpty);
      },
    );
  });

  group('saveAyahNote: the four cases', () {
    test('(a) a note on an ayah with no bookmark creates one with the note, owned by the scope', () async {
      final change = await repo.saveAyahNote(
        baqarah282,
        page: 48,
        wirdId: w1,
        note: '  أراجع هنا  ',
      );
      expect(change!.kind, AyahChangeKind.createdWithNote);
      expect(change.ref, baqarah282);
      expect(change.page, 48);
      final b = (await all()).single;
      expect(b.id, change.addedId);
      expect(
        (b.surah, b.ayah, b.page, b.wirdId, b.note),
        (2, 282, 48, w1, 'أراجع هنا'),
      );
    });

    test('(b) a note on a bookmarked ayah replaces the note of every row of the scope and nothing else', () async {
      final at = DateTime(2026, 11, 1, 8);
      final a = await seedAyah(
        baqarah282,
        48,
        wirdId: w1,
        note: 'قديمة',
        at: at,
      );
      final b = await seedAyah(baqarah282, 48, wirdId: w1, at: at);
      final other = await seedAyah(baqarah282, 48, wirdId: w2, note: 'للثاني');
      final page = await repo.addBookmark(48, 'صفحة', wirdId: w1);
      final before = await all();
      final change = await repo.saveAyahNote(
        baqarah282,
        page: 48,
        wirdId: w1,
        note: 'جديدة',
      );
      expect(change!.kind, AyahChangeKind.noteReplaced);
      expect(change.addedId, isNull);
      expect(change.removed, isEmpty);
      expect(
        change.before,
        unorderedEquals([(id: a, note: 'قديمة'), (id: b, note: null)]),
      );
      final rows = await all();
      expect(rows, hasLength(4), reason: 'no second bookmark');
      for (final r in rows) {
        final old = before.firstWhere((x) => x.id == r.id);
        if (r.id == a || r.id == b) {
          expect(r.note, 'جديدة');
          expect(
            r.copyWith(note: Value(old.note)),
            old,
            reason: 'id, page, owner and time unchanged',
          );
        } else {
          expect(
            r,
            old,
            reason: 'row ${r.id} is not this scope\'s ayah bookmark',
          );
        }
      }
      expect([other, page], everyElement(isPositive));
    });

    test('(c) an empty note on a bookmarked ayah clears the note and keeps the bookmark', () async {
      final a = await seedAyah(baqarah282, 48, wirdId: w1, note: 'قديمة');
      final before = (await all()).single;
      final change = await repo.saveAyahNote(
        baqarah282,
        page: 48,
        wirdId: w1,
        note: '',
      );
      expect(change!.kind, AyahChangeKind.noteCleared);
      expect(change.before, [(id: a, note: 'قديمة')]);
      final after = (await all()).single;
      expect(after.note, isNull);
      expect(after.copyWith(note: Value(before.note)), before);
    });

    test('spaces only, and null, are an empty note', () async {
      await seedAyah(baqarah282, 48, wirdId: w1, note: 'قديمة');
      final change = await repo.saveAyahNote(
        baqarah282,
        page: 48,
        wirdId: w1,
        note: '   ',
      );
      expect(change!.kind, AyahChangeKind.noteCleared);
      await repo.undoAyahBookmarkChange(change);
      final again = await repo.saveAyahNote(
        baqarah282,
        page: 48,
        wirdId: w1,
        note: null,
      );
      expect(again!.kind, AyahChangeKind.noteCleared);
    });

    test('(d) an empty note on an ayah with no bookmark returns null and writes nothing', () async {
      await seedAyah(baqarah282, 48, wirdId: w2, note: 'للثاني');
      final before = await all();
      expect(
        await repo.saveAyahNote(baqarah282, page: 48, wirdId: w1, note: ''),
        isNull,
      );
      expect(
        await repo.saveAyahNote(baqarah282, page: 48, wirdId: w1, note: '   '),
        isNull,
      );
      expect(await repo.saveAyahNote(baqarah282, page: 48, wirdId: w1), isNull);
      expect(await all(), before);
    });
  });

  group('undoAyahBookmarkChange restores exactly', () {
    test('after an add', () async {
      await seedAyah(kursi, 42, wirdId: w1);
      final before = await all();
      final change = await repo.toggleAyahBookmark(
        baqarah282,
        page: 48,
        wirdId: w1,
      );
      await repo.undoAyahBookmarkChange(change);
      expect(await all(), before);
      await repo.undoAyahBookmarkChange(change);
      expect(await all(), before, reason: 'twice changes nothing more');
    });

    test(
      'after a removal of two rows, with ids, times, notes, surah and ayah',
      () async {
        await seedAyah(
          baqarah282,
          48,
          wirdId: w1,
          note: 'أراجع هنا',
          at: DateTime(2026, 1, 2, 3, 4, 5),
        );
        await seedAyah(baqarah282, 48, wirdId: w1, at: DateTime(2026, 2, 3));
        final before = await all();
        final change = await repo.toggleAyahBookmark(
          baqarah282,
          page: 48,
          wirdId: w1,
        );
        expect(await all(), isEmpty);
        await repo.undoAyahBookmarkChange(change);
        expect(await all(), before);
        await repo.undoAyahBookmarkChange(change);
        expect(await all(), before);
      },
    );

    test(
      'a removed bookmark of a wird deleted since comes back general',
      () async {
        await seedAyah(baqarah282, 48, wirdId: w2, note: 'للثاني');
        final before = (await all()).single;
        final change = await repo.toggleAyahBookmark(
          baqarah282,
          page: 48,
          wirdId: w2,
        );
        await repo.delete(w2);
        await repo.undoAyahBookmarkChange(change);
        final back = (await all()).single;
        expect(back.wirdId, isNull);
        expect(back.copyWith(wirdId: Value(w2)), before);
      },
    );

    test('after a note created the bookmark', () async {
      final before = await all();
      final change = await repo.saveAyahNote(
        baqarah282,
        page: 48,
        wirdId: w1,
        note: 'أراجع هنا',
      );
      await repo.undoAyahBookmarkChange(change!);
      expect(await all(), before);
      await repo.undoAyahBookmarkChange(change);
      expect(await all(), before);
    });

    test('after a note replaced and after a note was cleared', () async {
      await seedAyah(baqarah282, 48, wirdId: w1, note: 'قديمة');
      await seedAyah(baqarah282, 48, wirdId: w1);
      final before = await all();
      final replaced = await repo.saveAyahNote(
        baqarah282,
        page: 48,
        wirdId: w1,
        note: 'جديدة',
      );
      await repo.undoAyahBookmarkChange(replaced!);
      expect(await all(), before);
      final cleared = await repo.saveAyahNote(
        baqarah282,
        page: 48,
        wirdId: w1,
        note: '',
      );
      await repo.undoAyahBookmarkChange(cleared!);
      expect(await all(), before);
      await repo.undoAyahBookmarkChange(cleared);
      expect(await all(), before);
    });
  });

  group('reading', () {
    test(
      'ayahBookmarkRows: the ayah\'s rows of the scope, newest first',
      () async {
        final old = await seedAyah(
          baqarah282,
          48,
          wirdId: w1,
          at: DateTime(2026, 1, 1),
        );
        final young = await seedAyah(
          baqarah282,
          48,
          wirdId: w1,
          note: 'ب',
          at: DateTime(2026, 6, 1),
        );
        await seedAyah(baqarah282, 48, wirdId: w2);
        await seedAyah(baqarah282, 48);
        await seedAyah(kursi, 42, wirdId: w1);
        await repo.addBookmark(48, null, wirdId: w1);
        expect(
          [
            for (final r in await repo.ayahBookmarkRows(baqarah282, wirdId: w1))
              r.id,
          ],
          [young, old],
        );
        expect(await repo.ayahBookmarkRows(baqarah282), hasLength(1));
        expect(await repo.ayahBookmarkRows(const AyahRef(1, 1)), isEmpty);
      },
    );

    test('ayahMarksOf: the ayat with an ayah bookmark in the scope', () async {
      await seedAyah(baqarah282, 48, wirdId: w1);
      await seedAyah(kursi, 42, wirdId: w2);
      await seedAyah(const AyahRef(1, 1), 1);
      await repo.addBookmark(50, null, wirdId: w1);
      await repo.addBookmark(51, null);
      final rows = await repo.bookmarkRows();
      expect(repo.ayahMarksOf(rows, w1), {baqarah282});
      expect(repo.ayahMarksOf(rows, w2), {kursi});
      expect(repo.ayahMarksOf(rows, null), {const AyahRef(1, 1)});
      expect(repo.ayahMarksOf(const [], w1), isEmpty);
    });
  });
}
