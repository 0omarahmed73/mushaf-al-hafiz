// The tips are true (feature 008, spec User Story 2, FR-003, SC-003, research D13): for each of the six steps the test does
// what the step says on the real reader and finds the control it names. If a control is renamed or removed, a test here
// fails and the sentence has to be revisited. Nothing here changes the reader.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/page_viewport.dart';
import 'package:mushaf/onboarding/tip_steps.dart';
import 'package:mushaf/onboarding/tips_dialog.dart';
import 'package:mushaf/settings/settings_screen.dart';

import '../support/reader_harness.dart' show settleReader;
import '../support/tips_harness.dart';

String pageNumber(WidgetTester t) => t.widget<Text>(key('page-number')).data!;

/// A word of ayah 2:255 that is on the screen of page 42.
Future<Finder> wordOnScreen(WidgetTester t, TipsReader reader) async {
  final data = await t.runAsync(() => reader.mushaf.loadPage(42));
  final ids = wordIdsOfAyah(data!, const AyahRef(2, 255));
  final viewport = t.getRect(find.byType(PageView));
  final id = ids.firstWhere(
    (id) => viewport.contains(t.getCenter(key('w$id'))),
  );
  return key('w$id');
}

/// A two-finger pinch in small steps (the scale gesture measures from where it is accepted).
Future<void> pinch(
  WidgetTester t,
  Offset center, {
  double from = 20,
  double to = 120,
}) async {
  final a = await t.startGesture(center - Offset(from, 0));
  final b = await t.startGesture(center + Offset(from, 0));
  await t.pump();
  for (var i = 1; i <= 12; i++) {
    final d = from + (to - from) * i / 12;
    await a.moveTo(center - Offset(d, 0));
    await b.moveTo(center + Offset(d, 0));
    await t.pump();
  }
  await a.up();
  await b.up();
  await t.pump();
}

double zoomOf(WidgetTester t) => t
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!
    .value
    .getMaxScaleOnAxis();

Future<void> back(WidgetTester t) async {
  await t.tap(find.byType(BackButton));
  await settleReader(t);
}

/// The names between «» in the six texts, which are names the app shows.
Set<String> quotedNames() => {
  for (final step in kTipSteps)
    for (final m in RegExp('«([^»]+)»').allMatches(step.body)) m.group(1)!,
};

