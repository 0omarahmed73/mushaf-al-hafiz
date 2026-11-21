// The reader in both looks (feature 004, T029; spec FR-006, FR-009, FR-015, SC-008; research D5; contracts/ui.md):
// the top line, the bars, the sheet it opens and the page take the look's tokens; the bottom bar floats as a 56 px
// pill inside the unchanged 68 px slot in Night; nothing changes in size or place between the looks; and a long
// press, a tap, a swipe, a pinch and a live change of the look all behave as in Emerald & Gold.
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/look/look_settings.dart';
import 'package:mushaf/mushaf/mushaf_page_card.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/page_look.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/bookmarks_sheet.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/contrast_walk.dart';
import '../support/fake_share.dart';
import '../support/reader_harness.dart' show settleReader;

/// A reader on [startPage] with the app's look at [choice], and a way to change the look while it is shown.
class LookReader {
  LookReader(this.repo, this.look);

  final WirdRepository repo;
  final AppLookSettings look;

  /// Changes the look while the reader is shown, as Settings does.
  Future<void> choose(WidgetTester t, LookChoice choice) async {
    await t.runAsync(() => look.set(choice));
    await t.pump();
    await settleReader(t);
  }
}

Future<LookReader> pumpLookReader(
  WidgetTester t, {
  LookChoice choice = LookChoice.emerald,
  int startPage = 42,
  Size screen = const Size(412, 915),
}) async {
  t.view.physicalSize = screen;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  final repo = WirdRepository(db);
  final look = AppLookSettings(repo);
  addTearDown(() async {
    look.dispose();
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(db.close);
  });
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
    if (choice != LookChoice.emerald) await look.set(choice);
  });
  await t.pumpWidget(
    MushafApp(
      wirdRepository: repo,
      mushafRepository: mushaf,
      ayahRepository: AyahRepository(rootBundle),
      shareService: FakeShareService(),
      appLook: look,
      home: const ReaderScreen(),
    ),
  );
  await settleReader(t);
  return LookReader(repo, look);
}

Finder key(String k) => find.byKey(ValueKey(k));

Finder word(int id) => key('w$id');

String pageNumber(WidgetTester t) => t.widget<Text>(key('page-number')).data!;

Rect rectOf(WidgetTester t, Finder f) => t.getRect(f);

Rect cardRect(WidgetTester t) => t.getRect(find.byType(MushafPageCard));

PageLook pageLookShown(WidgetTester t) =>
    t.widget<MushafPageCard>(find.byType(MushafPageCard)).look;

/// The `BoxDecoration`s of the boxes inside [of], with where each one is.
List<({BoxDecoration decoration, Rect rect})> boxesIn(
  WidgetTester t,
  Finder of,
) {
  final boxes = find.descendant(of: of, matching: find.byType(DecoratedBox));
  final out = <({BoxDecoration decoration, Rect rect})>[];
  for (var i = 0; i < boxes.evaluate().length; i++) {
    final d = t.widget<DecoratedBox>(boxes.at(i)).decoration;
    if (d is BoxDecoration) {
      out.add((decoration: d, rect: t.getRect(boxes.at(i))));
    }
  }
  return out;
}

/// The bar's own box: the one filled with the look's bar colour.
({BoxDecoration decoration, Rect rect}) barBox(
  WidgetTester t,
  AppLook look,
) => boxesIn(t, key('bottom-bar')).firstWhere(
  (b) => b.decoration.color == look.barFill,
  orElse: () => throw TestFailure(
    'no box of the bottom bar is filled with the bar colour ${look.barFill}',
  ),
);

Future<Set<int>> idsOf(WidgetTester t, int page, AyahRef ref) async {
  final data = await t.runAsync(
    () => MushafRepository(rootBundle).loadPage(page),
  );
  return wordIdsOfAyah(data!, ref);
}

int highlightedBoxes(WidgetTester t, Color wash) => t
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .where((d) => d.decoration is BoxDecoration)
    .where((d) => (d.decoration as BoxDecoration).color == wash)
    .length;

double zoomOf(WidgetTester t) => t
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!
    .value
    .getMaxScaleOnAxis();

Future<void> pinchAt(WidgetTester t, Offset center) async {
  final a = await t.startGesture(center - const Offset(20, 0));
  final b = await t.startGesture(center + const Offset(20, 0));
  await a.moveBy(const Offset(-60, 0));
  await b.moveBy(const Offset(60, 0));
  await t.pump(const Duration(milliseconds: 50));
  await a.up();
  await b.up();
  await settleReader(t);
}

const _looks = <LookChoice, AppLook>{
  LookChoice.emerald: AppLook.emerald,
  LookChoice.night: AppLook.night,
};

