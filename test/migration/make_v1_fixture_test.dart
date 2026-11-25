// Writes the REAL version-1 database file that the migration tests of feature 013 open (research D2, tasks.md T001).
//
// ONLY VALID AGAINST THE VERSION-1 LAYOUT. It was run once, on the code before feature 013 changed `lib/wirds/db.dart`,
// with
//
//   flutter test test/migration/make_v1_fixture_test.dart --dart-define=MAKE_DB_V1=true
//
// and its two output files (`fixtures/mushaf_v1.sqlite`, `fixtures/mushaf_v1_expected.json`) were committed with it.
// After the schema change this code would write a version-2 file, so it stays skipped and the committed files must never
// be regenerated (quickstart.md).
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show GeneratedDatabase, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/reminders/kahf_day.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

const bool _make = bool.fromEnvironment('MAKE_DB_V1');

/// The tables of the version-1 layout and the order their rows are dumped in.
const Map<String, String> kV1Tables = {
  'wirds': 'id',
  'wird_days': 'wird_id, day',
  'bookmarks': 'id',
  'settings': 'key',
};

/// The columns drift stores as unix seconds; the dump writes them as ISO times (UTC) as well.
const Set<String> kDateColumns = {'created_at', 'target_date'};

/// Every row of every table of [db] as text: a value is its text form (null stays null), a date column is the ISO time
/// in UTC. The migration test makes the same dump of the migrated file and compares the two.
Future<Map<String, List<Map<String, String?>>>> dumpRows(
  GeneratedDatabase db, {
  Iterable<String> tables = const [
    'wirds',
    'wird_days',
    'bookmarks',
    'settings',
  ],
  Set<String> skipColumns = const {},
}) async {
  final out = <String, List<Map<String, String?>>>{};
  for (final table in tables) {
    final rows = await db
        .customSelect('SELECT * FROM $table ORDER BY ${kV1Tables[table]}')
        .get();
    out[table] = [
      for (final r in rows)
        {
          for (final e in r.data.entries)
            if (!skipColumns.contains(e.key))
              e.key: e.value == null
                  ? null
                  : kDateColumns.contains(e.key)
                  ? DateTime.fromMillisecondsSinceEpoch(
                      (e.value as int) * 1000,
                      isUtc: true,
                    ).toIso8601String()
                  : '${e.value}',
        },
    ];
  }
  return out;
}

void main() {
  test(
    'writes the version-1 fixture from the unchanged code',
    () async {
      final dir = Directory('test/migration/fixtures')
        ..createSync(recursive: true);
      final file = File('${dir.path}/mushaf_v1.sqlite');
      if (file.existsSync()) file.deleteSync();
      final db = AppDatabase(NativeDatabase(file));
      final repo = WirdRepository(db);

      // 3 wirds: the default one and two more.
      await repo.ensureDefaults();
      final first = (await repo.activeWird())!.id;
      final hifz = await repo.create(
        WirdDraft(
          name: 'حفظ جزء عم',
          type: WirdType.hifz,
          startPage: 582,
          dailyPages: 1,
          notifyEnabled: true,
          notifyMinutes: 6 * 60 + 15,
          color: 0xFF6A1B9A,
        ),
      );
      final qiyam = await repo.create(
        WirdDraft(
          name: 'قيام الليل',
          type: WirdType.qiyam,
          startPage: 300,
          targetDate: DateTime(2027, 3, 1),
          color: 0xFF1565C0,
        ),
      );
      await repo.setPage(first, 213);

      // 12 portions: 4 days of each wird, some done.
      final wirdIds = [first, hifz, qiyam];
      for (final id in wirdIds) {
        for (var d = 0; d < 4; d++) {
          final day = DateTime(2026, 11, 20 + d, 12);
          await repo.today(id, day);
          if (d.isEven) await repo.markDone(id, day);
        }
      }

      // At least 50 bookmarks: general and of the 3 wirds, with and without notes, on pages 1 and 604, Arabic notes up to
      // 200 characters.
      final long = List.filled(30, 'أراجع هنا ').join().substring(0, 200);
      expect(long.length, 200);
      final notes = <String?>[
        null,
        'ملاحظة',
        'تثبيت الحفظ',
        null,
        long,
        'آية الكرسي',
      ];
      final owners = <int?>[null, first, hifz, qiyam];
      var n = 0;
      for (var i = 0; i < 56; i++) {
        final page = i == 0
            ? 1
            : i == 1
            ? 604
            : 1 + (i * 37) % 604;
        await repo.addBookmark(
          page,
          notes[i % notes.length],
          wirdId: owners[i % owners.length],
        );
        n++;
      }
      expect(n, greaterThanOrEqualTo(50));

      // Settings: the defaults' two and eight more.
      await repo.setTextSizePercent(120);
      await repo.setAppLook('night');
      await repo.setLastViewedPage(213);
      await repo.setKahf(enabled: false, minutes: 20 * 60 + 30);
      await repo.setKahfDay(KahfDay.friday);
      await repo.setTodayPanelExpanded(true);
      await repo.setNotificationPermissionAsked();
      await repo.writeSetting('tipsSeen', 'true');

      final rows = await dumpRows(db);
      final version = (await db.customSelect('PRAGMA user_version').getSingle())
          .data
          .values
          .first;
      final master = await db
          .customSelect(
            "SELECT name, sql FROM sqlite_master WHERE type = 'table' AND name = ?",
            variables: [Variable.withString('bookmarks')],
          )
          .getSingle();
      await db.close();

      expect(version, 1);
      expect(rows['wirds']!.length, 3);
      expect(rows['wird_days']!.length, 12);
      expect(rows['bookmarks']!.length, 56);
      expect(rows['settings']!.length, greaterThanOrEqualTo(8));

      File('${dir.path}/mushaf_v1_expected.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert({'userVersion': version, 'bookmarksSql': master.data['sql'], 'rows': rows})}\n',
      );
    },
    skip: _make
        ? false
        : 'only run on the version-1 code, with --dart-define=MAKE_DB_V1=true',
  );
}
