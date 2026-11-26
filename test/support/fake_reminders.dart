import 'package:mushaf/reminders/reminder_planner.dart';
import 'package:mushaf/reminders/reminder_service.dart';

/// A notification system that records what it is asked to do.
class FakeReminderService implements ReminderService {
  FakeReminderService({this.allowed = true, this.allowAfterRequest = true});

  bool allowed;

  /// What the permission dialog answers when [requestPermission] is called.
  bool allowAfterRequest;
  bool failNext = false;
  int requests = 0;
  int initCalls = 0;
  final List<List<PlannedReminder>> schedules = [];

  List<PlannedReminder> get current =>
      schedules.isEmpty ? const [] : schedules.last;

  @override
  Future<void> init({void Function(String payload)? onTap}) async =>
      initCalls++;

  @override
  Future<bool> notificationsAllowed() async => allowed;

  @override
  Future<bool> requestPermission() async {
    requests++;
    allowed = allowAfterRequest;
    return allowed;
  }

  @override
  Future<void> reschedule(List<PlannedReminder> plan) async {
    if (failNext) {
      failNext = false;
      throw StateError('the phone refused');
    }
    schedules.add(List.of(plan));
  }

  // Feature 014: exact alarms and the test notification.
  bool exact = true;
  int exactSettingsOpened = 0;
  final List<(String, String)> tests = [];

  @override
  Future<bool> exactAllowed() async => exact;

  @override
  Future<void> openExactSettings() async => exactSettingsOpened++;

  @override
  Future<void> showTest(String title, String body) async => tests.add((title, body));
}
