// The reader with the large-ayah settings provided (feature 015): an in-memory database, the real Mushaf assets and fonts,
// the ayah menu, the tint switch and the look.
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/large_ayah/large_ayah_screen.dart';
import 'package:mushaf/large_ayah/large_ayah_settings.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/look/look_settings.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/settings/ayah_tint_settings.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import 'fake_share.dart';
import 'reader_harness.dart';

class LargeReader {
  LargeReader(this.db, this.repo, this.settings, this.tint, this.look, this.mushaf);

  final AppDatabase db;
  final WirdRepository repo;
  final LargeAyahSettings settings;
  final AyahTintSettings tint;
  final AppLookSettings look;
  final MushafRepository mushaf;

  /// The position of the active wird.
  Future<int> wirdPage(WidgetTester t) async => (await t.runAsync(() async => (await repo.activeWird())!.currentPage))!;
}

/// The header text of the large-ayah screen shown (the one on stage).
String largeHeader(WidgetTester t) => t.widget<Text>(find.byKey(const ValueKey('large-header'))).data!;

/// The large-ayah screen on stage.
LargeAyahScreen shownLargeScreen(WidgetTester t) => t.widget<LargeAyahScreen>(find.byType(LargeAyahScreen));

/// One swipe to the next screen (left to right, as a Mushaf page).
Future<void> nextScreen(WidgetTester t, {double width = 412}) async {
  await t.drag(find.byType(LargeAyahScreen), Offset(width * 0.8, 0));
  await settleReader(t);
}

Future<void> previousScreen(WidgetTester t, {double width = 412}) async {
  await t.drag(find.byType(LargeAyahScreen), Offset(-width * 0.8, 0));
  await settleReader(t);
}

Future<LargeReader> pumpLargeReader(
  WidgetTester t, {
  int startPage = 50,
  bool on = false,
  int count = 1,
  int sizeStep = 1,
  AyahRef? at,
  LookChoice look = LookChoice.emerald,
  Size screen = const Size(412, 915),
  bool browsing = false,
}) async {
  t.view.physicalSize = screen;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(db.close);
  });
  final repo = WirdRepository(db);
  final mushaf = MushafRepository(rootBundle);
  final meta = (await t.runAsync(mushaf.loadMeta))!;
  final settings = LargeAyahSettings(repo, meta: meta);
  final tint = AyahTintSettings(repo);
  final lookSettings = AppLookSettings(repo);
  final size = TextSizeSettings(repo);
  addTearDown(settings.dispose);
  addTearDown(tint.dispose);
  addTearDown(lookSettings.dispose);
  addTearDown(size.dispose);
  await t.runAsync(() async {
    for (var p = startPage - 2; p <= startPage + 2; p++) {
      if (p >= 1 && p <= 604) await mushaf.loadPage(p);
    }
    await repo.ensureDefaults();
    final id = (await repo.activeWird())!.id;
    await repo.setPage(id, startPage);
    if (browsing) await repo.setLastViewedPage(startPage);
    await settings.setOn(on);
    await settings.setCount(count);
    await settings.setSizeStep(sizeStep);
    if (at != null) await settings.setAt(at);
    await lookSettings.set(look);
    await tint.load();
  });
  await t.pumpWidget(
    MushafApp(
      wirdRepository: repo,
      mushafRepository: mushaf,
      ayahRepository: AyahRepository(rootBundle),
      shareService: FakeShareService(),
      textSize: size,
      ayahTint: tint,
      appLook: lookSettings,
      largeAyah: settings,
      home: const ReaderScreen(),
    ),
  );
  await settleReader(t);
  await settleReader(t);
  return LargeReader(db, repo, settings, tint, lookSettings, mushaf);
}
