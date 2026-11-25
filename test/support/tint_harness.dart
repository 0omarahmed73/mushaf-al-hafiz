// Shared by the reader tests of the tint (feature 013, tasks T036 and T037): a reader on an in-memory database with the ayah
// menu, the tint switch provided to it, a repository that tells when the tint's source changed and how often the bookmarks
// were read, and finders of the words the page draws on a colour.
import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/backup/backup.dart';
import 'package:mushaf/backup/backup_service.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/look/look_settings.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/settings/ayah_tint_settings.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:provider/provider.dart';

import 'fake_backup.dart';
import 'fake_share.dart';
import 'reader_harness.dart';

Finder tintKey(String k) => find.byKey(ValueKey(k));

/// Frames drawn since the tests of this file started. A persistent frame callback registered after the binding's own, so it
/// runs when a frame has been built and painted. (A persistent callback cannot be removed; it only counts.)
int framesDrawn = 0;
bool _countingFrames = false;

void countFrames() {
  if (_countingFrames) return;
  _countingFrames = true;
  TestWidgetsFlutterBinding.ensureInitialized().addPersistentFrameCallback(
    (_) => framesDrawn++,
  );
}

/// A repository that records what the reader's controller asks of it.
class TintRepo extends WirdRepository {
  TintRepo(super.db);

  /// Calls of [bookmarkRows]: the one read the tint's source comes from.
  int bookmarkReads = 0;

  /// Every time the set of ayat the reader tints became another set: the frames drawn until then, and the new set. The
  /// controller works the set out here and hands it to the pages in the same step, so the first frame that can show it is
  /// frame `frames + 1`.
  final List<({int frames, Set<AyahRef> marks})> changes = [];
  Set<AyahRef>? _last;

  @override
  Future<List<Bookmark>> bookmarkRows() {
    bookmarkReads++;
    return super.bookmarkRows();
  }

  @override
  Set<AyahRef> ayahMarksOf(Iterable<Bookmark> rows, int? scopeWirdId) {
    final marks = super.ayahMarksOf(rows, scopeWirdId);
    if (_last == null || !setEquals(_last, marks)) {
      _last = marks;
      changes.add((frames: framesDrawn, marks: marks));
    }
    return marks;
  }
}

/// Counts the SELECT statements that read the bookmarks table.
class BookmarkSelects extends QueryInterceptor {
  int count = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.contains('bookmarks')) count++;
    return super.runSelect(executor, statement, args);
  }
}

/// The ids of the words a page draws on [color] (the word's own decoration, radius 4). With [skipOffstage] false the pages
/// the pager keeps built next to the shown one are looked at too.
Set<int> wordsOn(WidgetTester t, Color color, {bool skipOffstage = true}) {
  final out = <int>{};
  final boxes = find.byType(DecoratedBox, skipOffstage: skipOffstage);
  for (final e in boxes.evaluate()) {
    final d = (e.widget as DecoratedBox).decoration;
    if (d is! BoxDecoration || d.color != color) continue;
    expect(
      d.borderRadius,
      BorderRadius.circular(4),
      reason: 'the highlight\'s own word decoration',
    );
    final words = <int>[];
    void visit(Element x) {
      final key = x.widget.key;
      if (x.widget is Text &&
          key is ValueKey<String> &&
          key.value.startsWith('w')) {
        words.add(int.parse(key.value.substring(1)));
      }
      x.visitChildren(visit);
    }

    e.visitChildren(visit);
    expect(words, hasLength(1), reason: 'one decoration per word');
    out.add(words.single);
  }
  return out;
}

/// What a test needs once the reader is shown.
class TintReader {
  TintReader(
    this.db,
    this.repo,
    this.mushaf,
    this.meta,
    this.tint,
    this.look,
    this.files,
    this.selects,
    this.navigator,
    this.errors,
  );

  final AppDatabase db;
  final TintRepo repo;
  final MushafRepository mushaf;
  final MushafMeta meta;

  /// The Settings switch of the tint the reader listens to.
  final AyahTintSettings tint;
  final AppLookSettings look;

  /// The picker of the backup import.
  final FakeBackupFiles files;
  final BookmarkSelects selects;
  final GlobalKey<NavigatorState> navigator;
  final List<String> errors;

