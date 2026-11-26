// The prayer settings travel in the backup (feature 014, FR-025, research D10): no new backup version; a backup from
// before 014 keeps the reader's current prayer settings.
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/backup/backup_service.dart';
import 'package:mushaf/prayer/prayer_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

const PrayerSettings _set = PrayerSettings(
  enabled: true,
  place: Place(
    lat: 30.063,
    lon: 31.25,
    zone: 'Africa/Cairo',
    name: 'القاهرة',
    source: PlaceSource.list,
    country: 'EG',
  ),
  method: 'egyptian',
  asr: AsrRule.hanafi,
  offsets: [0, 0, 1, 0, 2, 0],
);

Future<(AppDatabase, WirdRepository)> _open() async {
  final db = AppDatabase(NativeDatabase.memory());
  final repo = WirdRepository(db);
  await repo.ensureDefaults();
  return (db, repo);
}

void main() {
  test('a backup with prayer settings restores them, with the same backup version as before', () async {
    final (source, repo) = await _open();
    final plain = jsonDecode(
      await BackupService(source).exportJson(),
    )['version'];
    await repo.setPrayerSettings(_set);
    final json = await BackupService(source).exportJson();
    expect(jsonDecode(json)['version'], plain);
    await source.close();

    final (target, targetRepo) = await _open();
    await BackupService(target).importJson(json);
    expect(
      PrayerSettings.read(await targetRepo.prayerEntries(), phoneZone: 'UTC'),
      _set,
    );
    await target.close();
  });

  test(
    'restoring a backup from before 014 keeps the current prayer settings',
    () async {
      final (source, _) = await _open();
      final old = await BackupService(source).exportJson();
      await source.close();
      expect(old.contains('prayer.'), isFalse);

      final (target, targetRepo) = await _open();
      await targetRepo.setPrayerSettings(_set);
      await BackupService(target).importJson(old);
      expect(
        PrayerSettings.read(await targetRepo.prayerEntries(), phoneZone: 'UTC'),
        _set,
      );
      await target.close();
    },
  );
}
