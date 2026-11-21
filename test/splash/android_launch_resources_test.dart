import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/xml_check.dart';

const String res = 'android/app/src/main/res';

XmlElement xml(String path) => parseXml(File('$res/$path').readAsStringSync());

/// The `<style>` called [name] of a styles file, as a map of item name to value plus its parent.
({String parent, Map<String, String> items}) style(String file, String name) {
  final s = xml(file)
      .descendants('style')
      .firstWhere(
        (e) => e.attributes['name'] == name,
        orElse: () => throw TestFailure('$file has no style $name'),
      );
  return (
    parent: s.attributes['parent'] ?? '',
    items: {
      for (final i in s.descendants('item')) i.attributes['name']!: i.text,
    },
  );
}

/// Whether a resource named by a reference like `@drawable/x` exists in the res folder.
bool exists(String reference) {
  final m = RegExp(r'^@(\w+)/(\w+)$').firstMatch(reference);
  if (m == null) return false;
  final type = m[1]!;
  final name = m[2]!;
  if (type == 'color') {
    return xml('values/colors.xml')
        .descendants('color')
        .any((c) => c.attributes['name'] == name);
  }
  final folders = Directory(res).listSync().whereType<Directory>().where(
    (d) =>
        d.path.split('/').last.startsWith('$type-') ||
        d.path.endsWith('/$type'),
  );
  return folders.any(
    (d) => d.listSync().any((f) {
      final file = f.path.split('/').last;
      return file == '$name.xml' || file == '$name.png';
    }),
  );
}

void main() {
  const launchFiles = [
    'drawable/launch_background.xml',
    'drawable-v21/launch_background.xml',
    'values/styles.xml',
    'values-night/styles.xml',
    'values-v31/styles.xml',
    'values-night-v31/styles.xml',
    'values/colors.xml',
  ];

  test('every launch resource exists and is well formed', () {
    for (final f in launchFiles) {
      expect(File('$res/$f').existsSync(), isTrue, reason: f);
      xml(f);
    }
  });

  test('the splash background is the night colour', () {
    final colors = xml('values/colors.xml').descendants('color');
    final c = colors.singleWhere(
      (e) => e.attributes['name'] == 'splash_background',
    );
    expect(c.text.toUpperCase(), anyOf('#0D1014', '#FF0D1014'));
  });

  for (final file in [
    'drawable/launch_background.xml',
    'drawable-v21/launch_background.xml',
  ]) {
    test('$file is dark with the icon in the middle and no white', () {
      final raw = File('$res/$file').readAsStringSync();
      expect(raw.toLowerCase(), isNot(contains('white')));
      expect(raw, isNot(contains('colorBackground')));
      final root = xml(file);
      expect(root.name, 'layer-list');
      final items = root.children.where((e) => e.name == 'item').toList();
      expect(items, hasLength(2));
      expect(
        items[0].attributes['android:drawable'],
        '@color/splash_background',
      );
      expect(
        items[1].attributes['android:drawable'],
        '@drawable/ic_launcher_foreground',
      );
      expect(items[1].attributes['android:gravity'], 'center');
      expect(items[1].attributes['android:width'], '140dp');
      expect(items[1].attributes['android:height'], '140dp');
    });
  }

  for (final file in ['values/styles.xml', 'values-night/styles.xml']) {
    test('$file starts dark in both day and night sets', () {
      final launch = style(file, 'LaunchTheme');
      expect(launch.parent, '@android:style/Theme.Black.NoTitleBar');
      expect(
        launch.items['android:windowBackground'],
        '@drawable/launch_background',
      );
      final normal = style(file, 'NormalTheme');
      expect(
        normal.items['android:windowBackground'],
        '@color/splash_background',
      );
      expect(
        File('$res/$file').readAsStringSync(),
        isNot(contains('colorBackground')),
      );
    });
  }

  for (final file in ['values-v31/styles.xml', 'values-night-v31/styles.xml']) {
    test('$file styles the Android 12 system splash', () {
      final launch = style(file, 'LaunchTheme');
      expect(launch.parent, '@android:style/Theme.Black.NoTitleBar');
      expect(
        launch.items['android:windowBackground'],
        '@drawable/launch_background',
      );
      expect(
        launch.items['android:windowSplashScreenBackground'],
        '@color/splash_background',
      );
      expect(
        launch.items['android:windowSplashScreenAnimatedIcon'],
        '@drawable/ic_launcher_foreground',
      );
      expect(
        int.parse(launch.items['android:windowSplashScreenAnimationDuration']!),
        inInclusiveRange(1, 1000),
      );
      expect(
        style(file, 'NormalTheme').items['android:windowBackground'],
        '@color/splash_background',
      );
    });
  }

  test(
    'the day and night files of Android 12 are identical (dark in both)',
    () {
      expect(
        File('$res/values-v31/styles.xml').readAsStringSync(),
        File('$res/values-night-v31/styles.xml').readAsStringSync(),
      );
    },
  );

  test('every reference in the launch files resolves', () {
    final refs = RegExp(r'@(?:drawable|color|mipmap)/\w+');
    for (final f in launchFiles) {
      final raw = File('$res/$f').readAsStringSync();
      for (final m in refs.allMatches(raw)) {
        expect(exists(m[0]!), isTrue, reason: '${m[0]} in $f');
      }
    }
  });

  test('the manifest still points at the launch and normal themes', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:theme="@style/LaunchTheme"'));
    expect(manifest, contains('android:resource="@style/NormalTheme"'));
    expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
  });
}
