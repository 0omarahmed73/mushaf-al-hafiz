// The prayer screen's first steps (feature 014, US1, FR-001, FR-003, FR-004, FR-004a, FR-004b, contracts/ui.md):
// off, then the place by the approximate location or the city list. The location is asked only on the tap.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/prayer/location_port.dart';
import 'package:mushaf/prayer/prayer_settings.dart';

import 'prayer_harness.dart';

Finder _k(String key) => find.byKey(ValueKey(key));

void main() {
  testWidgets(
    'off: the intro and the button; nothing asked, nothing scheduled',
    (t) async {
      final rig = await pumpPrayer(t);
      expect(_k('prayer-screen'), findsOneWidget);
      expect(_k('prayer-off'), findsOneWidget);
      expect(find.text('تشغيل مواقيت الصلاة'), findsOneWidget);
      expect(rig.location.requests, 0);
      expect(rig.service.current, isEmpty);
    },
  );

  testWidgets(
    'turning on leads to the place step, and the location is not asked yet',
    (t) async {
      final rig = await pumpPrayer(t);
      await t.tap(_k('prayer-enable'));
      await settlePrayer(t);
      expect(_k('prayer-place'), findsOneWidget);
      expect((await rig.settings(t)).enabled, isTrue);
      expect(rig.location.requests, 0);
    },
  );

  testWidgets(
    '«حدد موقعي» granted: the nearest city with «تقريبًا» and the phone zone',
    (t) async {
      final rig = await pumpPrayer(
        t,
        initial: const PrayerSettings(enabled: true),
        location: FakeLocationPort(
          ask: LocationAsk.granted,
          reading: (30.05, 31.24),
        ),
        phoneZone: 'Africa/Cairo',
      );
      await t.tap(_k('place-locate'));
      await settlePrayer(t);
      expect(rig.location.requests, 1);
      expect(_k('prayer-day'), findsOneWidget);
      // Design A (2026-11-26): «تقريبًا» is its own small text after the name.
      expect(find.text('القاهرة'), findsOneWidget);
      expect(find.text('تقريبًا'), findsOneWidget);
      final place = (await rig.settings(t)).place!;
      expect(place.source, PlaceSource.location);
      expect(place.zone, 'Africa/Cairo');
      expect(place.country, 'EG');
      expect((place.lat, place.lon), (30.05, 31.24));
    },
  );

  testWidgets(
    'denied: the failure line and the list; deniedForever adds the settings button',
    (t) async {
      final rig = await pumpPrayer(
        t,
        initial: const PrayerSettings(enabled: true),
        location: FakeLocationPort(ask: LocationAsk.denied),
      );
      await t.tap(_k('place-locate'));
      await settlePrayer(t);
      expect(_k('place-failed'), findsOneWidget);
      expect(_k('city-search'), findsOneWidget);
      expect(_k('place-settings'), findsNothing);

      rig.location.ask = LocationAsk.deniedForever;
      await t.tap(_k('place-locate'));
      await settlePrayer(t);
      expect(_k('place-settings'), findsOneWidget);
      await t.tap(_k('place-settings'));
      expect(rig.location.settingsOpened, 1);
    },
  );

  testWidgets('granted but no reading: the failure line and the list', (
    t,
  ) async {
    await pumpPrayer(
      t,
      initial: const PrayerSettings(enabled: true),
      location: FakeLocationPort(ask: LocationAsk.granted, reading: null),
    );
    await t.tap(_k('place-locate'));
    await settlePrayer(t);
    expect(_k('place-failed'), findsOneWidget);
    expect(_k('city-search'), findsOneWidget);
  });

  testWidgets(
    'the list: search without hamza and pick a city; its own zone, source list',
    (t) async {
      final rig = await pumpPrayer(
        t,
        initial: const PrayerSettings(enabled: true),
        phoneZone: 'Europe/London',
      );
      await t.tap(_k('place-list'));
      await settlePrayer(t);
      await t.enterText(_k('city-search'), 'الاسكندريه');
      await settlePrayer(t);
      await t.tap(find.text('الإسكندرية').first);
      await settlePrayer(t);
      expect(_k('prayer-day'), findsOneWidget);
      final place = (await rig.settings(t)).place!;
      expect(place.name, 'الإسكندرية');
      expect(place.source, PlaceSource.list);
      expect(place.zone, 'Africa/Cairo');
      expect(rig.location.requests, 0);
    },
  );
}
