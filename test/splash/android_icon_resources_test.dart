import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/splash/icon_geometry.dart';

import '../../tool/app_icon_resources.dart';
import 'support/pixels.dart';
import 'support/xml_check.dart';

const String res = 'android/app/src/main/res';

XmlElement xml(String path) => parseXml(File('$res/$path').readAsStringSync());

const regenerate = 'regenerate with: flutter test tool/make_app_icons.dart';

bool ivory(Color c) => c.a > 0.9 && c.r > 0.82 && c.g > 0.8 && c.b > 0.72;
bool teal(Color c) => c.a > 0.9 && c.g > 0.62 && c.b > 0.55 && c.r < 0.55;
bool gold(Color c) =>
    c.a > 0.9 && c.r > 0.72 && c.g > 0.5 && c.b < 0.5 && c.r - c.b > 0.3;
bool dark(Color c) => c.a > 0.9 && c.r < 0.2 && c.g < 0.2 && c.b < 0.22;

void main() {
  group('the adaptive icon (Android 8 and later)', () {
    test(
      'names a background, a foreground and a monochrome layer that exist',
      () {
        final root = xml('mipmap-anydpi-v26/ic_launcher.xml');
        expect(root.name, 'adaptive-icon');
        final layers = {
          for (final c in root.children)
            c.name: c.attributes['android:drawable'],
        };
        expect(layers, {
          'background': '@drawable/ic_launcher_background',
          'foreground': '@drawable/ic_launcher_foreground',
          'monochrome': '@drawable/ic_launcher_monochrome',
        });
        for (final name in ['background', 'foreground', 'monochrome']) {
          final file = File('$res/drawable/ic_launcher_$name.xml');
          expect(file.existsSync(), isTrue, reason: '$name layer is missing');
          final v = parseXml(file.readAsStringSync());
          expect(v.name, 'vector', reason: name);
          expect(v.attributes['android:width'], '108dp');
          expect(v.attributes['android:height'], '108dp');
          expect(v.attributes['android:viewportWidth'], '108');
          expect(v.attributes['android:viewportHeight'], '108');
        }
      },
    );

    test(
      'the three vector layers are what the tool writes from the geometry',
      () {
        expect(
          File('$res/drawable/ic_launcher_background.xml').readAsStringSync(),
          AppIconResources.background(),
          reason: regenerate,
        );
        expect(
          File('$res/drawable/ic_launcher_foreground.xml').readAsStringSync(),
          AppIconResources.foreground(),
          reason: regenerate,
        );
        expect(
          File('$res/drawable/ic_launcher_monochrome.xml').readAsStringSync(),
          AppIconResources.monochrome(),
          reason: regenerate,
        );
      },
    );

    test('the background is the night gradient with the teal glow', () {
      final v = xml('drawable/ic_launcher_background.xml');
      final gradients = v.descendants('gradient');
      expect(gradients, hasLength(2));
      expect(gradients[0].attributes['android:type'], 'linear');
      expect(gradients[0].attributes['android:endY'], '108');
      expect(
        gradients[0]
            .descendants('item')
            .map((i) => i.attributes['android:color']),
        ['#FF1A212A', '#FF0D1014'],
      );
      expect(gradients[1].attributes['android:type'], 'radial');
      expect(gradients[1].attributes['android:centerX'], '54');
      expect(gradients[1].attributes['android:centerY'], '30');
      expect(gradients[1].attributes['android:gradientRadius'], '48');
      expect(
        gradients[1]
            .descendants('item')
            .map((i) => i.attributes['android:color']),
        ['#4D6CC4B5', '#006CC4B5'],
      );
    });

    test('the foreground draws the art, placed inside the safe circle', () {
      final v = xml('drawable/ic_launcher_foreground.xml');
      final group = v.descendants('group').single;
      const p = AppIconGeometry.adaptive;
      expect(
        group.attributes['android:pivotX'],
        '${p.pivot.dx}'.replaceAll('.0', ''),
      );
      expect(group.attributes['android:pivotY'], '${p.pivot.dy}');
      expect(group.attributes['android:scaleX'], '${p.scale}');
      expect(group.attributes['android:scaleY'], '${p.scale}');
      expect(group.attributes['android:translateX'] ?? '0', anyOf('0', '0.0'));
      expect(group.attributes['android:translateY'], '${p.shift.dy}');
      final data = group
          .descendants('path')
          .map((e) => e.attributes['android:pathData'])
          .toSet();
      expect(data, {
        AppIconGeometry.starSquare,
        AppIconGeometry.starDiamond,
        AppIconGeometry.starHole,
        AppIconGeometry.pageLeft,
        AppIconGeometry.pageRight,
        AppIconGeometry.spine,
        AppIconGeometry.pagesLinesLeft,
        AppIconGeometry.pagesLinesRight,
        AppIconGeometry.goldLine,
      });
      expect(AppIconGeometry.farthestFromCentre(p), lessThanOrEqualTo(33));
    });

    test('the monochrome layer is one colour with a hole in the star', () {
      final v = xml('drawable/ic_launcher_monochrome.xml');
      final colours = <String>{};
      for (final e in v.all) {
        for (final k in ['android:fillColor', 'android:strokeColor']) {
          final c = e.attributes[k];
          if (c != null) colours.add(c);
        }
      }
      expect(colours, {'#FFFFFFFF'});
      expect(v.descendants('gradient'), isEmpty);
      final star = v
          .descendants('path')
          .where((e) => e.attributes['android:fillType'] == 'evenOdd');
      expect(star, hasLength(1));
      expect(
        star.single.attributes['android:pathData'],
        '${AppIconGeometry.monochromeStar} ${AppIconGeometry.starHole}',
      );
      final data = v
          .descendants('path')
          .map((e) => e.attributes['android:pathData'])
          .toSet();
      expect(
        data,
        containsAll([
          AppIconGeometry.monochromePageLeft,
          AppIconGeometry.monochromePageRight,
          AppIconGeometry.goldLine,
        ]),
      );
    });
  });

  group('the old-style icons (Android 7)', () {
    const sizes = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    for (final MapEntry(key: density, value: size) in sizes.entries) {
      testWidgets('$density is a $size px picture of the icon', (tester) async {
        final file = File('$res/mipmap-$density/ic_launcher.png');
        expect(file.existsSync(), isTrue);
        final bytes = file.readAsBytesSync();
        expect(bytes.sublist(0, 8), [
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ]);
        final header = ByteData.sublistView(Uint8List.fromList(bytes), 16, 24);
        expect(header.getUint32(0), size, reason: 'width');
        expect(header.getUint32(4), size, reason: 'height');

        final pixels = await decodePng(tester, bytes);
        // A rounded square: the corners are transparent, the middle is not.
        expect(pixels.at(0, 0).a, 0, reason: 'top-left corner');
        expect(
          pixels.at(size - 1, size - 1).a,
          0,
          reason: 'bottom-right corner',
        );
        expect(pixels.at(size ~/ 2, size ~/ 2).a, 1);
        // The palette of the design, so the Flutter default icon cannot pass.
        var ivoryN = 0, tealN = 0, goldN = 0, darkN = 0;
        for (var y = 0; y < size; y++) {
          for (var x = 0; x < size; x++) {
            final c = pixels.at(x, y);
            if (ivory(c)) ivoryN++;
            if (teal(c)) tealN++;
            if (gold(c)) goldN++;
            if (dark(c)) darkN++;
          }
        }
        final area = size * size;
        expect(ivoryN / area, greaterThan(0.06), reason: 'pages');
        expect(tealN / area, greaterThan(0.002), reason: 'star');
        expect(goldN / area, greaterThan(0.0015), reason: 'gold line');
        expect(darkN / area, greaterThan(0.35), reason: 'night background');
      });
    }

    test('no other density folder keeps the Flutter default', () {
      final dirs = Directory(res)
          .listSync()
          .whereType<Directory>()
          .map((d) => d.path.split('/').last)
          .where((n) => n.startsWith('mipmap-') && n != 'mipmap-anydpi-v26')
          .toSet();
      expect(dirs, sizes.keys.map((d) => 'mipmap-$d').toSet());
    });
  });
}
