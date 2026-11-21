// The look in a backup (spec FR-016, SC-006; research D10): export holds `appLook`; importing a file with Night
// shows Night at once; a file without it or with a bad value is Emerald & Gold and the import still succeeds; an import
// that fails part way leaves the look as it was.
import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/backup/backup.dart';
import 'package:mushaf/backup/backup_service.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/look/look_settings.dart';
import 'package:mushaf/settings/settings_screen.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/fake_backup.dart';
import '../support/harness.dart' show settle;
import '../support/look_harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

/// A backup file of a database that has [look] stored (null: none) and a bookmark that tells it from the current one.
Future<String> backupWith(String? look) async {
  final db = AppDatabase(NativeDatabase.memory());
  final repo = WirdRepository(db);
  await repo.ensureDefaults();
  await repo.addBookmark(77, 'من الملف', wirdId: 1);
  if (look != null) await repo.setAppLook(look);
  final json = await BackupService(db).exportJson();
  await db.close();
  return json;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('the service', () {
    late AppDatabase db;
    late WirdRepository repo;
    late AppLookSettings look;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = WirdRepository(db);
      look = AppLookSettings(repo);
      await repo.ensureDefaults();
    });
    tearDown(() async {
      look.dispose();
      await db.close();
    });

    test('export holds the look as one setting', () async {
      await look.set(LookChoice.night);
      final map = jsonDecode(
        await BackupService(db).exportJson(),
      ) as Map<String, dynamic>;
      expect((map['settings'] as Map<String, dynamic>)['appLook'], 'night');
    });

    test(
      'importing a backup with Night brings Night back, and reload shows it',
      () async {
        final file = await backupWith('night');
        await look.load();
        expect(look.choice, LookChoice.emerald);
        await BackupService(db).importJson(file);
        await look.reload();
        expect(look.choice, LookChoice.night);
      },
    );

    test('a backup without the setting gives Emerald & Gold and still imports everything else', () async {
      await look.set(LookChoice.night);
      final file = await backupWith(null);
      await BackupService(db).importJson(file);
      await look.reload();
      expect(look.choice, LookChoice.emerald);
      expect(await repo.appLookRaw(), isNull);
      expect(
        (await repo.watchBookmarks().first).single.bookmark.note,
        'من الملف',
      );
    });

    test('a bad value gives Emerald & Gold with no error, and the text is left alone', () async {
      final file = await backupWith('purple');
      await BackupService(db).importJson(file);
      await look.reload();
      expect(look.choice, LookChoice.emerald);
      expect(await repo.appLookRaw(), 'purple');
    });

    test('an import that fails part way leaves the look as it was', () async {
      await look.set(LookChoice.night);
      final file = await backupWith('emerald');
      final failing = BackupService(
        db,
        debugHook: (stage) async {
          if (stage == 'wirds') throw StateError('the disk went away');
        },
      );
      await expectLater(failing.importJson(file), throwsStateError);
      await look.reload();
      expect(look.choice, LookChoice.night);
      expect(await repo.appLookRaw(), 'night');
    });
  });

  group('in the app', () {
    late FakeBackupFiles files;

    setUp(() => files = FakeBackupFiles());

    /// The reader stand-in with Settings on top of it, in [choice].
    Future<LookApp> openSettings(WidgetTester t, LookChoice choice) async {
      final a = await LookApp.create(t, choice: choice);
      await a.show(
        t,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open-settings'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<bool>(builder: (_) => const SettingsScreen()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
        backup: Backup(service: BackupService(a.db), files: files),
      );
      await t.tap(key('open-settings'));
      await settle(t);
      return a;
    }

    Future<void> importFile(WidgetTester t, String json) async {
      files.toPick = json;
      final f = key('backup-import');
      await t.ensureVisible(f);
      await t.pump();
      await t.tap(f);
      await settle(t);
      await t.tap(key('import-confirm'));
      await settle(t);
    }

    testWidgets('importing Night switches the whole app at once', (t) async {
      final a = await openSettings(t, LookChoice.emerald);
      expect(
        Theme.of(t.element(find.byType(SettingsScreen)))
            .scaffoldBackgroundColor,
        AppLook.emerald.background,
      );
      await importFile(
        t,
        await t.runAsync(() => backupWith('night')) as String,
      );
      expect(a.look.choice, LookChoice.night);
      expect(
        Theme.of(t.element(find.byType(Scaffold).first))
            .scaffoldBackgroundColor,
        AppLook.night.background,
      );
    });

    testWidgets(
      'importing an old backup, or one with a bad look, shows Emerald & Gold',
      (t) async {
        for (final look in [null, 'purple']) {
          final a = await openSettings(t, LookChoice.night);
          expect(a.look.choice, LookChoice.night);
          await importFile(
            t,
            await t.runAsync(() => backupWith(look)) as String,
          );
          expect(a.look.choice, LookChoice.emerald, reason: '$look');
          expect(
            Theme.of(t.element(find.byType(Scaffold).first))
                .scaffoldBackgroundColor,
            AppLook.emerald.background,
          );
          expect(find.text('تم استرجاع النسخة الاحتياطية'), findsNothing);
          await t.pumpWidget(const SizedBox());
        }
      },
    );
  });
}
