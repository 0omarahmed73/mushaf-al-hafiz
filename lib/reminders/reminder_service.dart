import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../prayer/prayer_strings.dart';
import 'kahf_strings.dart';
import 'reminder_planner.dart';

/// What the app needs from the phone's notification system. Tests use a fake.
abstract class ReminderService {
  /// Prepares notifications; [onTap] gets the payload of a notification the user taps, including the
  /// one that started the app.
  Future<void> init({void Function(String payload)? onTap});

  /// Whether the user has allowed this app to show notifications.
  Future<bool> notificationsAllowed();

  /// Asks for the notification permission (Android 13+). Returns whether it is now allowed.
  Future<bool> requestPermission();

  /// Cancels every scheduled notification and schedules [plan] instead.
  Future<void> reschedule(List<PlannedReminder> plan);

  /// Whether exact alarms are allowed (feature 014, research D7). Always true before Android 12.
  Future<bool> exactAllowed();

  /// Opens the phone's setting that allows exact alarms for this app.
  Future<void> openExactSettings();

  /// Shows one prayer notification now, with the prayer sound (the «جرّب التنبيه» button, FR-023).
  Future<void> showTest(String title, String body);
}

/// Carries notification taps from the plugin (which can fire before any screen exists) to the reader.
class NotificationTaps {
  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  String? _pending;

  /// Taps that happen while a screen is listening.
  Stream<String> get stream => _controller.stream;

  void add(String payload) {
    _pending = payload;
    _controller.add(payload);
  }

  /// The last tap nobody has handled yet (a notification that started the app), once.
  String? takePending() {
    final p = _pending;
    _pending = null;
    return p;
  }
}

/// Local notifications on the phone, scheduled with `zonedSchedule` in inexact mode (no
/// exact-alarm permission) so they arrive with the screen locked and survive a restart.
class LocalNotificationService implements ReminderService {
  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const String _wirdChannel = 'wird_reminders';
  static const String _kahfChannel = 'kahf_reminders';

  // Feature 014 (research D8): a channel's sound is fixed once the channel exists, so each sound has its own channel.
  // The «بصوت» channel plays the bundled takbir (task T032). Builds before it made `prayer_sound` with the default
  // sound, and Android keeps a channel's first sound, so the takbir has a channel id of its own.
  static const String _prayerSoundChannel = 'prayer_sound_2';
  static const String _prayerSilentChannel = 'prayer_silent';
  static const String _prayerBeforeChannel = 'prayer_before';

  /// The channel and sound of each kind of reminder.
  @visibleForTesting
  static AndroidNotificationDetails detailsFor(ReminderKind kind) =>
      _details(kind);

  static AndroidNotificationDetails _details(ReminderKind kind) =>
      switch (kind) {
        ReminderKind.wird => const AndroidNotificationDetails(
          _wirdChannel,
          'تذكير الأوراد',
          importance: Importance.high,
          priority: Priority.high,
        ),
        ReminderKind.kahf => const AndroidNotificationDetails(
          _kahfChannel,
          kKahfChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        ReminderKind.prayerSound => const AndroidNotificationDetails(
          _prayerSoundChannel,
          kChannelSound,
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('takbir'),
        ),
        ReminderKind.prayerSilent => const AndroidNotificationDetails(
          _prayerSilentChannel,
          kChannelSilent,
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: false,
        ),
        ReminderKind.prayerBefore => const AndroidNotificationDetails(
          _prayerBeforeChannel,
          kChannelBefore,
          importance: Importance.high,
          priority: Priority.high,
        ),
      };

  @override
  Future<void> init({void Function(String payload)? onTap}) async {
    tzdata.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && onTap != null) onTap(payload);
      },
    );
    if (onTap == null) return;
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if ((launch?.didNotificationLaunchApp ?? false) && payload != null) {
      onTap(payload);
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> notificationsAllowed() async =>
      await _android?.areNotificationsEnabled() ?? true;

  @override
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? true;

  @override
  Future<void> reschedule(List<PlannedReminder> plan) async {
    // Only what is still waiting: a notification already in the tray stays there.
    await _plugin.cancelAllPendingNotifications();
    for (final r in plan) {
      final a = r.at;
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        payload: r.payload,
        scheduledDate: tz.TZDateTime(
          tz.local,
          a.year,
          a.month,
          a.day,
          a.hour,
          a.minute,
        ),
        notificationDetails: NotificationDetails(android: _details(r.kind)),
        androidScheduleMode: r.exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<bool> exactAllowed() async {
    try {
      return await _android?.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openExactSettings() async {
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  @override
  Future<void> showTest(String title, String body) => _plugin.show(
    id: kPrayerIdBase - 1,
    title: title,
    body: body,
    payload: 'prayer',
    notificationDetails: NotificationDetails(
      android: _details(ReminderKind.prayerSound),
    ),
  );
}
