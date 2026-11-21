// The page picture and the PDF pages never follow the text size setting (spec FR-011, SC-007): the same bytes at
// 80%, 100% and 150%, with the setting in the widget tree the renderer draws in.
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/page_font_loader.dart';
import 'package:mushaf/mushaf/mushaf_page.dart' show kTitleFont;
import 'package:mushaf/mushaf/page_look.dart';
import 'package:mushaf/render/page_renderer.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:provider/provider.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const page = 293;
  final navigator = GlobalKey<NavigatorState>();
  late MushafRepository mushaf;
  late PageFontLoader fonts;
  late AppDatabase db;
  late TextSizeSettings size;
  late OffscreenPageRenderer renderer;

  setUpAll(() {
    mushaf = MushafRepository(rootBundle);
    fonts = PageFontLoader();
  });

  Future<void> start(WidgetTester t) async {
    db = AppDatabase(NativeDatabase.memory());
    size = TextSizeSettings(WirdRepository(db));
    addTearDown(() async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
      size.dispose();
      await t.runAsync(db.close);
    });
    await t.runAsync(() async {
      await _loadFont(kTitleFont, 'assets/fonts/reemkufi/ReemKufi.ttf');
      await _loadFont('AmiriQuran', 'assets/fonts/amiri/AmiriQuran.ttf');
      await _loadFont(kUiFont, 'assets/fonts/cairo/Cairo-Regular.ttf');
      await mushaf.loadPage(page);
      await fonts.ensure(page);
    });
    await t.pumpWidget(
      ListenableProvider<TextSizeSettings?>.value(
        value: size,
        child: MaterialApp(
          navigatorKey: navigator,
          theme: buildAppTheme(),
          home: const SizedBox.expand(),
        ),
      ),
    );
    renderer = OffscreenPageRenderer(
      overlay: () => navigator.currentState!.overlay!,
      mushaf: mushaf,
      fonts: fonts,
    );
  }

  Future<void> choose(WidgetTester t, int percent) async {
    await t.runAsync(() => size.set(percent));
    await t.pump();
  }

  testWidgets('the page picture has the same bytes at 80%, 100% and 150%', (
    t,
  ) async {
    await start(t);
    await choose(t, 100);
    final at100 = await resolve(t, () => renderer.picture(page));
    for (final percent in [150, 80]) {
      await choose(t, percent);
      expect(size.percent, percent);
      final other = await resolve(t, () => renderer.picture(page));
      expect(other, at100, reason: 'picture at $percent%');
    }
  });

  testWidgets(
    'the PDF page and its raw pixels are the same at 150% as at 100%',
    (t) async {
      await start(t);
      await choose(t, 100);
      final pdf100 = await resolve(t, () => renderer.pdfPage(page));
      final raw100 = await resolve(
        t,
        () => renderer.renderRgba(page, PageLook.screen, 2),
      );
      await choose(t, 150);
      final pdf150 = await resolve(t, () => renderer.pdfPage(page));
      final raw150 = await resolve(
        t,
        () => renderer.renderRgba(page, PageLook.screen, 2),
      );
      expect((pdf150.width, pdf150.height), (pdf100.width, pdf100.height));
      expect(pdf150.palette, pdf100.palette);
      expect(pdf150.flateBytes, pdf100.flateBytes);
      expect(raw150.rgba, raw100.rgba);
      expect(raw150.rgba.length, 800 * 1200 * 4);
    },
  );
}
