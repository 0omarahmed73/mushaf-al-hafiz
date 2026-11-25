// Drift's `check(column...)` refers to the column being declared, which trips this lint.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'wird_type.dart';

export 'wird_type.dart';

part 'db.g.dart';

/// A named wird with its own position, goal and reminder.
class Wirds extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => textEnum<WirdType>()();

  /// 1..604, default 1.
  IntColumn get currentPage => integer()
      .withDefault(const Constant(1))
      .check(currentPage.isBetweenValues(1, 604))();

  /// >= 1 when set; wins over [targetDate].
  IntColumn get dailyPages => integer().nullable().check(
    dailyPages.isNull() | dailyPages.isBiggerOrEqualValue(1),
  )();

  /// Date only (stored at local midnight).
  DateTimeColumn get targetDate => dateTime().nullable()();
  IntColumn get khatmaCount => integer().withDefault(const Constant(0))();
  BoolColumn get notifyEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Minutes after local midnight.
  IntColumn get notifyMinutes => integer().nullable()();
  IntColumn get color => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// A wird's portion for one wird day (`yyyy-MM-dd`): one row per wird per day.
class WirdDays extends Table {
  IntColumn get wirdId =>
      integer().references(Wirds, #id, onDelete: KeyAction.cascade)();
  TextColumn get day => text()();
  IntColumn get startPage => integer()();
  IntColumn get endPage => integer()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {wirdId, day};
}

/// A bookmark; `wirdId == null` is a general bookmark («عامة»). With [surah] and [ayah] it is an ayah bookmark (feature
/// 013) whose [page] is the page where that ayah begins; without them (every row made before schema 2) a page bookmark.
class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wirdId => integer().nullable().references(
    Wirds,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get page => integer().check(page.isBetweenValues(1, 604))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// The ayah's surah, 1..114; null on a page bookmark (schema 2, data-model.md).
  IntColumn get surah => integer().nullable().check(
    surah.isNull() | surah.isBetweenValues(1, 114),
  )();

  /// The ayah's number, both or neither with [surah]. The cross-column rule lives here, on the column added second,
  /// because SQLite refuses a CHECK that names a column that does not exist yet (research D1). 286 is the longest
  /// surah; that the ayah exists in its surah is checked where rows are made and on import.
  IntColumn get ayah => integer().nullable().check(
    ayah.isNull().equalsExp(surah.isNull()) &
        (ayah.isNull() | ayah.isBetweenValues(1, 286)),
  )();
}

/// Key/value settings: activeWirdId, lastViewedPage, kahfEnabled, kahfDay (thursday or friday), kahfMinutes (only
/// when the user chose an hour), todayPanelExpanded, defaultsCreated.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Wirds, WirdDays, Bookmarks, Settings])
class AppDatabase extends _$AppDatabase {
  /// [migrationDebugHook] is for tests only: it is called with 'surah' after the first step of the migration to schema 2
  /// and with 'ayah' after the second, so a test can stop the migration halfway (like `BackupService.debugHook`).
  AppDatabase(super.e, {this.migrationDebugHook});

  /// The on-device database used by the app.
  AppDatabase.open()
    : migrationDebugHook = null,
      super(driftDatabase(name: 'mushaf'));

  final Future<void> Function(String step)? migrationDebugHook;

  @override
  int get schemaVersion => 2;

  /// The names of the columns [table] really has.
  Future<Set<String>> _columnsOf(String table) async => {
    for (final r in await customSelect('PRAGMA table_info($table)').get())
      r.data['name'] as String,
  };

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // A new install gets schema 2 at once (the same DDL as the migration: test/migration).
    onCreate: (m) => m.createAll(),
    // 1 to 2 (feature 013, research D2): two nullable columns on bookmarks, in one transaction, each step guarded by the
    // columns the table really has, so a run that was stopped halfway is finished by the next start and never fails with
    // "duplicate column". No row is read, written or deleted; drift sets user_version only after this returns.
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await transaction(() async {
          if (!(await _columnsOf('bookmarks')).contains('surah')) {
            await m.addColumn(bookmarks, bookmarks.surah);
          }
          await migrationDebugHook?.call('surah');
          if (!(await _columnsOf('bookmarks')).contains('ayah')) {
            await m.addColumn(bookmarks, bookmarks.ayah);
          }
          await migrationDebugHook?.call('ayah');
        });
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
