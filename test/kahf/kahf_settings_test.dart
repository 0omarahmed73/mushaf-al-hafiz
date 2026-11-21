import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/reminders/kahf_day.dart';
import 'package:mushaf/reminders/kahf_strings.dart';
import 'package:mushaf/reminders/reminder_scheduler.dart';
import 'package:mushaf/reminders/reminder_service.dart';
import 'package:mushaf/settings/settings_screen.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/fake_reminders.dart';
import '../support/harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

/// The check mark inside a card: how a selected day is shown besides its outline.
Finder checkIn(String cardKey) => find.descendant(
  of: key(cardKey),
  matching: find.byIcon(Icons.check_circle),
);

void main() {
  late FakeReminderService service;

  Reminders buildReminders(WirdRepository repo) => Reminders(
    service: service,
    scheduler: ReminderScheduler(repo, service),
    taps: NotificationTaps(),
  );

  Future<WirdRepository> openSettings(WidgetTester t) =>
      pumpAppWith(t, home: const SettingsScreen(), reminders: buildReminders);

  testWidgets(
    'with the switch on the choice sits between the switch and the hour, Thursday selected',
    (t) async {
      service = FakeReminderService();
      await openSettings(t);
      expect(key('kahf-day'), findsOneWidget);
      expect(key('kahf-day-thursday'), findsOneWidget);
      expect(key('kahf-day-friday'), findsOneWidget);
      expect(find.text(kKahfDayThursdayLabel), findsOneWidget);
      expect(find.text(kKahfDayFridayLabel), findsOneWidget);

      final switchTop = t.getTopLeft(key('kahf-switch')).dy;
      final dayTop = t.getTopLeft(key('kahf-day')).dy;
      final timeTop = t.getTopLeft(key('kahf-time')).dy;
      expect(switchTop, lessThan(dayTop));
      expect(dayTop, lessThan(timeTop));

      expect(checkIn('kahf-day-thursday'), findsOneWidget);
      expect(checkIn('kahf-day-friday'), findsNothing);
    },
  );

  testWidgets('the switch keeps today\'s texts while Thursday is chosen', (
    t,
  ) async {
    service = FakeReminderService();
    await openSettings(t);
    expect(find.text('تذكير سورة الكهف ليلة الجمعة'), findsOneWidget);
    expect(find.text('كل خميس في الوقت الذي تختاره'), findsOneWidget);
    expect(find.text(kKahfSwitchTitleFriday), findsNothing);
  });

  testWidgets(
    'tapping «الجمعة» saves Friday, moves the mark and names Friday in the switch',
    (t) async {
      service = FakeReminderService();
      final repo = await openSettings(t);
      await t.tap(key('kahf-day-friday'));
      await settle(t);

      expect(await t.runAsync(repo.kahfDay), KahfDay.friday);
      expect(await t.runAsync(repo.kahfEnabled), isTrue);
      expect(
        await t.runAsync(repo.kahfMinutes),
        KahfDay.friday.defaultMinutes,
        reason: 'no hour was chosen: Friday\'s default',
      );
      expect(checkIn('kahf-day-friday'), findsOneWidget);
      expect(checkIn('kahf-day-thursday'), findsNothing);
      expect(find.text(kKahfSwitchTitleFriday), findsOneWidget);
      expect(find.text(kKahfSwitchSubtitleFriday), findsOneWidget);
      expect(find.text('تذكير سورة الكهف ليلة الجمعة'), findsNothing);
      expect(find.text('كل خميس في الوقت الذي تختاره'), findsNothing);
      expect(
        find.text('10:00'),
        findsOneWidget,
        reason: 'no hour was chosen: Friday\'s default is shown',
      );
    },
  );

  testWidgets(
    'tapping the chosen day again writes nothing; tapping Thursday brings today\'s texts back',
    (t) async {
      service = FakeReminderService();
      final repo = await openSettings(t);
      await t.tap(key('kahf-day-thursday'));
      await settle(t);
      expect(
        await t.runAsync(() => repo.readSetting('kahfDay')),
        isNull,
        reason: 'nothing was written',
      );

      await t.tap(key('kahf-day-friday'));
      await settle(t);
      await t.tap(key('kahf-day-friday'));
      await settle(t);
      expect(await t.runAsync(repo.kahfDay), KahfDay.friday);

      await t.tap(key('kahf-day-thursday'));
      await settle(t);
      expect(await t.runAsync(repo.kahfDay), KahfDay.thursday);
      expect(find.text('تذكير سورة الكهف ليلة الجمعة'), findsOneWidget);
      expect(find.text('كل خميس في الوقت الذي تختاره'), findsOneWidget);
    },
  );

  testWidgets(
    'with the switch off the choice and the hour are hidden and the day is kept',
    (t) async {
      service = FakeReminderService();
      final repo = await openSettings(t);
      await t.tap(key('kahf-day-friday'));
      await settle(t);

      await t.tap(key('kahf-switch'));
      await settle(t);
      expect(key('kahf-day'), findsNothing);
      expect(key('kahf-time'), findsNothing);
      expect(await t.runAsync(repo.kahfDay), KahfDay.friday);

      await t.tap(key('kahf-switch'));
      await settle(t);
      expect(key('kahf-day'), findsOneWidget);
      expect(checkIn('kahf-day-friday'), findsOneWidget);
      expect(await t.runAsync(repo.kahfDay), KahfDay.friday);
    },
  );

  testWidgets('a saved Friday is shown when the settings open', (t) async {
    service = FakeReminderService();
    final repo = await pumpAppWith(
      t,
      home: const ReaderScreen(),
      reminders: buildReminders,
    );
    await t.runAsync(() => repo.setKahfDay(KahfDay.friday));
    await t.tap(key('open-settings'));
    await settle(t);
    expect(checkIn('kahf-day-friday'), findsOneWidget);
    expect(find.text(kKahfSwitchTitleFriday), findsOneWidget);
  });

  testWidgets(
    'with notifications not allowed the permission card shows and the choice still saves',
    (t) async {
      service = FakeReminderService(allowed: false);
      final repo = await openSettings(t);
      expect(key('permission-card'), findsOneWidget);
      await t.tap(key('kahf-day-friday'));
      await settle(t);
      expect(await t.runAsync(repo.kahfDay), KahfDay.friday);
      expect(key('permission-card'), findsOneWidget);
    },
  );
}
