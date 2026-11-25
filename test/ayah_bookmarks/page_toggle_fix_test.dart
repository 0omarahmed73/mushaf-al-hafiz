// The regression of feature 006's page toggle that feature 013 fixes (spec FR-011, SC-012; research D4): the page icon
// adds and removes PAGE bookmarks only. Before the fix `toggleBookmark(page, wirdId)` selected every bookmark of the page
// in the scope and deleted them all, ayah bookmarks included.
import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  late int w1;

  Future<List<Bookmark>> all() =>
      (db.select(db.bookmarks)..orderBy([(b) => OrderingTerm.asc(b.id)])).get();

  Future<int> seedAyah(
    int surah,
    int ayah,
    int page, {
    int? wirdId,
    String? note,
  }) => db
      .into(db.bookmarks)
      .insert(
        BookmarksCompanion.insert(
          page: page,
          wirdId: Value(wirdId),
          note: Value(note),
          surah: Value(surah),
          ayah: Value(ayah),
        ),
      );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    w1 = await repo.create(
      const WirdDraft(
        name: 'الأول',
        type: WirdType.reading,
        dailyPages: 5,
        color: 0xFF1565C0,
      ),
    );
  });

  tearDown(() => db.close());

  for (final scope in ['wird', 'general']) {
    int? wirdId() => scope == 'wird' ? w1 : null;

    group('scope $scope', () {
      test('a page with a page bookmark and an ayah bookmark: the tap removes only the page bookmark', () async {
        final ayahId = await seedAyah(
          2,
          282,
          48,
          wirdId: wirdId(),
          note: 'أراجع هنا',
        );
        final pageId = await repo.addBookmark(48, 'صفحة', wirdId: wirdId());
        final ayahRow = (await all()).firstWhere((b) => b.id == ayahId);
        final pageRow = (await all()).firstWhere((b) => b.id == pageId);

        final toggle = await repo.toggleBookmark(48, wirdId: wirdId());
        expect(toggle.wasAdded, isFalse);
        expect(toggle.removed, [pageRow]);
        expect(await all(), [
          ayahRow,
        ], reason: 'the ayah bookmark and its note stay');

        await repo.undoBookmarkToggle(toggle);
        expect(await all(), [
          ayahRow,
          pageRow,
        ], reason: '«تراجع» brings back exactly the page bookmark');
      });

      test('a page with only an ayah bookmark: the tap adds a page bookmark and leaves the ayah one', () async {
        final ayahId = await seedAyah(2, 282, 48, wirdId: wirdId());
        final ayahRow = (await all()).single;

        final toggle = await repo.toggleBookmark(48, wirdId: wirdId());
        expect(toggle.wasAdded, isTrue);
        final rows = await all();
        expect(rows, hasLength(2));
        expect(rows.first, ayahRow);
        final added = rows.firstWhere((b) => b.id == toggle.addedId);
        expect(
          (added.page, added.wirdId, added.note, added.surah, added.ayah),
          (48, wirdId(), null, null, null),
        );

        await repo.undoBookmarkToggle(toggle);
        expect(await all(), [ayahRow]);
        expect(ayahId, ayahRow.id);
      });
    });
  }
}
