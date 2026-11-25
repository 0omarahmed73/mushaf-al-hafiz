import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/backup/backup_service.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

/// Every user row, as plain data, to compare before and after.
Future<Map<String, Object?>> snapshot(AppDatabase db) async {
  final wirds = await db.select(db.wirds).get();
  final days = await db.select(db.wirdDays).get();
  final marks = await db.select(db.bookmarks).get();
  final settings = await db.select(db.settings).get();
  return {
    'wirds': [
      for (final w in wirds)
        [w.id, w.name, w.type.name, w.currentPage, w.dailyPages, w.targetDate?.toString(), w.khatmaCount,
         w.notifyEnabled, w.notifyMinutes, w.color, w.sortOrder, w.createdAt.millisecondsSinceEpoch],
    ],
    'days': [for (final d in days) [d.wirdId, d.day, d.startPage, d.endPage, d.done]],
    'marks': [for (final b in marks) [b.id, b.wirdId, b.page, b.note, b.createdAt.millisecondsSinceEpoch]],
    'settings': {for (final s in settings) s.key: s.value},
  };
}

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  late BackupService backup;
  final now = DateTime(2026, 11, 20, 21, 4);

  /// A database with a bit of everything.
  Future<void> fill(AppDatabase target) async {
    final r = WirdRepository(target);
    await r.ensureDefaults();
    final q = await r.create(WirdDraft(
      name: 'قيام الليل',
      type: WirdType.qiyam,
      startPage: 100,
      dailyPages: 2,
      targetDate: DateTime(2027, 1, 15),
      notifyEnabled: true,
      notifyMinutes: 22 * 60 + 30,
      color: 0xFF1565C0,
    ));
    await r.setPage(1, 213);
    await r.today(1, now);
    await r.markDone(1, now);
    await r.today(q, now);
    await r.addBookmark(77, 'ملاحظة', wirdId: 1);
    await r.addBookmark(293, null);
    await r.setKahf(enabled: false, minutes: 20 * 60);
    await r.setTodayPanelExpanded(true);
    await r.setLastViewedPage(213);
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    backup = BackupService(db);
  });
  tearDown(() => db.close());

  group('export', () {
    test('writes the documented shape with every row and setting', () async {
      await fill(db);
      final map = jsonDecode(await backup.exportJson(now: now)) as Map<String, dynamic>;
      expect(map['app'], 'mushaf-hafiz');
      expect(map['version'], 1);
      expect(map['exportedAt'], startsWith('2026-11-20T21:04:00'));
      expect((map['wirds'] as List).length, 2);
      expect((map['wirdDays'] as List).length, 2);
      expect((map['bookmarks'] as List).length, 2);
      final settings = map['settings'] as Map<String, dynamic>;
      expect(settings['kahfEnabled'], 'false');
      expect(settings['kahfMinutes'], '${20 * 60}');
      expect(settings['todayPanelExpanded'], 'true');
      final first = (map['wirds'] as List).first as Map<String, dynamic>;
      expect(first['type'], 'reading');
      expect(first['currentPage'], 233, reason: 'the portion was 213–232 and «تم» moved it past it');
      final second = (map['wirds'] as List).last as Map<String, dynamic>;
      expect(second['targetDate'], '2027-01-15', reason: 'a date only, as the contract says');
    });

    test('the file is named mushaf-backup-YYYY-MM-DD.json', () {
      expect(backupFileName(DateTime(2026, 11, 20, 23, 59)), 'mushaf-backup-2026-11-20.json');
      expect(backupFileName(DateTime(2027, 1, 5)), 'mushaf-backup-2027-01-05.json');
    });
  });

  group('round trip', () {
    test('export then import into another database restores identical wirds, days, bookmarks and settings', () async {
      await fill(db);
      final file = await backup.exportJson(now: now);
      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      await BackupService(other).importJson(file);
      expect(await snapshot(other), await snapshot(db));
    });

    test('importing over changed data brings back exactly what was exported', () async {
      await fill(db);
      final before = await snapshot(db);
      final file = await backup.exportJson(now: now);
      await repo.delete(1);
      await repo.addBookmark(5, 'new');
      await repo.setPage(2, 400);
      await repo.setKahf(enabled: true, minutes: 9 * 60);
      expect(await snapshot(db), isNot(before));
      await backup.importJson(file);
      expect(await snapshot(db), before);
    });

    test('a restored database keeps working: new rows get fresh ids and the reminder inputs read', () async {
      await fill(db);
      final file = await backup.exportJson(now: now);
      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      await BackupService(other).importJson(file);
      final r = WirdRepository(other);
      final id = await r.create(const WirdDraft(name: 'جديد', type: WirdType.reading, color: 0xFF2E7D32));
      expect(id, greaterThan(2));
      expect((await r.activeWird())!.id, 1);
      expect(await r.bookmarkCount(1), 1);
    });

    test('an empty app round-trips too', () async {
      final file = await backup.exportJson(now: now);
      await repo.create(const WirdDraft(name: 'x', type: WirdType.reading, color: 0xFF2E7D32));
      await backup.importJson(file);
      expect(await snapshot(db), await snapshot(AppDatabase(NativeDatabase.memory())));
    });
  });

  group('a bad file is refused and changes nothing', () {
    late String good;
    late Map<String, Object?> before;

    setUp(() async {
      await fill(db);
      good = await backup.exportJson(now: now);
      before = await snapshot(db);
    });

    Future<void> expectRefused(String file, BackupProblem problem) async {
      await expectLater(
        backup.importJson(file),
        throwsA(isA<BackupFormatException>().having((e) => e.problem, 'problem', problem)),
      );
      expect(await snapshot(db), before, reason: 'nothing changed');
    }

    Map<String, dynamic> edited(void Function(Map<String, dynamic>) change) {
      final m = jsonDecode(good) as Map<String, dynamic>;
      change(m);
      return m;
    }

    test('version 2 is a newer backup', () async {
      await expectRefused(jsonEncode(edited((m) => m['version'] = 3)), BackupProblem.newerVersion);
    });

    test('another app\'s file', () async {
      await expectRefused(jsonEncode(edited((m) => m['app'] = 'other-app')), BackupProblem.notABackup);
      await expectRefused(jsonEncode([1, 2, 3]), BackupProblem.notABackup);
    });

    test('malformed JSON and a missing or odd version', () async {
      await expectRefused('{not json', BackupProblem.invalid);
      await expectRefused('', BackupProblem.invalid);
      await expectRefused(jsonEncode(edited((m) => m.remove('version'))), BackupProblem.invalid);
      await expectRefused(jsonEncode(edited((m) => m['version'] = 0)), BackupProblem.invalid);
      await expectRefused(jsonEncode(edited((m) => m['version'] = '1')), BackupProblem.invalid);
    });

    test('a page outside 1–604', () async {
      await expectRefused(jsonEncode(edited((m) => (m['wirds'] as List).first['currentPage'] = 605)), BackupProblem.invalid);
      await expectRefused(jsonEncode(edited((m) => (m['bookmarks'] as List).first['page'] = 0)), BackupProblem.invalid);
      await expectRefused(jsonEncode(edited((m) => (m['wirdDays'] as List).first['endPage'] = 700)), BackupProblem.invalid);
    });

    test('rows that do not fit together', () async {
      await expectRefused(jsonEncode(edited((m) => (m['wirds'] as List).first['type'] = 'dancing')), BackupProblem.invalid);
      await expectRefused(jsonEncode(edited((m) => (m['wirds'] as List).first['name'] = '  ')), BackupProblem.invalid);
      await expectRefused(jsonEncode(edited((m) => (m['wirdDays'] as List).first['wirdId'] = 99)), BackupProblem.invalid);
      await expectRefused(jsonEncode(edited((m) => (m['bookmarks'] as List).first['wirdId'] = 99)), BackupProblem.invalid);
      await expectRefused(jsonEncode(edited((m) => (m['wirds'] as List).last['id'] = 1)), BackupProblem.invalid);
      await expectRefused(jsonEncode(edited((m) => m['settings'] = ['x'])), BackupProblem.invalid);
      await expectRefused(jsonEncode(edited((m) => (m['settings'] as Map)['activeWirdId'] = '99')), BackupProblem.invalid);
      await expectRefused(jsonEncode(edited((m) => (m['wirds'] as List).first['notifyMinutes'] = 1440)), BackupProblem.invalid);
      await expectRefused(jsonEncode(edited((m) => m.remove('wirds'))), BackupProblem.invalid);
    });

    test('a failure in the middle of the import rolls back: the data is the old data, never a mix', () async {
      for (final stage in ['cleared', 'wirds', 'wirdDays', 'bookmarks']) {
        final failing = BackupService(db, debugHook: (s) async {
          if (s == stage) throw StateError('disk full at $stage');
        });
        await expectLater(failing.importJson(good), throwsStateError);
        expect(await snapshot(db), before, reason: 'rolled back after $stage');
      }
    });
  });
}
