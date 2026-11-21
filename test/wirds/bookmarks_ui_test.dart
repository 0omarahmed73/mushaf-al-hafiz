import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/reminders/reminder_scheduler.dart';
import 'package:mushaf/reminders/reminder_service.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/fake_reminders.dart';
import '../support/harness.dart';

String pageNumber(WidgetTester t) => t.widget<Text>(find.byKey(const ValueKey('page-number'))).data!;

void main() {
  late NotificationTaps taps;

  Reminders build(WirdRepository repo) {
    final service = FakeReminderService();
    taps = NotificationTaps();
    return Reminders(service: service, scheduler: ReminderScheduler(repo, service), taps: taps);
  }

  Future<WirdRepository> pumpReader(WidgetTester t) => pumpAppWith(t, home: const ReaderScreen(), reminders: build);

  Future<void> openSheet(WidgetTester t) async {
    await t.tap(find.descendant(of: find.byKey(const ValueKey('bottom-bar')), matching: find.text('علامات')));
    await settle(t);
  }

  Future<void> addViaDialog(WidgetTester t, String note) async {
    await t.tap(find.byKey(const ValueKey('bookmark-add')));
    await settle(t);
    if (note.isNotEmpty) await t.enterText(find.byKey(const ValueKey('bookmark-note')), note);
    await t.tap(find.byKey(const ValueKey('bookmark-save')));
    await settle(t);
  }

  testWidgets('«علامات» opens a sheet that says where a new bookmark will go and starts empty', (t) async {
    await pumpReader(t);
    await openSheet(t);
    expect(find.text('لا توجد علامات بعد'), findsOneWidget);
    expect(find.text('إضافة علامة للصفحة 1'), findsOneWidget);
    expect(find.text('ستُحفظ ضمن: الورد اليومي'), findsOneWidget);
  });

  testWidgets('adding a bookmark with a note puts it at the top with the wird\'s name', (t) async {
    final repo = await pumpReader(t);
    await openSheet(t);
    await addViaDialog(t, 'آية الكرسي');
    expect(find.text('ص 1'), findsOneWidget);
    expect(find.text('آية الكرسي'), findsOneWidget);
    expect(find.text('الورد اليومي'), findsWidgets);
    expect(find.text('لا توجد علامات بعد'), findsNothing);
    final entry = (await t.runAsync(() => repo.watchBookmarks().first))!.single;
    expect(entry.bookmark.wirdId, 1);
    expect(entry.bookmark.note, 'آية الكرسي');
  });

  testWidgets('a bookmark may have no note, and cancelling the dialog adds nothing', (t) async {
    final repo = await pumpReader(t);
    await openSheet(t);
    await t.tap(find.byKey(const ValueKey('bookmark-add')));
    await settle(t);
    await t.tap(find.text('إلغاء'));
    await settle(t);
    expect(await t.runAsync(() => repo.watchBookmarks().first), isEmpty);

    await addViaDialog(t, '');
    final entry = (await t.runAsync(() => repo.watchBookmarks().first))!.single;
    expect(entry.bookmark.note, isNull);
    expect(find.text('ص 1'), findsOneWidget);
  });

  testWidgets('in browse mode a new bookmark is general («عامة»)', (t) async {
    await pumpReader(t);
    taps.add('page:293'); // a jump: browse mode on page 293
    await settle(t);
    await openSheet(t);
    expect(find.text('ستُحفظ كعلامة عامة'), findsOneWidget);
    await addViaDialog(t, 'الكهف');
    expect(find.text('ص 293'), findsOneWidget);
    expect(find.text('عامة'), findsOneWidget);
  });

  testWidgets('tapping a bookmark opens its page in browse mode without moving the wird', (t) async {
    final repo = await pumpReader(t);
    await t.runAsync(() => repo.addBookmark(77, 'هنا'));
    await openSheet(t);
    await t.tap(find.text('هنا'));
    await settle(t);
    expect(find.byKey(const ValueKey('bookmark-add')), findsNothing, reason: 'the sheet closed');
    expect(pageNumber(t), '77');
    expect(find.text('اجعلها موضعي'), findsOneWidget);
    expect((await t.runAsync(() => repo.wirdById(1)))!.currentPage, 1);
  });

  testWidgets('swiping a bookmark away deletes it', (t) async {
    final repo = await pumpReader(t);
    await t.runAsync(() async {
      await repo.addBookmark(10, 'الأولى');
      await repo.addBookmark(20, 'الثانية');
    });
    await openSheet(t);
    await t.drag(find.text('الأولى'), const Offset(-600, 0));
    await settle(t);
    expect(find.text('الأولى'), findsNothing);
    expect(find.text('الثانية'), findsOneWidget);
    final left = await t.runAsync(() => repo.watchBookmarks().first);
    expect(left!.map((e) => e.bookmark.note), ['الثانية']);
  });

  testWidgets('the list is newest first and shows «عامة» for a bookmark with no wird', (t) async {
    final repo = await pumpReader(t);
    await t.runAsync(() async {
      await repo.addBookmark(10, 'قديمة', wirdId: 1);
      await repo.addBookmark(20, 'جديدة');
    });
    await openSheet(t);
    expect(t.getTopLeft(find.text('جديدة')).dy, lessThan(t.getTopLeft(find.text('قديمة')).dy));
    expect(find.text('عامة'), findsOneWidget);
  });
}
