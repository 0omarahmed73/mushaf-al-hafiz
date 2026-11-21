// The look the owner chose, kept in the settings table (spec FR-003, FR-016; data-model.md `Look setting.value`).
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/look/look_settings.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  late AppLookSettings settings;
  late List<LookChoice> notified;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    settings = AppLookSettings(repo);
    notified = [];
    settings.addListener(() => notified.add(settings.choice));
  });
  tearDown(() async {
    settings.dispose();
    await db.close();
  });

  test(
    'the repository keeps the look under one key, absent until chosen',
    () async {
      expect(await repo.appLookRaw(), isNull);
      await repo.setAppLook('night');
      expect(await repo.appLookRaw(), 'night');
      final rows = await db.select(db.settings).get();
      expect(rows.where((r) => r.key == 'appLook').single.value, 'night');
    },
  );

  test('before anything is stored the look is Emerald and Gold', () async {
    expect(settings.choice, LookChoice.emerald);
    expect(settings.look, AppLook.emerald);
    await settings.load();
    expect(settings.choice, LookChoice.emerald);
    expect(notified, isEmpty, reason: 'loading the default changes nothing');
    expect(await repo.appLookRaw(), isNull, reason: 'loading never writes');
  });

  test('load reads the stored look and notifies', () async {
    await repo.setAppLook('night');
    await settings.load();
    expect(settings.choice, LookChoice.night);
    expect(settings.look, AppLook.night);
    expect(notified, [LookChoice.night]);
  });

  test('a bad stored value is Emerald and nothing is rewritten', () async {
    for (final raw in ['purple', '', 'Night', 'NIGHT', '1', 'null']) {
      await db
          .into(db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(key: 'appLook', value: raw),
          );
      final s = AppLookSettings(repo);
      await s.load();
      expect(s.choice, LookChoice.emerald, reason: '"$raw"');
      expect(
        await repo.appLookRaw(),
        raw,
        reason: 'the stored text is left alone',
      );
      s.dispose();
    }
  });

  test('set saves at once and notifies once', () async {
    await settings.set(LookChoice.night);
    expect(settings.choice, LookChoice.night);
    expect(await repo.appLookRaw(), 'night');
    expect(notified, [LookChoice.night]);
  });

  test('setting the same look again notifies nothing', () async {
    await settings.set(LookChoice.night);
    notified.clear();
    await settings.set(LookChoice.night);
    expect(notified, isEmpty);
  });

  test('choosing Emerald when nothing is stored writes it so the choice is explicit', () async {
    await settings.set(LookChoice.emerald);
    expect(notified, isEmpty);
    expect(await repo.appLookRaw(), 'emerald');
  });

  test(
    'reload picks up a value changed behind our back (a restored backup)',
    () async {
      await settings.load();
      await repo.setAppLook('night');
      await settings.reload();
      expect(settings.choice, LookChoice.night);
      expect(notified, [LookChoice.night]);
      await settings.reload();
      expect(notified, [
        LookChoice.night,
      ], reason: 'no change, no notification');
    },
  );

  test('a backup that removed the row brings Emerald back on reload', () async {
    await settings.set(LookChoice.night);
    await (db.delete(db.settings)..where((s) => s.key.equals('appLook'))).go();
    await settings.reload();
    expect(settings.choice, LookChoice.emerald);
  });

  test(
    'a second settings object on the same database sees the saved choice',
    () async {
      await settings.set(LookChoice.night);
      final again = AppLookSettings(repo);
      await again.load();
      expect(again.choice, LookChoice.night);
      again.dispose();
    },
  );
}
