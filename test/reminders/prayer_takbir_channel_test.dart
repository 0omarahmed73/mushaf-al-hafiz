// The prayer notification's takbir (feature 014, T032, research D8): the «بصوت» channel plays the bundled
// `res/raw/takbir.ogg`. A channel's sound is fixed once Android has it, and earlier builds made `prayer_sound` with the
// default sound, so the takbir gets a new channel id. Release builds keep the raw file through `keep.xml`.
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/reminders/reminder_planner.dart';
import 'package:mushaf/reminders/reminder_service.dart';

void main() {
  test('the sound channel plays the takbir on a new channel id', () {
    final d = LocalNotificationService.detailsFor(ReminderKind.prayerSound);
    expect(d.channelId, 'prayer_sound_2');
    expect(d.sound, isA<RawResourceAndroidNotificationSound>());
    expect(d.sound!.sound, 'takbir');
    expect(d.playSound, isTrue);
  });

  test('the silent and before channels are as they were', () {
    expect(
      LocalNotificationService.detailsFor(ReminderKind.prayerSilent).channelId,
      'prayer_silent',
    );
    expect(
      LocalNotificationService.detailsFor(ReminderKind.prayerSilent).playSound,
      isFalse,
    );
    expect(
      LocalNotificationService.detailsFor(ReminderKind.prayerBefore).channelId,
      'prayer_before',
    );
    expect(
      LocalNotificationService.detailsFor(ReminderKind.prayerBefore).sound,
      isNull,
    );
  });

  test('release builds keep the raw takbir', () {
    final keep = File('android/app/src/main/res/raw/keep.xml');
    expect(keep.existsSync(), isTrue);
    expect(keep.readAsStringSync(), contains('@raw/takbir'));
  });
}
