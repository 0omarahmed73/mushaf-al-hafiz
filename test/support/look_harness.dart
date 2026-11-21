import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/backup/backup.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/look/look_settings.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/reminders/reminder_scheduler.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import 'harness.dart' show settle;

/// An app on an in-memory database with an [AppLookSettings] that starts at [choice] (feature 004 tests). The
/// database is closed when the test ends.
class LookApp {
  LookApp._(this.db, this.repo, this.look);

  final AppDatabase db;
  final WirdRepository repo;
  final AppLookSettings look;

  static Future<LookApp> create(
    WidgetTester t, {
    LookChoice choice = LookChoice.emerald,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = WirdRepository(db);
    final look = AppLookSettings(repo);
    final app = LookApp._(db, repo, look);
    addTearDown(() async {
      look.dispose();
      // Unmount so nothing listens, pump so drift's cancel timers fire, then close the database for real.
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
      await t.runAsync(db.close);
    });
    if (choice != LookChoice.emerald) {
      await t.runAsync(() => look.set(choice));
    }
    return app;
  }

  /// The app around [home], with this object's look settings (or none when [withLook] is false).
  Widget app({
    required Widget home,
    bool withLook = true,
    Reminders? reminders,
    Backup? backup,
  }) => MushafApp(
    wirdRepository: repo,
    mushafRepository: MushafRepository(rootBundle),
    appLook: withLook ? look : null,
    reminders: reminders,
    backup: backup,
    home: home,
  );

  /// Changes the look while the app is shown, as Settings does.
  Future<void> choose(WidgetTester t, LookChoice choice) async {
    await t.runAsync(() => look.set(choice));
    await t.pump();
  }

  /// Shows [home] on a [screen]-sized window with the system text scaled by [textScale], after loading the Mushaf
  /// meta and (unless [defaults] is false) creating the default wirds, and lets real async work finish.
  Future<void> show(
    WidgetTester t,
    Widget home, {
    Size screen = const Size(412, 915),
    double textScale = 1.0,
    bool defaults = true,
    Reminders? reminders,
    Backup? backup,
  }) async {
    t.view.physicalSize = screen;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await MushafRepository(rootBundle).loadMeta();
      if (defaults) await repo.ensureDefaults();
    });
    await t.pumpWidget(
      app(
        reminders: reminders,
        backup: backup,
        home: textScale == 1.0
            ? home
            : Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(textScale)),
                  child: home,
                ),
              ),
      ),
    );
    await settle(t);
  }
}
