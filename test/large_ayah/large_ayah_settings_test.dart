// The large-ayah settings (feature 015, data-model.md "Stored: settings keys"; research D8): four keys in the settings
// table; parsing never throws, writes happen at once, listeners hear only real changes, reload after a restored backup.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/large_ayah/large_ayah_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/test_meta.dart';

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  late LargeAyahSettings settings;
  late int notified;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    settings = LargeAyahSettings(repo, meta: testMeta());
    notified = 0;
    settings.addListener(() => notified++);
  });
  tearDown(() async {
    settings.dispose();
    await db.close();
  });

  Future<void> store(String key, String raw) => repo.writeSetting(key, raw);
  Future<String?> raw(String key) async =>
      (await db.select(db.settings).get()).where((r) => r.key == key).map((r) => r.value).firstOrNull;

  test('defaults with nothing stored: off, 1 ayah, size step 1, no ayah; load never writes', () async {
    await settings.load();
    expect(settings.on, isFalse);
    expect(settings.count, 1);
    expect(settings.sizeStep, 1);
    expect(settings.factor, 2.0);
    expect(settings.at, isNull);
    expect(await db.select(db.settings).get(), isEmpty);
    expect(notified, 0);
  });

  test('the factors of the three size steps', () {
    expect(LargeAyahSettings.factors, [2.0, 2.5, 3.0]);
  });

  test('stored values are read', () async {
    await store('largeAyah', 'true');
    await store('largeAyahCount', '3');
    await store('largeAyahSize', '2');
    await store('largeAyahAt', '2:255');
    await settings.load();
    expect(settings.on, isTrue);
    expect(settings.count, 3);
    expect(settings.sizeStep, 2);
    expect(settings.factor, 2.5);
    expect(settings.at, const AyahRef(2, 255));
    expect(notified, greaterThan(0));
  });

  for (final bad in ['', 'yes', 'TRUE', '1']) {
    test('largeAyah "$bad" is off', () async {
      await store('largeAyah', bad);
      await settings.load();
      expect(settings.on, isFalse);
    });
  }

  for (final bad in ['0', '4', '-1', '2.5', 'x', '']) {
    test('largeAyahCount "$bad" and largeAyahSize "$bad" are 1', () async {
      await store('largeAyahCount', bad);
      await store('largeAyahSize', bad);
      await settings.load();
      expect(settings.count, 1);
      expect(settings.sizeStep, 1);
    });
  }

  for (final bad in ['2:287', 'x', '115:1', '0:1', '1:0', '1:', ':1', '1:2:3', '']) {
    test('largeAyahAt "$bad" is ignored', () async {
      await store('largeAyahAt', bad);
      await settings.load();
      expect(settings.at, isNull);
    });
  }

  test('setters write at once and notify only on a real change', () async {
    await settings.load();
    await settings.setOn(true);
    expect(await raw('largeAyah'), 'true');
    await settings.setCount(2);
    expect(await raw('largeAyahCount'), '2');
    await settings.setSizeStep(3);
    expect(await raw('largeAyahSize'), '3');
    await settings.setAt(const AyahRef(1, 7));
    expect(await raw('largeAyahAt'), '1:7');
    expect(notified, 3, reason: 'setAt does not notify');
    await settings.setOn(true);
    await settings.setCount(2);
    await settings.setSizeStep(3);
    await settings.setAt(const AyahRef(1, 7));
    expect(notified, 3, reason: 'no change, no notification');
    await settings.setOn(false);
    expect(await raw('largeAyah'), 'false');
    expect(settings.on, isFalse);
  });

  test('a count or size outside 1..3 is refused', () async {
    expect(() => settings.setCount(0), throwsArgumentError);
    expect(() => settings.setCount(4), throwsArgumentError);
    expect(() => settings.setSizeStep(4), throwsArgumentError);
  });

  test('the remembered ayah does not notify (it changes on every screen)', () async {
    await settings.setAt(const AyahRef(2, 5));
    await settings.setAt(const AyahRef(2, 6));
    expect(settings.at, const AyahRef(2, 6));
    expect(notified, 0);
  });

  test('reload picks up values written behind its back (a restored backup)', () async {
    await settings.load();
    await store('largeAyah', 'true');
    await store('largeAyahCount', '2');
    await settings.reload();
    expect(settings.on, isTrue);
    expect(settings.count, 2);
  });

  test('without a meta, any surah 1..114 and ayah >= 1 is accepted', () async {
    final loose = LargeAyahSettings(repo);
    await store('largeAyahAt', '114:6');
    await loose.load();
    expect(loose.at, const AyahRef(114, 6));
    loose.dispose();
  });
}
