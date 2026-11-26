// Feature 011 T042 (window [R4]): the found ayah stays highlighted until the reader next touches the reader, turns the page or
// opens something; the long press replaces it with its own highlight (spec FR-013; research D4). Under test: a `Listener` over
// the body, `_onPageChanged`, `_openAyahMenu` and the four screens the reader opens.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ui/ayah_sheet.dart';
import 'package:mushaf/reminders/reminder_scheduler.dart';
import 'package:mushaf/reminders/reminder_service.dart';
import 'package:mushaf/search/ayah_target.dart';
import 'package:mushaf/mushaf/index_screen.dart';
import 'package:mushaf/settings/settings_screen.dart';
import 'package:mushaf/wirds/bookmarks_sheet.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:mushaf/wirds/wirds_screen.dart';
import 'package:mushaf/mushaf/reader_screen.dart';

import '../support/fake_reminders.dart';
import '../support/harness.dart' as app;
import '../support/reader_harness.dart';
import '../support/reader_search_harness.dart';

const _kursi = AyahRef(2, 255);
const _before = AyahRef(2, 254);

/// A reader on page 42 (wird mode), with 2:255 found and highlighted; returns the ids of 2:255.
Future<Set<int>> _found(WidgetTester t) async {
  await pumpSizedReader(t, startPage: 42);
  final ids = await idsOn(t, 42, _kursi);
  await popIndexWith(t, const AyahTarget(_kursi, 42));
  expect(highlightedBoxes(t), ids.length, reason: 'the found ayah is shown');
  return ids;
}

/// A pointer goes down on [at] and is cancelled: nothing a tap would do happens, only the pointer-down.
Future<void> _touch(WidgetTester t, Offset at) async {
  final gesture = await t.startGesture(at);
  await t.pump(const Duration(milliseconds: 20));
  await gesture.cancel();
  await t.pump(const Duration(milliseconds: 20));
}

