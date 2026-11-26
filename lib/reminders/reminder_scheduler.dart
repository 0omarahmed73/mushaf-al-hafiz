import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../prayer/prayer_planner.dart';
import '../prayer/prayer_settings.dart';

import '../wirds/wird_repository.dart';
import 'reminder_planner.dart';
import 'reminder_service.dart';

/// Builds the plan for [now] from the database without changing anything in it: the wird and Kahf reminders, then the
/// prayer notifications of feature 014 (research D6), exact when [exact] (the phone allows exact alarms).
Future<List<PlannedReminder>> buildReminderPlan(
  WirdRepository repo,
  DateTime now, {
  bool exact = false,
}) async {
  final inputs = await repo.reminderInputs(now);
  final prayer = PrayerSettings.read(
    await repo.prayerEntries(),
    phoneZone: currentZoneName(),
  );
  return [
    ...planReminders(
      wirds: inputs.wirds,
      doneToday: inputs.doneToday,
      todayPortions: inputs.todayPortions,
      kahfEnabled: inputs.kahfEnabled,
      kahfMinutes: inputs.kahfMinutes,
      kahfDay: inputs.kahfDay,
      kahfPage: kKahfPage,
      now: now,
    ),
    ...planPrayers(s: prayer, now: now, exact: exact),
  ];
}

/// The phone's zone as the reminder service set it at start, or UTC before that (tests).
String currentZoneName() {
  try {
    return tz.local.name;
  } catch (_) {
    return 'UTC';
  }
}

/// Keeps the phone's schedule equal to the plan: once at start, on every wird, portion or setting
/// change (after a short pause so a burst of changes is one refresh), and when asked (app resume).
/// A refresh that would schedule exactly what is already scheduled does nothing.
class ReminderScheduler {
  ReminderScheduler(
    this._repo,
    this._service, {
    DateTime Function()? clock,
    this.debounce = const Duration(milliseconds: 400),
  }) : _clock = clock ?? DateTime.now;

  final WirdRepository _repo;
  final ReminderService _service;
  final DateTime Function() _clock;
  final Duration debounce;

  StreamSubscription<void>? _subscription;
  Timer? _timer;
  List<PlannedReminder>? _scheduled;
  bool _disposed = false;

  /// Plans now and again after every change.
  void start() {
    refresh();
    _subscription = _repo.watchReminderInputs().listen((_) {
      _timer?.cancel();
      _timer = Timer(debounce, refresh);
    });
  }

  /// Replans and reschedules. With [force] it reschedules even when the plan is unchanged, which
  /// also repairs a schedule the system dropped.
  Future<void> refresh({bool force = false}) async {
    if (_disposed) return;
    try {
      final plan = await buildReminderPlan(
        _repo,
        _clock(),
        exact: await _service.exactAllowed(),
      );
      if (!force && listEquals(plan, _scheduled)) return;
      await _service.reschedule(plan);
      _scheduled = plan;
    } catch (e, s) {
      // Reminders must never take the app down (Constitution VII); the next refresh tries again.
      debugPrint('reminder refresh failed: $e\n$s');
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _subscription?.cancel();
  }
}

/// The reminder pieces the screens use, provided once at the top of the app.
class Reminders {
  const Reminders({
    required this.service,
    required this.scheduler,
    required this.taps,
  });

  final ReminderService service;
  final ReminderScheduler scheduler;
  final NotificationTaps taps;
}
