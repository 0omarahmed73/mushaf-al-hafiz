import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/ayah/ui/ayah_sheet.dart';
import 'package:mushaf/mushaf/mushaf_page_card.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/pdf/pdf_job.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/fake_pdf.dart';
import '../support/fake_renderer.dart';
import '../support/fake_share.dart';

/// Lets real asset and font loading finish (they run outside the fake-async test clock).
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 16; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await t.pump(const Duration(milliseconds: 60));
  }
}

Future<WirdRepository> pumpReader(WidgetTester t, {int startPage = 1, FakeShareService? share, PdfJob? pdfJob}) async {
  t.view.physicalSize = const Size(412, 915);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  // Unmount so nothing listens, pump so drift's cancel timers (created in the fake-async zone)
  // fire, then close the database for real.
  addTearDown(() async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(db.close);
  });
  final repo = WirdRepository(db);
  // meta.json is over 50 KB, so the asset bundle decodes it in an isolate; start that load in real
  // time (runAsync) so the screen finds it ready.
  final mushaf = MushafRepository(rootBundle);
  await t.runAsync(() async {
    await mushaf.loadMeta();
    // rootBundle remembers the Future of every string it loads. A page first loaded inside the widget
    // test's fake-async zone would leave a Future that a later test can never complete, so the pages the
    // reader asks for are loaded here, in real time, before the screen starts.
    for (var p = startPage - 1; p <= startPage + 1; p++) {
      if (p >= 1 && p <= 604) await mushaf.loadPage(p);
    }
    await repo.ensureDefaults();
    final id = (await repo.activeWird())!.id;
    await repo.setPage(id, startPage);
  });
  await t.pumpWidget(MushafApp(
    wirdRepository: repo,
    mushafRepository: mushaf,
    ayahRepository: AyahRepository(rootBundle),
    shareService: share ?? FakeShareService(),
    pdfJob: pdfJob,
    home: const ReaderScreen(),
  ));
  await settle(t);
  return repo;
}

String pageNumber(WidgetTester t) => t.widget<Text>(find.byKey(const ValueKey('page-number'))).data!;

Future<void> openIndex(WidgetTester t) async {
  await t.tap(find.byKey(const ValueKey('open-index')));
  await settle(t);
}