  /// The errors that are not the bottom bar's known overflow at 320 dp (feature 006 T020).
  List<String> get unexpectedErrors => [
    for (final e in errors)
      if (!e.contains('_BottomBar')) e,
  ];

  Color get tintColor => look.pageLook.bookmarkTint;
  Color get highlightColor => look.pageLook.highlight;

  /// The words the shown page draws on the tint.
  Set<int> tinted(WidgetTester t, {bool skipOffstage = true}) =>
      wordsOn(t, tintColor, skipOffstage: skipOffstage);

  /// The words the shown page draws on the temporary highlight.
  Set<int> highlighted(WidgetTester t) => wordsOn(t, highlightColor);

  Future<PageData> page(WidgetTester t, int page) async =>
      (await t.runAsync(() => mushaf.loadPage(page)))!;

  /// The ids of the words of [refs] on [page].
  Future<Set<int>> ids(WidgetTester t, int page, Iterable<AyahRef> refs) async {
    final data = await this.page(t, page);
    return {for (final r in refs) ...wordIdsOfAyah(data, r)};
  }

  /// Every word id of [page].
  Future<Set<int>> allIds(WidgetTester t, int page) async => {
    for (final l in (await this.page(t, page)).lines)
      for (final w in l.words) w.id,
  };

  /// Long presses the first word of [ref] on [page] and lets the ayah sheet slide in.
  Future<void> longPressAyah(
    WidgetTester t,
    AyahRef ref, {
    required int page,
  }) async {
    final first = (await ids(t, page, [ref])).toList()..sort();
    expect(first, isNotEmpty, reason: '${ref.key} is not on page $page');
    await t.longPress(tintKey('w${first.first}'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
  }

  /// Runs [action], then draws frames one by one and checks that the first frame after the reader's set of tinted ayat
  /// became [marks] already draws exactly [expected] on the tint, and every frame after it too (spec FR-026, SC-016).
  /// [action] must not draw that frame itself.
  Future<void> expectFirstFrame(
    WidgetTester t, {
    required Future<void> Function() action,
    required Set<AyahRef> marks,
    required Set<int> expected,
    bool skipOffstage = true,
    int frames = 50,
  }) async {
    final from = repo.changes.length;
    await action();
    final seen = <int, Set<int>>{};
    for (var i = 0; i < frames; i++) {
      await t.pump(const Duration(milliseconds: 16));
      seen[framesDrawn] = tinted(t, skipOffstage: skipOffstage);
      // Real time for anything that does not run on the test clock; it draws no frame.
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 2)),
      );
    }
    final after = repo.changes.skip(from).toList();
    final change = after.where((c) => setEquals(c.marks, marks)).firstOrNull;
    expect(
      change,
      isNotNull,
      reason:
          'the set of tinted ayat never became $marks (changes: ${[for (final c in after) c.marks]})',
    );
    final first = change!.frames + 1;
    expect(
      seen.containsKey(first),
      isTrue,
      reason:
          'frame $first (the first after the change) was not drawn by this helper: frames ${seen.keys.toList()}',
    );
    for (final entry in seen.entries) {
      if (entry.key < first) continue;
      expect(
        entry.value,
        expected,
        reason:
            'frame ${entry.key} (${entry.key - first} after the first frame that follows the change)',
      );
    }
  }

  Future<List<Bookmark>> bookmarks(WidgetTester t) async =>
      (await t.runAsync(() => db.select(db.bookmarks).get()))!;
}

