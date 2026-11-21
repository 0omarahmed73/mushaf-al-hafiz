// The size setting applied end to end, through the real chain: the app with its setting, the slider in Settings,
// then the reader's page and an ayah's tafsir, translation and meanings, and a "restart" that reads the saved
// size back. Every other test in feature 003 checks one widget; this one checks that they are wired together.
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/ayah/ayah_repository.dart';
import 'package:mushaf/ayah/ui/ayah_sheet.dart';
import 'package:mushaf/mushaf/mushaf_page_card.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/reader_screen.dart';
import 'package:mushaf/settings/settings_screen.dart';
import 'package:mushaf/settings/text_size_settings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/ayah_harness.dart' show viewFiles;
import '../support/fake_share.dart';
import '../support/map_bundle.dart';
import '../support/reader_harness.dart' show settleReader;

Finder key(String k) => find.byKey(ValueKey(k));

double? fontOf(WidgetTester t, Finder f) => t.widget<Text>(f).style?.fontSize;

/// Small ayah assets that cover every ayah of surah 2, so the ayah a long press picks always has its texts.
Map<String, String> ayahFiles() {
  final files = viewFiles();
  files['assets/ayah/text/002.json'] = jsonEncode({
    'surah': 2,
    'ayahs': [
      for (var a = 1; a <= 286; a++) ['كلمةقرآنية$a'],
    ],
  });
  files['assets/ayah/tafsir/002.json'] = jsonEncode({
    'surah': 2,
    'entries': [
      {'from': 1, 'to': 286, 'text': 'تفسير الآيتين\n\nفقرة ثانية'},
    ],
    'without': <int>[],
  });
  files['assets/ayah/translation/002.json'] = jsonEncode({
    'surah': 2,
    'ayahs': [for (var a = 1; a <= 286; a++) 'English verse'],
  });
  files['assets/ayah/gharib/002.json'] = jsonEncode({
    'surah': 2,
    'ayahs': {
      for (var a = 1; a <= 286; a++)
        '$a': [
          {'w': 'كلمة', 'm': 'معنى الكلمة', 'b': 327},
        ],
    },
  });
  return files;
}

