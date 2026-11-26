// The prayer settings, kept as `prayer.*` keys in the Settings table (feature 014, data-model.md, research D10).
// Reading never throws: an unusable value falls back to its default, so the screen always opens (Principle VII).
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const String kPrayerEnabled = 'prayer.enabled';
const String kPrayerPlace = 'prayer.place';
const String kPrayerMethod = 'prayer.method';
const String kPrayerAsr = 'prayer.asr';
const String kPrayerOffsets = 'prayer.offsets';
const String kPrayerNotify = 'prayer.notify';

/// Every key this feature writes (the backup keeps them when a file has none, research D10).
const Set<String> kPrayerKeys = {
  kPrayerEnabled,
  kPrayerPlace,
  kPrayerMethod,
  kPrayerAsr,
  kPrayerOffsets,
  kPrayerNotify,
};

/// The methods a reader can choose (names of `adhan_dart`'s `CalculationMethod`); `auto` means by the country.
const List<String> kPrayerMethods = [
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
];

enum AsrRule { standard, hanafi }

enum PlaceSource { location, list }

enum NotifyMode { sound, silent, off }

/// The minutes a reminder may come before its prayer; 0 is no reminder.
const List<int> kBeforeChoices = [0, 5, 10, 15, 20, 30];

@immutable
class Place {
  const Place({
    required this.lat,
    required this.lon,
    required this.zone,
    required this.name,
    required this.source,
    required this.country,
  });

  final double lat;
  final double lon;

  /// An IANA zone id.
  final String zone;

  /// The list city's Arabic name, or the nearest list city's name for a location reading.
  final String name;
  final PlaceSource source;

  /// ISO 3166 alpha-2, for the method default.
  final String country;

  Map<String, Object> toJson() => {
    'lat': lat,
    'lon': lon,
    'zone': zone,
    'name': name,
    'source': source.name,
    'country': country,
  };

  @override
  bool operator ==(Object other) =>
      other is Place &&
      other.lat == lat &&
      other.lon == lon &&
      other.zone == zone &&
      other.name == name &&
      other.source == source &&
      other.country == country;

  @override
  int get hashCode => Object.hash(lat, lon, zone, name, source, country);
}

@immutable
class PrayerNotify {
  const PrayerNotify(this.mode, this.before);

  final NotifyMode mode;

  /// Minutes before the prayer for a reminder, one of [kBeforeChoices]; 0 is none.
  final int before;

  @override
  bool operator ==(Object other) =>
      other is PrayerNotify && other.mode == mode && other.before == before;

  @override
  int get hashCode => Object.hash(mode, before);

  @override
  String toString() => 'PrayerNotify(${mode.name}, $before)';
}

@immutable
class PrayerSettings {
  const PrayerSettings({
    this.enabled = false,
    this.place,
    this.method = 'auto',
    this.asr = AsrRule.standard,
    this.offsets = const [0, 0, 0, 0, 0, 0],
    this.notify = const [
      _defaultNotify,
      _defaultNotify,
      _defaultNotify,
      _defaultNotify,
      _defaultNotify,
    ],
  });

  static const PrayerNotify _defaultNotify = PrayerNotify(NotifyMode.sound, 0);

  final bool enabled;
  final Place? place;

  /// `auto` or one of [kPrayerMethods].
  final String method;
  final AsrRule asr;

  /// Six minute offsets, each −30..30: fajr, sunrise, dhuhr, asr, maghrib, isha.
  final List<int> offsets;

  /// Five entries: fajr, dhuhr, asr, maghrib, isha.
  final List<PrayerNotify> notify;

  PrayerSettings copyWith({
    bool? enabled,
    Place? place,
    String? method,
    AsrRule? asr,
    List<int>? offsets,
    List<PrayerNotify>? notify,
  }) => PrayerSettings(
    enabled: enabled ?? this.enabled,
    place: place ?? this.place,
    method: method ?? this.method,
    asr: asr ?? this.asr,
    offsets: offsets ?? this.offsets,
    notify: notify ?? this.notify,
  );

  /// The settings in [table] (the whole Settings table, or only its `prayer.*` keys). [phoneZone] replaces a stored zone
  /// the time-zone database does not know.
  static PrayerSettings read(
    Map<String, String> table, {
    required String phoneZone,
  }) => PrayerSettings(
    enabled: table[kPrayerEnabled] == 'true',
    place: _readPlace(table[kPrayerPlace], phoneZone),
    method: kPrayerMethods.contains(table[kPrayerMethod])
        ? table[kPrayerMethod]!
        : 'auto',
    asr: table[kPrayerAsr] == 'hanafi' ? AsrRule.hanafi : AsrRule.standard,
    offsets: _readOffsets(table[kPrayerOffsets]),
    notify: _readNotify(table[kPrayerNotify]),
  );

  Map<String, String> toEntries() => {
    kPrayerEnabled: '$enabled',
    if (place != null) kPrayerPlace: jsonEncode(place!.toJson()),
    kPrayerMethod: method,
    kPrayerAsr: asr.name,
    kPrayerOffsets: jsonEncode(offsets),
    kPrayerNotify: jsonEncode([
      for (final n in notify) {'mode': n.mode.name, 'before': n.before},
    ]),
  };

  @override
  bool operator ==(Object other) =>
      other is PrayerSettings &&
      other.enabled == enabled &&
      other.place == place &&
      other.method == method &&
      other.asr == asr &&
      listEquals(other.offsets, offsets) &&
      listEquals(other.notify, notify);

  @override
  int get hashCode => Object.hash(
    enabled,
    place,
    method,
    asr,
    Object.hashAll(offsets),
    Object.hashAll(notify),
  );
}

Object? _decode(String? raw) {
  if (raw == null) return null;
  try {
    return jsonDecode(raw);
  } catch (_) {
    return null;
  }
}

bool zoneKnown(String zone) {
  if (!tz.timeZoneDatabase.isInitialized) tzdata.initializeTimeZones();
  return tz.timeZoneDatabase.locations.containsKey(zone);
}

Place? _readPlace(String? raw, String phoneZone) {
  final m = _decode(raw);
  if (m is! Map) return null;
  final lat = m['lat'],
      lon = m['lon'],
      zone = m['zone'],
      name = m['name'],
      source = m['source'];
  final country = m['country'];
  if (lat is! num ||
      lon is! num ||
      lat < -90 ||
      lat > 90 ||
      lon < -180 ||
      lon > 180) {
    return null;
  }
  if (name is! String || country is! String) return null;
  final src = PlaceSource.values.where((s) => s.name == source).firstOrNull;
  if (src == null) return null;
  return Place(
    lat: lat.toDouble(),
    lon: lon.toDouble(),
    zone: zone is String && zoneKnown(zone) ? zone : phoneZone,
    name: name,
    source: src,
    country: country,
  );
}

List<int> _readOffsets(String? raw) {
  final v = _decode(raw);
  if (v is! List || v.length != 6 || v.any((e) => e is! int)) {
    return const [0, 0, 0, 0, 0, 0];
  }
  return [for (final e in v) (e as int).clamp(-30, 30)];
}

List<PrayerNotify> _readNotify(String? raw) {
  final fallback = const PrayerSettings().notify;
  final v = _decode(raw);
  if (v is! List || v.length != 5) return fallback;
  return [
    for (final e in v)
      if (e is Map)
        PrayerNotify(
          NotifyMode.values.where((m) => m.name == e['mode']).firstOrNull ??
              NotifyMode.sound,
          kBeforeChoices.contains(e['before']) ? e['before'] as int : 0,
        )
      else
        PrayerSettings._defaultNotify,
  ];
}
