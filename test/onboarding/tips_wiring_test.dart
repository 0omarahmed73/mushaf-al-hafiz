// How main() puts the first-run tips (feature 008) behind the splash (feature 009): the tips gate sits around the
// reader as the app's home, stays closed until the splash says it is gone, and nothing else in the app knows of it.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) => File(path).readAsStringSync();

void main() {
  final main = read('lib/main.dart');

  test(
    'the reader stays the home screen, inside a gate that waits for the splash',
    () {
      expect(main, contains("import 'onboarding/tips_gate.dart';"));
      expect(main, contains("import 'mushaf/reader_screen.dart';"));
      expect(main, contains('home: ValueListenableBuilder<bool>('));
      expect(main, contains('child: const ReaderScreen()'));
      expect(main, contains('TipsGate(enabled: gone, child: reader!)'));
    },
  );

  test('the splash opens the gate once it is gone', () {
    expect(
      RegExp(r'onFinished:\s*\(\)\s*=>\s*_splashGone\.value\s*=\s*true')
          .hasMatch(main),
      isTrue,
    );
    expect(
      main,
      contains(
        'final ValueNotifier<bool> _splashGone = ValueNotifier<bool>(false);',
      ),
    );
  });

  test('the app widget and the other tests know nothing of the gate', () {
    expect(read('lib/app.dart'), isNot(contains('TipsGate')));
    for (final f in Directory(
      'test',
    ).listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') ||
          f.path.startsWith('test/onboarding/') ||
          f.path == 'test/support/tips_harness.dart') {
        continue;
      }
      expect(
        f.readAsStringSync(),
        isNot(contains('TipsGate(')),
        reason: f.path,
      );
    }
  });
}
