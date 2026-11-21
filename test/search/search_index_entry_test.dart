// Feature 011 T045: the entry point. With a `SearchService` the index's app bar has the search icon, which pushes the search
// screen and hands whatever it pops (an int first page or an `AyahTarget`) to whoever opened the index, unchanged; without a
// service (every earlier test) the index is exactly as it was. Then the whole path through the real reader (spec FR-001,
// FR-003, FR-010, FR-030, SC-006; research D4, D10; contracts/ui.md "Where it is and how it is reached").
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/look/look_settings.dart';
import 'package:mushaf/mushaf/index_screen.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/search/ayah_target.dart';
import 'package:mushaf/search/search_screen.dart';
import 'package:mushaf/search/search_service.dart';
import 'package:mushaf/search/search_strings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/harness.dart' show settle;
import '../support/look_harness.dart';
import '../support/motion_geometry.dart';
import '../support/reader_harness.dart';
import '../support/reader_search_harness.dart';
import '../support/search_harness.dart';
import 'search_baseline_test.dart' show kBaseline, kTitleShrink, kTolerance;

const _openSearch = ValueKey('open-search');
const _ikhlas = AyahRef(112, 1);
const _makeMine = 'اجعلها موضعي';

/// What the index route popped with.
class _IndexRun {
  bool popped = false;
  Object? result;
}

/// The index screen, with [service] provided by `MushafApp(searchService:)` when it is not null. With [pushed] it is a route
/// pushed over an empty home and what it pops is recorded; otherwise it is the home, as in T001's baselines.
Future<_IndexRun> _pumpIndex(
  WidgetTester t, {
  required bool withService,
  bool pushed = true,
  LookChoice look = LookChoice.emerald,
  Size screen = const Size(412, 915),
  double textScale = 1.0,
}) async {
  t.view.physicalSize = screen;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  final repo = WirdRepository(db);
  final lookSettings = AppLookSettings(repo);
  addTearDown(() async {
    lookSettings.dispose();
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(db.close);
  });
  final mushaf = MushafRepository(rootBundle);
  SearchService? service;
  await t.runAsync(() async {
    await mushaf.loadMeta();
    await repo.ensureDefaults();
    if (look != LookChoice.emerald) await lookSettings.set(look);
    if (withService) {
      service = SearchService.prepared(
        await realIndex(),
        await realMeta(),
        yieldTurn: () async {},
      );
    }
  });
  final navigator = GlobalKey<NavigatorState>();
  Widget scaled(Widget child) => textScale == 1.0
      ? child
      : Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child,
          ),
        );
  await t.pumpWidget(
    MushafApp(
      wirdRepository: repo,
      mushafRepository: mushaf,
      appLook: lookSettings,
      searchService: service,
      navigatorKey: navigator,
      home: pushed
          ? const Scaffold(key: ValueKey('index-home'), body: SizedBox.shrink())
          : scaled(const IndexScreen()),
    ),
  );
  final run = _IndexRun();
  if (pushed) {
    unawaited(
      navigator.currentState!
          .push<Object>(
            MaterialPageRoute<Object>(builder: (_) => const IndexScreen()),
          )
          .then((value) {
            run.popped = true;
            run.result = value;
          }),
    );
  }
  await settle(t);
  return run;
}

Future<void> _openSearchFromIndex(WidgetTester t) async {
  await t.tap(find.byKey(_openSearch));
  await settle(t);
}

List<double> _box(Rect r) => [r.left, r.top, r.width, r.height];

/// The rectangles T001 measured on the index screen (the same things, in the same order of taps).
Future<Map<String, List<double>>> _indexBoxes(WidgetTester t) async {
  final boxes = <String, List<double>>{
    'title': _box(t.getRect(find.text('الفهرس'))),
    'tab-surahs': _box(t.getRect(find.text('السور'))),
    'tab-juz': _box(t.getRect(find.text('الأجزاء'))),
    'tab-page': _box(t.getRect(find.text('صفحة'))),
  };
  final rows = find.descendant(
    of: find.byKey(const ValueKey('surah-list')),
    matching: find.byType(ListTile),
  );
  for (var i = 0; i < 3; i++) {
    boxes['row-${i + 1}'] = _box(t.getRect(rows.at(i)));
  }
  await t.tap(find.text('صفحة'));
  await settle(t);
  boxes['page-field'] = _box(
    t.getRect(find.byKey(const ValueKey('page-field'))),
  );
  return boxes;
}

