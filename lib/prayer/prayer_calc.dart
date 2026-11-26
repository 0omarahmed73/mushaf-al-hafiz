// Prayer times calculated on the phone (feature 014, FR-006..FR-010, research D1, D5). Times are UTC instants; the
// screen and the scheduler show and schedule them in the place's zone.
import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'prayer_settings.dart';

/// The six times of a day, in this order everywhere in the feature.
enum Prayer { fajr, sunrise, dhuhr, asr, maghrib, isha }

/// The five prayers that can be next or notified (no sunrise).
const List<Prayer> kFivePrayers = [
  Prayer.fajr,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

@immutable
class DayTimes {
  const DayTimes(this.date, this.utc, {required this.highLatitude});

  /// The local date (year, month, day) these times belong to.
  final DateTime date;
  final Map<Prayer, DateTime> utc;

  /// Fajr or Isha come from a high-latitude rule here (FR-010).
  final bool highLatitude;
}

/// Above this latitude (north or south) Fajr and Isha come from the seventh-of-the-night rule (adhan's recommendation).
const double kHighLatitude = 48;

abstract final class PrayerCalc {
  static const Map<String, String> _byCountry = {
    'EG': 'egyptian',
    'SA': 'ummAlQura',
    'AE': 'dubai',
    'KW': 'kuwait',
    'QA': 'qatar',
    'MA': 'morocco',
    'TR': 'turkiye',
    'PK': 'karachi',
    'IN': 'karachi',
    'BD': 'karachi',
    'AF': 'karachi',
    'US': 'northAmerica',
    'CA': 'northAmerica',
  };

  /// The method `auto` means for a country (contracts/dart-interfaces.md).
  static String methodFor(String countryCode) =>
      _byCountry[countryCode] ?? 'muslimWorldLeague';

  static adhan.CalculationParameters _params(String method) => switch (method) {
    'egyptian' => adhan.CalculationMethodParameters.egyptian(),
    'ummAlQura' => adhan.CalculationMethodParameters.ummAlQura(),
    'karachi' => adhan.CalculationMethodParameters.karachi(),
    'dubai' => adhan.CalculationMethodParameters.dubai(),
    'kuwait' => adhan.CalculationMethodParameters.kuwait(),
    'qatar' => adhan.CalculationMethodParameters.qatar(),
    'morocco' => adhan.CalculationMethodParameters.morocco(),
    'turkiye' => adhan.CalculationMethodParameters.turkiye(),
    'northAmerica' => adhan.CalculationMethodParameters.northAmerica(),
    _ => adhan.CalculationMethodParameters.muslimWorldLeague(),
  };

  /// The six times of the local [date] (only its year, month and day count) at [place], with the offsets applied.
  static DayTimes day(DateTime date, Place place, PrayerSettings s) {
    final method = s.method == 'auto' ? methodFor(place.country) : s.method;
    final high = place.lat.abs() > kHighLatitude;
    final params = _params(method)
      ..madhab = s.asr == AsrRule.hanafi
          ? adhan.Madhab.hanafi
          : adhan.Madhab.shafi
      ..highLatitudeRule = high
          ? adhan.HighLatitudeRule.seventhOfTheNight
          : adhan.HighLatitudeRule.middleOfTheNight
      ..adjustments = {
        adhan.Prayer.fajr: s.offsets[0],
        adhan.Prayer.sunrise: s.offsets[1],
        adhan.Prayer.dhuhr: s.offsets[2],
        adhan.Prayer.asr: s.offsets[3],
        adhan.Prayer.maghrib: s.offsets[4],
        adhan.Prayer.isha: s.offsets[5],
      };
    final p = adhan.PrayerTimes(
      date: DateTime.utc(date.year, date.month, date.day),
      coordinates: adhan.Coordinates(place.lat, place.lon),
      calculationParameters: params,
    );
    return DayTimes(DateTime(date.year, date.month, date.day), {
      Prayer.fajr: p.fajr.toUtc(),
      Prayer.sunrise: p.sunrise.toUtc(),
      Prayer.dhuhr: p.dhuhr.toUtc(),
      Prayer.asr: p.asr.toUtc(),
      Prayer.maghrib: p.maghrib.toUtc(),
      Prayer.isha: p.isha.toUtc(),
    }, highLatitude: high);
  }

  /// The place's local date at the instant [utc].
  static DateTime localDate(DateTime utc, Place place) {
    if (!tz.timeZoneDatabase.isInitialized) tzdata.initializeTimeZones();
    final l = tz.TZDateTime.from(utc, tz.getLocation(place.zone));
    return DateTime(l.year, l.month, l.day);
  }

  /// The next of the five prayers after [nowUtc], across midnight to the next day's Fajr.
  static (Prayer, DateTime) next(
    DateTime nowUtc,
    Place place,
    PrayerSettings s,
  ) {
    final today = localDate(nowUtc, place);
    for (final d in [today, today.add(const Duration(days: 1))]) {
      final times = day(d, place, s);
      for (final p in kFivePrayers) {
        final at = times.utc[p]!;
        if (at.isAfter(nowUtc)) return (p, at);
      }
    }
    // Only reachable if the day after has no time after now, which cannot happen; Fajr of the day after is a safe answer.
    final after = day(today.add(const Duration(days: 2)), place, s);
    return (Prayer.fajr, after.utc[Prayer.fajr]!);
  }
}
