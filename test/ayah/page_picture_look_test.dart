// The page picture and the surah PDF follow the look in force when they are asked for (spec FR-010, FR-011): the action
// passes its look to the renderer, and the ayah menu reads the look from the app's setting when it opens.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/ayah/page_picture_action.dart';
import 'package:mushaf/ayah/share_service.dart';
import 'package:mushaf/ayah/ui/ayah_sheet.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/look/look_settings.dart';
import 'package:mushaf/mushaf/page_look.dart';
import 'package:mushaf/pdf/pdf_job.dart';
import 'package:mushaf/render/page_renderer.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/theme.dart';
import 'package:provider/provider.dart';

import '../support/ayah_harness.dart' show settleAsync, viewFiles;
import '../support/fake_pdf.dart';
import '../support/fake_renderer.dart';
import '../support/fake_share.dart';
import '../support/look_harness.dart';
import '../support/map_bundle.dart';
import '../support/test_meta.dart';

Finder key(String k) => find.byKey(ValueKey(k));

void main() {
  group('the action', () {
    test('passes its look to the renderer; the default is Emerald', () async {
      final renderer = FakePageRenderer();
      final files = MemoryShareFiles();
      final share = FakeShareService();
      await PagePictureAction(
        renderer: renderer,
        files: files,
        share: share,
      ).run(1);
      await PagePictureAction(
        renderer: renderer,
        files: files,
        share: share,
        look: PageLook.night,
      ).run(2);
      expect(renderer.pictured, [1, 2]);
      expect(renderer.pictureLooks, [PageLook.screen, PageLook.night]);
    });
  });

  group('the ayah menu', () {
    /// The menu of 2:6 opened over an app whose look setting is [setting] (or has none).
    Future<(FakePageRenderer, PdfJob)> open(
      WidgetTester t,
      AppLookSettings? setting,
    ) async {
      final renderer = FakePageRenderer();
      final job = fakePdfJob(renderer);
      addTearDown(job.dispose);
      await t.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AyahRepository?>.value(
              value: AyahRepository(MapBundle(viewFiles())),
            ),
            Provider<ShareService?>.value(value: FakeShareService()),
            Provider<PageRenderer?>.value(value: renderer),
            Provider<TempShareFiles?>.value(value: MemoryShareFiles()),
            ListenableProvider<PdfJob?>.value(value: job),
            ListenableProvider<TextSizeSettings?>.value(value: null),
            if (setting != null)
              ListenableProvider<AppLookSettings?>.value(value: setting),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: buildAppTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: TextButton(
                    key: const ValueKey('open'),
                    onPressed: () => showAyahSheet(
                      context,
                      ref: const AyahRef(2, 6),
                      meta: testMeta(),
                      page: 42,
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(key('open'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      return (renderer, job);
    }

    testWidgets('in Night the picture and every page of the PDF are Night', (
      t,
    ) async {
      final a = await LookApp.create(t, choice: LookChoice.night);
      final (renderer, job) = await open(t, a.look);
      await t.tap(key('ayah-page-picture'));
      await settleAsync(t);
      expect(renderer.pictureLooks, [PageLook.night]);
      // The picture closed nothing; the menu is still open for the PDF row.
      await t.tap(key('ayah-surah-pdf'));
      for (var i = 0; i < 400 && job.state is! PdfReady; i++) {
        await t.pump(const Duration(milliseconds: 10));
      }
      expect(job.state, isA<PdfReady>());
      expect(renderer.pdfLooks, isNotEmpty);
      expect(
        renderer.pdfLooks.every((l) => identical(l, PageLook.night)),
        isTrue,
      );
    });

    testWidgets('in Emerald they are as before', (t) async {
      final a = await LookApp.create(t);
      final (renderer, job) = await open(t, a.look);
      await t.tap(key('ayah-page-picture'));
      await settleAsync(t);
      expect(renderer.pictureLooks, [PageLook.screen]);
      await t.tap(key('ayah-surah-pdf'));
      for (var i = 0; i < 400 && job.state is! PdfReady; i++) {
        await t.pump(const Duration(milliseconds: 10));
      }
      expect(
        renderer.pdfLooks.every((l) => identical(l, PageLook.screen)),
        isTrue,
      );
    });

    testWidgets(
      'an app without a look setting (the earlier tests) is Emerald',
      (t) async {
        final (renderer, _) = await open(t, null);
        await t.tap(key('ayah-page-picture'));
        await settleAsync(t);
        expect(renderer.pictureLooks, [PageLook.screen]);
      },
    );
  });
}
