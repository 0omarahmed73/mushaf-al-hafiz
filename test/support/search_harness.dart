// Helpers of the feature 011 tests (test/search/). Small and append-friendly: other tasks add their own helpers at the end.
import 'dart:async';
import 'dart:io' show File;

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/look/look_settings.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/search/ayah_index.dart';
import 'package:mushaf/search/search_screen.dart';
import 'package:mushaf/search/search_service.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:provider/provider.dart';

import 'fake_share.dart';
import 'reader_harness.dart' show settleReader;

Future<MushafMeta>? _meta;
Future<AyahIndex>? _index;

/// `assets/ayah/text/NNN.json` of [surah].
String realTextPath(int surah) =>
    'assets/ayah/text/${surah.toString().padLeft(3, '0')}.json';

/// The Mushaf's meta (114 surahs, the page of every ayah), read once per test run from the bundled asset. Call it from
/// `setUpAll` or `runAsync`, not inside the fake-async zone of a widget test (a real asset read runs in real time).
Future<MushafMeta> realMeta() =>
    _meta ??= MushafRepository(rootBundle).loadMeta();

/// The [AyahIndex] of all 114 bundled surah files, built once per test run (the file's isolate) with the production
/// [AyahIndexBuilder]. Same remark as [realMeta].
Future<AyahIndex> realIndex() => _index ??= _buildRealIndex();

Future<AyahIndex> _buildRealIndex() async {
  final meta = await realMeta();
  final builder = AyahIndexBuilder();
  for (var s = 1; s <= MushafMeta.surahCount; s++) {
    builder.addSurah(
      s,
      await rootBundle.loadString(realTextPath(s), cache: false),
    );
  }
  return builder.build(meta);
}

/// A stored text typed the careless way (spec User Story 3 scenario 4, SC-003): tashkeel U+064B-0653 and U+0656-065F, the
/// Quranic marks U+06D6-06E4 and U+06E9-06ED and tatweel removed, ٱ أ إ آ as ا, ة as ه and ى as ي; the small letters (the
/// dagger alef, the hamza signs U+0654 and U+0655, the small high yeh and noon, the hamza letters) are left as the Mushaf
/// has them.
String carelessForm(String stored) {
  final out = StringBuffer();
  for (final unit in stored.codeUnits) {
    final dropped =
        (unit >= 0x64B && unit <= 0x653) ||
        (unit >= 0x656 && unit <= 0x65F) ||
        (unit >= 0x6D6 && unit <= 0x6E4) ||
        (unit >= 0x6E9 && unit <= 0x6ED) ||
        unit == 0x640;
    if (dropped) continue;
    out.writeCharCode(switch (unit) {
      0x671 || 0x623 || 0x625 || 0x622 => 0x627,
      0x629 => 0x647,
      0x649 => 0x64A,
      _ => unit,
    });
  }
  return out.toString();
}

/// The 114 surah files of `assets/ayah/text/` read from disk as a path -> text map, for a `MapBundle` that counts loads.
/// (Reads with dart:io, so it works inside a fake-async widget test too.)
Map<String, String> realTextFiles() => {
  for (var s = 1; s <= MushafMeta.surahCount; s++)
    realTextPath(s): File(realTextPath(s)).readAsStringSync(),
};

// ---------------------------------------------------------------------------------------------------------------------
// The search screen (T020 and after): `SearchScreen` pushed over a `MushafApp`, with its own `ListenableProvider<SearchService?>`
// above the app (a plain Provider of a ChangeNotifier throws in debug).
// ---------------------------------------------------------------------------------------------------------------------

/// A [SearchService] whose phase the test sets and whose answers it chooses: `prepare` and `retry` only count (and `retry`
/// runs [onRetry]), `searchAyat` answers at once with [answerOf] (an empty result by default).
class ScriptedSearchService extends ChangeNotifier implements SearchService {
  ScriptedSearchService({this._phase = IndexPhase.ready, this.answerOf});

  IndexPhase _phase;
  Object? _failure;
  int prepareCalls = 0;
  int retryCalls = 0;

  /// What `retry()` does besides counting (a test moves the phase here).
  void Function()? onRetry;

  /// The answer to a folded query; null for an empty result.
  AyahSearchResult Function(String foldedQuery)? answerOf;

  @override
  IndexPhase get phase => _phase;

  @override
  Object? get failure => _failure;

  void setPhase(IndexPhase phase, {Object? failure}) {
    _phase = phase;
    _failure = failure;
    notifyListeners();
  }

  @override
  Future<void> prepare() async => prepareCalls++;

  @override
  Future<void> retry() async {
    retryCalls++;
    onRetry?.call();
  }

  @override
  Future<AyahSearchResult?> searchAyat(
    String foldedQuery, {
    required bool Function() isCurrent,
  }) async =>
      answerOf?.call(foldedQuery) ?? const AyahSearchResult(total: 0, hits: []);
}

/// What [pumpSearch] returns: the pieces the test may need and what the search route popped with.
class SearchRun {
  SearchRun({
    required this.service,
    required this.look,
    required this.size,
    required this.navigator,
  });

  final SearchService service;
  final AppLookSettings look;
  final TextSizeSettings size;
  final GlobalKey<NavigatorState> navigator;

  /// The search route has been popped (by a row, the back arrow or the system back).
  bool popped = false;

  /// What it popped with: an `int` (a surah's first page), an `AyahTarget` or null (back).
  Object? result;

  /// Changes the reading size while search is open, as Settings does.
  Future<void> setSize(WidgetTester t, int percent) async {
    await t.runAsync(() => size.set(percent));
    await t.pump();
  }

