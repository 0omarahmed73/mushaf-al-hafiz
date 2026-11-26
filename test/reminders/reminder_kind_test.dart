// Feature 014 (research D6, D7): one plan holds the wird, Kahf and prayer notifications; each item says its kind (which
// picks the channel) and whether it is exact. A reminder built the old way is unchanged.
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/reminders/reminder_planner.dart';

import '../support/fake_reminders.dart';

void main() {
  final at = DateTime(2026, 3, 1, 8);

  test('an item built the old way is a wird or Kahf reminder, inexact, with the same fields', () {
    final wird = PlannedReminder(id: 301, at: at, title: 't', body: 'b', payload: 'wird:3');
    expect(wird.kind, ReminderKind.wird);
    expect(wird.exact, isFalse);
    expect(wird.isKahf, isFalse);
    expect((wird.id, wird.at, wird.title, wird.body, wird.payload), (301, at, 't', 'b', 'wird:3'));
    final kahf = PlannedReminder(id: kKahfIdBase + 2, at: at, title: 't', body: 'b', payload: 'page:293');
    expect(kahf.kind, ReminderKind.kahf);
    expect(kahf.isKahf, isTrue);
  });

  test('a prayer item keeps its kind even with an id above the Kahf base', () {
    final p = PlannedReminder(
      id: kPrayerIdBase + 12,
      at: at,
      title: 't',
      body: 'b',
      payload: 'prayer',
      kind: ReminderKind.prayerSound,
      exact: true,
    );
    expect(p.kind, ReminderKind.prayerSound);
    expect(p.isKahf, isFalse);
    expect(p.exact, isTrue);
  });

  test('equality includes the kind and the exact flag', () {
    PlannedReminder make(ReminderKind k, bool e) =>
        PlannedReminder(id: kPrayerIdBase, at: at, title: 't', body: 'b', payload: 'prayer', kind: k, exact: e);
    expect(make(ReminderKind.prayerSound, true), make(ReminderKind.prayerSound, true));
    expect(make(ReminderKind.prayerSound, true), isNot(make(ReminderKind.prayerSound, false)));
    expect(make(ReminderKind.prayerSound, true), isNot(make(ReminderKind.prayerSilent, true)));
  });

  test('the fake service answers the exact-alarm questions and records test notifications', () async {
    final s = FakeReminderService();
    expect(await s.exactAllowed(), isTrue);
    s.exact = false;
    expect(await s.exactAllowed(), isFalse);
    await s.openExactSettings();
    expect(s.exactSettingsOpened, 1);
    await s.showTest('a', 'b');
    expect(s.tests, [('a', 'b')]);
  });
}
