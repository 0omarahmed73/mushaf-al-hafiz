// The text size travels with the backup like every other setting, and a backup that does not have it, or has a
// value that makes no sense, never breaks the import (spec FR-013, FR-014; research D6).
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/backup/backup_service.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  late BackupService backup;
  late TextSizeSettings size;
  final now = DateTime(2026, 11, 20, 21, 4);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    backup = BackupService(db);
    size = TextSizeSettings(repo);
    await repo.ensureDefaults();
    await repo.addBookmark(77, 'ملاحظة');
  });
  tearDown(() async {
    size.dispose();
    await db.close();
  });

  Map<String, dynamic> decode(String json) =>
      jsonDecode(json) as Map<String, dynamic>;

  /// The file the backup holds, with the settings changed by [edit].
  Future<String> fileWith(
    void Function(Map<String, dynamic> settings) edit,
  ) async {
    final map = decode(await backup.exportJson(now: now));
    edit(map['settings'] as Map<String, dynamic>);
    return jsonEncode(map);
  }

  test('the export holds the chosen size as one more setting', () async {
    await size.set(130);
    final settings =
        decode(await backup.exportJson(now: now))['settings']
            as Map<String, dynamic>;
    expect(settings['textSizePercent'], '130');
  });

  test('an import restores the size and reload shows it', () async {
    await size.set(150);
    final file = await backup.exportJson(now: now);
    await size.set(90);
    expect(size.percent, 90);

    await backup.importJson(file);
    expect(
      size.percent,
      90,
      reason: 'the setting object only learns of it when it reloads',
    );
    final heard = <int>[];
    size.addListener(() => heard.add(size.percent));
    await size.reload();
    expect(size.percent, 150);
    expect(size.factor, 1.5);
    expect(heard, [150]);
  });

  test(
    'a backup without the key gives 100% and the import still succeeds',
    () async {
      await size.set(140);
      final file = await fileWith((s) => s.remove('textSizePercent'));
      await backup.importJson(file);
      await size.reload();
      expect(size.percent, 100);
      expect(size.isDefault, isTrue);
      expect(await repo.textSizeRaw(), isNull);
    },
  );

  for (final bad in ['abc', '999', '-5', '', '12.5']) {
    test(
      'a bad value "$bad" gives 100% and the import still succeeds',
      () async {
        await size.set(120);
        final file = await fileWith((s) => s['textSizePercent'] = bad);
        await backup.importJson(file);
        await size.reload();
        expect(size.percent, 100);
        expect(await repo.wirdById(1), isNotNull);
        expect(
          (await repo.watchBookmarks().first).single.bookmark.note,
          'ملاحظة',
        );
      },
    );
  }

  test(
    'nothing but the size changes: exporting again gives the same file',
    () async {
      await size.set(110);
      final first = await backup.exportJson(now: now);
      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      final copy = BackupService(other);
      await copy.importJson(first);
      final second = await copy.exportJson(now: now);
      expect(decode(second), decode(first));
      expect((decode(second)['settings'] as Map)['textSizePercent'], '110');
    },
  );
}