/// A reader on [startPage], following the default wird («الورد اليومي») unless [noWird] (the wird is deleted: browse mode
/// with no wird) or [browseWithWird] (a jump to [startPage] through «الانتقال إلى صفحة»: browse mode with a wird). [seed] runs
/// before the reader is pumped, with the active wird's id. The tint switch is provided to the reader the way the app
/// provides the text size (a `ListenableProvider<AyahTintSettings?>` above it).
Future<TintReader> pumpTintReader(
  WidgetTester t, {
  int startPage = 48,
  LookChoice look = LookChoice.emerald,
  Size screen = const Size(412, 915),
  bool noWird = false,
  bool browseWithWird = false,
  bool withBackup = false,
  QueryInterceptor? interceptor,
  Iterable<int> alsoLoad = const [],
  Future<void> Function(
    AppDatabase db,
    TintRepo repo,
    MushafMeta meta,
    int? wirdId,
  )?
  seed,
}) async {
  countFrames();
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
  final selects = BookmarkSelects();
  QueryExecutor executor = NativeDatabase.memory().interceptWith(selects);
  if (interceptor != null) executor = executor.interceptWith(interceptor);
  final db = AppDatabase(executor);
  final repo = TintRepo(db);
  final size = TextSizeSettings(repo);
  final lookSettings = AppLookSettings(repo);
  final tint = AyahTintSettings(repo);
  addTearDown(() async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    size.dispose();
    lookSettings.dispose();
    tint.dispose();
    await t.runAsync(db.close);
  });
  final mushaf = MushafRepository(rootBundle);
  final files = FakeBackupFiles();
  final navigator = GlobalKey<NavigatorState>();
  late MushafMeta meta;
  final opensOn = browseWithWird
      ? (startPage == 604 ? 603 : startPage + 1)
      : startPage;
  await t.runAsync(() async {
    meta = await mushaf.loadMeta();
    // Pages the reader may go to later are loaded in real time first (rootBundle remembers the Future of a load started in
    // the fake-async zone, and a later test that asks for that page would wait on it forever).
    for (final around in {startPage, opensOn, ...alsoLoad}) {
      for (var p = around - 3; p <= around + 4; p++) {
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
    if (seed != null) await seed(db, repo, meta, (await repo.activeWird())?.id);
    if (look != LookChoice.emerald) await lookSettings.set(look);
    await size.load();
    await tint.load();
  });
  await t.pumpWidget(
    MushafApp(
      wirdRepository: repo,
      mushafRepository: mushaf,
      ayahRepository: AyahRepository(rootBundle),
      shareService: FakeShareService(),
      backup: withBackup
          ? Backup(
              service: BackupService(db, meta: meta),
              files: files,
            )
          : null,
      textSize: size,
      appLook: lookSettings,
      navigatorKey: navigator,
      home: ListenableProvider<AyahTintSettings?>.value(
        value: tint,
        child: const ReaderScreen(),
      ),
    ),
  );
  await settleReader(t);
  if (browseWithWird) {
    await goToPage(t, startPage);
  }
  return TintReader(
    db,
    repo,
    mushaf,
    meta,
    tint,
    lookSettings,
    files,
    selects,
    navigator,
    errors,
  );
}

/// «الانتقال إلى صفحة» through the page number the page draws: browse mode on [page].
Future<void> goToPage(WidgetTester t, int page) async {
  await t.tap(tintKey('page-number'));
  await settleReader(t);
  await t.enterText(tintKey('goto-field'), '$page');
  await t.tap(tintKey('goto-go'));
  await settleReader(t);
}

/// The page number the reader shows.
String tintShownPage(WidgetTester t) =>
    t.widget<Text>(tintKey('page-number')).data!;

/// Seeds [total] ayah bookmarks of the scope [wirdId] through the repository: every ayah of [pages] first, then ayat from page
/// 100 on until there are [total]. Call it before the reader is pumped (in real time). Returns the ayat.
Future<Set<AyahRef>> seedManyAyahBookmarks(
  WirdRepository repo,
  int? wirdId, {
  required Iterable<int> pages,
  int total = 200,
}) async {
  final mushaf = MushafRepository(rootBundle);
  final meta = await mushaf.loadMeta();
  final refs = <AyahRef>{};
  Future<void> take(int page, {int? limit}) async {
    for (final line in (await mushaf.loadPage(page)).lines) {
      for (final w in line.words) {
        if (limit != null && refs.length >= limit) return;
        refs.add(AyahRef(w.surah, w.ayah));
      }
    }
  }

  for (final p in pages) {
    await take(p);
  }
  for (var p = 100; refs.length < total && p <= 604; p++) {
    if (!pages.contains(p)) await take(p, limit: total);
  }
  for (final ref in refs) {
    await repo.toggleAyahBookmark(
      ref,
      page: meta.pageOfAyah(ref.surah, ref.ayah),
      wirdId: wirdId,
    );
  }
  return refs;
}
