import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/backup/backup.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/reminders/reminder_scheduler.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

/// Lets real asset loading and drift's async work finish (they run outside the fake-async clock).
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await t.pump(const Duration(milliseconds: 60));
  }
}

/// Starts the whole app on a phone-sized screen with an in-memory database.
/// [reminders] builds the notification pieces from the repository (none by default).
Future<WirdRepository> pumpAppWith(
  WidgetTester t, {
  Widget? home,
  bool defaults = true,
  Reminders? Function(WirdRepository repo)? reminders,
  Backup? Function(AppDatabase db)? backup,
}) async {
  t.view.physicalSize = const Size(412, 915);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  final repo = WirdRepository(db);
  final made = reminders?.call(repo);
  // Unmount so nothing listens, pump so drift's cancel timers fire, then close the database for real.
  addTearDown(() async {
    made?.scheduler.dispose();
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(db.close);
  });
  final mushaf = MushafRepository(rootBundle);
  await t.runAsync(() async {
    await mushaf.loadMeta();
    if (defaults) await repo.ensureDefaults();
  });
  await t.pumpWidget(
    MushafApp(
      wirdRepository: repo,
      mushafRepository: mushaf,
      reminders: made,
      backup: backup?.call(db),
      home: home,
    ),
  );
  await settle(t);
  return repo;
}