Future<void> _closeTop(WidgetTester t, Type route) async {
  Navigator.of(t.element(find.byType(route))).pop();
  await settleReader(t);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(preloadReaderPages);

  group('it stays', () {
    testWidgets('while nothing touches the reader (5 s)', (t) async {
      final ids = await _found(t);
      for (var s = 0; s < 5; s++) {
        await t.pump(const Duration(seconds: 1));
      }
      expect(highlightedBoxes(t), ids.length);
      expect(cardHighlight(t, 42), ids);
    });

    testWidgets('through a rotation', (t) async {
      final ids = await _found(t);
      t.view.physicalSize = const Size(915, 412);
      await settleReader(t);
      expect(highlightedBoxes(t), ids.length);
      t.view.physicalSize = const Size(412, 915);
      await settleReader(t);
      expect(highlightedBoxes(t), ids.length);
    });

    testWidgets('through a lifecycle change', (t) async {
      final ids = await _found(t);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settleReader(t);
      expect(highlightedBoxes(t), ids.length);
    });

    testWidgets('through a nudge of the pager that ends on the same page', (
      t,
    ) async {
      final ids = await _found(t);
      final position = t
          .widget<PageView>(find.byType(PageView))
          .controller!
          .position;
      final home = position.pixels;
      position.jumpTo(home + 100);
      await t.pump();
      position.jumpTo(home);
      await t.pump();
      expect(shownPage(t), '42');
      expect(highlightedBoxes(t), ids.length);
    });
  });

  group('a pointer-down on the reader clears it', () {
    testWidgets('a tap on the page, which also toggles the bars as before', (
      t,
    ) async {
      await _found(t);
      expect(keyed('top-bar'), findsOneWidget);
      await t.tap(keyed('line-5'));
      await t.pump(const Duration(milliseconds: 300));
      expect(highlightedBoxes(t), 0);
      expect(keyed('top-bar'), findsNothing, reason: 'the page took its tap');
      expect(keyed('bottom-bar'), findsNothing);
      expect(shownPage(t), '42');
    });

    testWidgets('a pointer-down on the top bar', (t) async {
      await _found(t);
      await _touch(t, t.getCenter(keyed('juz-hizb')));
      expect(highlightedBoxes(t), 0);
      expect(find.byType(Scaffold), findsOneWidget, reason: 'nothing opened');
    });

    testWidgets('a pointer-down on the bottom bar', (t) async {
      await _found(t);
      await t.tap(find.text('اختبار')); // disabled: it does nothing itself (feature 014 replaced «استماع»)
      await t.pump(const Duration(milliseconds: 100));
      expect(highlightedBoxes(t), 0);
    });

    testWidgets('a pointer-down on the page number', (t) async {
      await _found(t);
      await _touch(t, t.getCenter(keyed('page-number')));
      expect(highlightedBoxes(t), 0);
      expect(keyed('goto-dialog'), findsNothing);
    });

    testWidgets('a pointer-down on the today card', (t) async {
      await _found(t);
      // Opened without a pointer, so only the card's own pointer-down can clear it.
      t.widget<InkWell>(keyed('today-chip')).onTap!();
      await settleReader(t);
      expect(keyed('today-card'), findsOneWidget);
      expect(
        highlightedBoxes(t),
        greaterThan(0),
        reason: 'opening it is not a touch',
      );
      await _touch(t, t.getCenter(keyed('today-card')));
      expect(highlightedBoxes(t), 0);
      expect(keyed('today-card'), findsOneWidget, reason: 'the card stays');
    });

    testWidgets('a pinch on the page', (t) async {
      await _found(t);
      final centre = t.getCenter(find.byType(PageView));
      final a = await t.startGesture(centre - const Offset(20, 0));
      final b = await t.startGesture(centre + const Offset(20, 0));
      await a.moveBy(const Offset(-60, 0));
      await b.moveBy(const Offset(60, 0));
      await t.pump(const Duration(milliseconds: 50));
      await a.up();
      await b.up();
      await settleReader(t);
      expect(highlightedBoxes(t), 0);
    });
  });

  group('a turn or a jump to another page clears it', () {
    testWidgets('a swipe to another page, and back', (t) async {
      await _found(t);
      await t.fling(find.byType(PageView), const Offset(400, 0), 1500);
      await settleReader(t);
      expect(shownPage(t), '43');
      expect(highlightedBoxes(t), 0);
      await t.fling(find.byType(PageView), const Offset(-400, 0), 1500);
      await settleReader(t);
      expect(shownPage(t), '42');
      expect(highlightedBoxes(t), 0, reason: 'it does not come back');
    });

    testWidgets(
      'jumps of a notification tap (no pointer on the reader) clear it, and it does not come back',
      (t) async {
        late NotificationTaps taps;
        Reminders build(WirdRepository repo) {
          final service = FakeReminderService();
          taps = NotificationTaps();
          return Reminders(
            service: service,
            scheduler: ReminderScheduler(repo, service),
            taps: taps,
          );
        }

        await app.pumpAppWith(t, home: const ReaderScreen(), reminders: build);
        await loadAround(t, 42);
        await loadAround(t, 293);
        final ids = await idsOn(t, 42, _kursi);
        await popIndexWith(t, const AyahTarget(_kursi, 42));
        expect(shownPage(t), '42');
        expect(highlightedBoxes(t), ids.length);

        taps.add('page:293');
        await settleReader(t);
        expect(shownPage(t), '293');
        expect(highlightedBoxes(t), 0);

        taps.add('page:42');
        await settleReader(t);
        expect(shownPage(t), '42');
        expect(highlightedBoxes(t), 0, reason: 'page 42 is not found any more');
      },
    );
  });

  group('the long press replaces it', () {
    testWidgets(
      'the menu highlights its own ayah, and nothing is highlighted when the menu closes',
      (t) async {
        final ids = await _found(t);
        final others = await idsOn(t, 42, _before);
        expect(others, isNotEmpty);
        expect(others.intersection(ids), isEmpty);

        await t.longPress(find.byKey(ValueKey('w${others.first}')));
        await settleReader(t);

        expect(find.byType(AyahSheet), findsOneWidget);
        expect(cardHighlight(t, 42), others, reason: 'the menu has its own');
        expect(highlightedBoxes(t), others.length);

        await t.tapAt(const Offset(200, 40)); // the barrier above the sheet
        await settleReader(t);
        expect(find.byType(AyahSheet), findsNothing);
        expect(highlightedBoxes(t), 0, reason: 'gone when the menu closes');
      },
    );
  });

  group('opening something clears it', () {
    // Each screen is opened by a touch, and again by what a screen reader does (an activation with no pointer on the reader).
    final screens =
        <(String, Finder Function(), void Function(WidgetTester), Type)>[
          (
            'the index',
            () => keyed('open-index'),
            (t) => t.widget<InkWell>(keyed('open-index')).onTap!(),
            IndexScreen,
          ),
          (
            'the bookmarks',
            () => find.text('علامات'),
            (t) => t
                .widget<InkWell>(
                  find.ancestor(
                    of: find.text('علامات'),
                    matching: find.byType(InkWell),
                  ),
                )
                .onTap!(),
            BookmarksSheet,
          ),
          (
            'the wirds',
            () => find.text('أوراد'),
            (t) => t
                .widget<InkWell>(
                  find.ancestor(
                    of: find.text('أوراد'),
                    matching: find.byType(InkWell),
                  ),
                )
                .onTap!(),
            WirdsScreen,
          ),
          (
            'the settings',
            () => keyed('open-settings'),
            (t) => t.widget<IconButton>(keyed('open-settings')).onPressed!(),
            SettingsScreen,
          ),
        ];
    for (final (name, finder, direct, route) in screens) {
      testWidgets('$name, by a touch', (t) async {
        await _found(t);
        await t.tap(finder());
        await settleReader(t);
        expect(find.byType(route), findsOneWidget);
        await _closeTop(t, route);
        expect(highlightedBoxes(t), 0);
      });

      testWidgets('$name, by an activation with no pointer', (t) async {
        await _found(t);
        direct(t);
        await settleReader(t);
        expect(find.byType(route), findsOneWidget);
        await _closeTop(t, route);
        expect(highlightedBoxes(t), 0);
      });
    }
  });
}
