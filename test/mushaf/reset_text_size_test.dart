// «الحجم الافتراضي» brings everything back to today's look at once: the preview, the ayah texts that are open
// and the Mushaf page; and 100% is what the next start finds (spec FR-004, FR-005).
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/ayah/share_service.dart';
import 'package:mushaf/ayah/ui/ayah_sheet.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/mushaf_page_card.dart';
import 'package:mushaf/settings/settings_screen.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/settings/text_size_tile.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:provider/provider.dart';

import '../support/ayah_harness.dart';
import '../support/fake_share.dart';
import '../support/map_bundle.dart';
import '../support/reader_harness.dart';
import '../support/test_meta.dart';

Finder key(String k) => find.byKey(ValueKey(k));

double? fontOf(WidgetTester t, Finder f) => t.widget<Text>(f).style?.fontSize;

void main() {
  testWidgets(
    'from the reader: Settings at 150%, reset, and the page below is at 100% at once and stays there after a restart',
    (t) async {
      final reader = await pumpSizedReader(t, percent: 150);
      expect(key('page-pan'), findsOneWidget);

      await t.tap(key('open-settings'));
      await settleReader(t);
      await t.scrollUntilVisible(
        key('text-size-reset'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(SettingsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await t.ensureVisible(key('text-size-reset'));
      await t.pump();
      expect(fontOf(t, key('text-size-preview-ar')), closeTo(17 * 1.5, 1e-9));
      expect(t.widget<Text>(key('text-size-value')).data, '150%');

      await t.tap(key('text-size-reset'));
      await t.pump();
      // The preview and the number are at 100% in the same frame...
      expect(fontOf(t, key('text-size-preview-ar')), 17);
      expect(fontOf(t, key('text-size-preview-en')), 17);
      expect(t.widget<Text>(key('text-size-value')).data, '100%');
      // ...and the reader kept under the Settings screen already has its page at 100%.
      // (Since feature 010 T012 the pager also keeps the next and the previous page built while it rests, so the reader
      // has up to three cards under Settings: every one of them is at 100%, which is what this line is about.)
      final underneath = find.byType(MushafPageCard, skipOffstage: false);
      final viewport = t.getRect(find.byType(PageView, skipOffstage: false));
      expect(underneath, findsWidgets);
      for (var i = 0; i < underneath.evaluate().length; i++) {
        expect(t.getSize(underneath.at(i)), viewport.size, reason: 'card $i');
      }

      await t.tap(find.byType(BackButton));
      await settleReader(t);
      expect(key('page-pan'), findsNothing);
      expect(t.getSize(find.byType(MushafPageCard)), viewport.size);

      // What the next start reads.
      expect(await t.runAsync(() => reader.repo.textSizeRaw()), '100');
      final restarted = TextSizeSettings(reader.repo);
      addTearDown(restarted.dispose);
      await t.runAsync(restarted.load);
      expect(restarted.percent, 100);
      expect(restarted.isDefault, isTrue);
    },
  );

  testWidgets(
    'with an ayah menu open at 150%: the reset button of the size row brings the tafsir text back to 100% at once',
    (t) async {
      final size = await _sizeAt(t, 150);
      await t.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AyahRepository?>.value(
              value: AyahRepository(MapBundle(viewFiles())),
            ),
            Provider<ShareService?>.value(value: FakeShareService()),
            ListenableProvider<TextSizeSettings?>.value(value: size),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: buildAppTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    const TextSizeTile(),
                    TextButton(
                      key: const ValueKey('open'),
                      onPressed: () => showAyahSheet(
                        context,
                        ref: const AyahRef(2, 6),
                        meta: testMeta(),
                        page: 42,
                      ),
                      child: const Text('open'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(key('open'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      await t.tap(key('ayah-tafsir'));
      await settleAsync(t);
      final tafsir = find.text('تفسير الآيتين');
      expect(fontOf(t, tafsir), closeTo(17 * 1.5, 1e-9));

      // The sheet's scrim covers the row, so the button's own handler is called, as its tap would.
      t.widget<TextButton>(key('text-size-reset')).onPressed!();
      await t.pump();
      expect(fontOf(t, tafsir), 17);
      expect(fontOf(t, find.text('فقرة ثانية')), 17);
      expect(fontOf(t, key('text-size-preview-ar')), 17);
      expect(size.percent, 100);
    },
  );
}

Future<TextSizeSettings> _sizeAt(WidgetTester t, int percent) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(db.close);
  });
  final size = TextSizeSettings(WirdRepository(db));
  addTearDown(size.dispose);
  await t.runAsync(() => size.set(percent));
  return size;
}
