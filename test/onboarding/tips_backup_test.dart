// The tips flag and the backup (feature 008, spec FR-008, SC-005, research D5): it travels like every other setting, an
// old file without it still imports, and importing a file never makes this phone forget that it has seen the tips.
import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/backup/backup_service.dart';
import 'package:mushaf/onboarding/tips_store.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

/// One phone: a database, its repository and its tips store.
class _Phone {
  _Phone() : db = AppDatabase(NativeDatabase.memory()) {
    repo = WirdRepository(db);
    tips = TipsStore(repo);
  }

  final AppDatabase db;
  late final WirdRepository repo;
  late final TipsStore tips;

  BackupService get backup => BackupService(db);

  Future<Map<String, String>> settings() async => {
    for (final s in await db.select(db.settings).get()) s.key: s.value,
  };

  Future<void> close() => db.close();
}

Map<String, dynamic> settingsOf(String file) =>
    ((jsonDecode(file) as Map<String, dynamic>)['settings'])
        as Map<String, dynamic>;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late _Phone phone;

  setUp(() async {
    phone = _Phone();
    await phone.repo.ensureDefaults();
    await phone.repo.setAppLook('night');
  });
  tearDown(() => phone.close());

  /// A file written by a phone that has [seen] the tips (or has not).
  Future<String> fileFrom({required bool seen}) async {
    final source = _Phone();
    await source.repo.ensureDefaults();
    await source.repo.addBookmark(77, 'من الملف', wirdId: 1);
    if (seen) await source.tips.markSeen();
    final text = await source.backup.exportJson();
    await source.close();
    return text;
  }

  /// A file of the format before this feature: the same file with no `tipsSeen` key.
  String withoutTipsKey(String file) {
    final map = jsonDecode(file) as Map<String, dynamic>;
    (map['settings'] as Map<String, dynamic>).remove(kTipsSeenKey);
    return jsonEncode(map);
  }

  test(
    'the set of settings that stay with the phone is exactly the tips flag',
    () {
      expect(kKeptOnImport, {kTipsSeenKey});
      expect(kKeptOnImport, {'tipsSeen'});
    },
  );

  group('the export', () {
    test(
      'a phone that has seen the tips writes the flag with the other settings',
      () async {
        await phone.tips.markSeen();
        final file = await phone.backup.exportJson();
        expect(settingsOf(file)['tipsSeen'], 'true');
        expect(settingsOf(file)['appLook'], 'night');
      },
    );

    test('a phone that has not seen them writes no flag', () async {
      final file = await phone.backup.exportJson();
      expect(settingsOf(file).containsKey('tipsSeen'), isFalse);
    });
  });

  group('a new phone', () {
    test('restoring a backup of a phone that finished the tips brings the flag: they do not show again', () async {
      final file = await fileFrom(seen: true);
      final fresh = _Phone();
      addTearDown(fresh.close);
      expect(await fresh.tips.seen(), isFalse);
      await fresh.backup.importJson(file);
      expect(await fresh.tips.seen(), isTrue);
    });

    test('restoring a backup of a phone that never saw them leaves them to be shown', () async {
      final file = await fileFrom(seen: false);
      final fresh = _Phone();
      addTearDown(fresh.close);
      await fresh.backup.importJson(file);
      expect(await fresh.tips.seen(), isFalse);
    });
  });

  group('an old file, written before this feature', () {
    test('still parses and imports everything else', () async {
      final old = withoutTipsKey(await fileFrom(seen: true));
      expect(() => phone.backup.check(old), returnsNormally);
      await phone.backup.importJson(old);
      final marks = await phone.repo.bookmarkRows();
      expect(marks.map((b) => b.page), contains(77));
    });

    test(
      'importing it on a phone that has seen the tips keeps the flag',
      () async {
        await phone.tips.markSeen();
        final old = withoutTipsKey(await fileFrom(seen: false));
        await phone.backup.importJson(old);
        expect(await phone.tips.seen(), isTrue);
        expect((await phone.settings())['tipsSeen'], 'true');
      },
    );

    test(
      'importing it on a phone that has not seen them leaves it unseen',
      () async {
        final old = withoutTipsKey(await fileFrom(seen: false));
        await phone.backup.importJson(old);
        expect(await phone.tips.seen(), isFalse);
        expect((await phone.settings()).containsKey('tipsSeen'), isFalse);
      },
    );
  });

  group('the file wins when it has the flag', () {
    test(
      'a file with "true" makes a phone that had not seen them seen',
      () async {
        final file = await fileFrom(seen: true);
        expect(await phone.tips.seen(), isFalse);
        await phone.backup.importJson(file);
        expect(await phone.tips.seen(), isTrue);
      },
    );

    test(
      'a file with "true" on a phone that had seen them stays seen, once',
      () async {
        await phone.tips.markSeen();
        await phone.backup.importJson(await fileFrom(seen: true));
        expect(await phone.tips.seen(), isTrue);
        final rows = (await phone.db.select(phone.db.settings).get()).where(
          (s) => s.key == 'tipsSeen',
        );
        expect(rows, hasLength(1));
      },
    );
  });

  group('the other settings are still replaced', () {
    test('a setting that is not in the file is gone, as before', () async {
      await phone.tips.markSeen();
      await phone.repo.setTextSizePercent(150);
      final file = withoutTipsKey(await fileFrom(seen: false));
      await phone.backup.importJson(file);
      final settings = await phone.settings();
      expect(
        settings.containsKey('textSizePercent'),
        isFalse,
        reason: 'replaced by the file',
      );
      expect(
        settings.containsKey('appLook'),
        isFalse,
        reason: 'the file has none',
      );
      expect(settings['tipsSeen'], 'true', reason: 'only this one stays');
    });
  });

  group('a failed import', () {
    test(
      'leaves the flag, the wirds and the bookmarks exactly as they were',
      () async {
        await phone.tips.markSeen();
        await phone.repo.addBookmark(5, 'قبل');
        final before = (
          await phone.settings(),
          (await phone.repo.bookmarkRows()).map((b) => b.page).toList(),
        );
        final file = withoutTipsKey(await fileFrom(seen: false));
        for (final stage in ['cleared', 'wirds', 'wirdDays', 'bookmarks']) {
          final failing = BackupService(
            phone.db,
            debugHook: (s) async {
              if (s == stage) throw StateError('disk full at $stage');
            },
          );
          await expectLater(failing.importJson(file), throwsStateError);
          final after = (
            await phone.settings(),
            (await phone.repo.bookmarkRows()).map((b) => b.page).toList(),
          );
          expect(after.$1, before.$1, reason: 'rolled back after $stage');
          expect(after.$2, before.$2, reason: 'rolled back after $stage');
          expect(await phone.tips.seen(), isTrue);
        }
      },
    );

    test('a refused file changes nothing, flag included', () async {
      await phone.tips.markSeen();
      await expectLater(
        () => phone.backup.importJson('{"app":"another-app"}'),
        throwsA(isA<BackupFormatException>()),
      );
      expect(await phone.tips.seen(), isTrue);
    });
  });
}