void main() {
  group('step 1: a long press on an ayah opens its menu', () {
    testWidgets(
      'the menu has the tafsir, the translation, the word meanings and the three shares',
      (t) async {
        final reader = await pumpTipsReader(t);
        final word = await wordOnScreen(t, reader);
        await t.longPress(word);
        await settleReader(t);
        for (final row in [
          'ayah-share', // the ayah
          'ayah-tafsir',
          'ayah-translation',
          'ayah-meanings',
          'ayah-page-picture', // the page
          'ayah-surah-pdf', // the surah
        ]) {
          expect(key(row), findsOneWidget, reason: row);
        }
        expect(find.text('التفسير'), findsOneWidget);
        expect(find.text('الترجمة'), findsOneWidget);
        expect(find.text('معاني الكلمات'), findsOneWidget);
      },
    );

    testWidgets(
      'the tafsir row opens the tafsir of al-Sa\'di and the translation row the English translation',
      (t) async {
        final reader = await pumpTipsReader(t);
        final word = await wordOnScreen(t, reader);
        await t.longPress(word);
        await settleReader(t);
        await t.tap(key('ayah-tafsir'));
        await settleReader(t);
        expect(find.text('تفسير السعدي'), findsWidgets);
        await t.tapAt(const Offset(200, 40));
        await settleReader(t);
        await t.tap(key('ayah-translation'));
        await settleReader(t);
        expect(find.text('Saheeh International'), findsWidgets);
      },
    );
  });

  group('step 2: turning pages and jumping', () {
    testWidgets('a swipe from left to right shows the next page', (t) async {
      final reader = await pumpTipsReader(t);
      final word = await wordOnScreen(t, reader);
      expect(pageNumber(t), '42');
      await t.fling(word, const Offset(400, 0), 1500);
      await settleReader(t);
      expect(pageNumber(t), '43');
    });

    testWidgets('a tap on the surah-name row opens the index, with its tabs', (
      t,
    ) async {
      await pumpTipsReader(t);
      await t.tap(key('open-index'));
      await settleReader(t);
      expect(find.text('الفهرس'), findsOneWidget);
      expect(find.text('السور'), findsOneWidget);
      expect(find.text('الأجزاء'), findsOneWidget);
      expect(find.text('صفحة'), findsOneWidget);
    });

    testWidgets('a tap on the page number opens «الانتقال إلى صفحة»', (
      t,
    ) async {
      await pumpTipsReader(t);
      await t.tap(key('page-number'));
      await settleReader(t);
      expect(key('goto-dialog'), findsOneWidget);
      expect(find.text('الانتقال إلى صفحة'), findsOneWidget);
    });
  });

  group('step 3: hiding the bars and zooming', () {
    testWidgets(
      'a tap on the page hides both bars and a second tap shows them',
      (t) async {
        final reader = await pumpTipsReader(t);
        final word = await wordOnScreen(t, reader);
        expect(key('top-bar'), findsOneWidget);
        expect(key('bottom-bar'), findsOneWidget);
        await t.tap(word);
        await t.pump(const Duration(milliseconds: 300));
        expect(key('top-bar'), findsNothing);
        expect(key('bottom-bar'), findsNothing);
        await t.tap(word);
        await t.pump(const Duration(milliseconds: 300));
        expect(key('top-bar'), findsOneWidget);
        expect(key('bottom-bar'), findsOneWidget);
      },
    );

    testWidgets('two fingers apart zoom the page, to at most three times', (
      t,
    ) async {
      final reader = await pumpTipsReader(t);
      final word = await wordOnScreen(t, reader);
      expect(zoomOf(t), closeTo(1, 1e-9));
      await pinch(t, t.getCenter(word));
      expect(zoomOf(t), greaterThan(1.2));
      await pinch(t, t.getCenter(word), from: 10, to: 190);
      expect(zoomOf(t), lessThanOrEqualTo(3.0 + 1e-6));
    });
  });

  group('step 4: the daily wird', () {
    testWidgets(
      'the top bar has the wird name and «ملخص اليوم»; the pill opens the wirds list, which can add a wird',
      (t) async {
        await pumpTipsReader(t);
        expect(
          find.descendant(
            of: key('wird-pill'),
            matching: find.text('الورد اليومي'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: key('today-chip'),
            matching: find.text('ملخص اليوم'),
          ),
          findsOneWidget,
        );
        await t.tap(key('wird-pill'));
        await settleReader(t);
        expect(find.text('أوراد'), findsWidgets);
        expect(find.text('ورد جديد'), findsWidgets);
      },
    );

    testWidgets('«ملخص اليوم» opens today\'s portion, with «تم»', (t) async {
      await pumpTipsReader(t);
      await t.tap(key('today-chip'));
      await settleReader(t);
      expect(find.textContaining('من ص'), findsWidgets);
      expect(find.text('تم'), findsWidgets);
    });

    testWidgets('«أوراد» in the bottom bar opens the same list', (t) async {
      await pumpTipsReader(t);
      await t.tap(
        find.descendant(of: key('bottom-bar'), matching: find.text('أوراد')),
      );
      await settleReader(t);
      expect(find.text('ورد جديد'), findsWidgets);
    });
  });

  group('step 5: the bookmarks', () {
    testWidgets(
      'the bookmark icon is in the top bar and a tap bookmarks the page; «علامات» lists it',
      (t) async {
        await pumpTipsReader(t);
        expect(
          find.descendant(of: key('top-bar'), matching: key('bookmark-button')),
          findsOneWidget,
        );
        // Directly under the juz text.
        expect(
          t.getTopLeft(key('bookmark-button')).dy,
          greaterThan(t.getBottomLeft(key('juz-hizb')).dy),
        );
        await t.tap(key('bookmark-button'));
        await settleReader(t);
        await t.tap(
          find.descendant(of: key('bottom-bar'), matching: find.text('علامات')),
        );
        await settleReader(t);
        expect(find.text('ص 42'), findsOneWidget);
      },
    );
  });

  group('step 6: the menu, the size and the look', () {
    testWidgets(
      '«القائمة» opens Settings, which has «حجم الخط» and «المظهر» with both looks',
      (t) async {
        await pumpTipsReader(t);
        expect(t.widget<IconButton>(key('open-settings')).tooltip, 'القائمة');
        await t.tap(key('open-settings'));
        await settleReader(t);
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(find.text('حجم الخط'), findsWidgets);
        expect(find.text('المظهر'), findsOneWidget);
        expect(find.text('زمردي وذهبي'), findsWidgets);
        expect(find.text('القارئ الليلي'), findsWidgets);
      },
    );
  });

  group('every name between « » in the six texts', () {
    test('is one of the names the tests above found on the reader', () {
      // The names this file looks for: a new quoted name in a text must get a check here first.
      expect(quotedNames(), {
        'ملخص اليوم',
        'تم',
        'أوراد',
        'علامات',
        'القائمة',
        'زمردي وذهبي',
        'القارئ الليلي',
      });
    });

    testWidgets(
      '«علامات» «أوراد» and «القائمة» are on the bottom bar of the reader',
      (t) async {
        await pumpTipsReader(t);
        final bar = key('bottom-bar');
        expect(
          find.descendant(of: bar, matching: find.text('علامات')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: bar, matching: find.text('أوراد')),
          findsOneWidget,
        );
        expect(t.widget<IconButton>(key('open-settings')).tooltip, 'القائمة');
      },
    );
  });

  group('the popup over the real reader', () {
    testWidgets(
      'on the first launch it opens over the reader, and after «تخطي» the reader is as usable as ever',
      (t) async {
        final reader = await pumpTipsReader(t, seen: false);
        await settleReader(t);
        expect(find.byType(TipsDialog), findsOneWidget);
        expect(
          find.byType(PageView),
          findsWidgets,
          reason: 'the reader is loaded underneath',
        );
        expect(pageNumber(t), '42');
        await t.tap(skipButton);
        await settleReader(t);
        expect(find.byType(TipsDialog), findsNothing);
        final word = await wordOnScreen(t, reader);
        await t.tap(word);
        await t.pump(const Duration(milliseconds: 300));
        expect(
          key('top-bar'),
          findsNothing,
          reason: 'a tap on the page hides the bars',
        );
        await t.tap(word);
        await t.pump(const Duration(milliseconds: 300));
        expect(pageNumber(t), '42', reason: 'the position was not touched');
      },
    );

    testWidgets('with the flag stored it never opens over the reader', (
      t,
    ) async {
      await pumpTipsReader(t);
      expect(find.byType(TipsDialog), findsNothing);
      expect(find.byType(PageViewport), findsWidgets);
    });
  });
}
