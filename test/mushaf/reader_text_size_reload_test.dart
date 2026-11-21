// A restored backup brings its text size back to the reader at once, without a restart (spec FR-013, FR-014).
import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/backup/backup.dart';
import 'package:mushaf/backup/backup_service.dart';
import 'package:mushaf/mushaf/mushaf_page_card.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/settings/settings_screen.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/fake_backup.dart';
import '../support/reader_harness.dart' show settleReader;

Finder key(String k) => find.byKey(ValueKey(k));

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  /// The reader with a backup service, a text size setting at [percent] and the page on page 50.
  Future<({TextSizeSettings size, FakeBackupFiles files})> pump(
    WidgetTester t, {
    required int percent,
  }) async {
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
      await t.runAsync(db.close);
    });
    final repo = WirdRepository(db);
    final size = TextSizeSettings(repo);
    addTearDown(size.dispose);
    final files = FakeBackupFiles();
    final mushaf = MushafRepository(rootBundle);
    await t.runAsync(() async {
      await mushaf.loadMeta();
      for (var p = 49; p <= 51; p++) {
        await mushaf.loadPage(p);
      }
      await repo.ensureDefaults();
      await repo.setPage((await repo.activeWird())!.id, 50);
      await size.set(percent);
    });
    await t.pumpWidget(
      MushafApp(
        wirdRepository: repo,
        mushafRepository: mushaf,
        backup: Backup(service: BackupService(db), files: files),
        textSize: size,
        home: const ReaderScreen(),
      ),
    );
    await settleReader(t);
    return (size: size, files: files);
  }

  /// A backup file made by another install whose size is [stored] (null: the file has no size at all).
  Future<String> backupWith(WidgetTester t, String? stored) async {
    final other = AppDatabase(NativeDatabase.memory());
    final json = await t.runAsync(() async {
      final r = WirdRepository(other);
      await r.ensureDefaults();
      await r.setPage(1, 50);
      final map = jsonDecode(
        await BackupService(other).exportJson(),
      ) as Map<String, dynamic>;
      final settings = map['settings'] as Map<String, dynamic>;
      settings.remove('textSizePercent');
      if (stored != null) settings['textSizePercent'] = stored;
      await other.close();
      return jsonEncode(map);
    });
    return json!;
  }

  Future<void> restore(
    WidgetTester t,
    FakeBackupFiles files,
    String file,
  ) async {
    await t.tap(key('open-settings'));
    await settleReader(t);
    files.toPick = file;
    final import = key('backup-import');
    // The backup section is below the size row; the list builds it only when it scrolls near.
    await t.scrollUntilVisible(
      import,
      200,
      scrollable: find
          .descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await t.pump();
    await t.tap(import);
    await settleReader(t);
    await t.tap(key('import-confirm'));
    await settleReader(t);
  }

  testWidgets(
    'restoring a backup that holds 150% makes the reader page bigger at once',
    (t) async {
      final run = await pump(t, percent: 100);
      expect(key('page-pan'), findsNothing);
      await restore(t, run.files, await backupWith(t, '150'));
      expect(
        key('open-settings'),
        findsOneWidget,
        reason: 'back on the reader',
      );
      expect(run.size.percent, 150);
      expect(key('page-pan'), findsOneWidget);
      final viewport = t.getRect(find.byType(PageView));
      expect(
        t.getSize(find.byType(MushafPageCard)).width,
        closeTo(viewport.width * 1.5, 0.5),
      );
    },
  );

  testWidgets(
    'restoring a backup that has no size puts the reader back at 100%',
    (t) async {
      final run = await pump(t, percent: 150);
      expect(key('page-pan'), findsOneWidget);
      await restore(t, run.files, await backupWith(t, null));
      expect(run.size.percent, 100);
      expect(key('page-pan'), findsNothing);
      final viewport = t.getRect(find.byType(PageView));
      expect(t.getSize(find.byType(MushafPageCard)), viewport.size);
    },
  );

  testWidgets('a backup with a nonsense size also gives 100%', (t) async {
    final run = await pump(t, percent: 130);
    await restore(t, run.files, await backupWith(t, 'abc'));
    expect(run.size.percent, 100);
    expect(key('page-pan'), findsNothing);
  });
}
