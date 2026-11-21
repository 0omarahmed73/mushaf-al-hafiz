import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  late TextSizeSettings settings;
  late List<int> notified;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    settings = TextSizeSettings(repo);
    notified = [];
    settings.addListener(() => notified.add(settings.percent));
  });
  tearDown(() async {
    settings.dispose();
    await db.close();
  });

  test(
    'the repository keeps the size under one key, absent until chosen',
    () async {
      expect(await repo.textSizeRaw(), isNull);
      await repo.setTextSizePercent(120);
      expect(await repo.textSizeRaw(), '120');
      final rows = await db.select(db.settings).get();
      expect(rows.where((r) => r.key == 'textSizePercent').single.value, '120');
    },
  );

  test(
    'before anything is stored the size is 100% and is the default',
    () async {
      expect(settings.percent, 100);
      expect(settings.factor, 1.0);
      expect(settings.isDefault, isTrue);
      await settings.load();
      expect(settings.percent, 100);
      expect(notified, isEmpty, reason: 'loading the default changes nothing');
    },
  );

  test('load reads the stored size and notifies', () async {
    await repo.setTextSizePercent(130);
    await settings.load();
    expect(
      (settings.percent, settings.factor, settings.isDefault),
      (130, 1.3, false),
    );
    expect(notified, [130]);
  });

  test('a bad stored value is the default and nothing is rewritten', () async {
    for (final raw in ['abc', '999', '-5', '']) {
      await db
          .into(db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(key: 'textSizePercent', value: raw),
          );
      final fresh = TextSizeSettings(repo);
      await fresh.load();
      expect(fresh.percent, 100, reason: raw);
      fresh.dispose();
      expect(await repo.textSizeRaw(), raw, reason: 'load never writes');
    }
  });

  test('set saves at once and notifies once', () async {
    await settings.set(140);
    expect(settings.percent, 140);
    expect(await repo.textSizeRaw(), '140');
    expect(notified, [140]);
  });

  test('setting the same size again does nothing', () async {
    await settings.set(110);
    await settings.set(110);
    expect(notified, [110]);
  });

  test('a size that is not a step snaps to the nearest step; one outside the range is the default', () async {
    await settings.set(104);
    expect(settings.percent, 100);
    await settings.set(116);
    expect(settings.percent, 120);
    expect(await repo.textSizeRaw(), '120');
    await settings.set(999);
    expect(settings.percent, 100);
    expect(await repo.textSizeRaw(), '100');
  });

  test('reset returns to 100% and stores it', () async {
    await settings.set(150);
    await settings.reset();
    expect(settings.percent, 100);
    expect(settings.isDefault, isTrue);
    expect(await repo.textSizeRaw(), '100');
    expect(notified, [150, 100]);
  });

  test('a new instance after a restart finds the saved size', () async {
    await settings.set(90);
    final restarted = TextSizeSettings(repo);
    await restarted.load();
    expect(restarted.percent, 90);
    restarted.dispose();
  });

  test(
    'reload picks up a change made behind its back (a restored backup)',
    () async {
      await settings.load();
      await repo.setTextSizePercent(150);
      await settings.reload();
      expect(settings.percent, 150);
      expect(notified, [150]);
      await db.delete(db.settings).go(); // a backup without the key
      await settings.reload();
      expect(settings.percent, 100);
      expect(notified, [150, 100]);
    },
  );
}
