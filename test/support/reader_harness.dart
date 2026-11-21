import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import 'fake_share.dart';

/// Lets real asset and font loading finish (they run outside the fake-async test clock).
Future<void> settleReader(WidgetTester t) async {
  for (var i = 0; i < 16; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await t.pump(const Duration(milliseconds: 60));
  }
}

/// A reader opened on [startPage] of an in-memory database, with the text size at [percent].
class SizedReader {
  SizedReader(this.repo, this.size);

  final WirdRepository repo;
  final TextSizeSettings size;

  /// Changes the size while the reader is shown, as Settings does.
  Future<void> setSize(WidgetTester t, int percent) async {
    await t.runAsync(() => size.set(percent));
    await t.pump();
  }
}

Future<SizedReader> pumpSizedReader(
  WidgetTester t, {
  int startPage = 50,
  int percent = 100,
  Size screen = const Size(412, 915),
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
  final size = TextSizeSettings(repo);
  addTearDown(size.dispose);
  final mushaf = MushafRepository(rootBundle);
  await t.runAsync(() async {
    await mushaf.loadMeta();
    // Pages the reader may ask for are loaded in real time first (rootBundle remembers Futures).
    for (var p = startPage - 2; p <= startPage + 2; p++) {
      if (p >= 1 && p <= 604) await mushaf.loadPage(p);
    }
    await repo.ensureDefaults();
    final id = (await repo.activeWird())!.id;
    await repo.setPage(id, startPage);
    await size.set(percent);
  });
  await t.pumpWidget(
    MushafApp(
      wirdRepository: repo,
      mushafRepository: mushaf,
      ayahRepository: AyahRepository(rootBundle),
      shareService: FakeShareService(),
      textSize: size,
      home: const ReaderScreen(),
    ),
  );
  await settleReader(t);
  return SizedReader(repo, size);
}
