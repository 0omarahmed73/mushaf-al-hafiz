// The default hour depends on the day (owner's answer of 2026-11-21): 21:00 for Thursday, 10:00 for Friday, and an
// hour the user chose always wins. The shown hour, the stored hour and the planner use one value.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/reminders/kahf_day.dart';
import 'package:mushaf/reminders/reminder_scheduler.dart';
import 'package:mushaf/reminders/reminder_service.dart';
import 'package:mushaf/settings/settings_screen.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/fake_reminders.dart';
import '../support/harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

void main() {
  group('repository', () {
    late AppDatabase db;
    late WirdRepository repo;
    // A Friday at 09:00: Friday's 10:00 is still ahead.
    final now = DateTime(2026, 11, 20, 9, 0);

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = WirdRepository(db);
      await repo.ensureDefaults();
    });
    tearDown(() => db.close());

    test('the default hours are 21:00 for Thursday and 10:00 for Friday', () {
      expect(KahfDay.thursday.defaultMinutes, 21 * 60);
      expect(KahfDay.friday.defaultMinutes, 10 * 60);
      expect(WirdRepository.defaultKahfMinutes, 21 * 60);
    });

    test('with no hour chosen the hour follows the day', () async {
      expect(await repo.kahfMinutes(), 21 * 60);
      expect(await repo.kahfMinutesChosen(), isFalse);
      await repo.setKahfDay(KahfDay.friday);
      expect(await repo.kahfMinutes(), 10 * 60);
      await repo.setKahfDay(KahfDay.thursday);
      expect(await repo.kahfMinutes(), 21 * 60);
      expect(
        await repo.readSetting('kahfMinutes'),
        isNull,
        reason: 'a default is never stored',
      );
    });

    test('a chosen hour wins for both days', () async {
      await repo.setKahfMinutes(8 * 60 + 15);
      expect(await repo.kahfMinutesChosen(), isTrue);
      for (final day in KahfDay.values) {
        await repo.setKahfDay(day);
        expect(await repo.kahfMinutes(), 8 * 60 + 15, reason: day.name);
      }
    });

    test(
      'setKahf (switch and hour together) also counts as a chosen hour',
      () async {
        await repo.setKahf(enabled: true, minutes: 21 * 60);
        await repo.setKahfDay(KahfDay.friday);
        expect(await repo.kahfMinutes(), 21 * 60);
      },
    );

    test(
      'the switch alone stores no hour, and the hour alone leaves the switch',
      () async {
        await repo.setKahfEnabled(false);
        expect(await repo.kahfEnabled(), isFalse);
        expect(await repo.kahfMinutesChosen(), isFalse);
        expect(await repo.readSetting('kahfMinutes'), isNull);
        await repo.setKahfMinutes(9 * 60);
        expect(await repo.kahfEnabled(), isFalse);
        await repo.setKahfEnabled(true);
        expect(await repo.kahfMinutes(), 9 * 60);
      },
    );

    test('a stored text that is not a number counts as no hour', () async {
      await repo.writeSetting('kahfMinutes', 'abc');
      expect(await repo.kahfMinutesChosen(), isFalse);
      expect(await repo.kahfMinutes(), 21 * 60);
      await repo.setKahfDay(KahfDay.friday);
      expect(await repo.kahfMinutes(), 10 * 60);
    });

    test('reminderInputs carries the same hour as kahfMinutes', () async {
      await repo.setKahfDay(KahfDay.friday);
      var inputs = await repo.reminderInputs(now);
      expect((inputs.kahfDay, inputs.kahfMinutes), (KahfDay.friday, 10 * 60));
      await repo.setKahfMinutes(7 * 60 + 30);
      inputs = await repo.reminderInputs(now);
      expect(
        (inputs.kahfDay, inputs.kahfMinutes),
        (KahfDay.friday, 7 * 60 + 30),
      );
      await repo.setKahfDay(KahfDay.thursday);
      expect((await repo.reminderInputs(now)).kahfMinutes, 7 * 60 + 30);
    });

    test('the scheduler\'s plan uses the day\'s default hour, and a chosen hour once it exists', () async {
      final service = FakeReminderService();
      final scheduler = ReminderScheduler(
        repo,
        service,
        clock: () => now,
        debounce: const Duration(milliseconds: 20),
      );
      addTearDown(() async {
        scheduler.dispose();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      List<DateTime> kahf() => [
        for (final r in service.current)
          if (r.payload == 'page:293') r.at,
      ];
      scheduler.start();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(kahf(), [
        DateTime(2026, 11, 26, 21, 0),
        DateTime(2026, 12, 3, 21, 0),
      ]);

      await repo.setKahfDay(KahfDay.friday);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(kahf(), [
        DateTime(2026, 11, 20, 10, 0),
        DateTime(2026, 11, 27, 10, 0),
      ]);

      await repo.setKahfMinutes(7 * 60 + 30);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      // Friday's 07:30 has passed today; the next one is in a week (the 14-day window holds no third Friday).
      expect(kahf(), [DateTime(2026, 11, 27, 7, 30)]);

      await repo.setKahfDay(KahfDay.thursday);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(kahf(), [
        DateTime(2026, 11, 26, 7, 30),
        DateTime(2026, 12, 3, 7, 30),
      ]);
    });
  });

  group('Settings', () {
    late FakeReminderService service;

    Reminders buildReminders(WirdRepository repo) => Reminders(
      service: service,
      scheduler: ReminderScheduler(repo, service),
      taps: NotificationTaps(),
    );

    Future<WirdRepository> openSettings(WidgetTester t) =>
        pumpAppWith(t, home: const SettingsScreen(), reminders: buildReminders);

    testWidgets(
      'choosing Friday with no hour chosen shows 10:00 at once and Thursday brings 21:00 back',
      (t) async {
        service = FakeReminderService();
        final repo = await openSettings(t);
        expect(find.text('21:00'), findsOneWidget);

        await t.tap(key('kahf-day-friday'));
        await t.pump();
        expect(find.text('10:00'), findsOneWidget);
        expect(find.text('21:00'), findsNothing);
        await settle(t);
        expect(await t.runAsync(repo.kahfMinutes), 10 * 60);
        expect(
          await t.runAsync(() => repo.readSetting('kahfMinutes')),
          isNull,
          reason: 'the default is not stored',
        );

        await t.tap(key('kahf-day-thursday'));
        await settle(t);
        expect(find.text('21:00'), findsOneWidget);
        expect(find.text('10:00'), findsNothing);
      },
    );

    testWidgets(
      'the switch stores no hour, so the default still follows a later day change',
      (t) async {
        service = FakeReminderService();
        final repo = await openSettings(t);
        await t.tap(key('kahf-day-friday'));
        await settle(t);
        await t.tap(key('kahf-switch'));
        await settle(t);
        await t.tap(key('kahf-switch'));
        await settle(t);
        expect(find.text('10:00'), findsOneWidget);
        expect(await t.runAsync(() => repo.readSetting('kahfMinutes')), isNull);

        await t.tap(key('kahf-day-thursday'));
        await settle(t);
        expect(find.text('21:00'), findsOneWidget);
      },
    );

    testWidgets(
      'an hour the user chose before wins over the new day\'s default',
      (t) async {
        service = FakeReminderService();
        final repo = await pumpAppWith(
          t,
          home: const ReaderScreen(),
          reminders: buildReminders,
        );
        await t.runAsync(() => repo.setKahfMinutes(7 * 60 + 30));
        await t.tap(key('open-settings'));
        await settle(t);
        expect(find.text('07:30'), findsOneWidget);
        await t.tap(key('kahf-day-friday'));
        await settle(t);
        expect(find.text('07:30'), findsOneWidget);
        expect(find.text('10:00'), findsNothing);
      },
    );

    testWidgets(
      'choosing an hour in the picker stores it, and it then wins over the other day\'s default',
      (t) async {
        service = FakeReminderService();
        final repo = await openSettings(t);
        await t.tap(key('kahf-day-friday'));
        await settle(t);
        await t.tap(key('kahf-time'));
        await settle(t);
        // The picker opens on the shown hour (10:00); confirming it chooses that hour.
        final ok = find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(TextButton),
            )
            .last;
        await t.tap(ok);
        await settle(t);
        expect(await t.runAsync(repo.kahfMinutesChosen), isTrue);
        expect(await t.runAsync(repo.kahfMinutes), 10 * 60);

        await t.tap(key('kahf-day-thursday'));
        await settle(t);
        expect(
          find.text('10:00'),
          findsOneWidget,
          reason: 'a chosen hour wins over Thursday\'s default',
        );
        expect(find.text('21:00'), findsNothing);
      },
    );
  });
}
