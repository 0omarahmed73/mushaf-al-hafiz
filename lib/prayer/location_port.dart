// The approximate location, through the app's own channel to the platform LocationManager (feature 014, FR-004,
// FR-005, research D3). Only ACCESS_COARSE_LOCATION, asked only when the reader taps «حدد موقعي»; never the network,
// never in the background. Errors give `denied` or null, never a throw (Principle VII).
import 'package:flutter/services.dart';

enum LocationAsk { granted, denied, deniedForever }

abstract class LocationPort {
  /// Asks for the approximate location permission (shows the system dialog when needed).
  Future<LocationAsk> request();

  /// One reading (latitude, longitude), or null when none comes within 30 seconds or there is no provider.
  Future<(double, double)?> current();

  /// Opens this app's page in the phone's settings.
  Future<void> openSettings();
}

class ChannelLocationPort implements LocationPort {
  const ChannelLocationPort();

  static const MethodChannel _channel = MethodChannel(
    'app.hafiz.mushaf/location',
  );

  @override
  Future<LocationAsk> request() async {
    try {
      return switch (await _channel.invokeMethod<Object?>('request')) {
        'granted' => LocationAsk.granted,
        'deniedForever' => LocationAsk.deniedForever,
        _ => LocationAsk.denied,
      };
    } catch (_) {
      return LocationAsk.denied;
    }
  }

  @override
  Future<(double, double)?> current() async {
    try {
      final v = await _channel.invokeMethod<Object?>('current');
      if (v is List && v.length == 2 && v[0] is num && v[1] is num) {
        return ((v[0] as num).toDouble(), (v[1] as num).toDouble());
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<Object?>('openSettings');
    } catch (_) {}
  }
}

/// For tests: answers as told and counts the requests.
class FakeLocationPort implements LocationPort {
  FakeLocationPort({this.ask = LocationAsk.granted, this.reading});

  LocationAsk ask;
  (double, double)? reading;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<LocationAsk> request() async {
    requests++;
    return ask;
  }

  @override
  Future<(double, double)?> current() async => reading;

  @override
  Future<void> openSettings() async => settingsOpened++;
}
