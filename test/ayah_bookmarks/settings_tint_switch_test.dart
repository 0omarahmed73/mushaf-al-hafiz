// The Settings switch of the tint (feature 013, spec FR-024, SC-017, SC-007; contracts/ui.md §6; research D7): one
// SwitchListTile `ayah-tint-switch` after the text-size tile, on by default, saved at once; the reader behind it follows
// without a restart; the value comes back after a restart and after a restored backup (the reader reloads it).
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/backup/backup.dart';
import 'package:mushaf/backup/backup_service.dart';
import 'package:mushaf/mushaf/ayah_bookmark_strings.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/page_look.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/settings/ayah_tint_settings.dart';
import 'package:mushaf/settings/settings_screen.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/fake_backup.dart';
import '../support/harness.dart' show settle;
import '../support/reader_harness.dart' show settleReader;

Finder key(String k) => find.byKey(ValueKey(k));
final Finder tintSwitch = key('ayah-tint-switch');

void main() {
  // A backup file is made from a second in-memory database on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late WirdRepository repo;
  late TextSizeSettings size;
  late AyahTintSettings tint;
  late MushafRepository mushaf;
  late FakeBackupFiles files;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    size = TextSizeSettings(repo);
    tint = AyahTintSettings(repo);
    mushaf = MushafRepository(rootBundle);
    files = FakeBackupFiles();
  });

  /// [home] in the app with the tint switch provided, on an in-memory database. [seed] runs before the pump.
  Future<void> pumpApp(
    WidgetTester t, {
    required Widget home,
    Size screen = const Size(412, 915),
    double textScale = 1.0,
    AyahTintSettings? setting,
    bool withBackup = false,
    Future<void> Function()? seed,
  }) async {
    t.view.physicalSize = screen;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    addTearDown(() async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
      size.dispose();
      tint.dispose();
      await t.runAsync(db.close);
    });
    await t.runAsync(() async {
      await mushaf.loadMeta();
      for (var p = 46; p <= 51; p++) {
        await mushaf.loadPage(p);
      }
      await repo.ensureDefaults();
      if (seed != null) await seed();
      await size.load();
      await (setting ?? tint).load();
    });
    await t.pumpWidget(
      MushafApp(
        wirdRepository: repo,
        mushafRepository: mushaf,
        backup: withBackup
            ? Backup(service: BackupService(db), files: files)
            : null,
        textSize: size,
        ayahTint: setting ?? tint,
        home: textScale == 1.0
            ? home
            : Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(textScale)),
                  child: home,
                ),
              ),
      ),
    );
    await settleReader(t);
  }

  /// The active wird on page 48 with an ayah bookmark of it on 2:282 (the whole page is that ayah).
  Future<void> seedBookmark() async {
    final id = (await repo.activeWird())!.id;
    await repo.setPage(id, 48);
    await repo.toggleAyahBookmark(const AyahRef(2, 282), page: 48, wirdId: id);
  }

  Future<void> showSwitch(WidgetTester t) async {
    await t.scrollUntilVisible(
      tintSwitch,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.pump();
  }

  Future<void> tapSwitch(WidgetTester t) async {
    await showSwitch(t);
    await t.tap(tintSwitch);
    await settle(t);
  }

  /// The words of page 48 that the reader draws on the Emerald & Gold tint.
  Future<int> tintedWords(WidgetTester t) async {
    final page = (await t.runAsync(() => mushaf.loadPage(48)))!;
    var n = 0;
    for (final w in page.lines.expand((MushafLine l) => l.words)) {
      final boxes = t.widgetList<DecoratedBox>(
        find.ancestor(
          of: find.byKey(ValueKey('w${w.id}')),
          matching: find.byType(DecoratedBox),
        ),
      );
      final tinted = boxes.any(
        (b) =>
            (b.decoration as BoxDecoration?)?.color ==
            PageLook.emerald.bookmarkTint,
      );
      if (tinted) n++;
    }
    return n;
  }

  Future<void> openSettings(WidgetTester t) async {
    await t.tap(key('open-settings'));
    await settle(t);
  }

  Future<void> back(WidgetTester t) async {
    // Not `t.pageBack()`: it looks for the English tooltip 'Back', and the app is Arabic.
    await t.tap(find.byType(BackButton));
    await settleReader(t);
  }

  testWidgets(
    'the switch sits after the text-size tile with its title and line, on by default, 48 px',
    (t) async {
      await pumpApp(t, home: const SettingsScreen());
      await showSwitch(t);
      expect(tintSwitch, findsOneWidget);
      final tile = t.widget<SwitchListTile>(tintSwitch);
      expect(tile.value, isTrue, reason: 'on by default');
      expect(
        find.descendant(of: tintSwitch, matching: find.text(kAyahTintTitle)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tintSwitch, matching: find.text(kAyahTintSubtitle)),
        findsOneWidget,
      );
      expect(kAyahTintTitle, 'تظليل الآيات التي عليها علامة');
      final box = t.getRect(tintSwitch);
      expect(box.height, greaterThanOrEqualTo(48));
      await t.scrollUntilVisible(
        key('text-size-slider'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      final sliderTop = t.getTopLeft(key('text-size-slider')).dy;
      await showSwitch(t);
      expect(
        t.getTopLeft(tintSwitch).dy,
        greaterThan(sliderTop),
        reason: 'after the text-size tile',
      );
      expect(
        await t.runAsync(repo.ayahTintRaw),
        isNull,
        reason: 'showing it writes nothing',
      );
    },
  );

  testWidgets('a toggle saves at once, both ways', (t) async {
    await pumpApp(t, home: const SettingsScreen());
    await tapSwitch(t);
    expect(tint.enabled, isFalse);
    expect(t.widget<SwitchListTile>(tintSwitch).value, isFalse);
    expect(await t.runAsync(repo.ayahTintRaw), 'false');
    await tapSwitch(t);
    expect(tint.enabled, isTrue);
    expect(t.widget<SwitchListTile>(tintSwitch).value, isTrue);
    expect(await t.runAsync(repo.ayahTintRaw), 'true');
  });

  testWidgets('the reader behind follows the switch without a restart', (
    t,
  ) async {
    await pumpApp(t, home: const ReaderScreen(), seed: seedBookmark);
    expect(t.widget<Text>(key('page-number')).data, '48');
    final all = await tintedWords(t);
    expect(
      all,
      greaterThan(0),
      reason: 'the bookmarked ayah is tinted with the switch on',
    );
    await openSettings(t);
    await tapSwitch(t);
    await back(t);
    expect(await tintedWords(t), 0, reason: 'off: no word is tinted');
    await openSettings(t);
    await tapSwitch(t);
    await back(t);
    expect(
      await tintedWords(t),
      all,
      reason: 'on again: the tint is back, no restart',
    );
  });

  testWidgets('the value comes back after a restart', (t) async {
    await t.runAsync(() async {
      await repo.ensureDefaults();
      final before = AyahTintSettings(repo);
      await before.set(false);
      before.dispose();
    });
    // A new settings object over the same database, loaded before the first frame as main.dart does.
    final restarted = AyahTintSettings(repo);
    addTearDown(restarted.dispose);
    await pumpApp(t, home: const SettingsScreen(), setting: restarted);
    await showSwitch(t);
    expect(restarted.enabled, isFalse);
    expect(t.widget<SwitchListTile>(tintSwitch).value, isFalse);
  });

  testWidgets(
    'the value comes back after a backup restore: the reader reloads it',
    (t) async {
      // A backup of another app state whose switch is off.
      final json = await t.runAsync(() async {
        final other = AppDatabase(NativeDatabase.memory());
        final otherRepo = WirdRepository(other);
        await otherRepo.ensureDefaults();
        await otherRepo.setAyahTint(false);
        final out = await BackupService(other).exportJson();
        await other.close();
        return out;
      });
      files.toPick = json;
      await pumpApp(t, home: const ReaderScreen(), withBackup: true);
      expect(tint.enabled, isTrue);
      await openSettings(t);
      final import = key('backup-import');
      await t.scrollUntilVisible(
        import,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(import);
      await settle(t);
      await t.tap(key('import-confirm'));
      await settleReader(t);
      expect(
        find.byKey(const ValueKey('backup-import')),
        findsNothing,
        reason: 'back on the reader',
      );
      expect(
        await t.runAsync(repo.ayahTintRaw),
        'false',
        reason: 'the backup carried the setting',
      );
      expect(
        tint.enabled,
        isFalse,
        reason: 'the reader reloaded it after the restore',
      );
      // «تم استرجاع النسخة الاحتياطية» lies over the bottom bar for its 4 s (as since feature 004): let it go first.
      await t.pump(const Duration(seconds: 5));
      await settleReader(t);
      await openSettings(t);
      await showSwitch(t);
      expect(t.widget<SwitchListTile>(tintSwitch).value, isFalse);
    },
  );

  testWidgets('no overflow at 320 dp with a 2x font, and still 48 px', (
    t,
  ) async {
    await pumpApp(
      t,
      home: const SettingsScreen(),
      screen: const Size(320, 640),
      textScale: 2.0,
    );
    await showSwitch(t);
    expect(t.takeException(), isNull);
    expect(t.getRect(tintSwitch).height, greaterThanOrEqualTo(48));
    expect(
      find.descendant(of: tintSwitch, matching: find.text(kAyahTintTitle)),
      findsOneWidget,
    );
  });
}
