// A reader on an in-memory database for the feature 010 measurements: like `reader_harness.dart` (which stays as it is)
// but it can open without a wird (browse mode) and it gives the rebuild probe and a swipe that is driven by hand.
import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import 'motion_probe.dart';

/// Lets real asset, font and database work finish (it runs outside the fake-async test clock).
Future<void> settleMotion(WidgetTester t, {int rounds = 12}) async {
  for (var i = 0; i < rounds; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await t.pump(const Duration(milliseconds: 60));
  }
}

/// Makes every database call take [delay] of (fake) test time, like the round trip to the database isolate of the phone
/// plus the disk. Frames that are pumped advance the clock, so the answers arrive during later frames, as they do in the
/// app; without it the in-memory database answers inside the same frame and every rebuild a write causes folds into one.
class DelayedDatabase extends QueryInterceptor {
  DelayedDatabase(this.delay);

  final Duration delay;

  Future<T> _later<T>(Future<T> Function() run) async {
    await Future<void>.delayed(delay);
    return run();
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _later(() => super.runSelect(executor, statement, args));

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _later(() => super.runInsert(executor, statement, args));

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _later(() => super.runUpdate(executor, statement, args));

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _later(() => super.runDelete(executor, statement, args));

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _later(() => super.runCustom(executor, statement, args));
}

/// What one swipe did, frame by frame.
class SwipeTrace {
  SwipeTrace(this.frameMs, this.pageRebuilds, this.screenRebuilds);

  /// Milliseconds each pumped frame took.
  final List<double> frameMs;

  /// `MushafPage` rebuilds and whole-screen (`Scaffold`) rebuilds in each pumped frame. Before feature 010 the reader's
  /// outer `ListenableBuilder` rebuilt the `Scaffold` on every controller change; it is the `Scaffold` that is counted now.
  final List<int> pageRebuilds;
  final List<int> screenRebuilds;

  int get pagesTotal => pageRebuilds.fold(0, (a, b) => a + b);
  int get screenTotal => screenRebuilds.fold(0, (a, b) => a + b);

  /// Frames in which the whole screen was rebuilt.
  int get framesWithScreenRebuild => screenRebuilds.where((n) => n > 0).length;
}

class MotionReader {
  MotionReader(this.repo, this.probe);

  final WirdRepository repo;
  final RebuildProbe probe;

  /// One finger drag that turns to the next page (a finger moving left to right), by hand so the rebuilds can be
  /// told apart: finger down, dragging, past the middle (the pager reports the new page), settling, and the late
  /// frames after the database answered.
  Future<SwipeTrace> swipeToNext(WidgetTester t, {String prefix = ''}) async {
    final frameMs = <double>[];
    final pages = <int>[];
    final screens = <int>[];
    Future<void> frame([int step = 16]) async {
      final pagesBefore = probe.total('MushafPage');
      final screensBefore = probe.total('Scaffold');
      final s = Stopwatch()..start();
      await t.pump(Duration(milliseconds: step));
      s.stop();
      frameMs.add(ms(s));
      pages.add(probe.total('MushafPage') - pagesBefore);
      screens.add(probe.total('Scaffold') - screensBefore);
    }

    final centre = t.getCenter(find.byType(PageView));
    probe.phase = '${prefix}a-finger-down';
    final g = await t.startGesture(centre - const Offset(150, 0));
    // A real finger starts in small steps, so the pager's drag (18 px of slop) wins the gesture arena against the
    // page's scale gesture (36 px) as it does on the phone; one big first move would hand the gesture to the zoom.
    for (var i = 0; i < 5; i++) {
      await g.moveBy(const Offset(8, 0));
    }
    await frame();
    probe.phase = '${prefix}b-dragging';
    await g.moveBy(const Offset(100, 0));
    await frame();
    // Past the middle of the page: the pager reports the new page now, with the finger still down.
    probe.phase = '${prefix}c-past-the-middle';
    await g.moveBy(const Offset(130, 0));
    await frame();
    await frame();
    probe.phase = '${prefix}d-settling';
    await g.up();
    for (var i = 0; i < 40; i++) {
      await frame();
    }
    probe.phase = '${prefix}e-late';
    await settleMotion(t, rounds: 6);
    probe.phase = null;
    return SwipeTrace(frameMs, pages, screens);
  }
}

/// Opens the reader on [startPage]. With [withWird] false there is no wird, so the reader is in browse mode and a page
/// change writes only the last viewed page.
Future<MotionReader> pumpMotionReader(
  WidgetTester t, {
  int startPage = 50,
  bool withWird = true,
  Duration? dbDelay = const Duration(milliseconds: 8),
  Size screen = const Size(412, 915),
  MushafRepository? repository,
  bool secondWird = false,
}) async {
  t.view.physicalSize = screen;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final executor = dbDelay == null
      ? NativeDatabase.memory()
      : NativeDatabase.memory().interceptWith(DelayedDatabase(dbDelay));
  final db = AppDatabase(executor);
  addTearDown(() async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(db.close);
  });
  final repo = WirdRepository(db);
  final mushaf = repository ?? MushafRepository(rootBundle);
  await t.runAsync(() async {
    await mushaf.loadMeta();
    // Pages the reader may ask for are loaded in real time first (rootBundle remembers Futures).
    for (var p = startPage - 3; p <= startPage + 4; p++) {
      if (p >= 1 && p <= 604) await mushaf.loadPage(p);
    }
    if (withWird) {
      await repo.ensureDefaults();
      final id = (await repo.activeWird())!.id;
      await repo.setPage(id, startPage);
      if (secondWird) {
        await repo.create(
          const WirdDraft(
            name: 'ورد الاختبار',
            type: WirdType.reading,
            startPage: 120,
            dailyPages: 5,
            color: 0xFF1565C0,
          ),
        );
      }
    } else {
      await repo.setLastViewedPage(startPage);
    }
  });
  final probe = RebuildProbe()..start();
  addTearDown(probe.stop);
  await t.pumpWidget(
    MushafApp(
      wirdRepository: repo,
      mushafRepository: mushaf,
      home: const ReaderScreen(),
    ),
  );
  await settleMotion(t, rounds: 16);
  return MotionReader(repo, probe);
}