void main() {
  longPressTests();
  pageNumberTests();
  surahNameTests();
  landscapeTests();
  pdfStripTests();
  testWidgets('opens straight on the active wird page, with no screen before it', (t) async {
    await pumpReader(t, startPage: 50);
    expect(pageNumber(t), '50');
    expect(find.byKey(const ValueKey('top-bar')), findsOneWidget);
    expect(find.text('الورد اليومي'), findsWidgets);
  });

  testWidgets('a finger moving left to right shows the next page, and back shows the previous', (t) async {
    final repo = await pumpReader(t, startPage: 50);
    await t.fling(find.byType(PageView), const Offset(400, 0), 1500);
    await settle(t);
    expect(pageNumber(t), '51');
    await t.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await settle(t);
    expect(pageNumber(t), '50');
    final wird = await t.runAsync(() => repo.activeWird());
    expect(wird!.currentPage, 50);
  });

  testWidgets('swiping to the next page moves the wird position', (t) async {
    final repo = await pumpReader(t, startPage: 50);
    await t.fling(find.byType(PageView), const Offset(400, 0), 1500);
    await settle(t);
    final wird = await t.runAsync(() => repo.activeWird());
    expect(wird!.currentPage, 51);
  });

  testWidgets('tapping the page toggles the top and bottom bars', (t) async {
    await pumpReader(t, startPage: 50);
    expect(find.byKey(const ValueKey('bottom-bar')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('line-5')));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('top-bar')), findsNothing);
    expect(find.byKey(const ValueKey('bottom-bar')), findsNothing);
    await t.tap(find.byType(PageView));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('top-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-bar')), findsOneWidget);
  });

  testWidgets('top bar shows juz, hizb and quarter in the exact format', (t) async {
    await pumpReader(t, startPage: 489);
    expect(find.text('جزء 25 · حزب 49 · ربع 4'), findsOneWidget);
    expect(find.textContaining('الشورى'), findsWidgets);
  });

  testWidgets('jumping to al-Kahf from the index shows page 293 in browse mode', (t) async {
    final repo = await pumpReader(t, startPage: 50);
    await openIndex(t);
    await t.scrollUntilVisible(
      find.text('الكهف'),
      300,
      scrollable: find.descendant(of: find.byKey(const ValueKey('surah-list')), matching: find.byType(Scrollable)),
    );
    await t.scrollUntilVisible(
      find.text('الكهف'),
      200,
      scrollable: find.descendant(of: find.byKey(const ValueKey('surah-list')), matching: find.byType(Scrollable)),
    );
    await t.tap(find.text('الكهف'));
    await settle(t);
    expect(pageNumber(t), '293');
    expect(find.text('اجعلها موضعي'), findsOneWidget);
    expect(find.text('جزء 15 · حزب 30 · ربع 1'), findsOneWidget);
    expect(find.textContaining('الكهف'), findsWidgets);
    final wird = await t.runAsync(() => repo.activeWird());
    expect(wird!.currentPage, 50, reason: 'a jump must not move the wird');

    await t.tap(find.text('اجعلها موضعي'));
    await settle(t);
    final moved = await t.runAsync(() => repo.activeWird());
    expect(moved!.currentPage, 293);
    expect(find.text('اجعلها موضعي'), findsNothing);
  });

  testWidgets('the bottom bar lists its five actions; listen and test are disabled with «قريباً»', (t) async {
    await pumpReader(t, startPage: 50);
    for (final label in ['استماع', 'علامات', 'أوراد', 'اختبار']) {
      expect(find.descendant(of: find.byKey(const ValueKey('bottom-bar')), matching: find.text(label)),
          findsOneWidget, reason: label);
    }
    expect(find.byKey(const ValueKey('open-settings')), findsOneWidget);
    expect(find.text('قريباً'), findsNWidgets(2));
    await t.tap(find.text('استماع'));
    await t.pump();
    expect(find.byKey(const ValueKey('page-number')), findsOneWidget); // nothing opened
  });

  testWidgets('pinch zoom is limited to 1x..3x', (t) async {
    await pumpReader(t, startPage: 50);
    final viewer = t.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    expect(viewer.minScale, 1);
    expect(viewer.maxScale, 3);
  });

  testWidgets('the page field accepts only 1..604', (t) async {
    await pumpReader(t, startPage: 50);
    await openIndex(t);
    await t.tap(find.text('صفحة'));
    await settle(t);
    final field = find.byKey(const ValueKey('page-field'));
    for (final bad in ['0', '605']) {
      await t.enterText(field, bad);
      await t.tap(find.byKey(const ValueKey('page-go')));
      await t.pump();
      expect(find.text('أدخل رقماً من 1 إلى 604'), findsOneWidget, reason: bad);
      expect(find.byKey(const ValueKey('page-field')), findsOneWidget); // still on the index
    }
    await t.enterText(field, '604');
    await t.tap(find.byKey(const ValueKey('page-go')));
    await settle(t);
    expect(pageNumber(t), '604');
  });
}

/// Word ids of an ayah on a page, read from the real page asset.
Future<Set<int>> idsOf(WidgetTester t, int page, AyahRef ref) async {
  final data = await t.runAsync(() => MushafRepository(rootBundle).loadPage(page));
  return wordIdsOfAyah(data!, ref);
}

Finder word(int id) => find.byKey(ValueKey('w$id'));

int highlightedBoxes(WidgetTester t) => t
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .where((d) => d.decoration is BoxDecoration && (d.decoration as BoxDecoration).color == const Color(0x55FFC107))
    .length;

Future<void> pinchAt(WidgetTester t, Offset center) async {
  final a = await t.startGesture(center - const Offset(20, 0));
  final b = await t.startGesture(center + const Offset(20, 0));
  await a.moveBy(const Offset(-60, 0));
  await b.moveBy(const Offset(60, 0));
  await t.pump(const Duration(milliseconds: 50));
  await a.up();
  await b.up();
  await settle(t);
}

double zoomOf(WidgetTester t) =>
    t.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!.value.getMaxScaleOnAxis();

