// The offscreen renderer in Night Reader (spec FR-010, FR-011, SC-007; research D4), over the real page data and
// fonts: a Night picture and a Night PDF page carry Night's colours (the dark background, the light ink, the teal
// title and ayah markers, the hairlines) and none of Emerald & Gold's ivory paper or gold frame. The same Emerald test
// is test/render/page_renderer_test.dart, which is not edited.
import 'dart:io' show zlib;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/mushaf_page.dart' show kTitleFont;
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/page_font_loader.dart';
import 'package:mushaf/mushaf/page_look.dart';
import 'package:mushaf/render/page_renderer.dart';
import 'package:mushaf/theme.dart';

Future<void> _loadFont(String family, String asset) async {
  final loader = FontLoader(family)..addFont(rootBundle.load(asset));
  await loader.load();
}

Future<T> resolve<T>(WidgetTester t, Future<T> Function() work) async {
  T? result;
  Object? error;
  StackTrace? stack;
  var done = false;
  work().then(
    (v) {
      result = v;
      done = true;
    },
    onError: (Object e, StackTrace s) {
      error = e;
      stack = s;
      done = true;
    },
  );
  for (var i = 0; i < 600 && !done; i++) {
    await t.pump(const Duration(milliseconds: 16));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  if (!done) fail('the render did not finish');
  if (error != null) Error.throwWithStackTrace(error!, stack!);
  return result as T;
}

/// How many pixels of [rgba] are within [tolerance] of [color] on every channel.
int count(Uint8List rgba, Color color, {int tolerance = 6}) {
  final r = (color.r * 255).round(),
      g = (color.g * 255).round(),
      b = (color.b * 255).round();
  var n = 0;
  for (var i = 0; i < rgba.length; i += 4) {
    if ((rgba[i] - r).abs() <= tolerance &&
        (rgba[i + 1] - g).abs() <= tolerance &&
        (rgba[i + 2] - b).abs() <= tolerance) {
      n++;
    }
  }
  return n;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MushafRepository mushaf;
  late PageFontLoader fonts;
  final navigator = GlobalKey<NavigatorState>();

  setUpAll(() {
    mushaf = MushafRepository(rootBundle);
    fonts = PageFontLoader();
  });

  Future<OffscreenPageRenderer> start(WidgetTester t, {int page = 293}) async {
    await t.runAsync(() async {
      await _loadFont(kTitleFont, 'assets/fonts/reemkufi/ReemKufi.ttf');
      await _loadFont('AmiriQuran', 'assets/fonts/amiri/AmiriQuran.ttf');
      await _loadFont(kUiFont, 'assets/fonts/cairo/Cairo-Regular.ttf');
      await mushaf.loadPage(page);
      await fonts.ensure(page);
    });
    await t.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: buildAppTheme(),
        home: const SizedBox.expand(),
      ),
    );
    return OffscreenPageRenderer(
      overlay: () => navigator.currentState!.overlay!,
      mushaf: mushaf,
      fonts: fonts,
    );
  }

  const night = PageLook.night;
  const teal = Color(0xFF6CC4B5);

  testWidgets(
    'a Night page is the dark background, light ink, teal title and markers, hairlines; no ivory, no gold',
    (t) async {
      final renderer = await start(t);
      final img = await resolve(t, () => renderer.renderRgba(293, night, 2));
      final total = img.width * img.height;
      expect(
        count(img.rgba, night.background),
        greaterThan(total ~/ 2),
        reason: 'most of the picture is the dark background',
      );
      expect(
        count(img.rgba, night.ink, tolerance: 8),
        greaterThan(5000),
        reason: 'the letters have solid light ink',
      );
      expect(
        count(img.rgba, teal, tolerance: 12),
        greaterThan(100),
        reason: 'the teal title and the ayah-end markers',
      );
      expect(
        count(img.rgba, night.bannerRule!),
        greaterThan(100),
        reason: 'the two hairlines of the surah title',
      );
      expect(count(img.rgba, AppColors.paper), 0, reason: 'no ivory paper');
      expect(count(img.rgba, AppColors.goldDark), 0, reason: 'no gold frame');
      expect(count(img.rgba, AppColors.ring), 0, reason: 'no ring');
      expect(
        count(img.rgba, const Color(0xFFFFFF00), tolerance: 70),
        0,
        reason: 'no yellow underline',
      );
    },
  );

  testWidgets(
    'picture(page, look: Night) is a 2000 x 3000 PNG whose corner and middle are Night',
    (t) async {
      final renderer = await start(t);
      final png = await resolve(t, () => renderer.picture(293, look: night));
      final image = (await t.runAsync(() async {
        final codec = await ui.instantiateImageCodec(png);
        return (await codec.getNextFrame()).image;
      }))!;
      expect((image.width, image.height), (2000, 3000));
      final bytes = (await t.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      Color at(int x, int y) {
        final i = (y * 2000 + x) * 4;
        return Color.fromARGB(
          255,
          bytes.getUint8(i),
          bytes.getUint8(i + 1),
          bytes.getUint8(i + 2),
        );
      }

      for (final p in [(3, 3), (1996, 2996), (1000, 1500), (3, 2996)]) {
        final c = at(p.$1, p.$2);
        expect(
          (c.r - night.background.r).abs() < 0.03 &&
              (c.g - night.background.g).abs() < 0.03 &&
              (c.b - night.background.b).abs() < 0.03,
          isTrue,
          reason: 'pixel $p is $c, not the Night background',
        );
      }
    },
  );

  testWidgets(
    'pdfPage(page, look: Night) is 256 colours with the Night background in the corner and no ivory',
    (t) async {
      final renderer = await start(t, page: 604);
      final result = await resolve(t, () => renderer.pdfPage(604, look: night));
      expect((result.width, result.height), (1600, 2400));
      expect(result.palette, hasLength(768));
      final indices = zlib.decode(result.flateBytes);
      Color at(int x, int y) {
        final k = indices[y * 1600 + x] * 3;
        return Color.fromARGB(
          255,
          result.palette[k],
          result.palette[k + 1],
          result.palette[k + 2],
        );
      }

      expect(at(2, 2), night.background);
      expect(at(800, 1200), night.background);
      var ivory = 0, ink = 0;
      for (var i = 0; i < 256; i++) {
        final r = result.palette[i * 3],
            g = result.palette[i * 3 + 1],
            b = result.palette[i * 3 + 2];
        if ((r - 251).abs() < 6 && (g - 245).abs() < 6 && (b - 227).abs() < 6) {
          ivory++;
        }
        if ((r - 0xEC).abs() < 12 &&
            (g - 0xE7).abs() < 12 &&
            (b - 0xDC).abs() < 12) {
          ink++;
        }
      }
      expect(ivory, 0, reason: 'no ivory in a Night page\'s palette');
      expect(ink, greaterThan(0), reason: 'the light ink has a palette entry');
    },
  );
}