void main() {
  for (final entry in _looks.entries) {
    final choice = entry.key;
    final look = entry.value;

    group('the reader chrome in ${choice.name}', () {
      testWidgets('the top line and the active-wird pill use the look', (
        t,
      ) async {
        await pumpLookReader(t, choice: choice);
        final surahName = find
            .descendant(of: key('open-index'), matching: find.byType(Text))
            .first;
        expect(
          t.widget<Text>(surahName).style?.color,
          look.heading,
          reason: 'the surah name',
        );
        expect(
          t.widget<Text>(key('juz-hizb')).style?.color,
          look.textSecondary,
          reason: 'juz · hizb · quarter',
        );
        final pill = boxesIn(t, key('wird-pill'));
        final outline = pill.first.decoration;
        expect(
          (outline.border as Border).top.color,
          look.controlBorder,
          reason: 'the pill outline',
        );
        expect(outline.borderRadius, BorderRadius.circular(999));
        final dot = pill.firstWhere(
          (b) => b.decoration.shape == BoxShape.circle,
        );
        expect(dot.decoration.color, look.accent);
        final name = find.descendant(
          of: key('wird-pill'),
          matching: find.byType(Text),
        );
        expect(t.widget<Text>(name).style?.color, look.text);
      });

      testWidgets('the bottom bar sits in the unchanged 68 px slot', (t) async {
        await pumpLookReader(t, choice: choice);
        final slot = rectOf(t, key('bottom-bar'));
        expect(slot.height, 68);
        expect(rectOf(t, key('top-bar')).height, 84);
        final bar = barBox(t, look);
        final border = bar.decoration.border as Border;
        expect(border.top.color, look.barBorder);
        if (look.floatingBar) {
          expect(bar.rect.height, 56, reason: 'a 56 px pill');
          expect(bar.rect.top, slot.top + 6);
          expect(bar.rect.bottom, slot.bottom - 6);
          expect(bar.rect.left, slot.left + 16);
          expect(bar.rect.right, slot.right - 16);
          expect(bar.decoration.borderRadius, BorderRadius.circular(28));
          expect(border.bottom.color, look.barBorder, reason: 'all four sides');
        } else {
          expect(bar.rect, slot, reason: 'today\'s full-width bar');
          expect(border.bottom.style, BorderStyle.none);
        }
      });

      testWidgets('the five items keep their labels, colours and actions', (
        t,
      ) async {
        await pumpLookReader(t, choice: choice);
        final bar = barBox(t, look).rect;
        for (final icon in [
          Icons.headphones,
          Icons.bookmark_border,
          Icons.menu_book,
          Icons.quiz_outlined,
          Icons.menu,
        ]) {
          final at = t.getCenter(find.byIcon(icon));
          expect(bar.contains(at), isTrue, reason: '$icon is inside the bar');
        }
        for (final label in ['استماع', 'علامات', 'أوراد', 'اختبار']) {
          expect(
            t.widget<Text>(find.text(label)).style?.color,
            look.heading,
            reason: label,
          );
        }
        expect(
          t.widget<Icon>(find.byIcon(Icons.bookmark_border)).color,
          look.heading,
        );
        expect(t.widget<IconButton>(key('open-settings')).color, look.heading);
        expect(find.text('قريباً'), findsNWidgets(2));
        for (final soon in ['استماع', 'اختبار']) {
          final fade = find.ancestor(
            of: find.text(soon),
            matching: find.byType(Opacity),
          );
          expect(t.widget<Opacity>(fade.first).opacity, 0.5, reason: soon);
        }
        // «استماع» and «اختبار» do nothing; «علامات» opens the bookmarks.
        await t.tap(find.text('استماع'));
        await t.tap(find.text('اختبار'));
        await t.pump();
        expect(find.byType(BookmarksSheet), findsNothing);
        expect(find.byType(ReaderScreen), findsOneWidget);
        await t.tap(find.text('علامات'));
        await settleReader(t);
        expect(find.byType(BookmarksSheet), findsOneWidget);
      });

      testWidgets('the bookmarks sheet the reader opens is on the look\'s '
          'background', (t) async {
        await pumpLookReader(t, choice: choice);
        await t.tap(find.text('علامات'));
        await settleReader(t);
        final sheet = find.ancestor(
          of: find.byType(BookmarksSheet),
          matching: find.byType(BottomSheet),
        );
        final surface = find
            .descendant(of: sheet, matching: find.byType(Material))
            .first;
        expect(t.widget<Material>(surface).color, look.background);
      });

      testWidgets('the bars pass the contrast walk', (t) async {
        await pumpLookReader(t, choice: choice);
        expect(contrastIssues(t, within: key('top-bar')), isEmpty);
        expect(contrastIssues(t, within: key('bottom-bar')), isEmpty);
      });
    });

    group('the page in ${choice.name}', () {
      testWidgets('the Mushaf page is drawn in the look', (t) async {
        await pumpLookReader(t, choice: choice);
        final shown = pageLookShown(t);
        expect(shown.paper, choice.pageLook.paper);
        expect(shown.ink, choice.pageLook.ink);
        expect(shown.frame, choice.pageLook.frame);
        expect(shown.numberColor, choice.pageLook.numberColor);
        expect(shown.highlight, choice.pageLook.highlight);
      });

      testWidgets('a long press highlights the ayah and opens its menu', (
        t,
      ) async {
        await pumpLookReader(t, choice: choice);
        const kursi = AyahRef(2, 255);
        final ids = await idsOf(t, 42, kursi);
        expect(ids, isNotEmpty);
        await t.longPress(word(ids.first));
        await settleReader(t);
        expect(find.text('سورة البقرة · آية 255'), findsOneWidget);
        expect(
          highlightedBoxes(t, choice.pageLook.highlight),
          ids.length,
          reason: 'every word of the ayah, the end number included',
        );
        await t.tapAt(const Offset(200, 40)); // the barrier above the sheet
        await settleReader(t);
        expect(highlightedBoxes(t, choice.pageLook.highlight), 0);
        expect(pageNumber(t), '42');
      });

      testWidgets('a tap toggles the bars and a swipe turns the page', (
        t,
      ) async {
        await pumpLookReader(t, choice: choice);
        final ids = await idsOf(t, 42, const AyahRef(2, 255));
        await t.tap(word(ids.first));
        await t.pump(const Duration(milliseconds: 300));
        expect(key('top-bar'), findsNothing);
        expect(key('bottom-bar'), findsNothing);
        await t.tap(word(ids.first));
        await t.pump(const Duration(milliseconds: 300));
        expect(key('top-bar'), findsOneWidget);
        expect(key('bottom-bar'), findsOneWidget);
        await t.fling(word(ids.first), const Offset(400, 0), 1500);
        await settleReader(t);
        expect(pageNumber(t), '43');
      });

      testWidgets('a two-finger pinch zooms and opens nothing', (t) async {
        await pumpLookReader(t, choice: choice);
        final ids = await idsOf(t, 42, const AyahRef(2, 255));
        await pinchAt(t, t.getCenter(word(ids.first)));
        expect(zoomOf(t), greaterThan(1));
        expect(highlightedBoxes(t, choice.pageLook.highlight), 0);
      });
    });
  }

  group('the look changes under an open reader', () {
    testWidgets('same page, same boxes, no restart, in both directions', (
      t,
    ) async {
      final reader = await pumpLookReader(t, startPage: 42);
      final state = t.state(find.byType(ReaderScreen));
      final card = cardRect(t);
      final pager = rectOf(t, find.byType(PageView));
      final top = rectOf(t, key('top-bar'));
      final bottom = rectOf(t, key('bottom-bar'));

      await reader.choose(t, LookChoice.night);
      expect(identical(t.state(find.byType(ReaderScreen)), state), isTrue);
      expect(pageNumber(t), '42');
      expect(pageLookShown(t).ink, PageLook.night.ink);
      expect(barBox(t, AppLook.night).rect.height, 56);
      expect(cardRect(t), card, reason: 'the page box does not move');
      expect(rectOf(t, find.byType(PageView)), pager);
      expect(rectOf(t, key('top-bar')), top);
      expect(rectOf(t, key('bottom-bar')), bottom);
      final wird = await t.runAsync(() => reader.repo.activeWird());
      expect(wird!.currentPage, 42, reason: 'the position is not touched');

      await reader.choose(t, LookChoice.emerald);
      expect(pageLookShown(t).ink, PageLook.emerald.ink);
      expect(barBox(t, AppLook.emerald).rect, bottom);
      expect(cardRect(t), card);
      expect(t.takeException(), isNull);
    });

    testWidgets('in Night every bar item is a 48 px target inside the pill', (
      t,
    ) async {
      await pumpLookReader(t, choice: LookChoice.night);
      final pill = barBox(t, AppLook.night).rect;
      for (final label in ['استماع', 'علامات', 'أوراد', 'اختبار']) {
        final item = t.getRect(
          find
              .ancestor(of: find.text(label), matching: find.byType(InkWell))
              .first,
        );
        expect(item.height, greaterThanOrEqualTo(48), reason: label);
        expect(item.width, greaterThanOrEqualTo(48), reason: label);
        expect(item.top, greaterThanOrEqualTo(pill.top - 0.01), reason: label);
        expect(
          item.bottom,
          lessThanOrEqualTo(pill.bottom + 0.01),
          reason: label,
        );
        expect(
          item.left,
          greaterThanOrEqualTo(pill.left - 0.01),
          reason: label,
        );
        expect(item.right, lessThanOrEqualTo(pill.right + 0.01), reason: label);
      }
      final menu = t.getRect(key('open-settings'));
      expect(menu.size.shortestSide, greaterThanOrEqualTo(48));
      expect(pill.contains(menu.center), isTrue);
    });
  });
}
