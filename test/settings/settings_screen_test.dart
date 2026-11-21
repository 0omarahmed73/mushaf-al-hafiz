import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/reminders/reminder_scheduler.dart';
import 'package:mushaf/reminders/reminder_service.dart';
import 'package:mushaf/settings/settings_screen.dart';

import '../support/fake_reminders.dart';
import '../support/harness.dart';

void main() {
  late FakeReminderService service;

  Reminders buildReminders(repo) {
    return Reminders(service: service, scheduler: ReminderScheduler(repo, service), taps: NotificationTaps());
  }

  testWidgets('the al-Kahf reminder is on at 21:00 by default and can be switched off', (t) async {
    service = FakeReminderService();
    final repo = await pumpAppWith(t, home: const SettingsScreen(), reminders: buildReminders);
    expect(t.widget<SwitchListTile>(find.byKey(const ValueKey('kahf-switch'))).value, isTrue);
    expect(find.text('21:00'), findsOneWidget);
    expect(find.text('كل خميس في الوقت الذي تختاره'), findsOneWidget);
    expect(find.byKey(const ValueKey('permission-card')), findsNothing);

    await t.tap(find.byKey(const ValueKey('kahf-switch')));
    await settle(t);
    expect(t.widget<SwitchListTile>(find.byKey(const ValueKey('kahf-switch'))).value, isFalse);
    expect(find.byKey(const ValueKey('kahf-time')), findsNothing, reason: 'no time while it is off');
    expect(await t.runAsync(repo.kahfEnabled), isFalse);
  });

  testWidgets('a saved time is shown when the settings open', (t) async {
    service = FakeReminderService();
    final repo = await pumpAppWith(t, home: const ReaderScreen(), reminders: buildReminders);
    await t.runAsync(() => repo.setKahf(enabled: true, minutes: 7 * 60 + 30));
    await t.tap(find.byKey(const ValueKey('open-settings')));
    await settle(t);
    expect(find.text('07:30'), findsOneWidget);
  });

  testWidgets('with notifications not allowed a line and a button appear; allowing hides them', (t) async {
    service = FakeReminderService(allowed: false, allowAfterRequest: true);
    await pumpAppWith(t, home: const SettingsScreen(), reminders: buildReminders);
    expect(find.byKey(const ValueKey('permission-card')), findsOneWidget);
    expect(find.textContaining('الإشعارات غير مسموحة'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('allow-notifications')));
    await settle(t);
    expect(service.requests, 1);
    expect(find.byKey(const ValueKey('permission-card')), findsNothing);
  });

  testWidgets('if the permission is still refused the screen says where to turn it on', (t) async {
    service = FakeReminderService(allowed: false, allowAfterRequest: false);
    await pumpAppWith(t, home: const SettingsScreen(), reminders: buildReminders);
    await t.tap(find.byKey(const ValueKey('allow-notifications')));
    await settle(t);
    expect(find.byKey(const ValueKey('permission-card')), findsOneWidget);
    expect(find.textContaining('من إعدادات الهاتف'), findsOneWidget);
  });

  testWidgets('«☰» in the reader opens the settings', (t) async {
    service = FakeReminderService();
    await pumpAppWith(t, home: const ReaderScreen(), reminders: buildReminders);
    await t.tap(find.byKey(const ValueKey('open-settings')));
    await settle(t);
    expect(find.text('تذكير سورة الكهف ليلة الجمعة'), findsOneWidget);
  });
}
