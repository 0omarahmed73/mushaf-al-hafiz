// Shared set-up for the prayer screen's widget tests (feature 014).
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/prayer/cities.dart';
import 'package:mushaf/prayer/location_port.dart';
import 'package:mushaf/prayer/prayer_screen.dart';
import 'package:mushaf/prayer/prayer_settings.dart';
import 'package:mushaf/reminders/reminder_scheduler.dart';
import 'package:mushaf/reminders/reminder_service.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../support/fake_reminders.dart';

const Place kCairo = Place(
  lat: 30.063,
  lon: 31.25,
  zone: 'Africa/Cairo',
  name: 'القاهرة',
  source: PlaceSource.list,
  country: 'EG',
);

/// An instant given in Cairo's local time.
DateTime cairoTime(int y, int m, int d, int h, [int min = 0, int s = 0]) {
  if (!tz.timeZoneDatabase.isInitialized) tzdata.initializeTimeZones();
  return tz.TZDateTime(
    tz.getLocation('Africa/Cairo'),
    y,
    m,
    d,
    h,
    min,
    s,
  ).toUtc();
}

class PrayerRig {
  PrayerRig(this.repo, this.location, this.service, this.now);

  final WirdRepository repo;
  final FakeLocationPort location;
  final FakeReminderService service;

  /// The clock the screen reads; tests move it.
  DateTime now;

  Future<PrayerSettings> settings(WidgetTester t) async => PrayerSettings.read(
    (await t.runAsync(repo.prayerEntries))!,
    phoneZone: 'Africa/Cairo',
  );
}

CityIndex? _cities;

/// The prayer screen alone, on an in-memory database with [initial] settings, at [size] with [textScale].
Future<PrayerRig> pumpPrayer(
  WidgetTester t, {
  PrayerSettings? initial,
  AppLook look = AppLook.emerald,
  Size size = const Size(412, 915),
  double textScale = 1,
  DateTime? now,
  String phoneZone = 'Africa/Cairo',
  FakeLocationPort? location,
  bool exact = true,
  bool notificationsAllowed = true,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  if (textScale != 1) {
    t.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  }
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() async {
    await t.pumpWidget(const SizedBox());
    await t.runAsync(db.close);
  });
  final repo = WirdRepository(db);
  _cities ??= await t.runAsync(() => CityIndex.load(rootBundle));
  if (initial != null) await t.runAsync(() => repo.setPrayerSettings(initial));
  final service = FakeReminderService()
    ..exact = exact
    ..allowed = notificationsAllowed;
  final rig = PrayerRig(
    repo,
    location ?? FakeLocationPort(),
    service,
    now ?? cairoTime(2026, 3, 1, 13),
  );
  final reminders = Reminders(
    service: service,
    scheduler: ReminderScheduler(repo, service),
    taps: NotificationTaps(),
  );
  await t.pumpWidget(
    MultiProvider(
      providers: [
        Provider<WirdRepository>.value(value: repo),
        Provider<Reminders?>.value(value: reminders),
      ],
      child: MaterialApp(
        theme: buildAppTheme(look: look),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: PrayerScreen(
            location: rig.location,
            loadCities: () async => _cities!,
            clock: () => rig.now,
            phoneZone: () async => phoneZone,
          ),
        ),
      ),
    ),
  );
  await settlePrayer(t);
  return rig;
}

/// Lets database reads and writes (real async) finish.
Future<void> settlePrayer(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await t.pump(const Duration(milliseconds: 50));
  }
}
