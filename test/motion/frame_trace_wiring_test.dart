// main() starts the frame trace (feature 010, task T002): after the binding exists and before the first frame is asked for;
// it does nothing unless the build was made with FRAME_TRACE (the compile-time constant), so a release build pays nothing.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main installs the frame trace between the binding and runApp, and awaits nothing before it', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains("import 'motion/frame_trace.dart';"));
    final binding = main.indexOf('WidgetsFlutterBinding.ensureInitialized();');
    final install = main.indexOf('FrameTrace.install();');
    final run = main.indexOf('runApp(');
    expect(binding, greaterThanOrEqualTo(0));
    expect(install, greaterThan(binding));
    expect(run, greaterThan(install));
    expect(
      main.substring(main.indexOf('Future<void> main()'), run),
      isNot(contains('await ')),
    );
  });

  test('the trace is off unless the build asks for it', () {
    final trace = File('lib/motion/frame_trace.dart').readAsStringSync();
    expect(trace, contains("bool.fromEnvironment('FRAME_TRACE')"));
    expect(trace, contains('if (!enabled) return;'));
  });
}
