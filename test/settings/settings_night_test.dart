// The Settings screen's own colours in both looks (spec FR-004, FR-012, FR-014; contracts/ui.md الإعدادات).
// Feature 003's size row and the look row have their own tests; the size row is not shown here.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/backup/backup.dart';
import 'package:mushaf/backup/backup_service.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/reminders/reminder_scheduler.dart';
import 'package:mushaf/reminders/reminder_service.dart';
import 'package:mushaf/settings/look_tile.dart';
import 'package:mushaf/settings/settings_screen.dart';
import 'package:mushaf/theme.dart';

import '../support/contrast_walk.dart';
import '../support/fake_backup.dart';
import '../support/fake_reminders.dart';
import '../support/harness.dart' show settle;
import '../support/look_harness.dart';

Finder key(String k) => find.byKey(ValueKey(k));

/// Settings on a [screen]-sized window with notifications not allowed (so the permission card shows) and a
/// backup service (so the backup rows show).
Future<LookApp> open(
  WidgetTester t,
  LookChoice choice, {
  Size screen = const Size(412, 915),
  double textScale = 1.0,
}) async {
  final a = await LookApp.create(t, choice: choice);
  final service = FakeReminderService(allowed: false, allowAfterRequest: false);
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
    backup: Backup(service: BackupService(a.db), files: FakeBackupFiles()),
  );
  return a;
}

Color? colorOf(WidgetTester t, String text) =>
    t.widget<Text>(find.text(text)).style?.color;

void main() {
  group('Emerald stays as it was', () {
    testWidgets(
      'muted labels and subtitles, gold time, gold-dark permission card',
      (t) async {
        await open(t, LookChoice.emerald);
        expect(colorOf(t, 'التذكيرات'), AppColors.muted);
        expect(colorOf(t, 'كل خميس في الوقت الذي تختاره'), AppColors.muted);
        expect(colorOf(t, '21:00'), AppColors.gold);
        expect(colorOf(t, 'النسخ الاحتياطي'), AppColors.muted);
        final card =
            t.widget<DecoratedBox>(key('permission-card')).decoration
                as BoxDecoration;
        expect((card.border as Border).top.color, AppColors.goldDark);
        expect((card.border as Border).top.width, 1.5);
        expect(card.borderRadius, BorderRadius.circular(14));
      },
    );
  });

  group('Night', () {
    testWidgets(
      'labels, subtitles, time and the permission card use the Night tokens',
      (t) async {
        await open(t, LookChoice.night);
        expect(colorOf(t, 'التذكيرات'), AppLook.night.textSecondary);
        expect(
          colorOf(t, 'كل خميس في الوقت الذي تختاره'),
          AppLook.night.textSecondary,
        );
        expect(colorOf(t, '21:00'), AppLook.night.accent);
        expect(colorOf(t, 'النسخ الاحتياطي'), AppLook.night.textSecondary);
        expect(colorOf(t, 'التطبيق'), AppLook.night.textSecondary);
        final card =
            t.widget<DecoratedBox>(key('permission-card')).decoration
                as BoxDecoration;
        expect((card.border as Border).top.color, AppLook.night.controlBorder);
        expect(card.borderRadius, BorderRadius.circular(20));
      },
    );

    testWidgets('after asking, the hint under the card is readable too', (
      t,
    ) async {
      await open(t, LookChoice.night);
      await t.tap(key('allow-notifications'));
      await settle(t);
      final hint = find.textContaining('من إعدادات الهاتف');
      expect(hint, findsOneWidget);
      expect(t.widget<Text>(hint).style!.color, AppLook.night.textSecondary);
    });

    testWidgets('every text and icon of the screen meets the contrast', (
      t,
    ) async {
      await open(t, LookChoice.night);
      await t.tap(key('allow-notifications'));
      await settle(t);
      final issues = contrastIssues(t);
      expect(issues, isEmpty, reason: issues.join('\n'));
    });

    testWidgets(
      'no bright block on the screen outside the look row\'s own colour samples',
      (t) async {
        await open(t, LookChoice.night);
        // The «المظهر» row shows each look in its own colours, so Emerald's ivory sample is meant to be bright.
        final outsideSamples = find
            .byWidgetPredicate((w) => w is DecoratedBox)
            .evaluate()
            .where((e) {
              var inside = false;
              e.visitAncestorElements((a) {
                if (a.widget is LookTile) inside = true;
                return !inside;
              });
              return !inside;
            });
        final bright = [
          for (final e in outsideSamples)
            if (((e.widget as DecoratedBox).decoration as BoxDecoration).color
                case final c? when c.computeLuminance() > 0.5)
              c,
        ];
        expect(bright, isEmpty);
      },
    );
  });

  for (final look in LookChoice.values) {
    testWidgets(
      '${look.name}: nothing overflows on 320 dp with a 2x font, down to «عن التطبيق»',
      (t) async {
        await open(t, look, screen: const Size(320, 640), textScale: 2.0);
        expect(t.takeException(), isNull);
        await t.dragUntilVisible(
          key('open-about'),
          find.byType(ListView),
          const Offset(0, -200),
        );
        expect(t.takeException(), isNull);
      },
    );
  }
}
