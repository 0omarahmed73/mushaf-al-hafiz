import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/splash/splash_palette.dart';
import 'package:mushaf/splash/splash_strings.dart';

void main() {
  test('the name is the app name everywhere', () {
    expect(kSplashName, 'مصحف الحافظ');
    expect(kSplashName, MushafApp.title);
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:label="$kSplashName"'));
  });

  test('the tagline is the line of the design (a proposal)', () {
    expect(kSplashTagline, 'المصحف كاملاً بلا إنترنت وبلا إعلانات');
    final source = File('lib/splash/splash_strings.dart').readAsStringSync();
    // Constitution VI: an Arabic string written by the assistant is marked as a proposal.
    expect(source, contains('PROPOSAL'));
  });

  test('the colours are the design\'s', () {
    expect(SplashColors.background, const Color(0xFF0D1014));
    expect(SplashColors.backdropGlow, const Color(0xFF17313A));
    expect(SplashColors.name, const Color(0xFFECE7DC));
    expect(SplashColors.tagline, const Color(0xFF9AA4AD));
    expect(SplashColors.progressTrack, const Color(0xFF232A33));
    expect(SplashColors.progressFill, const Color(0xFF6CC4B5));
    expect(SplashColors.ringNear, const Color(0xFF232A33));
    expect(SplashColors.ringFar, const Color(0xFF1B2128));
    expect(SplashColors.tileTop, const Color(0xFF1A212A));
    expect(SplashColors.star, const Color(0xFF6CC4B5));
    expect(SplashColors.pageLeft, const Color(0xFFECE7DC));
    expect(SplashColors.pageRight, const Color(0xFFD6D0C1));
    expect(SplashColors.pageInk, const Color(0xFF8A939C));
    expect(SplashColors.gold, const Color(0xFFE3B05A));
  });
}
