// Feature 010 measurement M2: what it costs to load one per-page QCF V2 font (research.md H3).
// The fonts are 180-400 KB each (153 MB for 604). Prints numbers; only generous bounds are asserted.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/mushaf/page_font_loader.dart';

import '../support/motion_probe.dart';

String _font(int page) => 'assets/fonts/qpc-v2/p$page.ttf';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('M2a: size of the page fonts (all 604)', () {
    final sizes = [
      for (var p = 1; p <= 604; p++) File(_font(p)).lengthSync() / 1024,
    ];
    final stats = MotionStats(sizes);
    final total = sizes.fold<double>(0, (a, b) => a + b);
    motionLog(
      'M2a font size KB per page: min=${stats.min.toStringAsFixed(0)} '
      'median=${stats.median.toStringAsFixed(0)} p95=${stats.p95.toStringAsFixed(0)} '
      'max=${stats.max.toStringAsFixed(0)}; all 604 = ${(total / 1024).toStringAsFixed(0)} MB',
    );
    expect(sizes.length, 604);
  });

  test('M2b: PageFontLoader.ensure on a cold page (read + engine font registration)', () async {
    final bundle = FileBundle();
    final fonts = PageFontLoader(bundle: bundle);
    // Warm up with pages we do not measure.
    for (final p in [3, 4, 5]) {
      await fonts.ensure(p);
    }
    final pages = samplePages(31).where((p) => p > 5).toList();
    final total = <double>[];
    final registerOnly = <double>[];
    for (final p in pages) {
      final s = Stopwatch()..start();
      await fonts.ensure(p);
      s.stop();
      total.add(ms(s));
    }
    // Registration alone: bytes already in memory, so this is what the engine charges the UI thread for.
    var n = 0;
    for (final p in pages) {
      final bytes = await File(_font(p)).readAsBytes();
      final loader = FontLoader('motion_probe_$p')
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      final s = Stopwatch()..start();
      await loader.load();
      s.stop();
      registerOnly.add(ms(s));
      n++;
    }
    motionLog(
      'M2b ensure() per cold page, read+register ($n pages): ${MotionStats(total)}',
    );
    motionLog(
      'M2b FontLoader.load() alone, bytes in memory ($n pages): ${MotionStats(registerOnly)}',
    );

    // A jump: prefetch asks for five fonts at once (page +- 2).
    final jump = Stopwatch()..start();
    fonts.prefetch(450);
    await Future.wait([for (var p = 448; p <= 452; p++) fonts.ensure(p)]);
    jump.stop();
    motionLog(
      'M2b prefetch of 5 fonts after a jump to page 450, all complete: ${ms(jump).toStringAsFixed(2)} ms',
    );

    final warm = <double>[];
    for (var i = 0; i < 50; i++) {
      final s = Stopwatch()..start();
      await fonts.ensure(450);
      s.stop();
      warm.add(ms(s));
    }
    motionLog('M2b ensure() on a loaded page: ${MotionStats(warm)}');
    expect(MotionStats(total).max, lessThan(2000));
  });
}
