import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/backup/backup.dart';
import 'package:mushaf/backup/backup_service.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/fake_backup.dart';
import '../support/harness.dart';

String pageNumber(WidgetTester t) => t.widget<Text>(find.byKey(const ValueKey('page-number'))).data!;

void main() {
  // The helper below opens a second in-memory database on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late FakeBackupFiles files;
  late BackupService service;

  Backup build(AppDatabase db) {
    service = BackupService(db);
    return Backup(service: service, files: files);
  }

  setUp(() => files = FakeBackupFiles());

  /// The reader, with the settings screen open on top.
  Future<WirdRepository> pumpSettings(WidgetTester t) async {
    final repo = await pumpAppWith(t, home: const ReaderScreen(), backup: build);
    await t.tap(find.byKey(const ValueKey('open-settings')));
    await settle(t);
    return repo;
  }

  /// A backup file from a different app state: another name, page 50 and a bookmark.
  Future<String> otherState(WidgetTester t) async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = WirdRepository(db);
    final json = await t.runAsync(() async {
      await repo.ensureDefaults();
      await repo.update(1, const WirdDraft(name: 'مستعاد', type: WirdType.reading, startPage: 50, dailyPages: 5, color: 0xFF1565C0));
      await repo.addBookmark(77, 'من الملف', wirdId: 1);
      final out = await BackupService(db).exportJson();
      await db.close();
      return out;
    });
    return json!;
  }

  Future<void> tapKey(WidgetTester t, String key) async {
    final f = find.byKey(ValueKey(key));
    await t.ensureVisible(f);
    await t.pump();
    await t.tap(f);
    await settle(t);
  }

  testWidgets('the backup section is not shown where there is no backup support', (t) async {
    await pumpAppWith(t, home: const ReaderScreen());
    await t.tap(find.byKey(const ValueKey('open-settings')));
    await settle(t);
    expect(find.byKey(const ValueKey('backup-export')), findsNothing);
    expect(find.byKey(const ValueKey('open-about')), findsOneWidget);
  });

  group('export', () {
    testWidgets('offers one file named mushaf-backup-YYYY-MM-DD.json with all the data', (t) async {
      final repo = await pumpSettings(t);
      await t.runAsync(() => repo.addBookmark(10, 'x'));
      await tapKey(t, 'backup-export');
      expect(files.shared.length, 1);
      final d = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      expect(files.shared.single.fileName, 'mushaf-backup-${d.year}-${two(d.month)}-${two(d.day)}.json');
      final map = jsonDecode(files.shared.single.json) as Map<String, dynamic>;
      expect(map['app'], 'mushaf-hafiz');
      expect((map['wirds'] as List).length, 1);
      expect((map['bookmarks'] as List).length, 1);
    });
  });

  group('import', () {
    testWidgets('asks before replacing, then restores everything and shows the restored wird', (t) async {
      final repo = await pumpSettings(t);
      files.toPick = await otherState(t);
      await tapKey(t, 'backup-import');
      expect(find.text('سيُستبدل كل ما في التطبيق. متابعة؟'), findsOneWidget);
      expect(await t.runAsync(() => repo.wirdById(1).then((w) => w!.name)), 'الورد اليومي', reason: 'nothing changed before the user confirms');

      await t.tap(find.byKey(const ValueKey('import-confirm')));
      await settle(t);

      final wird = await t.runAsync(() => repo.wirdById(1));
      expect((wird!.name, wird.currentPage, wird.dailyPages), ('مستعاد', 50, 5));
      expect((await t.runAsync(() => repo.watchBookmarks().first))!.single.bookmark.note, 'من الملف');
      expect(find.byKey(const ValueKey('backup-import')), findsNothing, reason: 'back on the reader');
      expect(pageNumber(t), '50', reason: 'the reader shows the restored position');
      expect(find.text('تم استرجاع النسخة الاحتياطية'), findsOneWidget);
    });

    testWidgets('cancelling the confirmation changes nothing', (t) async {
      final repo = await pumpSettings(t);
      files.toPick = await otherState(t);
      await tapKey(t, 'backup-import');
      await t.tap(find.text('إلغاء'));
      await settle(t);
      expect((await t.runAsync(() => repo.wirdById(1)))!.name, 'الورد اليومي');
      expect(find.byKey(const ValueKey('backup-import')), findsOneWidget, reason: 'still in settings');
    });

    testWidgets('cancelling the file picker does nothing', (t) async {
      final repo = await pumpSettings(t);
      files.toPick = null;
      await tapKey(t, 'backup-import');
      expect(files.picks, 1);
      expect(find.text('سيُستبدل كل ما في التطبيق. متابعة؟'), findsNothing);
      expect((await t.runAsync(() => repo.wirdById(1)))!.name, 'الورد اليومي');
    });

    Future<void> expectRefusedWith(WidgetTester t, WirdRepository repo, String file, String message) async {
      files.toPick = file;
      await tapKey(t, 'backup-import');
      expect(find.text(message), findsOneWidget);
      expect(find.text('سيُستبدل كل ما في التطبيق. متابعة؟'), findsNothing, reason: 'a bad file is not even offered');
      expect((await t.runAsync(() => repo.wirdById(1)))!.name, 'الورد اليومي');
    }

    testWidgets('another app\'s file, a newer backup and a damaged file are refused with a message and no change', (t) async {
      final repo = await pumpSettings(t);
      final good = jsonDecode(await otherState(t)) as Map<String, dynamic>;
      await expectRefusedWith(t, repo, jsonEncode({...good, 'app': 'other-app'}),
          'هذا الملف ليس نسخة احتياطية من «مصحف الحافظ». لم يتغيّر شيء.');
      await expectRefusedWith(t, repo, jsonEncode({...good, 'version': 2}),
          'هذه النسخة الاحتياطية أحدث من هذا التطبيق. لم يتغيّر شيء.');
      await expectRefusedWith(t, repo, '{ not json',
          'ملف النسخة الاحتياطية تالف أو غير صالح. لم يتغيّر شيء.');
    });

    testWidgets('a file that cannot be read says so', (t) async {
      final repo = await pumpSettings(t);
      files.pickError = StateError('no permission');
      await tapKey(t, 'backup-import');
      expect(find.text('تعذّرت قراءة الملف.'), findsOneWidget);
      expect((await t.runAsync(() => repo.wirdById(1)))!.name, 'الورد اليومي');
    });
  });

  group('About', () {
    testWidgets('opens from settings and credits every source', (t) async {
      await pumpSettings(t);
      await tapKey(t, 'open-about');
      expect(find.text('النص القرآني لم يُعدَّل'), findsOneWidget);
      for (final name in ['Tanzil', 'QUL', 'مجمع الملك فهد لطباعة المصحف الشريف', 'Amiri Quran', 'Reem Kufi', 'Cairo']) {
        await t.scrollUntilVisible(find.textContaining(name), 200, scrollable: find.byType(Scrollable).first);
        expect(find.textContaining(name), findsWidgets, reason: name);
      }
      expect(find.textContaining('SIL OFL'), findsNWidgets(3), reason: 'the three open fonts');
      // The QUL layout credit and the ayah-action sources from QUL (the list builds only what is near the screen).
      expect(find.textContaining('Tarteel'), findsWidgets);
      expect(find.textContaining('1421'), findsWidgets);
    });
  });
}