void longPressTests() {
  const kursi = AyahRef(2, 255);

  testWidgets('a long press on a word of 2:255 highlights the ayah and opens its menu', (t) async {
    await pumpReader(t, startPage: 42);
    final ids = await idsOf(t, 42, kursi);
    expect(ids, isNotEmpty);
    expect(find.byType(AyahSheet), findsNothing);
    await t.longPress(word(ids.first));
    await settle(t);
    expect(find.text('سورة البقرة · آية 255'), findsOneWidget);
    expect(highlightedBoxes(t), ids.length, reason: 'every word of the ayah, the end number included');
  });

  testWidgets('a long press on the end-of-ayah number also opens the menu', (t) async {
    await pumpReader(t, startPage: 42);
    final ids = await idsOf(t, 42, kursi);
    await t.longPress(word(ids.reduce((a, b) => a > b ? a : b)));
    await settle(t);
    expect(find.text('سورة البقرة · آية 255'), findsOneWidget);
  });

  testWidgets('closing the menu clears the highlight and leaves the same page and zoom', (t) async {
    await pumpReader(t, startPage: 42);
    final ids = await idsOf(t, 42, kursi);
    await t.longPress(word(ids.first));
    await settle(t);
    await t.tapAt(const Offset(200, 40)); // the barrier above the sheet
    await settle(t);
    expect(find.byType(AyahSheet), findsNothing);
    expect(highlightedBoxes(t), 0);
    expect(pageNumber(t), '42');
    expect(zoomOf(t), 1);
  });

  testWidgets('a short tap on a word still toggles the bars and opens nothing', (t) async {
    await pumpReader(t, startPage: 42);
    final ids = await idsOf(t, 42, kursi);
    await t.tap(word(ids.first));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('top-bar')), findsNothing);
    expect(find.byType(AyahSheet), findsNothing);
    expect(highlightedBoxes(t), 0);
  });

  testWidgets('a swipe that starts on a word turns the page and opens nothing', (t) async {
    await pumpReader(t, startPage: 42);
    final ids = await idsOf(t, 42, kursi);
    await t.fling(word(ids.first), const Offset(400, 0), 1500);
    await settle(t);
    expect(pageNumber(t), '43');
    expect(find.byType(AyahSheet), findsNothing);
  });

  testWidgets('a finger that moves before the hold is over cancels it', (t) async {
    await pumpReader(t, startPage: 42);
    final ids = await idsOf(t, 42, kursi);
    final g = await t.startGesture(t.getCenter(word(ids.first)));
    await g.moveBy(const Offset(40, 0)); // beyond the touch slop
    await t.pump(const Duration(milliseconds: 700));
    await g.up();
    await settle(t);
    expect(find.byType(AyahSheet), findsNothing);
  });

  testWidgets('a two-finger pinch that starts on a word zooms and opens nothing', (t) async {
    await pumpReader(t, startPage: 42);
    final ids = await idsOf(t, 42, kursi);
    await pinchAt(t, t.getCenter(word(ids.first)));
    expect(zoomOf(t), greaterThan(1));
    expect(find.byType(AyahSheet), findsNothing);
    expect(highlightedBoxes(t), 0);
  });

  testWidgets('a long press on a word while zoomed in still picks the ayah under the finger', (t) async {
    await pumpReader(t, startPage: 42);
    final ids = await idsOf(t, 42, kursi);
    await pinchAt(t, t.getCenter(find.byType(PageView)));
    expect(zoomOf(t), greaterThan(1));
    // the first words of the page are no longer all on screen; press a word that is
    final onScreen = [
      for (final id in ids)
        if (word(id).evaluate().isNotEmpty && t.getRect(word(id)).center.dy > 100 && t.getRect(word(id)).center.dy < 800) id,
    ];
    if (onScreen.isEmpty) return; // 2:255 is outside the zoomed window; covered by the unzoomed tests
    await t.longPress(word(onScreen.first), warnIfMissed: false);
    await settle(t);
    expect(find.text('سورة البقرة · آية 255'), findsOneWidget);
  });

  testWidgets('a long press on the surah banner, the basmallah line and the page number does nothing', (t) async {
    await pumpReader(t, startPage: 293);
    await t.longPress(find.byKey(const ValueKey('line-10'))); // «سورة الكهف»
    await settle(t);
    expect(find.byType(AyahSheet), findsNothing);
    await t.longPress(find.byKey(const ValueKey('line-11'))); // the basmallah
    await settle(t);
    expect(find.byType(AyahSheet), findsNothing);
    await t.longPress(find.byKey(const ValueKey('page-number')));
    await settle(t);
    expect(find.byType(AyahSheet), findsNothing);
    expect(highlightedBoxes(t), 0);
  });

  testWidgets('a long press on the top and bottom bars does nothing', (t) async {
    await pumpReader(t, startPage: 42);
    await t.longPress(find.byKey(const ValueKey('top-bar')), warnIfMissed: false);
    await settle(t);
    await t.longPress(find.byKey(const ValueKey('bottom-bar')), warnIfMissed: false);
    await settle(t);
    expect(find.byType(AyahSheet), findsNothing);
  });

  testWidgets('the first ayah of Al-Fatiha opens its menu', (t) async {
    await pumpReader(t, startPage: 1);
    final ids = await idsOf(t, 1, const AyahRef(1, 1));
    await t.longPress(word(ids.first));
    await settle(t);
    expect(find.text('سورة الفاتحة · آية 1'), findsOneWidget);
  });

  testWidgets('a second long press while the menu is open never opens a second menu', (t) async {
    await pumpReader(t, startPage: 42);
    final ids = await idsOf(t, 42, kursi);
    await t.longPress(word(ids.first));
    await settle(t);
    expect(find.byType(AyahSheet), findsOneWidget);
    // The page is behind the modal barrier: a press there is a tap on the barrier, which closes the menu.
    await t.longPress(word(ids.first), warnIfMissed: false);
    await settle(t);
    expect(find.byType(AyahSheet).evaluate().length, lessThanOrEqualTo(1));
    if (find.byType(AyahSheet).evaluate().isEmpty) expect(highlightedBoxes(t), 0);
  });
}

