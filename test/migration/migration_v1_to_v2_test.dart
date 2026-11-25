// The first change of the database layout (feature 013, schema 1 to 2; spec FR-013, SC-003; research D1, D2), proved on
// the REAL version-1 file that the unchanged code wrote (fixtures/mushaf_v1.sqlite, task T001). The committed fixture is
// never opened in place: every test copies it to a temporary file first.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/wirds/db.dart';

import 'make_v1_fixture_test.dart' show dumpRows;

const String _fixture = 'test/migration/fixtures/mushaf_v1.sqlite';

Map<String, dynamic> get _expected => jsonDecode(
  File('test/migration/fixtures/mushaf_v1_expected.json').readAsStringSync(),
) as Map<String, dynamic>;

/// A fresh copy of the version-1 fixture in a temporary folder.
File copyFixture() {
  final dir = Directory.systemTemp.createTempSync('mushaf_v1_');
  addTearDown(() => dir.deleteSync(recursive: true));
  return File(_fixture).copySync('${dir.path}/mushaf.sqlite');
}

/// Opens [file] with nothing but sqlite at [version], without drift's migration, to prepare or inspect a file.
class _RawUser extends QueryExecutorUser {
  _RawUser(this.schemaVersion);

  @override
  final int schemaVersion;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

Future<T> withRaw<T>(
  File file,
  Future<T> Function(QueryExecutor e) body, {
  int version = 1,
}) async {
  final e = NativeDatabase(file);
  await e.ensureOpen(_RawUser(version));
  try {
    return await body(e);
  } finally {
    await e.close();
  }
}

Future<int> userVersion(GeneratedDatabase db) async =>
    (await db.customSelect('PRAGMA user_version').getSingle()).data.values.first
        as int;

Future<List<Map<String, Object?>>> tableInfo(
  GeneratedDatabase db,
  String table,
) async => [
  for (final r in await db.customSelect('PRAGMA table_info($table)').get())
    r.data,
];

/// The CREATE statements of the tables, with whitespace and quoting normalised, so the migrated file and a fresh
/// install can be compared.
Future<Map<String, String>> schemaSql(GeneratedDatabase db) async {
  String normal(String sql) => sql
      .replaceAll('"', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'\s*([(),])\s*'), r'$1')
      .trim();
  return {
    for (final r
        in await db
            .customSelect(
              "SELECT name, sql FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
            )
            .get())
      r.data['name'] as String: normal(r.data['sql'] as String),
  };
}

/// Every row of the four tables equals the fixture's expected rows, and every old bookmark is a page bookmark.
Future<void> expectAllRowsKept(AppDatabase db) async {
  final rows = await dumpRows(db, skipColumns: const {'surah', 'ayah'});
  final expected = (_expected['rows'] as Map<String, dynamic>);
  for (final table in ['wirds', 'wird_days', 'bookmarks', 'settings']) {
    final want = [
      for (final r in expected[table] as List<dynamic>)
        (r as Map<String, dynamic>).cast<String, String?>(),
    ];
    expect(rows[table], want, reason: 'the rows of $table');
  }
  final marks = await db.select(db.bookmarks).get();
  expect(marks, hasLength(56));
  expect(marks.where((b) => b.surah != null || b.ayah != null), isEmpty);
}

void main() {
  test('the fixture is a real version-1 file', () async {
    expect(_expected['userVersion'], 1);
    final version = await withRaw(
      copyFixture(),
      (e) async => (await e.runSelect(
        'PRAGMA user_version',
        const [],
      )).single.values.first,
    );
    expect(version, 1);
  });

  test('every row of every table is kept, the new fields of old bookmarks are empty, version 2', () async {
    final db = AppDatabase(NativeDatabase(copyFixture()));
    addTearDown(db.close);
    await expectAllRowsKept(db);
    expect(await userVersion(db), 2);
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });

  test('the migrated layout equals a fresh install', () async {
    final migrated = AppDatabase(NativeDatabase(copyFixture()));
    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(migrated.close);
    addTearDown(fresh.close);
    expect(
      await tableInfo(migrated, 'bookmarks'),
      await tableInfo(fresh, 'bookmarks'),
    );
    final names = [
      for (final c in await tableInfo(migrated, 'bookmarks')) c['name'],
    ];
    expect(names, [
      'id',
      'wird_id',
      'page',
      'note',
      'created_at',
      'surah',
      'ayah',
    ]);
    expect(await schemaSql(migrated), await schemaSql(fresh));
  });

  test('a migration stopped after its first step leaves the data intact and finishes on the next start', () async {
    final file = copyFixture();
    final broken = AppDatabase(
      NativeDatabase(file),
      migrationDebugHook: (step) async {
        if (step == 'surah') throw StateError('killed after step $step');
      },
    );
    await expectLater(broken.customSelect('SELECT 1').get(), throwsA(anything));
    await broken.close();
    // Nothing of the stopped run is left: still version 1, no new column.
    final left = await withRaw(file, (e) async {
      final v = (await e.runSelect(
        'PRAGMA user_version',
        const [],
      )).single.values.first;
      final cols = [
        for (final r in await e.runSelect(
          'PRAGMA table_info(bookmarks)',
          const [],
        ))
          r['name'],
      ];
      return (v, cols);
    });
    expect(left.$1, 1);
    expect(left.$2, isNot(contains('surah')));

    final again = AppDatabase(NativeDatabase(file));
    addTearDown(again.close);
    await expectAllRowsKept(again);
    expect(await userVersion(again), 2);
  });

  test('a file that already has both columns but says version 1 opens without error', () async {
    final file = copyFixture();
    await withRaw(file, (e) async {
      await e.runCustom('ALTER TABLE bookmarks ADD COLUMN surah INTEGER NULL');
      await e.runCustom('ALTER TABLE bookmarks ADD COLUMN ayah INTEGER NULL');
    });
    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    await expectAllRowsKept(db);
    expect(await userVersion(db), 2);
  });

  test('5 000 bookmarks migrate in under 1 s', () async {
    final file = copyFixture();
    await withRaw(file, (e) async {
      await e.runCustom('BEGIN');
      for (var i = 0; i < 5000; i++) {
        await e.runInsert(
          'INSERT INTO bookmarks (wird_id, page, note, created_at) VALUES (?, ?, ?, ?)',
          [
            i % 3 == 0 ? null : 1 + i % 3,
            1 + i % 604,
            i.isEven ? 'ملاحظة $i' : null,
            1764000000 + i,
          ],
        );
      }
      await e.runCustom('COMMIT');
    });
    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final watch = Stopwatch()..start();
    expect(await userVersion(db), 2);
    watch.stop();
    expect(await db.select(db.bookmarks).get(), hasLength(5056));
    expect(
      watch.elapsedMilliseconds,
      lessThan(1000),
      reason: 'opening and migrating took ${watch.elapsedMilliseconds} ms',
    );
  });
}