bool _inside(Rect outer, Rect inner) =>
    inner.left >= outer.left - 0.5 &&
    inner.top >= outer.top - 0.5 &&
    inner.right <= outer.right + 0.5 &&
    inner.bottom <= outer.bottom + 0.5;

/// From the reader: the surah name, then the search icon (two of the three taps of SC-006).
Future<void> _readerToSearch(WidgetTester t) async {
  await t.tap(keyed('open-index'));
  await settleReader(t);
  await t.tap(find.byKey(_openSearch));
  await settleReader(t);
  expect(find.byType(SearchScreen), findsOneWidget);
}

/// The reader is the only route: the index and the search are gone and nothing can be popped.
void _expectReaderOnTop(WidgetTester t) {
  expect(find.byType(SearchScreen), findsNothing);
  expect(find.byType(IndexScreen), findsNothing);
  expect(find.byType(ReaderScreen), findsOneWidget);
  expect(
    Navigator.of(t.element(find.byType(ReaderScreen))).canPop(),
    isFalse,
    reason: 'the reader is the top route',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await preloadReaderPages();
    await realIndex();
  });

  group('without a SearchService the index is as it was', () {
    testWidgets('no search icon, no action in the app bar (LookApp)', (
      t,
    ) async {
      final app = await LookApp.create(t);
      await app.show(t, const IndexScreen());
      expect(find.byKey(_openSearch), findsNothing);
      expect(find.byIcon(Icons.search), findsNothing);
      expect(find.byTooltip(kSearchLabel), findsNothing);
      expect(t.widget<AppBar>(find.byType(AppBar)).actions, isNull);
      expect(find.text('الفهرس'), findsOneWidget);
    });

    testWidgets('a pushed index pops the chosen surah page and shows no icon', (
      t,
    ) async {
      final run = await _pumpIndex(t, withService: false);
      expect(find.byKey(_openSearch), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(IconButton),
        ),
        findsOneWidget,
        reason: 'only the back arrow',
      );
      await t.tap(find.text('الفاتحة'));
      await settle(t);
      expect(run.result, 1);
    });
  });

  group('with a SearchService the index has the search icon', () {
    testWidgets(
      'open-search: Icons.search, «بحث» as tooltip and to a screen reader, at least 48 x 48, at the end of the app bar',
      (t) async {
        final handle = t.ensureSemantics();
        await _pumpIndex(t, withService: true);
        final button = find.byKey(_openSearch);
        expect(button, findsOneWidget);
        final widget = t.widget(button);
        expect(widget, isA<IconButton>());
        expect((widget as IconButton).tooltip, kSearchLabel);
        expect((widget.icon as Icon).icon, Icons.search);
        expect(
          find.descendant(of: find.byType(AppBar), matching: button),
          findsOneWidget,
        );
        final rect = t.getRect(button);
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        // The end of a right-to-left app bar is its left: the icon is left of the title and does not cover it.
        final title = t.getRect(find.text('الفهرس'));
        expect(rect.right, lessThanOrEqualTo(title.left));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(56));
        // One button named «بحث» to a screen reader.
        final node = t.getSemantics(button);
        final data = node.getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        expect([data.label, data.tooltip].where((s) => s.isNotEmpty).toSet(), {
          kSearchLabel,
        }, reason: 'named «بحث», once');
        expect(find.bySemanticsLabel(kSearchLabel), findsNothing);
        handle.dispose();
      },
    );

    testWidgets('the icon is the only action and the title is still «الفهرس»', (
      t,
    ) async {
      await _pumpIndex(t, withService: true);
      expect(t.widget<AppBar>(find.byType(AppBar)).actions, hasLength(1));
      expect(find.text('الفهرس'), findsOneWidget);
      expect(find.byType(SearchScreen), findsNothing);
    });

    testWidgets('tapping it pushes SearchScreen over the index', (t) async {
      final run = await _pumpIndex(t, withService: true);
      await _openSearchFromIndex(t);
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('search-field')), findsOneWidget);
      expect(run.popped, isFalse, reason: 'the index is under the search');
    });

    testWidgets('a surah row: the index pops with the int first page', (
      t,
    ) async {
      final run = await _pumpIndex(t, withService: true);
      await _openSearchFromIndex(t);
      await typeQuery(t, 'كهف');
      await t.tap(find.byKey(const ValueKey('surah-row-18')));
      await settle(t);
      expect(run.popped, isTrue);
      expect(run.result, isA<int>());
      expect(run.result, 293);
      expect(find.byType(SearchScreen), findsNothing);
      expect(find.byType(IndexScreen), findsNothing);
      expect(find.byKey(const ValueKey('index-home')), findsOneWidget);
    });

    testWidgets('an ayah row: the index pops with the AyahTarget, unchanged', (
      t,
    ) async {
      final run = await _pumpIndex(t, withService: true);
      await _openSearchFromIndex(t);
      await typeQuery(t, 'قل هو الله احد');
      await t.tap(find.byKey(ValueKey('ayah-row-${_ikhlas.key}')));
      await settle(t);
      expect(run.popped, isTrue);
      expect(run.result, isA<AyahTarget>());
      final target = run.result! as AyahTarget;
      expect(target.ref, _ikhlas);
      expect(target.page, 604);
      expect(find.byType(SearchScreen), findsNothing);
      expect(find.byType(IndexScreen), findsNothing);
    });

    testWidgets(
      'back from search (the system back, then the arrow) returns to the index, which pops nothing',
      (t) async {
        final run = await _pumpIndex(t, withService: true);
        await _openSearchFromIndex(t);
        await typeQuery(t, 'كهف');
        await t.binding.handlePopRoute();
        await settle(t);
        expect(find.byType(SearchScreen), findsNothing);
        expect(find.byType(IndexScreen), findsOneWidget);
        expect(run.popped, isFalse);

        await _openSearchFromIndex(t);
        expect(
          t
              .widget<TextField>(find.byKey(const ValueKey('search-field')))
              .controller!
              .text,
          isEmpty,
          reason: 'a closed search forgets its query',
        );
        await t.tap(find.byType(BackButton).last);
        await settle(t);
        expect(find.byType(SearchScreen), findsNothing);
        expect(find.byType(IndexScreen), findsOneWidget);
        expect(run.popped, isFalse);

        // The index still works after search was opened and closed.
        await t.tap(find.text('الفاتحة'));
        await settle(t);
        expect(run.result, 1);
      },
    );

    testWidgets('the surah list still pops a surah page', (t) async {
      final run = await _pumpIndex(t, withService: true);
      expect(find.byKey(const ValueKey('surah-list')), findsOneWidget);
      await t.tap(find.text('البقرة'));
      await settle(t);
      expect(run.result, 2);
    });

    testWidgets('the juz tab still pops a juz page', (t) async {
      final run = await _pumpIndex(t, withService: true);
      await t.tap(find.text('الأجزاء'));
      await settle(t);
      await t.tap(find.text('الجزء 2'));
      await settle(t);
      expect(run.result, 22);
    });

    testWidgets(
      'the page tab still refuses 605 and pops 77, and the icon stays on every tab',
      (t) async {
        final run = await _pumpIndex(t, withService: true);
        await t.tap(find.text('صفحة'));
        await settle(t);
        expect(find.byKey(_openSearch), findsOneWidget);
        await t.enterText(find.byKey(const ValueKey('page-field')), '605');
        await t.tap(find.byKey(const ValueKey('page-go')));
        await settle(t);
        expect(run.popped, isFalse);
        expect(find.text('أدخل رقماً من 1 إلى 604'), findsOneWidget);
        await t.enterText(find.byKey(const ValueKey('page-field')), '77');
        await t.tap(find.byKey(const ValueKey('page-go')));
        await settle(t);
        expect(run.result, 77);
      },
    );
  });

  group('the rectangles of T001 hold with the icon present', () {
    for (final look in [LookChoice.emerald, LookChoice.night]) {
      for (final (screen, scale, label) in [
        (const Size(412, 915), 1.0, '412x915'),
        (const Size(320, 640), 2.0, '320x640@2'),
      ]) {
        final name = 'index/${look.name}/$label';
        testWidgets(name, (t) async {
          await _pumpIndex(
            t,
            withService: true,
            pushed: false,
            look: look,
            screen: screen,
            textScale: scale,
          );
          final button = t.getRect(find.byKey(_openSearch));
          expect(button.width, greaterThanOrEqualTo(48));
          expect(button.height, greaterThanOrEqualTo(48));
          expect(button.left, greaterThanOrEqualTo(0));
          final titleNow = t.getRect(find.text('الفهرس'));
          expect(
            button.right,
            lessThanOrEqualTo(titleNow.left + kTolerance),
            reason: 'the icon does not cover the title',
          );
          final now = await _indexBoxes(t);
          final was = kBaseline[name]!;
          expect(now.keys.toSet(), was.keys.toSet());
          for (final key in was.keys) {
            final a = was[key]!;
            final b = now[key]!;
            if (key == 'title') {
              // The one thing that may move: the title keeps its start edge (the right), its top and its height, and may
              // lose at most 48 px of width (spec FR-030).
              expect(b[0] + b[2], closeTo(a[0] + a[2], kTolerance));
              expect(b[1], closeTo(a[1], kTolerance));
              expect(b[3], closeTo(a[3], kTolerance));
              expect(
                b[2],
                inInclusiveRange(
                  a[2] - kTitleShrink - kTolerance,
                  a[2] + kTolerance,
                ),
              );
              continue;
            }
            for (var i = 0; i < 4; i++) {
              expect(b[i], closeTo(a[i], kTolerance), reason: '$name / $key');
            }
          }
        });
      }
    }
  });

  group('end to end through the real reader', () {
    testWidgets(
      'the surah name, the icon, «كهف», the row: page 293 in browse mode, no highlight, the reader on top',
      (t) async {
        final reader = await pumpSearchReader(t, startPage: 50, pages: [293]);
        expect(shownPage(t), '50');
        expect(find.text(_makeMine), findsNothing);

        await _readerToSearch(t); // taps 1 and 2
        await typeQuery(t, 'كهف');
        await t.tap(find.byKey(const ValueKey('surah-row-18'))); // tap 3
        await settleReader(t);

        expect(shownPage(t), '293');
        expect(find.text(_makeMine), findsOneWidget, reason: 'browse mode');
        _expectReaderOnTop(t);
        expect(cardHighlight(t, 293), isEmpty);
        expect(highlightedBoxes(t), 0);
        final wird = await t.runAsync(() => reader.repo.activeWird());
        expect(wird!.currentPage, 50);
      },
    );

    testWidgets(
      '«قل هو الله احد», the row: page 604 with 112:1 highlighted and in view, the reader on top',
      (t) async {
        final reader = await pumpSearchReader(t, startPage: 50, pages: [604]);
        final ids = await idsOn(t, 604, _ikhlas);
        // the four words and the ayah's end sign
        expect(ids, hasLength(5));

        await _readerToSearch(t);
        await typeQuery(t, 'قل هو الله احد');
        await t.tap(find.byKey(ValueKey('ayah-row-${_ikhlas.key}')));
        await settleReader(t);

        expect(shownPage(t), '604');
        expect(find.text(_makeMine), findsOneWidget, reason: 'browse mode');
        _expectReaderOnTop(t);
        expect(cardHighlight(t, 604), ids);
        expect(highlightedBoxes(t), ids.length);
        final pager = t.getRect(find.byType(PageView));
        for (final id in ids) {
          final word = t.getRect(find.byKey(ValueKey('w$id')));
          expect(
            _inside(pager, word),
            isTrue,
            reason: 'word $id $word is not inside the pager $pager',
          );
        }
        final wird = await t.runAsync(() => reader.repo.activeWird());
        expect(wird!.currentPage, 50, reason: 'a result moves no wird');
      },
    );

    testWidgets(
      'back from search returns to the index and back again to the reader exactly as it was',
      (t) async {
        final reader = await pumpSearchReader(t, startPage: 50);
        final rects = pageRects(t);
        final topBar = t.getRect(keyed('top-bar'));
        final lastViewed = await t.runAsync(reader.repo.lastViewedPage);

        await _readerToSearch(t);
        await typeQuery(t, 'قل هو الله احد');
        expect(find.byKey(ValueKey('ayah-row-${_ikhlas.key}')), findsOneWidget);

        await t.binding.handlePopRoute();
        await settleReader(t);
        expect(find.byType(SearchScreen), findsNothing);
        expect(find.byType(IndexScreen), findsOneWidget);
        expect(find.byKey(_openSearch), findsOneWidget);

        await t.binding.handlePopRoute();
        await settleReader(t);
        _expectReaderOnTop(t);
        expect(shownPage(t), '50');
        expect(find.text(_makeMine), findsNothing, reason: 'still the wird');
        expect(highlightedBoxes(t), 0);
        expect(t.getRect(keyed('top-bar')), topBar);
        expect(pageRects(t), rects);
        final wird = await t.runAsync(() => reader.repo.activeWird());
        expect(wird!.currentPage, 50);
        expect(await t.runAsync(reader.repo.lastViewedPage), lastViewed);
      },
    );
  });
}
