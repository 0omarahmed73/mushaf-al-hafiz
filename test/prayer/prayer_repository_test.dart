// The repository side of the prayer settings (feature 014, T006): one write of every `prayer.*` key, read back as
// entries, and a stream that emits on change.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/prayer/prayer_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

void main() {
  late AppDatabase db;
  late WirdRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
  });
  tearDown(() => db.close());

  test('nothing stored reads as no entries', () async {
    expect(await repo.prayerEntries(), isEmpty);
  });

  test(
    'setPrayerSettings writes every key and reads back the same settings',
    () async {
      const s = PrayerSettings(
        enabled: true,
        place: Place(
          lat: 31.2,
          lon: 29.9,
          zone: 'Africa/Cairo',
          name: 'الإسكندرية',
          source: PlaceSource.list,
          country: 'EG',
        ),
        method: 'egyptian',
      );
      await repo.setPrayerSettings(s);
      final entries = await repo.prayerEntries();
      expect(entries.keys.toSet(), kPrayerKeys);
      expect(PrayerSettings.read(entries, phoneZone: 'UTC'), s);
    },
  );

  test('a later write without a place removes the stored place', () async {
    await repo.setPrayerSettings(
      const PrayerSettings(
        place: Place(
          lat: 1,
          lon: 2,
          zone: 'UTC',
          name: 'x',
          source: PlaceSource.list,
          country: 'EG',
        ),
      ),
    );
    await repo.setPrayerSettings(const PrayerSettings());
    expect((await repo.prayerEntries()).containsKey(kPrayerPlace), isFalse);
  });

  test('watchPrayerEntries emits the new entries after a write', () async {
    final seen = <bool>[];
    final sub = repo.watchPrayerEntries().listen(
      (e) => seen.add(e[kPrayerEnabled] == 'true'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.setPrayerSettings(const PrayerSettings(enabled: true));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    expect(seen.last, isTrue);
  });
}
