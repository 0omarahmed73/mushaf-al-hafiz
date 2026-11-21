import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/wirds/wird_form_screen.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:mushaf/wirds/wirds_screen.dart';

import '../support/harness.dart';

/// A screen with one button that opens [WirdsScreen] and shows what it returned.
class _Launcher extends StatefulWidget {
  const _Launcher();

  @override
  State<_Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<_Launcher> {
  int? picked;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: [
            TextButton(
              onPressed: () async {
                final id = await Navigator.of(context).push<int>(MaterialPageRoute(builder: (_) => const WirdsScreen()));
                setState(() => picked = id);
              },
              child: const Text('فتح الأوراد'),
            ),
            Text('picked:$picked'),
          ],
        ),
      );
}

Future<WirdRepository> pumpApp(WidgetTester t, {Widget home = const _Launcher(), bool defaults = true}) =>
    pumpAppWith(t, home: home, defaults: defaults);

Future<void> openWirds(WidgetTester t) async {
  await t.tap(find.text('فتح الأوراد'));
  await settle(t);
}

Future<void> tapKey(WidgetTester t, String key) async {
  final f = find.byKey(ValueKey(key));
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  await settle(t);
}

Future<void> enter(WidgetTester t, String key, String text) async {
  final f = find.byKey(ValueKey(key));
  await t.ensureVisible(f);
  await t.enterText(f, text);
  await t.pump();
}

/// Opens the ⋮ menu of a wird and taps [item] ('تعديل' or 'حذف') once the menu has finished opening.
Future<void> chooseFromMenu(WidgetTester t, int wirdId, String item) async {
  await t.tap(find.byKey(ValueKey('wird-menu-$wirdId')));
  await t.pump();
  await t.pump(const Duration(milliseconds: 500));
  await t.tap(find.text(item));
  await settle(t);
}

bool notifySwitch(WidgetTester t) => t.widget<SwitchListTile>(find.byKey(const ValueKey('wird-notify'))).value;

