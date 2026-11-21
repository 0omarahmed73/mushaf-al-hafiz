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
  String? coldStart;

  Reminders build(WirdRepository repo) {
    final service = FakeReminderService();
    taps = NotificationTaps();
    if (coldStart != null) taps.add(coldStart!);
    return Reminders(service: service, scheduler: ReminderScheduler(repo, service), taps: taps);
  }

  setUp(() => coldStart = null);

  testWidgets('a notification that starts the app for al-Kahf opens page 293 in browse mode', (t) async {
    coldStart = 'page:293';
    await pumpAppWith(t, home: const ReaderScreen(), reminders: build);
    expect(pageNumber(t), '293');
    expect(find.text('اجعلها موضعي'), findsOneWidget);
  });

  testWidgets('tapping a wird notification while the app is open shows that wird, not in browse mode', (t) async {
    final repo = await pumpAppWith(t, home: const ReaderScreen(), reminders: build);
    final id = (await t.runAsync(() => repo.create(const WirdDraft(name: 'الثاني', type: WirdType.reading, startPage: 50, color: 0xFF1565C0))))!;
    taps.add('wird:$id');
    await settle(t);
    expect(pageNumber(t), '50');
    expect(find.text('اجعلها موضعي'), findsNothing);
    expect((await t.runAsync(() => repo.activeWird()))!.id, id);
  });

  testWidgets('a notification for a deleted wird opens browse mode at the last viewed page', (t) async {
    final repo = await pumpAppWith(t, home: const ReaderScreen(), reminders: build);
    await t.runAsync(() => repo.setLastViewedPage(77));
    taps.add('wird:999');
    await settle(t);
    expect(pageNumber(t), '77');
    expect(find.text('اجعلها موضعي'), findsOneWidget);
  });

  testWidgets('a tap while another screen is open brings the reader forward', (t) async {
    await pumpAppWith(t, home: const ReaderScreen(), reminders: build);
    await t.tap(find.descendant(of: find.byKey(const ValueKey('bottom-bar')), matching: find.text('أوراد')));
    await settle(t);
    expect(find.byKey(const ValueKey('wird-add')), findsOneWidget);
    taps.add('page:293');
    await settle(t);
    expect(find.byKey(const ValueKey('wird-add')), findsNothing);
    expect(pageNumber(t), '293');
  });
}