  /// Changes the look while search is open, as Settings does.
  Future<void> choose(WidgetTester t, LookChoice choice) async {
    await t.runAsync(() => look.set(choice));
    await t.pump();
  }
}

/// Shows `SearchScreen` as a route pushed over a `MushafApp` on a [screen]-sized window (the system text scaled by
/// [textScale], the reading size [readingPercent], the look [look]) and records what it pops with. [service] is a
/// `SearchService.prepared` over the real index (and an immediate yield, so a scan needs no pump) unless given.
Future<SearchRun> pumpSearch(
  WidgetTester t, {
  LookChoice look = LookChoice.emerald,
  Size screen = const Size(412, 915),
  double textScale = 1.0,
  int readingPercent = 100,
  SearchService? service,
}) async {
  t.view.physicalSize = screen;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  if (textScale != 1.0) {
    t.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  }
  final db = AppDatabase(NativeDatabase.memory());
  final repo = WirdRepository(db);
  final lookSettings = AppLookSettings(repo);
  final size = TextSizeSettings(repo);
  final mushaf = MushafRepository(rootBundle);
  addTearDown(() async {
    lookSettings.dispose();
    size.dispose();
    // Unmount so nothing listens, pump so drift's cancel timers fire, then close the database for real.
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(db.close);
  });
  late final SearchService built;
  await t.runAsync(() async {
    await mushaf.loadMeta();
    built =
        service ??
        SearchService.prepared(
          await realIndex(),
          await realMeta(),
          yieldTurn: () async {},
        );
    if (look != LookChoice.emerald) await lookSettings.set(look);
    await size.set(readingPercent);
  });
  final navigator = GlobalKey<NavigatorState>();
  await t.pumpWidget(
    ListenableProvider<SearchService?>.value(
      value: built,
      child: MushafApp(
        wirdRepository: repo,
        mushafRepository: mushaf,
        appLook: lookSettings,
        textSize: size,
        navigatorKey: navigator,
        home: const Scaffold(
          key: ValueKey('search-home'),
          body: SizedBox.shrink(),
        ),
      ),
    ),
  );
  final run = SearchRun(
    service: built,
    look: lookSettings,
    size: size,
    navigator: navigator,
  );
  unawaited(
    navigator.currentState!
        .push<Object>(
          MaterialPageRoute<Object>(builder: (_) => const SearchScreen()),
        )
        .then((value) {
          run.popped = true;
          run.result = value;
        }),
  );
  await settleSearch(t);
  return run;
}

/// Lets the route transition, the first frames and the microtasks of the screen finish (no real-time work is pending: the
/// service is prepared and the Mushaf meta was read before the app was pumped).
Future<void> settleSearch(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
  await t.pump(const Duration(milliseconds: 400));
}

/// Types [text] into the search field as the keyboard would (the whole text replaced) and lets the answers arrive.
Future<void> typeQuery(WidgetTester t, String text) async {
  await t.enterText(find.byKey(const ValueKey('search-field')), text);
  await t.pump();
  await t.pump();
}

// ---------------------------------------------------------------------------------------------------------------------
// The real reader with the search wired in (T045 and after): `MushafApp(searchService:)`, so the index shows the search
// icon and the whole path reader -> index -> search -> reader can be walked.
// ---------------------------------------------------------------------------------------------------------------------

/// What [pumpSearchReader] returns.
class SearchReader {
  SearchReader(this.db, this.repo, this.size, this.look, this.service);

  final AppDatabase db;
  final WirdRepository repo;
  final TextSizeSettings size;
  final AppLookSettings look;
  final SearchService service;
}

/// A copy of `pumpSizedReader` (test/support/reader_harness.dart) that passes `searchService:` to `MushafApp`: the reader
/// opened on [startPage] of the default wird of an in-memory database, the reading size [percent], the look [look].
/// [service] is a `SearchService.prepared` over the real index (and an immediate yield) unless given. The pages around
/// [startPage] and around each of [pages] (the pages a test will jump to) are read in real time first.
Future<SearchReader> pumpSearchReader(
  WidgetTester t, {
  int startPage = 50,
  int percent = 100,
  Size screen = const Size(412, 915),
  LookChoice look = LookChoice.emerald,
  Iterable<int> pages = const [],
  SearchService? service,
}) async {
  t.view.physicalSize = screen;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  final repo = WirdRepository(db);
  final size = TextSizeSettings(repo);
  final lookSettings = AppLookSettings(repo);
  addTearDown(() async {
    lookSettings.dispose();
    size.dispose();
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(db.close);
  });
  final mushaf = MushafRepository(rootBundle);
  late final SearchService built;
  await t.runAsync(() async {
    await mushaf.loadMeta();
    // Pages the reader may ask for are loaded in real time first (rootBundle remembers Futures).
    for (final centre in [startPage, ...pages]) {
      for (var p = centre - 3; p <= centre + 3; p++) {
        if (p >= 1 && p <= MushafMeta.pageCount) await mushaf.loadPage(p);
      }
    }
    built =
        service ??
        SearchService.prepared(
          await realIndex(),
          await realMeta(),
          yieldTurn: () async {},
        );
    await repo.ensureDefaults();
    final id = (await repo.activeWird())!.id;
    await repo.setPage(id, startPage);
    await size.set(percent);
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
      searchService: built,
      home: const ReaderScreen(),
    ),
  );
  await settleReader(t);
  return SearchReader(db, repo, size, lookSettings, built);
}