void main() {
  group('wird form', () {
    Future<void> openForm(WidgetTester t) async {
      await openWirds(t);
      await tapKey(t, 'wird-add');
    }

    testWidgets('adding a qiyam wird with 2 pages lists it as «قيام الليل» with the reminder off', (t) async {
      final repo = await pumpApp(t);
      await openForm(t);
      expect(notifySwitch(t), isTrue, reason: 'a reading wird starts with the reminder on');
      await enter(t, 'wird-name', 'قيامي');
      await tapKey(t, 'type-qiyam');
      expect(notifySwitch(t), isFalse, reason: 'a qiyam wird starts with the reminder off');
      await enter(t, 'wird-pages', '2');
      await tapKey(t, 'wird-save');

      expect(find.byKey(const ValueKey('wird-save')), findsNothing, reason: 'the form closed');
      expect(find.text('قيامي'), findsWidgets);
      expect(find.text('قيام الليل'), findsWidgets, reason: 'the type label is on its card');
      final wirds = await t.runAsync(() => repo.watchWirds().first);
      final qiyam = wirds!.singleWhere((w) => w.name == 'قيامي');
      expect(qiyam.type, WirdType.qiyam);
      expect(qiyam.dailyPages, 2);
      expect(qiyam.notifyEnabled, isFalse);
      expect(wirds.length, 2);
    });

    testWidgets('the type picker shows «حفظ» and «مراجعة» disabled with «قريباً»', (t) async {
      final repo = await pumpApp(t);
      await openForm(t);
      expect(find.text('حفظ'), findsOneWidget);
      expect(find.text('مراجعة'), findsOneWidget);
      expect(find.text('قريباً'), findsNWidgets(2));
      await t.ensureVisible(find.byKey(const ValueKey('type-hifz')));
      await t.tap(find.text('حفظ'));
      await t.tap(find.text('مراجعة'));
      await t.pump();
      await enter(t, 'wird-name', 'تجربة');
      await tapKey(t, 'wird-save');
      final wirds = await t.runAsync(() => repo.watchWirds().first);
      expect(wirds!.singleWhere((w) => w.name == 'تجربة').type, WirdType.reading, reason: 'the disabled types cannot be chosen');
    });

    testWidgets('the form rejects an empty name, pages per day below 1 and a start page outside 1–604', (t) async {
      final repo = await pumpApp(t);
      await openForm(t);

      await enter(t, 'wird-name', '   ');
      await tapKey(t, 'wird-save');
      expect(find.text('أدخل اسم الورد'), findsOneWidget);

      await enter(t, 'wird-name', 'اسم');
      await enter(t, 'wird-pages', '0');
      await tapKey(t, 'wird-save');
      expect(find.text('أدخل عدداً لا يقل عن 1'), findsOneWidget);

      await enter(t, 'wird-pages', '5');
      await enter(t, 'wird-start-page', '605');
      await tapKey(t, 'wird-save');
      expect(find.text('أدخل رقماً من 1 إلى 604'), findsOneWidget);

      await enter(t, 'wird-start-page', '0');
      await tapKey(t, 'wird-save');
      expect(find.text('أدخل رقماً من 1 إلى 604'), findsOneWidget);

      expect(find.byKey(const ValueKey('wird-save')), findsOneWidget, reason: 'still on the form');
      final wirds = await t.runAsync(() => repo.watchWirds().first);
      expect(wirds!.length, 1, reason: 'nothing was saved');
    });

    testWidgets('a target date is required when it is the chosen amount', (t) async {
      await pumpApp(t);
      await openForm(t);
      await enter(t, 'wird-name', 'بتاريخ');
      await tapKey(t, 'amount-date');
      await tapKey(t, 'wird-save');
      expect(find.text('اختر تاريخاً'), findsOneWidget);
      expect(find.byKey(const ValueKey('wird-save')), findsOneWidget);
    });

    testWidgets('editing a wird keeps its values and saves the changes', (t) async {
      final repo = await pumpApp(t);
      await openWirds(t);
      await chooseFromMenu(t, 1, 'تعديل');
      expect(find.text('تعديل الورد'), findsOneWidget);
      expect(t.widget<TextFormField>(find.byKey(const ValueKey('wird-name'))).controller!.text, 'الورد اليومي');
      expect(t.widget<TextFormField>(find.byKey(const ValueKey('wird-pages'))).controller!.text, '20');
      await enter(t, 'wird-name', 'وردي');
      await enter(t, 'wird-pages', '10');
      await tapKey(t, 'wird-save');
      final wird = await t.runAsync(() => repo.wirdById(1));
      expect((wird!.name, wird.dailyPages), ('وردي', 10));
    });

    testWidgets('the save button keeps a safe space above the system navigation bar', (t) async {
      await pumpApp(t);
      await openForm(t);
      // A phone with a 48-pixel navigation bar at the bottom.
      t.view.padding = const FakeViewPadding(bottom: 48);
      t.view.viewPadding = const FakeViewPadding(bottom: 48);
      addTearDown(t.view.resetPadding);
      addTearDown(t.view.resetViewPadding);
      await t.pump();
      await t.drag(find.byType(ListView), const Offset(0, -2000));
      await t.pump(const Duration(milliseconds: 500));
      final bottom = t.getRect(find.byKey(const ValueKey('wird-save'))).bottom;
      expect(bottom, lessThanOrEqualTo(915 - 48 - 24), reason: 'the button ends well above the navigation bar');
    });

    testWidgets('the form is usable on its own as a screen', (t) async {
      await pumpApp(t, home: const WirdFormScreen(), defaults: false);
      expect(find.text('ورد جديد'), findsOneWidget);
      expect(find.byKey(const ValueKey('wird-save')), findsOneWidget);
    });
  });

  group('wirds screen', () {
    testWidgets('lists each wird with type, position, bookmarks and khatmas, and marks the active one', (t) async {
      final repo = await pumpApp(t);
      await t.runAsync(() => repo.create(const WirdDraft(name: 'قيام', type: WirdType.qiyam, startPage: 100, dailyPages: 2, color: 0xFF1565C0)));
      await openWirds(t);
      expect(find.text('الورد اليومي'), findsWidgets);
      expect(find.text('قيام'), findsWidgets);
      expect(find.text('ص: 1'), findsOneWidget);
      expect(find.text('ص: 100'), findsOneWidget);
      expect(find.text('علامات: 0'), findsNWidgets(2));
      expect(find.text('ختمات: 0'), findsNWidgets(2));
      expect(find.text('النشط'), findsOneWidget);
    });

    testWidgets('tapping a wird makes it active and returns its id', (t) async {
      final repo = await pumpApp(t);
      final second = (await t.runAsync(() => repo.create(const WirdDraft(name: 'الثاني', type: WirdType.reading, startPage: 50, color: 0xFF1565C0))))!;
      await openWirds(t);
      await t.tap(find.byKey(ValueKey('wird-$second')));
      await settle(t);
      expect(find.text('picked:$second'), findsOneWidget);
      final active = await t.runAsync(() => repo.activeWird());
      expect(active!.id, second);
    });

    testWidgets('delete asks «حذف الورد؟»; cancelling keeps the wird, confirming removes it', (t) async {
      final repo = await pumpApp(t);
      await openWirds(t);
      await chooseFromMenu(t, 1, 'حذف');
      expect(find.text('حذف الورد؟'), findsOneWidget);
      await t.tap(find.text('إلغاء'));
      await settle(t);
      expect(find.text('حذف الورد؟'), findsNothing);
      expect(await t.runAsync(() => repo.wirdById(1)), isNotNull);

      await chooseFromMenu(t, 1, 'حذف');
      await t.tap(find.byKey(const ValueKey('delete-confirm')));
      await settle(t);
      expect(await t.runAsync(() => repo.wirdById(1)), isNull);
      expect(find.text('لا توجد أوراد. أضف وردك الأول.'), findsOneWidget);
    });

    testWidgets('the summary row reads «من ص 1 إلى ص 20» and shows a tick after «تم»', (t) async {
      final repo = await pumpApp(t);
      await openWirds(t);
      expect(find.text('من ص 1 إلى ص 20'), findsOneWidget);
      expect(find.byKey(const ValueKey('today-done-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('today-tick-1')), findsNothing);

      await t.tap(find.byKey(const ValueKey('today-done-1')));
      await settle(t);
      expect(find.byKey(const ValueKey('today-tick-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('today-done-1')), findsNothing);
      final wird = await t.runAsync(() => repo.wirdById(1));
      expect(wird!.currentPage, 21, reason: '«تم» moves the position to the page after the portion');
    });
  });

  group('reader summary', () {
    testWidgets('the chip opens a card with the portion, «تم» ticks it, and the choice is remembered', (t) async {
      final repo = await pumpApp(t, home: const ReaderScreen());
      expect(find.byKey(const ValueKey('today-card')), findsNothing, reason: 'closed until the user opens it');
      expect(find.text('0/1'), findsOneWidget);

      await tapKey(t, 'today-chip');
      expect(find.byKey(const ValueKey('today-card')), findsOneWidget);
      expect(find.text('من ص 1 إلى ص 20'), findsOneWidget);
      expect(await t.runAsync(repo.todayPanelExpanded), isTrue);

      await tapKey(t, 'today-done-1');
      expect(find.byKey(const ValueKey('today-tick-1')), findsOneWidget);
      expect(find.text('1/1'), findsOneWidget);

      await tapKey(t, 'today-close');
      expect(find.byKey(const ValueKey('today-card')), findsNothing);
      expect(await t.runAsync(repo.todayPanelExpanded), isFalse);
    });

    testWidgets('a tap anywhere outside the card closes it and does nothing else; a tap on the card keeps it open', (t) async {
      final repo = await pumpApp(t, home: const ReaderScreen());
      await tapKey(t, 'today-chip');
      expect(find.byKey(const ValueKey('today-card')), findsOneWidget);

      await t.tap(find.text('من ص 1 إلى ص 20'));
      await settle(t);
      expect(find.byKey(const ValueKey('today-card')), findsOneWidget, reason: 'a tap on the card keeps it open');

      // On the page, well below the card.
      await t.tapAt(const Offset(206, 700));
      await settle(t);
      expect(find.byKey(const ValueKey('today-card')), findsNothing);
      expect(find.byKey(const ValueKey('bottom-bar')), findsOneWidget, reason: 'the tap did not hide the bars');
      expect(await t.runAsync(repo.todayPanelExpanded), isFalse);

      // On a bottom-bar button: it only closes the card, it does not open the wirds screen.
      await tapKey(t, 'today-chip');
      await t.tap(
        find.descendant(of: find.byKey(const ValueKey('bottom-bar')), matching: find.text('أوراد')),
        warnIfMissed: false,
      );
      await settle(t);
      expect(find.byKey(const ValueKey('today-card')), findsNothing);
      expect(find.byKey(const ValueKey('wird-add')), findsNothing);
    });

    testWidgets('«أوراد» in the bottom bar opens the wirds screen', (t) async {
      await pumpApp(t, home: const ReaderScreen());
      await t.tap(find.descendant(of: find.byKey(const ValueKey('bottom-bar')), matching: find.text('أوراد')));
      await settle(t);
      expect(find.byKey(const ValueKey('wird-add')), findsOneWidget);
    });

    testWidgets('tapping the wird name at the top opens the wirds list like the bottom button', (t) async {
      await pumpApp(t, home: const ReaderScreen());
      await t.tap(find.byKey(const ValueKey('wird-pill')));
      await settle(t);
      expect(find.byKey(const ValueKey('wird-add')), findsOneWidget, reason: 'the wirds screen is open');
      expect(find.text('أورادي'), findsOneWidget);
    });

    testWidgets('switching wird from the wirds screen shows that wird\'s page in the reader', (t) async {
      final repo = await pumpApp(t, home: const ReaderScreen());
      final second = (await t.runAsync(() => repo.create(const WirdDraft(name: 'الثاني', type: WirdType.reading, startPage: 50, color: 0xFF1565C0))))!;
      await t.tap(find.descendant(of: find.byKey(const ValueKey('bottom-bar')), matching: find.text('أوراد')));
      await settle(t);
      await t.tap(find.byKey(ValueKey('wird-$second')));
      await settle(t);
      expect(t.widget<Text>(find.byKey(const ValueKey('page-number'))).data, '50');
    });
  });
}
