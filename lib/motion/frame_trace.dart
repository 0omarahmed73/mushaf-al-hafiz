import 'dart:ui' show FrameTiming, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Built with `--dart-define=FRAME_TRACE=true`, every frame logs how long it took, so a swipe can be measured on the phone
/// (specs/010-smooth-motion/research.md D9): `FRAMETRACE build=<ms> raster=<ms> total=<ms>`, and once
/// `FRAMETRACE refresh=<hz>`. Off, and free (a compile-time constant), in normal builds; it prints to the local log only.
abstract final class FrameTrace {
  static const bool enabled = bool.fromEnvironment('FRAME_TRACE');

  /// Registers the timings callback when [enabled]; does nothing otherwise.
  static void install({void Function(String line) log = _print}) {
    if (!enabled) return;
    final hz =
        PlatformDispatcher.instance.views.firstOrNull?.display.refreshRate;
    if (hz != null) log('FRAMETRACE refresh=${hz.toStringAsFixed(1)}');
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final t in timings) {
        log('FRAMETRACE ${formatFrame(t)}');
      }
    });
  }

  static void _print(String line) => debugPrint(line);

  /// `build=<ms> raster=<ms> total=<ms>`, two decimals.
  static String formatFrame(FrameTiming t) {
    String ms(Duration d) => (d.inMicroseconds / 1000).toStringAsFixed(2);
    return 'build=${ms(t.buildDuration)} raster=${ms(t.rasterDuration)} total=${ms(t.totalSpan)}';
  }

  /// What a swipe start prints under `PAGE_TURN_TRACE`: whether the two neighbours were ready (SC-002).
  static String warmLine({required bool next, required bool prev}) =>
      'PAGEWARM next=$next prev=$prev';
}
