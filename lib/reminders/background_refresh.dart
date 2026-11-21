import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../wirds/db.dart';
import '../wirds/wird_repository.dart';
import 'reminder_scheduler.dart';
import 'reminder_service.dart';

const String _taskName = 'refresh-reminders';
const String _uniqueName = 'reminders-refresh';

/// Runs in a background isolate about once a day, even when the app is never opened: replans the
/// next 14 days and reschedules them, so the reminders never run out (spec FR-037).
@pragma('vm:entry-point')
void reminderCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final db = AppDatabase.open();
    try {
      final service = LocalNotificationService();
      await service.init();
      final plan = await buildReminderPlan(WirdRepository(db), DateTime.now());
      await service.reschedule(plan);
      return true;
    } catch (e, s) {
      debugPrint('background reminder refresh failed: $e\n$s');
      return false;
    } finally {
      await db.close();
    }
  });
}

/// Registers the daily refresh (needs no network). Safe to call on every start: an existing
/// registration is kept.
Future<void> registerBackgroundRefresh() async {
  await Workmanager().initialize(reminderCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    _uniqueName,
    _taskName,
    frequency: const Duration(hours: 24),
    constraints: Constraints(networkType: NetworkType.notRequired),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
