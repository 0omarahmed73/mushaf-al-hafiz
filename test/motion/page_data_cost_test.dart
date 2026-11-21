// Feature 010 measurement M1: what it costs to read and parse one Mushaf page (research.md H5).
// Prints numbers; only generous bounds are asserted.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';

import '../support/motion_probe.dart';

String _asset(int page) =>
    'assets/mushaf/pages/p${page.toString().padLeft(3, '0')}.json';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('M1a: parse the JSON of every page (604) on the calling isolate', () {
    // Warm up the JIT so the first page does not count for the rest.
    for (var i = 0; i < 20; i++) {
      PageData.fromJson(
        jsonDecode(File(_asset(1 + i)).readAsStringSync())
            as Map<String, dynamic>,
      );
    }
    final decode = <double>[];
    final build = <double>[];
    var words = 0;
    var bytes = 0;
    final byteSizes = <int>[];
    for (var p = 1; p <= 604; p++) {
      final text = File(_asset(p)).readAsStringSync();
      bytes += text.length;
      byteSizes.add(text.length);
      final a = Stopwatch()..start();
      final json = jsonDecode(text) as Map<String, dynamic>;
      a.stop();
      final b = Stopwatch()..start();
      final data = PageData.fromJson(json);
      b.stop();
      decode.add(ms(a));
      build.add(ms(b));
      words += data.lines.fold<int>(0, (n, l) => n + l.words.length);
    }
    byteSizes.sort();
    motionLog(
      'M1a jsonDecode per page: ${MotionStats(decode)} | PageData.fromJson per page: ${MotionStats(build)}',
    );
    motionLog(
      'M1a pages=604 words=$words (mean ${(words / 604).toStringAsFixed(1)} per page) '
      'json total=${(bytes / 1024).toStringAsFixed(0)} KB, smallest=${byteSizes.first} B, '
      'largest=${byteSizes.last} B',
    );
    // A single page parse must never come close to a frame; generous: the test VM is JIT and unoptimised.
    expect(MotionStats(decode).max + MotionStats(build).max, lessThan(100));
  });

  test('M1b: MushafRepository.loadPage, cold (two asset reads and two parses per page) and warm (cache)', () async {
    final bundle = FileBundle();
    final repo = MushafRepository(bundle);
    // Warm up with pages we do not measure.
    for (var p = 300; p < 310; p++) {
      await repo.loadPage(p);
    }
    bundle.loads.clear();
    final cold = <double>[];
    var reads = 0;
    for (var p = 100; p < 160; p += 2) {
      final before = bundle.loads.length;
      final s = Stopwatch()..start();
      await repo.loadPage(p);
      s.stop();
      cold.add(ms(s));
      reads += bundle.loads.length - before;
    }
    final loadsPerPage = reads / cold.length;
    motionLog(
      'M1b loadPage cold (neighbour page not seen yet): ${MotionStats(cold)}',
    );
    motionLog(
      'M1b asset reads per cold loadPage: ${loadsPerPage.toStringAsFixed(2)} '
      '(1 for the page, +1 for the next page only to learn its first word)',
    );

    // The second page of a run already knows the next page's first word from the first read.
    bundle.loads.clear();
    final run = <double>[];
    var runReads = 0;
    for (var p = 200; p < 230; p++) {
      final before = bundle.loads.length;
      final s = Stopwatch()..start();
      await repo.loadPage(p);
      s.stop();
      run.add(ms(s));
      runReads += bundle.loads.length - before;
    }
    motionLog(
      'M1b loadPage in a forward run of 30 pages: ${MotionStats(run)}; reads per page '
      '${(runReads / run.length).toStringAsFixed(2)}',
    );

    final warm = <double>[];
    for (var i = 0; i < 100; i++) {
      final s = Stopwatch()..start();
      await repo.loadPage(220 + i % 8);
      s.stop();
      warm.add(ms(s));
    }
    motionLog('M1b loadPage warm (in the 8-page cache): ${MotionStats(warm)}');
    expect(MotionStats(cold).max, lessThan(100));
  });
}
