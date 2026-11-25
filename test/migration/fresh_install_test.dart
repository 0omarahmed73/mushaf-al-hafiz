// A new install gets the version-2 layout at once, and the checks of the two new bookmark columns hold (feature 013,
// spec FR-008, FR-013; data-model.md Bookmarks.surah, Bookmarks.ayah; research D1).
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/wirds/db.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> insert(String columns, String values) => db.customStatement(
    'INSERT INTO bookmarks (page, $columns) VALUES (48, $values)',
  );

  test('a fresh database is version 2 with the surah and ayah columns, both nullable', () async {
    final version = (await db.customSelect('PRAGMA user_version').getSingle())
        .data
        .values
        .first;
    expect(version, 2);
    final info = {
      for (final r
          in await db.customSelect('PRAGMA table_info(bookmarks)').get())
        r.data['name']: r.data,
    };
    expect(info['surah']?['notnull'], 0);
    expect(info['ayah']?['notnull'], 0);
    expect(info['surah']?['type'], 'INTEGER');
    expect(info['ayah']?['type'], 'INTEGER');
  });

  test('a page bookmark and an ayah bookmark insert', () async {
    await db.customStatement('INSERT INTO bookmarks (page) VALUES (48)');
    await insert('surah, ayah', '2, 282');
    await insert('surah, ayah', '1, 1');
    await insert('surah, ayah', '114, 6');
    await insert('surah, ayah', '2, 286');
    final rows = await db.select(db.bookmarks).get();
    expect(
      [for (final b in rows) (b.surah, b.ayah)],
      [(null, null), (2, 282), (1, 1), (114, 6), (2, 286)],
    );
  });

  test(
    'a surah alone, an ayah alone and numbers out of range are refused',
    () async {
      for (final (columns, values) in [
        ('surah', '2'),
        ('ayah', '282'),
        ('surah, ayah', '0, 1'),
        ('surah, ayah', '115, 1'),
        ('surah, ayah', '2, 0'),
        ('surah, ayah', '2, 287'),
      ]) {
        await expectLater(
          insert(columns, values),
          throwsA(anything),
          reason: '($columns) = ($values)',
        );
      }
      expect(await db.select(db.bookmarks).get(), isEmpty);
    },
  );

  test('an update that leaves one of the two alone is refused too', () async {
    await insert('surah, ayah', '2, 282');
    await expectLater(
      db.customStatement('UPDATE bookmarks SET ayah = NULL'),
      throwsA(anything),
    );
    await expectLater(
      db.customStatement('UPDATE bookmarks SET surah = NULL'),
      throwsA(anything),
    );
    await db.customStatement('UPDATE bookmarks SET surah = NULL, ayah = NULL');
    expect((await db.select(db.bookmarks).getSingle()).surah, isNull);
  });
}
