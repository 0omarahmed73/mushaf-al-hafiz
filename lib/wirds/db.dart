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

/// A page bookmark; `wirdId == null` is a general bookmark («عامة»).
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
  AppDatabase(super.e);

  /// The on-device database used by the app.
  AppDatabase.open() : super(driftDatabase(name: 'mushaf'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
