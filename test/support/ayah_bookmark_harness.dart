// Shared by the ayah bookmark tests (feature 013): ayah bookmarks seeded by ayah, a reader on an in-memory database with the
// ayah menu (the real ayah assets and a fake share service), in a look, a size and a scope, and the finders of the sheet's
// two rows and of the message.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/look/look_settings.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import 'fake_share.dart';
import 'motion_probe.dart' show FileBundle;
import 'reader_harness.dart';

Finder byKey(String k) => find.byKey(ValueKey(k));

/// The sheet's bookmark row and note row.
final Finder ayahBookmarkRow = byKey('ayah-bookmark');
final Finder ayahNoteRow = byKey('ayah-note');

/// The floating message showing [text].
Finder message(String text) =>
    find.descendant(of: find.byType(SnackBar), matching: find.text(text));

/// The fixed edition's meta, read from the project's own assets (no widget binding needed).
Future<MushafMeta> realMeta() => MushafRepository(FileBundle()).loadMeta();

/// An ayah bookmark written straight to the table, on the page where the ayah begins (as the app makes them).
Future<int> seedAyahBookmark(
  AppDatabase db,
  MushafMeta meta,
  AyahRef ref, {
  int? wirdId,
  String? note,
  DateTime? at,
}) => db
    .into(db.bookmarks)
    .insert(
      BookmarksCompanion.insert(
        page: meta.pageOfAyah(ref.surah, ref.ayah),
        wirdId: Value(wirdId),
        note: Value(note),
        surah: Value(ref.surah),
        ayah: Value(ref.ayah),
        createdAt: at == null ? const Value.absent() : Value(at),
      ),
    );

/// Every bookmark, oldest first.
Future<List<Bookmark>> allBookmarks(AppDatabase db) =>
    db.select(db.bookmarks).get();

/// What a test needs once the reader is shown.
class AyahBookmarkReader {
  AyahBookmarkReader(
    this.db,
    this.repo,
    this.mushaf,
    this.meta,
    this.size,
    this.look,
    this.errors,
  );

  final AppDatabase db;
  final WirdRepository repo;
  final MushafRepository mushaf;
  final MushafMeta meta;
  final TextSizeSettings size;
  final AppLookSettings look;

  /// Every Flutter error reported while the reader ran.
  final List<String> errors;

  /// The errors that are not the bottom bar's known overflow at 320 dp (feature 006 T020).
  List<String> get unexpectedErrors => [
    for (final e in errors)
      if (!e.contains('_BottomBar')) e,
  ];

  /// The words of [page] (already loaded by the harness for the pages around the start).
  Future<PageData> page(WidgetTester t, int page) async =>
      (await t.runAsync(() => mushaf.loadPage(page)))!;

  /// Long presses the first word of [ref] on [page] and lets the ayah sheet slide in.
  Future<void> longPressAyah(
    WidgetTester t,
    AyahRef ref, {
    required int page,
  }) async {
    final data = await this.page(t, page);
    final ids = wordIdsOfAyah(data, ref).toList()..sort();
    expect(ids, isNotEmpty, reason: '${ref.key} is not on page $page');
    await t.longPress(byKey('w${ids.first}'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
  }

  /// Taps [row] of the open sheet and lets the write, the sheet's close and the message finish.
  Future<void> tapRow(WidgetTester t, Finder row) async {
    await t.tap(row);
    await settleReader(t);
  }

  Future<List<Bookmark>> bookmarks(WidgetTester t) async =>
      (await t.runAsync(() => allBookmarks(db)))!;
}

/// A reader on [startPage], following the default wird («الورد اليومي») unless [noWird] (the wird is deleted: browse mode
/// with no wird) or [browseWithWird] (a jump to [startPage] through «الانتقال إلى صفحة», browse mode with a wird; the page
/// shown is then [startPage] itself). [seed] runs before the reader is pumped, with the active wird's id.
Future<AyahBookmarkReader> pumpAyahBookmarkReader(
  WidgetTester t, {
  int startPage = 48,
  LookChoice look = LookChoice.emerald,
  Size screen = const Size(412, 915),
  double textScale = 1.0,
  int percent = 100,
  bool noWird = false,
  bool browseWithWird = false,
  WirdRepository Function(AppDatabase db)? makeRepo,
  Iterable<int> alsoLoad = const [],
  Future<void> Function(
    AppDatabase db,
    WirdRepository repo,
    MushafMeta meta,
    int? wirdId,
  )?
  seed,
}) async {
  t.view.physicalSize = screen;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final errors = <String>[];
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.toString(minLevel: DiagnosticLevel.debug);
    errors.add(text);
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
  late MushafMeta meta;
  final opensOn = browseWithWird
      ? (startPage == 604 ? 603 : startPage + 1)
      : startPage;
  await t.runAsync(() async {
    meta = await mushaf.loadMeta();
    // Pages the reader may go to later are loaded in real time first: rootBundle remembers the Future of a load started
    // in the fake-async zone, and a later test that asks for that page would wait on it forever.
    for (final around in {startPage, opensOn, ...alsoLoad}) {
      for (var p = around - 2; p <= around + 3; p++) {
        if (p >= 1 && p <= 604) await mushaf.loadPage(p);
      }
    }
    await repo.ensureDefaults();
    final id = (await repo.activeWird())!.id;
    if (noWird) {
      await repo.delete(id);
      await repo.setLastViewedPage(startPage);
    } else {
      await repo.setPage(id, opensOn);
    }
    await size.set(percent);
    if (seed != null) await seed(db, repo, meta, (await repo.activeWird())?.id);
    if (look != LookChoice.emerald) await lookSettings.set(look);
  });
  await t.pumpWidget(
    MushafApp(
      wirdRepository: repo,
      mushafRepository: mushaf,
      ayahRepository: AyahRepository(rootBundle),
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
    await t.tap(byKey('page-number'));
    await settleReader(t);
    await t.enterText(byKey('goto-field'), '$startPage');
    await t.tap(byKey('goto-go'));
    await settleReader(t);
  }
  return AyahBookmarkReader(db, repo, mushaf, meta, size, lookSettings, errors);
}

/// The page number the reader shows.
String shownPage(WidgetTester t) => t.widget<Text>(byKey('page-number')).data!;
