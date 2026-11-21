import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) => File(path).readAsStringSync();

void main() {
  final main = read('lib/main.dart');

  test('main draws the splash first and boots the app behind it', () {
    expect(main, contains("import 'splash/splash_gate.dart';"));
    expect(main, contains("import 'splash/app_when_ready.dart';"));
    expect(main, contains('Future<MushafApp> _bootApp()'));
    // Whitespace-insensitive: main also hands the splash's onFinished to the first-run tips (feature 008).
    expect(RegExp(r'runApp\(\s*SplashGate\(').hasMatch(main), isTrue);
    expect(main, contains('AppWhenReady('));
    expect(RegExp(r'ready:\s*app\b').hasMatch(main), isTrue);
    // Exactly one runApp, and nothing is awaited before it: the first frame does not wait for the loading.
    expect('runApp('.allMatches(main), hasLength(1));
    final body = main.substring(
      main.indexOf('Future<void> main()'),
      main.indexOf('runApp('),
    );
    expect(body, isNot(contains('await ')));
    expect(body, contains('WidgetsFlutterBinding.ensureInitialized();'));
  });

  test('the loading that used to run before the first frame still runs, in _bootApp', () {
    final boot = main.substring(
      main.indexOf('Future<MushafApp> _bootApp()'),
      main.indexOf('/// Starts notifications'),
    );
    for (final step in [
      'AppDatabase.open()',
      'ensureDefaults()',
      '_startReminders(',
      'TempShareFiles().clean()',
      'textSize.load()',
      'appLook.load()',
      'return MushafApp(',
    ]) {
      expect(boot, contains(step), reason: step);
    }
  });

  test('the app widget and the existing tests know nothing of the splash', () {
    expect(read('lib/app.dart').toLowerCase(), isNot(contains('splash')));
    for (final f in Directory(
      'test',
    ).listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.startsWith('test/splash/')) {
        continue;
      }
      expect(
        f.readAsStringSync(),
        isNot(contains('SplashGate')),
        reason: f.path,
      );
    }
  });

  test('the splash code imports only Flutter, dart: and its own files (no theme, setting, database, network)', () {
    final allowed = RegExp(
      r'''^import '(dart:[a-z_]+|package:flutter/[a-z_]+\.dart|[a-z_]+\.dart)'(?: (?:as \w+|hide \w+|show [\w, ]+))*;$''',
    );
    for (final f in Directory('lib/splash').listSync().whereType<File>()) {
      for (final line in f.readAsLinesSync().where(
        (l) => l.startsWith('import '),
      )) {
        expect(allowed.hasMatch(line), isTrue, reason: '${f.path}: $line');
      }
      expect(f.readAsStringSync(), isNot(contains('dart:io')), reason: f.path);
    }
  });

  test('no package, font or asset was added for the splash', () {
    final pubspec = read('pubspec.yaml');
    for (final banned in [
      'flutter_svg',
      'flutter_native_splash',
      'flutter_launcher_icons',
      'lottie',
      'rive',
    ]) {
      expect(
        RegExp('\\b$banned\\b').hasMatch(pubspec),
        isFalse,
        reason: banned,
      );
    }
    expect(pubspec, isNot(contains('assets/splash')));
  });
}
