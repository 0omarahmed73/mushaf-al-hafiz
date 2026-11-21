// Shared by the khatm reader tests (feature 005): finding the dua, dragging at page 604, a reader in browse mode, and
// what «آمين» and back must not change.
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import 'reader_harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

String pageNumber(WidgetTester t) => t.widget<Text>(key('page-number')).data!;

Future<void> drag(
  WidgetTester t,
  double dx, {
  Offset from = const Offset(200, 400),
}) async {
  await t.dragFrom(from, Offset(dx, 0));
  await settleReader(t);
}

Future<void> flingForward(WidgetTester t) async {
  await t.fling(find.byType(PageView), const Offset(400, 0), 1500);
  await settleReader(t);
}

bool get duaOpen => key('khatm-amen').evaluate().isNotEmpty;

/// A reader with no wird at all, so it is in browse mode on [startPage] (the last viewed page).
Future<WirdRepository> pumpBrowseReader(
  WidgetTester t, {
  required int startPage,
}) async {
  t.view.physicalSize = const Size(412, 915);
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
    for (var p = startPage - 2; p <= startPage + 2; p++) {
      if (p >= 1 && p <= 604) await mushaf.loadPage(p);
    }
    await repo.ensureDefaults();
    await repo.delete((await repo.activeWird())!.id);
    await repo.setLastViewedPage(startPage);
  });
  await t.pumpWidget(
    MushafApp(
      wirdRepository: repo,
      mushafRepository: mushaf,
      textSize: size,
      home: const ReaderScreen(),
    ),
  );
  await settleReader(t);
  return repo;
}

/// What «آمين» must not change: the active wird's khatma count, today's portions with their done marks, and the
/// bookmarks.
Future<List<Object?>> untouched(WidgetTester t, WirdRepository repo) async {
  return (await t.runAsync(() async {
    final wird = await repo.activeWird();
    final today = await repo.watchTodayEntries().first;
    final bookmarks = await repo.watchBookmarks().first;
    return <Object?>[
      wird?.khatmaCount,
      [
        for (final e in today)
          (e.wird.id, e.day.startPage, e.day.endPage, e.done),
      ],
      [
        for (final b in bookmarks)
          (b.bookmark.id, b.bookmark.page, b.bookmark.note),
      ],
    ];
  }))!;
}

/// «آمين» is the last item of a text that scrolls: scroll to it as the reader does, then tap it and let the reader
/// settle (the confirmed wording is longer than one screen).
Future<void> tapAmen(WidgetTester t) async {
  await t.ensureVisible(key('khatm-amen'));
  await t.pump();
  await t.tap(key('khatm-amen'));
  await settleReader(t);
}
