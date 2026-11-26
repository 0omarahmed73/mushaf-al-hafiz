// The permissions of feature 014 (SC-007, constitution 3.0.0): the approximate location and exact alarms are added;
// the app still has no Internet, precise or background location, or USE_EXACT_ALARM. The release APK is also checked
// with `aapt2 dump permissions` before a Play build (quickstart).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the app manifest asks only what feature 014 allows', () {
    final m = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    bool has(String p) => m.contains('android:name="android.permission.$p"');
    expect(has('ACCESS_COARSE_LOCATION'), isTrue);
    expect(has('SCHEDULE_EXACT_ALARM'), isTrue);
    for (final p in [
      'INTERNET',
      'ACCESS_FINE_LOCATION',
      'ACCESS_BACKGROUND_LOCATION',
      'USE_EXACT_ALARM',
    ]) {
      expect(has(p), isFalse, reason: p);
    }
  });
}
