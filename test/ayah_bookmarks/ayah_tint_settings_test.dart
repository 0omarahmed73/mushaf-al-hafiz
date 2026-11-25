// The Settings switch of the tint (feature 013, spec FR-024, SC-017; data-model.md Settings `ayahTint`; research D7): one
// key in the settings table, on until a stored 'false', saved at once, read again after a restored backup.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/settings/ayah_tint_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  late AyahTintSettings settings;
  late List<bool> notified;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    settings = AyahTintSettings(repo);
    notified = [];
    settings.addListener(() => notified.add(settings.enabled));
  });
  tearDown(() async {
    settings.dispose();
    await db.close();
  });

  Future<void> store(String raw) => repo.writeSetting('ayahTint', raw);

  test('on with nothing stored; load never writes', () async {
    expect(settings.enabled, isTrue);
    await settings.load();
    expect(settings.enabled, isTrue);
    expect(notified, isEmpty);
    expect(await repo.ayahTintRaw(), isNull, reason: 'loading never writes');
  });

  test(
    'off only for a stored false; any other text is on and is not rewritten',
    () async {
      await store('false');
      await settings.load();
      expect(settings.enabled, isFalse);
      expect(notified, [false]);
      for (final raw in ['true', '', 'False', 'FALSE', '0', 'no', 'null']) {
        await store(raw);
        await settings.load();
        expect(settings.enabled, isTrue, reason: '«$raw»');
        expect(await repo.ayahTintRaw(), raw, reason: 'load never writes');
      }
    },
  );

  test(
    'set saves at once and notifies once; the same value again notifies nobody',
    () async {
      await settings.set(false);
      expect(settings.enabled, isFalse);
      expect(await repo.ayahTintRaw(), 'false');
      expect(notified, [false]);
      await settings.set(false);
      expect(notified, [false]);
      await settings.set(true);
      expect(await repo.ayahTintRaw(), 'true');
      expect(notified, [false, true]);
    },
  );

  test('the repository keeps it under the one key ayahTint', () async {
    await repo.setAyahTint(false);
    final rows = await db.select(db.settings).get();
    expect(rows.where((r) => r.key == 'ayahTint').single.value, 'false');
    await repo.setAyahTint(true);
    expect(await repo.ayahTintRaw(), 'true');
  });

  test(
    'reload follows a value written behind its back (a restored backup)',
    () async {
      await settings.load();
      await store('false');
      expect(settings.enabled, isTrue);
      await settings.reload();
      expect(settings.enabled, isFalse);
      await db.delete(db.settings).go();
      await settings.reload();
      expect(settings.enabled, isTrue, reason: 'a backup with no value is on');
      expect(notified, [false, true]);
    },
  );
}
