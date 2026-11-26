// The prayer settings as stored in the Settings table (feature 014, data-model.md, research D10). Parsing never
// throws: an unusable value falls back to its default.
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/prayer/prayer_settings.dart';

void main() {
  test('nothing stored gives the defaults', () {
    final s = PrayerSettings.read(const {}, phoneZone: 'Africa/Cairo');
    expect(s.enabled, isFalse);
    expect(s.place, isNull);
    expect(s.method, 'auto');
    expect(s.asr, AsrRule.standard);
    expect(s.offsets, [0, 0, 0, 0, 0, 0]);
    expect(s.notify, List.filled(5, const PrayerNotify(NotifyMode.sound, 0)));
  });

  test('a full round trip keeps every value', () {
    const place = Place(
      lat: 30.063,
      lon: 31.25,
      zone: 'Africa/Cairo',
      name: 'القاهرة',
      source: PlaceSource.location,
      country: 'EG',
    );
    final s = PrayerSettings(
      enabled: true,
      place: place,
      method: 'egyptian',
      asr: AsrRule.hanafi,
      offsets: const [1, 0, -2, 3, 30, -30],
      notify: const [
        PrayerNotify(NotifyMode.silent, 10),
        PrayerNotify(NotifyMode.sound, 0),
        PrayerNotify(NotifyMode.off, 0),
        PrayerNotify(NotifyMode.sound, 30),
        PrayerNotify(NotifyMode.sound, 5),
      ],
    );
    final back = PrayerSettings.read(s.toEntries(), phoneZone: 'Europe/London');
    expect(back, s);
    expect(s.toEntries().keys.toSet(), kPrayerKeys);
  });

  test('unusable values fall back without throwing', () {
    final s = PrayerSettings.read({
      'prayer.enabled': 'yes',
      'prayer.place': '{"lat": 95, "lon": 31, "zone": "Africa/Cairo", "name": "x", "source": "list", "country": "EG"}',
      'prayer.method': 'nonsense',
      'prayer.asr': 'maliki',
      'prayer.offsets': '[45, -40, 2]',
      'prayer.notify': 'not json',
    }, phoneZone: 'Africa/Cairo');
    expect(s.enabled, isFalse);
    expect(s.place, isNull, reason: 'lat must be in −90..90');
    expect(s.method, 'auto');
    expect(s.asr, AsrRule.standard);
    expect(s.offsets, [0, 0, 0, 0, 0, 0], reason: 'not six ints');
    expect(s.notify, List.filled(5, const PrayerNotify(NotifyMode.sound, 0)));
  });

  test('offsets are clamped to −30..30; an unknown "before" becomes 0', () {
    final s = PrayerSettings.read({
      'prayer.offsets': '[45, -40, 2, 0, 0, 0]',
      'prayer.notify':
          '[{"mode":"silent","before":7},{"mode":"off","before":10},{"mode":"x","before":5},'
          '{"mode":"sound","before":20},{"mode":"sound","before":0}]',
    }, phoneZone: 'Africa/Cairo');
    expect(s.offsets, [30, -30, 2, 0, 0, 0]);
    expect(s.notify[0], const PrayerNotify(NotifyMode.silent, 0));
    expect(s.notify[1], const PrayerNotify(NotifyMode.off, 10));
    expect(s.notify[2], const PrayerNotify(NotifyMode.sound, 5));
    expect(s.notify[3], const PrayerNotify(NotifyMode.sound, 20));
  });

  test('a place with an unknown zone takes the phone zone; a bad source or lon drops it', () {
    final s = PrayerSettings.read({
      'prayer.place': '{"lat": 30, "lon": 31, "zone": "Mars/Olympus", "name": "x", "source": "list", "country": "EG"}',
    }, phoneZone: 'Africa/Cairo');
    expect(s.place!.zone, 'Africa/Cairo');
    expect(
      PrayerSettings.read({
        'prayer.place': '{"lat": 30, "lon": 181, "zone": "Africa/Cairo", "name": "x", "source": "list", "country": "EG"}',
      }, phoneZone: 'Africa/Cairo').place,
      isNull,
    );
    expect(
      PrayerSettings.read({
        'prayer.place': '{"lat": 30, "lon": 31, "zone": "Africa/Cairo", "name": "x", "source": "gps", "country": "EG"}',
      }, phoneZone: 'Africa/Cairo').place,
      isNull,
    );
  });

  test('every method key is known', () {
    expect(
      kPrayerMethods,
      containsAll([
        'egyptian',
        'ummAlQura',
        'muslimWorldLeague',
        'karachi',
        'dubai',
        'kuwait',
        'qatar',
        'morocco',
        'turkiye',
        'northAmerica',
      ]),
    );
    expect(kPrayerMethods.length, 10);
  });
}
