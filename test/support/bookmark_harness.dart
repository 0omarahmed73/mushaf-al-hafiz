// Shared by the bookmark icon tests (feature 006): a reader on an in-memory database in the chosen look, window size,
// system text scale and reading size, either following a wird or browsing, plus a few finders.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/look/look_settings.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import 'fake_share.dart';
import 'reader_harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

/// What a test needs after the reader is shown.
class BookmarkReader {
  BookmarkReader(this.repo, this.size, this.look, this.errors);

  final WirdRepository repo;
  final TextSizeSettings size;
  final AppLookSettings look;

  /// Every Flutter error reported while the reader ran, as text with the widgets that caused it.
  final List<String> errors;

  /// The errors that are NOT the bottom bar's overflow at 320 dp, which exists since feature 001 (found while
  /// measuring the baseline of feature 006, tasks.md T020): a test of the top bar must see none of these.
  List<String> get unexpectedErrors => [
    for (final e in errors)
      if (!e.contains('_BottomBar')) e,
  ];

  /// The errors raised by a widget written inside `_TopBar` (the lines of its class in reader_screen.dart): the only
  /// ones this feature can be blamed for. With a 2x system font the bottom bar and the page's own text overflow too,
  /// which exists since features 001 and 002 (T020), so the 2x tests look at these.
  List<String> get topBarErrors {
    final lines = File('lib/mushaf/reader_screen.dart').readAsLinesSync();
    final start = lines.indexWhere((l) => l.startsWith('class _TopBar '));
    var end = lines.indexWhere((l) => l.startsWith('class '), start + 1);
    if (end < 0) end = lines.length;
    final where = RegExp(r'reader_screen\.dart:(\d+):\d+');
    return [
      for (final e in errors)
        if (where.allMatches(e).any((m) {
          final line = int.parse(m.group(1)!);
          return line > start && line <= end;
        }))
          e,
    ];
  }
}

/// A reader on [startPage]. By default it follows the default wird («الورد اليومي»); with [noWird] the wird is deleted
/// (browse mode with no wird). [browseWithWird] then jumps to [startPage] + 1 through «الانتقال إلى صفحة», which is
/// browse mode with a wird, the case where «اجعلها موضعي» is shown.
Future<BookmarkReader> pumpBookmarkReader(
  WidgetTester t, {
  int startPage = 50,
  LookChoice look = LookChoice.emerald,
  Size screen = const Size(412, 915),
  double textScale = 1.0,
  int percent = 100,
  bool noWird = false,
  bool browseWithWird = false,
  WirdRepository Function(AppDatabase db)? makeRepo,
  Future<void> Function(WirdRepository repo, int? wirdId)? seed,
}) async {
  t.view.physicalSize = screen;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final errors = <String>[];
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.toString(minLevel: DiagnosticLevel.debug);
    errors.add(text);
    // A layout overflow is only recorded (the bottom bar's, at 320 dp, is known: T020); anything else, a failed
    // expect() included, goes on to the framework so the test fails with its real message.
    if (!(details.exception is FlutterError && text.contains('overflowed'))) {
      previousOnError?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = previousOnError);
  final db = AppDatabase(NativeDatabase.memory());
  final repo = makeRepo == null ? WirdRepository(db) : makeRepo(db);
  final size = TextSizeSettings(repo);
  final lookSettings = AppLookSettings(repo);
  addTearDown(() async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    size.dispose();
    lookSettings.dispose();
    await t.runAsync(db.close);
  });
  final mushaf = MushafRepository(rootBundle);
  await t.runAsync(() async {
    await mushaf.loadMeta();
    for (var p = startPage - 2; p <= startPage + 3; p++) {
      if (p >= 1 && p <= 604) await mushaf.loadPage(p);
    }
    await repo.ensureDefaults();
    final id = (await repo.activeWird())!.id;
    if (noWird) {
      await repo.delete(id);
      await repo.setLastViewedPage(startPage);
    } else {
      await repo.setPage(id, startPage);
    }
    await size.set(percent);
    if (seed != null) await seed(repo, (await repo.activeWird())?.id);
    if (look != LookChoice.emerald) await lookSettings.set(look);
  });
  await t.pumpWidget(
    MushafApp(
      wirdRepository: repo,
      mushafRepository: mushaf,
      ayahRepository: null,
      shareService: FakeShareService(),
      textSize: size,
      appLook: lookSettings,
      home: textScale == 1.0
          ? const ReaderScreen()
          : Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(textScale)),
                child: const ReaderScreen(),
              ),
            ),
    ),
  );
  await settleReader(t);
  if (browseWithWird) {
    await jumpToPage(t, startPage + 1);
  }
  return BookmarkReader(repo, size, lookSettings, errors);
}

/// «الانتقال إلى صفحة» through the page number the page draws: browse mode on [page].
Future<void> jumpToPage(WidgetTester t, int page) async {
  await t.tap(key('page-number'));
  await settleReader(t);
  await t.enterText(key('goto-field'), '$page');
  await t.tap(key('goto-go'));
  await settleReader(t);
}

String shownPage(WidgetTester t) => t.widget<Text>(key('page-number')).data!;
