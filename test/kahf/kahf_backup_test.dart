import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/backup/backup_service.dart';
import 'package:mushaf/reminders/kahf_day.dart';
import 'package:mushaf/reminders/reminder_planner.dart';
import 'package:mushaf/reminders/reminder_scheduler.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  late BackupService backup;
  final now = DateTime(2026, 11, 20, 10, 0); // a Friday

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    backup = BackupService(db);
    await repo.ensureDefaults();
  });
  tearDown(() => db.close());

  /// An empty database (no defaults) with its repository and backup service.
  Future<(AppDatabase, WirdRepository, BackupService)> another() async {
    final other = AppDatabase(NativeDatabase.memory());
    addTearDown(other.close);
    return (other, WirdRepository(other), BackupService(other));
  }

  Map<String, dynamic> settingsOf(String file) =>
      (jsonDecode(file) as Map<String, dynamic>)['settings']
          as Map<String, dynamic>;

  /// [file] with the `kahfDay` setting removed, as a backup written before this feature.
  String withoutDay(String file) {
    final map = jsonDecode(file) as Map<String, dynamic>;
    (map['settings'] as Map<String, dynamic>).remove('kahfDay');
    return jsonEncode(map);
  }

  /// [file] with the `kahfDay` setting set to [value].
  String withDay(String file, String value) {
    final map = jsonDecode(file) as Map<String, dynamic>;
    (map['settings'] as Map<String, dynamic>)['kahfDay'] = value;
    return jsonEncode(map);
  }

  test('export carries Friday and import into an empty database restores it, with a plan of Fridays', () async {
    await repo.setKahfDay(KahfDay.friday);
    final file = await backup.exportJson(now: now);
    expect(settingsOf(file)['kahfDay'], 'friday');

    final (other, otherRepo, otherBackup) = await another();
    await otherBackup.importJson(file);
    expect(await otherRepo.kahfDay(), KahfDay.friday);
    expect(await other.select(other.settings).get(), isNotEmpty);
    final plan = await buildReminderPlan(otherRepo, now);
    final kahf = plan.where((r) => r.isKahf).toList();
    expect(kahf, isNotEmpty);
    expect(kahf.every((r) => r.at.weekday == DateTime.friday), isTrue);
  });

  test(
    'a day that was never set is not written, and imports as Thursday',
    () async {
      final file = await backup.exportJson(now: now);
      expect(settingsOf(file).containsKey('kahfDay'), isFalse);

      final (_, otherRepo, otherBackup) = await another();
      await otherBackup.importJson(file);
      expect(await otherRepo.kahfDay(), KahfDay.thursday);
    },
  );

  test('Thursday chosen on purpose is carried as thursday', () async {
    await repo.setKahfDay(KahfDay.thursday);
    final file = await backup.exportJson(now: now);
    expect(settingsOf(file)['kahfDay'], 'thursday');
    final (_, otherRepo, otherBackup) = await another();
    await otherBackup.importJson(file);
    expect(await otherRepo.kahfDay(), KahfDay.thursday);
  });

  test('a backup written before the feature (no kahfDay) is accepted and gives Thursday, also over a Friday', () async {
    await repo.setKahf(enabled: true, minutes: 8 * 60);
    final old = withoutDay(await backup.exportJson(now: now));
    expect(settingsOf(old).containsKey('kahfDay'), isFalse);

    backup.check(old); // must not throw
    await repo.setKahfDay(KahfDay.friday);
    await backup.importJson(old);
    expect(
      await repo.kahfDay(),
      KahfDay.thursday,
      reason: 'the settings table is replaced',
    );
    expect(await repo.kahfMinutes(), 8 * 60);
  });

  test(
    'a day the app does not know is accepted and reads as Thursday',
    () async {
      final file = withDay(await backup.exportJson(now: now), 'monday');
      backup.check(file);
      await repo.setKahfDay(KahfDay.friday);
      await backup.importJson(file);
      expect(await repo.kahfDay(), KahfDay.thursday);
      expect(
        await repo.readSetting('kahfDay'),
        'monday',
        reason: 'restored as written, read leniently',
      );
    },
  );

  test('the file format version is still 1', () async {
    await repo.setKahfDay(KahfDay.friday);
    final map =
        jsonDecode(await backup.exportJson(now: now)) as Map<String, dynamic>;
    expect(map['version'], 1);
    expect(kBackupVersion, 1);
  });

  test('the plan after an import follows the restored day', () async {
    await repo.setKahfDay(KahfDay.friday);
    final friday = await backup.exportJson(now: now);
    await repo.setKahfDay(KahfDay.thursday);
    await backup.importJson(friday);
    final kahf = (await buildReminderPlan(repo, now)).where((r) => r.isKahf);
    expect(kahf.map((r) => r.at.weekday).toSet(), {DateTime.friday});
    expect(kahf.every((r) => r.id >= kKahfIdBase), isTrue);
  });
}
