// The choice of the al-Kahf day in both looks, at every size, with a screen reader (spec FR-010, SC-005, US4;
// contracts/ui.md «The choice»).
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/reminders/kahf_day.dart';
import 'package:mushaf/reminders/kahf_strings.dart';
import 'package:mushaf/reminders/reminder_scheduler.dart';
import 'package:mushaf/reminders/reminder_service.dart';
import 'package:mushaf/settings/settings_screen.dart';

import '../support/contrast_walk.dart';
import '../support/fake_reminders.dart';
import '../support/look_harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

/// Settings on a [screen]-sized window, system text scaled by [textScale], with [day] saved and the reading size
/// [percent].
Future<LookApp> open(
  WidgetTester t,
  LookChoice choice, {
  Size screen = const Size(412, 915),
  double textScale = 1.0,
  KahfDay day = KahfDay.thursday,
  int percent = 100,
}) async {
  final a = await LookApp.create(t, choice: choice);
  await t.runAsync(() async {
    await a.repo.setKahfDay(day);
    await a.repo.setTextSizePercent(percent);
  });
  final service = FakeReminderService();
  final reminders = Reminders(
    service: service,
    scheduler: ReminderScheduler(a.repo, service),
    taps: NotificationTaps(),
  );
  addTearDown(reminders.scheduler.dispose);
  await a.show(
    t,
    const SettingsScreen(),
    screen: screen,
    textScale: textScale,
    reminders: reminders,
  );
  // The list builds only what is near the window: scroll until the choice exists, then bring it fully into view.
  await t.scrollUntilVisible(
    key('kahf-day'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await t.ensureVisible(key('kahf-day'));
  await t.pump();
  return a;
}

/// Checks the rectangles of the two cards against [screen].
void expectFits(WidgetTester t, Size screen, {required bool stacked}) {
  final th = t.getRect(key('kahf-day-thursday'));
  final fr = t.getRect(key('kahf-day-friday'));
  for (final r in [th, fr]) {
    expect(r.left, greaterThanOrEqualTo(0));
    expect(r.right, lessThanOrEqualTo(screen.width));
    expect(r.top, greaterThanOrEqualTo(0));
    expect(r.bottom, lessThanOrEqualTo(screen.height));
    expect(r.height, greaterThanOrEqualTo(48));
    expect(r.width, greaterThanOrEqualTo(48));
  }
  expect(th.overlaps(fr), isFalse);
  if (stacked) {
    expect(th.left, fr.left, reason: 'one above the other');
    expect(th.top, lessThan(fr.top));
  } else {
    expect(th.top, fr.top, reason: 'one row');
    expect(
      th.left,
      greaterThan(fr.left),
      reason: 'Thursday first, on the right in Arabic',
    );
  }
}

void main() {
  for (final choice in [LookChoice.emerald, LookChoice.night]) {
    for (final day in KahfDay.values) {
      group('${choice.name}, ${day.name} saved', () {
        testWidgets('412 x 915: side by side, fits, 48 px, contrast', (
          t,
        ) async {
          const screen = Size(412, 915);
          await open(t, choice, day: day);
          expect(t.takeException(), isNull);
          expectFits(t, screen, stacked: false);
          final issues = contrastIssues(t, within: key('kahf-day'));
          expect(issues, isEmpty, reason: issues.join('\n'));
        });

        testWidgets(
          '320 x 640 with a 2x system font: stacked, fits, 48 px, contrast',
          (t) async {
            const screen = Size(320, 640);
            await open(t, choice, screen: screen, textScale: 2.0, day: day);
            expect(t.takeException(), isNull);
            expectFits(t, screen, stacked: true);
            final issues = contrastIssues(t, within: key('kahf-day'));
            expect(issues, isEmpty, reason: issues.join('\n'));
          },
        );
      });
    }

    for (final percent in [80, 100, 150]) {
      testWidgets(
        '${choice.name}: the choice is the same at reading size $percent',
        (t) async {
          await open(t, choice, percent: percent);
          expect(t.takeException(), isNull);
          expectFits(t, const Size(412, 915), stacked: false);
          expect(
            t.getSize(key('kahf-day')).height,
            48,
            reason: 'the reading size does not touch Settings',
          );
        },
      );
    }
  }

  testWidgets(
    'semantics: the group is named, each card is a button with its name, the saved one is selected',
    (t) async {
      final handle = t.ensureSemantics();
      await open(t, LookChoice.emerald, day: KahfDay.friday);
      final group = t.getSemantics(key('kahf-day'));
      final thursday = t.getSemantics(key('kahf-day-thursday'));
      final friday = t.getSemantics(key('kahf-day-friday'));
      expect(group.label, contains(kKahfDayHeading));
      expect(thursday.label, contains(kKahfDayThursdayName));
      expect(friday.label, contains(kKahfDayFridayLabel));
      expect(thursday.flagsCollection.isButton, isTrue);
      expect(friday.flagsCollection.isButton, isTrue);
      expect(
        friday.flagsCollection.isSelected,
        isNot(thursday.flagsCollection.isSelected),
      );
      expect(
        thursday.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(friday.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    },
  );

  testWidgets('semantics: the selected state moves with a tap', (t) async {
    final handle = t.ensureSemantics();
    await open(t, LookChoice.emerald);
    final before = t
        .getSemantics(key('kahf-day-thursday'))
        .flagsCollection
        .isSelected;
    await t.tap(key('kahf-day-friday'));
    await t.pump(const Duration(milliseconds: 100));
    final after = t
        .getSemantics(key('kahf-day-thursday'))
        .flagsCollection
        .isSelected;
    expect(after, isNot(before));
    handle.dispose();
  });

  testWidgets(
    'the choice recolours when the look changes while Settings is shown',
    (t) async {
      final a = await open(t, LookChoice.emerald, day: KahfDay.friday);
      Color outline() {
        final material = t.widget<Material>(
          find
              .descendant(
                of: key('kahf-day-friday'),
                matching: find.byType(Material),
              )
              .first,
        );
        return ((material.shape! as RoundedRectangleBorder).side).color;
      }

      expect(outline(), LookChoice.emerald.look.accent);
      await a.choose(t, LookChoice.night);
      await t.pump(const Duration(milliseconds: 400));
      expect(outline(), LookChoice.night.look.accent);
    },
  );
}
