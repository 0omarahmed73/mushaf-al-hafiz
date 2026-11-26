// The bundled city list (feature 014, FR-004a, FR-004b, research D4): about 1,300 cities of the Arab League and OIC
// countries from GeoNames (CC BY 4.0), built by tool/build_cities.py. Read-only.
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../search/arabic_fold.dart';

@immutable
class City {
  const City({
    required this.ar,
    required this.en,
    required this.cc,
    required this.lat,
    required this.lon,
    required this.tz,
  });

  final String ar;
  final String en;
  final String cc;
  final double lat;
  final double lon;
  final String tz;
}

class CityIndex {
  CityIndex(this.cities)
    : _keys = [for (final c in cities) _arKey(c.ar)],
      _en = [for (final c in cities) c.en.toLowerCase()];

  static const String asset = 'assets/prayer/cities.json';

  /// Largest first.
  final List<City> cities;
  final List<String> _keys;
  final List<String> _en;

  static Future<CityIndex> load(AssetBundle bundle) async {
    final list = jsonDecode(await bundle.loadString(asset)) as List<dynamic>;
    return CityIndex([
      for (final e in list.cast<Map<String, dynamic>>())
        City(
          ar: e['ar'] as String,
          en: e['en'] as String,
          cc: e['cc'] as String,
          lat: (e['lat'] as num).toDouble(),
          lon: (e['lon'] as num).toDouble(),
          tz: e['tz'] as String,
        ),
    ]);
  }

  /// A name folded like a surah name of feature 011 (hamza forms, ة/ه, ى/ي and marks folded; spaces gone).
  static String _arKey(String name) => ArabicFold.surahKey(name);

  static String _withoutAl(String folded) =>
      folded.startsWith('ال') && folded.length > 2
      ? folded.substring(2)
      : folded;

  /// The cities whose Arabic or English name matches [query]: equal first, then starting with it, then containing it,
  /// largest first within each; an empty query gives the largest cities. At most [limit].
  List<City> search(String query, {int limit = 50}) {
    final typed = query.trim();
    if (typed.isEmpty) return cities.take(limit).toList();
    final q = ArabicFold.query(typed)
        .replaceAll(ArabicFold.seatWaw, 'و')
        .replaceAll(ArabicFold.seatYeh, 'ي')
        .replaceAll(' ', '');
    final arQueries = q.isEmpty ? const <String>{} : {q, _withoutAl(q)};
    final en = typed.toLowerCase();
    final ranked = <(int, int)>[];
    for (var i = 0; i < cities.length; i++) {
      var best = 3;
      final key = _keys[i];
      for (final name in {key, _withoutAl(key)}) {
        for (final a in arQueries) {
          final r = name == a
              ? 0
              : name.startsWith(a)
              ? 1
              : name.contains(a)
              ? 2
              : 3;
          if (r < best) best = r;
        }
      }
      final e = _en[i];
      final r = e == en
          ? 0
          : e.startsWith(en)
          ? 1
          : e.contains(en)
          ? 2
          : 3;
      if (r < best) best = r;
      if (best < 3) ranked.add((best, i));
    }
    ranked.sort(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    );
    return [for (final r in ranked.take(limit)) cities[r.$2]];
  }

  /// The listed city closest to ([lat], [lon]) on the sphere.
  City nearest(double lat, double lon) {
    City? best;
    var bestD = double.infinity;
    final la = lat * math.pi / 180;
    for (final c in cities) {
      final cl = c.lat * math.pi / 180;
      final dl = (c.lon - lon) * math.pi / 180;
      // The spherical law of cosines is exact enough to rank cities.
      final d = math.acos(
        (math.sin(la) * math.sin(cl) +
                math.cos(la) * math.cos(cl) * math.cos(dl))
            .clamp(-1.0, 1.0),
      );
      if (d < bestD) {
        bestD = d;
        best = c;
      }
    }
    return best!;
  }
}
