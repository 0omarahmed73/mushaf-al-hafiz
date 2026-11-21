// The offscreen page renderer, over the real page data and fonts (spec FR-014, SC-004). Rendering needs
// frames and the engine's real time, so each call is driven with pump() and runAsync().
import 'dart:io' show zlib;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/failures.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/page_font_loader.dart';
import 'package:mushaf/mushaf/mushaf_page.dart' show kTitleFont;
import 'package:mushaf/mushaf/mushaf_page_card.dart';
import 'package:mushaf/mushaf/page_look.dart';
import 'package:mushaf/render/page_renderer.dart';
import 'package:mushaf/theme.dart';

import '../support/map_bundle.dart';

Future<void> _loadFont(String family, String asset) async {
  final loader = FontLoader(family)..addFont(rootBundle.load(asset));
  await loader.load();
}

/// Drives [work] (which needs frames and real time) to its end.
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
int _count(Uint8List rgba, Color color, {int tolerance = 2}) {
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

  setUpAll(() async {
    mushaf = MushafRepository(rootBundle);
    fonts = PageFontLoader();
  });

  /// Starts the app shell, loads the fonts and pages in real time first (rootBundle remembers Futures, and
  /// one created in the fake-async zone could never complete in a later test) and returns the renderer.
  Future<OffscreenPageRenderer> start(
    WidgetTester t, {
    PageFontLoader? fontLoader,
    List<int> pages = const [293],
  }) async {
    await t.runAsync(() async {
      await _loadFont(kTitleFont, 'assets/fonts/reemkufi/ReemKufi.ttf');
      await _loadFont('AmiriQuran', 'assets/fonts/amiri/AmiriQuran.ttf');
      await _loadFont(kUiFont, 'assets/fonts/cairo/Cairo-Regular.ttf');
      for (final p in pages) {
        await mushaf.loadPage(p);
        await fonts.ensure(p);
      }
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
      fonts: fontLoader ?? fonts,
    );
  }

  Future<ui.Image> decode(WidgetTester t, Uint8List png) async {
    final image = await t.runAsync(() async {
      final codec = await ui.instantiateImageCodec(png);
      return (await codec.getNextFrame()).image;
    });
    return image!;
  }

  for (final page in [1, 2, 293, 604]) {
    testWidgets('picture($page) is a PNG of exactly 2000 x 3000 px', (t) async {
      final renderer = await start(t, pages: [page]);
      final png = await resolve(t, () => renderer.picture(page));
      expect(png.sublist(0, 8), [
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);
      final image = await decode(t, png);
      expect((image.width, image.height), (2000, 3000));
    });
  }

  testWidgets(
    'the screen look has the ivory paper and the green background, and no highlight colour',
    (t) async {
      final renderer = await start(t);
      final img = await resolve(
        t,
        () => renderer.renderRgba(293, PageLook.screen, 2),
      );
      final ivory = _count(img.rgba, AppColors.paper);
      final green = _count(img.rgba, AppColors.green);
      final highlight = _count(img.rgba, const Color(0xFFFCE49A), tolerance: 3);
      final dark = _count(img.rgba, const Color(0xFF14231D), tolerance: 40);
      expect(
        ivory,
        greaterThan(img.width * img.height ~/ 4),
        reason: 'most of the page is ivory paper',
      );
      expect(
        green,
        greaterThan(1000),
        reason: 'the green around the ring and the title banner',
      );
      expect(highlight, 0, reason: 'a picture never carries the highlight');
      expect(dark, greaterThan(1000), reason: 'the text is drawn');
    },
  );

  testWidgets(
    'the picture carries the app\'s colours and nothing added over the page (SC-010)',
    (t) async {
      // Without a Material above it the overlay passed MaterialApp's error text style (yellow double
      // underline, extra-bold weight) to every word; the picture came out striped and hollow.
      final renderer = await start(t);
      final img = await resolve(
        t,
        () => renderer.renderRgba(293, PageLook.screen, 2),
      );
      final yellow = _count(img.rgba, const Color(0xFFFFFF00), tolerance: 70);
      expect(yellow, 0, reason: 'no yellow underline or any other decoration');
      expect(
        _count(img.rgba, AppColors.goldDark, tolerance: 6),
        greaterThan(300),
        reason: 'the gold frame',
      );
      expect(
        _count(img.rgba, AppColors.ring, tolerance: 6),
        greaterThan(100),
        reason: 'the thin ring around the frame',
      );
      expect(
        _count(img.rgba, AppColors.gold, tolerance: 12),
        greaterThan(50),
        reason: 'the gold text and stars of the surah banner',
      );
      expect(
        _count(img.rgba, AppColors.ink, tolerance: 6),
        greaterThan(5000),
        reason: 'the letters have solid ink, not hollow outlines',
      );
    },
  );

  testWidgets(
    'a page whose font cannot be loaded is ShareFailure(couldNotPrepare)',
    (t) async {
      final broken = PageFontLoader(bundle: MapBundle({}));
      final renderer = await start(t, fontLoader: broken);
      Object? caught;
      try {
        await resolve(t, () => renderer.picture(293));
      } catch (error) {
        caught = error;
      }
      expect(
        caught,
        isA<ShareFailure>().having(
          (f) => f.kind,
          'kind',
          ShareFailureKind.couldNotPrepare,
        ),
      );
    },
  );

  testWidgets(
    'the render leaves nothing behind: the page is not left in the tree',
    (t) async {
      final renderer = await start(t);
      await resolve(t, () => renderer.picture(293));
      await t.pump();
      expect(find.byType(MushafPageCard), findsNothing);
    },
  );

  for (final page in [1, 293, 604]) {
    testWidgets(
      'pdfPage($page) is 1600 x 2400, 256 colours, in the app\'s own colours',
      (t) async {
        final renderer = await start(t, pages: [page]);
        final result = await resolve(t, () => renderer.pdfPage(page));
        expect((result.width, result.height), (1600, 2400));
        expect(result.palette, hasLength(768));
        final indices = zlib.decode(result.flateBytes);
        expect(indices, hasLength(1600 * 2400));
        // The corner of the sheet is the app's green and most of the page is the ivory paper.
        Color at(int x, int y) {
          final k = indices[y * 1600 + x] * 3;
          return Color.fromARGB(
            255,
            result.palette[k],
            result.palette[k + 1],
            result.palette[k + 2],
          );
        }

        expect(at(2, 2), AppColors.green);
        var paper = 0;
        final paperIndex = [
          for (var i = 0; i < 256; i++)
            if (result.palette[i * 3] == 251 &&
                result.palette[i * 3 + 1] == 245 &&
                result.palette[i * 3 + 2] == 227)
              i,
        ];
        expect(
          paperIndex,
          isNotEmpty,
          reason: 'the ivory paper is in the palette exactly',
        );
        for (final v in indices) {
          if (v == paperIndex.first) paper++;
        }
        expect(
          paper / indices.length,
          greaterThan(0.4),
          reason: 'mostly paper',
        );
      },
    );
  }

  testWidgets('pdfPage of a page whose font cannot be loaded is ShareFailure', (
    t,
  ) async {
    final renderer = await start(
      t,
      fontLoader: PageFontLoader(bundle: MapBundle({})),
    );
    Object? caught;
    try {
      await resolve(t, () => renderer.pdfPage(293));
    } catch (e) {
      caught = e;
    }
    expect(caught, isA<ShareFailure>());
    expect((caught! as ShareFailure).kind, ShareFailureKind.couldNotPrepare);
  });
}
