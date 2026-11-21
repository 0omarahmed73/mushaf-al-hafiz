import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/reminders/kahf_day.dart';
import 'package:mushaf/reminders/kahf_strings.dart';
import 'package:mushaf/reminders/reminder_planner.dart';

void main() {
  group('KahfDay', () {
    test('reads the stored text, Thursday for anything it does not know', () {
      expect(KahfDay.fromStorage(null), KahfDay.thursday);
      expect(KahfDay.fromStorage(''), KahfDay.thursday);
      expect(KahfDay.fromStorage('monday'), KahfDay.thursday);
      expect(KahfDay.fromStorage('Friday'), KahfDay.thursday);
      expect(KahfDay.fromStorage('thursday'), KahfDay.thursday);
      expect(KahfDay.fromStorage('friday'), KahfDay.friday);
    });

    test('has a storage value and a weekday each', () {
      expect(KahfDay.thursday.storageValue, 'thursday');
      expect(KahfDay.friday.storageValue, 'friday');
      expect(KahfDay.thursday.weekday, DateTime.thursday);
      expect(KahfDay.friday.weekday, DateTime.friday);
      expect(KahfDay.values.length, 2);
    });

    test('every value reads back from its own storage value', () {
      for (final d in KahfDay.values) {
        expect(KahfDay.fromStorage(d.storageValue), d);
      }
    });
  });

  group('strings (confirmed by the owner on 2026-11-21)', () {
    test('the new Arabic strings are exactly as confirmed', () {
      expect(kKahfBodyFriday, 'يوم الجمعة: لا تنسَ قراءة سورة الكهف');
      expect(kKahfDayHeading, 'يوم التذكير');
      expect(kKahfDayThursdayLabel, 'الخميس');
      expect(kKahfDayThursdayName, 'الخميس (ليلة الجمعة)');
      expect(kKahfDayFridayLabel, 'الجمعة');
      expect(kKahfSwitchTitleFriday, 'تذكير سورة الكهف يوم الجمعة');
      expect(kKahfSwitchSubtitleFriday, 'كل جمعة في الوقت الذي تختاره');
      expect(kKahfChannelName, 'تذكير سورة الكهف');
    });

    test('Thursday keeps today\'s texts', () {
      expect(kKahfSwitchTitleThursday, 'تذكير سورة الكهف ليلة الجمعة');
      expect(kKahfSwitchSubtitleThursday, 'كل خميس في الوقت الذي تختاره');
      expect(kKahfTitle, 'سورة الكهف');
      expect(kKahfBody, 'ليلة الجمعة: لا تنسَ قراءة سورة الكهف');
    });

    test('the Friday body differs from the Thursday body', () {
      expect(kKahfBodyFriday, isNot(kKahfBody));
    });
  });

  group('the notification channel\'s name in the phone\'s settings', () {
    test('names no weekday', () {
      expect(kKahfChannelName, isNot(contains('الخميس')));
      expect(kKahfChannelName, isNot(contains('الجمعة')));
    });

    test('is used by the notification service, whose channel id stays', () {
      // The plugin cannot run in a test, so the source is read.
      final source = File('lib/reminders/reminder_service.dart')
          .readAsStringSync();
      expect(source, contains('kKahfChannelName'));
      expect(source, isNot(contains("'سورة الكهف ليلة الجمعة'")));
      expect(source, contains("_kahfChannel = 'kahf_reminders'"));
    });
  });
}