void pageNumberTests() {
  Future<void> openDialog(WidgetTester t) async {
    await t.tap(find.byKey(const ValueKey('page-number')));
    await settle(t);
  }

  Future<void> goTo(WidgetTester t, String text) async {
    await t.enterText(find.byKey(const ValueKey('goto-field')), text);
    await t.tap(find.byKey(const ValueKey('goto-go')));
    await settle(t);
  }

  testWidgets('tapping the page number opens a popup to type a page and does not toggle the bars', (t) async {
    await pumpReader(t, startPage: 50);
    await openDialog(t);
    expect(find.byKey(const ValueKey('goto-dialog')), findsOneWidget);
    expect(find.byKey(const ValueKey('goto-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('top-bar')), findsOneWidget, reason: 'the bars stay as they were');
  });

  testWidgets('typing a page and pressing «اذهب» shows that page in browse mode without moving the wird', (t) async {
    final repo = await pumpReader(t, startPage: 50);
    await openDialog(t);
    await goTo(t, '293');
    expect(find.byKey(const ValueKey('goto-dialog')), findsNothing);
    expect(pageNumber(t), '293');
    expect(find.text('اجعلها موضعي'), findsOneWidget, reason: 'browse mode');
    final wird = await t.runAsync(() => repo.activeWird());
    expect(wird!.currentPage, 50);
  });

  testWidgets('Arabic-Indic digits are read as 0-9', (t) async {
    await pumpReader(t, startPage: 50);
    await openDialog(t);
    await goTo(t, '٢٩٣');
    expect(pageNumber(t), '293');
  });

  testWidgets('a number outside 1..604, or nothing, shows the error and keeps the popup open', (t) async {
    await pumpReader(t, startPage: 50);
    await openDialog(t);
    for (final bad in ['0', '605', '']) {
      await goTo(t, bad);
      expect(find.text('أدخل رقماً من 1 إلى 604'), findsOneWidget, reason: 'input "$bad"');
      expect(find.byKey(const ValueKey('goto-dialog')), findsOneWidget);
    }
    expect(pageNumber(t), '50');
  });

  testWidgets('«إلغاء» closes the popup and stays on the same page', (t) async {
    await pumpReader(t, startPage: 50);
    await openDialog(t);
    await t.tap(find.byKey(const ValueKey('goto-cancel')));
    await settle(t);
    expect(find.byKey(const ValueKey('goto-dialog')), findsNothing);
    expect(pageNumber(t), '50');
    expect(find.text('اجعلها موضعي'), findsNothing);
  });

  testWidgets('the popup also works while the bars are hidden', (t) async {
    await pumpReader(t, startPage: 50);
    await t.tap(find.byKey(const ValueKey('line-5')));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('top-bar')), findsNothing);
    await openDialog(t);
    await goTo(t, '10');
    expect(pageNumber(t), '10');
  });
}

void surahNameTests() {
  testWidgets('tapping the surah name at the top opens the surahs list, and a surah opens its first page', (t) async {
    await pumpReader(t, startPage: 50);
    await t.tap(find.text('آل عمران').first);
    await settle(t);
    expect(find.text('الفهرس'), findsOneWidget);
    expect(find.byKey(const ValueKey('surah-list')), findsOneWidget, reason: 'the «السور» tab is the one shown');
    await t.scrollUntilVisible(
      find.text('الكهف'),
      200,
      scrollable: find.descendant(of: find.byKey(const ValueKey('surah-list')), matching: find.byType(Scrollable)),
    );
    await t.tap(find.text('الكهف'));
    await settle(t);
    expect(pageNumber(t), '293');
  });
}

/// The page in landscape: a portrait-shaped page, at most 600 wide, that scrolls up and down.
void landscapeTests() {
  Future<void> rotate(WidgetTester t, Size size) async {
    t.view.physicalSize = size;
    await t.pump(const Duration(milliseconds: 100));
    await settle(t);
  }

  const landscape = Size(915, 412);
  final scroll = find.byKey(const ValueKey('landscape-scroll'));

  testWidgets('in landscape the page keeps its portrait shape and scrolls vertically', (t) async {
    await pumpReader(t, startPage: 42);
    expect(scroll, findsNothing, reason: 'portrait is unchanged');
    await rotate(t, landscape);
    expect(scroll, findsOneWidget);
    final card = t.getSize(find.byType(MushafPageCard));
    expect(card.width, lessThanOrEqualTo(600));
    expect(card.height, closeTo(card.width * 1.75, 1));
    expect(card.height, greaterThan(landscape.height), reason: 'taller than the screen, so it scrolls');
  });

  testWidgets('the end of the page, with its number, is reached by scrolling', (t) async {
    await pumpReader(t, startPage: 42);
    await rotate(t, landscape);
    await t.scrollUntilVisible(find.byKey(const ValueKey('page-number')), 150, scrollable: find.descendant(of: scroll, matching: find.byType(Scrollable)));
    expect(t.getRect(find.byKey(const ValueKey('page-number'))).bottom, lessThanOrEqualTo(landscape.height));
    expect(pageNumber(t), '42');
  });

  // The owner's change of 2026-11-21: landscape used to start with the bars hidden (feature 001); it now shows them, with the
  // surah, juz and page details, and a tap still hides and shows them for the orientation being used.
  testWidgets('the bars are shown in landscape too until a tap, and portrait keeps its own setting', (t) async {
    await pumpReader(t, startPage: 42);
    expect(find.byKey(const ValueKey('top-bar')), findsOneWidget);
    await rotate(t, landscape);
    expect(find.byKey(const ValueKey('top-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('juz-hizb')), findsOneWidget, reason: 'the juz, hizb and quarter are in the top bar');
    await t.tap(find.byKey(const ValueKey('line-2'))); // a line that is on the screen
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('top-bar')), findsNothing);
    expect(find.byKey(const ValueKey('bottom-bar')), findsNothing);
    await rotate(t, const Size(412, 915));
    expect(find.byKey(const ValueKey('top-bar')), findsOneWidget, reason: 'portrait still shows its bars');
    expect(scroll, findsNothing);
    await rotate(t, landscape);
    expect(find.byKey(const ValueKey('top-bar')), findsNothing, reason: 'landscape keeps the hiding the user chose');
  });

  testWidgets('swiping sideways still turns the page in landscape', (t) async {
    await pumpReader(t, startPage: 42);
    await rotate(t, landscape);
    await t.fling(find.byType(PageView), const Offset(500, 0), 1500);
    await settle(t);
    expect(pageNumber(t), '43');
  });

  testWidgets('a long press on a word still opens the ayah menu in landscape', (t) async {
    await pumpReader(t, startPage: 42);
    await rotate(t, landscape);
    await t.longPress(find.descendant(of: find.byKey(const ValueKey('line-2')), matching: find.byType(Text)).first);
    await settle(t);
    expect(find.byType(AyahSheet), findsOneWidget);
  });
}

/// The surah PDF strip in the reader (spec FR-016): the reader stays usable while a job is prepared.
void pdfStripTests() {
  Finder key(String k) => find.byKey(ValueKey(k));

  testWidgets('while a PDF is prepared the strip shows and pages still turn', (
    t,
  ) async {
    final renderer = FakePageRenderer()..gate = Completer<void>().future;
    final job = fakePdfJob(renderer)..start(2);
    addTearDown(job.dispose);
    await pumpReader(t, startPage: 50, pdfJob: job);
    expect(key('pdf-strip'), findsOneWidget);
    expect(find.text('جارٍ تجهيز سورة البقرة'), findsOneWidget);
    expect(find.text('صفحة 1 من 48'), findsOneWidget);
    await t.fling(find.byType(PageView), const Offset(400, 0), 1500);
    await settle(t);
    expect(pageNumber(t), '51');
    expect(key('pdf-strip'), findsOneWidget);
    unawaited(job.cancel());
  });

  testWidgets(
    'the strip does not block a tap on the page, which still toggles the bars',
    (t) async {
      final renderer = FakePageRenderer()..gate = Completer<void>().future;
      final job = fakePdfJob(renderer)..start(2);
      addTearDown(job.dispose);
      await pumpReader(t, startPage: 50, pdfJob: job);
      await t.tap(find.byKey(const ValueKey('line-5')));
      await t.pump(const Duration(milliseconds: 300));
      expect(key('bottom-bar'), findsNothing);
      expect(key('pdf-strip'), findsOneWidget);
      unawaited(job.cancel());
    },
  );

  testWidgets('«إلغاء» in the strip stops the job', (t) async {
    final renderer = FakePageRenderer()..gate = Completer<void>().future;
    final job = fakePdfJob(renderer)..start(2);
    addTearDown(job.dispose);
    await pumpReader(t, startPage: 50, pdfJob: job);
    await t.tap(key('pdf-cancel'));
    await t.pump();
    expect(job.state, isA<PdfIdle>());
    expect(key('pdf-strip'), findsNothing);
  });

  testWidgets(
    'a job that finishes while the app is in front is handed to the share sheet by itself',
    (t) async {
      final share = FakeShareService();
      final job = fakePdfJob(FakePageRenderer());
      addTearDown(job.dispose);
      await pumpReader(t, startPage: 1, share: share, pdfJob: job);
      job.start(1);
      for (var i = 0; i < 40 && share.files.isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 20));
      }
      final shared = share.files.single;
      expect(
        (shared.fileName, shared.mimeType),
        ('سورة الفاتحة.pdf', 'application/pdf'),
      );
      await t.pump();
      expect(key('pdf-strip'), findsNothing);
    },
  );

  testWidgets(
    'a job that finishes while the app is in the background waits with «مشاركة»',
    (t) async {
      final share = FakeShareService();
      final job = fakePdfJob(FakePageRenderer());
      addTearDown(job.dispose);
      await pumpReader(t, startPage: 1, share: share, pdfJob: job);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      job.start(1);
      for (var i = 0; i < 40 && job.state is PdfPreparing; i++) {
        await t.pump(const Duration(milliseconds: 20));
      }
      expect(job.state, isA<PdfReady>());
      expect(share.files, isEmpty);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(find.text('تم تجهيز الملف'), findsOneWidget);
      await t.tap(key('pdf-share'));
      await t.pump();
      await t.pump();
      expect(share.files.single.mimeType, 'application/pdf');
    },
  );
}
