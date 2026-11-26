// The notification controls of the prayer screen (feature 014, US2, FR-015, FR-018, FR-022, FR-023, contracts/ui.md).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/prayer/prayer_screen.dart';
import 'package:mushaf/prayer/prayer_settings.dart';
import 'package:mushaf/reminders/reminder_scheduler.dart';

import 'package:mushaf/reminders/reminder_service.dart';

import '../support/fake_reminders.dart';
import '../support/harness.dart';
import 'prayer_harness.dart';

Finder _k(String key) => find.byKey(ValueKey(key));

const PrayerSettings _on = PrayerSettings(enabled: true, place: kCairo);

void main() {
  testWidgets('a bell cycles sound, silent, off and saves each step', (
    t,
  ) async {
    final rig = await pumpPrayer(t, initial: _on);
    for (final want in [NotifyMode.silent, NotifyMode.off, NotifyMode.sound]) {
      await t.tap(_k('prayer-bell-asr'));
      await settlePrayer(t);
      expect((await rig.settings(t)).notify[2].mode, want);
    }
    expect(find.byTooltip('العصر: بصوت'), findsOneWidget);
  });

  testWidgets(
    'exact alarms not allowed: the line, and its button opens the setting',
    (t) async {
      final rig = await pumpPrayer(t, initial: _on, exact: false);
      expect(_k('exact-off'), findsOneWidget);
      // The sun-arc hero (design A) is taller, so the line sits below the first screen.
      await t.ensureVisible(_k('exact-off'));
      await t.pumpAndSettle();
      await t.tap(
        find.descendant(of: _k('exact-off'), matching: find.byType(TextButton)),
      );
      expect(rig.service.exactSettingsOpened, 1);
    },
  );

  testWidgets('exact allowed: no line; every bell off: no line either', (
    t,
  ) async {
    await pumpPrayer(t, initial: _on);
    expect(_k('exact-off'), findsNothing);
    await pumpPrayer(
      t,
      initial: _on.copyWith(
        notify: List.filled(5, const PrayerNotify(NotifyMode.off, 0)),
      ),
      exact: false,
    );
    expect(_k('exact-off'), findsNothing);
  });

  testWidgets('notifications off for the app: the line', (t) async {
    await pumpPrayer(t, initial: _on, notificationsAllowed: false);
    expect(_k('notif-off'), findsOneWidget);
  });

  testWidgets(
    'the test button sends one notification; the battery guide opens; disable turns it off',
    (t) async {
      final rig = await pumpPrayer(t, initial: _on);
      await t.ensureVisible(_k('prayer-test'));
      await t.pumpAndSettle();
      await t.tap(_k('prayer-test'));
      await settlePrayer(t);
      expect(rig.service.tests.length, 1);
      expect(rig.service.tests.single.$1, 'حان الآن موعد صلاة العصر');
      await t.ensureVisible(_k('prayer-battery'));
      await t.pumpAndSettle();
      await t.tap(_k('prayer-battery'));
      await t.pumpAndSettle();
      expect(_k('battery-guide'), findsOneWidget);
      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();
      await t.ensureVisible(_k('prayer-disable'));
      await t.tap(_k('prayer-disable'));
      await settlePrayer(t);
      expect((await rig.settings(t)).enabled, isFalse);
      expect(_k('prayer-off'), findsOneWidget);
    },
  );

  testWidgets('back from the phone settings re-checks exact alarms', (t) async {
    final rig = await pumpPrayer(t, initial: _on, exact: false);
    expect(_k('exact-off'), findsOneWidget);
    rig.service.exact = true;
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settlePrayer(t);
    expect(_k('exact-off'), findsNothing);
  });

  testWidgets(
    'tapping a prayer notification in the reader opens the prayer screen',
    (t) async {
      late Reminders made;
      await pumpAppWith(
        t,
        reminders: (repo) {
          final service = FakeReminderService();
          return made = Reminders(
            service: service,
            scheduler: ReminderScheduler(repo, service),
            taps: NotificationTaps(),
          );
        },
      );
      expect(find.byType(PrayerScreen), findsNothing);
      made.taps.add('prayer');
      await settle(t);
      expect(find.byType(PrayerScreen), findsOneWidget);
    },
  );
}
