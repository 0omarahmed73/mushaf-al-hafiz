// The four large-ayah keys travel in the backup file with no format change (feature 015, FR-006, research D8): the backup
// writes and restores every key of the settings table.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/backup/backup_service.dart';
import 'package:mushaf/large_ayah/large_ayah_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

void main() {
  test('export, wipe and import bring the four values back', () async {
    final source = AppDatabase(NativeDatabase.memory());
    final repo = WirdRepository(source);
    await repo.ensureDefaults();
    final settings = LargeAyahSettings(repo);
    await settings.setOn(true);
    await settings.setCount(3);
    await settings.setSizeStep(2);
    await settings.setAt(const AyahRef(2, 255));
    final json = await BackupService(source).exportJson();
    await source.close();

    final target = AppDatabase(NativeDatabase.memory());
    final targetRepo = WirdRepository(target);
    await targetRepo.ensureDefaults();
    await BackupService(target).importJson(json);
    final restored = LargeAyahSettings(targetRepo);
    await restored.load();
    expect(restored.on, isTrue);
    expect(restored.count, 3);
    expect(restored.sizeStep, 2);
    expect(restored.at, const AyahRef(2, 255));
    restored.dispose();
    settings.dispose();
    await target.close();
  });

  test('a backup without the keys restores the defaults', () async {
    final source = AppDatabase(NativeDatabase.memory());
    await WirdRepository(source).ensureDefaults();
    final json = await BackupService(source).exportJson();
    await source.close();

    final target = AppDatabase(NativeDatabase.memory());
    final targetRepo = WirdRepository(target);
    await targetRepo.ensureDefaults();
    final before = LargeAyahSettings(targetRepo);
    await before.setOn(true);
    await before.setCount(2);
    await BackupService(target).importJson(json);
    final restored = LargeAyahSettings(targetRepo);
    await restored.load();
    expect(restored.on, isFalse);
    expect(restored.count, 1);
    expect(restored.sizeStep, 1);
    expect(restored.at, isNull);
    before.dispose();
    restored.dispose();
    await target.close();
  });
}