void main() {
  const page = 42;

  late AppDatabase db;
  late WirdRepository repo;
  late MushafRepository mushaf;

  /// The whole app on the reader, with a setting object that has just been loaded from the database, as
  /// `main()` does at a start.
  Future<TextSizeSettings> start(WidgetTester t) async {
    final size = TextSizeSettings(repo);
    addTearDown(size.dispose);
    await t.runAsync(size.load);
    await t.pumpWidget(
      MushafApp(
        wirdRepository: repo,
        mushafRepository: mushaf,
        ayahRepository: AyahRepository(MapBundle(ayahFiles())),
        shareService: FakeShareService(),
        textSize: size,
        home: const ReaderScreen(),
      ),
    );
    await settleReader(t);
    return size;
  }

  Future<void> prepare(WidgetTester t) async {
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    db = AppDatabase(NativeDatabase.memory());
    repo = WirdRepository(db);
    mushaf = MushafRepository(rootBundle);
    addTearDown(() async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
      await t.runAsync(db.close);
    });
    await t.runAsync(() async {
      await mushaf.loadMeta();
      for (var p = page - 1; p <= page + 1; p++) {
        await mushaf.loadPage(p);
      }
      await repo.ensureDefaults();
      await repo.setPage((await repo.activeWird())!.id, page);
    });
  }

  /// Long-presses a word of 2:255 that is on the screen and opens [row] of its menu.
  Future<void> openView(WidgetTester t, String row) async {
    final data = await t.runAsync(() => mushaf.loadPage(page));
    final ids = wordIdsOfAyah(data!, const AyahRef(2, 255));
    final viewport = t.getRect(find.byType(PageView));
    final onScreen = ids.firstWhere(
      (id) => viewport.contains(t.getCenter(key('w$id'))),
    );
    await t.longPress(key('w$onScreen'));
    await settleReader(t);
    await t.tap(key(row));
    await settleReader(t);
  }

  /// A tap on the barrier leaves a view for the menu first and closes the menu the second time.
  Future<void> closeSheet(WidgetTester t) async {
    for (var i = 0; i < 2; i++) {
      await t.tapAt(const Offset(200, 40));
      await settleReader(t);
    }
    expect(find.byType(AyahSheet), findsNothing);
  }

  testWidgets(
    'the slider in Settings changes the page and the three ayah texts, and the size is still there after a restart',
    (t) async {
      await prepare(t);
      final size = await start(t);

      // At the start: today's look.
      final viewport = t.getRect(find.byType(PageView));
      expect(key('page-pan'), findsNothing);
      expect(t.getSize(find.byType(MushafPageCard)), viewport.size);

      // From the reader to Settings, and the slider to the largest size with a finger.
      await t.tap(key('open-settings'));
      await settleReader(t);
      await t.drag(key('text-size-slider'), const Offset(-2000, 0));
      await t.pump();
      expect(size.percent, 150);
      expect(fontOf(t, key('text-size-preview-ar')), closeTo(17 * 1.5, 1e-9));
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Back on the reader the page is 1.5 times bigger.
      await t.tap(find.byType(BackButton));
      await settleReader(t);
      expect(key('page-pan'), findsOneWidget);
      expect(
        t.getSize(find.byType(MushafPageCard)).width,
        closeTo(viewport.width * 1.5, 0.5),
      );
      expect(
        t.getSize(find.byType(MushafPageCard)).height,
        closeTo(viewport.height * 1.5, 0.5),
      );

      // The three ayah texts of a word on that bigger page are bigger too.
      await openView(t, 'ayah-tafsir');
      expect(fontOf(t, find.text('تفسير الآيتين')), closeTo(17 * 1.5, 1e-9));
      await closeSheet(t);
      await openView(t, 'ayah-translation');
      expect(fontOf(t, find.text('English verse')), closeTo(17 * 1.5, 1e-9));
      await closeSheet(t);
      await openView(t, 'ayah-meanings');
      expect(fontOf(t, find.text('كلمة')), closeTo(18 * 1.5, 1e-9));
      expect(fontOf(t, find.text('معنى الكلمة')), closeTo(16 * 1.5, 1e-9));
      await closeSheet(t);

      // A restart: a new setting object loads what was saved, and the app starts with the bigger page.
      expect(await t.runAsync(() => repo.textSizeRaw()), '150');
      await t.pumpWidget(const SizedBox());
      final restarted = await start(t);
      expect(restarted.percent, 150);
      expect(key('page-pan'), findsOneWidget);
      expect(
        t.getSize(find.byType(MushafPageCard)).width,
        closeTo(viewport.width * 1.5, 0.5),
      );
      await openView(t, 'ayah-tafsir');
      expect(fontOf(t, find.text('تفسير الآيتين')), closeTo(17 * 1.5, 1e-9));
    },
  );

  testWidgets(
    'the smallest size shrinks the page and the three ayah texts, through the same chain',
    (t) async {
      await prepare(t);
      final size = await start(t);
      final viewport = t.getRect(find.byType(PageView));

      await t.tap(key('open-settings'));
      await settleReader(t);
      await t.drag(key('text-size-slider'), const Offset(2000, 0));
      await t.pump();
      expect(size.percent, 80);
      await t.tap(find.byType(BackButton));
      await settleReader(t);

      expect(key('page-pan'), findsNothing);
      expect(
        t.getSize(find.byType(MushafPageCard)).width,
        closeTo(viewport.width * 0.8, 0.5),
      );
      await openView(t, 'ayah-tafsir');
      expect(fontOf(t, find.text('تفسير الآيتين')), closeTo(17 * 0.8, 1e-9));
      await closeSheet(t);
      await openView(t, 'ayah-translation');
      expect(fontOf(t, find.text('English verse')), closeTo(17 * 0.8, 1e-9));
      await closeSheet(t);
      await openView(t, 'ayah-meanings');
      expect(fontOf(t, find.text('كلمة')), closeTo(18 * 0.8, 1e-9));
    },
  );
}
